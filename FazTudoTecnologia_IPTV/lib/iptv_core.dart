import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class IptvItem {
  final String id, name, url, category, logo, kind, epgId, extension, catchupTemplate;
  final Map<String,String> headers;
  final bool catchup;
  const IptvItem({
    required this.id, required this.name, required this.url,
    this.category='Geral', this.logo='', this.kind='live', this.epgId='',
    this.extension='ts', this.headers=const {}, this.catchup=false, this.catchupTemplate='',
  });
}

class XtreamAccount {
  final String server, username, password;
  const XtreamAccount(this.server,this.username,this.password);
  Uri endpoint(Map<String,String> query) {
    final base=server.replaceAll(RegExp(r'/+$'),'');
    return Uri.parse('$base/player_api.php').replace(queryParameters:{
      'username':username,'password':password,...query,
    });
  }
  String streamUrl(String type,String id,String ext) {
    final base=server.replaceAll(RegExp(r'/+$'),'');
    return '$base/$type/${Uri.encodeComponent(username)}/${Uri.encodeComponent(password)}/$id.$ext';
  }
  String catchupUrl(String id,String ext,DateTime start,int durationMinutes) {
    final d=start.toLocal();
    String pad(int n)=>n.toString().padLeft(2,'0');
    final stamp='${d.year}-${pad(d.month)}-${pad(d.day)}:${pad(d.hour)}-${pad(d.minute)}';
    final base=server.replaceAll(RegExp(r'/+$'),'');
    return '$base/timeshift/${Uri.encodeComponent(username)}/${Uri.encodeComponent(password)}/$durationMinutes/$stamp/$id.$ext';
  }
}

class XtreamService {
  final http.Client client;
  XtreamService([http.Client? c]):client=c??http.Client();

  Future<dynamic> _get(XtreamAccount a, Map<String,String> q) async {
    final uri=a.endpoint(q);
    final r=await client.get(uri,headers:{'Accept':'application/json','User-Agent':'FazTudoIPTV/1.1'})
      .timeout(const Duration(seconds:35));
    if(r.statusCode<200||r.statusCode>=300) throw Exception('Servidor respondeu HTTP ${r.statusCode}');
    final body=utf8.decode(r.bodyBytes,allowMalformed:true);
    try { return jsonDecode(body); } catch (_) { throw Exception('Resposta inválida do servidor (não é JSON). Confirma o endereço e o acesso.'); }
  }

  Future<Map<String,dynamic>> accountInfo(XtreamAccount a) async {
    final v=await _get(a,{});
    if(v is! Map<String,dynamic>) throw Exception('Resposta de conta inválida');
    return v;
  }

  Future<dynamic> _optional(XtreamAccount a,String action) async {
    try { return await _get(a,{'action':action}); } catch (_) { return const []; }
  }
  Future<List<IptvItem>> loadLive(XtreamAccount a) async {
    final cats=await _optional(a,'get_live_categories');
    final streams=await _get(a,{'action':'get_live_streams'});
    return _mapStreams(a,streams,cats,'live');
  }
  Future<List<IptvItem>> loadMovies(XtreamAccount a) async {
    final cats=await _optional(a,'get_vod_categories');
    final streams=await _get(a,{'action':'get_vod_streams'});
    return _mapStreams(a,streams,cats,'movie');
  }
  Future<List<IptvItem>> loadSeries(XtreamAccount a) async {
    final cats=await _optional(a,'get_series_categories');
    final streams=await _get(a,{'action':'get_series'});
    return _mapStreams(a,streams,cats,'series');
  }

  List<IptvItem> _mapStreams(XtreamAccount a,dynamic data,dynamic categories,String kind) {
    if(data is! List) throw Exception('O servidor não devolveu uma lista de $kind.');
    final catMap=<String,String>{};
    if(categories is List) for(final c in categories) {
      if(c is Map) catMap['${c['category_id']}']='${c['category_name']??'Geral'}';
    }
    return data.whereType<Map>().map((e) {
      final id='${e[kind=='series'?'series_id':'stream_id']??''}';
      final ext='${e['container_extension']??(kind=='live'?'ts':'mp4')}';
      final url=kind=='series'?'':a.streamUrl(kind=='movie'?'movie':'live',id,ext);
      final archive=e['tv_archive']==1 || e['tv_archive']=='1' ||
        (int.tryParse('${e['tv_archive_duration']??'0'}')??0)>0;
      return IptvItem(id:id,name:'${e['name']??'Sem nome'}',url:url,
        category:catMap['${e['category_id']}']??'${e['category_name']??'Geral'}',
        logo:'${e['cover']??e['stream_icon']??''}',kind:kind,extension:ext,
        epgId:'${e['epg_channel_id']??''}',catchup:archive);
    }).where((e)=>e.id.isNotEmpty).toList();
  }

  Future<List<IptvItem>> loadEpisodes(XtreamAccount a,String seriesId) async {
    final data=await _get(a,{'action':'get_series_info','series_id':seriesId});
    if(data is! Map) throw Exception('Resposta de série inválida.');
    final episodes=data['episodes'];
    if(episodes is! Map) return [];
    final out=<IptvItem>[];
    for(final season in episodes.values) {
      if(season is! List) continue;
      for(final e in season) {
        if(e is! Map) continue;
        final id='${e['id']??e['episode_id']??''}';
        if(id.isEmpty) continue;
        final ext='${e['container_extension']??'mp4'}';
        out.add(IptvItem(id:id,name:'${e['title']??e['name']??'Episódio'}',
          url:a.streamUrl('series',id,ext),kind:'episode',extension:ext,
          category:'Temporada ${e['season']??''}'));
      }
    }
    return out;
  }
}

