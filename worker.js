const CACHE_NAME = "faz-tudo-v21";
const HTML_REVALIDATE_MS = 15 * 60 * 1000;

const ASSETS = [
  "./manifest.json",
  "./navigation.js",
  "./image-loader.js",
  "./install.js",
  "./icon-192.png",
  "./icon-512.png",
  "./icon-512-maskable.png"
];

async function enhanceHomepage(response) {
  const contentType = response.headers.get("content-type") || "";
  if (!contentType.includes("text/html")) return response;

  // Inspecciona apenas o início do HTML para evitar reconstruir a página inteira.
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
      if (head.includes("navigation.js") && head.includes("install.js")) return response;
    }
  } catch (_) {}

  // Compatibilidade para páginas antigas que ainda não declaram os scripts.
  const original = await response.clone().text();
  if (original.includes("install.js") && original.includes("navigation.js")) return response;

  const injected = '<script src="./navigation.js" defer></script><script src="./install.js" defer></script>';
  const html = original.replace(/<\/body\s*>/i, injected + "</body>");
  const headers = new Headers(response.headers);
  headers.delete("content-length");
  headers.set("cache-control", "no-cache");
  return new Response(html, {status: response.status, statusText: response.statusText, headers});
}

async function fetchAndCache(request, cacheKey, enhance = false) {
  const response = await fetch(request);
  if (response && response.ok) {
    const finalResponse = enhance ? await enhanceHomepage(response) : response;
    const headers = new Headers(finalResponse.headers);
    headers.set("x-faztudo-cached-at", String(Date.now()));
    const stored = new Response(finalResponse.clone().body, {
      status: finalResponse.status,
      statusText: finalResponse.statusText,
      headers
    });
    const cache = await caches.open(CACHE_NAME);
    await cache.put(cacheKey, stored);
    return finalResponse;
  }
  return response;
}

self.addEventListener("install", event => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(ASSETS))
      .catch(error => console.warn("Cache inicial parcial:", error))
  );
  self.skipWaiting();
});

self.addEventListener("activate", event => {
  event.waitUntil(caches.keys().then(keys =>
    Promise.all(keys.filter(key =>
      key.startsWith("faz-tudo-") && key !== CACHE_NAME
    ).map(key => caches.delete(key)))
  ));
  self.clients.claim();
});

self.addEventListener("fetch", event => {
  if (event.request.method !== "GET") return;
  const url = new URL(event.request.url);
  if (url.origin !== self.location.origin) return;

  const isHomepage =
    url.pathname.endsWith("/index.html") ||
    url.pathname.endsWith("/index.html/") ||
    url.pathname.endsWith("/");

  if (isHomepage && event.request.mode === "navigate") {
    const cacheUrl = new URL(url.pathname, url.origin);
    const cacheKey = new Request(cacheUrl.toString(), {method: "GET"});
    const cachedPromise = caches.open(CACHE_NAME).then(cache => cache.match(cacheKey));

    // A página em cache abre sem esperar pela rede. Só volta a descarregar
    // o HTML quando ainda não existe cache ou quando tem mais de quinze minutos.
    const updatePromise = cachedPromise.then(cached => {
      const savedAt = Number(cached?.headers.get("x-faztudo-cached-at") || 0);
      const isStale = !savedAt || Date.now() - savedAt > HTML_REVALIDATE_MS;
      return (!cached || isStale) ? fetchAndCache(event.request, cacheKey, true) : null;
    });

    event.waitUntil(updatePromise.then(() => undefined).catch(() => undefined));
    event.respondWith(cachedPromise.then(cached => cached || updatePromise));
    return;
  }

  // Outras páginas continuam a tentar a rede primeiro, com cache como reserva.
  event.respondWith(
    fetch(event.request).then(response => {
      if (response && response.ok) {
        const copy = response.clone();
        caches.open(CACHE_NAME).then(cache => cache.put(event.request, copy));
      }
      return response;
    }).catch(() => caches.match(event.request))
  );
});
