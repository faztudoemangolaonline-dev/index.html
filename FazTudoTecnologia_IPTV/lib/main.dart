import 'dart:async';
import 'dart:convert';
import 'dart:io' show gzip;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'iptv_core.dart';

String decodeIptvText(List<int> bytes) {
  if(bytes.length>2 && bytes[0]==0x1f && bytes[1]==0x8b) {
    return utf8.decode(gzip.decode(bytes),allowMalformed:true);
  }
  return utf8.decode(bytes,allowMalformed:true);
}

String? mediaStartupError;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // A falha ao carregar o motor multimédia não pode impedir a interface de abrir.
  try {
    MediaKit.ensureInitialized();
  } catch (e) {
    mediaStartupError = e.toString();
  }
  runApp(const FazTudoApp());
}

class _BrandMark extends StatelessWidget {
  final double size;
  const _BrandMark({this.size = 42});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xffe51b2b), Color(0xff8d1019), Color(0xff17191e)]),
      borderRadius: BorderRadius.circular(size * .27),
      border: Border.all(color: const Color(0xffffc928), width: size * .018),
      boxShadow: const [BoxShadow(color: Color(0x558d1019), blurRadius: 13, offset: Offset(0, 5))],
    ),
    child: Stack(alignment: Alignment.center, children: [
      Icon(Icons.tv_rounded, size: size * .66, color: Colors.white),
      Positioned(right: size*.16, bottom: size*.18,
        child: Icon(Icons.play_arrow_rounded, size: size*.34, color: const Color(0xffffc928))),
    ]),
  );
}

class FazTudoApp extends StatelessWidget {
  const FazTudoApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Faz Tudo Tecnologia IPTV',
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(useMaterial3: true).copyWith(
      colorScheme: const ColorScheme.dark(
        primary: Color(0xffd71920), secondary: Color(0xffffc928),
        surface: Color(0xff17191e), onPrimary: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xff090a0d),
      cardTheme: CardThemeData(
        color: const Color(0xff15171c), elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xff292c33))),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xff101115), foregroundColor: Colors.white,
        centerTitle: false, elevation: 0, scrolledUnderElevation: 0,
      ),
      dividerColor: const Color(0xff292c33),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: const Color(0xff1b1d23),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xff343740))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xff343740))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xffd71920), width: 1.5)),
      ),
      chipTheme: ThemeData.dark().chipTheme.copyWith(
        selectedColor: const Color(0xff9f151c), backgroundColor: const Color(0xff202228),
        side: const BorderSide(color: Color(0xff343740)),
        labelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      )),
    home: const WelcomeScreen());
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}
class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    SystemSound.play(SystemSoundType.alert);
    Timer(const Duration(seconds: 4), () {
      if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    });
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff090a0d),
    body: Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xff191116), Color(0xff090a0d), Color(0xff111216)]),
      ),
      child: Center(child: Padding(padding: const EdgeInsets.all(26), child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
          const _BrandMark(size: 112),
          const SizedBox(height: 25),
          const Text('FAZ TUDO', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900,
            letterSpacing: 2, color: Colors.white)),
          const Text('IPTV', style: TextStyle(fontSize: 39, height: 1.0,
            fontWeight: FontWeight.w900, letterSpacing: 3, color: Color(0xffffc928))),
          const SizedBox(height: 10),
          Container(width: 54, height: 3, decoration: BoxDecoration(
            color: const Color(0xffd71920), borderRadius: BorderRadius.circular(3))),
          const SizedBox(height: 22),
          const Text('Seja Bem vindo a Faz Tudo do Ananias',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white70),
            textAlign: TextAlign.center),
          const SizedBox(height: 28),
          const SizedBox(width: 22, height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xffffc928)))
        ]))),
    );
}

class Playlist {
  final String name, type, server, username, password, epgUrl;
  const Playlist(this.name, this.type, this.server, {this.username = '', this.password = '', this.epgUrl = ''});
  Map<String,dynamic> toJson() => {'name':name,'type':type,'server':server,'username':username,'password':password,'epgUrl':epgUrl};
  factory Playlist.fromJson(Map<String,dynamic> j) => Playlist(
    j['name'] ?? 'Lista', j['type'] ?? 'm3u', j['server'] ?? '',
    username:j['username'] ?? '', password:j['password'] ?? '', epgUrl:j['epgUrl'] ?? '');
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  final Player player = Player();
  late final VideoController video = VideoController(player);
  final search = TextEditingController();
  final XtreamService xtream = XtreamService();
  List<Playlist> playlists = [];
  List<IptvItem> channels = [], visible = [], episodes = [];
  final Set<String> favorites = {};
  final Set<String> hiddenCategories = {};
  List<EpgProgramme> epg = [];
  IptvItem? current;
  XtreamAccount? activeAccount;
  Playlist? activePlaylist;
  String status = 'Adiciona uma lista M3U/M3U8 ou uma conta Xtream Codes.';
  String group = 'Todos', section = 'live';
  bool loading = false, onlyFavorites = false, miniPlayer = false;
  String quality = 'Todos';
  String? pin, resumeItemId, resumePlaylistName;

