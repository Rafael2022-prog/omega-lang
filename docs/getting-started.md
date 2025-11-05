# Getting Started with OMEGA

OMEGA adalah bahasa pemrograman blockchain universal yang memungkinkan Anda menulis smart contract sekali dan deploy ke berbagai blockchain. Dengan ekstensi file native `.mega` dan logo OMEGA yang terintegrasi, OMEGA memberikan pengalaman development yang konsisten dan profesional.

## ⚠️ Pembaruan Penting (Windows Native-Only)

Saat ini toolchain dan pipeline CI berjalan dalam mode native-only di Windows.
Gunakan langkah-langkah berikut untuk memulai tanpa ketergantungan Rust/npm/mdBook/valgrind/cargo-tarpaulin:

- Build: `pwsh -NoProfile -ExecutionPolicy Bypass -File build_omega_native.ps1`
- Jalankan: gunakan `omega.exe` jika ada, jika tidak `pwsh -File omega.ps1`
- Subcommand yang tersedia: `compile`, `--version`, `--help` (build/test/deploy belum aktif di wrapper CLI)
- Coverage: `scripts/generate_coverage.ps1` menghasilkan `coverage/omega-coverage.json` dan `coverage/omega-coverage.lcov` lalu upload via Codecov uploader resmi

### Quickstart (Native-Only)
```powershell
# 1) Build
pwsh -NoProfile -ExecutionPolicy Bypass -File .\build_omega_native.ps1 -Clean

# 2) Jalankan
$omegaCmd = if (Test-Path .\omega.exe) { .\omega.exe } else { "pwsh -NoProfile -ExecutionPolicy Bypass -File .\omega.ps1" }
Invoke-Expression "$omegaCmd --version"
Invoke-Expression "$omegaCmd compile tests\lexer_tests.mega"
Invoke-Expression "$omegaCmd compile tests\parser_tests.mega"

# 3) Coverage
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\generate_coverage.ps1 -SourceDir tests -OutputDir coverage -Verbose
```

## 📋 Prerequisites

Sebelum memulai, pastikan sistem Anda memiliki:

### System Requirements
- **Operating System**: Windows 10+, macOS 10.15+, atau Linux (Ubuntu 18.04+)
- **Memory**: Minimum 4GB RAM (8GB recommended)
- **Storage**: 2GB free space
- **Internet**: Untuk download dependencies dan blockchain interaction

### Required Software
```bash
# 1. Rust (1.70 atau lebih baru)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# 2. Node.js (18 atau lebih baru)
# Download dari https://nodejs.org atau gunakan nvm
nvm install 18
nvm use 18

# 3. Git
# Download dari https://git-scm.com

# Verifikasi instalasi
rustc --version
node --version
git --version
```

## 🚀 Instalasi OMEGA

### Method 1: Install dari Source (Recommended)
```bash
# Clone repository
git clone https://github.com/Rafael2022-prog/omega-lang.git
cd omega

# Build compiler
cargo build --release

# Install globally
cargo install --path .

# Verifikasi instalasi
omega --version
```

### Method 2: Pre-built Binaries
```bash
# Download latest release
curl -L https://github.com/Rafael2022-prog/omega-lang/releases/latest/download/omega-x86_64-unknown-linux-gnu.tar.gz | tar xz

# Move to PATH
sudo mv omega /usr/local/bin/

# Verifikasi
omega --version
```

## 🏗️ Membuat Proyek Pertama

### 1. Inisialisasi Proyek
```bash
# Buat proyek baru dengan template basic
omega init my-first-dapp --template basic
cd my-first-dapp

# Struktur proyek yang dibuat:
# my-first-dapp/
# ├── omega.toml          # Konfigurasi proyek
# ├── contracts/          # Smart contracts
# │   └── SimpleToken.mega
# ├── tests/              # Test files
# │   └── basic_tests.json
# ├── scripts/            # Deployment scripts
# └── README.md
```

### 2. Konfigurasi Target Blockchain
```bash
# Lihat konfigurasi saat ini
omega config show

# Enable target blockchain yang diinginkan
omega config enable evm solana

# Set network untuk testing
omega config set evm.network sepolia
omega config set solana.network devnet

# Lihat konfigurasi yang sudah diupdate
omega config show
```

