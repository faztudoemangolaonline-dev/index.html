package ao.faztudo.iptv

import android.app.Activity
import android.os.Bundle
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.*
import androidx.activity.ComponentActivity
import androidx.activity.result.contract.ActivityResultContracts
import androidx.media3.common.MediaItem
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.PlayerView

data class Channel(val name: String, val url: String, val group: String)

class MainActivity : ComponentActivity() {
    private val channels = mutableListOf<Channel>()
    private lateinit var root: LinearLayout
    private lateinit var list: ListView
    private lateinit var playerView: PlayerView
    private var player: ExoPlayer? = null
    private val pickFile = registerForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        uri?.let { contentResolver.takePersistableUriPermission(it, Intent.FLAG_GRANT_READ_URI_PERMISSION); loadM3u(it) }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.statusBarColor = Color.BLACK
        showSplash()
    }

    private fun showSplash() {
        val splash = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.rgb(18,18,18))
            addView(TextView(this@MainActivity).apply {
                text = "FAZ TUDO TECNOLOGIA IPTV"
                textSize = 27f; setTextColor(Color.WHITE); gravity = Gravity.CENTER
            })
            addView(TextView(this@MainActivity).apply {
                text = "Seja Bem vindo a Faztudo Ananias inovação"
                textSize = 17f; setTextColor(Color.LTGRAY); gravity = Gravity.CENTER
                setPadding(20,24,20,20)
            })
        }
        setContentView(splash)
        splash.postDelayed({ showHome() }, 4000)
    }

    private fun showHome() {
        root = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setBackgroundColor(Color.rgb(15,15,15)); setPadding(12,12,12,8) }
        val title = TextView(this).apply { text = "FAZ TUDO IPTV"; textSize = 23f; setTextColor(Color.WHITE); gravity = Gravity.CENTER; setPadding(8,12,8,12) }
        root.addView(title)
        val actions = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL; gravity = Gravity.CENTER }
        actions.addView(actionButton("Abrir lista M3U") { pickFile.launch(arrayOf("*/*")) })
        actions.addView(actionButton("Xtream Codes") { showXtreamDialog() })
        root.addView(actions)
        playerView = PlayerView(this).apply { useController = true; layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 220) }
        root.addView(playerView)
        list = ListView(this).apply { setBackgroundColor(Color.rgb(25,25,25)); setOnItemClickListener { _,_,position,_ -> play(channels[position].url) } }
        root.addView(list, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f))
        setContentView(root)
        refreshList()
    }

    private fun actionButton(label: String, action: () -> Unit) = Button(this).apply {
        text = label; setOnClickListener { action() }
    }

    private fun loadM3u(uri: Uri) {
        try {
            val text = contentResolver.openInputStream(uri)?.bufferedReader()?.use { it.readText() } ?: ""
            parseM3u(text)
        } catch (e: Exception) { toast("Não foi possível abrir a lista: ${e.message}") }
    }

    private fun parseM3u(text: String) {
        channels.clear()
        var name = "Canal"; var group = "Geral"
        text.lineSequence().forEach { raw ->
            val line = raw.trim()
            if (line.startsWith("#EXTINF", true)) {
                name = line.substringAfterLast(",").trim().ifBlank { "Canal" }
                group = Regex("""group-title="([^"]*)"""").find(line)?.groupValues?.get(1) ?: "Geral"
            } else if (line.isNotBlank() && !line.startsWith("#") && (line.startsWith("http://") || line.startsWith("https://"))) {
                channels.add(Channel(name, line, group)); name = "Canal"
            }
        }
        refreshList()
        toast("Lista carregada: ${channels.size} itens")
    }

    private fun refreshList() {
        if (!::list.isInitialized) return
        list.adapter = ArrayAdapter(this, android.R.layout.simple_list_item_1, channels.map { "［${it.group}］ ${it.name}" })
    }

    private fun showXtreamDialog() {
        val box = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setPadding(24,8,24,8) }
        val server = EditText(this).apply { hint = "Servidor (https://...)"; setSingleLine() }
        val user = EditText(this).apply { hint = "Utilizador"; setSingleLine() }
        val pass = EditText(this).apply { hint = "Palavra-passe"; setSingleLine() }
        box.addView(server); box.addView(user); box.addView(pass)
        AlertDialog.Builder(this).setTitle("Xtream Codes").setView(box)
            .setPositiveButton("Carregar") { _,_ ->
                val base = server.text.toString().trim().trimEnd('/')
                val u = Uri.encode(user.text.toString()); val p = Uri.encode(pass.text.toString())
                if (base.startsWith("http") && u.isNotBlank() && p.isNotBlank()) {
                    Thread {
                        try {
                            val url = java.net.URL("$base/player_api.php?username=$u&password=$p&action=get_live_streams")
                            val data = url.openStream().bufferedReader().use { it.readText() }
                            val arr = org.json.JSONArray(data)
                            runOnUiThread {
                                channels.clear()
                                for (i in 0 until arr.length()) {
                                    val item = arr.getJSONObject(i)
                                    val id = item.optString("stream_id")
                                    val ext = item.optString("container_extension", "ts")
                                    channels.add(Channel(item.optString("name", "Canal"), "$base/live/$u/$p/$id.$ext", item.optString("category_name", "TV")))
                                }
                                refreshList(); toast("Canais carregados: ${channels.size}")
                            }
                        } catch (e: Exception) { runOnUiThread { toast("Falha ao ligar ao servidor: ${e.message}") } }
                    }.start()
                } else toast("Confirma servidor, utilizador e palavra-passe")
            }.setNegativeButton("Cancelar", null).show()
    }

    private fun play(url: String) {
        try {
            if (player == null) { player = ExoPlayer.Builder(this).build(); playerView.player = player }
            player?.setMediaItem(MediaItem.fromUri(url)); player?.prepare(); player?.play()
        } catch (e: Exception) { toast("Não foi possível reproduzir este conteúdo") }
    }

    private fun toast(message: String) = Toast.makeText(this, message, Toast.LENGTH_LONG).show()

    override fun onStop() { super.onStop(); player?.release(); player = null }
}
