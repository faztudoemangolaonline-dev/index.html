(function () {
  "use strict";
  var cache = {};
  var fallback = "data:image/svg+xml,%3Csvg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 16 9%22%3E%3Crect width=%2216%22 height=%229%22 fill=%22%23edf4fb%22/%3E%3C/svg%3E";

  function loadChunk(file, originalOnly) {
    var key = file + (originalOnly ? "::original" : "::preferred");
    if (cache[key]) return cache[key];
    cache[key] = new Promise(function (resolve, reject) {
      var match = file.match(/^image-assets-([0-9]+)[.]json$/);
      var preferred = !originalOnly && match ? "./image-assets-webp-" + match[1] + ".json" : null;
      function loadOriginal() {
        fetch("./" + file, { cache: "force-cache" }).then(function (response) {
          if (!response.ok) throw new Error("Falha ao carregar imagens");
          return response.json();
        }).then(resolve, reject);
      }
      if (preferred) {
        fetch(preferred, { cache: "force-cache" }).then(function (response) {
          if (!response.ok) throw new Error("Versão optimizada indisponível");
          return response.json();
        }).then(resolve, loadOriginal);
      } else {
        loadOriginal();
      }
    });
    return cache[key];
  }

  function reveal(img) {
    if (img.getAttribute("data-loaded") === "1") return;
    img.setAttribute("data-loaded", "1");
    var file = img.getAttribute("data-image-chunk");
    var key = img.getAttribute("data-image-key");
    loadChunk(file, false).then(function (data) {
      var uri = data && data[key] ? data[key] : fallback;
      if (uri && uri.toLowerCase().indexOf("data:image/webp") === 0) {
        img.onerror = function () {
          img.onerror = null;
          loadChunk(file, true).then(function (original) {
            img.src = original && original[key] ? original[key] : fallback;
          }, function () {
            img.src = fallback;
          });
        };
      }
      img.src = uri;
    }, function () {
      img.src = fallback;
      img.alt = (img.alt || "Imagem") + " — imagem temporariamente indisponível";
    });
  }

  function start() {
    var imgs = document.querySelectorAll("img[data-image-key]");
    var list = [];
    var i;
    for (i = 0; i < imgs.length; i++) list.push(imgs[i]);
    if (!list.length) return;
    if ("IntersectionObserver" in window) {
      var observer = new IntersectionObserver(function (entries) {
        var j, entry;
        for (j = 0; j < entries.length; j++) {
          entry = entries[j];
          if (entry.isIntersecting) {
            observer.unobserve(entry.target);
            reveal(entry.target);
          }
        }
      }, { rootMargin: "150px 0px" });
      for (i = 0; i < list.length; i++) observer.observe(list[i]);
    } else {
      for (i = 0; i < list.length; i++) reveal(list[i]);
    }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", start, false);
  } else {
    start();
  }
}());
