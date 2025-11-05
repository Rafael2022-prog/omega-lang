# OMEGA Best Practices Guide

> Catatan Penting (Windows Native-Only, Compile-Only)
> - Saat ini pipeline CI berjalan Windows-only dan CLI wrapper mendukung mode compile-only.
> - Gunakan skrip build native: `build_omega_native.ps1` untuk menghasilkan `omega.exe`.
> - Jalankan CLI: prioritaskan `./omega.exe`; jika belum tersedia gunakan `pwsh -NoProfile -ExecutionPolicy Bypass -File ./omega.ps1`.
> - Coverage: gunakan `scripts/generate_coverage.ps1` (native), bukan `cargo-tarpaulin`.
> - Perintah `omega build/test/deploy` pada dokumen ini bersifat forward-looking. Untuk verifikasi dasar gunakan `omega compile <file.mega>` pada Windows.
> - Ketergantungan seperti Node.js/npm, mdBook, valgrind, cargo-tarpaulin tidak diperlukan pada mode ini.

Panduan lengkap untuk mengembangkan smart contract yang aman, efisien, dan maintainable dengan bahasa OMEGA.

## 🏗️ Project Structure

### Recommended Directory Layout
```
my-omega-project/
├── omega.toml              # Project configuration
├── README.md               # Project documentation
├── .gitignore             # Git ignore rules
├── contracts/             # Smart contracts
│   ├── core/              # Core business logic
│   │   ├── Token.mega
│   │   └── Governance.mega
│   ├── interfaces/        # Contract interfaces
│   │   ├── IERC20.mega
│   │   └── IGovernance.mega
│   └── libraries/         # Reusable libraries
│       ├── SafeMath.mega
│       └── AccessControl.mega
├── tests/                 # Test suites
│   ├── unit/              # Unit tests
│   ├── integration/       # Integration tests
│   └── e2e/              # End-to-end tests
├── scripts/               # Deployment & utility scripts
│   ├── deploy.sh
│   └── verify.sh
├── docs/                  # Project documentation
│   ├── architecture.md
│   └── api-reference.md
└── build/                 # Generated artifacts (gitignored)
    ├── evm/
    └── solana/
```

### Configuration Best Practices
```toml
# omega.toml
[project]
name = "my-defi-protocol"
version = "1.0.0"
description = "A secure DeFi protocol built with OMEGA"
authors = ["Your Name <your.email@example.com>"]
license = "MIT"
repository = "https://github.com/yourorg/my-defi-protocol"

[targets]
evm = { enabled = true, network = "mainnet" }
solana = { enabled = true, network = "mainnet-beta" }

[build]
optimization = true
output_dir = "build"
source_dir = "contracts"
include_debug_info = false

[security]
enable_static_analysis = true
require_formal_verification = true
max_gas_limit = 8000000

[deployment]
evm = { 
    rpc_url = "${EVM_RPC_URL}",
    gas_price_strategy = "fast",
    verify_contracts = true
}
solana = { 
    rpc_url = "${SOLANA_RPC_URL}",
    commitment = "confirmed"
}
```

## 🔒 Security Best Practices

### 1. Input Validation
```omega
blockchain SecureContract {
    state {
        mapping(address => uint256) balances;
        address owner;
        bool paused;
    }
    
    // ✅ GOOD: Comprehensive input validation
    function transfer(address to, uint256 amount) public {
        // Validate addresses
        require(to != address(0), "Transfer to zero address");
        require(to != address(this), "Transfer to contract address");
        require(msg.sender != to, "Self transfer not allowed");
        
        // Validate amounts
        require(amount > 0, "Amount must be positive");
        require(amount <= balances[msg.sender], "Insufficient balance");
        require(amount <= type(uint256).max - balances[to], "Overflow protection");
        
        // Check contract state
        require(!paused, "Contract is paused");
        
        // Perform transfer
        balances[msg.sender] -= amount;
        balances[to] += amount;
        
        emit Transfer(msg.sender, to, amount);
    }
    
    // ❌ BAD: No input validation
    function bad_transfer(address to, uint256 amount) public {
        balances[msg.sender] -= amount;  // Can underflow
        balances[to] += amount;          // Can overflow
    }
}
```

