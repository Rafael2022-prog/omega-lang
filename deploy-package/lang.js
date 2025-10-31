// OMEGA Website - Multi-language Support System
// Automatic language detection and translation system

class LanguageManager {
    constructor() {
        this.currentLanguage = 'en'; // Default language
        this.supportedLanguages = ['en', 'id'];
        this.translations = {};
        this.init();
    }

    // Initialize language system
    init() {
        this.loadTranslations();
        this.detectLanguage();
        this.applyTranslations();
        this.setupLanguageSwitcher();
    }

    // Detect user's preferred language
    detectLanguage() {
        // Check localStorage first
        const savedLang = localStorage.getItem('omega-language');
        if (savedLang && this.supportedLanguages.includes(savedLang)) {
            this.currentLanguage = savedLang;
            return;
        }

        // Detect from browser
        const browserLang = navigator.language || navigator.userLanguage;
        const langCode = browserLang.split('-')[0].toLowerCase();
        
        // Check if detected language is supported
        if (this.supportedLanguages.includes(langCode)) {
            this.currentLanguage = langCode;
        } else {
            // Default to English if not supported
            this.currentLanguage = 'en';
        }

        // Save detected language
        localStorage.setItem('omega-language', this.currentLanguage);
    }

    // Load translation files
    loadTranslations() {
        this.translations = {
            en: {
                // Navigation
                'nav.home': 'Home',
                'nav.docs': 'Docs',
                'nav.playground': 'Playground',
                'nav.github': 'GitHub',
                'nav.features': 'Features',

                // Hero Section
                'hero.title': 'OMEGA',
                'hero.title.main': 'Write Once,',
                'hero.title.sub': 'Deploy Everywhere',
                'hero.subtitle': 'Universal Blockchain Programming Language',
                'hero.description': 'Write once, deploy everywhere. OMEGA enables you to write smart contracts once and compile them to multiple blockchain targets including EVM and non-EVM platforms.',
                'hero.cta.primary': 'Get Started',
                'hero.cta.secondary': 'View Documentation',
                'hero.cta.playground': 'Try Playground',
                'hero.cta.docs': 'Documentation',

                // Features Section
                'features.title': 'Why Choose OMEGA?',
                'features.description': 'OMEGA provides everything you need for cross-chain smart contract development',
                'features.universal.title': 'Universal Compatibility',
                'features.universal.desc': 'Deploy to Ethereum, Solana, Cosmos, and more with a single codebase',
                'features.security.title': 'Built-in Security',
                'features.security.desc': 'Advanced static analysis and formal verification prevent vulnerabilities',
                'features.performance.title': 'Optimized Performance',
                'features.performance.desc': 'Target-specific optimizations ensure maximum efficiency',
                'features.developer.title': 'Developer Experience',
                'features.developer.desc': 'Rich tooling, debugging support, and comprehensive documentation',
                'features.cross-chain.title': 'Cross-Chain Native',
                'features.cross-chain.desc': 'Built-in support for inter-blockchain communication and asset transfers',
                'features.testing.title': 'Testing Framework',
                'features.testing.desc': 'Comprehensive testing tools with cross-chain simulation capabilities',

                // Navigation Community
                'nav.community': 'Community',

                // Playground Section
                'playground.title': 'Try OMEGA Online',
                'playground.description': 'Experience OMEGA\'s power with our interactive playground. Write, compile, and test smart contracts directly in your browser.',
                'playground.cta': 'Open Playground',

                // Documentation Section
                'docs.title': 'Comprehensive Documentation',
                'docs.description': 'Everything you need to master OMEGA development',
                'docs.page.title': 'OMEGA Documentation - Universal Blockchain Programming Language',
                'docs.introduction.title': 'OMEGA Documentation',
                'docs.introduction.welcome': 'Welcome to the comprehensive documentation for OMEGA, the universal blockchain programming language that enables you to write smart contracts once and deploy them across multiple blockchain platforms.',
                'docs.getting-started': 'Getting Started',
                'docs.getting-started.desc': 'Installation guide and first tutorial to get started with OMEGA',
                'docs.language-spec': 'Language Specification',
                'docs.language-spec.desc': 'Complete OMEGA language specification and features',
                'docs.examples': 'Examples',
                'docs.examples.desc': 'Practical examples of DeFi, NFT, and cross-chain applications',
                'docs.best-practices': 'Best Practices',
                'docs.best-practices.desc': 'Tips and best practices for optimal development',
                'docs.read-more': 'Read More →',

                // Playground Section
                'playground.title': 'Try OMEGA Online',
                'playground.description': 'Write, compile, and test OMEGA smart contracts directly in your browser',
                'playground.examples': 'Example Contracts',
                'playground.examples.token': 'Simple Token',
                'playground.examples.token.desc': 'Basic ERC-20 compatible token contract',
                'playground.examples.nft': 'NFT Collection',
                'playground.examples.nft.desc': 'Non-fungible token with minting functionality',
                'playground.examples.defi': 'DeFi Vault',
                'playground.examples.defi.desc': 'Yield farming vault with rewards',
                'playground.examples.dao': 'DAO Governance',
                'playground.examples.dao.desc': 'Decentralized governance with voting',
                'playground.examples.bridge': 'Cross-Chain Bridge',
                'playground.examples.bridge.desc': 'Bridge tokens between blockchains',
                'playground.target.evm': 'EVM',
                'playground.target.solana': 'Solana',
                'playground.target.cosmos': 'Cosmos',
                'playground.compile': 'Compile',
                'playground.tabs.contract': 'Contract.omega',
                'playground.tabs.test': 'Test.omega',
                'playground.output.compiled': 'Compiled',
                'playground.output.console': 'Console',
                'playground.output.gas': 'Gas Analysis',
                'playground.result': 'Compilation Result',
                'playground.status': 'Ready',
                'playground.instruction': 'Click "Compile" to see the generated code',

                // Stats
                'stats.type-safe': 'Type Safe',
                'stats.gas-reduction': 'Gas Reduction',

                // Footer Additional
                'footer.tagline': 'Universal Blockchain Programming Language',
                'footer.documentation': 'Documentation',
                'footer.discord': 'Discord',
                'footer.twitter': 'Twitter',
                'footer.forum': 'Forum',
                'footer.blog': 'Blog',
                'footer.roadmap': 'Roadmap',
                'footer.security': 'Security',

                // Community Section
                'community.title': 'Join the Community',
                'community.description': 'Connect with developers building the future of blockchain',
                'community.github': 'GitHub Repository',
                'community.github.desc': 'Source code and contributions',
                'community.forum': 'Community Forum',
                'community.forum.desc': 'Discussions, Q&A, and sharing experiences with other OMEGA developers',
                'community.discussions': 'Discussions',
                'community.discussions.desc': 'Community discussions and Q&A',
                'community.issues': 'Issues & Bugs',
                'community.issues.desc': 'Report bugs and request features',
                'community.wiki': 'Documentation Wiki',
                'community.wiki.desc': 'Complete guides, tutorials, and technical documentation for OMEGA',

                // Footer
                'footer.description': 'Universal blockchain programming language enabling cross-chain smart contract development.',
                'footer.links': 'Quick Links',
                'footer.community': 'Community',
                'footer.resources': 'Resources',
                'footer.copyright': 'Created by Emylton Leunufna - 2025',

                // 404 Page
                'error.title': 'Page Not Found',
                'error.description': 'The page you\'re looking for doesn\'t exist or has been moved.',
                'error.home': 'Go Home',
                'error.docs': 'Documentation',
                'error.playground': 'Try Playground',

                // Stats
                'stats.blockchains': 'Supported Blockchains',
                'stats.developers': 'Active Developers',
                'stats.contracts': 'Deployed Contracts',
                'stats.savings': 'Gas Savings',

                // Code Comments
                'code.comment.constructor': '// Constructor with initial parameters',
                'code.comment.transfer': '// Transfer function with safety checks',
                'code.comment.balance': '// Get balance of an account',
                'code.comment.event': '// Transfer event emission'
            },
            id: {
                // Navigation
                'nav.home': 'Beranda',
                'nav.docs': 'Dokumentasi',
                'nav.playground': 'Playground',
                'nav.github': 'GitHub',
                'nav.features': 'Fitur',
                'nav.community': 'Komunitas',

                // Hero Section
                'hero.title': 'OMEGA',
                'hero.title.main': 'Tulis Sekali,',
                'hero.title.sub': 'Deploy Di Mana Saja',
                'hero.subtitle': 'Bahasa Pemrograman Blockchain Universal',
                'hero.description': 'Tulis sekali, deploy di mana saja. OMEGA memungkinkan Anda menulis smart contract sekali dan mengompilasi ke berbagai target blockchain termasuk platform EVM dan non-EVM.',
                'hero.cta.primary': 'Mulai Sekarang',
                'hero.cta.secondary': 'Lihat Dokumentasi',
                'hero.cta.playground': 'Coba Playground',
                'hero.cta.docs': 'Dokumentasi',

                // Features Section
                'features.title': 'Mengapa Memilih OMEGA?',
                'features.description': 'OMEGA menyediakan semua yang Anda butuhkan untuk pengembangan smart contract lintas rantai',
                'features.universal.title': 'Kompatibilitas Universal',
                'features.universal.desc': 'Deploy ke Ethereum, Solana, Cosmos, dan lainnya dengan satu codebase',
                'features.security.title': 'Keamanan Bawaan',
                'features.security.desc': 'Analisis statis lanjutan dan verifikasi formal mencegah kerentanan',
                'features.performance.title': 'Performa Optimal',
                'features.performance.desc': 'Optimasi khusus target memastikan efisiensi maksimal',
                'features.developer.title': 'Pengalaman Developer',
                'features.developer.desc': 'Tooling lengkap, dukungan debugging, dan dokumentasi komprehensif',
                'features.cross-chain.title': 'Cross-Chain Native',
                'features.cross-chain.desc': 'Dukungan bawaan untuk komunikasi antar blockchain dan transfer aset',
                'features.testing.title': 'Framework Testing',
                'features.testing.desc': 'Tools testing komprehensif dengan kemampuan simulasi cross-chain',

                // Playground Section
                'playground.title': 'Coba OMEGA Online',
                'playground.description': 'Tulis, kompilasi, dan uji smart contract OMEGA langsung di browser Anda',
                'playground.cta': 'Buka Playground',
                'playground.examples': 'Contoh Kontrak',
                'playground.examples.token': 'Token Sederhana',
                'playground.examples.token.desc': 'Kontrak token dasar yang kompatibel dengan ERC-20',
                'playground.examples.nft': 'Koleksi NFT',
                'playground.examples.nft.desc': 'Token non-fungible dengan fungsi minting',
                'playground.examples.defi': 'Vault DeFi',
                'playground.examples.defi.desc': 'Vault yield farming dengan reward',
                'playground.examples.dao': 'Governance DAO',
                'playground.examples.dao.desc': 'Governance terdesentralisasi dengan voting',
                'playground.examples.bridge': 'Bridge Cross-Chain',
                'playground.examples.bridge.desc': 'Bridge token antar blockchain',
                'playground.target.evm': 'EVM',
                'playground.target.solana': 'Solana',
                'playground.target.cosmos': 'Cosmos',
                'playground.compile': 'Kompilasi',
                'playground.tabs.contract': 'Contract.omega',
                'playground.tabs.test': 'Test.omega',
                'playground.output.compiled': 'Terkompilasi',
                'playground.output.console': 'Konsol',
                'playground.output.gas': 'Analisis Gas',
                'playground.result': 'Hasil Kompilasi',
                'playground.status': 'Siap',
                'playground.instruction': 'Klik "Kompilasi" untuk melihat kode yang dihasilkan',

                // Documentation Section
                'docs.title': 'Dokumentasi Lengkap',
                'docs.description': 'Semua yang Anda butuhkan untuk menguasai pengembangan OMEGA',
                'docs.page.title': 'Dokumentasi OMEGA - Bahasa Pemrograman Blockchain Universal',
                'docs.introduction.title': 'Dokumentasi OMEGA',
                'docs.introduction.welcome': 'Selamat datang di dokumentasi lengkap untuk OMEGA, bahasa pemrograman blockchain universal yang memungkinkan Anda menulis smart contract sekali dan men-deploy ke berbagai platform blockchain.',
                'docs.getting-started': 'Memulai',
                'docs.getting-started.desc': 'Panduan instalasi dan tutorial pertama untuk memulai dengan OMEGA',
                'docs.language-spec': 'Spesifikasi Bahasa',
                'docs.language-spec.desc': 'Spesifikasi lengkap bahasa OMEGA dan fitur-fiturnya',
                'docs.examples': 'Contoh',
                'docs.examples.desc': 'Contoh praktis aplikasi DeFi, NFT, dan cross-chain',
                'docs.best-practices': 'Best Practices',
                'docs.best-practices.desc': 'Tips dan best practices untuk pengembangan optimal',
                'docs.read-more': 'Baca Selengkapnya →',

                // Stats
                'stats.type-safe': 'Type Safe',
                'stats.gas-reduction': 'Pengurangan Gas',

                // Footer Additional
                'footer.tagline': 'Bahasa Pemrograman Blockchain Universal',
                'footer.documentation': 'Dokumentasi',
                'footer.discord': 'Discord',
                'footer.twitter': 'Twitter',
                'footer.forum': 'Forum',
                'footer.blog': 'Blog',
                'footer.roadmap': 'Roadmap',
                'footer.security': 'Keamanan',

                // Community Section
                'community.title': 'Bergabung dengan Komunitas',
                'community.description': 'Terhubung dengan developer yang membangun masa depan blockchain',
                'community.github': 'Repositori GitHub',
                'community.github.desc': 'Source code dan kontribusi',
                'community.forum': 'Forum Komunitas',
                'community.forum.desc': 'Diskusi, tanya jawab, dan berbagi pengalaman dengan developer OMEGA lainnya',
                'community.discussions': 'Diskusi',
                'community.discussions.desc': 'Diskusi komunitas dan tanya jawab',
                'community.issues': 'Issues & Bug',
                'community.issues.desc': 'Laporkan bug dan request fitur',
                'community.wiki': 'Wiki Dokumentasi',
                'community.wiki.desc': 'Panduan lengkap, tutorial, dan dokumentasi teknis OMEGA',

                // Footer
                'footer.description': 'Bahasa pemrograman blockchain universal yang memungkinkan pengembangan smart contract lintas rantai.',
                'footer.links': 'Tautan Cepat',
                'footer.community': 'Komunitas',
                'footer.resources': 'Sumber Daya',
                'footer.copyright': 'Dibuat oleh Emylton Leunufna - 2025',

                // 404 Page
                'error.title': 'Halaman Tidak Ditemukan',
                'error.description': 'Halaman yang Anda cari tidak ada atau telah dipindahkan.',
                'error.home': 'Kembali ke Beranda',
                'error.docs': 'Dokumentasi',
                'error.playground': 'Coba Playground',

                // Stats
                'stats.blockchains': 'Blockchain Didukung',
                'stats.developers': 'Developer Aktif',
                'stats.contracts': 'Kontrak Terdeploy',
                'stats.savings': 'Penghematan Gas',

                // Code Comments
                'code.comment.constructor': '// Constructor dengan parameter awal',
                'code.comment.transfer': '// Fungsi transfer dengan pemeriksaan keamanan',
                'code.comment.balance': '// Dapatkan saldo dari sebuah akun',
                'code.comment.event': '// Emisi event Transfer'
            }
        };
    }

