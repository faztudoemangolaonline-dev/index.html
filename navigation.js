/* Navegação modular optimizada — Faz Tudo Tecnologia */
(() => {
  "use strict";
  if (window.__FAZTUDO_NAV_V2__) return;
  window.__FAZTUDO_NAV_V2__ = true;

  const SUPPORT_RE = /(?:\+?244[\s.-]*)?950[\s.-]*822[\s.-]*328/g;
  const SKIP = /^(SCRIPT|STYLE|NOSCRIPT|TEXTAREA|INPUT)$/i;
  const BRAND_RE = /Música de Ananias Pedro/gi;

  function maskTextNode(node) {
    if (!node || !node.parentElement || SKIP.test(node.parentElement.tagName)) return;
    const value = node.nodeValue || "";
    if (!/950[\s.-]*822[\s.-]*328|Música de Ananias Pedro/i.test(value)) return;
    SUPPORT_RE.lastIndex = 0;
    node.nodeValue = value.replace(SUPPORT_RE, "2328").replace(BRAND_RE, "MUSICA ANGOLANA DO GHETTO E DA CITY");
  }

  function maskLinks(root) {
    if (!root || root.nodeType !== Node.ELEMENT_NODE) return;
    const selector = 'a[href*="950822328"],a[href*="244950822328"]';
    const links = [];
    if (root.matches && root.matches(selector)) links.push(root);
    if (root.querySelectorAll) root.querySelectorAll(selector).forEach(a => links.push(a));
    for (const a of links) {
      if (!/whatsapp|wa\.me|api\.whatsapp|tel:/i.test(a.href)) continue;
      a.setAttribute("aria-label", "Contactar apoio Faz Tudo Tecnologia — final 2328");
      if (/950[\s.-]*822[\s.-]*328/.test(a.textContent)) a.textContent = "2328";
    }
  }

  function maskSubtree(root) {
    if (!root) return;
    if (root.nodeType === Node.TEXT_NODE) { maskTextNode(root); return; }
    if (root.nodeType !== Node.ELEMENT_NODE && root !== document) return;
    if (root.nodeType === Node.ELEMENT_NODE && SKIP.test(root.tagName)) return;
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    while (walker.nextNode()) maskTextNode(walker.currentNode);
    if (root.nodeType === Node.ELEMENT_NODE) maskLinks(root);
    else document.querySelectorAll('a[href*="950822328"],a[href*="244950822328"]').forEach(a => maskLinks(a.parentElement || a));
  }

  function collectLinks() {
    const found = new Map();
    const add = (label, href) => {
      if (!label || !href || href === "#") return;
      if (/admin|painel|logout|sair/i.test(label + " " + href)) return;
      const key = href.trim();
      if (!found.has(key)) found.set(key, { label: label.trim().replace(/\s+/g, " "), href: key });
    };
    document.querySelectorAll("header nav a, nav a, [role='navigation'] a").forEach(a => add(a.textContent, a.getAttribute("href")));
    [
      ["Início", "#inicio"], ["Serviços", "#servicos"], ["Planos", "#planos"],
      ["Contactos", "#contacto"], ["Música Angolana", "./musica-angolana.html"],
      ["Criar contas digitais", "./contas-digitais.html"],
      ["WhatsApp — apoio 2328", "https://wa.me/244950822328"]
    ].forEach(([label, href]) => {
      if (href.startsWith("#") && !document.querySelector(href)) return;
      add(label, href);
    });
    return [...found.values()].slice(0, 18);
  }

  function installNavigation() {
    if (document.getElementById("faztudo-accessible-navigation")) return;
    const links = collectLinks();
    if (!links.length) return;
    const style = document.createElement("style");
    style.id = "faztudo-navigation-style";
    style.textContent = `
      #faztudo-accessible-navigation{position:sticky;top:0;z-index:10000;background:#14212d;color:#fff;display:flex;align-items:center;justify-content:space-between;gap:12px;padding:10px 14px;box-shadow:0 3px 14px rgba(0,0,0,.18);transform:translateY(0);transition:transform .22s ease}
      #faztudo-accessible-navigation.ft-hidden{transform:translateY(-120%)}
      #faztudo-accessible-navigation .ft-brand{font-weight:800;color:#fff;text-decoration:none;white-space:nowrap}
      #faztudo-accessible-navigation details{position:relative}
      #faztudo-accessible-navigation summary{cursor:pointer;list-style:none;border:1px solid #ffffff66;border-radius:8px;padding:8px 12px;font-weight:700}
      #faztudo-accessible-navigation summary::-webkit-details-marker{display:none}
      #faztudo-accessible-navigation .ft-links{position:absolute;right:0;top:calc(100% + 8px);min-width:230px;max-height:70vh;overflow:auto;background:#fff;color:#14212d;border-radius:10px;padding:8px;box-shadow:0 8px 28px rgba(0,0,0,.24);display:flex;flex-direction:column;gap:3px}
      #faztudo-accessible-navigation .ft-links a{color:#14212d;text-decoration:none;padding:10px;border-radius:7px}
      #faztudo-accessible-navigation .ft-links a:hover,#faztudo-accessible-navigation .ft-links a:focus{background:#eaf2f8}
      #faztudo-accessible-navigation a:focus-visible,#faztudo-accessible-navigation summary:focus-visible{outline:3px solid #ffcc00;outline-offset:2px}
      @media(min-width:900px){#faztudo-accessible-navigation{padding-inline:clamp(16px,4vw,48px)}}
      @media(prefers-reduced-motion:reduce){#faztudo-accessible-navigation{transition:none}}
    `;
    document.head.appendChild(style);
    const bar = document.createElement("div");
    bar.id = "faztudo-accessible-navigation";
    bar.setAttribute("role", "navigation");
    bar.setAttribute("aria-label", "Navegação principal Faz Tudo Tecnologia");
    const brand = document.createElement("a");
    brand.className = "ft-brand"; brand.href = "./#inicio"; brand.textContent = "FAZ TUDO TECNOLOGIA";
    const details = document.createElement("details");
    const summary = document.createElement("summary"); summary.textContent = "☰ Explorar";
    const menu = document.createElement("div"); menu.className = "ft-links";
    links.forEach(({label, href}) => {
      const a = document.createElement("a"); a.href = href; a.textContent = label;
      if (/^https?:\/\//i.test(href)) { a.target = "_blank"; a.rel = "noopener noreferrer"; }
      a.addEventListener("click", () => { details.open = false; });
      menu.appendChild(a);
    });
    details.append(summary, menu); bar.append(brand, details);
    document.body.insertBefore(bar, document.body.firstChild);
    let lastY = window.scrollY, scheduled = false;
    window.addEventListener("scroll", () => {
      if (scheduled) return;
      scheduled = true;
      window.requestAnimationFrame(() => {
        const y = window.scrollY;
        if (y < 40 || y < lastY - 4) bar.classList.remove("ft-hidden");
        else if (y > lastY + 4 && !details.open) bar.classList.add("ft-hidden");
        lastY = y; scheduled = false;
      });
    }, { passive: true });
  }

  function start() {
    maskSubtree(document);
    installNavigation();
    const observer = new MutationObserver(records => {
      for (const record of records) {
        if (record.type === "characterData") maskTextNode(record.target);
        for (const node of record.addedNodes || []) {
          if (node.nodeType === Node.TEXT_NODE) maskTextNode(node);
          else if (node.nodeType === Node.ELEMENT_NODE && node.id !== "faztudo-accessible-navigation" && !node.closest("#faztudo-accessible-navigation")) maskSubtree(node);
        }
      }
    });
    observer.observe(document.body, { subtree: true, childList: true, characterData: true });
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", start, { once: true });
  else start();
})();