### 2. Access Control Patterns
```omega
blockchain AccessControlled {
    state {
        mapping(address => bool) admins;
        mapping(bytes32 => mapping(address => bool)) roles;
        address owner;
        
        // Role constants
        bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");
        bytes32 constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    }
    
    constructor() {
        owner = msg.sender;
        admins[msg.sender] = true;
        roles[MINTER_ROLE][msg.sender] = true;
    }
    
    // Modifiers for access control
    modifier only_owner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    
    modifier only_admin() {
        require(admins[msg.sender], "Only admin");
        _;
    }
    
    modifier only_role(bytes32 role) {
        require(roles[role][msg.sender], "Missing required role");
        _;
    }
    
    // Role management functions
    function grant_role(bytes32 role, address account) public only_admin {
        require(account != address(0), "Invalid account");
        roles[role][account] = true;
        emit RoleGranted(role, account, msg.sender);
    }
    
    function revoke_role(bytes32 role, address account) public only_admin {
        roles[role][account] = false;
        emit RoleRevoked(role, account, msg.sender);
    }
    
    // Protected functions
    function mint(address to, uint256 amount) public only_role(MINTER_ROLE) {
        // Minting logic
    }
    
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
}
```

### 3. Reentrancy Protection
```omega
blockchain ReentrancyGuard {
    state {
        bool private locked;
        mapping(address => uint256) balances;
    }
    
    modifier non_reentrant() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }
    
    // ✅ GOOD: Protected against reentrancy
    function withdraw(uint256 amount) public non_reentrant {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        // Update state before external call
        balances[msg.sender] -= amount;
        
        // External call (potential reentrancy point)
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawal(msg.sender, amount);
    }
    
    // ❌ BAD: Vulnerable to reentrancy
    function bad_withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        // External call before state update
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        // State update after external call (vulnerable)
        balances[msg.sender] -= amount;
    }
    
    event Withdrawal(address indexed user, uint256 amount);
}
```

### 4. Safe Math Operations
```omega
blockchain SafeMathExample {
    state {
        mapping(address => uint256) balances;
        uint256 total_supply;
    }
    
    // ✅ GOOD: Safe arithmetic operations
    function safe_add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Addition overflow");
        return c;
    }
    
    function safe_sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Subtraction underflow");
        return a - b;
    }
    
    function safe_mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "Multiplication overflow");
        return c;
    }
    
    function safe_div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "Division by zero");
        return a / b;
    }
    
    // Use safe math in operations
    function mint(address to, uint256 amount) public {
        require(to != address(0), "Mint to zero address");
        
        total_supply = safe_add(total_supply, amount);
        balances[to] = safe_add(balances[to], amount);
        
        emit Transfer(address(0), to, amount);
    }
    
    event Transfer(address indexed from, address indexed to, uint256 value);
}
```

## ⚡ Performance Optimization

