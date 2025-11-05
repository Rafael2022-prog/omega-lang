# Tutorial: Membuat Token Dasar dengan OMEGA

Tutorial lengkap untuk membuat, menguji, dan mendeploy token ERC20 menggunakan bahasa OMEGA yang kompatibel dengan EVM dan Solana.

⚠️ Catatan: Mode Windows native-only (compile-only) sedang aktif. Gunakan `build_omega_native.ps1` untuk build, `./omega.exe` atau `pwsh -File ./omega.ps1` untuk menjalankan, dan `scripts/generate_coverage.ps1` untuk coverage. Perintah `build/test/deploy` di bawah ini bersifat forward-looking dan mungkin belum tersedia di wrapper CLI; gunakan `omega compile` untuk verifikasi dasar.

## 🎯 Tujuan Tutorial

Setelah menyelesaikan tutorial ini, Anda akan dapat:
- Membuat smart contract token menggunakan OMEGA
- Mengkompilasi untuk multiple blockchain (EVM & Solana)
- Menulis dan menjalankan test suite
- Mendeploy token ke testnet
- Memverifikasi deployment

## 📋 Prerequisites

- OMEGA compiler sudah terinstall
- Node.js dan npm/yarn (opsional; tidak diperlukan untuk mode Windows native-only)
- Rust dan Cargo (untuk Solana)
- Wallet dengan testnet tokens
- Text editor (VS Code recommended)

## 🚀 Langkah 1: Setup Proyek

### Inisialisasi Proyek Baru

```bash
# Buat proyek baru dengan template basic
omega init my-token-project --template basic --targets evm,solana

# Masuk ke direktori proyek
cd my-token-project

# Lihat struktur proyek
ls -la
```

Struktur proyek yang dihasilkan:
```
my-token-project/
├── omega.toml              # Konfigurasi proyek
├── contracts/              # Smart contracts
│   └── Token.mega         # Template token
├── tests/                  # Test suites
│   └── token_tests.json    # Test configuration
├── scripts/                # Deployment scripts
├── .gitignore
└── README.md
```

### Konfigurasi Proyek

Edit file `omega.toml`:

```toml
[project]
name = "my-token-project"
version = "1.0.0"
description = "A basic token built with OMEGA"
authors = ["Your Name <your.email@example.com>"]
license = "MIT"

[targets]
evm = { enabled = true, network = "sepolia" }
solana = { enabled = true, network = "devnet" }

[build]
optimization = true
output_dir = "build"
source_dir = "contracts"

[evm]
solidity_version = "0.8.19"
optimizer_runs = 200

[solana]
anchor_version = "0.28.0"

[deployment]
evm = { 
    rpc_url = "${SEPOLIA_RPC_URL}",
    gas_price_strategy = "fast"
}
solana = { 
    rpc_url = "https://api.devnet.solana.com",
    commitment = "confirmed"
}
```

## 🔧 Langkah 2: Implementasi Token

### Membuat Smart Contract Token

Buat file `contracts/MyToken.mega`:

```omega
// MyToken.mega - Token ERC20 dasar dengan fitur tambahan
blockchain MyToken {
    // Import standard libraries
    import "std/tokens/ERC20.mega";
    import "std/security/AccessControl.mega";
    import "std/security/Pausable.mega";
    
    // Inherit dari kontrak standar
    extends ERC20, AccessControl, Pausable {
        
        // State variables
        state {
            // Token metadata
            string private name_value;
            string private symbol_value;
            uint8 private decimals_value;
            
            // Supply management
            uint256 private total_supply_value;
            uint256 private max_supply;
            
            // Role definitions
            bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");
            bytes32 constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
            
            // Balances and allowances
            mapping(address => uint256) private balances;
            mapping(address => mapping(address => uint256)) private allowances;
            
            // Additional features
            bool public transfer_fee_enabled;
            uint256 public transfer_fee_rate; // Basis points (100 = 1%)
            address public fee_collector;
        }
        
        // Constructor
        constructor(
            string memory name,
            string memory symbol,
            uint8 decimals,
            uint256 initial_supply,
            uint256 max_supply_limit,
            address initial_owner
        ) {
            // Set token metadata
            name_value = name;
            symbol_value = symbol;
            decimals_value = decimals;
            max_supply = max_supply_limit;
            
            // Setup roles
            _setup_role(DEFAULT_ADMIN_ROLE, initial_owner);
            _setup_role(MINTER_ROLE, initial_owner);
            _setup_role(PAUSER_ROLE, initial_owner);
            
            // Mint initial supply
            if (initial_supply > 0) {
                _mint(initial_owner, initial_supply);
            }
            
            // Set fee collector
            fee_collector = initial_owner;
            transfer_fee_enabled = false;
            transfer_fee_rate = 0;
        }
        
        // ERC20 Implementation
        function name() public view returns (string memory) {
            return name_value;
        }
        
        function symbol() public view returns (string memory) {
            return symbol_value;
        }
        
        function decimals() public view returns (uint8) {
            return decimals_value;
        }
        
        function total_supply() public view override returns (uint256) {
            return total_supply_value;
        }
        
        function balance_of(address account) public view override returns (uint256) {
            return balances[account];
        }
        
        function allowance(address owner, address spender) public view override returns (uint256) {
            return allowances[owner][spender];
        }
        
        // Transfer functions
        function transfer(address to, uint256 amount) public override when_not_paused returns (bool) {
            address owner = msg.sender;
            _transfer_with_fee(owner, to, amount);
            return true;
        }
        
        function transfer_from(address from, address to, uint256 amount) public override when_not_paused returns (bool) {
            address spender = msg.sender;
            _spend_allowance(from, spender, amount);
            _transfer_with_fee(from, to, amount);
            return true;
        }
        
        function approve(address spender, uint256 amount) public override when_not_paused returns (bool) {
            address owner = msg.sender;
            _approve(owner, spender, amount);
            return true;
        }
        
        // Minting and burning
        function mint(address to, uint256 amount) public only_role(MINTER_ROLE) when_not_paused {
            require(total_supply_value + amount <= max_supply, "MyToken: exceeds max supply");
            _mint(to, amount);
        }
        
        function burn(uint256 amount) public when_not_paused {
            _burn(msg.sender, amount);
        }
        
        function burn_from(address account, uint256 amount) public when_not_paused {
            _spend_allowance(account, msg.sender, amount);
            _burn(account, amount);
        }
        
        // Pause functionality
        function pause() public only_role(PAUSER_ROLE) {
            _pause();
        }
        
        function unpause() public only_role(PAUSER_ROLE) {
            _unpause();
        }
        
        // Fee management
        function set_transfer_fee(bool enabled, uint256 fee_rate) public only_role(DEFAULT_ADMIN_ROLE) {
            require(fee_rate <= 1000, "MyToken: fee rate too high"); // Max 10%
            transfer_fee_enabled = enabled;
            transfer_fee_rate = fee_rate;
            emit TransferFeeUpdated(enabled, fee_rate);
        }
        
        function set_fee_collector(address new_collector) public only_role(DEFAULT_ADMIN_ROLE) {
            require(new_collector != address(0), "MyToken: zero address");
            fee_collector = new_collector;
            emit FeeCollectorUpdated(new_collector);
        }
        
        // Internal functions
        function _transfer_with_fee(address from, address to, uint256 amount) internal {
            require(from != address(0), "MyToken: transfer from zero address");
            require(to != address(0), "MyToken: transfer to zero address");
            
            uint256 from_balance = balances[from];
            require(from_balance >= amount, "MyToken: transfer amount exceeds balance");
            
            uint256 transfer_amount = amount;
            uint256 fee_amount = 0;
            
            // Calculate fee if enabled
            if (transfer_fee_enabled && from != fee_collector && to != fee_collector) {
                fee_amount = (amount * transfer_fee_rate) / 10000;
                transfer_amount = amount - fee_amount;
            }
            
            // Update balances
            balances[from] = from_balance - amount;
            balances[to] += transfer_amount;
            
            // Transfer fee to collector
            if (fee_amount > 0) {
                balances[fee_collector] += fee_amount;
                emit Transfer(from, fee_collector, fee_amount);
            }
            
            emit Transfer(from, to, transfer_amount);
        }
        
        function _mint(address to, uint256 amount) internal {
            require(to != address(0), "MyToken: mint to zero address");
            
            total_supply_value += amount;
            balances[to] += amount;
            
            emit Transfer(address(0), to, amount);
        }
        
        function _burn(address from, uint256 amount) internal {
            require(from != address(0), "MyToken: burn from zero address");
            
            uint256 account_balance = balances[from];
            require(account_balance >= amount, "MyToken: burn amount exceeds balance");
            
            balances[from] = account_balance - amount;
            total_supply_value -= amount;
            
            emit Transfer(from, address(0), amount);
        }
        
        function _approve(address owner, address spender, uint256 amount) internal {
            require(owner != address(0), "MyToken: approve from zero address");
            require(spender != address(0), "MyToken: approve to zero address");
            
            allowances[owner][spender] = amount;
            emit Approval(owner, spender, amount);
        }
        
        function _spend_allowance(address owner, address spender, uint256 amount) internal {
            uint256 current_allowance = allowance(owner, spender);
            if (current_allowance != type(uint256).max) {
                require(current_allowance >= amount, "MyToken: insufficient allowance");
                _approve(owner, spender, current_allowance - amount);
            }
        }
        
        // Events
        event TransferFeeUpdated(bool enabled, uint256 fee_rate);
        event FeeCollectorUpdated(address indexed new_collector);
    }
}
```

