# OMEGA - Universal Blockchain Programming Language

![OMEGA Logo](https://img.shields.io/badge/OMEGA-Blockchain%20Language-blue?style=for-the-badge)
![Version](https://img.shields.io/badge/version-1.0.0-green?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)

## 📚 Quick Navigation

| Getting Started | Language Reference | Development |
|---|---|---|
| [🚀 Getting Started Guide](Getting-Started-Guide.md) | [📖 Language Specification](Language-Specification.md) | [🏗️ Compiler Architecture](Compiler-Architecture.md) |
| [📦 Installation](#-instalasi) | [🔧 API Reference](API-Reference.md) | [🤝 Contributing](Contributing.md) |
| [⚡ Quick Start](#-quick-start) | [📚 Examples](#-use-cases--examples) | [🐛 Issue Reporting](Contributing.md#-issue-reporting) |

---

## 🌟 Visi Proyek

OMEGA adalah bahasa pemrograman revolusioner yang dirancang khusus untuk pengembangan blockchain dengan prinsip **"Write Once, Deploy Everywhere"**. Dengan OMEGA, developer dapat menulis smart contract sekali dan mengompilasi ke berbagai target blockchain baik EVM maupun non-EVM.

## 🚀 Fitur Utama

### ✨ Universal Compatibility
- **EVM Compatible**: Ethereum, Polygon, BSC, Avalanche, Arbitrum
- **Non-EVM Support**: Solana, Cosmos, Substrate, Move VM
- **Cross-Chain**: Built-in support untuk komunikasi antar blockchain

### 🔒 Type Safety & Security
- Strong typing system dengan compile-time checks
- Built-in security patterns untuk mencegah vulnerabilities
- Automatic gas optimization untuk target EVM

### 🎯 Developer Experience
- Sintaks yang familiar dan ekspresif
- Rich standard library untuk operasi blockchain
- Comprehensive tooling dan debugging support

### ⚡ Performance Optimized
- Target-specific optimizations
- Efficient memory management
- Minimal runtime overhead

## 📦 Instalasi

### Prerequisites
- Make build system
- Node.js 18+ (untuk EVM tooling)
- Git

### Install dari Source
```bash
git clone https://github.com/Rafael2022-prog/omega-lang.git
cd omega
make build
make install
```

### Install via Package Manager
```bash
# NPM Package (Available for v1.2.0+)
npm install -g @omega-lang/cli@latest

# Chocolatey (Windows)
choco install omega-lang

# Homebrew (macOS/Linux) - Coming Soon
# brew install omega-lang
```

## 🏗️ Quick Start

### 1. Inisialisasi Proyek Baru
```bash
omega init my-dapp --template basic
cd my-dapp
```

### 2. Konfigurasi Target
```bash
omega config enable evm solana
omega config show
```

### 3. Tulis Smart Contract Pertama
```omega
// contracts/SimpleToken.omega
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
}
```

### 4. Compile untuk Multiple Targets
```bash
omega build
# Output:
# ✅ EVM: SimpleToken.sol generated
# ✅ Solana: native code generated
# ✅ Build completed successfully
```

### 5. Deploy ke Testnet
```bash
omega deploy --target evm --network sepolia
omega deploy --target solana --network devnet
```

## 📚 Dokumentasi Lengkap

### 📖 Panduan Pembelajaran
- [Language Specification](Language-Specification.md) - Spesifikasi lengkap bahasa OMEGA
- [Getting Started Guide](Getting-Started-Guide.md) - Tutorial step-by-step
- [API Reference](API-Reference.md) - Dokumentasi API lengkap
- [Compiler Architecture](Compiler-Architecture.md) - Arsitektur compiler

### 🔧 Developer Tools
- [Compiler Architecture](Compiler-Architecture.md) - Arsitektur compiler
- [API Reference](API-Reference.md) - Command line interface
- [Contributing](Contributing.md) - Panduan kontribusi
- [Getting Started Guide](Getting-Started-Guide.md) - Setup development

### 🌐 Blockchain Integration
- [Language Specification](Language-Specification.md) - Ethereum Virtual Machine
- [API Reference](API-Reference.md) - Solana runtime
- [Compiler Architecture](Compiler-Architecture.md) - Cosmos SDK
- [Home](Home.md) - Inter-blockchain communication

## 🤝 Contributing

Kami menyambut kontribusi dari komunitas! Lihat [Contributing](Contributing.md) untuk panduan kontribusi.

### Development Setup
```bash
git clone https://github.com/Rafael2022-prog/omega-lang.git
cd omega
make build
omega test
```

### Areas for Contribution
- 🐛 Bug fixes dan improvements
- 📚 Documentation dan tutorials
- 🔧 New blockchain target support
- ⚡ Performance optimizations
- 🧪 Test coverage expansion

## 📊 Roadmap

### Phase 1: Core Language (Q1 2025) ✅
- [x] Language specification
- [x] Basic compiler architecture
- [x] EVM code generation
- [x] Solana code generation

### Phase 2: Advanced Features (Q2 2025)
- [ ] Cross-chain communication primitives
- [ ] Advanced optimization passes
- [ ] IDE integration (VS Code)
- [ ] Package manager

### Phase 3: Ecosystem (Q3 2025)
- [ ] Standard library expansion
- [ ] DeFi protocol templates
- [ ] Governance framework
- [ ] Audit tools integration

### Phase 4: Production Ready (Q4 2025)
- [ ] Mainnet deployments
- [ ] Security audits
- [ ] Performance benchmarks
- [ ] Enterprise features

## 📞 Support & Community

- 💬 **Discord**: [Join our community](https://discord.gg/omega-lang)
- 🐦 **Twitter**: [@omega_lang](https://twitter.com/omega_lang)
- 📧 **Email**: support@omega-lang.org
- 📖 **Documentation**: [docs.omega-lang.org](https://docs.omega-lang.org)
- 🐛 **Issues**: [GitHub Issues](https://github.com/omega-lang/omega/issues)

## 📄 License

OMEGA is licensed under the [MIT License](./LICENSE).

## 🙏 Acknowledgments

Terima kasih kepada:
- Ethereum Foundation untuk EVM specification
- Solana Labs untuk Solana runtime documentation
- OMEGA community untuk tooling inspiration
- All contributors dan early adopters

---

## 📖 Wiki Navigation

| **Documentation** | **Development** | **Community** |
|---|---|---|
| [🏠 Home](Home.md) | [🏗️ Compiler Architecture](Compiler-Architecture.md) | [🤝 Contributing](Contributing.md) |
| [🚀 Getting Started](Getting-Started-Guide.md) | [🔧 API Reference](API-Reference.md) | [💬 Discord](https://discord.gg/omega-lang) |
| [📖 Language Spec](Language-Specification.md) | [🧪 Testing Guide](Contributing.md#-testing) | [🐦 Twitter](https://twitter.com/omega_lang) |

---

**Created by Emylton Leunufna - 2025**

*"Bridging the gap between blockchain ecosystems, one smart contract at a time."*