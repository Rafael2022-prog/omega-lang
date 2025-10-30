# API Reference

> [🏠 Home](Home.md) | [🚀 Getting Started](Getting-Started-Guide.md) | [📖 Language Spec](Language-Specification.md) | [🏗️ Compiler Architecture](Compiler-Architecture.md) | [🤝 Contributing](Contributing.md)

Dokumentasi lengkap untuk OMEGA API, built-in functions, standard library, dan compiler interfaces.

## 📚 Overview

OMEGA menyediakan comprehensive API yang mencakup:
- **Built-in Functions**: Fungsi-fungsi bawaan untuk operasi blockchain
- **Standard Library**: Koleksi library untuk operasi umum
- **Compiler API**: Interface untuk integrasi dengan tools dan IDEs
- **Runtime API**: Interface untuk interaksi dengan blockchain runtime

## 🔧 Built-in Functions

### Blockchain Primitives

#### Message Context

```omega
// Mendapatkan alamat pengirim transaksi
msg.sender -> address

// Mendapatkan nilai yang dikirim dengan transaksi (dalam wei)
msg.value -> uint256

// Mendapatkan data transaksi
msg.data -> bytes

// Mendapatkan gas yang tersisa
msg.gas -> uint256

// Mendapatkan signature hash dari transaksi
msg.sig -> bytes4
```

**Example:**
```omega
function transfer(address to, uint256 amount) public {
    require(msg.sender != address(0), "Invalid sender");
    require(msg.value >= amount, "Insufficient value");
    // Transfer logic
}
```

#### Block Information

```omega
// Mendapatkan hash dari block tertentu
block.blockhash(uint256 block_number) -> bytes32

// Mendapatkan alamat coinbase (miner)
block.coinbase -> address

// Mendapatkan difficulty block saat ini
block.difficulty -> uint256

// Mendapatkan gas limit block saat ini
block.gaslimit -> uint256

// Mendapatkan nomor block saat ini
block.number -> uint256

// Mendapatkan timestamp block saat ini
block.timestamp -> uint256
```

**Example:**
```omega
function get_block_info() public view returns (uint256, uint256) {
    return (block.number, block.timestamp);
}

function is_recent_block(uint256 target_block) public view returns (bool) {
    return block.number - target_block <= 256;
}
```

#### Transaction Information

```omega
// Mendapatkan gas price transaksi
tx.gasprice -> uint256

// Mendapatkan alamat asal transaksi
tx.origin -> address
```

### Cryptographic Functions

#### Hashing Functions

```omega
// Keccak-256 hash
hash.keccak256(bytes memory data) -> bytes32

// SHA-256 hash
hash.sha256(bytes memory data) -> bytes32

// RIPEMD-160 hash
hash.ripemd160(bytes memory data) -> bytes20

// Blake2b hash (untuk Substrate/Polkadot)
@target(substrate)
hash.blake2b(bytes memory data) -> bytes32
```

**Example:**
```omega
function verify_data(bytes memory data, bytes32 expected_hash) public pure returns (bool) {
    bytes32 actual_hash = hash.keccak256(data);
    return actual_hash == expected_hash;
}

function create_commitment(string memory secret) public pure returns (bytes32) {
    return hash.keccak256(abi.encodePacked(secret, msg.sender));
}
```

#### Digital Signatures

```omega
// Recover address dari signature
crypto.ecrecover(
    bytes32 hash,
    uint8 v,
    bytes32 r,
    bytes32 s
) -> address

// Verify signature (high-level interface)
crypto.verify_signature(
    bytes32 message_hash,
    bytes memory signature,
    address signer
) -> bool

// Solana-specific signature verification
@target(solana)
crypto.verify_ed25519(
    bytes memory message,
    bytes memory signature,
    bytes memory public_key
) -> bool
```

**Example:**
```omega
function verify_message(
    string memory message,
    bytes memory signature,
    address expected_signer
) public pure returns (bool) {
    bytes32 message_hash = hash.keccak256(abi.encodePacked(message));
    return crypto.verify_signature(message_hash, signature, expected_signer);
}
```

### Address Utilities

```omega
// Check if address is a contract
address.is_contract(address addr) -> bool

// Get balance of address
address.balance(address addr) -> uint256

// Get code size of address
address.code_size(address addr) -> uint256

// Get code hash of address
address.code_hash(address addr) -> bytes32
```

**Example:**
```omega
function is_eoa(address addr) public view returns (bool) {
    return !address.is_contract(addr);
}

function get_contract_info(address addr) public view returns (uint256, bytes32) {
    require(address.is_contract(addr), "Not a contract");
    return (address.code_size(addr), address.code_hash(addr));
}
```

### Error Handling