### 1. Gas Optimization for EVM
```omega
blockchain GasOptimized {
    state {
        // ✅ GOOD: Pack structs to minimize storage slots
        struct User {
            uint128 balance;      // 16 bytes
            uint64 last_update;   // 8 bytes
            uint32 tier;          // 4 bytes
            bool active;          // 1 byte
            // Total: 29 bytes (fits in 1 storage slot)
        }
        
        // ✅ GOOD: Use mappings for sparse data
        mapping(address => User) users;
        
        // ✅ GOOD: Use constants for fixed values
        uint256 constant MAX_SUPPLY = 1000000 * 10**18;
        bytes32 constant DOMAIN_SEPARATOR = keccak256("MyContract");
        
        // ❌ BAD: Separate variables use more storage
        // mapping(address => uint256) balances;
        // mapping(address => uint256) last_updates;
        // mapping(address => uint256) tiers;
        // mapping(address => bool) active_users;
    }
    
    // ✅ GOOD: Batch operations to reduce gas costs
    function batch_transfer(address[] memory recipients, uint256[] memory amounts) public {
        require(recipients.length == amounts.length, "Array length mismatch");
        require(recipients.length <= 100, "Too many recipients"); // Prevent gas limit issues
        
        uint256 total_amount = 0;
        
        // Calculate total first
        for (uint256 i = 0; i < amounts.length; i++) {
            total_amount += amounts[i];
        }
        
        require(users[msg.sender].balance >= total_amount, "Insufficient balance");
        
        // Update sender balance once
        users[msg.sender].balance -= uint128(total_amount);
        
        // Process transfers
        for (uint256 i = 0; i < recipients.length; i++) {
            users[recipients[i]].balance += uint128(amounts[i]);
            emit Transfer(msg.sender, recipients[i], amounts[i]);
        }
    }
    
    // ✅ GOOD: Use events for data that doesn't need on-chain storage
    function log_activity(string memory activity_type, bytes32 data) public {
        emit ActivityLogged(msg.sender, activity_type, data, block.timestamp);
        // No storage update needed
    }
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event ActivityLogged(address indexed user, string activity_type, bytes32 data, uint256 timestamp);
}
```

### 2. Memory Management
```omega
blockchain MemoryOptimized {
    state {
        mapping(address => uint256[]) user_transactions;
    }
    
    // ✅ GOOD: Use memory for temporary data
    function process_transactions(uint256[] memory transaction_ids) public view returns (uint256[] memory) {
        uint256[] memory results = new uint256[](transaction_ids.length);
        
        for (uint256 i = 0; i < transaction_ids.length; i++) {
            results[i] = calculate_fee(transaction_ids[i]);
        }
        
        return results;
    }
    
    // ✅ GOOD: Use storage references for existing data
    function update_user_transactions(address user, uint256 new_transaction) public {
        uint256[] storage transactions = user_transactions[user];
        transactions.push(new_transaction);
        
        // Clean up old transactions if array gets too large
        if (transactions.length > 1000) {
            // Remove oldest 100 transactions
            for (uint256 i = 0; i < transactions.length - 100; i++) {
                transactions[i] = transactions[i + 100];
            }
            // Resize array
            assembly {
                sstore(transactions.slot, sub(sload(transactions.slot), 100))
            }
        }
    }
    
    function calculate_fee(uint256 transaction_id) internal pure returns (uint256) {
        return transaction_id * 100; // Simplified calculation
    }
}
```

## 🧪 Testing Best Practices

### 1. Comprehensive Test Coverage
```json
// tests/comprehensive_tests.json
{
  "name": "Comprehensive Test Suite",
  "description": "Full coverage testing for smart contracts",
  "test_cases": [
    {
      "id": "unit_tests",
      "name": "Unit Tests",
      "description": "Test individual functions",
      "targets": ["evm", "solana"],
      "test_type": "Execution",
      "scenarios": [
        {
          "name": "successful_transfer",
          "setup": "Deploy contract with initial balances",
          "action": "Call transfer function with valid parameters",
          "expected": "Transfer succeeds, balances updated, event emitted"
        },
        {
          "name": "insufficient_balance",
          "setup": "Deploy contract with low balance",
          "action": "Call transfer with amount > balance",
          "expected": "Transaction reverts with 'Insufficient balance'"
        },
        {
          "name": "zero_address_transfer",
          "setup": "Deploy contract",
          "action": "Call transfer with to = address(0)",
          "expected": "Transaction reverts with 'Transfer to zero address'"
        }
      ]
    },
    {
      "id": "integration_tests",
      "name": "Integration Tests",
      "description": "Test contract interactions",
      "targets": ["evm", "solana"],
      "test_type": "CrossChain",
      "scenarios": [
        {
          "name": "multi_contract_interaction",
          "setup": "Deploy multiple contracts",
          "action": "Execute complex workflow",
          "expected": "All contracts interact correctly"
        }
      ]
    },
    {
      "id": "security_tests",
      "name": "Security Tests",
      "description": "Test security vulnerabilities",
      "targets": ["evm", "solana"],
      "test_type": "Security",
      "scenarios": [
        {
          "name": "reentrancy_attack",
          "setup": "Deploy vulnerable contract and attacker",
          "action": "Execute reentrancy attack",
          "expected": "Attack fails, contract remains secure"
        },
        {
          "name": "overflow_attack",
          "setup": "Deploy contract with arithmetic operations",
          "action": "Attempt integer overflow",
          "expected": "Operation reverts safely"
        }
      ]
    }
  ]
}
```

