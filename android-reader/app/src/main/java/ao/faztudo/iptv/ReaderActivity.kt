package ao.faztudo.iptv

import android.app.Activity
import android.os.Bundle
import android.graphics.Color
import android.widget.*
import android.view.Gravity
import android.view.View
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
    private val tvMode by lazy { packageManager.hasSystemFeature(android.content.pm.PackageManager.FEATURE_LEANBACK) }
    private val favorites = mutableSetOf<String>()
    private var showFavoritesOnly = false
    private var currentUrl = ""
    private var token = ""
    private lateinit var page: LinearLayout
    private lateinit var message: TextView
    private lateinit var email: EditText
    private lateinit var pass: EditText
    private lateinit var key: EditText
    private lateinit var video: PlayerView
    private var exo: ExoPlayer? = null
    private val items = mutableListOf<Pair<String,String>>()
    private var currentIndex = -1

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.statusBarColor = Color.BLACK
        window.navigationBarColor = Color.BLACK
        if (tvMode) {
            window.setFlags(android.view.WindowManager.LayoutParams.FLAG_FULLSCREEN, android.view.WindowManager.LayoutParams.FLAG_FULLSCREEN)
            window.decorView.systemUiVisibility = (View.SYSTEM_UI_FLAG_FULLSCREEN or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY)
        }
        loginScreen()
    }

    private fun layout(title: String) {
        page = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            val pad = if (tvMode) 32 else 16
            setPadding(pad,pad,pad,pad)
            setBackgroundColor(Color.rgb(20,20,20))
        }
        page.addView(TextView(this).apply {
            text = title; textSize = if (tvMode) 32f else 24f; gravity = Gravity.CENTER
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
            if (tvMode) { textSize = 20f; minHeight = 58 }
            if (secret) inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_PASSWORD
        }
        page.addView(v)
        return v
    }

    private fun button(label: String, run: () -> Unit) {
        page.addView(Button(this).apply {
            text = label
            isFocusable = true
            if (tvMode) { textSize = 18f; minHeight = 58 }
            setOnClickListener { run() }
        })
    }

    private fun loginScreen() {
        layout("FAZ TUDO IPTV")
        page.addView(TextView(this).apply {
            text = if (tvMode) "EDIÇÃO ANDROID TV • Use as setas e OK do comando" else "Leitor Android independente • listas M3U/M3U8"
            setTextColor(Color.LTGRAY); textSize = if (tvMode) 18f else 14f
        })
        email = input("E-mail da conta do site")
        pass = input("Palavra-passe", true)
        key = input("UUID do leitor autorizado")
        button("ENTRAR E VALIDAR ACESSO") { login() }
        message.text = "A subscrição é validada pelo Supabase antes de abrir a lista."
        authorBio()
    }

    private fun authorBio() {
        page.addView(TextView(this).apply {
            text = "SOBRE O AUTOR"
            textSize = 20f
            setTextColor(Color.rgb(255, 202, 40))
            setPadding(4, 24, 4, 8)
        })
        val paragraphs = listOf(
            "Ananias Barroso Pedro é um jovem angolano, natural da província de Malanje e residente em Luanda. Apaixonado por tecnologia, é técnico de informática, estudante do curso de Gestão de Recursos Humanos e dedica-se também ao desenvolvimento e à criação de sistemas informáticos.",
            "Desde pequeno, encontrou na leitura, na aprendizagem e no ensino fontes de inspiração. Gosta de descobrir coisas novas, aprofundar conhecimentos e partilhar aquilo que aprende. Considera que o conhecimento ganha ainda mais valor quando é colocado ao serviço das pessoas e da comunidade.",
            "Sonhador, trabalhador e determinado, ambiciona crescer no mundo da ciência e da inovação e tornar-se uma referência pelo positivismo, pela atitude construtiva e pelo contributo que deixa na vida dos outros. Acredita que os grandes resultados começam com curiosidade, disciplina, persistência e coragem para transformar ideias em realidade.",
            "Foi com esse espírito que nasceu o Faz Tudo Tecnologia: um projecto pensado para aproximar as pessoas do conhecimento geral e da aprendizagem, facilitar o acesso a soluções tecnológicas e mostrar como a tecnologia pode ser uma ferramenta útil no quotidiano. A intenção é criar um espaço onde as pessoas possam descobrir, aprender, encontrar serviços e desenvolver novas capacidades.",
            "Mais do que construir um site, Ananias pretende desenvolver uma plataforma de utilidade pública, feita com dedicação e amor pela tecnologia, que incentive a partilha de conhecimento, a criatividade, o empreendedorismo e a evolução contínua."
        )
        paragraphs.forEach { paragraph ->
            page.addView(TextView(this).apply {
                text = paragraph
                textSize = 14f
                setTextColor(Color.LTGRAY)
                setPadding(4, 5, 4, 5)
            })
        }
        page.addView(TextView(this).apply {
            text = "“Aprender sempre, ensinar com humildade e usar o conhecimento para fazer o bem.”"
            textSize = 15f
            setTextColor(Color.rgb(255, 202, 40))
            setPadding(4, 12, 4, 20)
        })
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
        video.useController = true
        page.addView(video, LinearLayout.LayoutParams(-1, if (tvMode) 320 else 220))
        button("TODOS OS CANAIS / FAVORITOS") { showFavoritesOnly = !showFavoritesOnly; showItems() }
        button("CANAL ANTERIOR") { moveChannel(-1) }
        button("CANAL SEGUINTE") { moveChannel(1) }
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
        val shown = items.filter { !showFavoritesOnly || favorites.contains(it.second) }
        message.text = "Canais: ${items.size} • Favoritos: ${favorites.size}" + if (showFavoritesOnly) " • filtro activo" else ""
        shown.forEach { item ->
            page.addView(Button(this).apply {
                text = (if (favorites.contains(item.second)) "★  " else "") + item.first
                isFocusable = true
                if (tvMode) { textSize = 19f; minHeight = 62 }
                setOnClickListener {
                    currentIndex = items.indexOf(item)
                    play(item.second,item.first)
                }
                setOnLongClickListener {
                    if (!favorites.add(item.second)) favorites.remove(item.second)
                    showItems()
                    true
                }
            })
        }
    }

    private fun moveChannel(step: Int) {
        if (items.isEmpty()) return
        currentIndex = (currentIndex + step).coerceIn(0, items.lastIndex)
        val item = items[currentIndex]
        play(item.second, item.first)
    }

    private fun play(url: String, title: String) {
        currentUrl = url
        message.text = "A reproduzir: $title"
        if (exo == null) { exo = ExoPlayer.Builder(this).build(); video.player = exo }
        exo?.setMediaItem(MediaItem.fromUri(url)); exo?.prepare(); exo?.play()
    }

    override fun onDestroy() { exo?.release(); exo = null; super.onDestroy() }
}
