# OMEGA Programming Language Specification

> [🏠 Home](Home.md) | [🚀 Getting Started](Getting-Started-Guide.md) | [🏗️ Compiler Architecture](Compiler-Architecture.md) | [🔧 API Reference](API-Reference.md) | [🤝 Contributing](Contributing.md)

## Overview

OMEGA adalah bahasa pemrograman yang dirancang khusus untuk pengembangan blockchain dengan prinsip **"Write Once, Deploy Everywhere"** - kompatibel dengan EVM dan non-EVM chains.

## Design Philosophy

### Core Principles
1. **Universal Compatibility**: Satu codebase untuk multiple blockchain platforms
2. **Type Safety**: Strong typing untuk mencegah runtime errors
3. **Resource Awareness**: Built-in gas/fee optimization
4. **Security First**: Memory safety dan overflow protection
5. **Developer Experience**: Familiar syntax dengan blockchain-specific features

## Language Syntax

### Basic Structure

Setiap smart contract OMEGA didefinisikan menggunakan keyword `blockchain`:

```omega
blockchain MyContract {
    // Contract content
}
```

### State Variables

State variables didefinisikan dalam blok `state`:

```omega
blockchain ERC20Token {
    state {
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        uint256 totalSupply;
        string name;
        string symbol;
        uint8 decimals;
    }
}
```

### Constructor

Constructor menggunakan keyword `constructor` atau `init`:

```omega
blockchain MyToken {
    constructor(string _name, string _symbol, uint256 _totalSupply) {
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        balances[msg.sender] = _totalSupply;
    }
}
```

### Functions

Functions didefinisikan dengan visibility modifiers:

```omega
// Public function
function transfer(address to, uint256 amount) public returns (bool) {
    require(balances[msg.sender] >= amount, "Insufficient balance");
    balances[msg.sender] -= amount;
    balances[to] += amount;
    emit Transfer(msg.sender, to, amount);
    return true;
}

// View function
function balanceOf(address account) public view returns (uint256) {
    return balances[account];
}

// Private function
function _mint(address to, uint256 amount) private {
    totalSupply += amount;
    balances[to] += amount;
}
```

### Events

Events untuk logging dan monitoring:

```omega
event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);

// Emit events
emit Transfer(msg.sender, to, amount);
```

## Data Types

### Primitive Types

- `uint8`, `uint16`, `uint32`, `uint64`, `uint128`, `uint256`
- `int8`, `int16`, `int32`, `int64`, `int128`, `int256`
- `bool`
- `address`
- `string`
- `bytes`, `bytes32`

### Complex Types

- `mapping(KeyType => ValueType)`
- `array[Type]`
- `struct`

### Example:

```omega
struct User {
    string name;
    uint256 balance;
    bool active;
}

state {
    mapping(address => User) users;
    array[address] userList;
}
```

## Control Flow

### Conditionals

```omega
if (condition) {
    // code
} else if (other_condition) {
    // code
} else {
    // code
}
```

### Loops

```omega
// For loop
for (uint256 i = 0; i < length; i++) {
    // code
}

// While loop
while (condition) {
    // code
}
```

## Built-in Functions

### Assertions and Requirements

```omega
require(condition, "Error message");
assert(condition);
revert("Error message");
```

### Global Variables

- `msg.sender` - Address of the caller
- `msg.value` - Amount of native token sent
- `block.timestamp` - Current block timestamp
- `block.number` - Current block number

## Cross-Chain Features

### Target-Specific Code

```omega
@target(evm)
function evmSpecificFunction() public {
    // EVM-specific implementation
}

@target(solana)
function solanaSpecificFunction() public {
    // Solana-specific implementation
}
```

### Cross-Chain Communication

```omega
@cross_chain(target = "solana")
function bridgeToSolana(bytes32 recipient, uint256 amount) public {
    // Cross-chain bridge logic
}
```

## Modifiers

### Access Control

```omega
modifier onlyOwner() {
    require(msg.sender == owner, "Not owner");
    _;
}

function withdraw() public onlyOwner {
    // Only owner can call this
}
```

### Gas Optimization

```omega
@optimize(gas)
function optimizedFunction() public {
    // Compiler will apply gas optimizations
}
```

## Error Handling

### Custom Errors

```omega
error InsufficientBalance(uint256 available, uint256 required);
error Unauthorized(address caller);

function transfer(address to, uint256 amount) public {
    if (balances[msg.sender] < amount) {
        revert InsufficientBalance(balances[msg.sender], amount);
    }
}
```

## Compilation Targets

OMEGA dapat dikompilasi ke berbagai target:

- **EVM**: Ethereum, Polygon, BSC, Avalanche, Arbitrum
- **Solana**: Native Solana programs
- **Cosmos**: CosmWasm contracts
- **Substrate**: Ink! contracts

### Target-Specific Compilation

```bash
omega build --target evm
omega build --target solana
omega build --target cosmos
```

## Best Practices

### Security

1. Always use `require()` for input validation
2. Check for integer overflow/underflow
3. Use proper access control modifiers
4. Validate external calls

### Performance

1. Use appropriate data types
2. Minimize storage operations
3. Use events for logging instead of storage
4. Optimize gas usage with compiler hints

### Code Organization

1. Group related functions together
2. Use clear and descriptive names
3. Add comprehensive comments
4. Follow consistent formatting

## Example: Complete Token Contract

```omega
blockchain SimpleToken {
    state {
        mapping(address => uint256) balances;
        uint256 totalSupply;
        string name;
        string symbol;
        address owner;
    }
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    constructor(string _name, string _symbol, uint256 _initialSupply) {
        name = _name;
        symbol = _symbol;
        totalSupply = _initialSupply;
        owner = msg.sender;
        balances[msg.sender] = _initialSupply;
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

## See Also

- [Getting Started Guide](Getting-Started-Guide.md) - Tutorial untuk memulai dengan OMEGA
- [Compiler Architecture](Compiler-Architecture.md) - Arsitektur compiler OMEGA
- [API Reference](API-Reference.md) - Referensi lengkap API
- [Contributing](Contributing.md) - Panduan kontribusi dan best practices
- [Home](Home.md) - Kembali ke halaman utama

---

> [🏠 Home](Home.md) | [🚀 Getting Started](Getting-Started-Guide.md) | [🏗️ Compiler Architecture](Compiler-Architecture.md) | [🔧 API Reference](API-Reference.md) | [🤝 Contributing](Contributing.md)