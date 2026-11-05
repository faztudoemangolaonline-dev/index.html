import 'package:flutter_test/flutter_test.dart';
import 'package:faz_tudo_tecnologia_iptv/iptv_core.dart';

void main() {
  group('M3uParser', () {
    test('reads names, groups, logos, EPG ids and stream headers', () {
      const source='''#EXTM3U
#EXTINF:-1 tvg-id="news.pt" tvg-logo="https://img.test/a.png" group-title="Notícias",Canal Notícias
#EXTVLCOPT:http-user-agent=FazTudoTest/1.0
#EXTVLCOPT:http-referrer=https://portal.test/
https://stream.test/live.m3u8
''';
      final items=M3uParser.parse(source);
      expect(items,hasLength(1));
      expect(items.first.name,'Canal Notícias');
      expect(items.first.category,'Notícias');
      expect(items.first.epgId,'news.pt');
      expect(items.first.logo,'https://img.test/a.png');
      expect(items.first.headers['User-Agent'],'FazTudoTest/1.0');
      expect(items.first.headers['Referer'],'https://portal.test/');
    });

    test('resolves relative stream paths against playlist URL', () {
      const source='#EXTM3U\n#EXTINF:-1,Canal 2\nstreams/canal2.ts\n';
      final items=M3uParser.parse(source,baseUrl:'https://host.test/lists/main.m3u');
      expect(items.single.url,'https://host.test/lists/streams/canal2.ts');
    });

    test('accepts single-quoted attributes and skips comments', () {
      const source="#EXTM3U\n#EXTINF:-1 group-title='Desporto',Canal Sport\n# comment\nhttps://host.test/sport.ts";
      final items=M3uParser.parse(source);
      expect(items.single.category,'Desporto');
      expect(items.single.name,'Canal Sport');
    });
  });

  test('XmltvParser reads programme schedule with timezone offset', () {
    const xml='''<?xml version="1.0"?>
<tv><programme channel="news.pt" start="20261106090000 +0100" stop="20261106100000 +0100">
<title lang="pt">Notícias da Manhã</title><desc>Resumo do dia</desc>
</programme></tv>''';
    final items=XmltvParser.parse(xml);
    expect(items,hasLength(1));
    expect(items.single.title,'Notícias da Manhã');
    expect(items.single.start,DateTime.utc(2026,11,6,8));
    expect(items.single.stop,DateTime.utc(2026,11,6,9));
  });
}
