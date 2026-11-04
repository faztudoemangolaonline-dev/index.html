"use strict";

/* Service worker compatível com navegadores Android mais antigos.
   O pré-cache é feito ficheiro a ficheiro para um recurso em falta
   não impedir a instalação do service worker. */
var CACHE_NAME = "faz-tudo-v33";
var APP_ASSETS = [
  "./",
  "./index.html",
  "./manifest.json",
  "./navigation.js",
  "./image-loader.js",
  "./install.js",
  "./icon-192.png",
  "./icon-512.png",
  "./icon-512-maskable.png"
];

self.addEventListener("install", function(event) {
  event.waitUntil(
    caches.open(CACHE_NAME).then(function(cache) {
      var tasks = APP_ASSETS.map(function(asset) {
        return cache.add(asset).catch(function(error) {
          // Um recurso individual em falta não cancela a instalação.
          return null;
        });
      });
      return Promise.all(tasks);
    }).then(function() {
      return self.skipWaiting();
    })
  );
});

self.addEventListener("activate", function(event) {
  event.waitUntil(
    caches.keys().then(function(keys) {
      return Promise.all(keys.map(function(key) {
        if (key.indexOf("faz-tudo-") === 0 && key !== CACHE_NAME) {
          return caches.delete(key);
        }
        return Promise.resolve(false);
      }));
    }).then(function() {
      return self.clients.claim();
    })
  );
});

self.addEventListener("fetch", function(event) {
  var request = event.request;
  if (!request || request.method !== "GET") return;

  var requestUrl;
  try {
    requestUrl = new URL(request.url);
  } catch (error) {
    return;
  }
  if (requestUrl.origin !== self.location.origin) return;

  if (request.mode === "navigate") {
    event.respondWith(
      fetch(request).then(function(response) {
        if (response && response.ok) {
          var copy = response.clone();
          caches.open(CACHE_NAME).then(function(cache) {
            cache.put("./", copy);
          }).catch(function() {});
        }
        return response;
      }).catch(function() {
        return caches.open(CACHE_NAME).then(function(cache) {
          return cache.match(request).then(function(saved) {
            if (saved) return saved;
            return cache.match("./").then(function(home) {
              return home || Response.error();
            });
          });
        });
      })
    );
    return;
  }

  if (requestUrl.origin === self.location.origin) {
    event.respondWith(
      caches.open(CACHE_NAME).then(function(cache) {
        return cache.match(request).then(function(saved) {
          if (saved) return saved;
          return fetch(request).then(function(response) {
            if (response && response.ok) {
              cache.put(request, response.clone()).catch(function() {});
            }
            return response;
          });
        });
      })
    );
  }
});
