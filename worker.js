const CACHE_NAME = "faz-tudo-v14";

// Recursos pequenos e essenciais; a página principal é guardada apenas
// depois de ser visitada, para não bloquear a instalação da aplicação.
const ASSETS = [
  "./manifest.json",
  "./navigation.js",
  "./install.js",
  "./icon-192.png",
  "./icon-512.png",
  "./icon-512-maskable.png"
];

async function enhanceHomepage(response) {
  const contentType = response.headers.get("content-type") || "";
  if (!contentType.includes("text/html")) return response;

  // Primeiro inspecciona apenas o início do HTML. Se os scripts já estiverem
  // declarados no cabeçalho, evita ler e reconstruir os quase 4 MB da página.
  try {
    const reader = response.clone().body?.getReader();
    if (reader) {
      let prefix = new Uint8Array(0);
      while (prefix.length < 16384) {
        const part = await reader.read();
        if (part.done) break;
        const merged = new Uint8Array(prefix.length + part.value.length);
        merged.set(prefix);
        merged.set(part.value, prefix.length);
        prefix = merged;
        if (prefix.length >= 16384) break;
      }
      try { await reader.cancel(); } catch (_) {}
      const head = new TextDecoder().decode(prefix);
      if (head.includes("navigation.js") && head.includes("install.js")) {
        return response;
      }
    }
  } catch (_) {
    // Navegadores antigos seguem pelo método compatível abaixo.
  }

  // Compatibilidade: injecção antiga, apenas quando os scripts não aparecem
  // no início do documento.
  const original = await response.clone().text();
  if (original.includes("install.js") && original.includes("navigation.js")) return response;

  const injected = '<script src="./navigation.js" defer></script><script src="./install.js" defer></script>';
  const html = original.replace(/<\\/body\\s*>/i, injected + "</body>");
  const headers = new Headers(response.headers);
  headers.delete("content-length");
  headers.set("cache-control", "no-cache");
  return new Response(html, {
    status: response.status,
    statusText: response.statusText,
    headers
  });
}

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(ASSETS))
      .catch(error => console.warn("Cache inicial parcial:", error))
  );
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(caches.keys().then(keys =>
    Promise.all(keys.filter(key =>
      key.startsWith("faz-tudo-") && key !== CACHE_NAME
    ).map(key => caches.delete(key)))
  ));
  self.clients.claim();
});

self.addEventListener("fetch", (event) => {
  if (event.request.method !== "GET") return;

  const url = new URL(event.request.url);
  if (url.origin !== self.location.origin) return;

  const isHomepage =
    url.pathname.endsWith("/index.html") ||
    url.pathname.endsWith("/index.html/") ||
    url.pathname.endsWith("/");

  if (isHomepage && event.request.mode === "navigate") {
    const cacheUrl = new URL(url.pathname, url.origin);
    const cacheKey = new Request(cacheUrl.toString(), { method: "GET" });

    // Uma única actualização em segundo plano; a cópia em cache abre logo.
    const update = fetch(event.request)
      .then(enhanceHomepage)
      .then(async response => {
        if (response && response.ok) {
          const cache = await caches.open(CACHE_NAME);
          await cache.put(cacheKey, response.clone());
        }
        return response;
      });

    event.respondWith(
      caches.open(CACHE_NAME).then(async cache =>
        (await cache.match(cacheKey)) || update
      ).catch(() => update)
    );
    event.waitUntil(update.then(() => undefined).catch(() => undefined));
    return;
  }

  event.respondWith(
    fetch(event.request).then(response => {
      if (response && response.ok) {
        const copy = response.clone();
        caches.open(CACHE_NAME).then(cache =>
          cache.put(event.request, copy)
        );
      }
      return response;
    }).catch(() => caches.match(event.request))
  );
});
