import { precacheAndRoute } from 'workbox-precaching';
import { registerRoute } from 'workbox-routing';
import { CacheFirst, StaleWhileRevalidate } from 'workbox-strategies';

declare let self: ServiceWorkerGlobalScope;

// Precache and route static assets
precacheAndRoute(self.__WB_MANIFEST || []);

// Cache JS/CSS with stale-while-revalidate
registerRoute(
  ({ request }) => request.destination === 'style' || request.destination === 'script',
  new StaleWhileRevalidate()
);

// Cache images, fonts, and other assets with cache-first
registerRoute(
  ({ request }) => ['image', 'font', 'audio', 'video', 'worker'].includes(request.destination),
  new CacheFirst()
);

// Cache API responses for game data
registerRoute(
  ({ url }) => url.pathname.startsWith('/api/'),
  new StaleWhileRevalidate()
);