### 2. Test Organization
```bash
# Test directory structure
tests/
├── unit/
│   ├── token_tests.json
│   ├── governance_tests.json
│   └── access_control_tests.json
├── integration/
│   ├── defi_protocol_tests.json
│   └── cross_chain_tests.json
├── security/
│   ├── reentrancy_tests.json
│   ├── overflow_tests.json
│   └── access_control_tests.json
├── performance/
│   ├── gas_optimization_tests.json
│   └── load_tests.json
└── e2e/
    ├── user_journey_tests.json
    └── mainnet_fork_tests.json
```

### 3. Automated Testing Pipeline
```bash
#!/bin/bash
# scripts/test.sh

set -e

echo "🧪 Running OMEGA Test Suite..."
# Catatan (Windows Native-Only): Perintah `omega test` belum aktif di wrapper CLI.
# Gunakan kompilasi compile-only untuk verifikasi dasar, contoh:
#   .\\omega.exe compile tests\\unit\\lexer_tests.mega
# atau
#   pwsh -NoProfile -ExecutionPolicy Bypass -File .\\omega.ps1 compile tests\\unit\\lexer_tests.mega

# 1. Unit tests
echo "📋 Running unit tests..."
omega test --suite unit --parallel --coverage

# 2. Integration tests
echo "🔗 Running integration tests..."
omega test --suite integration --timeout 60000

# 3. Security tests
echo "🔒 Running security tests..."
omega test --suite security --strict

# 4. Performance tests
echo "⚡ Running performance tests..."
omega test --suite performance --benchmark

# 5. Cross-chain tests
echo "🌐 Running cross-chain tests..."
omega test --cross-chain --all-targets

# 6. Generate reports
echo "📊 Generating test reports..."
omega test report --format html --output reports/

echo "✅ All tests completed successfully!"
```

## 📚 Code Organization

### 1. Modular Design
```omega
// contracts/interfaces/IERC20.mega
interface IERC20 {
    function total_supply() external view returns (uint256);
    function balance_of(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer_from(address from, address to, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// contracts/libraries/SafeMath.mega
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
}

// contracts/core/Token.mega
import "./interfaces/IERC20.mega";
import "./libraries/SafeMath.mega";

blockchain Token implements IERC20 {
    using SafeMath for uint256;
    
    state {
        mapping(address => uint256) private balances;
        mapping(address => mapping(address => uint256)) private allowances;
        uint256 private total_supply_value;
        string private name_value;
        string private symbol_value;
        uint8 private decimals_value;
    }
    
    constructor(string memory name, string memory symbol, uint8 decimals, uint256 initial_supply) {
        name_value = name;
        symbol_value = symbol;
        decimals_value = decimals;
        total_supply_value = initial_supply;
        balances[msg.sender] = initial_supply;
        emit Transfer(address(0), msg.sender, initial_supply);
    }
    
    // Implement IERC20 interface
    function total_supply() public view override returns (uint256) {
        return total_supply_value;
    }
    
    function balance_of(address account) public view override returns (uint256) {
        return balances[account];
    }
    
    function transfer(address to, uint256 amount) public override returns (bool) {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(balances[msg.sender] >= amount, "ERC20: transfer amount exceeds balance");
        
        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[to] = balances[to].add(amount);
        
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    // ... other functions
}
```

