# Getting Started with OMEGA

> [🏠 Home](Home.md) | [📖 Language Spec](Language-Specification.md) | [🏗️ Compiler Architecture](Compiler-Architecture.md) | [🔧 API Reference](API-Reference.md) | [🤝 Contributing](Contributing.md)

Selamat datang di OMEGA! Panduan ini akan membantu Anda memulai perjalanan pengembangan blockchain dengan bahasa pemrograman universal OMEGA.

## 📋 Prerequisites

Sebelum memulai, pastikan sistem Anda memiliki:

- **Make build system** - Untuk kompilasi
- **Node.js 18+** - Untuk EVM tooling
- **Git** - Untuk version control
- **Text Editor/IDE** - VS Code direkomendasikan

## 🚀 Instalasi

### Metode 1: Install dari Source

```bash
# Clone repository
git clone https://github.com/Rafael2022-prog/omega-lang.git
cd omega

# Build dan install
make build
make install

# Verifikasi instalasi
omega --version
```

### Metode 2: Package Manager (Available v1.2.0+)

```bash
# NPM Package (Available Now!)
npm install -g @omega-lang/cli@latest

# Chocolatey (Windows - Available Now!)
choco install omega-lang

# Homebrew (macOS/Linux - Coming Soon)
# brew install omega-lang

# Verify installation
omega --version
```

## 🏗️ Membuat Proyek Pertama

### 1. Inisialisasi Proyek

```bash
# Buat proyek baru
omega init my-first-dapp --template basic
cd my-first-dapp

# Lihat struktur proyek
ls -la
```

Struktur proyek yang dihasilkan:

```
my-first-dapp/
├── contracts/
│   └── SimpleToken.omega
├── tests/
│   └── token_test.omega
├── omega.toml
└── README.md
```

### 2. Konfigurasi Target Blockchain

```bash
# Enable target blockchain
omega config enable evm solana

# Lihat konfigurasi
omega config show

# Set default target
omega config set default-target evm
```

### 3. Tulis Smart Contract Pertama

Buat file `contracts/MyToken.omega`:

```omega
blockchain MyToken {
    state {
        mapping(address => uint256) balances;
        uint256 totalSupply;
        string name;
        string symbol;
        address owner;
    }
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }
    
    constructor(string _name, string _symbol, uint256 _initialSupply) {
        name = _name;
        symbol = _symbol;
        totalSupply = _initialSupply;
        owner = msg.sender;
        balances[msg.sender] = _initialSupply;
        
        emit Transfer(address(0), msg.sender, _initialSupply);
    }
    
    function transfer(address to, uint256 amount) public returns (bool) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(to != address(0), "Invalid recipient");
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
        
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
    
    function mint(address to, uint256 amount) public onlyOwner {
        totalSupply += amount;
        balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }
}
```

## 🔨 Kompilasi dan Build

### Kompilasi untuk Single Target

```bash
# Kompilasi untuk EVM
omega build --target evm

# Kompilasi untuk Solana
omega build --target solana

# Kompilasi untuk Cosmos
omega build --target cosmos
```

### Kompilasi untuk Multiple Targets

```bash
# Kompilasi untuk semua target yang enabled
omega build

# Output yang dihasilkan:
# ✅ EVM: MyToken.sol generated
# ✅ Solana: native code generated
# ✅ Build completed successfully
```

### Melihat Output

```bash
# Lihat file yang dihasilkan
ls -la build/

# Struktur build directory:
build/
├── evm/
│   ├── MyToken.sol
│   └── artifacts/
├── solana/
│   ├── lib.rs
│   └── Cargo.toml
└── cosmos/
    └── contract.rs
```

## 🧪 Testing

### Menulis Test

Buat file `tests/my_token_test.omega`:

```omega
test_suite MyTokenTests {
    use contracts.MyToken;
    
    test "should deploy with correct initial values" {
        let token = MyToken.new("Test Token", "TST", 1000000);
        
        assert_eq!(token.name(), "Test Token");
        assert_eq!(token.symbol(), "TST");
        assert_eq!(token.totalSupply(), 1000000);
        assert_eq!(token.balanceOf(msg.sender), 1000000);
    }
    
    test "should transfer tokens correctly" {
        let token = MyToken.new("Test", "TST", 1000);
        let recipient = address("0x742d35Cc6634C0532925a3b8D4C9db96590c6C87");
        
        let success = token.transfer(recipient, 100);
        
        assert_eq!(success, true);
        assert_eq!(token.balanceOf(recipient), 100);
        assert_eq!(token.balanceOf(msg.sender), 900);
    }
    
    test "should fail on insufficient balance" {
        let token = MyToken.new("Test", "TST", 100);
        let recipient = address("0x742d35Cc6634C0532925a3b8D4C9db96590c6C87");
        
        expect_revert(
            token.transfer(recipient, 200),
            "Insufficient balance"
        );
    }
    
    test "only owner can mint" {
        let token = MyToken.new("Test", "TST", 1000);
        let other_user = address("0x742d35Cc6634C0532925a3b8D4C9db96590c6C87");
        
        // Owner can mint
        token.mint(other_user, 500);
        assert_eq!(token.balanceOf(other_user), 500);
        
        // Non-owner cannot mint
        set_caller(other_user);
        expect_revert(
            token.mint(other_user, 100),
            "Not the owner"
        );
    }
}
```

