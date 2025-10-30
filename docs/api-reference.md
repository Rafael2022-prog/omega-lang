# OMEGA API Reference

Dokumentasi lengkap untuk OMEGA Language API, CLI Commands, dan Standard Library.

## 📚 Table of Contents

- [Language Syntax](#-language-syntax)
- [CLI Commands](#-cli-commands)
- [Standard Library](#-standard-library)
- [Compiler API](#-compiler-api)
- [Configuration API](#-configuration-api)
- [Testing API](#-testing-api)

## 🔤 Language Syntax

### Basic Structure

#### Blockchain Declaration
```omega
blockchain ContractName {
    // Contract body
}
```

#### State Variables
```omega
blockchain MyContract {
    state {
        // State variable declarations
        uint256 public counter;
        mapping(address => uint256) balances;
        address private owner;
        bool public paused;
    }
}
```

#### Functions
```omega
// Public function
function function_name(param_type param_name) public returns (return_type) {
    // Function body
}

// Private function
function internal_function(uint256 value) private pure returns (bool) {
    return value > 0;
}

// View function (read-only)
function get_balance(address user) public view returns (uint256) {
    return balances[user];
}

// Payable function (can receive Ether)
function deposit() public payable {
    balances[msg.sender] += msg.value;
}
```

#### Modifiers
```omega
modifier only_owner() {
    require(msg.sender == owner, "Only owner allowed");
    _;
}

modifier not_paused() {
    require(!paused, "Contract is paused");
    _;
}

// Using modifiers
function withdraw(uint256 amount) public only_owner not_paused {
    // Function implementation
}
```

#### Events
```omega
// Event declaration
event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);

// Emitting events
function transfer(address to, uint256 amount) public {
    // Transfer logic
    emit Transfer(msg.sender, to, amount);
}
```

#### Constructor
```omega
blockchain Token {
    state {
        string name;
        string symbol;
        uint256 total_supply;
        address owner;
    }
    
    constructor(string memory _name, string memory _symbol, uint256 _supply) {
        name = _name;
        symbol = _symbol;
        total_supply = _supply;
        owner = msg.sender;
    }
}
```

### Data Types

#### Primitive Types
```omega
// Integers
uint8 small_number;      // 0 to 255
uint256 large_number;    // 0 to 2^256 - 1
int256 signed_number;    // -2^255 to 2^255 - 1

// Boolean
bool is_active;          // true or false

// Address
address user_address;    // Ethereum address (20 bytes)
address payable wallet;  // Payable address

// Bytes
bytes32 hash_value;      // Fixed-size byte array
bytes dynamic_data;      // Dynamic byte array

// String
string user_name;        // Dynamic string
```

#### Complex Types
```omega
// Arrays
uint256[] dynamic_array;           // Dynamic array
uint256[10] fixed_array;          // Fixed-size array
mapping(address => uint256) balances;  // Mapping

// Structs
struct User {
    string name;
    uint256 balance;
    bool active;
    address[] referrals;
}

// Enums
enum Status {
    Pending,
    Active,
    Suspended,
    Closed
}
```

### Control Structures

#### Conditionals
```omega
function check_balance(address user) public view returns (string memory) {
    if (balances[user] > 1000) {
        return "High balance";
    } else if (balances[user] > 100) {
        return "Medium balance";
    } else {
        return "Low balance";
    }
}
```

#### Loops
```omega
// For loop
function sum_array(uint256[] memory numbers) public pure returns (uint256) {
    uint256 total = 0;
    for (uint256 i = 0; i < numbers.length; i++) {
        total += numbers[i];
    }
    return total;
}

// While loop
function find_first_zero(uint256[] memory numbers) public pure returns (uint256) {
    uint256 i = 0;
    while (i < numbers.length && numbers[i] != 0) {
        i++;
    }
    return i;
}
```

#### Error Handling
```omega
// Require statements
function transfer(address to, uint256 amount) public {
    require(to != address(0), "Cannot transfer to zero address");
    require(balances[msg.sender] >= amount, "Insufficient balance");
    
    // Transfer logic
}

// Revert statements
function withdraw(uint256 amount) public {
    if (amount > balances[msg.sender]) {
        revert("Insufficient funds for withdrawal");
    }
    
    // Withdrawal logic
}

// Assert statements (for internal errors)
function internal_calculation(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 result = a + b;
    assert(result >= a); // Should never fail unless overflow
    return result;
}
```

## 🖥️ CLI Commands

### Project Management

#### `omega init`
Inisialisasi proyek OMEGA baru.

```bash
omega init [PROJECT_NAME] [OPTIONS]

# Options:
--template <TEMPLATE>    # Project template (basic, defi, nft, dao)
--targets <TARGETS>      # Target blockchains (evm, solana, cosmos)
--path <PATH>           # Project directory path
--force                 # Overwrite existing directory

# Examples:
omega init my-defi-project --template defi --targets evm,solana
omega init token-contract --template basic --path ./contracts
```

#### `omega config`
Mengelola konfigurasi proyek.

```bash
omega config <SUBCOMMAND> [OPTIONS]

# Subcommands:
show                    # Show current configuration
enable <TARGET>         # Enable target blockchain
disable <TARGET>        # Disable target blockchain
set <KEY> <VALUE>      # Set configuration value
get <KEY>              # Get configuration value

# Examples:
omega config show
omega config enable solana
omega config set evm.network mainnet
omega config get build.optimization
```

### Build & Compilation

#### `omega build`
Kompilasi smart contracts.

```bash
omega build [OPTIONS]

# Options:
--target <TARGET>       # Specific target (evm, solana, cosmos)
--release              # Release build with optimizations
--watch                # Watch for file changes
--parallel             # Enable parallel compilation
--output <DIR>         # Output directory
--verbose              # Verbose output
--gas-report           # Generate gas usage report

# Examples:
omega build --target evm --release
omega build --watch --verbose
omega build --gas-report --output ./build
```

#### `omega check`
Validasi kode tanpa kompilasi penuh.

```bash
omega check [OPTIONS]

# Options:
--target <TARGET>       # Check specific target
--all                  # Check all enabled targets
--syntax               # Syntax check only
--semantic             # Semantic analysis only
--security             # Security analysis

# Examples:
omega check --all
omega check --target solana --security
omega check --syntax --semantic
```

### Testing

#### `omega test`
Menjalankan test suite.

```bash
omega test [OPTIONS] [TEST_PATTERN]

# Options:
--suite <SUITE>         # Test suite name
--target <TARGET>       # Target blockchain
--parallel             # Run tests in parallel
--coverage             # Generate coverage report
--benchmark            # Run performance benchmarks
--timeout <SECONDS>    # Test timeout
--verbose              # Verbose output
--watch                # Watch mode
--cross-chain          # Cross-chain tests only

# Examples:
omega test --suite unit --parallel --coverage
omega test --target evm --benchmark
omega test token_tests --verbose
omega test --cross-chain --timeout 120
```

### Deployment

#### `omega deploy`
Deploy smart contracts.

```bash
omega deploy [OPTIONS]

# Options:
--target <TARGET>       # Target blockchain
--network <NETWORK>     # Network (mainnet, testnet, devnet)
--dry-run              # Simulate deployment
--verify               # Verify contracts after deployment
--gas-price <PRICE>    # Gas price (for EVM)
--gas-limit <LIMIT>    # Gas limit (for EVM)
--priority-fee <FEE>   # Priority fee (for Solana)

# Examples:
omega deploy --target evm --network testnet --verify
omega deploy --target solana --network devnet --dry-run
omega deploy --gas-price 20 --gas-limit 8000000
```

#### `omega verify`
Verifikasi smart contracts yang sudah di-deploy.

```bash
omega verify [OPTIONS]

# Options:
--target <TARGET>       # Target blockchain
--network <NETWORK>     # Network name
--address <ADDRESS>     # Contract address
--constructor-args <ARGS> # Constructor arguments

# Examples:
omega verify --target evm --network mainnet --address 0x123...
omega verify --target solana --network mainnet-beta
```

### Development Tools

#### `omega fmt`
Format kode OMEGA.

```bash
omega fmt [OPTIONS] [FILES]

# Options:
--check                # Check if files are formatted
--diff                 # Show formatting differences
--config <FILE>        # Custom formatting config

# Examples:
omega fmt contracts/
omega fmt --check --diff
omega fmt Token.mega Governance.mega
```

#### `omega docs`
Generate dokumentasi.

```bash
omega docs [OPTIONS]

# Options:
--output <DIR>         # Output directory
--format <FORMAT>      # Output format (html, markdown, json)
--include-private      # Include private functions
--include-addresses    # Include deployed addresses

# Examples:
omega docs --output ./docs --format html
omega docs --include-private --include-addresses
```

#### `omega analyze`
Analisis kode untuk optimasi dan keamanan.

```bash
omega analyze [OPTIONS]

# Options:
--security             # Security analysis
--gas-usage           # Gas usage analysis
--complexity          # Code complexity analysis
--dependencies        # Dependency analysis
--output <FILE>       # Output report file

# Examples:
omega analyze --security --output security-report.json
omega analyze --gas-usage --complexity
```

## 📖 Standard Library

### Math Library

#### SafeMath
```omega
import "std/math/SafeMath.mega";

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256);
    function sub(uint256 a, uint256 b) internal pure returns (uint256);
    function mul(uint256 a, uint256 b) internal pure returns (uint256);
    function div(uint256 a, uint256 b) internal pure returns (uint256);
    function mod(uint256 a, uint256 b) internal pure returns (uint256);
    function sqrt(uint256 a) internal pure returns (uint256);
    function pow(uint256 base, uint256 exponent) internal pure returns (uint256);
}

// Usage:
using SafeMath for uint256;

function calculate(uint256 a, uint256 b) public pure returns (uint256) {
    return a.add(b).mul(2);
}
```

#### FixedPoint
```omega
import "std/math/FixedPoint.mega";

library FixedPoint {
    struct UFixed256x18 {
        uint256 value;
    }
    
    function from_uint(uint256 value) internal pure returns (UFixed256x18 memory);
    function to_uint(UFixed256x18 memory fixed) internal pure returns (uint256);
    function add(UFixed256x18 memory a, UFixed256x18 memory b) internal pure returns (UFixed256x18 memory);
    function mul(UFixed256x18 memory a, UFixed256x18 memory b) internal pure returns (UFixed256x18 memory);
    function div(UFixed256x18 memory a, UFixed256x18 memory b) internal pure returns (UFixed256x18 memory);
}
```

### Security Library

#### AccessControl
```omega
import "std/security/AccessControl.mega";

contract AccessControl {
    mapping(bytes32 => mapping(address => bool)) private roles;
    
    bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
    
    function has_role(bytes32 role, address account) public view returns (bool);
    function grant_role(bytes32 role, address account) public;
    function revoke_role(bytes32 role, address account) public;
    function renounce_role(bytes32 role, address account) public;
    
    modifier only_role(bytes32 role) {
        require(has_role(role, msg.sender), "AccessControl: missing role");
        _;
    }
}
```

#### ReentrancyGuard
```omega
import "std/security/ReentrancyGuard.mega";

contract ReentrancyGuard {
    bool private locked;
    
    modifier non_reentrant() {
        require(!locked, "ReentrancyGuard: reentrant call");
        locked = true;
        _;
        locked = false;
    }
}
```

#### Pausable
```omega
import "std/security/Pausable.mega";

contract Pausable {
    bool private paused_state;
    
    function paused() public view returns (bool);
    function pause() public;
    function unpause() public;
    
    modifier when_not_paused() {
        require(!paused(), "Pausable: paused");
        _;
    }
    
    modifier when_paused() {
        require(paused(), "Pausable: not paused");
        _;
    }
}
```

### Token Standards

#### ERC20
```omega
import "std/tokens/ERC20.mega";

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

contract ERC20 implements IERC20 {
    // Implementation provided
}
```

#### ERC721
```omega
import "std/tokens/ERC721.mega";

interface IERC721 {
    function balance_of(address owner) external view returns (uint256);
    function owner_of(uint256 token_id) external view returns (address);
    function safe_transfer_from(address from, address to, uint256 token_id, bytes calldata data) external;
    function safe_transfer_from(address from, address to, uint256 token_id) external;
    function transfer_from(address from, address to, uint256 token_id) external;
    function approve(address to, uint256 token_id) external;
    function set_approval_for_all(address operator, bool approved) external;
    function get_approved(uint256 token_id) external view returns (address);
    function is_approved_for_all(address owner, address operator) external view returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 indexed token_id);
    event Approval(address indexed owner, address indexed approved, uint256 indexed token_id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
}
```

### Utility Libraries

#### Strings
```omega
import "std/utils/Strings.mega";

library Strings {
    function to_string(uint256 value) internal pure returns (string memory);
    function to_hex_string(uint256 value) internal pure returns (string memory);
    function to_hex_string(uint256 value, uint256 length) internal pure returns (string memory);
    function equal(string memory a, string memory b) internal pure returns (bool);
    function length(string memory str) internal pure returns (uint256);
    function concat(string memory a, string memory b) internal pure returns (string memory);
}
```

#### Arrays
```omega
import "std/utils/Arrays.mega";

library Arrays {
    function find_upper_bound(uint256[] storage array, uint256 element) internal view returns (uint256);
    function find_lower_bound(uint256[] storage array, uint256 element) internal view returns (uint256);
    function sort(uint256[] memory array) internal pure returns (uint256[] memory);
    function reverse(uint256[] memory array) internal pure returns (uint256[] memory);
    function contains(uint256[] memory array, uint256 element) internal pure returns (bool);
    function remove(uint256[] storage array, uint256 index) internal;
}
```

## 🔧 Compiler API

### Programmatic Compilation

```rust
use omega_compiler::{Compiler, Config, Target};

// Create compiler instance
let mut compiler = Compiler::new();

// Load configuration
let config = Config::load_from_file("omega.toml")?;

// Set targets
compiler.set_targets(vec![Target::EVM, Target::Solana]);

// Compile project
let result = compiler.compile_project(&config)?;

// Access compilation results
for output in result.outputs {
    println!("Generated: {}", output.file_path);
    println!("Target: {:?}", output.target);
    println!("Content: {}", output.content);
}

// Check for warnings
for warning in result.warnings {
    println!("Warning: {}", warning.message);
}
```

### Custom Code Generation

```rust
use omega_compiler::codegen::{CodeGenerator, GeneratorConfig};

// Create custom code generator
struct CustomGenerator {
    config: GeneratorConfig,
}

impl CodeGenerator for CustomGenerator {
    fn generate(&self, ir: &IntermediateRepresentation) -> Result<String, Error> {
        // Custom code generation logic
        Ok("Generated code".to_string())
    }
}

// Register custom generator
compiler.register_generator(Target::Custom("my-target"), Box::new(CustomGenerator::new()));
```

## ⚙️ Configuration API

### Configuration Structure

```toml
# omega.toml
[project]
name = "my-project"
version = "1.0.0"
description = "My OMEGA project"
authors = ["Developer <dev@example.com>"]
license = "MIT"

[targets]
evm = { enabled = true, network = "mainnet" }
solana = { enabled = true, network = "mainnet-beta" }
cosmos = { enabled = false }

[build]
optimization = true
output_dir = "build"
source_dir = "contracts"
parallel = true

[evm]
solidity_version = "0.8.19"
optimizer_runs = 200
gas_limit = 8000000

[solana]
anchor_version = "0.28.0"
rust_version = "1.70.0"

[deployment]
evm = { rpc_url = "${EVM_RPC_URL}", gas_price_strategy = "fast" }
solana = { rpc_url = "${SOLANA_RPC_URL}", commitment = "confirmed" }
```

### Programmatic Configuration

```rust
use omega_compiler::Config;

// Create configuration
let mut config = Config::new();

// Set project metadata
config.project.name = "my-project".to_string();
config.project.version = "1.0.0".to_string();

// Enable targets
config.targets.evm.enabled = true;
config.targets.solana.enabled = true;

// Set build options
config.build.optimization = true;
config.build.parallel = true;

// Save configuration
config.save_to_file("omega.toml")?;
```

## 🧪 Testing API

### Test Configuration

```json
{
  "name": "My Test Suite",
  "description": "Comprehensive tests for my project",
  "setup": {
    "commands": ["omega build --release"],
    "environment": {
      "NODE_ENV": "test",
      "NETWORK": "testnet"
    },
    "accounts": [
      {
        "name": "deployer",
        "private_key": "${DEPLOYER_KEY}",
        "balance": "100 ETH"
      }
    ]
  },
  "test_cases": [
    {
      "id": "basic_functionality",
      "name": "Basic Functionality Test",
      "targets": ["evm", "solana"],
      "test_type": "Execution",
      "timeout": 30000,
      "source_code": "contracts/Token.mega",
      "expected_output": {
        "success": true,
        "gas_usage": { "max": 100000 }
      }
    }
  ]
}
```

### Programmatic Testing

```rust
use omega_testing::{TestRunner, TestSuite, TestCase};

// Create test runner
let mut runner = TestRunner::new();

// Load test suite
let suite = TestSuite::load_from_file("tests/my_tests.json")?;

// Run tests
let results = runner.run_suite(&suite).await?;

// Process results
for result in results {
    match result.status {
        TestStatus::Passed => println!("✅ {}", result.test_case.name),
        TestStatus::Failed => println!("❌ {} - {}", result.test_case.name, result.error.unwrap()),
        TestStatus::Skipped => println!("⏭️ {}", result.test_case.name),
    }
}
```

---

Dokumentasi API ini memberikan referensi lengkap untuk menggunakan OMEGA dalam berbagai skenario development. Untuk informasi lebih lanjut, lihat [dokumentasi lengkap](./README.md) dan [panduan best practices](./best-practices.md). 🚀