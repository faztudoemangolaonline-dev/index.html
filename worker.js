const CACHE_NAME = "faz-tudo-v11";

// Cache apenas recursos leves. A página principal tem cerca de 3,9 MB
// e não deve bloquear a instalação da PWA através de cache.addAll().
const ASSETS = [
  "./manifest.json",
  "./navigation.js",
  "./icon-192.png",
  "./icon-512.png",
  "./icon-512-maskable.png"
];

async function enhanceHomepage(response) {
  const contentType = response.headers.get("content-type") || "";
  if (!contentType.includes("text/html")) return response;

  const original = await response.clone().text();
  if (original.includes("navigation.js")) return response;

  const injected = '<script src="./navigation.js" defer></script>';
  const html = original.replace(/<\/body\s*>/i, injected + "</body>");
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
    // Usa uma chave sem parâmetros de campanha (utm_*) para reutilizar cache.
    const cacheUrl = new URL(url.pathname, url.origin);
    const cacheKey = new Request(cacheUrl.toString(), { method: "GET" });

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

    // Actualiza a cópia em segundo plano sem atrasar a página já em cache.
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