### 2. Documentation Standards
```omega
/**
 * @title Advanced DeFi Protocol
 * @author Your Name
 * @notice This contract implements a comprehensive DeFi protocol with lending, borrowing, and yield farming
 * @dev Uses OpenZeppelin-style security patterns and gas optimizations
 */
blockchain DeFiProtocol {
    /**
     * @notice Represents a lending pool for a specific asset
     * @dev Packed struct to minimize storage costs
     */
    struct LendingPool {
        address asset;              // The underlying asset address
        uint128 total_deposits;     // Total amount deposited (128 bits)
        uint128 total_borrows;      // Total amount borrowed (128 bits)
        uint64 interest_rate;       // Current interest rate (64 bits)
        uint32 last_update;         // Last update timestamp (32 bits)
        bool active;                // Pool status (8 bits)
    }
    
    /**
     * @notice Deposits assets into the lending pool
     * @dev Emits Deposit event on success
     * @param pool_id The ID of the lending pool
     * @param amount The amount to deposit
     * @return success True if deposit was successful
     * @custom:security Checks for reentrancy and validates inputs
     * @custom:gas-optimization Uses packed structs and batch operations
     */
    function deposit(uint256 pool_id, uint256 amount) public returns (bool success) {
        require(pool_id < pools.length, "Invalid pool ID");
        require(amount > 0, "Amount must be positive");
        require(pools[pool_id].active, "Pool is inactive");
        
        // Implementation...
        
        emit Deposit(msg.sender, pool_id, amount);
        return true;
    }
    
    /**
     * @notice Emitted when a user deposits assets
     * @param user The address of the depositor
     * @param pool_id The ID of the pool
     * @param amount The amount deposited
     */
    event Deposit(address indexed user, uint256 indexed pool_id, uint256 amount);
}
```

## 🚀 Deployment Best Practices

### 1. Environment Management
```bash
# .env.example
# Copy to .env and fill in your values

# Network Configuration
MAINNET_RPC_URL=https://mainnet.infura.io/v3/YOUR_KEY
TESTNET_RPC_URL=https://sepolia.infura.io/v3/YOUR_KEY
SOLANA_MAINNET_RPC=https://api.mainnet-beta.solana.com
SOLANA_DEVNET_RPC=https://api.devnet.solana.com

# Private Keys (use hardware wallet in production)
DEPLOYER_PRIVATE_KEY=0x...
SOLANA_DEPLOYER_KEY=path/to/keypair.json

# Contract Verification
ETHERSCAN_API_KEY=YOUR_ETHERSCAN_KEY
POLYGONSCAN_API_KEY=YOUR_POLYGONSCAN_KEY

# Security
ENABLE_FORMAL_VERIFICATION=true
REQUIRE_MULTISIG=true
TIMELOCK_DELAY=86400  # 24 hours
```

### 2. Deployment Scripts
```bash
#!/bin/bash
# scripts/deploy.sh

set -e

# Load environment variables
source .env

# Configuration
NETWORK=${1:-testnet}
TARGET=${2:-evm}
DRY_RUN=${3:-false}

echo "🚀 Deploying to $TARGET ($NETWORK)..."

# Pre-deployment checks
echo "🔍 Running pre-deployment checks..."
omega check --all
omega test --suite security
omega analyze --security-audit

# Deploy contracts
if [ "$DRY_RUN" = "true" ]; then
    echo "🧪 Dry run mode - simulating deployment..."
    omega deploy --target $TARGET --network $NETWORK --dry-run
else
    echo "📦 Deploying contracts..."
    omega deploy --target $TARGET --network $NETWORK --verify
    
    # Post-deployment verification
    echo "✅ Verifying deployment..."
    omega verify --target $TARGET --network $NETWORK
    
    # Update documentation
    echo "📚 Updating documentation..."
    omega docs generate --include-addresses
fi

echo "🎉 Deployment completed successfully!"
```

