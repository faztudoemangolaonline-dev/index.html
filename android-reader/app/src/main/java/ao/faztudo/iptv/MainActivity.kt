package ao.faztudo.iptv

import android.app.Activity
import android.os.Bundle
import android.graphics.Color
import android.view.Gravity
import android.widget.*
import android.text.InputType
import androidx.media3.common.MediaItem
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.PlayerView
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import org.json.JSONArray
import java.io.IOException
import java.util.concurrent.TimeUnit

class MainActivity : Activity() {
    private val base = "https://atrlbhisqmtuyopibjtu.supabase.co"
    private val anon = "sb_publishable_Whcxweh1gjH2wPoQ47spvg_f-vhZl1u"
    private val http = OkHttpClient.Builder().connectTimeout(20, TimeUnit.SECONDS).readTimeout(45, TimeUnit.SECONDS).build()
    private var jwt: String? = null
    private var player: ExoPlayer? = null
    private lateinit var root: LinearLayout
    private lateinit var status: TextView
    private lateinit var deviceKey: EditText
    private lateinit var email: EditText
    private lateinit var password: EditText
    private lateinit var playerView: PlayerView
    private val channels = mutableListOf<Pair<String,String>>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.statusBarColor = Color.rgb(18,18,18)
        window.navigationBarColor = Color.BLACK
        showLogin()
    }

    private fun shell(title: String) {
        root = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setPadding(18); setBackgroundColor(Color.rgb(18,18,18)) }
        root.addView(TextView(this).apply { text = title; textSize = 25f; setTextColor(Color.WHITE); gravity = Gravity.CENTER; setPadding(8) })
        status = TextView(this).apply { text = "Faz Tudo Tecnologia"; textSize = 13f; setTextColor(Color.LTGRAY); setPadding(8) }
        root.addView(status)
        setContentView(ScrollView(this).apply { addView(root) })
    }

    private fun field(hintText: String, secret: Boolean = false): EditText = EditText(this).apply {
        hint = hintText; setTextColor(Color.WHITE); setHintTextColor(Color.GRAY)
        inputType = if (secret) InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_PASSWORD else InputType.TYPE_CLASS_TEXT
        setPadding(12); setSingleLine(true)
        root.addView(this, LinearLayout.LayoutParams(-1, -2).apply { topMargin = 7; bottomMargin = 7 })
    }

    private fun action(label: String, callback: () -> Unit) {
        root.addView(Button(this).apply { text = label; setOnClickListener { callback() } }, LinearLayout.LayoutParams(-1, -2).apply { topMargin = 6; bottomMargin = 6 })
    }

    private fun showLogin() {
        shell("FAZ TUDO IPTV")
        root.addView(TextView(this).apply { text = "Leitor IPTV independente • M3U / M3U8 • HLS • Android 6+"; setTextColor(Color.LTGRAY); textSize = 14f })
        email = field("E-mail da conta de cliente")
        password = field("Palavra-passe da conta", true)
        deviceKey = field("Identificador do leitor autorizado (UUID)")
        action("ENTRAR E VALIDAR SUBSCRIÇÃO") { signIn() }
        status.text = "Entre com a conta do site e o identificador de leitor autorizado pelo administrador."
    }

    private fun signIn() {
        val e = email.text.toString().trim()
        val p = password.text.toString()
        val dk = deviceKey.text.toString().trim()
        if (e.isBlank() || p.isBlank() || dk.isBlank()) { status.text = "Preencha e-mail, palavra-passe e identificador do leitor."; return }
        status.text = "A validar a conta…"
        val body = JSONObject().put("email", e).put("password", p)
        val req = Request.Builder().url("$base/auth/v1/token?grant_type=password")
            .addHeader("apikey", anon).addHeader("Content-Type", "application/json")
            .post(body.toString().toRequestBody("application/json".toMediaType())).build()
        http.newCall(req).enqueue(object: Callback {
            override fun onFailure(call: Call, ex: IOException) { runOnUiThread { status.text = "Falha de ligação: ${ex.message}" } }
            override fun onResponse(call: Call, response: Response) {
                val raw = response.body?.string().orEmpty()
                if (!response.isSuccessful) { runOnUiThread { status.text = "Não foi possível iniciar sessão. Verifique os dados."; return } }
                jwt = JSONObject(raw).optString("access_token")
                validateReader(dk)
            }
        })
    }

    private fun validateReader(dk: String) {
        val body = JSONObject().put("p_device_key", dk)
        val req = Request.Builder().url("$base/rest/v1/rpc/iptv_my_access")
            .addHeader("apikey", anon).addHeader("Authorization", "Bearer $jwt")
            .addHeader("Content-Type", "application/json")
            .post(body.toString().toRequestBody("application/json".toMediaType())).build()
        http.newCall(req).enqueue(object: Callback {
            override fun onFailure(call: Call, ex: IOException) { runOnUiThread { status.text = "Erro ao validar autorização: ${ex.message}" } }
            override fun onResponse(call: Call, response: Response) {
                val raw = response.body?.string().orEmpty()
                if (!response.isSuccessful) { runOnUiThread { status.text = "Leitor não autorizado. Peça ao administrador para associar este dispositivo à subscrição." }; return }
                val arr = JSONArray(raw)
                var valid = false
                for (i in 0 until arr.length()) {
                    val item = arr.getJSONObject(i)
                    val end = item.optString("ends_at")
                    val active = item.optString("status") == "active"
                    val notExpired = end.isBlank() || end == "null" || end.startsWith("2")
                    if (active && notExpired && item.optString("playlist_id") != "null") valid = true
                }
                if (!valid) { runOnUiThread { status.text = "Subscrição inactiva ou expirada. Contacte o administrador."; return } }
                runOnUiThread { showReader() }
            }
        })
    }

    private fun showReader() {
        shell("FAZ TUDO IPTV")
        status.text = "Subscrição validada. A carregar a lista autorizada…"
        playerView = PlayerView(this).apply { setBackgroundColor(Color.BLACK) }
        root.addView(playerView, LinearLayout.LayoutParams(-1, 220))
        action("CARREGAR LISTA AUTORIZADA") { loadPlaylist() }
        action("TERMINAR SESSÃO") { player?.release(); player = null; jwt = null; showLogin() }
        loadPlaylist()
    }

    private fun loadPlaylist() {
        val body = JSONObject().put("device_key", deviceKey.text.toString().trim())
        val req = Request.Builder().url("$base/functions/v1/iptv-gateway?mode=playlist")
            .addHeader("apikey", anon).addHeader("Authorization", "Bearer $jwt")
            .addHeader("Content-Type", "application/json")
            .post(body.toString().toRequestBody("application/json".toMediaType())).build()
        status.text = "A descarregar canais…"
        http.newCall(req).enqueue(object: Callback {
            override fun onFailure(call: Call, ex: IOException) { runOnUiThread { status.text = "Erro ao carregar lista: ${ex.message}" } }
            override fun onResponse(call: Call, response: Response) {
                val raw = response.body?.string().orEmpty()
                if (!response.isSuccessful) { runOnUiThread { status.text = "Lista indisponível: autorização ou configuração inválida."; return } }
                parseM3u(raw)
                runOnUiThread { renderChannels() }
            }
        })
    }

    private fun parseM3u(text: String) {
        channels.clear()
        var name = "Canal"
        text.lineSequence().forEach { line ->
            val s = line.trim()
            if (s.startsWith("#EXTINF", true)) name = s.substringAfterLast(',').trim().ifBlank { "Canal" }
            else if (s.isNotBlank() && !s.startsWith("#") && (s.startsWith("http://") || s.startsWith("https://"))) {
                channels.add(name to s); name = "Canal"
            }
        }
    }

    private fun renderChannels() {
        status.text = "Lista carregada: ${channels.size} canais"
        channels.forEach { item ->
            root.addView(Button(this).apply { text = item.first; setOnClickListener { play(item.second, item.first) } },
                LinearLayout.LayoutParams(-1, -2).apply { topMargin = 3; bottomMargin = 3 })
        }
    }

    private fun play(url: String, name: String) {
        status.text = "A reproduzir: $name"
        if (player == null) { player = ExoPlayer.Builder(this).build(); playerView.player = player }
        player?.setMediaItem(MediaItem.fromUri(url)); player?.prepare(); player?.play()
    }

    override fun onDestroy() { player?.release(); player = null; super.onDestroy() }
}
