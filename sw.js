const CACHE_NAME = "smokehouse-live-v1";
const STATIC = ["./", "./index.html", "./cloud_config.js", "./appicon.png", "./manifest.json"];

self.addEventListener("install", event => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => cache.addAll(STATIC).catch(()=>{}))
  );
});

self.addEventListener("activate", event => {
  event.waitUntil((async()=>{
    const keys = await caches.keys();
    await Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)));
    await self.clients.claim();
  })());
});

self.addEventListener("fetch", event => {
  const req = event.request;
  if(req.method !== "GET") return;

  const url = new URL(req.url);

  // Supabase API/Auth/Storage: always live network, never Cache Storage.
  if(url.hostname.endsWith("supabase.co")){
    event.respondWith(fetch(req, {cache:"no-store"}));
    return;
  }

  // App shell / config: network first so GitHub updates appear without clearing cache.
  if(req.mode === "navigate" ||
     url.pathname.endsWith("/index.html") ||
     url.pathname.endsWith("/cloud_config.js") ||
     url.pathname.endsWith("/manifest.json") ||
     url.pathname.endsWith("/sw.js")){
    event.respondWith((async()=>{
      try{
        const fresh = await fetch(req, {cache:"no-store"});
        if(fresh && fresh.ok){
          const cache = await caches.open(CACHE_NAME);
          cache.put(req, fresh.clone()).catch(()=>{});
        }
        return fresh;
      }catch(e){
        return (await caches.match(req)) || (await caches.match("./index.html"));
      }
    })());
    return;
  }

  // Other static files: cache fallback, but try network first.
  event.respondWith((async()=>{
    try{
      const fresh = await fetch(req);
      if(fresh && fresh.ok){
        const cache = await caches.open(CACHE_NAME);
        cache.put(req, fresh.clone()).catch(()=>{});
      }
      return fresh;
    }catch(e){
      return caches.match(req);
    }
  })());
});
