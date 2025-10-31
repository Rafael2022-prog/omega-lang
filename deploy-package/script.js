// OMEGA Website - Enhanced Interactive Features
class OmegaWebsite {
    constructor() {
        this.init();
    }

    init() {
        this.setupNavigation();
        this.setupScrollEffects();
        this.setupAnimations();
        this.setupCodePlayground();
        this.setupLanguageSwitcher();
        this.setupMobileMenu();
        this.setupParallax();
        this.setupTypingEffect();
    }

    // Enhanced Navigation with Smooth Scrolling
    setupNavigation() {
        const navbar = document.querySelector('.navbar');
        const navLinks = document.querySelectorAll('.nav-link');
        
        // Navbar scroll effect with glassmorphism
        window.addEventListener('scroll', () => {
            const scrolled = window.scrollY > 50;
            navbar.classList.toggle('scrolled', scrolled);
        });

        // Smooth scrolling for navigation links
        navLinks.forEach(link => {
            link.addEventListener('click', (e) => {
                const href = link.getAttribute('href');
                if (href && href.startsWith('#') && href.length > 1) {
                    e.preventDefault();
                    try {
                        const target = document.querySelector(href);
                        if (target) {
                            const offsetTop = target.offsetTop - 80;
                            window.scrollTo({
                                top: offsetTop,
                                behavior: 'smooth'
                            });
                            
                            // Update active link
                            navLinks.forEach(l => l.classList.remove('active'));
                            link.classList.add('active');
                        }
                    } catch (error) {
                        console.warn('Invalid selector:', href);
                    }
                }
            });
        });

        // Active section highlighting
        this.updateActiveNavLink();
        window.addEventListener('scroll', () => this.updateActiveNavLink());
    }

    updateActiveNavLink() {
        const sections = document.querySelectorAll('section[id]');
        const navLinks = document.querySelectorAll('.nav-link[href^="#"]');
        
        let current = '';
        sections.forEach(section => {
            const sectionTop = section.offsetTop - 100;
            const sectionHeight = section.clientHeight;
            if (window.scrollY >= sectionTop && window.scrollY < sectionTop + sectionHeight) {
                current = section.getAttribute('id');
            }
        });

        navLinks.forEach(link => {
            link.classList.remove('active');
            if (link.getAttribute('href') === `#${current}`) {
                link.classList.add('active');
            }
        });
    }

