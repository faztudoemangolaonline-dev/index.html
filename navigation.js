(function () {
  "use strict";
  if (window.__FAZTUDO_NAV_V4__) return;
  window.__FAZTUDO_NAV_V4__ = true;

  function hasClass(el, name) {
    return (" " + el.className + " ").indexOf(" " + name + " ") !== -1;
  }
  function addClass(el, name) {
    if (!hasClass(el, name)) el.className = (el.className ? el.className + " " : "") + name;
  }
  function removeClass(el, name) {
    el.className = (" " + el.className + " ").replace(" " + name + " ", " ").replace(/^\s+|\s+$/g, "");
  }
  function closestLink(target, nav) {
    while (target && target !== nav) {
      if (target.tagName && target.tagName.toLowerCase() === "a") return target;
      target = target.parentNode;
    }
    return null;
  }
  function init() {
    var header = document.querySelector("body>header");
    var nav = header && header.querySelector("nav");
    var wrap, button, style;
    if (!header || !nav) return;

    nav.setAttribute("aria-label", "Navegação principal");
    if (!nav.id) nav.id = "faztudo-main-nav";
    button = header.querySelector("[data-ft-menu-toggle]");
    if (!button) {
      button = document.createElement("button");
      button.type = "button";
      button.setAttribute("data-ft-menu-toggle", "1");
      button.textContent = "☰ Menu";
      button.setAttribute("aria-controls", nav.id);
      button.setAttribute("aria-expanded", "false");
      button.style.cssText = "display:none;padding:9px 13px;border:1px solid #1769aa;border-radius:8px;background:#1769aa;color:#fff;font-weight:700";
      button.onclick = function () {
        var open = button.getAttribute("aria-expanded") !== "true";
        button.setAttribute("aria-expanded", open ? "true" : "false");
        if (open) addClass(nav, "ftt-menu-open");
        else removeClass(nav, "ftt-menu-open");
      };
      wrap = header.querySelector(".nav");
      if (wrap) wrap.appendChild(button);

      style = document.createElement("style");
      style.id = "ftt-mobile-nav-style";
      style.type = "text/css";
      style.appendChild(document.createTextNode("@media(max-width:780px){header .nav{position:relative}header [data-ft-menu-toggle]{display:inline-block!important}header nav:not(.ftt-menu-open){display:none!important}header nav.ftt-menu-open{display:flex!important;flex-direction:column;align-items:flex-start;width:100%;padding:12px 0}header nav.ftt-menu-open a{padding:7px 0}}"));
      document.head.appendChild(style);
    }

    nav.addEventListener("click", function (event) {
      var link = closestLink(event.target || event.srcElement, nav);
      var mobile = window.matchMedia ? window.matchMedia("(max-width:780px)").matches : window.innerWidth <= 780;
      if (link && mobile) {
        removeClass(nav, "ftt-menu-open");
        button.setAttribute("aria-expanded", "false");
      }
    }, false);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init, false);
  } else {
    init();
  }
}());
