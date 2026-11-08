# Stock Fácil Angola

Aplicação publicada: https://index-html-3ks.pages.dev/stock-facil-angola/

Aplicação web/PWA para gestão de pequenos negócios em Angola, com moeda Kz e dados isolados por conta Supabase.

## Configuração
1. O projecto Supabase já está configurado em `config.js` com a chave publicável (nunca usar service_role no navegador).
2. Aplicar o SQL de `sql/create_stock_sale.sql` no SQL Editor do Supabase antes de registar vendas.
3. Publicar esta pasta num alojamento HTTPS (GitHub Pages, Cloudflare Pages ou outro).
4. No Supabase Auth, configurar Site URL e Redirect URLs para o endereço final da aplicação.

## Funcionalidades nesta versão
- Registo, login e recuperação de palavra-passe por email.
- Perfil e negócio.
- Produtos, quantidades, custos e preços.
- Clientes.
- Registo de vendas com validação transaccional do stock e pagamentos iniciais.
- Despesas, resumo com valor em stock e dívidas por receber.
- Reposição de stock e recebimento posterior de dívidas.
- Exportação e reposição de cópia JSON com IDs preservados.
- PWA com cache de ficheiros estáticos.

## Limitações conhecidas
- É necessária Internet para autenticação e operações de dados; o modo offline ainda não regista vendas.
- A aplicação e os ficheiros públicos foram verificados no alojamento; ainda é necessário um teste operacional com uma conta real do utilizador para validar o fluxo completo de autenticação e transacções.
- Importar um backup é uma operação de reposição/acréscimo e deve ser feito com cuidado; não importar o mesmo ficheiro repetidamente.
- Não inclui facturação fiscal certificada nem gestão multi-funcionário.
- Pagamentos posteriores de dívidas e relatórios avançados ficam para versão seguinte.

## Segurança
As tabelas usam RLS no Supabase. Não colocar chaves secretas ou service_role em ficheiros públicos.