    // Enhanced Scroll Effects with Intersection Observer
    setupScrollEffects() {
        const observerOptions = {
            threshold: 0.1,
            rootMargin: '0px 0px -50px 0px'
        };

        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('animate-in');
                    
                    // Trigger counter animations for stats
                    if (entry.target.classList.contains('stat-number')) {
                        this.animateCounter(entry.target);
                    }
                }
            });
        }, observerOptions);

        // Observe elements for animation
        const animateElements = document.querySelectorAll(
            '.feature-card, .stat-number, .code-preview, .hero-badge, .section-title'
        );
        animateElements.forEach(el => observer.observe(el));
    }

    // Counter Animation for Statistics
    animateCounter(element) {
        const target = parseInt(element.getAttribute('data-target') || element.textContent);
        const duration = 2000;
        const step = target / (duration / 16);
        let current = 0;

        const timer = setInterval(() => {
            current += step;
            if (current >= target) {
                current = target;
                clearInterval(timer);
            }
            element.textContent = Math.floor(current).toLocaleString();
        }, 16);
    }

    // Modern Animations and Micro-interactions
    setupAnimations() {
        // Button hover effects with ripple
        const buttons = document.querySelectorAll('.btn');
        buttons.forEach(button => {
            button.addEventListener('click', (e) => {
                this.createRipple(e, button);
            });
        });

        // Card hover effects
        const cards = document.querySelectorAll('.feature-card, .code-preview');
        cards.forEach(card => {
            card.addEventListener('mouseenter', () => {
                card.style.transform = 'translateY(-8px) scale(1.02)';
            });
            
            card.addEventListener('mouseleave', () => {
                card.style.transform = 'translateY(0) scale(1)';
            });
        });

        // Logo animation on hover
        const logo = document.querySelector('.nav-logo');
        if (logo) {
            logo.addEventListener('mouseenter', () => {
                logo.style.transform = 'rotate(360deg) scale(1.1)';
            });
            
            logo.addEventListener('mouseleave', () => {
                logo.style.transform = 'rotate(0deg) scale(1)';
            });
        }
    }

    // Ripple effect for buttons
    createRipple(event, button) {
        const ripple = document.createElement('span');
        const rect = button.getBoundingClientRect();
        const size = Math.max(rect.width, rect.height);
        const x = event.clientX - rect.left - size / 2;
        const y = event.clientY - rect.top - size / 2;
        
        ripple.style.cssText = `
            position: absolute;
            border-radius: 50%;
            background: rgba(255, 255, 255, 0.6);
            transform: scale(0);
            animation: ripple 0.6s linear;
            width: ${size}px;
            height: ${size}px;
            left: ${x}px;
            top: ${y}px;
        `;
        
        button.appendChild(ripple);
        
        setTimeout(() => {
            ripple.remove();
        }, 600);
    }

    // Enhanced Code Playground
    setupCodePlayground() {
        const codeBlocks = document.querySelectorAll('.code-content pre');
        
        codeBlocks.forEach(block => {
            // Add copy button
            const copyButton = document.createElement('button');
            copyButton.innerHTML = '📋';
            copyButton.className = 'copy-btn';
            copyButton.style.cssText = `
                position: absolute;
                top: 10px;
                right: 10px;
                background: rgba(255, 255, 255, 0.1);
                border: none;
                color: white;
                padding: 8px;
                border-radius: 4px;
                cursor: pointer;
                opacity: 0;
                transition: opacity 0.3s ease;
            `;
            
            const container = block.parentElement;
            container.style.position = 'relative';
            container.appendChild(copyButton);
            
            container.addEventListener('mouseenter', () => {
                copyButton.style.opacity = '1';
            });
            
            container.addEventListener('mouseleave', () => {
                copyButton.style.opacity = '0';
            });
            
            copyButton.addEventListener('click', () => {
                navigator.clipboard.writeText(block.textContent);
                copyButton.innerHTML = '✅';
                setTimeout(() => {
                    copyButton.innerHTML = '📋';
                }, 2000);
            });
        });

        // Syntax highlighting enhancement
        this.enhanceSyntaxHighlighting();
    }

    enhanceSyntaxHighlighting() {
        const codeElements = document.querySelectorAll('.code-content code');
        
        codeElements.forEach(code => {
            let html = code.innerHTML;
            
            // Enhanced syntax highlighting patterns
            const patterns = {
                keyword: /\b(blockchain|function|contract|state|mapping|uint256|address|string|bool|public|private|view|returns|require|emit|event)\b/g,
                string: /(["'])((?:(?!\1)[^\\]|\\.)*)\1/g,
                comment: /(\/\/.*$|\/\*[\s\S]*?\*\/)/gm,
                function: /\b([a-zA-Z_][a-zA-Z0-9_]*)\s*(?=\()/g,
                type: /\b(uint256|address|string|bool|bytes32)\b/g,
                number: /\b\d+\b/g
            };
            
            // Apply syntax highlighting
            Object.entries(patterns).forEach(([className, pattern]) => {
                html = html.replace(pattern, `<span class="code-${className}">$&</span>`);
            });
            
            code.innerHTML = html;
        });
    }

    // Language Switcher Enhancement
    setupLanguageSwitcher() {
        const langButtons = document.querySelectorAll('.lang-btn');
        const content = {
            en: {
                title: 'Universal Blockchain Programming Language',
                subtitle: 'Write once, deploy everywhere. OMEGA enables cross-chain smart contract development.',
                getStarted: 'Get Started',
                documentation: 'Documentation'
            },
            id: {
                title: 'Bahasa Pemrograman Blockchain Universal',
                subtitle: 'Tulis sekali, deploy di mana saja. OMEGA memungkinkan pengembangan smart contract lintas blockchain.',
                getStarted: 'Mulai Sekarang',
                documentation: 'Dokumentasi'
            }
        };

        langButtons.forEach(button => {
            button.addEventListener('click', () => {
                const lang = button.getAttribute('data-lang');
                
                // Update active button
                langButtons.forEach(btn => btn.classList.remove('active'));
                button.classList.add('active');
                
                // Update content
                this.updateContent(content[lang]);
                
                // Store preference
                localStorage.setItem('omega-lang', lang);
            });
        });

        // Load saved language preference
        const savedLang = localStorage.getItem('omega-lang') || 'en';
        const activeButton = document.querySelector(`[data-lang="${savedLang}"]`);
        if (activeButton) {
            activeButton.click();
        }
    }

    updateContent(content) {
        const elements = {
            '.hero-title': content.title,
            '.hero-subtitle': content.subtitle,
            '.btn-primary': content.getStarted,
            '.btn-secondary': content.documentation
        };

        Object.entries(elements).forEach(([selector, text]) => {
            const element = document.querySelector(selector);
            if (element) {
                element.textContent = text;
            }
        });
    }

    // Enhanced Mobile Menu
    setupMobileMenu() {
        const mobileToggle = document.querySelector('.nav-toggle');
        const mobileMenu = document.querySelector('.mobile-menu');
        const mobileLinks = document.querySelectorAll('.mobile-nav-link');

        if (mobileToggle && mobileMenu) {
            mobileToggle.addEventListener('click', () => {
                mobileToggle.classList.toggle('active');
                mobileMenu.classList.toggle('active');
                document.body.classList.toggle('menu-open');
            });

            // Close menu when clicking links
            mobileLinks.forEach(link => {
                link.addEventListener('click', () => {
                    mobileToggle.classList.remove('active');
                    mobileMenu.classList.remove('active');
                    document.body.classList.remove('menu-open');
                });
            });

            // Close menu when clicking outside
            document.addEventListener('click', (e) => {
                if (!mobileToggle.contains(e.target) && !mobileMenu.contains(e.target)) {
                    mobileToggle.classList.remove('active');
                    mobileMenu.classList.remove('active');
                    document.body.classList.remove('menu-open');
                }
            });
        }
    }

    // Parallax Effects
    setupParallax() {
        const parallaxElements = document.querySelectorAll('.floating-element');
        
        window.addEventListener('scroll', () => {
            const scrolled = window.pageYOffset;
            const rate = scrolled * -0.5;
            
            parallaxElements.forEach((element, index) => {
                const speed = (index + 1) * 0.3;
                element.style.transform = `translateY(${rate * speed}px)`;
            });
        });
    }

    // Typing Effect for Hero Title
    setupTypingEffect() {
        const heroTitle = document.querySelector('.hero-title');
        if (!heroTitle) return;

        const text = heroTitle.textContent;
        const words = text.split(' ');
        heroTitle.innerHTML = '';

        words.forEach((word, index) => {
            const span = document.createElement('span');
            span.textContent = word + ' ';
            span.style.opacity = '0';
            span.style.animation = `fadeInUp 0.6s ease-out ${index * 0.1}s forwards`;
            heroTitle.appendChild(span);
        });
    }
}

// Code Playground functionality
class CodePlayground {
    constructor() {
        this.editor = document.querySelector('.code-editor');
        this.compileBtn = document.querySelector('.btn-compile');
        this.targetSelect = document.querySelector('.target-select');
        this.outputContent = document.querySelector('.output-content');
        this.outputStatus = document.querySelector('.output-status');
        this.tabs = document.querySelectorAll('.tab');
        
        this.examples = {
            basic: `// Basic OMEGA Smart Contract
blockchain SimpleToken {
    state {
        mapping(address => uint256) balances;
        uint256 total_supply;
        string name;
        string symbol;
    }
    
    constructor(string _name, string _symbol, uint256 _initial_supply) {
        name = _name;
        symbol = _symbol;
        total_supply = _initial_supply;
        balances[msg.sender] = _initial_supply;
    }
    
    function transfer(address to, uint256 amount) public returns (bool) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(to != address(0), "Invalid recipient");
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
        
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function balance_of(address account) public view returns (uint256) {
        return balances[account];
    }
    
    event Transfer(address indexed from, address indexed to, uint256 value);
}`,
            defi: `// DeFi AMM Example
blockchain AutomatedMarketMaker {
    state {
        mapping(address => uint256) token_a_balance;
        mapping(address => uint256) token_b_balance;
        uint256 reserve_a;
        uint256 reserve_b;
        uint256 total_liquidity;
        mapping(address => uint256) liquidity_shares;
    }
    
    function add_liquidity(uint256 amount_a, uint256 amount_b) public returns (uint256) {
        require(amount_a > 0 && amount_b > 0, "Invalid amounts");
        
        uint256 liquidity;
        if (total_liquidity == 0) {
            liquidity = sqrt(amount_a * amount_b);
        } else {
            liquidity = min(
                (amount_a * total_liquidity) / reserve_a,
                (amount_b * total_liquidity) / reserve_b
            );
        }
        
        reserve_a += amount_a;
        reserve_b += amount_b;
        total_liquidity += liquidity;
        liquidity_shares[msg.sender] += liquidity;
        
        emit LiquidityAdded(msg.sender, amount_a, amount_b, liquidity);
        return liquidity;
    }
    
    function swap_a_for_b(uint256 amount_a) public returns (uint256) {
        require(amount_a > 0, "Invalid amount");
        
        uint256 amount_b = (amount_a * reserve_b) / (reserve_a + amount_a);
        require(amount_b > 0, "Insufficient output");
        
        reserve_a += amount_a;
        reserve_b -= amount_b;
        
        emit Swap(msg.sender, amount_a, 0, 0, amount_b);
        return amount_b;
    }
    
    event LiquidityAdded(address indexed provider, uint256 amount_a, uint256 amount_b, uint256 liquidity);
    event Swap(address indexed user, uint256 amount_a_in, uint256 amount_b_in, uint256 amount_a_out, uint256 amount_b_out);
}`,
            crosschain: `// Cross-Chain Bridge Example
blockchain CrossChainBridge {
    state {
        mapping(bytes32 => bool) processed_transactions;
        mapping(address => uint256) locked_balances;
        mapping(string => bool) supported_chains;
        uint256 bridge_fee;
    }
    
    constructor() {
        supported_chains["ethereum"] = true;
        supported_chains["solana"] = true;
        supported_chains["polygon"] = true;
        bridge_fee = 1000; // 0.1%
    }
    
    @cross_chain(target = "solana")
    function bridge_to_solana(bytes32 recipient, uint256 amount) public {
        require(amount > bridge_fee, "Amount too small");
        require(supported_chains["solana"], "Chain not supported");
        
        uint256 fee = (amount * bridge_fee) / 1000000;
        uint256 net_amount = amount - fee;
        
        locked_balances[msg.sender] += amount;
        
        emit TokensBridged(msg.sender, recipient, net_amount, "solana");
    }
    
    @cross_chain(target = "ethereum")
    function bridge_to_ethereum(address recipient, uint256 amount) public {
        require(amount > bridge_fee, "Amount too small");
        require(supported_chains["ethereum"], "Chain not supported");
        
        uint256 fee = (amount * bridge_fee) / 1000000;
        uint256 net_amount = amount - fee;
        
        locked_balances[msg.sender] += amount;
        
        emit TokensBridged(msg.sender, bytes32(uint256(uint160(recipient))), net_amount, "ethereum");
    }
    
    function claim_bridged_tokens(bytes32 tx_hash, uint256 amount) public {
        require(!processed_transactions[tx_hash], "Already processed");
        
        processed_transactions[tx_hash] = true;
        // Transfer tokens to user
        
        emit TokensClaimed(msg.sender, tx_hash, amount);
    }
    
    event TokensBridged(address indexed from, bytes32 indexed to, uint256 amount, string target_chain);
    event TokensClaimed(address indexed to, bytes32 indexed tx_hash, uint256 amount);
}`
        };
        
        this.init();
    }

    init() {
        if (!this.editor) return;

        // Set initial example
        this.editor.value = this.examples.basic;

        // Handle tab switching
        this.tabs.forEach(tab => {
            tab.addEventListener('click', () => this.switchTab(tab));
        });

        // Handle compilation
        if (this.compileBtn) {
            this.compileBtn.addEventListener('click', () => this.compile());
        }

        // Handle target selection
        if (this.targetSelect) {
            this.targetSelect.addEventListener('change', () => this.updateTarget());
        }

        // Add syntax highlighting simulation
        this.editor.addEventListener('input', () => this.simulateSyntaxHighlighting());
    }

    switchTab(activeTab) {
        // Update tab appearance
        this.tabs.forEach(tab => tab.classList.remove('active'));
        activeTab.classList.add('active');

        // Load corresponding example
        const tabType = activeTab.dataset.example;
        if (this.examples[tabType]) {
            this.editor.value = this.examples[tabType];
        }
    }

    compile() {
        const code = this.editor.value.trim();
        const target = this.targetSelect.value;

        if (!code) {
            this.showOutput('Error: No code to compile', 'error');
            return;
        }

        // Simulate compilation process
        this.showOutput('Compiling...', 'compiling');
        this.compileBtn.disabled = true;
        this.compileBtn.textContent = 'Compiling...';

        setTimeout(() => {
            this.simulateCompilation(code, target);
        }, 1500);
    }

    simulateCompilation(code, target) {
        // Simple validation
        const hasBlockchain = code.includes('blockchain');
        const hasState = code.includes('state');
        const hasFunction = code.includes('function');

        if (!hasBlockchain) {
            this.showOutput('Error: Missing blockchain declaration', 'error');
            this.resetCompileButton();
            return;
        }

        // Simulate successful compilation
        const outputs = {
            evm: {
                title: 'EVM Compilation Successful',
                content: `✅ Solidity code generated successfully
📁 Output: SimpleToken.sol
⛽ Estimated gas: ~2,100,000
🔧 Optimization: Enabled
📊 Contract size: 24.5 KB

Generated files:
- contracts/SimpleToken.sol
- artifacts/SimpleToken.json
- typechain/SimpleToken.ts`
            },
            solana: {
                title: 'Solana Compilation Successful',
                content: `✅ Native code generated successfully
📁 Output: lib.rs + Cargo.toml
💾 Program size: ~45 KB
🔧 Optimization: Release mode
📊 Accounts: 3 required

Generated files:
- src/lib.rs
- Cargo.toml
- target/deploy/program.so`
            },
            cosmos: {
                title: 'Cosmos Compilation Successful',
                content: `✅ CosmWasm code generated successfully
📁 Output: contract.rs
💾 Wasm size: ~180 KB
🔧 Optimization: Enabled
📊 Gas limit: 1,000,000

Generated files:
- src/contract.rs
- schema/
- artifacts/contract.wasm`
            }
        };

        const output = outputs[target] || outputs.evm;
        this.showOutput(output.content, 'success', output.title);
        this.resetCompileButton();
    }

    showOutput(content, type, title = null) {
        this.outputStatus.textContent = title || (type === 'error' ? 'Compilation Failed' : 
                                                 type === 'compiling' ? 'Compiling...' : 'Compilation Successful');
        
        this.outputContent.innerHTML = `
            <div class="output-result ${type}">
                <pre>${content}</pre>
            </div>
        `;

        // Add appropriate styling
        const resultDiv = this.outputContent.querySelector('.output-result');
        if (type === 'error') {
            resultDiv.style.color = '#ef4444';
            resultDiv.style.background = '#fef2f2';
            resultDiv.style.border = '1px solid #fecaca';
        } else if (type === 'success') {
            resultDiv.style.color = '#059669';
            resultDiv.style.background = '#f0fdf4';
            resultDiv.style.border = '1px solid #bbf7d0';
        } else {
            resultDiv.style.color = '#d97706';
            resultDiv.style.background = '#fffbeb';
            resultDiv.style.border = '1px solid #fed7aa';
        }
        
        resultDiv.style.padding = '1rem';
        resultDiv.style.borderRadius = '0.5rem';
        resultDiv.style.fontFamily = 'var(--font-mono)';
        resultDiv.style.fontSize = '0.875rem';
        resultDiv.style.lineHeight = '1.6';
    }

    resetCompileButton() {
        this.compileBtn.disabled = false;
        this.compileBtn.textContent = 'Compile';
    }

    updateTarget() {
        const target = this.targetSelect.value;
        console.log(`Target changed to: ${target}`);
        // Could update UI based on target
    }

    simulateSyntaxHighlighting() {
        // This is a simple simulation - in a real implementation,
        // you'd use a proper syntax highlighting library like Prism.js or Monaco Editor
        // For now, we'll just add some basic styling hints
    }
}

// Statistics Counter Animation
class StatsCounter {
    constructor() {
        this.stats = document.querySelectorAll('.stat-number');
        this.init();
    }

    init() {
        // Intersection Observer for animation trigger
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    this.animateCounter(entry.target);
                    observer.unobserve(entry.target);
                }
            });
        });

        this.stats.forEach(stat => observer.observe(stat));
    }

    animateCounter(element) {
        const target = parseInt(element.textContent.replace(/[^0-9]/g, ''));
        const duration = 2000;
        const step = target / (duration / 16);
        let current = 0;

        const timer = setInterval(() => {
            current += step;
            if (current >= target) {
                current = target;
                clearInterval(timer);
            }
            
            // Format number with appropriate suffix
            let displayValue = Math.floor(current);
            if (target >= 1000) {
                displayValue = (displayValue / 1000).toFixed(1) + 'K+';
            } else {
                displayValue = displayValue + '+';
            }
            
            element.textContent = displayValue;
        }, 16);
    }
}

