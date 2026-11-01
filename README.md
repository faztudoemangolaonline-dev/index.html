# Faz Tudo Tecnologia

Site e aplicação web instalável (PWA) de serviços, ferramentas e informação para Angola.

## Endereços
- GitHub Pages: https://faztudoemangolaonline-dev.github.io/index.html/
- Repositório: https://github.com/faztudoemangolaonline-dev/index.html

## Publicação
- Página principal: `index.html`
- PWA: `manifest.json` e `worker.js`
- Ícones: `icon-192.png`, `icon-512.png`, `icon-512-maskable.png`
- A branch `main` contém a versão de publicação. GitHub Pages/Cloudflare Pages devem estar ligados à branch `main`.

## Backend Supabase
Project ref: `atrlbhisqmtuyopibjtu`

- Migrações versionadas em `supabase/migrations/`.
- Edge Functions activas: `faztudo-chat` e `faztudo-voice`.
- Código-fonte das funções em `supabase/functions/`.
- A função de chat usa o segredo de servidor `GEMINI_API_KEY`; a função de voz usa o mesmo segredo.
- Nunca colocar chaves secretas ou service-role keys no HTML, JavaScript público ou GitHub.

## Segurança e administração
- Todas as tabelas públicas têm Row Level Security (RLS) activa.
- Clientes só consultam os seus próprios pedidos, pagamentos e subscrições.
- Registos de clientes e pedidos de revendedor não podem atribuir privilégios administrativos.
- Playlists e códigos privados não são acessíveis aos clientes.
- A função de administrador único é protegida em `private.admin_users`; a chave singleton impede um segundo administrador.
- O painel administrativo gere pedidos, pagamentos, subscrições, revendedores, canais, playlists, códigos privados, mensagens, anúncios, avisos comunitários e avaliações.

## Primeiro administrador — passo obrigatório antes do lançamento
Ainda não existe utilizador no Auth. Antes de o proprietário criar a conta:
1. No Supabase SQL Editor, executar:
   `insert into private.admin_bootstrap_emails(email) values (lower('TEU_EMAIL')) on conflict do nothing;`
2. No site, criar uma conta com exactamente esse e-mail.
3. Confirmar o endereço através do e-mail de verificação.
4. A trigger promove essa conta para o único administrador. O registo público nunca apresenta a opção de administrador.

Não partilhar a palavra-passe com terceiros nem a colocar no GitHub.

## Planos apresentados
- Demonstração: 24 horas
- Semanal: 2.499 Kz
- Mensal: 4.999 Kz

Contacto oficial: +244 950 822 328