## 🧪 Langkah 3: Menulis Tests

### Konfigurasi Test Suite

Buat file `tests/my_token_tests.json`:

```json
{
  "name": "MyToken Test Suite",
  "description": "Comprehensive tests for MyToken contract",
  "setup": {
    "commands": [
      "omega build --release"
    ],
    "environment": {
      "NODE_ENV": "test",
      "NETWORK": "testnet"
    },
    "accounts": [
      {
        "name": "deployer",
        "private_key": "${DEPLOYER_PRIVATE_KEY}",
        "balance": "100 ETH"
      },
      {
        "name": "user1",
        "private_key": "${USER1_PRIVATE_KEY}",
        "balance": "10 ETH"
      },
      {
        "name": "user2",
        "private_key": "${USER2_PRIVATE_KEY}",
        "balance": "10 ETH"
      }
    ]
  },
  "test_cases": [
    {
      "id": "deployment_test",
      "name": "Contract Deployment Test",
      "description": "Test successful contract deployment",
      "targets": ["evm", "solana"],
      "test_type": "Deployment",
      "timeout": 30000,
      "source_code": "contracts/MyToken.mega",
      "constructor_args": [
        "MyToken",
        "MTK",
        18,
        "1000000000000000000000000",
        "10000000000000000000000000",
        "${deployer.address}"
      ],
      "expected_output": {
        "success": true,
        "gas_usage": {
          "max": 2000000
        }
      }
    },
    {
      "id": "basic_functionality",
      "name": "Basic Token Functionality",
      "description": "Test basic ERC20 functions",
      "targets": ["evm", "solana"],
      "test_type": "Execution",
      "timeout": 60000,
      "dependencies": ["deployment_test"],
      "test_steps": [
        {
          "action": "call",
          "function": "name",
          "expected": "MyToken"
        },
        {
          "action": "call",
          "function": "symbol",
          "expected": "MTK"
        },
        {
          "action": "call",
          "function": "decimals",
          "expected": 18
        },
        {
          "action": "call",
          "function": "total_supply",
          "expected": "1000000000000000000000000"
        },
        {
          "action": "call",
          "function": "balance_of",
          "args": ["${deployer.address}"],
          "expected": "1000000000000000000000000"
        }
      ]
    },
    {
      "id": "transfer_test",
      "name": "Transfer Functionality",
      "description": "Test token transfers",
      "targets": ["evm", "solana"],
      "test_type": "Execution",
      "timeout": 60000,
      "dependencies": ["deployment_test"],
      "test_steps": [
        {
          "action": "transaction",
          "function": "transfer",
          "from": "deployer",
          "args": ["${user1.address}", "1000000000000000000000"],
          "expected": {
            "success": true,
            "events": [
              {
                "name": "Transfer",
                "args": {
                  "from": "${deployer.address}",
                  "to": "${user1.address}",
                  "value": "1000000000000000000000"
                }
              }
            ]
          }
        },
        {
          "action": "call",
          "function": "balance_of",
          "args": ["${user1.address}"],
          "expected": "1000000000000000000000"
        }
      ]
    },
    {
      "id": "approval_test",
      "name": "Approval and TransferFrom",
      "description": "Test approval and transferFrom functionality",
      "targets": ["evm", "solana"],
      "test_type": "Execution",
      "timeout": 60000,
      "dependencies": ["transfer_test"],
      "test_steps": [
        {
          "action": "transaction",
          "function": "approve",
          "from": "user1",
          "args": ["${user2.address}", "500000000000000000000"],
          "expected": {
            "success": true,
            "events": [
              {
                "name": "Approval",
                "args": {
                  "owner": "${user1.address}",
                  "spender": "${user2.address}",
                  "value": "500000000000000000000"
                }
              }
            ]
          }
        },
        {
          "action": "transaction",
          "function": "transfer_from",
          "from": "user2",
          "args": ["${user1.address}", "${user2.address}", "200000000000000000000"],
          "expected": {
            "success": true
          }
        },
        {
          "action": "call",
          "function": "balance_of",
          "args": ["${user2.address}"],
          "expected": "200000000000000000000"
        }
      ]
    },
    {
      "id": "minting_test",
      "name": "Minting Functionality",
      "description": "Test token minting by authorized accounts",
      "targets": ["evm", "solana"],
      "test_type": "Execution",
      "timeout": 60000,
      "dependencies": ["deployment_test"],
      "test_steps": [
        {
          "action": "transaction",
          "function": "mint",
          "from": "deployer",
          "args": ["${user1.address}", "1000000000000000000000"],
          "expected": {
            "success": true,
            "events": [
              {
                "name": "Transfer",
                "args": {
                  "from": "0x0000000000000000000000000000000000000000",
                  "to": "${user1.address}",
                  "value": "1000000000000000000000"
                }
              }
            ]
          }
        }
      ]
    },
    {
      "id": "pause_test",
      "name": "Pause Functionality",
      "description": "Test contract pause and unpause",
      "targets": ["evm", "solana"],
      "test_type": "Execution",
      "timeout": 60000,
      "dependencies": ["deployment_test"],
      "test_steps": [
        {
          "action": "transaction",
          "function": "pause",
          "from": "deployer",
          "expected": {
            "success": true
          }
        },
        {
          "action": "transaction",
          "function": "transfer",
          "from": "deployer",
          "args": ["${user1.address}", "1000000000000000000000"],
          "expected": {
            "success": false,
            "error": "Pausable: paused"
          }
        },
        {
          "action": "transaction",
          "function": "unpause",
          "from": "deployer",
          "expected": {
            "success": true
          }
        }
      ]
    },
    {
      "id": "fee_test",
      "name": "Transfer Fee Functionality",
      "description": "Test transfer fee mechanism",
      "targets": ["evm", "solana"],
      "test_type": "Execution",
      "timeout": 60000,
      "dependencies": ["deployment_test"],
      "test_steps": [
        {
          "action": "transaction",
          "function": "set_transfer_fee",
          "from": "deployer",
          "args": [true, 100],
          "expected": {
            "success": true
          }
        },
        {
          "action": "transaction",
          "function": "transfer",
          "from": "deployer",
          "args": ["${user1.address}", "1000000000000000000000"],
          "expected": {
            "success": true
          }
        },
        {
          "action": "call",
          "function": "balance_of",
          "args": ["${user1.address}"],
          "expected": "990000000000000000000"
        }
      ]
    },
    {
      "id": "security_test",
      "name": "Security Tests",
      "description": "Test security features and access control",
      "targets": ["evm", "solana"],
      "test_type": "Security",
      "timeout": 60000,
      "dependencies": ["deployment_test"],
      "test_steps": [
        {
          "action": "transaction",
          "function": "mint",
          "from": "user1",
          "args": ["${user1.address}", "1000000000000000000000"],
          "expected": {
            "success": false,
            "error": "AccessControl: missing role"
          }
        },
        {
          "action": "transaction",
          "function": "pause",
          "from": "user1",
          "expected": {
            "success": false,
            "error": "AccessControl: missing role"
          }
        }
      ]
    }
  ],
  "teardown": {
    "commands": [
      "echo 'Tests completed'"
    ]
  }
}
```