    // Apply translations to the page
    applyTranslations() {
        const elements = document.querySelectorAll('[data-lang]');
        elements.forEach(element => {
            const key = element.getAttribute('data-lang');
            const translation = this.getTranslation(key);
            if (translation) {
                if (element.tagName === 'INPUT' && element.type === 'submit') {
                    element.value = translation;
                } else if (element.hasAttribute('placeholder')) {
                    element.placeholder = translation;
                } else {
                    element.textContent = translation;
                }
            }
        });

        // Update HTML lang attribute
        document.documentElement.lang = this.currentLanguage;
    }

    // Get translation for a key
    getTranslation(key) {
        return this.translations[this.currentLanguage]?.[key] || 
               this.translations['en']?.[key] || 
               key;
    }

    // Alias for getTranslation (for compatibility)
    translate(key) {
        return this.getTranslation(key);
    }

    // Switch language
    switchLanguage(langCode) {
        if (this.supportedLanguages.includes(langCode)) {
            this.currentLanguage = langCode;
            localStorage.setItem('omega-language', langCode);
            this.applyTranslations();
            this.updateLanguageSwitcher();
        }
    }

    // Setup language switcher in navigation
    setupLanguageSwitcher() {
        const navbar = document.querySelector('.nav-menu');
        if (navbar) {
            const langSwitcher = document.createElement('div');
            langSwitcher.className = 'language-switcher';
            langSwitcher.innerHTML = `
                <button class="lang-btn ${this.currentLanguage === 'en' ? 'active' : ''}" data-lang-code="en">
                    <span class="flag">🇺🇸</span> EN
                </button>
                <button class="lang-btn ${this.currentLanguage === 'id' ? 'active' : ''}" data-lang-code="id">
                    <span class="flag">🇮🇩</span> ID
                </button>
            `;
            
            navbar.appendChild(langSwitcher);
            
            // Add event listeners
            langSwitcher.querySelectorAll('.lang-btn').forEach(btn => {
                btn.addEventListener('click', (e) => {
                    const langCode = e.currentTarget.getAttribute('data-lang-code');
                    this.switchLanguage(langCode);
                });
            });
        }
    }

    // Update language switcher active state
    updateLanguageSwitcher() {
        const langButtons = document.querySelectorAll('.lang-btn');
        langButtons.forEach(btn => {
            const langCode = btn.getAttribute('data-lang-code');
            btn.classList.toggle('active', langCode === this.currentLanguage);
        });
    }

    // Get current language
    getCurrentLanguage() {
        return this.currentLanguage;
    }

    // Check if language is RTL (for future Arabic support)
    isRTL() {
        const rtlLanguages = ['ar', 'he', 'fa'];
        return rtlLanguages.includes(this.currentLanguage);
    }
}

// Initialize language manager when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.languageManager = new LanguageManager();
});

// Also initialize immediately if DOM is already loaded
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        if (!window.languageManager) {
            window.languageManager = new LanguageManager();
        }
    });
} else {
    // DOM is already loaded
    window.languageManager = new LanguageManager();
}

// Export for use in other scripts
if (typeof module !== 'undefined' && module.exports) {
    module.exports = LanguageManager;
}