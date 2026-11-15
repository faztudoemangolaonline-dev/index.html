# FAZ TUDO IPTV — TECNOLOGIA

Aplicação IPTV própria, com identidade visual azul e navegação adaptada a telemóvel, computador e Android TV. A referência funcional é o conjunto de recursos do 9 Xtream; o código e a interface são implementação independente.

## Recursos presentes no código
- Leitor de vídeo integrado através de MediaKit.
- Importação de listas M3U/M3U8 por URL e ficheiro local.
- Ligação Xtream Codes: autenticação e carregamento de TV ao vivo, VOD/filmes, séries e episódios.
- Categorias, pesquisa, filtros de qualidade, favoritos e várias listas guardadas localmente.
- EPG/XMLTV: importação e apresentação de programas actuais e futuros.
- Catch-up quando o fornecedor disponibiliza arquivo e URL compatível.
- Selecção de faixas de áudio e legendas quando o stream fornece essas faixas.
- PIN parental local e ocultação de categorias.
- Retoma do último conteúdo e controlos de reprodução.
- Interface responsiva com navegação por teclado e comando remoto Android TV.
- Ligação para a biografia e fotografia oficiais do criador.

## Ainda não implementado / não garantido
- Grelha EPG completa com timeline por canal.
- Downloads offline e gestão de armazenamento.
- Perfis de utilizador, sincronização na nuvem e controlo parental remoto.
- Picture-in-Picture e multi-ecrã.
- Paridade integral com 9 Xtream; esta aplicação não é uma cópia do software original.
- Compatibilidade com Apple TV/tvOS e publicação na App Store.

## Plataformas e limites
- Android 8+ / Android TV: APK gerado por GitHub Actions.
- Windows 10+: build Windows gerado por GitHub Actions.
- iPhone/iPad: ainda sem distribuição App Store configurada; uma compilação técnica sem assinatura não é instalável como app normal.
- macOS: build sem assinatura/notarização Apple.

A reprodução depende do servidor, credenciais, rede, protocolo, codec, DRM e restrições do fornecedor. A aplicação não fornece canais nem credenciais. Usa apenas listas e transmissões a que tens acesso autorizado.

## Compilar e verificar
O workflow `.github/workflows/build-faztudo-iptv.yml` executa os testes de parser e gera builds Android, Windows e Apple. Um build verde confirma a compilação e os testes automatizados indicados; não substitui ensaios de reprodução com contas e dispositivos reais.