// Scroll Animations
class ScrollAnimations {
    constructor() {
        this.elements = document.querySelectorAll('.feature-card, .doc-card, .community-card');
        this.init();
    }

    init() {
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.style.opacity = '1';
                    entry.target.style.transform = 'translateY(0)';
                }
            });
        }, {
            threshold: 0.1,
            rootMargin: '0px 0px -50px 0px'
        });

        this.elements.forEach(element => {
            element.style.opacity = '0';
            element.style.transform = 'translateY(30px)';
            element.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
            observer.observe(element);
        });
    }
}

// Theme Toggle (for future dark mode support)
class ThemeToggle {
    constructor() {
        this.theme = localStorage.getItem('omega-theme') || 'light';
        this.init();
    }

    init() {
        // Apply saved theme
        document.documentElement.setAttribute('data-theme', this.theme);
        
        // Create theme toggle button (if needed in future)
        // This is prepared for future dark mode implementation
    }

    toggle() {
        this.theme = this.theme === 'light' ? 'dark' : 'light';
        document.documentElement.setAttribute('data-theme', this.theme);
        localStorage.setItem('omega-theme', this.theme);
    }
}

// Copy to Clipboard functionality
class ClipboardManager {
    constructor() {
        this.init();
    }

    init() {
        // Add copy buttons to code blocks
        document.querySelectorAll('pre code').forEach(codeBlock => {
            this.addCopyButton(codeBlock);
        });
    }

