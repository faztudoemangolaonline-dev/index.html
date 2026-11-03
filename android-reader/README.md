# Faz Tudo IPTV — Android

Aplicativo Android independente em desenvolvimento, compilado gratuitamente pelo GitHub Actions.

## Incluído nesta base
- Aplicativo nativo Android (Android 5.0 ou superior).
- Login com a conta de cliente existente do Faz Tudo Tecnologia.
- Verificação de subscrição e do identificador do leitor através do Supabase.
- Carregamento da lista M3U autorizada através da Edge Function `iptv-gateway`.
- Reprodução HLS/M3U8 e outros formatos reconhecidos pelo ExoPlayer/Media3.
- Sem limite artificial de canais imposto pela interface.

## Gerar o APK
O workflow `.github/workflows/android-reader.yml` compila um APK de depuração. No GitHub, abrir **Actions**, seleccionar **Build Faz Tudo IPTV Android APK**, abrir a execução concluída e descarregar o artefacto `faz-tudo-iptv-debug-apk`.

## Acesso
O cliente precisa da conta do site e do UUID bruto do leitor que já esteja autorizado e associado à subscrição no painel. O backend continua a validar o acesso; a aplicação não substitui a gestão de prazos do administrador.

## O que ainda não está concluído
Esta primeira base utiliza a rota M3U protegida já existente. Xtream Codes API, Stalker/Ministra, múltiplas fontes independentes, EPG/XMLTV, VOD/séries e testes em Android TV precisam de implementação e validação próprias. Não anunciar essas integrações como prontas ainda. A compatibilidade final depende dos protocolos, codecs, DRM, rede e permissões do fornecedor.
