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
- O assistente principal do site chama `faztudo-chat`; o chat usa o segredo de servidor `GEMINI_API_KEY`. A função de voz usa o mesmo segredo.
- Nunca colocar chaves secretas ou service-role keys no HTML, JavaScript público ou GitHub.

## Segurança e administração
- A conta administrativa única já existe, está confirmada e está associada ao email do proprietário.
- Não executar novamente o procedimento antigo de bootstrap do primeiro administrador.
- Registos de clientes e pedidos de revendedor não podem atribuir privilégios administrativos.
- Clientes só consultam os seus próprios pedidos, pagamentos e subscrições.
- Playlists e códigos privados são geridos em área restrita.
- O contacto pessoal do autor é guardado no esquema privado e as funções públicas RPC apenas permitem a leitura/alteração por utilizadores autenticados que passam a verificação de administrador.
- O contacto de apoio ao cliente `+244 950 822 328` permanece público. O contacto pessoal do autor não deve ser apresentado aos visitantes.
- O painel musical permite gerir músicas, capas, publicação, estatísticas, opiniões e perfil do autor.

## Migrações recentes
- `20261101120450_secure_author_private_contact.sql`: armazena o telefone pessoal do autor no esquema privado.
- `20261101121050_expose_admin_author_contact_rpc.sql`: disponibiliza chamadas RPC protegidas para o painel administrativo gerir esse telefone.

## Planos apresentados
- Demonstração: 24 horas
- Semanal: 2.499 Kz
- Mensal: 4.999 Kz

Contacto oficial de apoio: +244 950 822 328
