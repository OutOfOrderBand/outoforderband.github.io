(() => {
  "use strict";

  const version = "NS02062025V17::CacheFirstSafe";
  const offlineUrl = "/offline.html";

  async function updateStaticCache() {
    const cache = await caches.open(version);
    return cache.addAll([offlineUrl, "/"]);
  }

  async function addToCache(request, response) {
    if (
      !response ||
      !response.ok ||
      (response.type !== "basic" && response.type !== "opaque")
    )
      return;
    const cache = await caches.open(version);
    cache.put(request, response.clone());
  }

  self.addEventListener("install", (event) => {
    event.waitUntil(updateStaticCache());
    self.skipWaiting();
  });

  self.addEventListener("activate", (event) => {
    event.waitUntil(
      caches.keys().then((keys) =>
        Promise.all(
          keys
            .filter((key) => key.indexOf(version) !== 0)
            .map((key) => caches.delete(key))
        )
      )
    );
    self.clients.claim();
  });

  function serveOfflineImage(request) {
    // Optionally, serve a fallback image for image requests
    if (request.destination === "image") {
      // You can add a fallback image to your cache and return it here
      // return caches.match('/offline-image.png');
    }
    return caches.match(offlineUrl);
  }

  self.addEventListener("fetch", (event) => {
    const request = event.request;

    // Always fetch non-GET requests from the network
    if (request.method !== "GET" || request.url.match(/\/browserLink/gi)) {
      event.respondWith(
        fetch(request).catch(() => caches.match(offlineUrl))
      );
      return;
    }

    // For HTML requests, try the network first, fall back to the cache, finally the offline page
    if (request.headers.get("Accept")?.includes("text/html")) {
      event.respondWith(
        (async () => {
          try {
            const response = await fetch(request);
            addToCache(request, response);
            return response;
          } catch {
            const cached = await caches.match(request);
            return cached || caches.match(offlineUrl);
          }
        })()
      );
      return;
    }

    // Cache first for fingerprinted resources
    if (request.url.match(/(\?|&)v=/gi)) {
      event.respondWith(
        (async () => {
          const cached = await caches.match(request);
          if (cached) return cached;
          try {
            const response = await fetch(request);
            addToCache(request, response);
            return response || serveOfflineImage(request);
          } catch {
            return serveOfflineImage(request);
          }
        })()
      );
      return;
    }

    // Network first for non-fingerprinted resources
    event.respondWith(
      (async () => {
        try {
          const response = await fetch(request);
          addToCache(request, response);
          return response;
        } catch {
          const cached = await caches.match(request);
          return cached || serveOfflineImage(request);
        }
      })()
    );
  });
})();
