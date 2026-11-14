# Faz Tudo Tecnologia IPTV

Aplicação IPTV multiplataforma com identidade visual Faz Tudo Tecnologia e biografia do criador.

## Distribuição por plataforma

| Plataforma | Formato previsto | Estado |
|---|---|---|
| Android 6+ / Android TV | APK nativo | Compilação automática em GitHub Actions; aguarda resultado do build |
| Windows 10/11 | Instalador EXE | Compilação automática em GitHub Actions; aguarda resultado do build |
| macOS | Imagem DMG | Compilação automática em GitHub Actions; sem assinatura Apple |
| iPhone / iPad | PWA pelo Safari | Instalar via Partilhar → Adicionar ao ecrã principal |
| Apple TV (tvOS) | App nativa | Não incluída; exige projeto tvOS próprio e assinatura Apple |
| Samsung Tizen / LG webOS / Roku | App nativa | Não incluída; exige versões específicas |

## Aplicação web

URL: https://faztudoemangolaonline-dev.github.io/index.html/faz-tudo-iptv/

- Importação de lista M3U por URL ou ficheiro.
- Leitura inicial de Xtream Codes; na versão web usa playlist M3U.
- Organização básica de TV, filmes e séries por grupos.
- Pesquisa, favoritos, histórico e PIN parental local.
- Reprodução HLS quando o navegador e o servidor permitem.
- Leitura inicial de ficheiro EPG/XMLTV.
- Interface adaptável a toque, rato, teclado e setas de comando remoto.
- Manifesto PWA, ícone e cache da aplicação.
- Biografia e fotografia de Ananias Barroso Pedro.

## Builds automáticos

Os instaladores são gerados em GitHub Actions e ficam na secção **Actions → execução concluída → Artifacts**. Os artefactos de teste têm validade limitada (30 dias). A compilação bem-sucedida não substitui testes reais em cada dispositivo.

- Android: workflow `.github/workflows/faz-tudo-iptv-android.yml`.
- Windows e macOS: workflow `.github/workflows/faz-tudo-iptv-desktop.yml`.

## Limites conhecidos

A aplicação desktop abre a versão online, por isso precisa de Internet. O pacote macOS não está assinado/notarizado pela Apple; a distribuição pela App Store não está configurada. No iPhone/iPad, a instalação atual é PWA, não uma app publicada na App Store. Apple TV necessita de uma app tvOS independente.

O leitor ainda não tem paridade total com 9Xtream: faltam Xtream API completa para VOD/séries, grelha EPG completa, catch-up, downloads offline, seleção avançada de áudio/legendas, PiP, sincronização cloud e perfis.

Não existe compatibilidade universal com qualquer API ou stream. Codec, DRM, CORS, autenticação, geobloqueio e limitações do fornecedor podem impedir a reprodução. O utilizador deve fornecer listas e credenciais para conteúdos a que tenha acesso autorizado. Não é exigido código de ativação próprio pelo player.