## 🔨 Langkah 4: Build dan Test

### Kompilasi Kontrak

```bash
# Build untuk semua target yang enabled
omega build --release --verbose

# Build untuk target spesifik
omega build --target evm --gas-report
omega build --target solana --verbose

# Check hasil build
ls -la build/
```

Output yang dihasilkan:
```
build/
├── evm/
│   ├── MyToken.sol          # Generated Solidity
│   ├── MyToken.json         # ABI and bytecode
│   └── package.json         # NPM package config
├── solana/
│   ├── lib.rs              # Generated Rust
│   ├── Cargo.toml          # Cargo config
│   └── Anchor.toml         # Anchor config
└── reports/
    └── gas-usage.html      # Gas analysis report
```

### Menjalankan Tests

```bash
# Jalankan semua tests
omega test --suite my_token_tests --parallel --coverage

# Test untuk target spesifik
omega test --target evm --verbose
omega test --target solana --timeout 120

# Test dengan benchmark
omega test --benchmark --gas-analysis

# Watch mode untuk development
omega test --watch
```

### Analisis Hasil Test

```bash
# Generate test report
omega test report --format html --output reports/

# Lihat coverage report
open reports/coverage.html

# Analisis gas usage
omega analyze --gas-usage --output gas-report.json
```

## 🚀 Langkah 5: Deployment

