// Supabase Edge Function: site-assistant
// Configure the OPENAI_API_KEY secret in Supabase before deploying this function.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Método não permitido." }), {
      status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) {
    return new Response(JSON.stringify({ error: "O administrador ainda não configurou OPENAI_API_KEY no servidor." }), {
      status: 503, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    const body = await req.json();
    const messages = Array.isArray(body.messages) ? body.messages : [];
    const safeMessages = messages
      .filter((m: any) => m && ["user", "assistant"].includes(m.role) && typeof m.content === "string")
      .slice(-12)
      .map((m: any) => ({ role: m.role, content: m.content.slice(0, 4000) }));

    if (!safeMessages.length || safeMessages[safeMessages.length - 1].role !== "user") {
      return new Response(JSON.stringify({ error: "Escreva uma pergunta válida." }), {
        status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const result = await fetch("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: { "Authorization": `Bearer ${apiKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        model: "gpt-4.1-mini",
        instructions: "És o assistente do site Faz Tudo Tecnologia, em Angola. Responde em português claro e útil por padrão. Ajuda com tecnologia, estudos, matemática e os serviços apresentados no site. Não inventes preços, disponibilidade ou factos. Se não souberes, explica. Nunca peças palavras-passe, códigos bancários ou frases de recuperação. As respostas são informativas e podem precisar de verificação.",
        input: safeMessages.map((m: any) => ({ role: m.role, content: [{ type: "input_text", text: m.content }] })),
        max_output_tokens: 700,
      }),
    });

    const data = await result.json();
    if (!result.ok) {
      console.error("OpenAI API error", result.status, data?.error?.type || data?.error?.code || "unknown");
      return new Response(JSON.stringify({ error: "O serviço de IA não conseguiu responder agora. Verifica a configuração da API." }), {
        status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const reply = (data.output || [])
      .flatMap((item: any) => item.content || [])
      .filter((part: any) => part.type === "output_text")
      .map((part: any) => part.text)
      .join("\n")
      .trim();

    if (!reply) throw new Error("Resposta vazia da API.");
    return new Response(JSON.stringify({ reply }), {
      status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("site-assistant failure", error instanceof Error ? error.message : "unknown");
    return new Response(JSON.stringify({ error: "Pedido inválido ou falha temporária. Tenta novamente." }), {
      status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
