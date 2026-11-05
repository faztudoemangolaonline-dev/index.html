import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

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

class TvItem {
  final String id, name, url, group, logo;
  const TvItem(this.id, this.name, this.url, {this.group = 'Geral', this.logo = ''});
}
class Playlist {
  final String name, type, server, username, password;
  const Playlist(this.name, this.type, this.server, {this.username = '', this.password = ''});
  Map<String,dynamic> toJson() => {'name':name,'type':type,'server':server,'username':username,'password':password};
  factory Playlist.fromJson(Map<String,dynamic> j) => Playlist(
    j['name'] ?? 'Lista', j['type'] ?? 'm3u', j['server'] ?? '',
    username:j['username'] ?? '', password:j['password'] ?? '');
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
  List<Playlist> playlists = [];
  List<TvItem> channels = [], visible = [];
  final Set<String> favorites = {};
  TvItem? current;
  String status = 'Adicione uma lista M3U/M3U8 ou conta Xtream Codes.';
  String group = 'Todos';
  bool loading = false, onlyFavorites = false;

  @override
  void initState() { super.initState(); restore(); }
  @override
  void dispose() { search.dispose(); player.dispose(); super.dispose(); }

  Future<void> restore() async {
    final p = await SharedPreferences.getInstance();
    try {
      final a = jsonDecode(p.getString('iptv_lists') ?? '[]') as List;
      final f = jsonDecode(p.getString('iptv_favorites') ?? '[]') as List;
      setState(() {
        playlists = a.map((e) => Playlist.fromJson(Map<String,dynamic>.from(e))).toList();
        favorites.addAll(f.cast<String>());
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
    final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
      title:const Text('Adicionar M3U/M3U8'),
      content:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:n,decoration:const InputDecoration(labelText:'Nome')),
        TextField(controller:u,keyboardType:TextInputType.url,decoration:const InputDecoration(labelText:'URL da lista'))]),
      actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancelar')),
        FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Guardar'))]));
    if(ok==true && u.text.trim().isNotEmpty){
      final p=Playlist(n.text.trim().isEmpty?'Lista M3U':n.text.trim(),'m3u',u.text.trim());
      setState(()=>playlists.add(p)); await persist(); await load(p);
    }
  }