    addCopyButton(codeBlock) {
        const button = document.createElement('button');
        button.className = 'copy-btn';
        button.innerHTML = '📋';
        button.title = 'Copy to clipboard';
        
        button.addEventListener('click', () => {
            this.copyToClipboard(codeBlock.textContent);
            button.innerHTML = '✅';
            setTimeout(() => {
                button.innerHTML = '📋';
            }, 2000);
        });

        const container = codeBlock.parentElement;
        container.style.position = 'relative';
        container.appendChild(button);
        
        // Style the copy button
        button.style.position = 'absolute';
        button.style.top = '0.5rem';
        button.style.right = '0.5rem';
        button.style.background = 'rgba(255, 255, 255, 0.1)';
        button.style.border = 'none';
        button.style.borderRadius = '0.25rem';
        button.style.padding = '0.25rem 0.5rem';
        button.style.cursor = 'pointer';
        button.style.fontSize = '0.875rem';
    }

    async copyToClipboard(text) {
        try {
            await navigator.clipboard.writeText(text);
        } catch (err) {
            // Fallback for older browsers
            const textArea = document.createElement('textarea');
            textArea.value = text;
            document.body.appendChild(textArea);
            textArea.select();
            document.execCommand('copy');
            document.body.removeChild(textArea);
        }
    }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    new OmegaWebsite();
    new CodePlayground();
    new StatsCounter();
    new ScrollAnimations();
    new ThemeToggle();
    new ClipboardManager();
    