  @override
  void initState() { super.initState(); restore(); }
  @override
  void dispose() { search.dispose(); player.dispose(); super.dispose(); }

  Future<void> restore() async {
    final p = await SharedPreferences.getInstance();
    try {
      final a = jsonDecode(p.getString('iptv_lists') ?? '[]') as List;
      final fav = jsonDecode(p.getString('iptv_favorites') ?? '[]') as List;
      if(!mounted)return;
      setState(() {
        playlists = a.map((e) => Playlist.fromJson(Map<String,dynamic>.from(e))).toList();
        favorites.addAll(fav.cast<String>());
        pin=p.getString('iptv_parental_pin');
        hiddenCategories.addAll((jsonDecode(p.getString('iptv_hidden_categories')??'[]') as List).cast<String>());
        resumeItemId=p.getString('iptv_last_item_id');
        resumePlaylistName=p.getString('iptv_last_playlist');
      });
      if(resumePlaylistName!=null){
        final saved=playlists.where((e)=>e.name==resumePlaylistName).toList();
        if(saved.isNotEmpty) await load(saved.first);
      }
    } catch (_) {}
  }
  Future<void> persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('iptv_lists', jsonEncode(playlists.map((e)=>e.toJson()).toList()));
    await p.setString('iptv_favorites', jsonEncode(favorites.toList()));
    await p.setString('iptv_hidden_categories', jsonEncode(hiddenCategories.toList()));
  }

  Future<void> addM3u() async {
    final n=TextEditingController(text:'Minha lista');
    final u=TextEditingController();
    final e=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
      title:const Text('Adicionar lista M3U/M3U8'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:n,decoration:const InputDecoration(labelText:'Nome da lista')),
        TextField(controller:u,keyboardType:TextInputType.url,decoration:const InputDecoration(labelText:'URL M3U/M3U8')),
        TextField(controller:e,keyboardType:TextInputType.url,decoration:const InputDecoration(labelText:'URL EPG XMLTV (opcional)'))])),
      actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancelar')),
        FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Guardar'))]));
    if(ok==true && u.text.trim().isNotEmpty){
      final p=Playlist(n.text.trim().isEmpty?'Lista M3U':n.text.trim(),'m3u',u.text.trim(),epgUrl:e.text.trim());
      setState(()=>playlists.add(p)); await persist(); await load(p);
    }
  }

  Future<void> importLocalM3u() async {
    try {
      final result=await FilePicker.platform.pickFiles(
        type:FileType.custom,allowedExtensions:['m3u','m3u8','txt','gz'],withData:true);
      if(result==null||result.files.isEmpty)return;
      final file=result.files.single;
      final bytes=file.bytes;
      if(bytes==null)throw Exception('Não foi possível ler o ficheiro escolhido.');
      final text=decodeIptvText(bytes);
      final parsed=M3uParser.parse(text);
      if(parsed.isEmpty)throw Exception('Não encontrei endereços de canais válidos neste ficheiro.');
      setState(() {
        activePlaylist=Playlist(file.name,'local','');
        activeAccount=null; channels=parsed; section='live'; group='Todos';
        current=null; status='Ficheiro local carregado: ${parsed.length} itens.';
      });
      filter('');
    } catch(e) { if(mounted)showMessage('Importação falhou: $e'); }
  }

  Future<void> addDirectStream() async {
    final name=TextEditingController(text:'Stream directo');
    final url=TextEditingController();
    final agent=TextEditingController();
    final referer=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
      title:const Text('Abrir endereço de vídeo'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:name,decoration:const InputDecoration(labelText:'Nome')),
        TextField(controller:url,keyboardType:TextInputType.url,decoration:const InputDecoration(labelText:'URL HLS / DASH / MP4 / RTSP')),
        TextField(controller:agent,decoration:const InputDecoration(labelText:'User-Agent (opcional)')),
        TextField(controller:referer,decoration:const InputDecoration(labelText:'Referer (opcional)')),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancelar')),
        FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Abrir'))]));
    if(ok!=true)return;
    final value=url.text.trim();
    final uri=Uri.tryParse(value);
    if(uri==null||!uri.hasScheme){showMessage('Indica um endereço completo com http://, https:// ou rtsp://.');return;}
    final headers=<String,String>{};
    if(agent.text.trim().isNotEmpty)headers['User-Agent']=agent.text.trim();
    if(referer.text.trim().isNotEmpty)headers['Referer']=referer.text.trim();
    final item=IptvItem(id:value,name:name.text.trim().isEmpty?'Stream directo':name.text.trim(),
      url:value,headers:headers);
    setState(() { channels=[...channels,item]; section='live'; group='Todos'; });
    filter(search.text);
    await play(item);
  }

  Future<void> addXtream() async {
    final n=TextEditingController(text:'Minha conta');
    final h=TextEditingController(), u=TextEditingController(), p=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
      title:const Text('Adicionar Xtream Codes'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:n,decoration:const InputDecoration(labelText:'Nome da conta')),
        TextField(controller:h,keyboardType:TextInputType.url,decoration:const InputDecoration(labelText:'Servidor / DNS com porta')),
        TextField(controller:u,decoration:const InputDecoration(labelText:'Utilizador')),
        TextField(controller:p,obscureText:true,decoration:const InputDecoration(labelText:'Palavra-passe'))])),
      actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancelar')),
        FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Ligar'))]));
    if(ok==true && h.text.trim().isNotEmpty && u.text.isNotEmpty && p.text.isNotEmpty){
      var host=h.text.trim().replaceAll(RegExp(r'/+$'),'');
      if(!host.startsWith('http://')&&!host.startsWith('https://'))host='http://$host';
      final pl=Playlist(n.text.trim().isEmpty?'Xtream':n.text.trim(),'xtream',host,username:u.text.trim(),password:p.text);
      setState(()=>playlists.add(pl)); await persist(); await load(pl);
    }
  }

  Future<void> load(Playlist p) async {
    setState((){loading=true;status='A testar e carregar '+p.name+'...';channels=[];visible=[];episodes=[];current=null;activePlaylist=p;group='Todos';});
    try {
      List<IptvItem> result=[];
      if(p.type=='m3u'){
        final uri=Uri.parse(p.server);
        final r=await http.get(uri,headers:{'Accept':'*/*','User-Agent':'FazTudoIPTV/1.1'}).timeout(const Duration(seconds:45));
        if(r.statusCode<200||r.statusCode>=300) throw Exception('HTTP ${r.statusCode}. O servidor recusou a lista.');
        result=M3uParser.parse(decodeIptvText(r.bodyBytes),baseUrl:p.server);
        if(p.epgUrl.isNotEmpty)await loadEpg(p.epgUrl);
        activeAccount=null;
      } else {
        final account=XtreamAccount(p.server,p.username,p.password);
        final info=await xtream.accountInfo(account);
        final auth=info['user_info'];
        if(auth is Map && auth['auth']!=null && auth['auth'].toString()=='0')throw Exception('Utilizador ou palavra-passe rejeitados pelo servidor.');
        activeAccount=account;
        final lists=await Future.wait([
          xtream.loadLive(account).catchError((_) => <IptvItem>[]),
          xtream.loadMovies(account).catchError((_) => <IptvItem>[]),
          xtream.loadSeries(account).catchError((_) => <IptvItem>[]),
        ]);
        result=[...lists[0],...lists[1],...lists[2]];
        final epgUrl='${p.server}/xmltv.php?username=${Uri.encodeQueryComponent(p.username)}&password=${Uri.encodeQueryComponent(p.password)}';
        try{await loadEpg(epgUrl);}catch(_){epg=[];}
      }
      if(result.isEmpty)throw Exception('O endereço respondeu, mas não entregou itens M3U/Xtream reconhecíveis. Verifica o formato e as credenciais.');
      if(!mounted)return;
      setState((){channels=result;section='live';status='${result.length} itens encontrados: ${result.where((e)=>e.kind=='live').length} TV • ${result.where((e)=>e.kind=='movie').length} filmes • ${result.where((e)=>e.kind=='series').length} séries.';});
      filter(search.text);
      final savedId=resumeItemId;
      if(savedId!=null){
        final previous=result.where((e)=>e.id==savedId||e.url==savedId).toList();
        if(previous.isNotEmpty){resumeItemId=null;await play(previous.first);}
      }
    } catch(e){if(mounted)setState(()=>status='Não foi possível carregar: ${e.toString()}');}
    finally{if(mounted)setState(()=>loading=false);}
  }

  Future<void> loadEpg(String url) async {
    final r=await http.get(Uri.parse(url),headers:{'User-Agent':'FazTudoIPTV/1.1'}).timeout(const Duration(seconds:45));
    if(r.statusCode<200||r.statusCode>=300)throw Exception('EPG HTTP ${r.statusCode}');
    final parsed=XmltvParser.parse(utf8.decode(r.bodyBytes,allowMalformed:true));
    if(mounted)setState(()=>epg=parsed);
  }

  Future<void> loadSection(String kind) async {
    if(kind=='all'){
      setState(() { section='all'; group='Todos'; });
      filter(search.text,source:channels);
      return;
    }
    if(kind=='episode' && episodes.isNotEmpty){
      setState(()=>section='episode');
      filter(search.text,source:episodes);
      return;
    }
    if(activeAccount==null){setState(()=>section=kind);filter(search.text);return;}
    setState(()=>loading=true);
    try{
      final account=activeAccount!;
      final items=kind=='live'?await xtream.loadLive(account):kind=='movie'?await xtream.loadMovies(account):await xtream.loadSeries(account);
      setState(()=>section=kind);
      filter(search.text,source:items);
      setState(()=>status='${items.length} itens nesta secção.');
    }catch(e){showMessage('Erro ao abrir secção: $e');}
    finally{if(mounted)setState(()=>loading=false);}
  }

  void filter(String q,{List<IptvItem>? source}) {
    final data=source??(section=='episode'?episodes:channels);
    final kindMatches=(IptvItem e)=>section=='all'||e.kind==section||(section=='live'&&e.kind=='live');
    final v=data.where((e)=>kindMatches(e) && (group=='Todos'||e.category==group) &&
      !hiddenCategories.contains(e.category) && e.name.toLowerCase().contains(q.toLowerCase()) &&
      (quality=='Todos'||qualityOf(e)==quality) && (!onlyFavorites||favorites.contains(e.id))).toList();
    if(mounted)setState(()=>visible=v);
  }
  List<String> get groups=>['Todos',...(section=='episode'?episodes:channels).where((e)=>section=='all'||section=='episode'||e.kind==section||(section=='live'&&e.kind=='live')).map((e)=>e.category).toSet().toList()..sort()];

  String qualityOf(IptvItem item){
    final value=item.name.toLowerCase()+' '+item.url.toLowerCase();
    if(RegExp(r'\b(2160p|4k|uhd|1080p|fhd|full.?hd)\b').hasMatch(value))return 'Full HD';
    if(RegExp(r'\b(720p|hd)\b').hasMatch(value))return 'HD';
    if(RegExp(r'\b(576p|480p|360p|sd)\b').hasMatch(value))return 'SD';
    return 'Não identificado';
  }

  Future<void> toggleFavorite(IptvItem e) async {
    setState(()=>favorites.contains(e.id)?favorites.remove(e.id):favorites.add(e.id));
    await persist(); filter(search.text);
  }

  Future<void> play(IptvItem e) async {
    if(e.kind=='series'){
      if(activeAccount==null){showMessage('Este item é uma série, mas a lista M3U não disponibilizou temporadas/episódios separados.');return;}
      setState(()=>loading=true);
      try{
        episodes=await xtream.loadEpisodes(activeAccount!,e.id);
        if(episodes.isEmpty)throw Exception('O servidor não devolveu episódios para esta série.');
        setState(()=>section='episode');
        setState(()=>visible=episodes);
        showMessage('${episodes.length} episódios carregados: ${e.name}');
      }catch(err){showMessage('Falha ao carregar episódios: $err');}
      finally{if(mounted)setState(()=>loading=false);}
      return;
    }
    setState(() { current=e; status='A abrir ${e.name}...'; });
    final prefs=await SharedPreferences.getInstance();
    await prefs.setString('iptv_last_item_id',e.id);
    if(activePlaylist!=null)await prefs.setString('iptv_last_playlist',activePlaylist!.name);
    try {
      await player.open(Media(e.url,httpHeaders:e.headers.isEmpty?null:e.headers));
      if(mounted)setState(()=>status='A reproduzir: ${e.name}');
    } catch(err){if(mounted)setState(()=>status='Falha na reprodução: ${err.toString()}');}
  }

  String epgLabel(IptvItem item){
    final now=DateTime.now().toUtc();
    final p=epg.where((e)=>(item.epgId.isNotEmpty?e.channel==item.epgId:e.channel==item.id)&&!now.isBefore(e.start)&&now.isBefore(e.stop)).toList();
    return p.isEmpty?'':p.first.title;
  }

  Future<void> showEpg() async {
    if(epg.isEmpty){showMessage('Esta lista não forneceu um guia EPG/XMLTV válido.');return;}
    final now=DateTime.now().toUtc();
    final programmes=epg.where((e)=>e.stop.isAfter(now)).toList()
      ..sort((a,b)=>a.start.compareTo(b.start));
    showDialog<void>(context:context,builder:(ctx)=>AlertDialog(
      title:const Text('Guia de programação (EPG)'),
      content:SizedBox(width:520,height:420,child:ListView.builder(
        itemCount:programmes.length,itemBuilder:(_,i){
          final p=programmes[i];
          final start=p.start.toLocal().toString();
          final stop=p.stop.toLocal().toString();
          return ListTile(dense:true,title:Text(p.title),
            subtitle:Text('${p.channel} • ${start.substring(11,16)}–${stop.substring(11,16)}'),
            onTap:()=>Navigator.pop(ctx));
        })),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Fechar'))]));
  }

  Future<void> showTracks() async {
    if(current==null){showMessage('Abre primeiro um canal ou vídeo.');return;}
    final tracks=player.state.tracks;
    showDialog<void>(context:context,builder:(ctx)=>AlertDialog(
      title:const Text('Áudio e legendas'),
      content:SizedBox(width:420,child:SingleChildScrollView(child:Column(
        crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
          const Text('FAIXAS DE ÁUDIO',style:TextStyle(fontWeight:FontWeight.bold)),
          ...tracks.audio.map((t)=>ListTile(dense:true,title:Text(t.title??t.language??t.id),
            onTap:(){player.setAudioTrack(t);Navigator.pop(ctx);})),
          const Divider(),
          const Text('LEGENDAS',style:TextStyle(fontWeight:FontWeight.bold)),
          ...tracks.subtitle.map((t)=>ListTile(dense:true,title:Text(t.title??t.language??t.id),
            onTap:(){player.setSubtitleTrack(t);Navigator.pop(ctx);})),
        ]))),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Fechar'))]));
  }

  Future<void> showCatchup(IptvItem item) async {
    final channel=item.epgId.isNotEmpty?item.epgId:item.id;
    final now=DateTime.now().toUtc();
    final past=epg.where((e)=>e.channel==channel&&e.start.isBefore(now)&&e.stop.isBefore(now))
      .toList()..sort((a,b)=>b.start.compareTo(a.start));
    if(past.isEmpty){showMessage('Não há programas anteriores no EPG para este canal.');return;}
    showDialog<void>(context:context,builder:(ctx)=>AlertDialog(
      title:Text('Catch-up • ${item.name}'),
      content:SizedBox(width:500,height:380,child:ListView.builder(
        itemCount:past.length,itemBuilder:(_,i){
          final p=past[i];
          final a=p.start.toLocal().toString(),b=p.stop.toLocal().toString();
          return ListTile(title:Text(p.title),
            subtitle:Text('${a.substring(0,16)} – ${b.substring(11,16)}'),
            onTap:(){Navigator.pop(ctx);playCatchup(item,p);}
          );
        })),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Fechar'))]));
  }

  Future<void> playCatchup(IptvItem item,EpgProgramme programme) async {
    final duration=programme.stop.difference(programme.start).inMinutes.abs().clamp(1,1440).toInt();
    String url='';
    if(activeAccount!=null) {
      url=activeAccount!.catchupUrl(item.id,item.extension,programme.start,duration);
    } else if(item.catchupTemplate.isNotEmpty) {
      final start=programme.start.millisecondsSinceEpoch~/1000;
      final end=programme.stop.millisecondsSinceEpoch~/1000;
      url=item.catchupTemplate.replaceAll('{utc}','$start')
        .replaceAll('{utcend}','$end').replaceAll('{duration}','$duration')
        .replaceAll('{start}','$start').replaceAll('{end}','$end');
    }
    if(url.isEmpty){showMessage('O fornecedor não disponibilizou um endereço Catch-up compatível.');return;}
    try{await player.open(Media(url,httpHeaders:item.headers.isEmpty?null:item.headers));}
    catch(e){showMessage('O servidor recusou o Catch-up: $e');}
  }

  Future<void> manageHiddenCategories() async {
    if(pin==null){showMessage('Define primeiro um PIN parental.');return;}
    final c=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
      title:const Text('PIN parental'),
      content:TextField(controller:c,obscureText:true,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Introduz o PIN')),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancelar')),
        FilledButton(onPressed:()=>Navigator.pop(ctx,c.text==pin),child:const Text('Continuar'))]));
    if(ok!=true){showMessage('PIN incorrecto.');return;}
    final cats=channels.map((e)=>e.category).toSet().toList()..sort();
    final selected=Set<String>.from(hiddenCategories);
    final saved=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setLocal)=>AlertDialog(
      title:const Text('Bloquear / mostrar categorias'),
      content:SizedBox(width:420,height:400,child:ListView(children:cats.map((cat)=>CheckboxListTile(
        value:selected.contains(cat),title:Text(cat),subtitle:const Text('Marcado = categoria escondida'),
        onChanged:(v)=>setLocal(()=>v==true?selected.add(cat):selected.remove(cat)))).toList())),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancelar')),
        FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Guardar'))])));
    if(saved==true){
      setState(() { hiddenCategories..clear()..addAll(selected); });
      await persist();filter(search.text);showMessage('Categorias actualizadas.');
    }
  }

  Future<void> setParentalPin() async {
    final c=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
      title:const Text('Definir PIN parental'),
      content:TextField(controller:c,keyboardType:TextInputType.number,obscureText:true,maxLength:6,decoration:const InputDecoration(hintText:'PIN de 4 a 6 dígitos')),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Guardar'))]));
    if(ok==true&&c.text.length>=4&&c.text.length<=6){
      pin=c.text;final p=await SharedPreferences.getInstance();await p.setString('iptv_parental_pin',pin!);showMessage('PIN parental guardado.');
    }
  }
  Future<void> showMessage(String msg) async {
    if(!mounted)return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(msg),duration:const Duration(seconds:4)));
  }

  @override
  Widget build(BuildContext context){
    final media=MediaQuery.of(context);
    final screenWidth=media.size.width;
    final tvMode=screenWidth>=1000 && media.size.shortestSide>=600;
    final wide=screenWidth>780;
    return FocusTraversalGroup(policy: ReadingOrderTraversalPolicy(), child: Scaffold(
      appBar: AppBar(
        toolbarHeight: tvMode?82:68,
        title: Row(children:[
          _BrandMark(size:tvMode?52:42),
          const SizedBox(width:12),
          Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
            Text('FAZ TUDO IPTV',style:TextStyle(fontWeight:FontWeight.w900,letterSpacing:1.2,fontSize:tvMode?21:17)),
            Text('ENTRETENIMENTO SEM LIMITES',style:TextStyle(fontSize:tvMode?11:9,color:Color(0xffffc928),letterSpacing:1.4))
          ])
        ]),
        actions:[
          IconButton(tooltip:'Guia de programação',onPressed:showEpg,icon:const Icon(Icons.calendar_month)),
          IconButton(tooltip:'Áudio e legendas',onPressed:showTracks,icon:const Icon(Icons.subtitles)),
          IconButton(tooltip:'Favoritos',onPressed:(){setState(()=>onlyFavorites=!onlyFavorites);filter(search.text);},icon:Icon(onlyFavorites?Icons.star:Icons.star_border,color:const Color(0xffffc928))),
          PopupMenuButton<String>(onSelected:(v){
            if(v=='m3u')addM3u();if(v=='local')importLocalM3u();if(v=='xtream')addXtream();if(v=='direct')addDirectStream();if(v=='pin')setParentalPin();if(v=='categories')manageHiddenCategories();
          },itemBuilder:(_)=>const[
            PopupMenuItem(value:'m3u',child:Text('Adicionar M3U por URL')),
            PopupMenuItem(value:'local',child:Text('Importar ficheiro M3U/M3U8')),
            PopupMenuItem(value:'xtream',child:Text('Adicionar Xtream Codes')),
            PopupMenuItem(value:'direct',child:Text('Abrir URL de vídeo directa')),
            PopupMenuDivider(),PopupMenuItem(value:'pin',child:Text('Configurar PIN parental')),
            PopupMenuItem(value:'categories',child:Text('Bloquear categorias'))])
        ]),
      body:wide?Row(children:[
        Container(width:tvMode?250:205,color:const Color(0xff111216),padding:EdgeInsets.fromLTRB(tvMode?18:12,18,tvMode?18:12,12),
          child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
            const Padding(padding:EdgeInsets.fromLTRB(8,4,8,16),child:Text('MENU PRINCIPAL',style:TextStyle(color:Color(0xffffc928),fontWeight:FontWeight.bold,fontSize:11,letterSpacing:1.2))),
            _sideNav(Icons.live_tv,'TV AO VIVO','live',tvMode),
            _sideNav(Icons.movie,'FILMES','movie',tvMode),
            _sideNav(Icons.video_library,'SÉRIES','series',tvMode),
            _sideNav(Icons.grid_view,'TODOS OS CONTEÚDOS','all',tvMode),
            const Divider(color:Color(0xff303139),height:28),
            const Padding(padding:EdgeInsets.symmetric(horizontal:8,vertical:5),child:Text('AS MINHAS LISTAS',style:TextStyle(color:Colors.white54,fontWeight:FontWeight.bold,fontSize:10,letterSpacing:1))),
            if(playlists.isEmpty)const Padding(padding:EdgeInsets.all(8),child:Text('Nenhuma lista adicionada',style:TextStyle(color:Colors.white38,fontSize:12))),
            ...playlists.map((p)=>ListTile(dense:true,contentPadding:const EdgeInsets.symmetric(horizontal:8),leading:const Icon(Icons.playlist_play,color:Color(0xffffc928),size:19),title:Text(p.name,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:12)),onTap:()=>load(p))),
            const Spacer(),
            OutlinedButton.icon(onPressed:addM3u,icon:const Icon(Icons.link),label:const Text('Adicionar M3U')),
            const SizedBox(height:7),
            OutlinedButton.icon(onPressed:addXtream,icon:const Icon(Icons.account_circle),label:const Text('Ligar Xtream')),
            const SizedBox(height:7),
            OutlinedButton.icon(onPressed:importLocalM3u,icon:const Icon(Icons.folder_open),label:const Text('Abrir ficheiro')),
            const SizedBox(height:12),
            const Text('ANGOLA • VERMELHO • PRETO • AMARELO',textAlign:TextAlign.center,style:TextStyle(fontSize:8,color:Colors.white38))
          ])),
        Expanded(child:Column(children:[
          Container(height:43,decoration:const BoxDecoration(color:Color(0xff15171c),border:Border(bottom:BorderSide(color:Color(0xff292c33)))),padding:const EdgeInsets.symmetric(horizontal:16),child:Row(children:[
            Expanded(child:Text(status,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white70,fontSize:12))),
            if(loading)const SizedBox(width:17,height:17,child:CircularProgressIndicator(strokeWidth:2,color:Color(0xffffc928)))
          ])),
          Expanded(child:Row(children:[
            Expanded(flex:miniPlayer?1:3,child:Padding(padding:EdgeInsets.all(tvMode?16:10),child:Column(children:[
              Expanded(child:ClipRRect(borderRadius:BorderRadius.circular(12),child:playerPane())),
              const SizedBox(height:8),
              if(current!=null)Container(width:double.infinity,padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:const Color(0xff17191e),borderRadius:BorderRadius.circular(9)),child:Text(current!.name,style:const TextStyle(fontWeight:FontWeight.bold)))
            ]))),
            Expanded(flex:2,child:Padding(padding:EdgeInsets.fromLTRB(0,tvMode?16:10,tvMode?16:10,tvMode?16:10),child:ClipRRect(borderRadius:BorderRadius.circular(12),child:Container(color:const Color(0xff111216),child:listPane(tvMode:tvMode)))))
          ]))
        ]))
      ]):Column(children:[
        Padding(padding:const EdgeInsets.fromLTRB(10,8,10,4),child:Text(status,maxLines:2,overflow:TextOverflow.ellipsis)),
        Expanded(child:Column(children:[SizedBox(height:miniPlayer?125:235,child:playerPane()),Expanded(child:listPane())]))
      ]),
    ));
  }

  Widget _sideNav(IconData icon,String label,String value,bool tvMode)=>Padding(
    padding:const EdgeInsets.symmetric(vertical:3),
    child:ListTile(dense:true,selected:section==value,selectedTileColor:const Color(0xff3a171b),
      shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(10)),
      focusColor:const Color(0x44ffc928), minTileHeight:tvMode?62:48,
      leading:Icon(icon,color:section==value?const Color(0xffffc928):Colors.white70,size:tvMode?26:20),
      title:Text(label,style:TextStyle(fontSize:tvMode?14:11,fontWeight:section==value?FontWeight.bold:FontWeight.w500)),
      onTap:(){setState(()=>group='Todos');loadSection(value);}));

  Widget playerPane()=>Container(color:Colors.black,child:Column(children:[
    Expanded(child:Stack(children:[
      Positioned.fill(child:Video(controller:video,fit:BoxFit.contain)),
      if(current==null)const Center(child:Column(mainAxisSize:MainAxisSize.min,children:[
        Icon(Icons.live_tv,size:58,color:Colors.white54),SizedBox(height:8),
        Text('Escolhe um canal, filme ou episódio',style:TextStyle(color:Colors.white70))]))
    ])),
    if(current!=null)Wrap(alignment:WrapAlignment.center,crossAxisAlignment:WrapCrossAlignment.center,spacing:4,children:[
      IconButton(tooltip:'Recuar 10 segundos',onPressed:()=>player.seek(player.state.position-Duration(seconds:10)),icon:const Icon(Icons.replay_10)),
      IconButton(tooltip:'Reproduzir',onPressed:()=>player.play(),icon:const Icon(Icons.play_arrow)),
      IconButton(tooltip:'Pausar',onPressed:()=>player.pause(),icon:const Icon(Icons.pause)),
      IconButton(tooltip:'Avançar 10 segundos',onPressed:()=>player.seek(player.state.position+Duration(seconds:10)),icon:const Icon(Icons.forward_10)),
      IconButton(tooltip:'Parar',onPressed:()=>player.stop(),icon:const Icon(Icons.stop)),
      const Icon(Icons.volume_up,size:18),
      SizedBox(width:90,child:Slider(min:0,max:100,value:player.state.volume.clamp(0,100).toDouble(),onChanged:(v)=>player.setVolume(v))),
      IconButton(tooltip:miniPlayer?'Ecrã normal':'Mini ecrã',onPressed:()=>setState(()=>miniPlayer=!miniPlayer),icon:Icon(miniPlayer?Icons.fullscreen:Icons.picture_in_picture_alt))
    ])
  ]));
  Widget _itemIcon(IptvItem e)=>Container(
    width:52,height:42,alignment:Alignment.center,
    decoration:BoxDecoration(color:const Color(0xff292c34),borderRadius:BorderRadius.circular(7)),
    child:Icon(e.kind=='movie'?Icons.movie:e.kind=='series'?Icons.video_library:Icons.live_tv,
      color:const Color(0xffffc928),size:25));

  Widget listPane({bool tvMode=false})=>Column(children:[
    if(playlists.isNotEmpty)SizedBox(height:44,child:ListView(scrollDirection:Axis.horizontal,
      children:playlists.map((p)=>Padding(padding:const EdgeInsets.all(4),child:ActionChip(label:Text(p.name),onPressed:()=>load(p)))).toList())),
    SizedBox(height:42,child:ListView(scrollDirection:Axis.horizontal,children:[
      _sectionChip('TV ao vivo','live'),_sectionChip('Filmes','movie'),_sectionChip('Séries','series'),_sectionChip('Todos','all'),
      if(section=='episode')_sectionChip('Episódios','episode')
    ])),
    Padding(padding:const EdgeInsets.all(8),child:TextField(controller:search,onChanged:filter,
      decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Pesquisar canais, filmes e séries',border:OutlineInputBorder(),isDense:true))),
    SizedBox(height:38,child:ListView(scrollDirection:Axis.horizontal,children:['Todos','SD','HD','Full HD'].map((q)=>Padding(padding:const EdgeInsets.symmetric(horizontal:3),child:ChoiceChip(label:Text(q),selected:quality==q,onSelected:(_){setState(()=>quality=q);filter(search.text);})).toList())),
    if(groups.length>1)SizedBox(height:40,child:ListView(scrollDirection:Axis.horizontal,
      children:groups.map((g)=>Padding(padding:const EdgeInsets.symmetric(horizontal:3),child:ChoiceChip(
        label:Text(g),selected:group==g,onSelected:(_){setState(()=>group=g);filter(search.text);}))).toList())),
    Expanded(child:visible.isEmpty?const Center(child:Text('Sem itens nesta secção. Carrega uma lista ou muda de secção.'))
      :ListView.builder(itemCount:visible.length,itemBuilder:(_,i){
        final e=visible[i];final fav=favorites.contains(e.id);final programme=epgLabel(e);
        return ListTile(dense:!tvMode,minTileHeight:tvMode?76:56,contentPadding:EdgeInsets.symmetric(horizontal:tvMode?18:12,vertical:tvMode?5:0),focusColor:const Color(0x44ffc928),selectedTileColor:const Color(0xff35171b),selected:current?.id==e.id,
          leading:e.logo.isNotEmpty
            ?ClipRRect(borderRadius:BorderRadius.circular(7),child:Image.network(e.logo,width:tvMode?68:52,height:tvMode?54:42,fit:BoxFit.contain,
                cacheWidth:104,cacheHeight:84,errorBuilder:(_,__,___)=>_itemIcon(e)))
            :_itemIcon(e),
          title:Text(e.name,maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:tvMode?17:14,fontWeight:FontWeight.w600)),
          subtitle:Text(programme.isNotEmpty?'${e.category} • Agora: $programme':e.category,maxLines:2,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:tvMode?13:11)),
          trailing:Row(mainAxisSize:MainAxisSize.min,children:[
            if(e.catchup)IconButton(tooltip:'Catch-up',onPressed:()=>showCatchup(e),icon:const Icon(Icons.history)),
            IconButton(onPressed:()=>toggleFavorite(e),icon:Icon(fav?Icons.star:Icons.star_border,color:fav?Colors.amber:null))
          ]),
          onTap:()=>play(e));
      }))
  ]);
  Widget _sectionChip(String label,String value)=>Padding(padding:const EdgeInsets.symmetric(horizontal:3),child:ChoiceChip(
    label:Text(label),selected:section==value,onSelected:(_){setState(()=>group='Todos');loadSection(value);}));
}
