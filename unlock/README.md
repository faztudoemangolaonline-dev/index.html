# Faz Tudo Unlock

Plataforma pública gratuita para diagnóstico, compatibilidade e guias de desbloqueio de rede autorizados para telemóveis, routers e modems.

## Estado implementado
- Página responsiva e PWA com cache offline versionado.
- Diagnóstico local de IMEI, ICCID, MCC/MNC, modelo e operadora.
- Validação de formato/check digit de IMEI e ICCID; não consulta bases privadas nem calcula NCK.
- Catálogo público de modelos publicados no Supabase.
- Painel de autenticação Supabase e formulário de publicação de equipamentos.
- Tabelas public.unlock_devices e public.unlock_articles com RLS: visitantes leem apenas conteúdos publicados; só contas autenticadas com app_metadata.unlock_admin = true podem gerir registos.

## Ativação do administrador
No Supabase Dashboard do projeto atrlbhisqmtuyopibjtu, abre Authentication > Users, identifica a conta do proprietário e atribui em App Metadata o JSON {"unlock_admin": true}. Termina e inicia novamente a sessão no painel para renovar o token. Não uses User Metadata para permissões.

## Limites técnicos
- Um site no navegador não pode ler livremente o SIM nem o IMEI do dispositivo.
- Leitura direta requer aplicação Android e permissões permitidas pelo sistema.
- NCK/MCK/SPCK dependem do fabricante/operadora e de bases autorizadas; não são calculados a partir do IMEI pelo formulário.
- Não apoiar alteração de IMEI, bypass de FRP/contas, anti-roubo, MDM ou acesso não autorizado.
- A chave publishable é própria para frontend; nunca usar service_role/secret key no navegador.

URL: https://faztudoemangolaonline-dev.github.io/index.html/unlock/
