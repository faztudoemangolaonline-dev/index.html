package ao.faztudo.iptv;

import android.app.*;
import android.os.*;
import android.graphics.Color;
import android.view.*;
import android.view.inputmethod.InputMethodManager;
import android.content.Context;
import android.widget.*;
import android.text.InputType;
import androidx.appcompat.app.AppCompatActivity;
import androidx.media3.common.MediaItem;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.ui.PlayerView;
import org.json.*;
import java.net.*;
import java.io.*;
import java.util.*;
import java.util.concurrent.*;

public class MainActivity extends AppCompatActivity {
    private final ExecutorService worker = Executors.newSingleThreadExecutor();
    private final ArrayList<Channel> channels = new ArrayList<>();
    private LinearLayout root, listBox;
    private EditText server, username, password, playlistUrl;
    private PlayerView playerView;
    private ExoPlayer player;
    private TextView status;
    private static class Channel {
        String name, url, group;
        Channel(String n, String u, String g) { name=n; url=u; group=g; }
    }

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        getWindow().setStatusBarColor(Color.rgb(16,16,16));
        getWindow().setNavigationBarColor(Color.rgb(16,16,16));
        showWelcome();
        new Handler().postDelayed(this::showHome, 2200);
    }

    private void showWelcome() {
        TextView welcome = new TextView(this);
        welcome.setText("Seja Bem vindo a Faztudo Ananias inovação");
        welcome.setTextColor(Color.WHITE); welcome.setTextSize(25);
        welcome.setGravity(Gravity.CENTER); welcome.setBackgroundColor(Color.rgb(16,16,16));
        setContentView(welcome);
    }

    private TextView text(String value, int size) {
        TextView t = new TextView(this); t.setText(value); t.setTextColor(Color.WHITE);
        t.setTextSize(size); t.setPadding(12,10,12,10); return t;
    }
    private EditText field(String hint, boolean url) {
        EditText e = new EditText(this); e.setSingleLine(true); e.setHint(hint);
        e.setHintTextColor(Color.LTGRAY); e.setTextColor(Color.WHITE);
        e.setPadding(14,10,14,10); e.setBackgroundTintList(android.content.res.ColorStateList.valueOf(Color.GRAY));
        if(url) e.setInputType(InputType.TYPE_TEXT_VARIATION_URI);
        return e;
    }
    private Button button(String label, Runnable action) {
        Button b = new Button(this); b.setText(label); b.setTextColor(Color.WHITE);
        b.setBackgroundTintList(android.content.res.ColorStateList.valueOf(Color.rgb(190,20,35)));
        b.setOnClickListener(v -> action.run()); return b;
    }
    private void showHome() {
        root = new LinearLayout(this); root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(14,8,14,8); root.setBackgroundColor(Color.rgb(16,16,16));
        ScrollView scroll = new ScrollView(this);
        LinearLayout content = new LinearLayout(this); content.setOrientation(LinearLayout.VERTICAL);
        TextView title=text("FAZ TUDO IPTV",24); title.setGravity(Gravity.CENTER);
        title.setTextColor(Color.rgb(225,25,40)); content.addView(title);
        content.addView(text("Entre com Xtream Codes",17));
        server=field("URL do servidor (ex.: https://servidor.com)",true);
        username=field("Utilizador",false);
        password=field("Palavra-passe",false); password.setInputType(InputType.TYPE_CLASS_TEXT|InputType.TYPE_TEXT_VARIATION_PASSWORD);
        content.addView(server); content.addView(username); content.addView(password);
        content.addView(button("LIGAR À CONTA XTREAM",this::connectXtream));
        content.addView(text("Ou carregar uma lista M3U / M3U8",17));
        playlistUrl=field("URL da lista M3U/M3U8",true); content.addView(playlistUrl);
        content.addView(button("CARREGAR LISTA",this::loadM3u));
        status=text("Pronto para ligar. Usa apenas listas e serviços autorizados.",13); content.addView(status);
        playerView=new PlayerView(this); playerView.setUseController(true);
        content.addView(playerView,new LinearLayout.LayoutParams(-1,420));
        content.addView(text("CANAIS",19));
        listBox=new LinearLayout(this); listBox.setOrientation(LinearLayout.VERTICAL); content.addView(listBox);
        scroll.addView(content); root.addView(scroll); setContentView(root);
    }
    private void report(String msg) { runOnUiThread(() -> status.setText(msg)); }
    private String cleanServer(String s) { s=s.trim(); while(s.endsWith("/")) s=s.substring(0,s.length()-1); return s; }
    private void connectXtream() {
        String base=cleanServer(server.getText().toString()), user=username.getText().toString().trim(), pass=password.getText().toString();
        if(base.isEmpty()||user.isEmpty()||pass.isEmpty()){ report("Preenche servidor, utilizador e palavra-passe."); return; }
        report("A autenticar e a procurar canais...");
        worker.execute(() -> {
            try {
                String api=base+"/player_api.php?username="+enc(user)+"&password="+enc(pass)+"&action=get_live_streams";
                JSONArray arr=new JSONArray(readUrl(api));
                ArrayList<Channel> found=new ArrayList<>();
                for(int i=0;i<arr.length();i++){
                    JSONObject o=arr.getJSONObject(i);
                    String id=o.optString("stream_id","");
                    String name=o.optString("name","Canal "+id);
                    String group=o.optString("category_name","Geral");
                    if(!id.isEmpty()) found.add(new Channel(name,base+"/live/"+enc(user)+"/"+enc(pass)+"/"+id+".ts",group));
                }
                runOnUiThread(() -> showChannels(found,"Xtream: "+found.size()+" canais carregados."));
            } catch(Exception ex){ report("Falha Xtream: "+ex.getMessage()); }
        });
    }
    private void loadM3u() {
        String url=playlistUrl.getText().toString().trim();
        if(url.isEmpty()){report("Introduz o endereço da lista M3U.");return;}
        report("A descarregar e interpretar a lista...");
        worker.execute(() -> {
            try {
                String data=readUrl(url); ArrayList<Channel> found=parseM3u(data);
                runOnUiThread(() -> showChannels(found,"M3U: "+found.size()+" entradas carregadas."));
            } catch(Exception ex){report("Falha ao carregar M3U: "+ex.getMessage());}
        });
    }
    private ArrayList<Channel> parseM3u(String data) {
        ArrayList<Channel> out=new ArrayList<>(); String name="Canal", group="Geral";
        for(String raw:data.split("\\r?\\n")){
            String line=raw.trim();
            if(line.startsWith("#EXTINF")){
                int comma=line.lastIndexOf(',');
                name=comma>=0?line.substring(comma+1).trim():"Canal";
                int g=line.indexOf("group-title=\"");
                if(g>=0){int end=line.indexOf('"',g+13); if(end>g) group=line.substring(g+13,end);}
            } else if(!line.isEmpty()&&!line.startsWith("#")&&(line.startsWith("http://")||line.startsWith("https://"))){
                out.add(new Channel(name,line,group)); name="Canal"; group="Geral";
            }
        }
        return out;
    }
    private void showChannels(ArrayList<Channel> found,String message) {
        channels.clear(); channels.addAll(found); listBox.removeAllViews(); status.setText(message);
        String last="";
        for(Channel c:channels){
            if(!c.group.equals(last)){ TextView heading=text(c.group.toUpperCase(),14); heading.setTextColor(Color.rgb(230,45,45)); listBox.addView(heading); last=c.group; }
            Button item=button(c.name,()->{}); item.setOnClickListener(v->play(c)); listBox.addView(item);
        }
        if(channels.isEmpty()) status.setText("Nenhum canal encontrado. Verifica a lista ou os dados de acesso.");
    }
    private void play(Channel c) {
        try {
            if(player==null){player=new ExoPlayer.Builder(this).build();playerView.setPlayer(player);}
            player.setMediaItem(MediaItem.fromUri(c.url)); player.prepare(); player.play();
            status.setText("A reproduzir: "+c.name);
        } catch(Exception ex){status.setText("Erro de reprodução: "+ex.getMessage());}
    }
    private String readUrl(String address) throws Exception {
        HttpURLConnection c=(HttpURLConnection)new URL(address).openConnection();
        c.setConnectTimeout(15000); c.setReadTimeout(30000); c.setRequestProperty("User-Agent","FazTudoIPTV/1.0");
        try(InputStream in=c.getInputStream(); ByteArrayOutputStream out=new ByteArrayOutputStream()){
            byte[] buf=new byte[8192]; int n; while((n=in.read(buf))!=-1){out.write(buf,0,n); if(out.size()>25*1024*1024) throw new IOException("Lista demasiado grande (limite 25 MB)");}
            return out.toString("UTF-8");
        } finally { c.disconnect(); }
    }
    private String enc(String s) throws Exception { return java.net.URLEncoder.encode(s,"UTF-8"); }
    @Override protected void onStop(){ super.onStop(); if(player!=null) player.pause(); }
    @Override protected void onDestroy(){ super.onDestroy(); if(player!=null) player.release(); worker.shutdownNow(); }
}
