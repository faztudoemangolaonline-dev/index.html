(function () {
  "use strict";
  if (window.__FAZTUDO_INSTALL_UI__) return;
  window.__FAZTUDO_INSTALL_UI__ = true;

  var promptEvent = null;
  var banner = null;

  function isStandalone() {
    var media = false;
    try { media = window.matchMedia && window.matchMedia("(display-mode: standalone)").matches; } catch (e) {}
    return media || window.navigator.standalone === true;
  }

  function helpText() {
    var ua = navigator.userAgent || "";
    if (/Android/i.test(ua)) {
      return "Android: abra o menu ⋮ do Chrome e escolha Instalar aplicação ou Adicionar ao ecrã inicial. Se essa opção não existir, actualize o Chrome. Em alguns navegadores de Smart TV a instalação PWA não é suportada; nesse caso abra o site no navegador.";
    }
    if (/iPhone|iPad|iPod/i.test(ua)) {
      return "No iPhone/iPad, abra no Safari, toque em Partilhar e escolha Adicionar ao ecrã principal.";
    }
    return "No computador, abra o menu do navegador e escolha Instalar Faz Tudo Tecnologia, se essa opção estiver disponível.";
  }

  function showHelp() {
    if (document.getElementById("ft-install-help")) return;
    var overlay = document.createElement("div");
    overlay.id = "ft-install-help";
    overlay.setAttribute("role", "dialog");
    overlay.style.cssText = "position:fixed;inset:0;z-index:2147483000;background:rgba(0,0,0,.65);display:flex;align-items:center;justify-content:center;padding:18px";
    var panel = document.createElement("div");
    panel.style.cssText = "max-width:440px;background:#fff;color:#172033;border-radius:14px;padding:22px;font:16px/1.5 Arial,sans-serif";
    var title = document.createElement("h2");
    title.appendChild(document.createTextNode("Instalar Faz Tudo Tecnologia"));
    var message = document.createElement("p");
    message.appendChild(document.createTextNode(helpText()));
    var close = document.createElement("button");
    close.appendChild(document.createTextNode("Fechar"));
    close.style.cssText = "padding:10px 18px;background:#1769aa;color:#fff;border:0;border-radius:8px";
    close.onclick = function () { if (overlay.parentNode) overlay.parentNode.removeChild(overlay); };
    panel.appendChild(title); panel.appendChild(message); panel.appendChild(close); overlay.appendChild(panel);
    overlay.onclick = function (event) { if (event.target === overlay && overlay.parentNode) overlay.parentNode.removeChild(overlay); };
    document.body.appendChild(overlay);
  }

  function showBanner() {
    if (banner || isStandalone() || !document.body) return;
    try { if (sessionStorage.getItem("ft-install-dismissed") === "1") return; } catch (e) {}
    banner = document.createElement("aside");
    banner.id = "ft-install-banner";
    banner.style.cssText = "position:fixed;left:12px;right:12px;bottom:12px;z-index:2147482000;display:flex;align-items:center;gap:10px;background:#14212d;color:#fff;padding:12px;border-radius:13px;box-shadow:0 5px 24px rgba(0,0,0,.35);font:14px Arial,sans-serif";
    var label = document.createElement("div");
    label.style.cssText = "flex:1";
    label.appendChild(document.createTextNode("Instale o Faz Tudo Tecnologia para abrir pelo ecrã inicial."));
    var install = document.createElement("button");
    install.appendChild(document.createTextNode("Instalar"));
    install.style.cssText = "padding:10px 13px;border:0;border-radius:8px;background:#f4c542;color:#172033;font-weight:bold";
    install.onclick = function () {
      if (promptEvent) {
        var event = promptEvent;
        promptEvent = null;
        try {
          event.prompt();
          event.userChoice.then(function (choice) {
            if (choice && choice.outcome === "accepted") {
              if (banner && banner.parentNode) banner.parentNode.removeChild(banner);
              banner = null;
            } else {
              install.textContent = "Tentar instalar";
            }
          });
        } catch (e) { install.textContent = "Ver instruções"; showHelp(); }
      } else { showHelp(); }
    };
    var close = document.createElement("button");
    close.appendChild(document.createTextNode("×"));
    close.setAttribute("aria-label", "Fechar");
    close.style.cssText = "border:0;background:transparent;color:#fff;font-size:23px";
    close.onclick = function () {
      if (banner && banner.parentNode) banner.parentNode.removeChild(banner);
      banner = null;
      try { sessionStorage.setItem("ft-install-dismissed", "1"); } catch (e) {}
    };
    banner.appendChild(label); banner.appendChild(install); banner.appendChild(close);
    document.body.appendChild(banner);
  }

  window.addEventListener("beforeinstallprompt", function (event) {
    event.preventDefault();
    promptEvent = event;
    showBanner();
  });
  window.addEventListener("appinstalled", function () {
    promptEvent = null;
    if (banner && banner.parentNode) banner.parentNode.removeChild(banner);
    banner = null;
  });
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", showBanner, false);
  } else { showBanner(); }
}());