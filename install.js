(function () {
  "use strict";
  if (window.__FAZTUDO_INSTALL_UI__) return;
  window.__FAZTUDO_INSTALL_UI__ = true;

  var promptEvent = null;
  var banner = null;
  var isAndroid = /Android/i.test(navigator.userAgent || "");
  var isIOS = /iPhone|iPad|iPod/i.test(navigator.userAgent || "");

  function isStandalone() {
    var media = false;
    try { media = !!(window.matchMedia && window.matchMedia("(display-mode: standalone)").matches); } catch (e) {}
    return media || navigator.standalone === true;
  }

  function removeBanner() {
    if (banner && banner.parentNode) banner.parentNode.removeChild(banner);
    banner = null;
  }

  function showFallback() {
    if (document.getElementById("ft-install-help")) return;
    var overlay = document.createElement("div");
    overlay.id = "ft-install-help";
    overlay.setAttribute("role", "dialog");
    overlay.setAttribute("aria-modal", "true");
    overlay.style.cssText = "position:fixed;inset:0;z-index:2147483000;background:rgba(0,0,0,.68);display:flex;align-items:center;justify-content:center;padding:18px";
    var panel = document.createElement("div");
    panel.style.cssText = "width:100%;max-width:440px;background:#fff;color:#172033;border-radius:16px;padding:22px;font:16px/1.5 Arial,sans-serif;box-shadow:0 12px 40px rgba(0,0,0,.3)";
    var title = document.createElement("h2");
    title.textContent = "Instalação neste navegador";
    title.style.cssText = "margin:0 0 12px;font-size:22px";
    var message = document.createElement("p");
    if (isAndroid) {
      message.textContent = "Este navegador não disponibilizou a instalação directa. Para instalar, abra este mesmo endereço no Google Chrome actualizado e toque em Instalar. Se o Chrome também não mostrar a opção, este dispositivo/navegador não permite a instalação automática de aplicações web.";
    } else if (isIOS) {
      message.textContent = "No iPhone ou iPad, abra este site no Safari, toque em Partilhar e escolha Adicionar ao ecrã principal.";
    } else {
      message.textContent = "Este navegador não disponibilizou a instalação directa. Abra o menu do navegador e escolha Instalar aplicação ou Adicionar ao ecrã inicial, se a opção estiver disponível.";
    }
    var close = document.createElement("button");
    close.type = "button";
    close.textContent = "Fechar";
    close.style.cssText = "padding:11px 18px;background:#1769aa;color:#fff;border:0;border-radius:9px;font-weight:bold";
    close.onclick = function () { if (overlay.parentNode) overlay.parentNode.removeChild(overlay); };
    panel.appendChild(title);
    panel.appendChild(message);
    panel.appendChild(close);
    overlay.appendChild(panel);
    overlay.onclick = function (event) {
      if (event.target === overlay && overlay.parentNode) overlay.parentNode.removeChild(overlay);
    };
    document.body.appendChild(overlay);
  }

  function tryInstall() {
    if (isStandalone()) return;
    if (promptEvent) {
      var event = promptEvent;
      promptEvent = null;
      try {
        event.prompt();
        Promise.resolve(event.userChoice).then(function (choice) {
          if (choice && choice.outcome === "accepted") {
            removeBanner();
          } else if (banner) {
            var button = banner.querySelector("button[data-install]");
            if (button) button.textContent = "Tentar novamente";
          }
        }).catch(showFallback);
      } catch (error) {
        showFallback();
      }
      return;
    }

    // Alguns navegadores Android não expõem beforeinstallprompt.
    // Tenta abrir a mesma página no Chrome; a instalação continua a exigir confirmação do utilizador.
    if (isAndroid && !/Chrome\//i.test(navigator.userAgent || "")) {
      var target = location.href.split("#")[0] + location.hash;
      var fallback = encodeURIComponent(target);
      location.href = "intent://" + location.host + location.pathname + location.search + location.hash +
        "#Intent;scheme=https;package=com.android.chrome;S.browser_fallback_url=" + fallback + ";end";
      window.setTimeout(showFallback, 1800);
      return;
    }
    showFallback();
  }

  function showBanner() {
    if (banner || isStandalone() || !document.body) return;
    try { if (sessionStorage.getItem("ft-install-dismissed") === "1") return; } catch (e) {}

    banner = document.createElement("aside");
    banner.id = "ft-install-banner";
    banner.style.cssText = "position:fixed;left:12px;right:12px;bottom:12px;z-index:2147482000;display:flex;align-items:center;gap:10px;background:#14212d;color:#fff;padding:12px;border-radius:13px;box-shadow:0 5px 24px rgba(0,0,0,.35);font:14px Arial,sans-serif";
    var label = document.createElement("div");
    label.style.cssText = "flex:1;line-height:1.35";
    label.textContent = "Instale o Faz Tudo Tecnologia no seu dispositivo.";
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
    close.onclick = function () {
      removeBanner();
      try { sessionStorage.setItem("ft-install-dismissed", "1"); } catch (e) {}
    };
    banner.appendChild(label);
    banner.appendChild(install);
    banner.appendChild(close);
    document.body.appendChild(banner);
  }

  window.addEventListener("beforeinstallprompt", function (event) {
    event.preventDefault();
    promptEvent = event;
    showBanner();
    var button = banner && banner.querySelector("button[data-install]");
    if (button) button.textContent = "Instalar";
  });

  window.addEventListener("appinstalled", function () {
    promptEvent = null;
    removeBanner();
  });

  function init() {
    if (!isStandalone()) showBanner();
  }
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init, false);
  } else {
    init();
  }
}());