```omega
// Require condition with error message
require(bool condition, string memory message)

// Assert condition (for internal errors)
assert(bool condition)

// Revert with error message
revert(string memory message)

// Revert with custom error
revert CustomError(uint256 code, string memory details)
```

**Example:**
```omega
error InsufficientBalance(uint256 requested, uint256 available);
error Unauthorized(address caller);

function withdraw(uint256 amount) public {
    require(amount > 0, "Amount must be positive");
    
    if (balances[msg.sender] < amount) {
        revert InsufficientBalance(amount, balances[msg.sender]);
    }
    
    if (msg.sender != owner) {
        revert Unauthorized(msg.sender);
    }
    
    balances[msg.sender] -= amount;
    payable(msg.sender).transfer(amount);
}
```

## 📦 Standard Library

### Collections

#### Vector

```omega
import std.collections.Vector;

// Dynamic array implementation
struct Vector<T> {
    function new() -> Vector<T>
    function push(T item)
    function pop() -> T
    function get(uint256 index) -> T
    function set(uint256 index, T value)
    function length() -> uint256
    function is_empty() -> bool
    function clear()
    function contains(T item) -> bool
    function index_of(T item) -> int256  // -1 if not found
}
```

**Example:**
```omega
import std.collections.Vector;

blockchain TokenRegistry {
    state {
        Vector<address> registered_tokens;
        mapping(address => bool) is_registered;
    }
    
    function register_token(address token) public {
        require(!is_registered[token], "Token already registered");
        
        registered_tokens.push(token);
        is_registered[token] = true;
    }
    
    function get_token_count() public view returns (uint256) {
        return registered_tokens.length();
    }
    
    function get_token_at(uint256 index) public view returns (address) {
        require(index < registered_tokens.length(), "Index out of bounds");
        return registered_tokens.get(index);
    }
}
```

#### HashMap

```omega
import std.collections.HashMap;

// Hash map implementation
struct HashMap<K, V> {
    function new() -> HashMap<K, V>
    function insert(K key, V value)
    function get(K key) -> V
    function contains_key(K key) -> bool
    function remove(K key) -> bool
    function size() -> uint256
    function is_empty() -> bool
    function keys() -> Vector<K>
    function values() -> Vector<V>
}
```

#### Set

```omega
import std.collections.Set;

// Set implementation (unique values)
struct Set<T> {
    function new() -> Set<T>
    function add(T item) -> bool  // returns true if item was added
    function remove(T item) -> bool  // returns true if item was removed
    function contains(T item) -> bool
    function size() -> uint256
    function is_empty() -> bool
    function to_vector() -> Vector<T>
}
```

### Mathematics

#### SafeMath

```omega
import std.math.SafeMath;

library SafeMath {
    // Safe arithmetic operations
    function add(uint256 a, uint256 b) -> uint256
    function sub(uint256 a, uint256 b) -> uint256
    function mul(uint256 a, uint256 b) -> uint256
    function div(uint256 a, uint256 b) -> uint256
    function mod(uint256 a, uint256 b) -> uint256
    
    // Power and root operations
    function pow(uint256 base, uint256 exponent) -> uint256
    function sqrt(uint256 x) -> uint256
    
    // Min/Max operations
    function min(uint256 a, uint256 b) -> uint256
    function max(uint256 a, uint256 b) -> uint256
    
    // Percentage calculations
    function percentage(uint256 value, uint256 percent) -> uint256
}
```

**Example:**
```omega
import std.math.SafeMath;

blockchain LiquidityPool {
    using SafeMath for uint256;
    
    state {
        uint256 reserve_a;
        uint256 reserve_b;
    }
    
    function calculate_output(uint256 input_amount) public view returns (uint256) {
        uint256 numerator = input_amount.mul(reserve_b);
        uint256 denominator = reserve_a.add(input_amount);
        return numerator.div(denominator);
    }
    
    function calculate_fee(uint256 amount, uint256 fee_rate) public pure returns (uint256) {
        return amount.percentage(fee_rate);
    }
}
```

#### FixedPoint

```omega
import std.math.FixedPoint;

// Fixed-point arithmetic for precise calculations
library FixedPoint {
    struct Fixed {
        uint256 value;
        uint8 decimals;
    }
    
    function from_uint(uint256 value, uint8 decimals) -> Fixed
    function to_uint(Fixed fixed) -> uint256
    function add(Fixed a, Fixed b) -> Fixed
    function sub(Fixed a, Fixed b) -> Fixed
    function mul(Fixed a, Fixed b) -> Fixed
    function div(Fixed a, Fixed b) -> Fixed
}
```

### Security

#### Access Control

