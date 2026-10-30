(() => {
  "use strict";
  const SUPABASE_URL = "https://atrlbhisqmtuyopibjtu.supabase.co";
  const FUNCTION_NAME = "site-assistant";
  const root = document.createElement("article");
  root.className = "card ftt-ai-card";
  root.id = "ftt-ai-assistant";
  root.innerHTML = `
    <style>
      .ftt-ai-card{grid-column:1/-1;border:1px solid #cbdced;background:linear-gradient(145deg,#fff,#f1f7ff);padding:clamp(16px,3vw,26px);overflow:hidden}
      .ftt-ai-head{display:flex;gap:12px;align-items:center;margin-bottom:12px}
      .ftt-ai-icon{width:48px;height:48px;display:grid;place-items:center;border-radius:14px;background:#1769aa;color:#fff;font-size:25px;flex-shrink:0}
      .ftt-ai-card h3{margin:0;color:#102a43}.ftt-ai-subtitle{margin:3px 0 0;color:#52677d;font-size:.94rem}
      .ftt-ai-messages{height:300px;max-height:45vh;overflow:auto;background:#fff;border:1px solid #d6e2ef;border-radius:12px;padding:12px;display:flex;flex-direction:column;gap:10px}
      .ftt-ai-msg{max-width:92%;padding:10px 12px;border-radius:12px;white-space:pre-wrap;overflow-wrap:anywhere;font-size:.96rem}
      .ftt-ai-msg.bot{align-self:flex-start;background:#edf4fb;color:#18324b}
      .ftt-ai-msg.user{align-self:flex-end;background:#1769aa;color:#fff}
      .ftt-ai-form{display:flex;gap:8px;margin-top:10px}
      .ftt-ai-input{flex:1;min-width:0;padding:12px;border:1px solid #b9cadb;border-radius:10px;font:inherit}
      .ftt-ai-send{border:0;border-radius:10px;padding:0 18px;background:#1769aa;color:#fff;font-weight:700;cursor:pointer}
      .ftt-ai-send:disabled{opacity:.6;cursor:wait}.ftt-ai-actions{display:flex;gap:8px;flex-wrap:wrap;margin-top:9px}
      .ftt-ai-actions button{border:1px solid #c6d6e5;background:#fff;color:#18324b;border-radius:8px;padding:7px 10px;cursor:pointer}
      .ftt-ai-status{min-height:1.4em;color:#607086;font-size:.85rem;margin:7px 0 0}
      @media(max-width:520px){.ftt-ai-form{flex-direction:column}.ftt-ai-send{padding:12px}.ftt-ai-messages{height:260px}}
    </style>
    <div class="ftt-ai-head"><div class="ftt-ai-icon" aria-hidden="true">✦</div><div><h3>ChatGPT — Assistente Inteligente</h3><p class="ftt-ai-subtitle">Pergunta em português. Ajuda com tecnologia, estudos, cálculos e muito mais.</p></div></div>
    <div class="ftt-ai-messages" id="fttAiMessages" role="log" aria-live="polite"><div class="ftt-ai-msg bot">Olá! Sou o assistente inteligente da Faz Tudo Tecnologia. Como posso ajudar?</div></div>
    <form class="ftt-ai-form" id="fttAiForm"><label for="fttAiInput" class="sr-only" style="position:absolute;left:-9999px">A tua pergunta</label><input class="ftt-ai-input" id="fttAiInput" maxlength="2000" autocomplete="off" placeholder="Escreve a tua pergunta..." required><button class="ftt-ai-send" id="fttAiSend" type="submit">Enviar ➤</button></form>
    <div class="ftt-ai-actions"><button type="button" id="fttAiClear">Nova conversa</button><button type="button" id="fttAiCopy">Copiar última resposta</button></div>
    <p class="ftt-ai-status" id="fttAiStatus">O assistente precisa de a função segura estar publicada no Supabase.</p>`;
  function placeAssistant() {
    const grid = document.querySelector("#ferramentas .tool-grid");
    const calc = grid && Array.from(grid.querySelectorAll("article")).find(card => /Calculadora científica/i.test(card.textContent));
    if (calc) { calc.insertAdjacentElement("afterend", root); }
    else if (grid) { grid.appendChild(root); }
    else { const section = document.querySelector("#ferramentas"); if (section) section.appendChild(root); }
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", placeAssistant); else placeAssistant();
  const history = [];
  let lastAnswer = "";
  const $ = id => document.getElementById(id);
  function addMessage(text, role) {
    const el = document.createElement("div"); el.className = "ftt-ai-msg " + role; el.textContent = text;
    $("fttAiMessages").appendChild(el); $("fttAiMessages").scrollTop = $("fttAiMessages").scrollHeight; return el;
  }
  $("fttAiForm").addEventListener("submit", async event => {
    event.preventDefault();
    const input = $("fttAiInput"), send = $("fttAiSend"), status = $("fttAiStatus");
    const question = input.value.trim(); if (!question || send.disabled) return;
    addMessage(question, "user"); input.value = ""; send.disabled = true; status.textContent = "A preparar resposta…";
    const waiting = addMessage("Estou a pensar…", "bot");
    try {
      const response = await fetch(SUPABASE_URL + "/functions/v1/" + FUNCTION_NAME, {
        method: "POST", headers: {"Content-Type":"application/json"},
        body: JSON.stringify({message:question, history:history.slice(-10)})
      });
      let data = {}; try { data = await response.json(); } catch (_) {}
      if (!response.ok) {
        if (response.status === 404 || response.status === 401) throw new Error("O assistente ainda não está publicado/configurado no Supabase.");
        throw new Error(data.error || "Não foi possível obter resposta. Tenta novamente.");
      }
      const answer = typeof data.reply === "string" ? data.reply : "";
      if (!answer) throw new Error("O serviço respondeu sem texto. Tenta novamente.");
      waiting.textContent = answer; lastAnswer = answer;
      history.push({role:"user",content:question},{role:"assistant",content:answer});
      status.textContent = "Resposta recebida.";
    } catch (error) {
      waiting.textContent = error.message || "Falha de ligação. Verifica a internet e tenta novamente.";
      status.textContent = "Não foi possível concluir o pedido.";
    } finally { send.disabled = false; input.focus(); }
  });
  $("fttAiClear").addEventListener("click", () => {
    history.length = 0; lastAnswer = ""; $("fttAiMessages").replaceChildren();
    addMessage("Conversa reiniciada. O que gostarias de saber?", "bot"); $("fttAiStatus").textContent = "Nova conversa iniciada.";
  });
  $("fttAiCopy").addEventListener("click", async () => {
    if (!lastAnswer) { $("fttAiStatus").textContent = "Ainda não há resposta para copiar."; return; }
    try { await navigator.clipboard.writeText(lastAnswer); $("fttAiStatus").textContent = "Resposta copiada."; }
    catch (_) { $("fttAiStatus").textContent = "O navegador não permitiu copiar automaticamente."; }
  });
})();