### 3. Memahami File Konfigurasi dengan Arsitektur Modular
```toml
# omega.toml
[project]
name = "my-first-dapp"
version = "1.0.0"
description = "My first OMEGA DApp"
authors = ["Your Name <your.email@example.com>"]

[compiler]
optimization_level = "basic"  # none, basic, aggressive
debug_info = true
warnings_as_errors = false
ir_output = true
optimization_passes = [
    "constant_folding",
    "dead_code_elimination",
    "gas_optimization"
]

[targets]
evm = { 
    enabled = true, 
    network = "sepolia",
    solidity_version = "0.8.19",
    gas_optimizations = true
}
solana = { 
    enabled = true, 
    network = "devnet",
    anchor_framework = true,
    program_id = "11111111111111111111111111111112"
}
cosmos = { 
    enabled = false,
    sdk_version = "0.47.0",
    wasm_enabled = true
}

[build]
output_dir = "build"
source_dir = "contracts"
emit_ir = false
parallel_compilation = true

[deployment]
evm = { rpc_url = "https://sepolia.infura.io/v3/YOUR_KEY" }
solana = { rpc_url = "https://api.devnet.solana.com" }

[testing]
test_dir = "tests"
timeout_ms = 30000
parallel_tests = true

[ir]
optimization_stats = true
visualization = false
output_format = "human"  # human, json, dot
```

## 📝 Writing Your First Smart Contract

Sekarang mari kita buat smart contract sederhana menggunakan OMEGA dengan ekstensi `.mega`:

### Simple Token Contract

Buat file baru `src/main.mega`:

```omega
// src/main.mega
blockchain evm, solana;

use std::collections::Map;
use std::token::ERC20;

contract SimpleToken {
    // State variables
    name: String = "My First Token";
    symbol: String = "MFT";
    decimals: u8 = 18;
    total_supply: u256;
    
    // Mappings
    balances: Map<address, u256>;
    allowances: Map<address, Map<address, u256>>;
    
    // Owner
    owner: address;
    
    // Events
    event Transfer(from: address, to: address, value: u256);
    event Approval(owner: address, spender: address, value: u256);
    
    // Constructor
    constructor(initial_supply: u256) {
        total_supply = initial_supply * 10^decimals;
        owner = msg.sender;
        balances[msg.sender] = total_supply;
        
        emit Transfer(address(0), msg.sender, total_supply);
    }
    
    // Public functions
    pub fn transfer(to: address, amount: u256) -> bool {
        require(to != address(0), "Transfer to zero address");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
        
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    pub fn approve(spender: address, amount: u256) -> bool {
        require(spender != address(0), "Approve to zero address");
        
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    pub fn transfer_from(from: address, to: address, amount: u256) -> bool {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        require(balances[from] >= amount, "Insufficient balance");
        require(allowances[from][msg.sender] >= amount, "Insufficient allowance");
        
        balances[from] -= amount;
        balances[to] += amount;
        allowances[from][msg.sender] -= amount;
        
        emit Transfer(from, to, amount);
        return true;
    }
    
    // View functions
    pub fn balance_of(account: address) -> u256 view {
        return balances[account];
    }
    
    pub fn allowance(owner_addr: address, spender: address) -> u256 view {
        return allowances[owner_addr][spender];
    }
    
    pub fn get_total_supply() -> u256 view {
        return total_supply;
    }
}
    
    function get_total_supply() public view returns (uint256) {
        return total_supply;
    }
    
    // Owner-only functions
    function mint(address to, uint256 amount) public {
        require(msg.sender == owner, "Only owner can mint");
        require(to != address(0), "Mint to zero address");
        
        total_supply += amount;
        balances[to] += amount;
        
        emit Transfer(address(0), to, amount);
    }
    
    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
```

## 🔨 Compile dan Build dengan Arsitektur Modular

### 1. Basic Compilation
```bash
# Compile untuk semua target yang enabled
omega build

# Dengan level optimasi spesifik
omega build --optimization basic
omega build --optimization aggressive

# Output IR untuk debugging
omega build --emit-ir

# Output yang dihasilkan:
# ✅ Compiling SimpleToken.mega...
# ✅ IR Generation: 156 instructions generated
# ✅ Optimization: 3 passes applied (12% reduction)
# ✅ EVM target: build/evm/SimpleToken.sol
# ✅ Solana target: build/solana/lib.rs, build/solana/Cargo.toml
# ✅ Build completed in 2.1s
```

