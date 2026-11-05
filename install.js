(function () {
  "use strict";
  if (window.__FAZTUDO_INSTALL_UI__) return;
  window.__FAZTUDO_INSTALL_UI__ = true;

  var promptEvent = null;
  var banner = null;
  var isAndroid = /Android/i.test(navigator.userAgent || "");
  var isIOS = /iPhone|iPad|iPod/i.test(navigator.userAgent || "");

  function isStandalone() {
    var standalone = false;
    try {
      standalone = !!(window.matchMedia &&
        window.matchMedia("(display-mode: standalone)").matches);
    } catch (e) {}
    return standalone || navigator.standalone === true;
  }

  function removeBanner() {
    if (banner && banner.parentNode) banner.parentNode.removeChild(banner);
    banner = null;
  }

  function showHelp() {
    if (document.getElementById("ft-install-help")) return;
    var overlay = document.createElement("div");
    overlay.id = "ft-install-help";
    overlay.setAttribute("role", "dialog");
    overlay.setAttribute("aria-modal", "true");
    overlay.style.cssText = "position:fixed;inset:0;z-index:2147483000;background:rgba(0,0,0,.72);display:flex;align-items:center;justify-content:center;padding:16px";
    var panel = document.createElement("div");
    panel.style.cssText = "width:100%;max-width:440px;max-height:90%;overflow:auto;background:#fff;color:#172033;border-radius:16px;padding:21px;font:16px/1.5 Arial,sans-serif";
    var title = document.createElement("h2");
    title.style.cssText = "margin:0 0 12px;font-size:21px";
    title.textContent = "Como instalar o Faz Tudo Tecnologia";
    var message = document.createElement("p");

    if (isAndroid) {
      message.textContent = "1. Abra o site no Chrome actualizado. 2. Toque no menu ⋮ no canto superior. 3. Escolha «Instalar aplicação» ou «Adicionar ao ecrã principal». 4. Confirme. Se só aparecer «Adicionar ao ecrã principal», será criado um atalho para abrir o site. Android 5, 8 e 9 dependem da versão do navegador; alguns navegadores antigos ou de TV não suportam a instalação como aplicação.";
    } else if (isIOS) {
      message.textContent = "Abra este site no Safari, toque em Partilhar e escolha «Adicionar ao ecrã principal».";
    } else {
      message.textContent = "Abra o menu do navegador e escolha «Instalar aplicação» ou «Adicionar ao ecrã inicial», se essa opção estiver disponível.";
    }

    var close = document.createElement("button");
    close.type = "button";
    close.textContent = "Fechar";
    close.style.cssText = "padding:11px 18px;background:#1769aa;color:#fff;border:0;border-radius:9px;font-weight:bold";
    close.onclick = function() {
      if (overlay.parentNode) overlay.parentNode.removeChild(overlay);
    };
    panel.appendChild(title);
    panel.appendChild(message);
    panel.appendChild(close);
    overlay.appendChild(panel);
    overlay.onclick = function(event) {
      if (event.target === overlay && overlay.parentNode) {
        overlay.parentNode.removeChild(overlay);
      }
    };
    document.body.appendChild(overlay);
  }

  function tryInstall() {
    if (isStandalone()) return;
    if (promptEvent) {
      var savedEvent = promptEvent;
      promptEvent = null;
      try {
        savedEvent.prompt();
        if (savedEvent.userChoice && typeof savedEvent.userChoice.then === "function") {
          savedEvent.userChoice.then(function(choice) {
            if (choice && choice.outcome === "accepted") {
              removeBanner();
            } else if (banner) {
              var button = banner.querySelector("button[data-install]");
              if (button) button.textContent = "Instalar";
            }
          }, showHelp);
        } else {
          showHelp();
        }
      } catch (error) {
        showHelp();
      }
      return;
    }
    showHelp();
  }

  function showBanner() {
    if (banner || isStandalone() || !document.body) return;
    banner = document.createElement("aside");
    banner.id = "ft-install-banner";
    banner.style.cssText = "position:fixed;left:12px;right:12px;bottom:12px;z-index:2147482000;display:flex;align-items:center;gap:10px;background:#14212d;color:#fff;padding:12px;border-radius:13px;box-shadow:0 5px 24px rgba(0,0,0,.35);font:14px Arial,sans-serif";
    var label = document.createElement("div");
    label.style.cssText = "flex:1;line-height:1.35";
    label.textContent = "Instale ou adicione o Faz Tudo Tecnologia ao ecrã inicial.";
    var install = document.createElement("button");
    install.type = "button";
    install.setAttribute("data-install", "1");
    install.textContent = "Instalar";
    install.style.cssText = "padding:10px 13px;border:0;border-radius:8px;background:#f4c542;color:#172033;font-weight:bold";
    install.onclick = tryInstall;

    var close = document.createElement("button");
    close.type = "button";
    close.textContent = "×";
    close.setAttribute("aria-label", "Fechar aviso de instalação");
    close.style.cssText = "border:0;background:transparent;color:#fff;font-size:23px";
    close.onclick = removeBanner;

    banner.appendChild(label);
    banner.appendChild(install);
    banner.appendChild(close);
    document.body.appendChild(banner);
  }

  window.addEventListener("beforeinstallprompt", function(event) {
    if (event.preventDefault) event.preventDefault();
    promptEvent = event;
    showBanner();
    var button = banner && banner.querySelector("button[data-install]");
    if (button) button.textContent = "Instalar";
  });

  window.addEventListener("appinstalled", function() {
    promptEvent = null;
    removeBanner();
  });

  function registerWorker() {
    if ("serviceWorker" in navigator &&
        (location.protocol === "https:" || location.hostname === "localhost")) {
      navigator.serviceWorker.register("./worker.js", { scope: "./" }).then(function() {
        // Registado com sucesso.
      }, function(error) {
        if (window.console && console.warn) console.warn("PWA: falha ao registar o service worker", error);
      });
    }
  }

  function init() {
    registerWorker();
    if (!isStandalone()) showBanner();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init, false);
  } else {
    init();
  }
}());
