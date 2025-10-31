// OMEGA Website Service Worker v1.1.0
const CACHE_NAME = 'omega-website-v1.1.0';
const STATIC_CACHE = 'omega-static-v1.1.0';
const DYNAMIC_CACHE = 'omega-dynamic-v1.1.0';

// Resources to cache immediately
const STATIC_ASSETS = [
    '/',
    '/index.html',
    '/styles.css',
    '/script.js',
    '/performance.js',
    '/lang.js',
    '/logo.svg',
    '/docs.html',
    '/playground.html',
    '/404.html',
    '/robots.txt',
    '/sitemap.xml',
    // External resources
    'https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500;600&display=swap'
];

// Resources to cache on demand
const DYNAMIC_ASSETS = [
    '/api/',
    '/docs/',
    '/examples/'
];

// Install event - cache static assets
self.addEventListener('install', (event) => {
    console.log('Service Worker: Installing...');
    
    event.waitUntil(
        Promise.all([
            // Cache static assets
            caches.open(STATIC_CACHE).then((cache) => {
                console.log('Service Worker: Caching static assets');
                return cache.addAll(STATIC_ASSETS);
            }),
            // Skip waiting to activate immediately
            self.skipWaiting()
        ])
    );
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
    console.log('Service Worker: Activating...');
    
    event.waitUntil(
        Promise.all([
            // Clean up old caches
            caches.keys().then((cacheNames) => {
                return Promise.all(
                    cacheNames.map((cacheName) => {
                        if (cacheName !== STATIC_CACHE && cacheName !== DYNAMIC_CACHE) {
                            console.log('Service Worker: Deleting old cache:', cacheName);
                            return caches.delete(cacheName);
                        }
                    })
                );
            }),
            // Take control of all clients
            self.clients.claim()
        ])
    );
});

// Fetch event - serve from cache with network fallback
self.addEventListener('fetch', (event) => {
    const { request } = event;
    const url = new URL(request.url);
    
    // Skip non-GET requests
    if (request.method !== 'GET') {
        return;
    }
    
    // Skip chrome-extension and other non-http requests
    if (!url.protocol.startsWith('http')) {
        return;
    }
    
    event.respondWith(
        handleFetchRequest(request)
    );
});

async function handleFetchRequest(request) {
    const url = new URL(request.url);
    
    // Strategy 1: Cache First (for static assets)
    if (isStaticAsset(request)) {
        return cacheFirst(request);
    }
    
    // Strategy 2: Network First (for dynamic content)
    if (isDynamicAsset(request)) {
        return networkFirst(request);
    }
    
    // Strategy 3: Stale While Revalidate (for other resources)
    return staleWhileRevalidate(request);
}

function isStaticAsset(request) {
    const url = new URL(request.url);
    const pathname = url.pathname;
    
    return STATIC_ASSETS.some(asset => pathname.endsWith(asset)) ||
           pathname.match(/\.(css|js|png|jpg|jpeg|gif|svg|ico|woff|woff2|ttf|eot)$/);
}

function isDynamicAsset(request) {
    const url = new URL(request.url);
    const pathname = url.pathname;
    
    return DYNAMIC_ASSETS.some(pattern => pathname.startsWith(pattern)) ||
           pathname.startsWith('/api/');
}

// Cache First Strategy
async function cacheFirst(request) {
    try {
        const cachedResponse = await caches.match(request);
        if (cachedResponse) {
            return cachedResponse;
        }
        
        const networkResponse = await fetch(request);
        
        // Cache successful responses
        if (networkResponse.status === 200) {
            const cache = await caches.open(STATIC_CACHE);
            cache.put(request, networkResponse.clone());
        }
        
        return networkResponse;
    } catch (error) {
        console.error('Cache First failed:', error);
        
        // Return offline page for navigation requests
        if (request.mode === 'navigate') {
            return caches.match('/404.html');
        }
        
        throw error;
    }
}

// Network First Strategy
async function networkFirst(request) {
    try {
        const networkResponse = await fetch(request);
        
        // Cache successful responses
        if (networkResponse.status === 200) {
            const cache = await caches.open(DYNAMIC_CACHE);
            cache.put(request, networkResponse.clone());
        }
        
        return networkResponse;
    } catch (error) {
        console.log('Network failed, trying cache:', error);
        
        const cachedResponse = await caches.match(request);
        if (cachedResponse) {
            return cachedResponse;
        }
        
        throw error;
    }
}

