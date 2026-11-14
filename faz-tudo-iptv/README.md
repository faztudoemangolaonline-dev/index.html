# Faz Tudo Tecnologia IPTV

Aplicação IPTV com identidade visual azul Faz Tudo Tecnologia.

## Compatibilidade desta versão

| Plataforma | Situação atual | Instalação |
|---|---|---|
| Android | Acesso via navegador compatível | PWA/atalho; APK nativo ainda por construir |
| Android TV / Google TV | Acesso web; foco e navegação por setas adicionados | APK nativo Android TV ainda por construir |
| Windows 10/11 | Acesso via Edge/Chrome | Instalar como PWA |
| iPhone/iPad | Acesso via Safari/navegador | Adicionar ao ecrã principal |
| macOS | Acesso via Safari/Chrome/Edge | Adicionar ao Dock ou instalar conforme navegador |
| Apple TV | Não existe app tvOS nesta versão | App nativa tvOS necessária |
| Samsung Tizen / LG webOS / Roku | Não garantido nesta versão | Apps específicas das plataformas necessárias |

## Implementado nesta versão
- Importação de lista M3U por URL ou ficheiro.
- Leitura inicial de Xtream Codes usando endpoint de playlist M3U.
- Organização de TV ao vivo, filmes e séries a partir de grupos M3U.
- Pesquisa, favoritos, histórico e PIN parental local.
- Reprodução HLS quando o navegador e o servidor permitem.
- Leitura inicial de ficheiro EPG/XMLTV.
- Interface responsiva para toque, rato, teclado e setas de comando remoto.
- Manifesto PWA, ícone SVG e cache da aplicação.

## Para alcançar paridade avançada com 9Xtream
- Xtream API completa: autenticação, categorias, VOD, séries, temporadas, episódios e metadados.
- Integração de APIs de outros painéis, como 1-Stream, com documentação e credenciais válidas.
- Grelha EPG completa e associação automática por IDs de canal.
- Catch-up/TV Archive, se o fornecedor disponibilizar essa função.
- Downloads offline, player externo, escolha de áudio e legendas, Picture-in-Picture e retomar reprodução.
- Perfis, sincronização entre dispositivos e controlos parentais completos.
- Aplicações nativas assinadas para Android/Android TV, iOS/iPadOS/tvOS, Windows, Samsung Tizen e LG webOS.

## Limites técnicos
Não existe compatibilidade universal com literalmente qualquer API ou stream. Formatos, autenticação, codecs, DRM, CORS, geobloqueio, limites do servidor e capacidade do dispositivo podem impedir a reprodução. O player não inclui canais nem subscrições: o utilizador fornece listas e credenciais para conteúdos a que tenha acesso autorizado.

A versão web/PWA não substitui apps nativas para Apple TV, Samsung Tizen ou LG webOS. Não há código de ativação próprio obrigatório nesta versão, mas isso não remove restrições impostas pelo fornecedor da lista.

## URL
https://faztudoemangolaonline-dev.github.io/index.html/faz-tudo-iptv/