  Future<void> addXtream() async {
    final n=TextEditingController(text:'Minha conta');
    final h=TextEditingController(), u=TextEditingController(), p=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
      title:const Text('Adicionar Xtream Codes'),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:n,decoration:const InputDecoration(labelText:'Nome')),
        TextField(controller:h,keyboardType:TextInputType.url,decoration:const InputDecoration(labelText:'Servidor com porta')),
        TextField(controller:u,decoration:const InputDecoration(labelText:'Utilizador')),
        TextField(controller:p,obscureText:true,decoration:const InputDecoration(labelText:'Palavra-passe'))])),
      actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancelar')),
        FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Guardar'))]));
    if(ok==true && h.text.trim().isNotEmpty && u.text.isNotEmpty && p.text.isNotEmpty){
      final pl=Playlist(n.text.trim().isEmpty?'Xtream':n.text.trim(),'xtream',
        h.text.trim().replaceAll(RegExp(r'/+$'),''),username:u.text.trim(),password:p.text);
      setState(()=>playlists.add(pl)); await persist(); await load(pl);
    }
  }

  Future<void> load(Playlist p) async {
    setState((){loading=true;status='A carregar '+p.name+'...';channels=[];visible=[];current=null;});
    try {
      List<TvItem> result=[];
      if(p.type=='m3u'){
        final r=await http.get(Uri.parse(p.server)).timeout(const Duration(seconds:30));
        if(r.statusCode<200||r.statusCode>=300) throw Exception('HTTP '+r.statusCode.toString());
        result=parseM3u(utf8.decode(r.bodyBytes,allowMalformed:true));
      } else {
        final uri=Uri.parse(p.server+'/player_api.php').replace(queryParameters:{
          'username':p.username,'password':p.password,'action':'get_live_streams'});
        final r=await http.get(uri).timeout(const Duration(seconds:30));
        if(r.statusCode<200||r.statusCode>=300) throw Exception('HTTP '+r.statusCode.toString());
        final data=jsonDecode(r.body);
        if(data is! List) throw Exception('Resposta Xtream inválida ou acesso recusado.');
        for(final e in data){
          if(e is Map && e['stream_id']!=null){
            final id=e['stream_id'].toString();
            final ext=(e['container_extension']??'ts').toString();
            final url=p.server+'/live/'+Uri.encodeComponent(p.username)+'/'+Uri.encodeComponent(p.password)+'/'+id+'.'+ext;
            result.add(TvItem(id,(e['name']??'Canal '+id).toString(),url,
              group:(e['category_name']??'Canais').toString(),logo:(e['stream_icon']??'').toString()));
          }
        }
      }
      setState((){channels=result;visible=result;status=result.length.toString()+' canais carregados.';});
    } catch(e){setState(()=>status='Erro ao carregar lista: '+e.toString());}
    finally{setState(()=>loading=false);}
  }

  List<TvItem> parseM3u(String text){
    final out=<TvItem>[];
    String name='Canal', grp='Geral', logo='';
    for(final raw in const LineSplitter().convert(text)){
      final line=raw.trim();
      if(line.startsWith('#EXTINF')){
        final comma=line.lastIndexOf(',');
        name=comma>=0?line.substring(comma+1).trim():'Canal';
        grp=RegExp(r'group-title="([^"]*)"').firstMatch(line)?.group(1)??'Geral';
        logo=RegExp(r'tvg-logo="([^"]*)"').firstMatch(line)?.group(1)??'';
      } else if(line.startsWith('http://')||line.startsWith('https://')||line.startsWith('rtsp://')){
        out.add(TvItem(line,name,line,group:grp,logo:logo)); name='Canal';grp='Geral';logo='';
      }
    }
    return out;
  }

  List<String> get groups => ['Todos',...channels.map((e)=>e.group).toSet().toList()..sort()];
  void filter(String q) {
    final v=channels.where((e)=>(group=='Todos'||e.group==group) &&
      e.name.toLowerCase().contains(q.toLowerCase()) &&
      (!onlyFavorites||favorites.contains(e.id))).toList();
    setState(()=>visible=v);
  }
  Future<void> toggleFavorite(TvItem e) async {
    setState(()=>favorites.contains(e.id)?favorites.remove(e.id):favorites.add(e.id));
    await persist(); filter(search.text);
  }
  Future<void> play(TvItem e) async {
    setState(() { current=e; status='A abrir '+e.name+'...'; });
    try { await player.open(Media(e.url)); }
    catch(err){setState(()=>status='Falha na reprodução: '+err.toString());}
  }

  @override
  Widget build(BuildContext context){
    final wide=MediaQuery.of(context).size.width>780;
    return Scaffold(appBar:AppBar(title:const Text('FAZ TUDO TECNOLOGIA IPTV'),
      actions:[
        IconButton(tooltip:'Favoritos',onPressed:(){setState(()=>onlyFavorites=!onlyFavorites);filter(search.text);},
          icon:Icon(onlyFavorites?Icons.star:Icons.star_border)),
        PopupMenuButton<String>(onSelected:(v){if(v=='m3u')addM3u();if(v=='xtream')addXtream();},
          itemBuilder:(_)=>const[PopupMenuItem(value:'m3u',child:Text('Adicionar M3U/M3U8')),
            PopupMenuItem(value:'xtream',child:Text('Adicionar Xtream Codes'))])
      ]),
      body:Column(children:[
        Padding(padding:const EdgeInsets.all(10),child:Row(children:[
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
      Text('Escolha um canal para começar',style:TextStyle(color:Colors.white70))]))
  ]));
  Widget listPane()=>Column(children:[
    if(playlists.isNotEmpty)SizedBox(height:48,child:ListView(scrollDirection:Axis.horizontal,
      children:playlists.map((p)=>Padding(padding:const EdgeInsets.all(4),
        child:ActionChip(label:Text(p.name),onPressed:()=>load(p)))).toList())),
    Padding(padding:const EdgeInsets.all(8),child:TextField(controller:search,onChanged:filter,
      decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Pesquisar canais',
        border:OutlineInputBorder(),isDense:true))),
    if(channels.isNotEmpty)SizedBox(height:42,child:ListView(scrollDirection:Axis.horizontal,
      children:groups.map((g)=>Padding(padding:const EdgeInsets.symmetric(horizontal:3),
        child:ChoiceChip(label:Text(g),selected:group==g,onSelected:(_){setState(()=>group=g);filter(search.text);}))).toList())),
    Expanded(child:visible.isEmpty?const Center(child:Text('Adicione uma lista para ver os canais.'))
      :ListView.builder(itemCount:visible.length,itemBuilder:(_,i){
        final e=visible[i]; final fav=favorites.contains(e.id);
        return ListTile(dense:true,selected:current?.id==e.id,
          leading:const Icon(Icons.play_circle_outline),title:Text(e.name,maxLines:1,overflow:TextOverflow.ellipsis),
          subtitle:Text(e.group),trailing:IconButton(onPressed:()=>toggleFavorite(e),
            icon:Icon(fav?Icons.star:Icons.star_border,color:fav?Colors.amber:null)),
          onTap:()=>play(e));
      }))
  ]);
}