### 3. Multi-signature Setup
```omega
blockchain MultiSigWallet {
    state {
        mapping(address => bool) public owners;
        mapping(uint256 => Transaction) public transactions;
        mapping(uint256 => mapping(address => bool)) public confirmations;
        
        struct Transaction {
            address destination;
            uint256 value;
            bytes data;
            bool executed;
            uint256 confirmation_count;
        }
        
        uint256 public required_confirmations;
        uint256 public transaction_count;
        address[] public owner_list;
    }
    
    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length >= 3, "Minimum 3 owners required");
        require(_required >= 2, "Minimum 2 confirmations required");
        require(_required <= _owners.length, "Required exceeds owner count");
        
        for (uint256 i = 0; i < _owners.length; i++) {
            require(_owners[i] != address(0), "Invalid owner address");
            require(!owners[_owners[i]], "Duplicate owner");
            
            owners[_owners[i]] = true;
            owner_list.push(_owners[i]);
        }
        
        required_confirmations = _required;
    }
    
    function submit_transaction(address destination, uint256 value, bytes memory data) public returns (uint256) {
        require(owners[msg.sender], "Only owners can submit");
        
        uint256 transaction_id = transaction_count;
        transactions[transaction_id] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false,
            confirmation_count: 0
        });
        
        transaction_count += 1;
        
        emit TransactionSubmitted(transaction_id, msg.sender, destination, value);
        return transaction_id;
    }
    
    function confirm_transaction(uint256 transaction_id) public {
        require(owners[msg.sender], "Only owners can confirm");
        require(transaction_id < transaction_count, "Invalid transaction");
        require(!confirmations[transaction_id][msg.sender], "Already confirmed");
        require(!transactions[transaction_id].executed, "Already executed");
        
        confirmations[transaction_id][msg.sender] = true;
        transactions[transaction_id].confirmation_count += 1;
        
        emit TransactionConfirmed(transaction_id, msg.sender);
        
        if (transactions[transaction_id].confirmation_count >= required_confirmations) {
            execute_transaction(transaction_id);
        }
    }
    
    function execute_transaction(uint256 transaction_id) internal {
        Transaction storage txn = transactions[transaction_id];
        require(!txn.executed, "Already executed");
        require(txn.confirmation_count >= required_confirmations, "Insufficient confirmations");
        
        txn.executed = true;
        
        (bool success, ) = txn.destination.call{value: txn.value}(txn.data);
        require(success, "Transaction execution failed");
        
        emit TransactionExecuted(transaction_id);
    }
    
    event TransactionSubmitted(uint256 indexed transaction_id, address indexed submitter, address indexed destination, uint256 value);
    event TransactionConfirmed(uint256 indexed transaction_id, address indexed owner);
    event TransactionExecuted(uint256 indexed transaction_id);
}
```

## 🔧 Maintenance & Monitoring

### 1. Contract Upgrades
```omega
blockchain UpgradeableContract {
    state {
        address public implementation;
        address public admin;
        mapping(bytes32 => uint256) public versions;
        
        // Upgrade timelock
        uint256 public upgrade_delay;
        mapping(bytes32 => uint256) public upgrade_timestamps;
    }
    
    modifier only_admin() {
        require(msg.sender == admin, "Only admin");
        _;
    }
    
    function propose_upgrade(address new_implementation, bytes32 version_hash) public only_admin {
        require(new_implementation != address(0), "Invalid implementation");
        require(new_implementation != implementation, "Same implementation");
        
        upgrade_timestamps[version_hash] = block.timestamp + upgrade_delay;
        
        emit UpgradeProposed(new_implementation, version_hash, upgrade_timestamps[version_hash]);
    }
    
    function execute_upgrade(address new_implementation, bytes32 version_hash) public only_admin {
        require(upgrade_timestamps[version_hash] != 0, "Upgrade not proposed");
        require(block.timestamp >= upgrade_timestamps[version_hash], "Timelock not expired");
        
        address old_implementation = implementation;
        implementation = new_implementation;
        versions[version_hash] = block.timestamp;
        
        // Clear upgrade timestamp
        delete upgrade_timestamps[version_hash];
        
        emit UpgradeExecuted(old_implementation, new_implementation, version_hash);
    }
    
    event UpgradeProposed(address indexed new_implementation, bytes32 indexed version_hash, uint256 execution_time);
    event UpgradeExecuted(address indexed old_implementation, address indexed new_implementation, bytes32 indexed version_hash);
}
```

