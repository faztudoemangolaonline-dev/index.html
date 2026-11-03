# Faz Tudo Unlock

Plataforma pública gratuita para diagnóstico, compatibilidade e guias de desbloqueio de rede autorizados para telemóveis, routers e modems.

## Funcionalidades implementadas
- Página responsiva em português e PWA instalável.
- Diagnóstico local de IMEI, ICCID, MCC/MNC, modelo e operadora.
- Validação do formato e dígito de controlo de IMEI e ICCID.
- Catálogo público de equipamentos publicados pelo administrador.
- Catálogo público de guias e artigos publicados.
- Painel Supabase para o administrador adicionar equipamentos e publicar guias.
- Acesso público sem registo; apenas conteúdos publicados são visíveis.
- RLS limita inserção, alteração e remoção à conta com `app_metadata.unlock_admin = true`.

## Administrador
Conta autorizada: `faztudoemangolaonline@gmail.com`.

O administrador entra na própria página, na secção “Painel do administrador”, usando a palavra-passe da conta Supabase. Se a permissão foi alterada recentemente, terminar a sessão e entrar novamente para renovar o token.

## URL pública
https://faztudoemangolaonline-dev.github.io/index.html/unlock/

## Limites técnicos e segurança
- Um site no navegador não consegue ler livremente o SIM nem o IMEI do dispositivo.
- Leitura direta do SIM/IMEI exige aplicação Android e permissões permitidas pelo sistema.
- NCK/MCK/SPCK dependem do fabricante, da operadora e de bases autorizadas; não podem ser calculados universalmente a partir do IMEI.
- A plataforma não altera IMEI, não contorna FRP/contas, anti-roubo ou MDM, e não permite acesso a equipamentos sem autorização.
- A chave publishable pode estar no frontend; nunca colocar service_role/secret key no navegador.
- Só publicar códigos e procedimentos verificados, específicos para o modelo e permitidos pelo fabricante/operadora.

## Estado do catálogo
Os três guias educativos já existentes são apresentados na área pública. O catálogo de equipamentos começa vazio e deve ser preenchido pelo administrador com modelos e métodos tecnicamente confirmados.