### Menjalankan Test

```bash
# Run semua test
omega test

# Run test specific
omega test --suite MyTokenTests

# Run dengan verbose output
omega test --verbose

# Run test untuk target tertentu
omega test --target evm
```

## 🚀 Deployment

### Setup Network Configuration

Edit file `omega.toml`:

```toml
[project]
name = "my-first-dapp"
version = "0.1.0"

[targets]
evm = true
solana = true

[networks.sepolia]
type = "evm"
rpc_url = "https://sepolia.infura.io/v3/YOUR_PROJECT_ID"
chain_id = 11155111

[networks.devnet]
type = "solana"
rpc_url = "https://api.devnet.solana.com"
```

### Deploy ke Testnet

```bash
# Deploy ke Ethereum Sepolia
omega deploy --target evm --network sepolia --contract MyToken

# Deploy ke Solana Devnet
omega deploy --target solana --network devnet --contract MyToken

# Deploy dengan constructor arguments
omega deploy --target evm --network sepolia --contract MyToken \
  --args "My Token" "MTK" 1000000
```

### Verifikasi Deployment

```bash
# Lihat deployment history
omega deployments list

# Get contract address
omega deployments get MyToken --network sepolia

# Verify contract
omega verify --network sepolia --address 0x...
```

## 🔧 Development Workflow

### 1. Development Loop

```bash
# Edit contract
vim contracts/MyToken.omega

# Compile dan test
omega build && omega test

# Deploy ke local testnet
omega deploy --target evm --network local
```

### 2. Debugging

```bash
# Compile dengan debug info
omega build --debug

# Run dengan verbose logging
omega test --verbose --debug

# Analyze gas usage
omega analyze --gas contracts/MyToken.omega
```

### 3. Code Formatting

```bash
# Format code
omega format contracts/

# Check formatting
omega format --check

# Lint code
omega lint contracts/
```

## 📚 Next Steps

Sekarang Anda sudah memiliki dasar-dasar OMEGA! Berikut langkah selanjutnya:

### Pelajari Lebih Lanjut
- [Language Specification](Language-Specification.md) - Pelajari sintaks lengkap OMEGA
- [API Reference](API-Reference.md) - Dokumentasi API lengkap
- [Compiler Architecture](Compiler-Architecture.md) - Memahami cara kerja compiler

### Advanced Topics
- [Home](Home.md) - Kembali ke halaman utama
- [Contributing](Contributing.md) - Berkontribusi ke proyek OMEGA

### Tools & Integration
- [Home](Home.md) - Setup VS Code extension
- [API Reference](API-Reference.md) - Command lengkap CLI
- [Compiler Architecture](Compiler-Architecture.md) - Advanced debugging

### Community
- 💬 [Discord Community](https://discord.gg/omega-lang)
- 🐛 [Report Issues](https://github.com/omega-lang/omega/issues)
- 📖 [Documentation](https://docs.omega-lang.org)

## 🆘 Troubleshooting

### Common Issues

**Error: "omega command not found"**
```bash
# Pastikan PATH sudah di-set
export PATH=$PATH:/usr/local/bin/omega
source ~/.bashrc
```

**Error: "Target not supported"**
```bash
# Enable target terlebih dahulu
omega config enable evm
```

**Build Error: "Contract not found"**
```bash
# Pastikan file contract ada
ls contracts/
omega build --verbose
```

### Getting Help

Jika mengalami masalah:

1. Cek [Contributing Guide](Contributing.md) untuk troubleshooting
2. Search di [GitHub Issues](https://github.com/omega-lang/omega/issues)
3. Tanya di [Discord Community](https://discord.gg/omega-lang)
4. Buat issue baru jika diperlukan

## Next Steps

- 📖 Pelajari [Language Specification](Language-Specification.md) untuk detail sintaks
- 🏗️ Pahami [Compiler Architecture](Compiler-Architecture.md) untuk advanced usage
- 🔧 Explore [API Reference](API-Reference.md) untuk integrasi
- 🤝 Bergabung dengan [Contributing](Contributing.md) untuk berkontribusi

---

> [🏠 Home](Home.md) | [📖 Language Spec](Language-Specification.md) | [🏗️ Compiler Architecture](Compiler-Architecture.md) | [🔧 API Reference](API-Reference.md) | [🤝 Contributing](Contributing.md)

Selamat coding dengan OMEGA! 🚀