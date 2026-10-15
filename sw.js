// 43.80 SVA-E · service worker
// La página principal se pide primero a la red (así las actualizaciones llegan solas al abrir con cobertura)
// y, si no hay red, se sirve la copia guardada. Si cambias iconos o manifest, sube el número de VERSION.
const VERSION = 'sva4380-v9';
const BASE = ['./', 'index.html', 'manifest.json', 'icons/icon-192.png', 'icons/icon-512.png', 'icons/icon-180.png', 'vendor/supabase.js', 'vendor/pdf.min.js', 'vendor/pdf.worker.min.js'];
const CDN = ['cdn.jsdelivr.net', 'cdnjs.cloudflare.com', 'fonts.googleapis.com', 'fonts.gstatic.com'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(VERSION).then(c => c.addAll(BASE)).then(() => self.skipWaiting()));
});
self.addEventListener('activate', e => {
  e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k.startsWith('sva4380-v') && k !== VERSION).map(k => caches.delete(k)))).then(() => self.clients.claim()));
});
self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  // Los datos del servidor (Supabase) nunca se guardan aquí: la app guarda su propia copia.
  // Los PDF de procedimientos los guarda la app en su propia caché (sva4380-pdf), que no se borra al actualizar.
  if (url.hostname.endsWith('supabase.co')) return;
  if (req.mode === 'navigate' || (url.origin === location.origin && (url.pathname.endsWith('index.html') || url.pathname.includes('/fichas/')))) {
    e.respondWith(fetch(req).then(r => { if (!r.ok) return caches.match(req.mode === 'navigate' ? 'index.html' : req, { ignoreSearch: true }).then(c => c || r); const copy = r.clone(); const key = req.mode === 'navigate' ? 'index.html' : req; caches.open(VERSION).then(c => c.put(key, copy)); return r; })
      .catch(() => caches.match(req.mode === 'navigate' ? 'index.html' : req, { ignoreSearch: true })));
    return;
  }
  if (url.origin === location.origin || CDN.includes(url.hostname)) {
    e.respondWith(caches.match(req).then(hit => hit || fetch(req).then(r => {
      if (r.ok || r.type === 'opaque') { const copy = r.clone(); caches.open(VERSION).then(c => c.put(req, copy)); }
      return r;
    })));
  }
});