### 2. Advanced Compilation dengan Custom Passes
```bash
# Compile dengan optimization passes spesifik
omega build --passes constant_folding,dead_code_elimination,gas_optimization

# Compile dengan konfigurasi custom
omega build --config custom_build.toml

# Analyze IR sebelum dan sesudah optimasi
omega build --emit-ir --optimization-stats
```

### 3. Programmatic API Usage
Untuk integrasi dengan tools lain, Anda dapat menggunakan OMEGA API secara programmatic:

```rust
// examples/programmatic_usage.rs
use omega::compiler::{OmegaCompiler, CompilerConfig, GenerationTarget, OptimizationLevel};
use std::path::PathBuf;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Setup compiler configuration
    let config = CompilerConfig {
        optimization_level: OptimizationLevel::Basic,
        debug_info: true,
        warnings_as_errors: false,
        output_dir: PathBuf::from("build"),
        ir_output: true,
        optimization_passes: vec![
            "constant_folding".to_string(),
            "dead_code_elimination".to_string(),
        ],
    };
    
    // Create compiler instance
    let mut compiler = OmegaCompiler::new(config);
    
    // Add compilation targets
    compiler.add_target(GenerationTarget::EVM {
        version: EVMVersion::London,
        solidity_version: "0.8.19".to_string(),
        gas_optimizations: true,
    });
    
    compiler.add_target(GenerationTarget::Solana {
        program_id: Some("11111111111111111111111111111112".to_string()),
        anchor_framework: true,
        cluster: SolanaCluster::Devnet,
    });
    
    // Read source code
    let source = std::fs::read_to_string("contracts/SimpleToken.mega")?;
    
    // Compile with IR output
    let (ir_module, result) = compiler.compile_with_ir(&source)?;
    
    // Print compilation results
    println!("Compilation successful: {}", result.success);
    println!("Generated {} files", result.outputs.files.len());
    
    // Print IR statistics
    println!("IR Statistics:");
    println!("  Functions: {}", ir_module.functions.len());
    println!("  Instructions: {}", ir_module.instruction_count());
    
    // Access generated files
    for file in result.outputs.files {
        println!("Generated {}: {} lines", file.filename, file.content.lines().count());
        
        // Write to filesystem
        std::fs::write(&file.filename, &file.content)?;
    }
    
    Ok(())
}
```

### 4. IR Analysis dan Debugging
```bash
# Generate dan analyze IR
omega ir generate contracts/SimpleToken.mega --output build/ir/

# Optimize IR dengan specific passes
omega ir optimize build/ir/SimpleToken.ir --passes constant_folding,dead_code_elimination

# Visualize IR
omega ir visualize build/ir/SimpleToken.ir --format dot --output build/ir/graph.dot

# Compare IR sebelum dan sesudah optimasi
omega ir diff build/ir/SimpleToken.ir build/ir/SimpleToken.optimized.ir
```

**EVM Output (Solidity):**
```solidity
// build/evm/MyToken.sol
pragma solidity ^0.8.19;

contract MyToken {
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    
    uint256 private total_supply;
    string private name;
    string private symbol;
    uint8 private decimals;
    address private owner;
    
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initial_supply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        total_supply = _initial_supply * (10 ** _decimals);
        owner = msg.sender;
        balances[msg.sender] = total_supply;
        
        emit Transfer(address(0), msg.sender, total_supply);
    }
    
    // ... rest of the functions
}
```

**Solana Output (Rust):**
```rust
// build/solana/lib.mega
use anchor_lang::prelude::*;

declare_id!("11111111111111111111111111111111");

#[program]
pub mod my_token {
    use super::*;
    
    pub fn initialize(
        ctx: Context<Initialize>,
        name: String,
        symbol: String,
        decimals: u8,
        initial_supply: u64,
    ) -> Result<()> {
        let token_account = &mut ctx.accounts.token_account;
        token_account.name = name;
        token_account.symbol = symbol;
        token_account.decimals = decimals;
        token_account.total_supply = initial_supply * (10_u64.pow(decimals as u32));
        token_account.owner = ctx.accounts.authority.key();
        
        Ok(())
    }
    
    // ... rest of the functions
}
```

## 🧪 Testing

Catatan: Perintah `omega test` belum aktif di wrapper CLI native-only saat ini. Untuk verifikasi dasar, gunakan kompilasi compile-only (contoh: `omega compile tests\lexer_tests.mega`).