```omega
import std.access.{Ownable, AccessControl};

// Ownable pattern
contract Ownable {
    address private owner;
    
    modifier only_owner {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    function transfer_ownership(address new_owner) public only_owner
    function renounce_ownership() public only_owner
}

// Role-based access control
contract AccessControl {
    mapping(bytes32 => mapping(address => bool)) private roles;
    
    modifier has_role(bytes32 role) {
        require(roles[role][msg.sender], "Access denied");
        _;
    }
    
    function grant_role(bytes32 role, address account) public
    function revoke_role(bytes32 role, address account) public
    function has_role(bytes32 role, address account) -> bool
}
```

#### ReentrancyGuard

```omega
import std.security.ReentrancyGuard;

contract ReentrancyGuard {
    bool private locked;
    
    modifier non_reentrant {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }
}
```

**Example:**
```omega
import std.security.ReentrancyGuard;
import std.access.Ownable;

blockchain Vault extends Ownable, ReentrancyGuard {
    mapping(address => uint256) balances;
    
    function withdraw(uint256 amount) public non_reentrant {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }
}
```

### Token Standards

#### ERC20

```omega
import std.token.ERC20;

interface IERC20 {
    function total_supply() -> uint256
    function balance_of(address account) -> uint256
    function transfer(address to, uint256 amount) -> bool
    function allowance(address owner, address spender) -> uint256
    function approve(address spender, uint256 amount) -> bool
    function transfer_from(address from, address to, uint256 amount) -> bool
    
    event Transfer(address indexed from, address indexed to, uint256 value)
    event Approval(address indexed owner, address indexed spender, uint256 value)
}

contract ERC20 implements IERC20 {
    // Standard ERC20 implementation
}
```

#### ERC721

```omega
import std.token.ERC721;

interface IERC721 {
    function balance_of(address owner) -> uint256
    function owner_of(uint256 token_id) -> address
    function safe_transfer_from(address from, address to, uint256 token_id)
    function transfer_from(address from, address to, uint256 token_id)
    function approve(address to, uint256 token_id)
    function set_approval_for_all(address operator, bool approved)
    function get_approved(uint256 token_id) -> address
    function is_approved_for_all(address owner, address operator) -> bool
}
```

### Cross-Chain

#### Bridge Utilities

```omega
import std.bridge.{CrossChainMessage, BridgeValidator};

struct CrossChainMessage {
    uint32 source_chain;
    uint32 dest_chain;
    address sender;
    bytes recipient;
    bytes payload;
    uint256 nonce;
}

library BridgeValidator {
    function validate_message(CrossChainMessage message) -> bool
    function verify_signatures(bytes32 message_hash, bytes[] signatures) -> bool
    function encode_message(CrossChainMessage message) -> bytes
    function decode_message(bytes data) -> CrossChainMessage
}
```

**Example:**
```omega
import std.bridge.{CrossChainMessage, BridgeValidator};

blockchain CrossChainBridge {
    mapping(bytes32 => bool) processed_messages;
    
    function process_message(
        CrossChainMessage memory message,
        bytes[] memory signatures
    ) public {
        bytes32 message_hash = hash.keccak256(BridgeValidator.encode_message(message));
        require(!processed_messages[message_hash], "Message already processed");
        require(BridgeValidator.verify_signatures(message_hash, signatures), "Invalid signatures");
        
        processed_messages[message_hash] = true;
        
        // Process the cross-chain message
        _execute_message(message);
    }
}
```

## 🖥️ Compiler API

### Compilation Interface

```omega
// OMEGA API for compiler integration
blockchain OmegaCompiler {
    state {
        CompilerConfig config;
        Diagnostic[] diagnostics;
    }
    
    constructor(CompilerConfig _config) {
        config = _config;
    }
    
    function compile(SourceFile[] sources) public returns (CompilationResult) {
        // Implementation
    }
    
    function compile_to_target(SourceFile[] sources, Target target) public returns (TargetOutput) {
        // Implementation
    }
    
    function get_diagnostics() public view returns (Diagnostic[]) {
        return diagnostics;
    }
}

blockchain CompilerConfig {
    state {
        OptimizationLevel optimization_level;
        mapping(Target => TargetConfig) target_configs;
        string[] include_paths;
        bool debug_info;
    }
}

pub struct CompilationResult {
    pub targets: HashMap<Target, TargetOutput>,
    pub diagnostics: Vec<Diagnostic>,
    pub metadata: CompilationMetadata,
}
```

### Language Server Protocol

```typescript
// TypeScript definitions for LSP integration
interface OmegaLanguageServer {
    // Document management
    didOpen(params: DidOpenTextDocumentParams): void;
    didChange(params: DidChangeTextDocumentParams): void;
    didClose(params: DidCloseTextDocumentParams): void;
    
    // Language features
    completion(params: CompletionParams): CompletionList;
    hover(params: HoverParams): Hover | null;
    signatureHelp(params: SignatureHelpParams): SignatureHelp | null;
    definition(params: DefinitionParams): Location[];
    references(params: ReferenceParams): Location[];
    documentSymbol(params: DocumentSymbolParams): DocumentSymbol[];
    
    // Diagnostics
    publishDiagnostics(params: PublishDiagnosticsParams): void;
    
    // Code actions
    codeAction(params: CodeActionParams): CodeAction[];
    
    // Formatting
    formatting(params: DocumentFormattingParams): TextEdit[];
    rangeFormatting(params: DocumentRangeFormattingParams): TextEdit[];
}
```

