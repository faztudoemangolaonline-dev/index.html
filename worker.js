const CACHE_NAME = "faz-tudo-v10";
const ASSETS = [
  "./",
  "./index.html",
  "./contas-digitais.html",
  "./musica-angolana.html",
  "./manifest.json",
  "./navigation.js",
  "./icon-192.png",
  "./icon-512.png",
  "./icon-512-maskable.png"
];

async function enhanceHomepage(response) {
  const contentType = response.headers.get("content-type") || "";
  if (!contentType.includes("text/html")) return response;
  const original = await response.text();
  if (original.includes("navigation.js")) {
    const headers = new Headers(response.headers);
    headers.delete("content-length");
    headers.set("cache-control", "no-cache");
    return new Response(original, { status: response.status, statusText: response.statusText, headers });
  }
  const injected = '<script src="./navigation.js" defer></script>';
  const html = original.replace(/<\/body\s*>/i, injected + "</body>");
  const headers = new Headers(response.headers);
  headers.delete("content-length");
  headers.set("cache-control", "no-cache");
  return new Response(html, { status: response.status, statusText: response.statusText, headers });
}

self.addEventListener("install", (event) => {
  event.waitUntil(caches.open(CACHE_NAME).then(cache => cache.addAll(ASSETS)));
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(caches.keys().then(keys =>
    Promise.all(keys.filter(key => key.startsWith("faz-tudo-") && key !== CACHE_NAME).map(key => caches.delete(key)))
  ));
  self.clients.claim();
});

self.addEventListener("fetch", (event) => {
  if (event.request.method !== "GET") return;
  const url = new URL(event.request.url);
  const isHomepage = url.origin === self.location.origin &&
    (url.pathname.endsWith("/index.html") || url.pathname.endsWith("/"));
  event.respondWith(
    fetch(event.request).then(async response => {
      if (response && response.ok && url.origin === self.location.origin) {
        if (isHomepage) return enhanceHomepage(response);
        const copy = response.clone();
        caches.open(CACHE_NAME).then(cache => cache.put(event.request, copy));
      }
      return response;
    }).catch(() => caches.match(event.request))
  );
});
