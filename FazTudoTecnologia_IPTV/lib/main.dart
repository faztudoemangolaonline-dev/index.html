import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'iptv_core.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const FazTudoApp());
}

class FazTudoApp extends StatelessWidget {
  const FazTudoApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Faz Tudo Tecnologia IPTV',
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(useMaterial3: true).copyWith(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xffd71920), brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xff101114)),
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
    Timer(const Duration(seconds: 4), () {
      if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    });
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff111111),
    body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 90, height: 90, decoration: BoxDecoration(color: const Color(0xffd71920), borderRadius: BorderRadius.circular(22)),
          child: const Icon(Icons.live_tv, size: 54, color: Colors.white)),
        const SizedBox(height: 24),
        const Text('FAZ TUDO TECNOLOGIA', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
        const SizedBox(height: 18),
        const Text('Seja Bem vindo a Faztudo Ananias inovação', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        const SizedBox(height: 26),
        const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
      ]))));
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
  List<EpgProgramme> epg = [];
  IptvItem? current;
  XtreamAccount? activeAccount;
  Playlist? activePlaylist;
  String status = 'Adiciona uma lista M3U/M3U8 ou uma conta Xtream Codes.';
  String group = 'Todos', section = 'live';
  bool loading = false, onlyFavorites = false;
  String? pin;

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
      });
    } catch (_) {}
  }
  Future<void> persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('iptv_lists', jsonEncode(playlists.map((e)=>e.toJson()).toList()));
    await p.setString('iptv_favorites', jsonEncode(favorites.toList()));
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
        type:FileType.custom,allowedExtensions:['m3u','m3u8','txt'],withData:true);
      if(result==null||result.files.isEmpty)return;
      final file=result.files.single;
      final bytes=file.bytes;
      if(bytes==null)throw Exception('Não foi possível ler o ficheiro escolhido.');
      final text=utf8.decode(bytes,allowMalformed:true);
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
        result=M3uParser.parse(utf8.decode(r.bodyBytes,allowMalformed:true),baseUrl:p.server);
        if(p.epgUrl.isNotEmpty)await loadEpg(p.epgUrl);
        activeAccount=null;
      } else {
        final account=XtreamAccount(p.server,p.username,p.password);
        final info=await xtream.accountInfo(account);
        final auth=info['user_info'];
        if(auth is Map && auth['auth']!=null && auth['auth'].toString()=='0')throw Exception('Utilizador ou palavra-passe rejeitados pelo servidor.');
        activeAccount=account;
        final lists=await Future.wait([xtream.loadLive(account),xtream.loadMovies(account),xtream.loadSeries(account)]);
        result=[...lists[0],...lists[1],...lists[2]];
        final epgUrl='${p.server}/xmltv.php?username=${Uri.encodeQueryComponent(p.username)}&password=${Uri.encodeQueryComponent(p.password)}';
        try{await loadEpg(epgUrl);}catch(_){epg=[];}
      }
      if(result.isEmpty)throw Exception('O endereço respondeu, mas não entregou itens M3U/Xtream reconhecíveis. Verifica o formato e as credenciais.');
      if(!mounted)return;
      setState((){channels=result;section='live';status:' ';status='${result.length} itens carregados. Escolhe TV, Filmes ou Séries.';});
      filter(search.text);
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
    final data=source??channels;
    final kindMatches=(IptvItem e)=>section=='all'||e.kind==section||(section=='live'&&e.kind=='live');
    final v=data.where((e)=>kindMatches(e) && (group=='Todos'||e.category==group) &&
      e.name.toLowerCase().contains(q.toLowerCase()) && (!onlyFavorites||favorites.contains(e.id))).toList();
    if(mounted)setState(()=>visible=v);
  }
  List<String> get groups=>['Todos',...visible.map((e)=>e.category).toSet().toList()..sort()];

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
    final wide=MediaQuery.of(context).size.width>780;
    return Scaffold(appBar:AppBar(title:const Text('FAZ TUDO TECNOLOGIA IPTV'),
      actions:[
        IconButton(tooltip:'Guia de programação',onPressed:showEpg,icon:const Icon(Icons.calendar_month)),
        IconButton(tooltip:'Áudio e legendas',onPressed:showTracks,icon:const Icon(Icons.subtitles)),
        IconButton(tooltip:'Favoritos',onPressed:(){setState(()=>onlyFavorites=!onlyFavorites);filter(search.text);},icon:Icon(onlyFavorites?Icons.star:Icons.star_border)),
        PopupMenuButton<String>(onSelected:(v){
          if(v=='m3u')addM3u();if(v=='local')importLocalM3u();if(v=='xtream')addXtream();if(v=='pin')setParentalPin();
        },itemBuilder:(_)=>const[
          PopupMenuItem(value:'m3u',child:Text('Adicionar M3U por URL')),
          PopupMenuItem(value:'local',child:Text('Importar ficheiro M3U/M3U8')),
          PopupMenuItem(value:'xtream',child:Text('Adicionar Xtream Codes')),
          PopupMenuDivider(),PopupMenuItem(value:'pin',child:Text('Configurar PIN parental'))])
      ]),
      body:Column(children:[
        Padding(padding:const EdgeInsets.fromLTRB(10,8,10,4),child:Row(children:[
          Expanded(child:Text(status,maxLines:2,overflow:TextOverflow.ellipsis)),
          if(loading)const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2))])),
        Expanded(child:wide?Row(children:[Expanded(flex:3,child:playerPane()),Expanded(flex:2,child:listPane())])
          :Column(children:[SizedBox(height:235,child:playerPane()),Expanded(child:listPane())]))
      ]));
  }

  Widget playerPane()=>Container(color:Colors.black,child:Stack(children:[
    Positioned.fill(child:Video(controller:video,fit:BoxFit.contain)),
    if(current==null)const Center(child:Column(mainAxisSize:MainAxisSize.min,children:[
      Icon(Icons.live_tv,size:58,color:Colors.white54),SizedBox(height:8),
      Text('Escolhe um canal, filme ou episódio',style:TextStyle(color:Colors.white70))]))
  ]));
  Widget listPane()=>Column(children:[
    if(playlists.isNotEmpty)SizedBox(height:44,child:ListView(scrollDirection:Axis.horizontal,
      children:playlists.map((p)=>Padding(padding:const EdgeInsets.all(4),child:ActionChip(label:Text(p.name),onPressed:()=>load(p)))).toList())),
    SizedBox(height:42,child:ListView(scrollDirection:Axis.horizontal,children:[
      _sectionChip('TV ao vivo','live'),_sectionChip('Filmes','movie'),_sectionChip('Séries','series'),_sectionChip('Todos','all'),
      if(section=='episode')_sectionChip('Episódios','episode')
    ])),
    Padding(padding:const EdgeInsets.all(8),child:TextField(controller:search,onChanged:filter,
      decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Pesquisar canais, filmes e séries',border:OutlineInputBorder(),isDense:true))),
    if(groups.length>1)SizedBox(height:40,child:ListView(scrollDirection:Axis.horizontal,
      children:groups.map((g)=>Padding(padding:const EdgeInsets.symmetric(horizontal:3),child:ChoiceChip(
        label:Text(g),selected:group==g,onSelected:(_){setState(()=>group=g);filter(search.text);}))).toList())),
    Expanded(child:visible.isEmpty?const Center(child:Text('Sem itens nesta secção. Carrega uma lista ou muda de secção.'))
      :ListView.builder(itemCount:visible.length,itemBuilder:(_,i){
        final e=visible[i];final fav=favorites.contains(e.id);final programme=epgLabel(e);
        return ListTile(dense:true,selected:current?.id==e.id,
          leading:Icon(e.kind=='movie'?Icons.movie:e.kind=='series'?Icons.video_library:Icons.play_circle_outline),
          title:Text(e.name,maxLines:1,overflow:TextOverflow.ellipsis),
          subtitle:Text(programme.isNotEmpty?'${e.category} • Agora: $programme':e.category,maxLines:2,overflow:TextOverflow.ellipsis),
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
