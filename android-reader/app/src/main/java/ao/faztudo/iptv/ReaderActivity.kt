package ao.faztudo.iptv

import android.app.Activity
import android.os.Bundle
import android.graphics.Color
import android.widget.*
import android.view.Gravity
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

class ReaderActivity : Activity() {
    private val base = "https://atrlbhisqmtuyopibjtu.supabase.co"
    private val anon = "sb_publishable_Whcxweh1gjH2wPoQ47spvg_f-vhZl1u"
    private val client = OkHttpClient()
    private var token = ""
    private lateinit var page: LinearLayout
    private lateinit var message: TextView
    private lateinit var email: EditText
    private lateinit var pass: EditText
    private lateinit var key: EditText
    private lateinit var video: PlayerView
    private var exo: ExoPlayer? = null
    private val items = mutableListOf<Pair<String,String>>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.statusBarColor = Color.BLACK
        window.navigationBarColor = Color.BLACK
        loginScreen()
    }

    private fun layout(title: String) {
        page = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(16,16,16,16)
            setBackgroundColor(Color.rgb(20,20,20))
        }
        page.addView(TextView(this).apply {
            text = title; textSize = 24f; gravity = Gravity.CENTER
            setTextColor(Color.WHITE); setPadding(8,12,8,12)
        })
        message = TextView(this).apply { setTextColor(Color.LTGRAY); text = "Faz Tudo Tecnologia"; setPadding(6,8,6,8) }
        page.addView(message)
        setContentView(ScrollView(this).apply { addView(page) })
    }

    private fun input(label: String, secret: Boolean = false): EditText {
        val v = EditText(this).apply {
            hint = label; setTextColor(Color.WHITE); setHintTextColor(Color.GRAY)
            setPadding(12,12,12,12); setSingleLine(true)
            if (secret) inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_PASSWORD
        }
        page.addView(v)
        return v
    }

    private fun button(label: String, run: () -> Unit) {
        page.addView(Button(this).apply { text = label; setOnClickListener { run() } })
    }

    private fun loginScreen() {
        layout("FAZ TUDO IPTV")
        page.addView(TextView(this).apply { text = "Leitor Android independente • listas M3U/M3U8"; setTextColor(Color.LTGRAY) })
        email = input("E-mail da conta do site")
        pass = input("Palavra-passe", true)
        key = input("UUID do leitor autorizado")
        button("ENTRAR E VALIDAR ACESSO") { login() }
        message.text = "A subscrição é validada pelo Supabase antes de abrir a lista."
    }

    private fun login() {
        val e = email.text.toString().trim()
        val p = pass.text.toString()
        val device = key.text.toString().trim()
        if (e.isEmpty() || p.isEmpty() || device.isEmpty()) { message.text = "Preencha os três campos."; return }
        message.text = "A validar conta…"
        val data = JSONObject().put("email",e).put("password",p)
        val request = Request.Builder().url("$base/auth/v1/token?grant_type=password")
            .header("apikey",anon).post(data.toString().toRequestBody("application/json".toMediaType())).build()
        client.newCall(request).enqueue(object: Callback {
            override fun onFailure(call: Call, ex: IOException) { runOnUiThread { message.text = "Falha de rede: ${ex.message}" } }
            override fun onResponse(call: Call, response: Response) {
                val body = response.body?.string().orEmpty()
                if (!response.isSuccessful) {
                    runOnUiThread { message.text = "Credenciais incorrectas ou conta indisponível." }
                } else {
                    token = JSONObject(body).optString("access_token")
                    validate(device)
                }
            }
        })
    }

    private fun validate(device: String) {
        val data = JSONObject().put("p_device_key",device)
        val request = Request.Builder().url("$base/rest/v1/rpc/iptv_my_access")
            .header("apikey",anon).header("Authorization","Bearer $token")
            .post(data.toString().toRequestBody("application/json".toMediaType())).build()
        client.newCall(request).enqueue(object: Callback {
            override fun onFailure(call: Call, ex: IOException) { runOnUiThread { message.text = "Falha ao validar acesso." } }
            override fun onResponse(call: Call, response: Response) {
                val raw = response.body?.string().orEmpty()
                var allowed = false
                if (response.isSuccessful) {
                    val rows = JSONArray(raw)
                    for (i in 0 until rows.length()) {
                        val row = rows.getJSONObject(i)
                        if (row.optString("status") == "active" && row.optString("playlist_id") != "null") allowed = true
                    }
                }
                if (allowed) runOnUiThread { readerScreen() }
                else runOnUiThread { message.text = "Sem subscrição activa neste leitor. Contacte o administrador." }
            }
        })
    }

    private fun readerScreen() {
        layout("FAZ TUDO IPTV")
        video = PlayerView(this).apply { setBackgroundColor(Color.BLACK) }
        page.addView(video, LinearLayout.LayoutParams(-1,220))
        button("ACTUALIZAR LISTA") { loadList() }
        button("SAIR") { exo?.release(); exo = null; token = ""; loginScreen() }
        loadList()
    }

    private fun loadList() {
        message.text = "A carregar canais autorizados…"
        val data = JSONObject().put("device_key",key.text.toString().trim())
        val request = Request.Builder().url("$base/functions/v1/iptv-gateway?mode=playlist")
            .header("apikey",anon).header("Authorization","Bearer $token")
            .post(data.toString().toRequestBody("application/json".toMediaType())).build()
        client.newCall(request).enqueue(object: Callback {
            override fun onFailure(call: Call, ex: IOException) { runOnUiThread { message.text = "Falha ao carregar lista." } }
            override fun onResponse(call: Call, response: Response) {
                val raw = response.body?.string().orEmpty()
                if (!response.isSuccessful) {
                    runOnUiThread { message.text = "A lista não está activa ou o leitor não está autorizado." }
                } else {
                    parse(raw)
                    runOnUiThread { showItems() }
                }
            }
        })
    }

    private fun parse(m3u: String) {
        items.clear()
        var title = "Canal"
        for (line in m3u.lineSequence()) {
            val s = line.trim()
            if (s.startsWith("#EXTINF",true)) title = s.substringAfterLast(',').trim().ifBlank { "Canal" }
            else if (s.startsWith("http://") || s.startsWith("https://")) {
                items.add(title to s); title = "Canal"
            }
        }
    }

    private fun showItems() {
        message.text = "Canais disponíveis: ${items.size}"
        items.forEach { item ->
            page.addView(Button(this).apply {
                text = item.first
                setOnClickListener { play(item.second,item.first) }
            })
        }
    }

    private fun play(url: String, title: String) {
        message.text = "A reproduzir: $title"
        if (exo == null) { exo = ExoPlayer.Builder(this).build(); video.player = exo }
        exo?.setMediaItem(MediaItem.fromUri(url)); exo?.prepare(); exo?.play()
    }

    override fun onDestroy() { exo?.release(); exo = null; super.onDestroy() }
}