    console.log('🚀 OMEGA Website with enhanced animations initialized successfully!');
    
    // Add performance monitoring
    if ('performance' in window) {
        window.addEventListener('load', () => {
            const loadTime = performance.now();
            console.log(`⚡ Page loaded in ${Math.round(loadTime)}ms`);
        });
    }
});

// Add CSS animations
const style = document.createElement('style');
style.textContent = `
    @keyframes ripple {
        to {
            transform: scale(4);
            opacity: 0;
        }
    }
    
    @keyframes fadeInUp {
        from {
            opacity: 0;
            transform: translateY(30px);
        }
        to {
            opacity: 1;
            transform: translateY(0);
        }
    }
    
    .animate-in {
        animation: fadeInUp 0.8s ease-out forwards;
    }
    
    .nav-logo {
        transition: transform 0.3s ease;
    }
    
    .feature-card, .code-preview {
        transition: transform 0.3s ease, box-shadow 0.3s ease;
    }
    
    .btn {
        position: relative;
        overflow: hidden;
    }
    
    body.menu-open {
        overflow: hidden;
    }
`;
document.head.appendChild(style);

// Handle external links with enhanced security
document.addEventListener('click', (e) => {
    if (e.target.matches('a[href^="http"]')) {
        e.target.setAttribute('target', '_blank');
        e.target.setAttribute('rel', 'noopener noreferrer');
        
        // Add visual feedback for external links
        e.target.style.transition = 'all 0.3s ease';
        e.target.style.transform = 'scale(1.05)';
        setTimeout(() => {
            e.target.style.transform = 'scale(1)';
        }, 200);
    }
});

// Performance optimization: Enhanced lazy loading with fade-in effect
if ('IntersectionObserver' in window) {
    const imageObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const img = entry.target;
                img.style.transition = 'opacity 0.5s ease';
                img.style.opacity = '0';
                
                img.onload = () => {
                    img.style.opacity = '1';
                    img.classList.remove('lazy');
                    img.classList.add('loaded');
                };
                
                img.src = img.dataset.src;
                imageObserver.unobserve(img);
            }
        });
    }, {
        rootMargin: '50px 0px',
        threshold: 0.1
    });

    document.querySelectorAll('img[data-src]').forEach(img => {
        img.style.opacity = '0';
        img.style.transition = 'opacity 0.5s ease';
        imageObserver.observe(img);
    });
    
    // Add loading placeholder styles
    const imgStyle = document.createElement('style');
    imgStyle.textContent = `
        img.lazy {
            background: linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%);
            background-size: 200% 100%;
            animation: loading 1.5s infinite;
        }
        
        @keyframes loading {
            0% { background-position: 200% 0; }
            100% { background-position: -200% 0; }
        }
        
        img.loaded {
            animation: none;
            background: none;
        }
    `;
    document.head.appendChild(imgStyle);
}