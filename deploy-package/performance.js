// OMEGA Website - Performance Optimizations
class PerformanceOptimizer {
    constructor() {
        this.init();
    }

    init() {
        this.setupLazyLoading();
        this.setupImageOptimization();
        this.setupCriticalResourceHints();
        this.setupServiceWorker();
        this.setupAnalytics();
        this.monitorPerformance();
    }

    // Enhanced Lazy Loading
    setupLazyLoading() {
        // Intersection Observer for images
        if ('IntersectionObserver' in window) {
            const imageObserver = new IntersectionObserver((entries) => {
                entries.forEach(entry => {
                    if (entry.isIntersecting) {
                        const img = entry.target;
                        this.loadImage(img);
                        imageObserver.unobserve(img);
                    }
                });
            }, {
                rootMargin: '50px 0px',
                threshold: 0.1
            });

            // Observe all lazy images
            document.querySelectorAll('img[data-src]').forEach(img => {
                imageObserver.observe(img);
            });
        }

        // Lazy load sections
        const sectionObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('loaded');
                    this.loadSectionContent(entry.target);
                }
            });
        }, { threshold: 0.1 });

        document.querySelectorAll('.lazy-section').forEach(section => {
            sectionObserver.observe(section);
        });
    }

    loadImage(img) {
        return new Promise((resolve, reject) => {
            const tempImg = new Image();
            tempImg.onload = () => {
                img.src = tempImg.src;
                img.classList.remove('lazy');
                img.classList.add('loaded');
                resolve();
            };
            tempImg.onerror = reject;
            tempImg.src = img.dataset.src;
        });
    }

    loadSectionContent(section) {
        // Load dynamic content for sections
        const contentType = section.dataset.content;
        if (contentType && !section.dataset.loaded) {
            section.dataset.loaded = 'true';
            // Load content based on type
            switch (contentType) {
                case 'code-examples':
                    this.loadCodeExamples(section);
                    break;
                case 'documentation':
                    this.loadDocumentation(section);
                    break;
            }
        }
    }

    // Image Optimization
    setupImageOptimization() {
        // WebP support detection
        const supportsWebP = this.checkWebPSupport();
        
        if (supportsWebP) {
            document.querySelectorAll('img[data-webp]').forEach(img => {
                img.dataset.src = img.dataset.webp;
            });
        }

        // Responsive images
        this.setupResponsiveImages();
    }

    checkWebPSupport() {
        return new Promise(resolve => {
            const webP = new Image();
            webP.onload = webP.onerror = () => {
                resolve(webP.height === 2);
            };
            webP.src = 'data:image/webp;base64,UklGRjoAAABXRUJQVlA4IC4AAACyAgCdASoCAAIALmk0mk0iIiIiIgBoSygABc6WWgAA/veff/0PP8bA//LwYAAA';
        });
    }

    setupResponsiveImages() {
        const images = document.querySelectorAll('img[data-sizes]');
        images.forEach(img => {
            const sizes = JSON.parse(img.dataset.sizes);
            const currentWidth = window.innerWidth;
            
            let selectedSrc = sizes.default;
            for (const [breakpoint, src] of Object.entries(sizes)) {
                if (currentWidth <= parseInt(breakpoint)) {
                    selectedSrc = src;
                    break;
                }
            }
            
            if (img.dataset.src !== selectedSrc) {
                img.dataset.src = selectedSrc;
            }
        });
    }

    // Critical Resource Hints
    setupCriticalResourceHints() {
        // Preload critical resources
        const criticalResources = [
            { href: '/styles.css', as: 'style' },
            { href: '/script.js', as: 'script' },
            { href: '/logo.svg', as: 'image' }
        ];

        criticalResources.forEach(resource => {
            const link = document.createElement('link');
            link.rel = 'preload';
            link.href = resource.href;
            link.as = resource.as;
            if (resource.type) link.type = resource.type;
            document.head.appendChild(link);
        });

        // DNS prefetch for external resources
        const externalDomains = [
            'fonts.googleapis.com',
            'fonts.gstatic.com',
            'cdn.jsdelivr.net'
        ];

        externalDomains.forEach(domain => {
            const link = document.createElement('link');
            link.rel = 'dns-prefetch';
            link.href = `//${domain}`;
            document.head.appendChild(link);
        });
    }

    // Service Worker Registration
    setupServiceWorker() {
        if ('serviceWorker' in navigator) {
            window.addEventListener('load', () => {
                navigator.serviceWorker.register('/sw.js')
                    .then(registration => {
                        console.log('SW registered: ', registration);
                        this.handleServiceWorkerUpdate(registration);
                    })
                    .catch(registrationError => {
                        console.log('SW registration failed: ', registrationError);
                    });
            });
        }
    }

    handleServiceWorkerUpdate(registration) {
        registration.addEventListener('updatefound', () => {
            const newWorker = registration.installing;
            newWorker.addEventListener('statechange', () => {
                if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
                    // Show update notification
                    this.showUpdateNotification();
                }
            });
        });
    }

    showUpdateNotification() {
        const notification = document.createElement('div');
        notification.className = 'update-notification';
        notification.innerHTML = `
            <div class="update-content">
                <span>🚀 New version available!</span>
                <button onclick="window.location.reload()" class="btn btn-sm">Update</button>
                <button onclick="this.parentElement.parentElement.remove()" class="btn btn-sm btn-secondary">Later</button>
            </div>
        `;
        document.body.appendChild(notification);
    }

    // Analytics and Monitoring
    setupAnalytics() {
        // Core Web Vitals monitoring
        this.measureCoreWebVitals();
        
        // User interaction tracking
        this.trackUserInteractions();
        
        // Error tracking
        this.setupErrorTracking();
    }

    measureCoreWebVitals() {
        // Largest Contentful Paint
        new PerformanceObserver((entryList) => {
            const entries = entryList.getEntries();
            const lastEntry = entries[entries.length - 1];
            console.log('LCP:', lastEntry.startTime);
            this.sendMetric('LCP', lastEntry.startTime);
        }).observe({ entryTypes: ['largest-contentful-paint'] });

        // First Input Delay
        new PerformanceObserver((entryList) => {
            const firstInput = entryList.getEntries()[0];
            console.log('FID:', firstInput.processingStart - firstInput.startTime);
            this.sendMetric('FID', firstInput.processingStart - firstInput.startTime);
        }).observe({ entryTypes: ['first-input'] });

        // Cumulative Layout Shift
        let clsValue = 0;
        new PerformanceObserver((entryList) => {
            for (const entry of entryList.getEntries()) {
                if (!entry.hadRecentInput) {
                    clsValue += entry.value;
                }
            }
            console.log('CLS:', clsValue);
            this.sendMetric('CLS', clsValue);
        }).observe({ entryTypes: ['layout-shift'] });
    }

    trackUserInteractions() {
        // Track button clicks
        document.addEventListener('click', (e) => {
            if (e.target.matches('.btn')) {
                this.sendEvent('button_click', {
                    button_text: e.target.textContent.trim(),
                    button_class: e.target.className
                });
            }
        });

        // Track navigation
        document.addEventListener('click', (e) => {
            if (e.target.matches('.nav-link')) {
                this.sendEvent('navigation', {
                    link_text: e.target.textContent.trim(),
                    link_href: e.target.href
                });
            }
        });

        // Track scroll depth
        let maxScroll = 0;
        window.addEventListener('scroll', this.throttle(() => {
            const scrollPercent = Math.round((window.scrollY / (document.body.scrollHeight - window.innerHeight)) * 100);
            if (scrollPercent > maxScroll) {
                maxScroll = scrollPercent;
                if (maxScroll % 25 === 0) {
                    this.sendEvent('scroll_depth', { percent: maxScroll });
                }
            }
        }, 1000));
    }

    setupErrorTracking() {
        window.addEventListener('error', (e) => {
            this.sendError('javascript_error', {
                message: e.message,
                filename: e.filename,
                lineno: e.lineno,
                colno: e.colno
            });
        });

        window.addEventListener('unhandledrejection', (e) => {
            this.sendError('promise_rejection', {
                reason: e.reason
            });
        });
    }

    // Performance Monitoring
    monitorPerformance() {
        // Monitor memory usage
        if ('memory' in performance) {
            setInterval(() => {
                const memory = performance.memory;
                if (memory.usedJSHeapSize > memory.jsHeapSizeLimit * 0.9) {
                    console.warn('High memory usage detected');
                    this.sendMetric('memory_warning', memory.usedJSHeapSize);
                }
            }, 30000);
        }

        // Monitor long tasks
        if ('PerformanceObserver' in window) {
            new PerformanceObserver((entryList) => {
                entryList.getEntries().forEach(entry => {
                    if (entry.duration > 50) {
                        console.warn('Long task detected:', entry.duration);
                        this.sendMetric('long_task', entry.duration);
                    }
                });
            }).observe({ entryTypes: ['longtask'] });
        }

        // Page load metrics
        window.addEventListener('load', () => {
            setTimeout(() => {
                const navigation = performance.getEntriesByType('navigation')[0];
                const metrics = {
                    dns_lookup: navigation.domainLookupEnd - navigation.domainLookupStart,
                    tcp_connect: navigation.connectEnd - navigation.connectStart,
                    request_response: navigation.responseEnd - navigation.requestStart,
                    dom_parse: navigation.domContentLoadedEventEnd - navigation.responseEnd,
                    load_complete: navigation.loadEventEnd - navigation.navigationStart
                };
                
                Object.entries(metrics).forEach(([key, value]) => {
                    this.sendMetric(key, value);
                });
            }, 0);
        });
    }

    // Utility Methods
    sendMetric(name, value) {
        // Send to analytics service
        if (typeof gtag !== 'undefined') {
            gtag('event', name, {
                custom_parameter: value
            });
        }
        
        // Log for development
        console.log(`Metric: ${name} = ${value}`);
    }

    sendEvent(name, parameters) {
        if (typeof gtag !== 'undefined') {
            gtag('event', name, parameters);
        }
        
        console.log(`Event: ${name}`, parameters);
    }

    sendError(name, error) {
        if (typeof gtag !== 'undefined') {
            gtag('event', 'exception', {
                description: `${name}: ${error.message || error.reason}`,
                fatal: false
            });
        }
        
        console.error(`Error: ${name}`, error);
    }

    throttle(func, limit) {
        let inThrottle;
        return function() {
            const args = arguments;
            const context = this;
            if (!inThrottle) {
                func.apply(context, args);
                inThrottle = true;
                setTimeout(() => inThrottle = false, limit);
            }
        };
    }

    debounce(func, wait) {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    }
}

// Initialize performance optimizer
document.addEventListener('DOMContentLoaded', () => {
    new PerformanceOptimizer();
});

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = PerformanceOptimizer;
}