// Stale While Revalidate Strategy
async function staleWhileRevalidate(request) {
    const cache = await caches.open(DYNAMIC_CACHE);
    const cachedResponse = await cache.match(request);
    
    // Fetch from network in background
    const networkResponsePromise = fetch(request).then((networkResponse) => {
        if (networkResponse.status === 200) {
            cache.put(request, networkResponse.clone());
        }
        return networkResponse;
    }).catch(() => {
        // Network failed, but we might have cache
        return null;
    });
    
    // Return cached version immediately if available
    if (cachedResponse) {
        return cachedResponse;
    }
    
    // Otherwise wait for network
    return networkResponsePromise;
}

// Background Sync for offline actions
self.addEventListener('sync', (event) => {
    console.log('Service Worker: Background sync triggered');
    
    if (event.tag === 'background-sync') {
        event.waitUntil(doBackgroundSync());
    }
});

async function doBackgroundSync() {
    // Handle offline actions when back online
    try {
        // Process any queued actions
        const queuedActions = await getQueuedActions();
        
        for (const action of queuedActions) {
            await processAction(action);
        }
        
        await clearQueuedActions();
    } catch (error) {
        console.error('Background sync failed:', error);
    }
}

async function getQueuedActions() {
    // Get actions from IndexedDB or localStorage
    return [];
}

async function processAction(action) {
    // Process individual action
    console.log('Processing action:', action);
}

async function clearQueuedActions() {
    // Clear processed actions
    console.log('Clearing queued actions');
}

// Push notifications
self.addEventListener('push', (event) => {
    console.log('Service Worker: Push received');
    
    const options = {
        body: event.data ? event.data.text() : 'New update available!',
        icon: '/logo.svg',
        badge: '/logo.svg',
        vibrate: [100, 50, 100],
        data: {
            dateOfArrival: Date.now(),
            primaryKey: 1
        },
        actions: [
            {
                action: 'explore',
                title: 'Explore',
                icon: '/logo.svg'
            },
            {
                action: 'close',
                title: 'Close',
                icon: '/logo.svg'
            }
        ]
    };
    
    event.waitUntil(
        self.registration.showNotification('OMEGA Website', options)
    );
});

// Notification click handling
self.addEventListener('notificationclick', (event) => {
    console.log('Service Worker: Notification clicked');
    
    event.notification.close();
    
    if (event.action === 'explore') {
        event.waitUntil(
            clients.openWindow('/')
        );
    }
});

// Message handling from main thread
self.addEventListener('message', (event) => {
    console.log('Service Worker: Message received', event.data);
    
    if (event.data && event.data.type === 'SKIP_WAITING') {
        self.skipWaiting();
    }
    
    if (event.data && event.data.type === 'GET_VERSION') {
        event.ports[0].postMessage({ version: CACHE_NAME });
    }
    
    if (event.data && event.data.type === 'CLEAR_CACHE') {
        event.waitUntil(
            caches.keys().then((cacheNames) => {
                return Promise.all(
                    cacheNames.map((cacheName) => caches.delete(cacheName))
                );
            })
        );
    }
});

// Periodic background sync
self.addEventListener('periodicsync', (event) => {
    console.log('Service Worker: Periodic sync triggered');
    
    if (event.tag === 'content-sync') {
        event.waitUntil(syncContent());
    }
});

async function syncContent() {
    try {
        // Sync content in background
        console.log('Syncing content...');
        
        // Update cache with fresh content
        const cache = await caches.open(DYNAMIC_CACHE);
        const requests = [
            '/api/latest-news',
            '/api/documentation-updates'
        ];
        
        await Promise.all(
            requests.map(async (url) => {
                try {
                    const response = await fetch(url);
                    if (response.ok) {
                        await cache.put(url, response);
                    }
                } catch (error) {
                    console.error('Failed to sync:', url, error);
                }
            })
        );
    } catch (error) {
        console.error('Content sync failed:', error);
    }
}

// Error handling
self.addEventListener('error', (event) => {
    console.error('Service Worker error:', event.error);
});

self.addEventListener('unhandledrejection', (event) => {
    console.error('Service Worker unhandled rejection:', event.reason);
});

console.log('Service Worker: Loaded successfully');