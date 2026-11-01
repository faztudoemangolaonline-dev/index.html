const CACHE_NAME = "faz-tudo-v7";
const ASSETS = [
  "./",
  "./index.html",
  "./contas-digitais.html",
  "./musica-angolana.html",
  "./manifest.json",
  "./icon-192.png",
  "./icon-512.png",
  "./icon-512-maskable.png"
];

async function enhanceHomepage(response) {
  const contentType = response.headers.get("content-type") || "";
  if (!contentType.includes("text/html")) return response;
  const original = await response.text();
  const injected = `
<script>
(function(){
  const replaceVisibleText = () => {
    const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
    const nodes = [];
    while (walker.nextNode()) nodes.push(walker.currentNode);
    for (const node of nodes) {
      if (!node.parentElement || /^(SCRIPT|STYLE|NOSCRIPT|TEXTAREA|INPUT)$/i.test(node.parentElement.tagName)) continue;
      if (/950[\\s.-]*822[\\s.-]*328/.test(node.nodeValue) || /244[\\s.-]*950[\\s.-]*822[\\s.-]*328/.test(node.nodeValue)) {
        node.nodeValue = node.nodeValue.replace(/(?:\\+?244[\\s.-]*)?950[\\s.-]*822[\\s.-]*328/g, '••• ••• 2328');
      }
      node.nodeValue = node.nodeValue.replace(/Música de Ananias Pedro/gi, 'MUSICA ANGOLANA DO GHETTO E DA CITY');
    }
    document.querySelectorAll('a[href*="950822328"],a[href*="950%20822%20328"],a[href*="244950822328"]').forEach(a => {
      if (/whatsapp|wa\\.me|api.whatsapp|tel:/i.test(a.href) || /950.?822.?328/.test(a.textContent)) {
        a.setAttribute('aria-label', 'Contactar apoio Faz Tudo Tecnologia: final 2328');
        if (/950[\\s.-]*822[\\s.-]*328/.test(a.textContent) || /244[\\s.-]*950[\\s.-]*822[\\s.-]*328/.test(a.textContent)) a.textContent = '••• ••• 2328';
      }
    });
  };
  const addQuickLinks = () => {
    if (document.getElementById('faz-tudo-quick-links')) return;
    const nav = document.createElement('div');
    nav.id='faz-tudo-quick-links';
    nav.setAttribute('aria-label','Atalhos Faz Tudo Tecnologia');
    nav.style.cssText='display:flex;flex-wrap:wrap;gap:10px;justify-content:center;padding:12px;background:#17212b;color:#fff;position:relative;z-index:9999';
    nav.innerHTML='<a style="color:#fff;font-weight:700" href="./musica-angolana.html">🎵 MUSICA ANGOLANA DO GHETTO E DA CITY</a><a style="color:#fff;font-weight:700" href="./contas-digitais.html">Criar e-mail e contas internacionais</a><a style="color:#fff;font-weight:700" href="https://wa.me/244950822328" target="_blank" rel="noopener noreferrer">WhatsApp ••• ••• 2328</a><a style="color:#fff;font-weight:700" href="tel:+244950822328">Ligar ••• ••• 2328</a>';
    document.body.insertBefore(nav,document.body.firstChild);
  };
  const run=()=>{replaceVisibleText();addQuickLinks();};
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',run,{once:true});else run();
  new MutationObserver(()=>{replaceVisibleText();}).observe(document.documentElement,{subtree:true,childList:true,characterData:true});
})();
</script>`;
  const html = original.replace(/<\/body\s*>/i, injected + "</body>");
  const headers = new Headers(response.headers);
  headers.delete("content-length");
  headers.set("cache-control","no-cache");
  return new Response(html,{status:response.status,statusText:response.statusText,headers});
}

self.addEventListener("install", (event) => {
  event.waitUntil(caches.open(CACHE_NAME).then(cache => cache.addAll(ASSETS)));
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(key => key !== CACHE_NAME).map(key => caches.delete(key)))));
  self.clients.claim();
});

self.addEventListener("fetch", (event) => {
  if (event.request.method !== "GET") return;
  const url = new URL(event.request.url);
  const isHomepage = url.origin === self.location.origin && (url.pathname.endsWith("/index.html") || url.pathname.endsWith("/"));
  event.respondWith(
    fetch(event.request).then(async response => {
      if (response && response.ok && url.origin === self.location.origin) {
        if (isHomepage) return enhanceHomepage(response);
        const copy = response.clone();
        caches.open(CACHE_NAME).then(cache => cache.put(event.request,copy));
      }
      return response;
    }).catch(() => caches.match(event.request))
  );
});