### Setup Environment Variables

Buat file `.env`:

```bash
# EVM Networks
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_KEY
MAINNET_RPC_URL=https://mainnet.infura.io/v3/YOUR_INFURA_KEY

# Solana Networks
SOLANA_DEVNET_RPC=https://api.devnet.solana.com
SOLANA_MAINNET_RPC=https://api.mainnet-beta.solana.com

# Private Keys (use hardware wallet in production)
DEPLOYER_PRIVATE_KEY=0x...
USER1_PRIVATE_KEY=0x...
USER2_PRIVATE_KEY=0x...

# Solana Keypairs
SOLANA_DEPLOYER_KEY=path/to/deployer-keypair.json

# API Keys for verification
ETHERSCAN_API_KEY=YOUR_ETHERSCAN_KEY
```

### Deploy ke Testnet

```bash
# Deploy ke EVM testnet (Sepolia)
omega deploy --target evm --network sepolia --verify

# Deploy ke Solana devnet
omega deploy --target solana --network devnet

# Dry run untuk testing
omega deploy --target evm --network sepolia --dry-run

# Deploy dengan custom gas settings
omega deploy --target evm --network sepolia --gas-price 20 --gas-limit 3000000
```

### Verifikasi Deployment

```bash
# Verifikasi kontrak EVM
omega verify --target evm --network sepolia --address 0x...

# Check deployment status
omega status --target evm --network sepolia

# Interact dengan deployed contract
omega call --target evm --network sepolia --address 0x... --function "name()"
```

## 📊 Langkah 6: Monitoring dan Maintenance

### Setup Monitoring

Buat script monitoring `scripts/monitor.sh`:

```bash
#!/bin/bash

# Monitor contract health
echo "🔍 Monitoring MyToken contract..."

# Check EVM deployment
EVM_ADDRESS=$(omega status --target evm --network sepolia --json | jq -r '.address')
echo "EVM Contract: $EVM_ADDRESS"

# Check Solana deployment
SOLANA_ADDRESS=$(omega status --target solana --network devnet --json | jq -r '.program_id')
echo "Solana Program: $SOLANA_ADDRESS"

# Monitor key metrics
omega call --target evm --address $EVM_ADDRESS --function "total_supply()"
omega call --target evm --address $EVM_ADDRESS --function "paused()"

# Check recent transactions
omega events --target evm --address $EVM_ADDRESS --from-block latest --limit 10
```

### Update dan Upgrade

```bash
# Update contract code
# Edit contracts/MyToken.mega

# Rebuild
omega build --release

# Test changes
omega test --suite my_token_tests

# Deploy new version (if using upgradeable pattern)
omega deploy --target evm --network sepolia --upgrade --verify
```

## 🎉 Hasil Akhir

Setelah menyelesaikan tutorial ini, Anda telah berhasil:

1. ✅ Membuat token ERC20 lengkap dengan fitur advanced
2. ✅ Mengkompilasi untuk multiple blockchain (EVM & Solana)
3. ✅ Menulis test suite komprehensif
4. ✅ Mendeploy ke testnet
5. ✅ Memverifikasi dan memonitor deployment

### Fitur Token yang Diimplementasikan

- **ERC20 Standard**: Transfer, approve, allowance
- **Access Control**: Role-based permissions
- **Pausable**: Emergency pause functionality
- **Mintable**: Controlled token minting
- **Burnable**: Token burning capability
- **Transfer Fees**: Configurable transfer fees
- **Max Supply**: Supply cap protection

### Generated Code

**EVM (Solidity)**:
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract MyToken is ERC20, AccessControl, Pausable {
    // Generated Solidity implementation
}
```

**Solana (Rust/Anchor)**:
```rust
use anchor_lang::prelude::*;
use anchor_spl::token::{self, Token, TokenAccount, Mint};

#[program]
pub mod my_token {
    use super::*;
    
    // Generated Anchor implementation
}
```

## 🔗 Next Steps

1. **Advanced Features**: Implement staking, governance, atau DeFi integrations
2. **Frontend Integration**: Build web interface menggunakan Web3.js/Ethers.js
3. **Mainnet Deployment**: Deploy ke production networks
4. **Security Audit**: Conduct professional security audit
5. **Community**: Share project dan gather feedback

## 📚 Resources

- [OMEGA Documentation](../README.md)
- [Best Practices Guide](../best-practices.md)
- [API Reference](../api-reference.md)
- [Advanced Tutorials](./advanced-defi.md)

Selamat! Anda telah berhasil membuat token pertama dengan OMEGA! 🎊