## 🌐 Runtime API

### EVM Runtime

```solidity
// Generated Solidity interface
interface IOmegaRuntime {
    function getVersion() external pure returns (string memory);
    function getChainId() external view returns (uint256);
    function crossChainCall(uint32 destChain, bytes calldata payload) external;
    function bridgeTokens(address token, uint256 amount, uint32 destChain, bytes calldata recipient) external;
}
```

### Solana Runtime

```omega
// Generated OMEGA interface for Solana
blockchain OmegaRuntime {
    function get_version() public pure returns (string) {
    fn get_cluster() -> Cluster;
    fn cross_chain_call(dest_chain: u32, payload: Vec<u8>) -> Result<(), ProgramError>;
    fn bridge_tokens(mint: Pubkey, amount: u64, dest_chain: u32, recipient: Vec<u8>) -> Result<(), ProgramError>;
}
```

## 🧪 Testing API

### Test Framework

```omega
// OMEGA testing framework
test_suite MyContractTests {
    use contracts.MyContract;
    
    setup {
        let contract = MyContract.new("Test", "TST", 1000);
        let alice = address("0x1111111111111111111111111111111111111111");
        let bob = address("0x2222222222222222222222222222222222222222");
    }
    
    test "should transfer tokens" {
        let success = contract.transfer(alice, 100);
        assert_eq!(success, true);
        assert_eq!(contract.balance_of(alice), 100);
    }
    
    test "should fail with insufficient balance" {
        expect_revert(
            contract.transfer(alice, 2000),
            "Insufficient balance"
        );
    }
}
```

### Assertion Functions

```omega
// Test assertion functions
assert_eq!(actual, expected)                    // Equality assertion
assert_ne!(actual, expected)                    // Inequality assertion
assert!(condition)                              // Boolean assertion
assert_approx_eq!(actual, expected, tolerance)  // Approximate equality
expect_revert(call, expected_error)             // Expect transaction revert
expect_emit(event_signature)                    // Expect event emission
```

### Mock Functions

```omega
// Mocking utilities
mock.set_block_timestamp(timestamp)
mock.set_block_number(number)
mock.set_msg_sender(address)
mock.set_msg_value(value)
mock.set_balance(address, balance)
```

## 📊 Performance Monitoring

### Gas Analysis

```omega
// Gas analysis utilities
gas.start_measurement("function_name")
gas.end_measurement("function_name")
gas.get_usage("function_name") -> uint256
gas.optimize_for_target(target)
```

### Profiling

```omega
// Performance profiling
profile.start("operation_name")
profile.end("operation_name")
profile.get_duration("operation_name") -> uint256
profile.get_report() -> ProfilingReport
```

## 🔗 Integration Examples

### Web3 Integration

```javascript
// JavaScript/TypeScript integration
import { OmegaContract } from '@omega-lang/web3';

const contract = new OmegaContract(abi, address, provider);

// Call view functions
const balance = await contract.balance_of(userAddress);

// Send transactions
const tx = await contract.transfer(recipient, amount);
await tx.wait();

// Listen to events
contract.on('Transfer', (from, to, value) => {
    console.log(`Transfer: ${from} -> ${to}, amount: ${value}`);
});
```

### CLI Integration

```bash
# Command line interface
omega compile --target evm,solana contract.omega
omega deploy --network testnet --target evm
omega test --coverage
omega analyze --security
```

---

## 🔗 Related Documentation

- [Language Specification](Language-Specification.md) - OMEGA language syntax dan semantics
- [Getting Started Guide](Getting-Started-Guide.md) - Setup dan basic usage
- [Compiler Architecture](Compiler-Architecture.md) - Internal compiler design
- [Contributing](Contributing.md) - Development guidelines dan API contribution
- [Home](Home.md) - Kembali ke halaman utama

---

> [🏠 Home](Home.md) | [🚀 Getting Started](Getting-Started-Guide.md) | [📖 Language Spec](Language-Specification.md) | [🏗️ Compiler Architecture](Compiler-Architecture.md) | [🤝 Contributing](Contributing.md)

API Reference ini akan terus diperbarui seiring dengan perkembangan OMEGA. Untuk informasi terbaru, kunjungi [dokumentasi online](https://docs.omega-lang.org) atau [GitHub repository](https://github.com/Rafael2022-prog/omega-lang).