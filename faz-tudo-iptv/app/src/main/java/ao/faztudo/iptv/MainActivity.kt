package ao.faztudo.iptv

import android.app.AlertDialog
import android.os.Bundle
import android.content.Context
import android.graphics.Color
import android.net.Uri
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.inputmethod.InputMethodManager
import android.webkit.WebView
import android.widget.*
import androidx.activity.ComponentActivity
import androidx.activity.result.contract.ActivityResultContracts
import androidx.media3.common.MediaItem
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.PlayerView
import org.json.JSONArray
import org.json.JSONObject

data class Channel(val name: String, val url: String, val group: String, val type: String = "TV")

class MainActivity : ComponentActivity() {
    private val channels = mutableListOf<Channel>()
    private val favorites = mutableSetOf<String>()
    private lateinit var root: LinearLayout
    private lateinit var list: ListView
    private lateinit var playerView: PlayerView
    private lateinit var search: EditText
    private lateinit var status: TextView
    private var player: ExoPlayer? = null
    private var selectedType = "Todos"
    private var showingFavorites = false
    private val prefs by lazy { getSharedPreferences("faztudo_iptv_permanent", Context.MODE_PRIVATE) }

    private val pickFile = registerForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        uri?.let {
            try { contentResolver.takePersistableUriPermission(it, IntentFlags.READ) } catch (_: Exception) {}
            loadM3u(it)
        }
    }

    private object IntentFlags { const val READ = android.content.Intent.FLAG_GRANT_READ_URI_PERMISSION }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.statusBarColor = Color.rgb(5, 24, 42)
        loadSaved()
        showHome()
    }

    private fun showHome() {
        root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.rgb(8, 24, 40))
            setPadding(12, 10, 12, 8)
        }
        val title = TextView(this).apply {
            text = "FAZ TUDO TECNOLOGIA IPTV"
            textSize = 21f; setTextColor(Color.WHITE); gravity = Gravity.CENTER
            setPadding(4, 10, 4, 12)
        }
        root.addView(title)
        val actions = LinearLayout(this).apply { gravity = Gravity.CENTER; orientation = LinearLayout.HORIZONTAL }
        actions.addView(actionButton("M3U / Ficheiro") { pickFile.launch(arrayOf("*/*")) })
        actions.addView(actionButton("Xtream") { showXtreamDialog() })
        actions.addView(actionButton("Sobre o criador") { showBiography() })
        root.addView(actions)

        playerView = PlayerView(this).apply {
            useController = true
            layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 220)
        }
        root.addView(playerView)

        search = EditText(this).apply {
            hint = "Pesquisar canais, filmes e séries"
            setSingleLine(true)
            setTextColor(Color.WHITE); setHintTextColor(Color.LTGRAY)
            setPadding(12, 5, 12, 5)
        }
        root.addView(search)
        search.addTextChangedListener(SimpleTextWatcher { refreshList() })

        val filters = LinearLayout(this).apply { gravity = Gravity.CENTER; orientation = LinearLayout.HORIZONTAL }
        listOf("Todos", "TV", "Filmes", "Séries", "Favoritos").forEach { type ->
            filters.addView(actionButton(type) {
                showingFavorites = type == "Favoritos"
                selectedType = if (showingFavorites) "Todos" else type
                refreshList()
            })
        }
        root.addView(filters)

        status = TextView(this).apply {
            text = if (channels.isEmpty()) "Importe uma lista M3U ou ligue-se ao seu fornecedor." else "Lista guardada neste dispositivo: ${channels.size} conteúdos"
            setTextColor(Color.rgb(154, 205, 235)); textSize = 12f
            setPadding(5, 7, 5, 7)
        }
        root.addView(status)
        list = ListView(this).apply {
            setBackgroundColor(Color.rgb(15, 35, 54))
            setOnItemClickListener { _, _, position, _ ->
                val filtered = filteredChannels()
                filtered.getOrNull(position)?.let { play(it) }
            }
        }
        root.addView(list, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f))
        setContentView(root)
        refreshList()
    }

    private fun actionButton(label: String, action: () -> Unit) = Button(this).apply {
        text = label
        textSize = 11f
        setTextColor(Color.WHITE)
        setBackgroundColor(Color.rgb(23, 91, 145))
        setPadding(5, 2, 5, 2)
        setOnClickListener { action() }
    }

    private fun filteredChannels(): List<Channel> {
        val query = if (::search.isInitialized) search.text.toString().trim().lowercase() else ""
        return channels.filter { c ->
            (!showingFavorites || favorites.contains(c.url)) &&
            (selectedType == "Todos" || c.type.equals(selectedType, true)) &&
            (query.isBlank() || (c.name + " " + c.group).lowercase().contains(query))
        }
    }

    private fun refreshList() {
        if (!::list.isInitialized) return
        val rows = filteredChannels()
        list.adapter = ArrayAdapter(this, android.R.layout.simple_list_item_1,
            rows.map { (if (favorites.contains(it.url)) "★ " else "") + "[${it.type}] ${it.group} — ${it.name}" })
        status.text = "${rows.size} conteúdos apresentados · ${channels.size} guardados neste dispositivo"
    }

    private fun loadM3u(uri: Uri) {
        try {
            val text = contentResolver.openInputStream(uri)?.bufferedReader()?.use { it.readText() } ?: ""
            parseM3u(text)
        } catch (e: Exception) { toast("Não foi possível abrir a lista: ${e.message}") }
    }

    private fun parseM3u(text: String) {
        channels.clear()
        var name = "Canal"; var group = "Geral"; var type = "TV"
        text.lineSequence().forEach { raw ->
            val line = raw.trim()
            if (line.startsWith("#EXTINF", true)) {
                name = line.substringAfterLast(",").trim().ifBlank { "Canal" }
                group = Regex("group-title=\\"([^\\"]*)\\"").find(line)?.groupValues?.get(1) ?: "Geral"
                type = when {
                    Regex("filme|movie|vod", RegexOption.IGNORE_CASE).containsMatchIn(group) -> "Filmes"
                    Regex("s[eé]rie|series|epis[oó]dio", RegexOption.IGNORE_CASE).containsMatchIn(group) -> "Séries"
                    else -> "TV"
                }
            } else if (line.isNotBlank() && !line.startsWith("#") &&
                (line.startsWith("http://") || line.startsWith("https://"))) {
                channels.add(Channel(name, line, group, type))
                name = "Canal"; group = "Geral"; type = "TV"
            }
        }
        saveChannels()
        refreshList()
        toast("Lista carregada e guardada: ${channels.size} conteúdos")
    }

    private fun loadSaved() {
        try {
            val raw = prefs.getString("channels", "[]") ?: "[]"
            val arr = JSONArray(raw)
            for (i in 0 until arr.length()) {
                val o = arr.getJSONObject(i)
                channels.add(Channel(o.optString("name"), o.optString("url"), o.optString("group"), o.optString("type", "TV")))
            }
            val fav = JSONArray(prefs.getString("favorites", "[]") ?: "[]")
            for (i in 0 until fav.length()) favorites.add(fav.getString(i))
        } catch (_: Exception) { channels.clear() }
    }

    private fun saveChannels() {
        val arr = JSONArray()
        channels.forEach { c -> arr.put(JSONObject().put("name", c.name).put("url", c.url).put("group", c.group).put("type", c.type)) }
        val fav = JSONArray()
        favorites.forEach { fav.put(it) }
        prefs.edit().putString("channels", arr.toString()).putString("favorites", fav.toString()).apply()
    }

    private fun showXtreamDialog() {
        val box = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setPadding(24, 8, 24, 8) }
        val server = EditText(this).apply { hint = "Servidor (https://...)"; setSingleLine() }
        val user = EditText(this).apply { hint = "Utilizador"; setSingleLine() }
        val pass = EditText(this).apply { hint = "Palavra-passe"; setSingleLine(); inputType = 129 }
        box.addView(server); box.addView(user); box.addView(pass)
        AlertDialog.Builder(this).setTitle("Ligação Xtream Codes").setView(box)
            .setPositiveButton("Carregar canais") { _, _ ->
                val base = server.text.toString().trim().trimEnd('/')
                val u = Uri.encode(user.text.toString()); val p = Uri.encode(pass.text.toString())
                if (!base.startsWith("http") || u.isBlank() || p.isBlank()) {
                    toast("Confirma servidor, utilizador e palavra-passe"); return@setPositiveButton
                }
                Thread {
                    try {
                        val url = java.net.URL("$base/player_api.php?username=$u&password=$p&action=get_live_streams")
                        val conn = url.openConnection()
                        conn.connectTimeout = 15000; conn.readTimeout = 20000
                        val data = conn.getInputStream().bufferedReader().use { it.readText() }
                        val arr = JSONArray(data)
                        val loaded = mutableListOf<Channel>()
                        for (i in 0 until arr.length()) {
                            val item = arr.getJSONObject(i)
                            val id = item.optString("stream_id")
                            val ext = item.optString("container_extension", "ts")
                            loaded.add(Channel(item.optString("name", "Canal"), "$base/live/$u/$p/$id.$ext", item.optString("category_name", "TV"), "TV"))
                        }
                        runOnUiThread {
                            channels.clear(); channels.addAll(loaded); saveChannels(); refreshList()
                            toast("Canais carregados e guardados: ${channels.size}")
                        }
                    } catch (e: Exception) { runOnUiThread { toast("Falha na ligação: ${e.message}") } }
                }.start()
            }.setNegativeButton("Cancelar", null).show()
    }

    private fun showBiography() {
        val web = WebView(this)
        web.settings.javaScriptEnabled = false
        web.loadUrl("https://faztudoemangolaonline-dev.github.io/index.html/#criador-ananias")
        AlertDialog.Builder(this).setTitle("Sobre o Criador").setView(web)
            .setPositiveButton("Fechar", null).show()
    }

    private fun play(channel: Channel) {
        try {
            if (player == null) {
                player = ExoPlayer.Builder(this).build()
                playerView.player = player
            }
            player?.setMediaItem(MediaItem.fromUri(channel.url))
            player?.prepare(); player?.play()
            if (!favorites.contains(channel.url)) {
                // Favorites are changed only by the dedicated long-press action.
            }
            list.setOnItemLongClickListener { _, _, position, _ ->
                val item = filteredChannels().getOrNull(position) ?: return@setOnItemLongClickListener true
                if (favorites.contains(item.url)) favorites.remove(item.url) else favorites.add(item.url)
                saveChannels(); refreshList()
                toast(if (favorites.contains(item.url)) "Adicionado aos favoritos" else "Removido dos favoritos")
                true
            }
        } catch (e: Exception) { toast("Não foi possível reproduzir: ${e.message}") }
    }

    private fun toast(message: String) = Toast.makeText(this, message, Toast.LENGTH_LONG).show()

    override fun onStop() { super.onStop(); player?.release(); player = null }
}

private class SimpleTextWatcher(val changed: () -> Unit) : android.text.TextWatcher {
    override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
    override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) { changed() }
    override fun afterTextChanged(s: android.text.Editable?) {}
}
