(() => {
  "use strict";

  const version = "NSV021::CacheFirstSafe";
  const offlineUrl = "/offline.html";
  const offlineImage = "/offline.png"; // <-- add this to your precache

  async function updateStaticCache() {
    const cache = await caches.open(version);
    // You may want to remove "/" if it changes often and shouldn't be cached
    return cache.addAll([offlineUrl, offlineImage, "/"]);
  }

  async function addToCache(request, response) {
    if (
      !response ||
      !response.ok ||
      (response.type !== "basic" && response.type !== "opaque")
    )
      return;

    // Never cache Dates.html
    if (request.url.includes("Dates.html")) {
      return;
    }

    const cache = await caches.open(version);
    await cache.put(request, response.clone());
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

  function serveOfflineFallback(request) {
    if (request.destination === "image") {
      return caches.match(offlineImage);
    }
    if (request.destination === "document") {
      return caches.match(offlineUrl);
    }
    // For CSS/JS/etc., just fail silently instead of serving HTML
    return undefined;
  }

  self.addEventListener("fetch", (event) => {
    const request = event.request;

    // Never cache Dates.html - always fetch from network
    if (request.url.includes("Dates.html")) {
      event.respondWith(
        fetch(request).catch(() => caches.match(offlineUrl))
      );
      return;
    }

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
            await addToCache(request, response);
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
            await addToCache(request, response);
            return response || serveOfflineFallback(request);
          } catch {
            return serveOfflineFallback(request);
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
          await addToCache(request, response);
          return response;
        } catch {
          const cached = await caches.match(request);
          return cached || serveOfflineFallback(request);
        }
      })()
    );
  });
})();