### 1. Membuat Test Suite
```json
// tests/token_tests.json
{
  "name": "MyToken Test Suite",
  "description": "Comprehensive tests for MyToken contract",
  "test_cases": [
    {
      "id": "deployment_test",
      "name": "Contract Deployment",
      "description": "Test successful contract deployment",
      "targets": ["evm", "solana"],
      "source_code": "blockchain MyToken { ... }",
      "expected_outputs": {
        "evm": {
          "success": true,
          "gas_usage": { "deployment_gas": 800000 }
        },
        "solana": {
          "success": true
        }
      },
      "test_type": "Compilation",
      "timeout_ms": 30000
    },
    {
      "id": "transfer_test",
      "name": "Token Transfer",
      "description": "Test token transfer functionality",
      "targets": ["evm", "solana"],
      "source_code": "// Test transfer function",
      "expected_outputs": {
        "evm": {
          "success": true,
          "execution_result": { "return_value": true }
        },
        "solana": {
          "success": true
        }
      },
      "test_type": "Execution",
      "timeout_ms": 15000
    }
  ]
}
```

### 2. Menjalankan Tests
```bash
# Run all tests
omega test

# Run specific test suite
omega test --suite token_tests

# Run tests untuk target tertentu
omega test --target evm
omega test --target solana

# Run dengan verbose output
omega test --verbose

# Output:
# 🧪 Running MyToken Test Suite...
# ✅ deployment_test (EVM): PASSED (2.1s)
# ✅ deployment_test (Solana): PASSED (1.8s)
# ✅ transfer_test (EVM): PASSED (0.9s)
# ✅ transfer_test (Solana): PASSED (0.7s)
# 
# 📊 Test Results:
# Total: 4 tests
# Passed: 4 (100%)
# Failed: 0 (0%)
# Duration: 5.5s
```

## 🚀 Deployment

Catatan: Perintah `omega deploy` belum aktif di wrapper CLI native-only saat ini; bagian ini bersifat forward-looking. Fokus saat ini pada kompilasi (`omega compile`).

### 1. Setup Network Configuration
```bash
# Set up environment variables (do NOT commit secrets)
export INFURA_API_KEY="your_infura_api_key"
export PRIVATE_KEY="your_private_key"
export SOLANA_PRIVATE_KEY="your_solana_private_key"

# On Windows PowerShell:
# $env:INFURA_API_KEY = "your_infura_api_key"
# $env:PRIVATE_KEY = "your_private_key"
# $env:SOLANA_PRIVATE_KEY = "your_solana_private_key"

# Update omega.toml dengan network settings (gunakan env vars)
omega config set evm.rpc_url "https://sepolia.infura.io/v3/$INFURA_API_KEY"
omega config set solana.rpc_url "https://api.devnet.solana.com"
```

> Security notes:
> - Store secrets only in environment variables or a local `.env` that is gitignored
> - Never hardcode secrets in source files or configs
> - Rotate keys regularly and use separate keys for dev/test/prod

### 2. Deploy ke Testnet
```bash
# Deploy ke EVM (Sepolia)
omega deploy --target evm --network sepolia --args "MyToken,MTK,18,1000000"

# Output:
# 🚀 Deploying to EVM (Sepolia)...
# ✅ Contract deployed successfully!
# 📍 Address: 0x742d35Cc6634C0532925a3b8D4C9db96590c6C87
# ⛽ Gas used: 847,392
# 💰 Cost: 0.0021 ETH
# 🔗 Transaction: 0x1234...5678

# Deploy ke Solana (Devnet)
omega deploy --target solana --network devnet --args "MyToken,MTK,18,1000000"

# Output:
# 🚀 Deploying to Solana (Devnet)...
# ✅ Program deployed successfully!
# 📍 Program ID: 7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgHRJ
# 💰 Cost: 0.002 SOL
# 🔗 Transaction: 3Kx7...9Yz2
```

### 3. Verifikasi Deployment
```bash
# Verifikasi contract di EVM
omega verify --target evm --address 0x742d35Cc6634C0532925a3b8D4C9db96590c6C87

# Verifikasi program di Solana
omega verify --target solana --program-id 7xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgHRJ
```

## 🔧 Development Tools

### 1. VS Code Extension
```bash
# Install OMEGA VS Code extension
code --install-extension omega-lang.mega-vscode

# Features:
# - Syntax highlighting
# - IntelliSense
# - Error detection
# - Integrated compiler
# - Debugger support
```

