/* USCW Seminar Check-In — service worker
   The app is now online-first (data lives in Supabase), so the shell is served
   network-first: signed-in kiosks always load the latest app when online, and
   fall back to the cached shell only if the network is unavailable.
   Bump CACHE to retire old caches. */
const CACHE = 'uscw-checkin-v12';

// Paths are relative to this script's location, so they resolve correctly under
// the GitHub Pages subpath (…/Seminar-Check-In-App/).
const PRECACHE = [
  './index2.html',
  './manifest.json',
  './icon-192.png',
  './icon-512.png',
  './apple-touch-icon.png'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE)
      .then((cache) => cache.addAll(PRECACHE))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  // Non-GET (e.g. Supabase / LeadConnector POSTs) is left to the network entirely.
  if (req.method !== 'GET') return;
  // Only manage our own origin's shell assets. Cross-origin requests (Supabase API,
  // the supabase-js CDN, the LeadConnector booking iframe, etc.) go straight to the
  // network untouched so the service worker can never interfere with them.
  if (new URL(req.url).origin !== self.location.origin) return;
  // Network-first: always prefer the live shell so app updates ship immediately;
  // refresh the cached copy on success and fall back to cache only when offline.
  event.respondWith(
    fetch(req).then((res) => {
      const copy = res.clone();
      caches.open(CACHE).then((c) => c.put(req, copy)).catch(() => {});
      return res;
    }).catch(() => caches.match(req, { ignoreSearch: true }))
  );
});
