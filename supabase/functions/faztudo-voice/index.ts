const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Vary": "Origin",
};
function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), { status, headers: { ...cors, "Content-Type": "application/json; charset=utf-8", "Cache-Control": "no-store" } });
}
const voices = new Set(["Zephyr","Puck","Charon","Kore","Fenrir","Leda","Orus","Aoede","Callirrhoe","Autonoe","Enceladus","Iapetus","Umbriel","Algieba","Despina","Erinome","Algenib","Rasalgethi","Laomedeia","Achernar","Alnilam","Schedar","Gacrux","Pulcherrima","Achird","Zubenelgenubi","Vindemiatrix","Sadachbia","Sadaltager","Sulafat"]);
function decodeBase64(value: string): Uint8Array {
  const binary = atob(value);
  const bytes = new Uint8Array(binary.length);
  for (let i=0;i<binary.length;i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}
Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "Use POST." }, 405);
  if (!GEMINI_API_KEY) return json({ error: "A chave GEMINI_API_KEY não está configurada no Supabase." }, 503);
  let body: any;
  try { body = await req.json(); } catch { return json({ error: "JSON inválido." }, 400); }

  if (body.action === "transcribe") {
    const audio = typeof body.audio === "string" ? body.audio : "";
    const mimeType = typeof body.mimeType === "string" ? body.mimeType : "audio/webm";
    if (!audio || audio.length > 12_000_000) return json({ error: "Áudio vazio ou demasiado longo. Grava uma mensagem mais curta." }, 413);
    const prompt = "Transcreve fielmente o áudio para texto. O áudio está provavelmente em português de Angola ou português. Responde apenas com as palavras reconhecidas, sem comentários, sem traduzir.";
    const upstream = await fetch("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=" + GEMINI_API_KEY, {
      method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ contents: [{ role: "user", parts: [{ text: prompt }, { inlineData: { mimeType, data: audio } }] }], generationConfig: { temperature: 0.1, maxOutputTokens: 1200 } }),
      signal: AbortSignal.timeout(55000),
    });
    const result = await upstream.json().catch(() => ({}));
    if (!upstream.ok) {
      console.error("Gemini transcription error", upstream.status, result);
      return json({ error: result?.error?.message || "Não foi possível reconhecer a voz. Tenta novamente." }, 502);
    }
    const transcript = (result?.candidates?.[0]?.content?.parts || []).map((p: any) => p.text || "").join("").trim();
    if (!transcript) return json({ error: "Não consegui reconhecer palavras nesse áudio. Fala mais perto do microfone e tenta novamente." }, 422);
    return json({ transcript });
  }

  if (body.action === "speak") {
    const text = typeof body.text === "string" ? body.text.trim() : "";
    const voice = voices.has(body.voice) ? body.voice : "Kore";
    if (!text || text.length > 5000) return json({ error: "Texto vazio ou demasiado longo para leitura." }, 400);
    const upstream = await fetch("https://generativelanguage.googleapis.com/v1beta/interactions?key=" + GEMINI_API_KEY, {
      method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        model: "gemini-3.8-flash-lite-tts",
        input: [{ type: "user_input", content: [{ type: "text", text, annotations: [{ type: "speech_metadata", style: "Speak naturally and clearly in conversational Portuguese, with a warm and helpful tone." }] }] }],
        response_format: { type: "audio" },
        generation_config: { speech_config: [{ voice }] },
      }),
      signal: AbortSignal.timeout(55000),
    });
    const result = await upstream.json().catch(() => ({}));
    if (!upstream.ok) {
      console.error("Gemini TTS error", upstream.status, result);
      return json({ error: result?.error?.message || "Não foi possível gerar o áudio." }, 502);
    }
    const audio = (result?.steps || []).flatMap((s: any) => s.content || []).filter((p: any) => p.type === "audio").at(-1)?.data;
    if (!audio) return json({ error: "O serviço não devolveu áudio." }, 502);
    return new Response(decodeBase64(audio), { headers: { ...cors, "Content-Type": "audio/wav", "Cache-Control": "no-store" } });
  }
  return json({ error: "Acção inválida." }, 400);
});