### 2. CLI Commands Reference dengan Fitur Modular
```bash
# Project management
omega init <name> [--template <template>]
omega config <command> [options]

# Building dengan arsitektur modular
omega build [--target <target>] [--optimization <level>]
omega build --emit-ir [--ir-format <format>]
omega build --passes <pass1,pass2,...>
omega build --optimization-stats
omega clean [--target <target>]

# IR operations
omega ir generate <input> [--output <dir>]
omega ir optimize <ir_file> [--passes <passes>]
omega ir visualize <ir_file> [--format <format>]
omega ir diff <ir1> <ir2>
omega ir stats <ir_file>

# Testing dengan parallel support
omega test [--suite <suite>] [--target <target>]
omega test --parallel [--jobs <n>]
omega test --benchmark [--iterations <n>]
omega test --coverage

# Deployment
omega deploy --target <target> --network <network>
omega verify --target <target> --address <address>

# Analysis dan debugging
omega analyze [--target <target>] [--output-format <format>]
omega profile <source> [--target <target>]
omega lint [files...] [--fix]

# Utilities
omega format [files...]
omega check [files...]
omega docs generate [--format <format>]
omega completion [shell]
```

### 3. Advanced Debugging dengan IR
```bash
# Enable debug mode dengan IR output
export OMEGA_DEBUG=1
export OMEGA_IR_DEBUG=1

# Run dengan detailed debug output
omega build --debug --emit-ir --optimization-stats

# Analyze generated IR
omega ir stats build/ir/SimpleToken.ir
# Output:
# IR Statistics for SimpleToken.ir:
#   Functions: 8
#   Basic Blocks: 24
#   Instructions: 156
#   Memory Usage: 2.4KB
#   Optimization Potential: 23%

# Profile compilation performance
omega profile contracts/SimpleToken.mega --target evm
# Output:
# Compilation Profile:
#   Lexing: 12ms
#   Parsing: 45ms
#   Semantic Analysis: 78ms
#   IR Generation: 134ms
#   Optimization: 89ms (3 passes)
#   Code Generation: 67ms
#   Total: 425ms

# Compare optimization levels
omega build --optimization none --emit-ir --output build/ir/unoptimized/
omega build --optimization aggressive --emit-ir --output build/ir/optimized/
omega ir diff build/ir/unoptimized/SimpleToken.ir build/ir/optimized/SimpleToken.ir
```

## 📚 Next Steps

Setelah menguasai dasar-dasar OMEGA, Anda dapat:

1. **Explore Advanced Features**
   - [Cross-chain communication](./cross-chain.md)
   - [DeFi protocol development](./defi-guide.md)
   - [NFT collections](./nft-guide.md)

2. **Learn Best Practices**
   - [Security patterns](./security-guide.md)
   - [Gas optimization](./optimization-guide.md)
   - [Testing strategies](./testing-guide.md)

3. **Join Community**
   - [Discord server](https://discord.gg/omega-lang)
   - [GitHub discussions](https://github.com/Rafael2022-prog/omega-lang/discussions)
   - [Twitter updates](https://twitter.com/omega_lang)

## 🆘 Troubleshooting

### Common Issues

**1. Compilation Errors**
```bash
# Error: "Unknown target 'evm'"
# Solution: Enable target first
omega config enable evm

# Error: "Missing dependencies"
# Solution: Install required tools
cargo install --force --locked
```

**2. Deployment Issues**
```bash
# Error: "Insufficient funds"
# Solution: Get testnet tokens
# Sepolia: https://sepoliafaucet.com
# Solana Devnet: solana airdrop 2

# Error: "RPC connection failed"
# Solution: Check network configuration
omega config show
```

**3. Performance Issues**
```bash
# Slow compilation
# Solution: Enable optimization
omega config set build.optimization true

# Large binary size
# Solution: Use release mode
omega build --release
```

## 📞 Getting Help

Jika Anda mengalami masalah atau memiliki pertanyaan:

1. **Check Documentation**: [docs.omega-lang.org](https://docs.omega-lang.org)
2. **Search Issues**: [GitHub Issues](https://github.com/Rafael2022-prog/omega-lang/issues)
3. **Ask Community**: [Discord #help channel](https://discord.gg/omega-lang)
4. **Report Bugs**: [Create new issue](https://github.com/Rafael2022-prog/omega-lang/issues/new)

---

Selamat coding dengan OMEGA! 🚀