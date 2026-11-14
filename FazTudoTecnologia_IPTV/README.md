# FAZ TUDO IPTV TECNOLOGIA

Aplicação Flutter multiplataforma para entretenimento IPTV, com marca Faz Tudo Tecnologia.

## Funcionalidades implementadas no código
- Leitor de vídeo integrado.
- Listas M3U/M3U8 por URL e importação de ficheiros locais.
- Acesso Xtream Codes com TV ao vivo, filmes, séries e episódios.
- Pesquisa, categorias e filtros de qualidade.
- Favoritos e listas guardadas localmente.
- Guia electrónico XMLTV/EPG e Catch-up quando suportados pelo fornecedor.
- PIN parental e bloqueio de categorias.
- Retoma do último conteúdo e controlos do leitor.
- Interface adaptável para telemóvel, Android TV e computador.
- Menu "Biografia do criador" que abre a biografia e fotografia oficiais no site Faz Tudo Tecnologia.
- Abertura cinematográfica com fogo, chave de processamento, mensagem de boas-vindas e som.

## Plataformas
- Android 8+ / Android TV: APK de lançamento.
- Windows 10+: pacote ZIP com os ficheiros da aplicação.
- iPhone/iPad: compilação iOS sem assinatura, para validação técnica. Para instalar num dispositivo ou distribuir pela App Store é necessária assinatura Apple.
- macOS: pacote da aplicação macOS.
- Apple TV/tvOS: não é um alvo de compilação suportado por este projecto Flutter.

## Compilação e downloads
O workflow GitHub Actions "Build Faz Tudo IPTV" compila Android, Windows e Apple. Os artefactos temporários ficam disponíveis na execução do workflow durante 14 dias. A versão só deve ser considerada entregue depois de os testes e as compilações terminarem com sucesso e os ficheiros serem verificados.

## Compatibilidade de conteúdos
A reprodução depende da fonte, do protocolo, do codec e da rede. A aplicação não contorna DRM, autenticação ou restrições de acesso. Utilize apenas listas e transmissões que tenha autorização para utilizar.
