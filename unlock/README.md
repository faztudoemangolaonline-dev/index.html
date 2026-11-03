Faz Tudo Unlock

Primeira versão pública (frontend) da plataforma Faz Tudo Unlock.

Decisões: consulta pública gratuita sem registo; apenas o proprietário administra e publica; conteúdos sobre diagnóstico, compatibilidade, configuração e desbloqueio de rede autorizado. Não apoiar alteração de IMEI, bypass de FRP/contas, anti-roubo, MDM ou acesso não autorizado.

Estado: página inicial responsiva, pesquisa local por categorias e marcas, manifesto PWA e cache offline básico. O catálogo ainda está por alimentar. A área administrativa ainda não está ligada. Não existe autenticação simulada no navegador.

Antes de activar gestão pelo administrador, integrar Supabase Auth e tabela unlock_articles com RLS: leitura pública apenas de conteúdos publicados; INSERT/UPDATE/DELETE apenas para o utilizador administrador validado no servidor. Nunca colocar service_role key no frontend.

URL esperada no GitHub Pages: https://faztudoemangolaonline-dev.github.io/index.html/unlock/

Próxima etapa: criar tabelas isoladas com prefixo unlock_ no Supabase, políticas RLS e painel autenticado exclusivo do administrador. Só depois activar a gestão de conteúdos.