class M3uParser {
  static List<IptvItem> parse(String source,{String? baseUrl}) {
    final normalized=source.replaceFirst('\uFEFF','').replaceAll('\r','');
    if(baseUrl!=null && RegExp(r'#EXT-X-(TARGETDURATION|MEDIA-SEQUENCE|PLAYLIST-TYPE)').hasMatch(normalized)) {
      return [IptvItem(id:baseUrl,name:'Stream HLS',url:baseUrl,kind:'live')];
    }
    final lines=normalized.split('\n');
    final result=<IptvItem>[];
    String name='Canal',group='Geral',logo='',epg='',kind='live',catchupSource='';
    bool catchup=false;
    Map<String,String> headers={};
    for(final raw in lines) {
      final line=raw.trim();
      if(line.isEmpty) continue;
      if(line.startsWith('#EXTINF',true)) {
        final comma=line.lastIndexOf(',');
        name=comma>=0?line.substring(comma+1).trim():(_attr(line,'tvg-name')??'Canal');
        group=_attr(line,'group-title')??'Geral';
        logo=_attr(line,'tvg-logo')??'';
        epg=_attr(line,'tvg-id')??'';
        final type=(_attr(line,'type')??'').toLowerCase();
        kind=type.contains('movie')?'movie':type.contains('series')?'series':'live';
        catchup=(_attr(line,'catchup')??'').toLowerCase()!='' && (_attr(line,'catchup')??'').toLowerCase()!='none';
        catchupSource=_attr(line,'catchup-source')??'';
        headers={};
      } else if(line.startsWith('#EXTVLCOPT:',true)) {
        final opt=line.substring(line.indexOf(':')+1);
        final ix=opt.indexOf('=');
        if(ix>0) {
          final k=opt.substring(0,ix).toLowerCase(),v=opt.substring(ix+1);
          if(k=='http-user-agent') headers['User-Agent']=v;
          if(k=='http-referrer'||k=='http-referer') headers['Referer']=v;
          if(k=='http-origin') headers['Origin']=v;
        }
      } else if(line.startsWith('#EXTHTTP:',true)) {
        try {
          final map=jsonDecode(line.substring(line.indexOf(':')+1));
          if(map is Map) map.forEach((k,v)=>headers['$k']='$v');
        } catch (_) {}
      } else if(line.startsWith('#EXTGRP:',true)) {
        group=line.substring(line.indexOf(':')+1).trim();
      } else if(line.startsWith('#EXT-X-SESSION-DATA:',true)) {
        continue;
      } else if(!line.startsWith('#')) {
        String url=line;
        if(baseUrl!=null && Uri.tryParse(url)?.hasScheme!=true) url=Uri.parse(baseUrl).resolve(url).toString();
        if(url.startsWith('http://')||url.startsWith('https://')||url.startsWith('rtsp://')||url.startsWith('rtmp://')||url.startsWith('file://')) {
          result.add(IptvItem(id:epg.isNotEmpty?epg:url,name:name,url:url,category:group,
            logo:logo,kind:kind,epgId:epg,headers:Map.of(headers),catchup:catchup,catchupTemplate:catchupSource));
        }
        name='Canal';group='Geral';logo='';epg='';kind='live';catchup=false;catchupSource='';headers={};
      }
    }
    return result;
  }

  static String? _attr(String line,String key) {
    final doubleQuoted=RegExp('(?:^|\\s)$key\\s*=\\s*"([^"]*)"',caseSensitive:false);
    final singleQuoted=RegExp("(?:^|\\s)$key\\s*=\\s*'([^']*)'",caseSensitive:false);
    final m=doubleQuoted.firstMatch(line)??singleQuoted.firstMatch(line);
    return m?.group(1)?.trim();
  }
}

class EpgProgramme {
  final String channel,title,description;
  final DateTime start,stop;
  const EpgProgramme(this.channel,this.title,this.description,this.start,this.stop);
}
class XmltvParser {
  static List<EpgProgramme> parse(String xml) {
    final doc=XmlDocument.parse(xml);
    final out=<EpgProgramme>[];
    for(final node in doc.findAllElements('programme')) {
      final channel=node.getAttribute('channel')??'';
      final start=_date(node.getAttribute('start')??'');
      final stop=_date(node.getAttribute('stop')??'');
      if(start==null||stop==null) continue;
      final titles=node.findElements('title').toList();
      final descriptions=node.findElements('desc').toList();
      final title=titles.isEmpty?'':titles.first.innerText.trim();
      final desc=descriptions.isEmpty?'':descriptions.first.innerText.trim();
      out.add(EpgProgramme(channel,title,desc,start,stop));
    }
    return out;
  }
  static DateTime? _date(String s) {
    if(s.length<14) return null;
    try {
      final y=int.parse(s.substring(0,4)),m=int.parse(s.substring(4,6)),d=int.parse(s.substring(6,8));
      final h=int.parse(s.substring(8,10)),mi=int.parse(s.substring(10,12)),se=int.parse(s.substring(12,14));
      final zone=s.length>14?s.substring(14).trim():'';
      final utc=DateTime.utc(y,m,d,h,mi,se);
      final z=RegExp(r'([+-])(\d{2})(\d{2})').firstMatch(zone);
      if(z==null) return utc;
      final offset=Duration(hours:int.parse(z.group(2)!),minutes:int.parse(z.group(3)!));
      return z.group(1)=='+'?utc.subtract(offset):utc.add(offset);
    } catch (_) { return null; }
  }
}