# Faz Tudo Tecnologia

Plataforma web/PWA de serviços, ferramentas e informação para Angola.

## Publicação
- Página principal: `index.html`
- PWA: `manifest.json` e `worker.js`
- Ícones: `icon-192.png`, `icon-512.png`, `icon-512-maskable.png`
- O site pode ser publicado em GitHub Pages ou Cloudflare Pages a partir da branch `main`.

## Backend Supabase
Project ref: `atrlbhisqmtuyopibjtu`

As migrações aplicadas estão versionadas em `supabase/migrations/`.
Funções Edge actualmente activas:
- `faztudo-chat`
- `faztudo-voice`

Os respectivos fontes estão em `supabase/functions/`.

## Segurança
- Todas as tabelas públicas têm Row Level Security (RLS) activa.
- Os clientes só consultam os seus próprios pedidos, pagamentos e subscrições.
- A aprovação de revendedores e a gestão de canais, playlists e códigos privados são reservadas ao administrador.
- O administrador único é controlado no esquema privado `private.admin_users`; o registo público nunca permite escolher a função de administrador.
- A chave de IA deve permanecer como segredo no Supabase (por exemplo, `GEMINI_API_KEY`) e nunca no HTML público.

## Primeiro administrador
Antes de criar a conta do proprietário, inserir o e-mail confirmado na tabela privada `private.admin_bootstrap_emails` através do SQL Editor. A trigger promove apenas esse e-mail quando a conta confirmar o endereço. A tabela permite apenas um administrador.

## Planos actualmente apresentados
- Demonstração: 24 horas
- Semanal: 2.499 Kz
- Mensal: 4.999 Kz

Contacto: +244 950 822 328