### 2. Monitoring & Analytics
```omega
blockchain MonitoredContract {
    state {
        // Metrics tracking
        mapping(bytes4 => uint256) function_call_counts;
        mapping(address => uint256) user_activity_counts;
        mapping(uint256 => uint256) daily_transaction_volumes;
        
        // Health monitoring
        uint256 public last_health_check;
        bool public emergency_pause;
        mapping(address => bool) public monitors;
    }
    
    modifier track_usage(bytes4 function_selector) {
        function_call_counts[function_selector] += 1;
        user_activity_counts[msg.sender] += 1;
        
        uint256 today = block.timestamp / 86400; // Daily buckets
        daily_transaction_volumes[today] += 1;
        
        _;
        
        emit FunctionCalled(function_selector, msg.sender, block.timestamp);
    }
    
    modifier health_check() {
        require(!emergency_pause, "Contract paused for maintenance");
        
        // Update health check timestamp
        last_health_check = block.timestamp;
        
        _;
        
        // Post-execution health checks
        if (address(this).balance > 1000 ether) {
            emit HighBalanceAlert(address(this).balance);
        }
    }
    
    function emergency_pause_contract() public {
        require(monitors[msg.sender], "Only monitors can pause");
        emergency_pause = true;
        emit EmergencyPause(msg.sender, block.timestamp);
    }
    
    function get_metrics() public view returns (uint256, uint256, uint256) {
        uint256 today = block.timestamp / 86400;
        return (
            function_call_counts[msg.sig],
            user_activity_counts[msg.sender],
            daily_transaction_volumes[today]
        );
    }
    
    event FunctionCalled(bytes4 indexed selector, address indexed caller, uint256 timestamp);
    event HighBalanceAlert(uint256 balance);
    event EmergencyPause(address indexed monitor, uint256 timestamp);
}
```

## 📊 Performance Monitoring

### 1. Gas Usage Tracking
```bash
#!/bin/bash
# scripts/gas-analysis.sh

echo "⛽ Analyzing gas usage..."
# Catatan (Windows Native-Only): `omega build --gas-report` dan `omega test --benchmark --gas-analysis`
# bersifat forward-looking pada wrapper CLI saat ini.
# Untuk saat ini, gunakan kompilasi file tunggal untuk verifikasi dasar dan analisis manual bila diperlukan:
#   .\\omega.exe compile contracts\\core\\Token.mega
# atau
#   pwsh -NoProfile -ExecutionPolicy Bypass -File .\\omega.ps1 compile contracts\\core\\Token.mega

# Compile with gas reporting
omega build --gas-report

# Run gas benchmarks
omega test --benchmark --gas-analysis

# Generate gas usage report
omega analyze --gas-usage --output reports/gas-analysis.html

# Check for gas optimizations
omega optimize --suggest --target evm

echo "📊 Gas analysis completed. Check reports/gas-analysis.html"
```

### 2. Performance Benchmarks
```json
{
  "name": "Performance Benchmarks",
  "benchmarks": [
    {
      "name": "token_transfer",
      "description": "Benchmark token transfer operations",
      "iterations": 1000,
      "targets": ["evm", "solana"],
      "metrics": ["gas_usage", "execution_time", "throughput"],
      "expected_performance": {
        "evm": { "max_gas": 21000, "max_time_ms": 100 },
        "solana": { "max_time_ms": 50, "min_throughput": 1000 }
      }
    }
  ]
}
```

---

Dengan mengikuti best practices ini, Anda dapat mengembangkan smart contract OMEGA yang aman, efisien, dan maintainable untuk deployment di berbagai blockchain platform. 🚀