(function () {
  "use strict";
  function initSiteAssistant() {
    const calculator = document.getElementById("sciCalcBtn")?.closest("article.card");
    if (!calculator || document.getElementById("assistente-ia")) return;
    const card = document.createElement("article");
    card.className = "card site-ai-card";
    card.id = "assistente-ia";
    card.innerHTML = `
      <style>
        .site-ai-card{grid-column:1/-1;min-width:0;background:linear-gradient(145deg,#fff,#f2f8ff);border:1px solid #c8dff3}
        .site-ai-head{display:flex;gap:12px;align-items:center}.site-ai-mark{display:grid;place-items:center;flex:0 0 46px;height:46px;border-radius:14px;background:linear-gradient(135deg,#1769aa,#102a43);color:white;font-size:25px}
        .site-ai-head h3{margin:0;color:#123b61}.site-ai-head p{margin:4px 0;color:#607086}.site-ai-messages{display:flex;flex-direction:column;gap:9px;max-height:350px;overflow:auto;padding:12px;margin:12px 0;background:#f7fbff;border:1px solid #d9e8f5;border-radius:12px}
        .site-ai-msg{white-space:pre-wrap;overflow-wrap:anywhere;padding:11px 13px;border-radius:12px;max-width:95%;line-height:1.55}.site-ai-msg.ai{align-self:flex-start;background:#e7f2fc;color:#173b5d}.site-ai-msg.me{align-self:flex-end;background:#1769aa;color:white}
        .site-ai-card textarea{display:block;width:100%;resize:vertical;min-height:62px;border:1px solid #c8d8e8;border-radius:8px;padding:12px;background:white;color:#18324b}.site-ai-buttons{display:flex;flex-wrap:wrap;gap:9px;margin-top:10px}.site-ai-buttons button:disabled{opacity:.6;cursor:wait}.site-ai-status,.site-ai-note{font-size:12px;color:#607086}
        @media(max-width:600px){.site-ai-head{align-items:flex-start}.site-ai-msg{max-width:100%}.site-ai-buttons button{flex:1}}
      </style>
      <div class="site-ai-head"><span class="site-ai-mark" aria-hidden="true">✦</span><div><h3>ChatGPT — Assistente inteligente</h3><p>Faça perguntas e receba ajuda directamente no Faz Tudo Tecnologia.</p></div></div>
      <div class="site-ai-messages" id="siteAiMessages" role="log" aria-live="polite"><div class="site-ai-msg ai">Olá! Sou o assistente do Faz Tudo Tecnologia. Em que posso ajudar?</div></div>
      <form id="siteAiForm"><label for="siteAiInput">A sua mensagem</label><textarea id="siteAiInput" maxlength="4000" rows="2" required placeholder="Escreva a sua pergunta…"></textarea>
        <div class="site-ai-buttons"><button class="btn-red" id="siteAiSend" type="submit">Enviar mensagem</button><button class="btn-dark" id="siteAiNew" type="button">Nova conversa</button></div>
      </form><p id="siteAiStatus" class="site-ai-status" role="status">A ligação requer a função segura publicada no Supabase.</p>
      <p class="site-ai-note">Não partilhe palavras-passe, códigos bancários ou informações confidenciais. As respostas podem conter erros.</p>`;
    calculator.insertAdjacentElement("afterend", card);

    const form = card.querySelector("#siteAiForm"), input = card.querySelector("#siteAiInput");
    const messagesEl = card.querySelector("#siteAiMessages"), status = card.querySelector("#siteAiStatus");
    const send = card.querySelector("#siteAiSend"), newChat = card.querySelector("#siteAiNew");
    const history = [];
    const addMessage = (text, who) => {
      const el = document.createElement("div"); el.className = "site-ai-msg " + who; el.textContent = text;
      messagesEl.appendChild(el); messagesEl.scrollTop = messagesEl.scrollHeight; return el;
    };
    newChat.addEventListener("click", () => { history.length = 0; messagesEl.replaceChildren(); addMessage("Conversa reiniciada. Em que posso ajudar?", "ai"); status.textContent = "Nova conversa iniciada."; input.focus(); });
    form.addEventListener("submit", async (event) => {
      event.preventDefault(); const question = input.value.trim();
      if (!question || send.disabled) return;
      addMessage(question, "me"); history.push({role:"user",content:question}); input.value = "";
      send.disabled = true; newChat.disabled = true; status.textContent = "A preparar resposta…";
      const pending = addMessage("A pensar…", "ai");
      try {
        const key = "sb_publishable_Whcxweh1gjH2wPoQ47spvg_f-vhZl1u";
        const response = await fetch("https://atrlbhisqmtuyopibjtu.supabase.co/functions/v1/site-assistant", {
          method:"POST", headers:{"Content-Type":"application/json","apikey":key,"Authorization":"Bearer "+key},
          body:JSON.stringify({messages:history.slice(-12)})
        });
        let data = {}; try { data = await response.json(); } catch (_) {}
        if (!response.ok) throw new Error(data.error || "A função de IA não está disponível (HTTP " + response.status + ").");
        const answer = String(data.reply || "Não recebi uma resposta válida.");
        pending.textContent = answer; history.push({role:"assistant",content:answer}); status.textContent = "Resposta recebida.";
      } catch (error) {
        pending.textContent = "Não foi possível ligar ao assistente. O administrador deve publicar a função no Supabase e configurar a chave da API no servidor.";
        status.textContent = error && error.message ? error.message : "Falha de ligação.";
        if (history.length) history.pop();
      } finally { send.disabled = false; newChat.disabled = false; input.focus(); }
    });
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", initSiteAssistant);
  else initSiteAssistant();
})();