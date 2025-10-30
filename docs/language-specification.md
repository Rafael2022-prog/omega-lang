# OMEGA Language Specification

Spesifikasi formal untuk bahasa pemrograman OMEGA - bahasa blockchain-agnostic untuk pengembangan smart contract cross-chain.

## 📋 Table of Contents

1. [Introduction](#introduction)
2. [Lexical Structure](#lexical-structure)
3. [Syntax Grammar](#syntax-grammar)
4. [Type System](#type-system)
5. [Expressions](#expressions)
6. [Statements](#statements)
7. [Declarations](#declarations)
8. [Blockchain Abstractions](#blockchain-abstractions)
9. [Standard Library](#standard-library)
10. [Memory Model](#memory-model)
11. [Compilation Model](#compilation-model)
12. [Formal Semantics](#formal-semantics)

## Introduction

OMEGA adalah bahasa pemrograman yang dirancang khusus untuk pengembangan smart contract yang dapat dikompilasi ke berbagai blockchain platforms. Bahasa ini menggabungkan type safety, performance, dan abstraksi cross-chain dalam satu syntax yang konsisten.

### Design Principles

1. **Type Safety**: Strong static typing dengan compile-time verification
2. **Cross-Chain Compatibility**: Abstraksi yang konsisten untuk berbagai blockchain
3. **Performance**: Optimasi untuk gas efficiency dan execution speed
4. **Developer Experience**: Syntax yang familiar dan tooling yang powerful
5. **Security**: Built-in security patterns dan best practices

### File Extension

OMEGA source files menggunakan extension `.mega`.

## Lexical Structure

### Character Set

OMEGA menggunakan Unicode UTF-8 encoding. Semua karakter Unicode valid dapat digunakan dalam string literals dan comments.

### Identifiers

```ebnf
identifier = letter { letter | digit | "_" }
letter = "a" ... "z" | "A" ... "Z"
digit = "0" ... "9"
```

**Rules:**
- Identifiers case-sensitive
- Tidak boleh dimulai dengan digit
- Tidak boleh sama dengan reserved keywords
- Maximum length: 255 characters

**Examples:**
```omega
myVariable
_privateVar
Contract123
calculateBalance
```

### Keywords

```
blockchain    contract      function      let           mut
pub           priv          internal      external      view
pure          payable       modifier      event         emit
constructor   if            else          while         for
loop          break         continue      return        require
assert        revert        try           catch         import
export        as            type          struct        enum
impl          trait         where         self          super
true          false         null          undefined     this
```

### Operators

#### Arithmetic Operators
```
+   -   *   /   %   **
+=  -=  *=  /=  %=  **=
++  --
```

#### Comparison Operators
```
==  !=  <   >   <=  >=
```

#### Logical Operators
```
&&  ||  !
```

#### Bitwise Operators
```
&   |   ^   ~   <<  >>
&=  |=  ^=  <<=  >>=
```

#### Assignment Operators
```
=   +=  -=  *=  /=  %=
&=  |=  ^=  <<=  >>=
```

### Literals

#### Integer Literals
```ebnf
integer_literal = decimal_literal | hex_literal | binary_literal | octal_literal
decimal_literal = digit { digit | "_" }
hex_literal = "0x" hex_digit { hex_digit | "_" }
binary_literal = "0b" binary_digit { binary_digit | "_" }
octal_literal = "0o" octal_digit { octal_digit | "_" }
```

**Examples:**
```omega
42
1_000_000
0xFF
0b1010_1010
0o755
```

#### String Literals
```ebnf
string_literal = "\"" { string_char } "\""
string_char = any_char_except_quote | escape_sequence
escape_sequence = "\\" ( "n" | "t" | "r" | "\\" | "\"" | "'" | "0" | "x" hex_digit hex_digit | "u" hex_digit hex_digit hex_digit hex_digit )
```

**Examples:**
```omega
"Hello, World!"
"Line 1\nLine 2"
"Unicode: \u03A9"  // Ω symbol
"Hex: \x41"        // 'A'
```

#### Boolean Literals
```omega
true
false
```

#### Address Literals
```omega
0x742d35Cc6634C0532925a3b8D4C9db4C4C4b4C4C  // Ethereum address
5FHneW46xGXgs5mUiveU4sbTyGBzmstUspZC92UhjJM694ty  // Substrate address
```

### Comments

#### Line Comments
```omega
// This is a line comment
let x = 42; // Comment at end of line
```

#### Block Comments
```omega
/*
 * This is a block comment
 * spanning multiple lines
 */
```

#### Documentation Comments
```omega
/// This function calculates the balance
/// @param account The account address
/// @return The current balance
pub function getBalance(account: Address) -> U256 {
    // implementation
}
```

## Syntax Grammar

### Program Structure

```ebnf
program = { blockchain_declaration | import_declaration | contract_declaration | function_declaration | type_declaration }

blockchain_declaration = "blockchain" blockchain_list ";"
blockchain_list = blockchain_target { "," blockchain_target }
blockchain_target = "evm" | "solana" | "cosmos" | identifier

import_declaration = "import" import_spec ";"
import_spec = string_literal [ "as" identifier ]

contract_declaration = "contract" identifier [ inheritance_clause ] "{" { contract_member } "}"
inheritance_clause = ":" identifier { "," identifier }

contract_member = state_variable | function_declaration | event_declaration | modifier_declaration | constructor_declaration
```

### Type Declarations

```ebnf
type_declaration = "type" identifier "=" type_expression ";"

struct_declaration = "struct" identifier "{" { field_declaration } "}"
field_declaration = identifier ":" type_expression ";"

enum_declaration = "enum" identifier "{" enum_variant { "," enum_variant } "}"
enum_variant = identifier [ "(" type_expression { "," type_expression } ")" ]
```

### Function Declarations

```ebnf
function_declaration = [ visibility ] "function" identifier "(" parameter_list ")" [ "->" type_expression ] [ function_modifiers ] function_body

parameter_list = [ parameter { "," parameter } ]
parameter = identifier ":" type_expression

function_modifiers = { function_modifier }
function_modifier = "view" | "pure" | "payable" | modifier_call

function_body = "{" { statement } "}"
```

### Statements

```ebnf
statement = expression_statement | declaration_statement | assignment_statement | if_statement | while_statement | for_statement | return_statement | break_statement | continue_statement | block_statement

expression_statement = expression ";"
declaration_statement = variable_declaration ";"
assignment_statement = lvalue assignment_operator expression ";"
if_statement = "if" "(" expression ")" statement [ "else" statement ]
while_statement = "while" "(" expression ")" statement
for_statement = "for" "(" [ variable_declaration ] ";" [ expression ] ";" [ expression ] ")" statement
return_statement = "return" [ expression ] ";"
break_statement = "break" ";"
continue_statement = "continue" ";"
block_statement = "{" { statement } "}"
```

### Expressions

```ebnf
expression = assignment_expression
assignment_expression = conditional_expression [ assignment_operator assignment_expression ]
conditional_expression = logical_or_expression [ "?" expression ":" conditional_expression ]
logical_or_expression = logical_and_expression { "||" logical_and_expression }
logical_and_expression = equality_expression { "&&" equality_expression }
equality_expression = relational_expression { ( "==" | "!=" ) relational_expression }
relational_expression = additive_expression { ( "<" | ">" | "<=" | ">=" ) additive_expression }
additive_expression = multiplicative_expression { ( "+" | "-" ) multiplicative_expression }
multiplicative_expression = unary_expression { ( "*" | "/" | "%" ) unary_expression }
unary_expression = [ unary_operator ] postfix_expression
postfix_expression = primary_expression { postfix_operator }
primary_expression = identifier | literal | "(" expression ")" | function_call | array_access | member_access
```

## Type System

### Primitive Types

#### Integer Types
```omega
// Unsigned integers
U8      // 8-bit unsigned integer (0 to 255)
U16     // 16-bit unsigned integer (0 to 65,535)
U32     // 32-bit unsigned integer (0 to 4,294,967,295)
U64     // 64-bit unsigned integer
U128    // 128-bit unsigned integer
U256    // 256-bit unsigned integer (blockchain native)

// Signed integers
I8      // 8-bit signed integer (-128 to 127)
I16     // 16-bit signed integer
I32     // 32-bit signed integer
I64     // 64-bit signed integer
I128    // 128-bit signed integer
I256    // 256-bit signed integer
```

#### Other Primitive Types
```omega
Bool        // Boolean: true or false
String      // UTF-8 string
Bytes       // Dynamic byte array
Address     // Blockchain address (20 bytes for EVM, 32 bytes for Solana)
Hash        // 32-byte hash value
PublicKey   // Public key (varies by blockchain)
Signature   // Digital signature
```

### Composite Types

#### Arrays
```omega
// Fixed-size arrays
[T; N]      // Array of type T with N elements

// Dynamic arrays
[T]         // Dynamic array of type T

// Examples
[U256; 10]  // Array of 10 U256 values
[Address]   // Dynamic array of addresses
```

#### Mappings
```omega
// Key-value mappings
Map<K, V>   // Mapping from type K to type V

// Examples
Map<Address, U256>          // Address to balance mapping
Map<String, Bool>           // String to boolean mapping
Map<Address, Map<Address, U256>>  // Nested mapping (allowances)
```

#### Tuples
```omega
// Tuple types
(T1, T2, ..., Tn)

// Examples
(Address, U256)             // Address and amount pair
(String, Bool, U32)         // Mixed tuple
```

#### Structs
```omega
struct User {
    address: Address,
    balance: U256,
    active: Bool,
}

struct TokenInfo {
    name: String,
    symbol: String,
    decimals: U8,
    total_supply: U256,
}
```

#### Enums
```omega
enum Status {
    Pending,
    Active,
    Suspended,
    Closed,
}

enum Result<T, E> {
    Ok(T),
    Err(E),
}
```

### Type Inference

OMEGA mendukung type inference dalam konteks tertentu:

```omega
let x = 42;          // Inferred as U32
let y = 42u256;      // Explicit U256
let z = "hello";     // Inferred as String
let addr = msg.sender; // Inferred as Address
```

### Type Conversion

#### Implicit Conversions
- Widening integer conversions (U8 → U16 → U32 → U64 → U128 → U256)
- Subtype to supertype conversions

#### Explicit Conversions
```omega
let x: U32 = 42;
let y: U64 = x as U64;      // Safe upcast
let z: U16 = y as U16;      // Potentially unsafe downcast (requires explicit cast)
```

### Generic Types

```omega
// Generic struct
struct Container<T> {
    value: T,
}

// Generic function
function identity<T>(x: T) -> T {
    return x;
}

// Bounded generics
function compare<T: Comparable>(a: T, b: T) -> Bool {
    return a < b;
}
```

## Expressions

### Literals

```omega
// Integer literals
42
1_000_000u256
0xFF
0b1010

// String literals
"Hello, World!"
"Multi-line\nstring"

// Boolean literals
true
false

// Address literals
0x742d35Cc6634C0532925a3b8D4C9db4C4C4b4C4C

// Array literals
[1, 2, 3, 4, 5]
[Address; 0]  // Empty fixed array

// Struct literals
User {
    address: msg.sender,
    balance: 1000u256,
    active: true,
}
```

### Arithmetic Expressions

```omega
let a = 10 + 20;        // Addition
let b = 50 - 30;        // Subtraction
let c = 4 * 5;          // Multiplication
let d = 100 / 4;        // Division
let e = 17 % 5;         // Modulo
let f = 2 ** 8;         // Exponentiation
```

### Comparison Expressions

```omega
let equal = a == b;         // Equality
let not_equal = a != b;     // Inequality
let less = a < b;           // Less than
let greater = a > b;        // Greater than
let less_eq = a <= b;       // Less than or equal
let greater_eq = a >= b;    // Greater than or equal
```

### Logical Expressions

```omega
let and_result = true && false;     // Logical AND
let or_result = true || false;      // Logical OR
let not_result = !true;             // Logical NOT
```

### Bitwise Expressions

```omega
let and_bits = 0xFF & 0x0F;         // Bitwise AND
let or_bits = 0xFF | 0x0F;          // Bitwise OR
let xor_bits = 0xFF ^ 0x0F;         // Bitwise XOR
let not_bits = ~0xFF;               // Bitwise NOT
let left_shift = 1 << 8;            // Left shift
let right_shift = 256 >> 2;         // Right shift
```

### Function Calls

```omega
// Simple function call
let result = calculateBalance(account);

// Method call
let length = myString.length();

// Chained calls
let processed = data.filter(isValid).map(transform).reduce(combine);
```

### Array Access

```omega
let first = myArray[0];
let last = myArray[myArray.length - 1];

// Multi-dimensional arrays
let element = matrix[i][j];
```

### Member Access

```omega
let userAddress = user.address;
let tokenName = token.info.name;
```

### Conditional Expressions

```omega
let max = a > b ? a : b;
let status = isActive ? "Active" : "Inactive";
```

## Statements

### Variable Declarations

```omega
// Immutable variable
let x = 42;
let name: String = "OMEGA";

// Mutable variable
let mut counter = 0;
let mut balance: U256 = 1000;

// Multiple declarations
let (x, y) = (10, 20);
let mut (a, b, c) = (1, 2, 3);
```

### Assignment Statements

```omega
// Simple assignment
x = 42;

// Compound assignment
counter += 1;
balance -= amount;
value *= 2;
bits |= flag;

// Tuple assignment
(x, y) = (y, x);  // Swap values
```

### Control Flow Statements

#### If Statements

```omega
if condition {
    // statements
}

if condition {
    // statements
} else {
    // statements
}

if condition1 {
    // statements
} else if condition2 {
    // statements
} else {
    // statements
}
```

#### While Loops

```omega
while condition {
    // statements
}

let mut i = 0;
while i < 10 {
    // loop body
    i += 1;
}
```

#### For Loops

```omega
// Range-based for loop
for i in 0..10 {
    // loop body
}

// Array iteration
for item in array {
    // process item
}

// Enumerated iteration
for (index, item) in array.enumerate() {
    // process index and item
}

// Traditional C-style for loop
for let mut i = 0; i < 10; i += 1 {
    // loop body
}
```

#### Loop Control

```omega
while true {
    if condition1 {
        continue;  // Skip to next iteration
    }
    
    if condition2 {
        break;     // Exit loop
    }
    
    // loop body
}
```

### Return Statements

```omega
function getValue() -> U256 {
    return 42;
}

function getMax(a: U256, b: U256) -> U256 {
    if a > b {
        return a;
    }
    return b;
}

// Early return
function processValue(value: U256) -> U256 {
    if value == 0 {
        return 0;
    }
    
    // process non-zero value
    return value * 2;
}
```

## Declarations

### Contract Declarations

```omega
contract MyToken {
    // State variables
    let name: String = "My Token";
    let symbol: String = "MTK";
    let mut total_supply: U256 = 0;
    let mut balances: Map<Address, U256> = Map::new();
    
    // Events
    event Transfer(from: Address, to: Address, amount: U256);
    event Approval(owner: Address, spender: Address, amount: U256);
    
    // Constructor
    constructor(initial_supply: U256) {
        total_supply = initial_supply;
        balances[msg.sender] = initial_supply;
    }
    
    // Functions
    pub function transfer(to: Address, amount: U256) -> Bool {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
        
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    pub view function balanceOf(account: Address) -> U256 {
        return balances[account];
    }
}
```

### Function Declarations

#### Visibility Modifiers

```omega
pub function publicFunction() {
    // Accessible from anywhere
}

internal function internalFunction() {
    // Accessible within contract and derived contracts
}

priv function privateFunction() {
    // Accessible only within this contract
}

external function externalFunction() {
    // Only callable from outside the contract
}
```

#### State Mutability

```omega
view function readOnlyFunction() -> U256 {
    // Cannot modify state
    return balance;
}

pure function pureFunction(a: U256, b: U256) -> U256 {
    // Cannot read or modify state
    return a + b;
}

payable function receiveEther() {
    // Can receive native tokens
    balance += msg.value;
}
```

#### Function Modifiers

```omega
modifier onlyOwner() {
    require(msg.sender == owner, "Not the owner");
    _;
}

modifier validAmount(amount: U256) {
    require(amount > 0, "Amount must be positive");
    _;
}

pub function withdraw(amount: U256) onlyOwner validAmount(amount) {
    // Function body
}
```

### Event Declarations

```omega
event Transfer(from: Address, to: Address, amount: U256);
event Approval(owner: Address, spender: Address, amount: U256);
event StateChanged(oldState: U8, newState: U8);

// Indexed parameters (for efficient filtering)
event Transfer(indexed from: Address, indexed to: Address, amount: U256);
```

### State Variable Declarations

```omega
contract MyContract {
    // Public state variable (automatic getter generated)
    pub let owner: Address = msg.sender;
    
    // Private state variable
    priv let mut secret: U256 = 0;
    
    // Constant
    let DECIMALS: U8 = 18;
    
    // Mapping
    let mut balances: Map<Address, U256> = Map::new();
    
    // Array
    let mut users: [Address] = [];
    
    // Struct
    let mut config: Config = Config {
        fee_rate: 100,
        max_supply: 1_000_000,
        paused: false,
    };
}
```

## Blockchain Abstractions

### Built-in Variables

#### Message Context

```omega
msg.sender      // Address of the caller
msg.value       // Amount of native tokens sent (EVM: wei, Solana: lamports)
msg.data        // Call data
msg.sig         // Function signature (first 4 bytes of call data)
```

#### Block Context

```omega
block.number        // Current block number
block.timestamp     // Current block timestamp
block.difficulty    // Block difficulty (EVM only)
block.gaslimit      // Block gas limit (EVM only)
block.coinbase      // Block miner address (EVM only)
```

#### Transaction Context

```omega
tx.origin       // Original transaction sender
tx.gasprice     // Gas price (EVM only)
```

#### Contract Context

```omega
this.address    // Current contract address
this.balance    // Current contract balance
```

### Built-in Functions

#### Cryptographic Functions

```omega
// Hash functions
keccak256(data: Bytes) -> Hash
sha256(data: Bytes) -> Hash
blake2b(data: Bytes) -> Hash

// Signature verification
ecrecover(hash: Hash, v: U8, r: Hash, s: Hash) -> Address
verify_signature(message: Bytes, signature: Signature, pubkey: PublicKey) -> Bool
```

#### Utility Functions

```omega
// Assertions
require(condition: Bool, message: String)
assert(condition: Bool)
revert(message: String)

// Type conversions
address(value: U256) -> Address
uint256(addr: Address) -> U256
bytes32(value: U256) -> Hash
```

#### Transfer Functions

```omega
// Native token transfers
transfer(to: Address, amount: U256) -> Bool
send(to: Address, amount: U256) -> Bool

// Low-level calls
call(to: Address, data: Bytes) -> (Bool, Bytes)
delegatecall(to: Address, data: Bytes) -> (Bool, Bytes)
staticcall(to: Address, data: Bytes) -> (Bool, Bytes)
```

### Cross-Chain Abstractions

#### Universal Types

```omega
// Universal address type that works across chains
type UniversalAddress = Address;

// Universal token amount (automatically scaled for chain decimals)
type TokenAmount = U256;

// Universal transaction hash
type TxHash = Hash;
```

#### Chain-Specific Blocks

```omega
contract CrossChainToken {
    #[evm]
    function mint_evm(to: Address, amount: U256) {
        // EVM-specific implementation
        _mint(to, amount);
    }
    
    #[solana]
    function mint_solana(to: Address, amount: U64) {
        // Solana-specific implementation
        token::mint_to(ctx, to, amount)?;
    }
    
    #[cosmos]
    function mint_cosmos(to: Address, amount: U256) {
        // Cosmos-specific implementation
        bank.mint_coins(ctx, to, amount);
    }
}
```

## Standard Library

### Core Modules

#### Math Module

```omega
import "std/math";

// Basic operations
Math.abs(x: I256) -> U256
Math.min(a: U256, b: U256) -> U256
Math.max(a: U256, b: U256) -> U256
Math.pow(base: U256, exp: U256) -> U256
Math.sqrt(x: U256) -> U256

// Safe arithmetic (prevents overflow/underflow)
Math.safe_add(a: U256, b: U256) -> Result<U256, String>
Math.safe_sub(a: U256, b: U256) -> Result<U256, String>
Math.safe_mul(a: U256, b: U256) -> Result<U256, String>
Math.safe_div(a: U256, b: U256) -> Result<U256, String>
```

#### String Module

```omega
import "std/string";

// String operations
String.length(s: String) -> U32
String.concat(a: String, b: String) -> String
String.substring(s: String, start: U32, end: U32) -> String
String.to_bytes(s: String) -> Bytes
String.from_bytes(b: Bytes) -> String
```

#### Array Module

```omega
import "std/array";

// Array operations
Array.length<T>(arr: [T]) -> U32
Array.push<T>(arr: [T], item: T) -> [T]
Array.pop<T>(arr: [T]) -> (T, [T])
Array.get<T>(arr: [T], index: U32) -> Option<T>
Array.contains<T>(arr: [T], item: T) -> Bool
```

#### Map Module

```omega
import "std/map";

// Map operations
Map.new<K, V>() -> Map<K, V>
Map.insert<K, V>(map: Map<K, V>, key: K, value: V) -> Map<K, V>
Map.get<K, V>(map: Map<K, V>, key: K) -> Option<V>
Map.contains_key<K, V>(map: Map<K, V>, key: K) -> Bool
Map.remove<K, V>(map: Map<K, V>, key: K) -> Map<K, V>
```

### Token Standards

#### ERC20 Interface

```omega
import "std/token/erc20";

trait ERC20 {
    function totalSupply() -> U256;
    function balanceOf(account: Address) -> U256;
    function transfer(to: Address, amount: U256) -> Bool;
    function allowance(owner: Address, spender: Address) -> U256;
    function approve(spender: Address, amount: U256) -> Bool;
    function transferFrom(from: Address, to: Address, amount: U256) -> Bool;
    
    event Transfer(indexed from: Address, indexed to: Address, amount: U256);
    event Approval(indexed owner: Address, indexed spender: Address, amount: U256);
}
```

#### ERC721 Interface

```omega
import "std/token/erc721";

trait ERC721 {
    function balanceOf(owner: Address) -> U256;
    function ownerOf(tokenId: U256) -> Address;
    function safeTransferFrom(from: Address, to: Address, tokenId: U256);
    function transferFrom(from: Address, to: Address, tokenId: U256);
    function approve(to: Address, tokenId: U256);
    function getApproved(tokenId: U256) -> Address;
    function setApprovalForAll(operator: Address, approved: Bool);
    function isApprovedForAll(owner: Address, operator: Address) -> Bool;
    
    event Transfer(indexed from: Address, indexed to: Address, indexed tokenId: U256);
    event Approval(indexed owner: Address, indexed approved: Address, indexed tokenId: U256);
    event ApprovalForAll(indexed owner: Address, indexed operator: Address, approved: Bool);
}
```

### Security Module

```omega
import "std/security";

// Access control
Security.only_owner(owner: Address)
Security.only_role(role: String, account: Address)

// Reentrancy protection
Security.nonReentrant()

// Pause functionality
Security.whenNotPaused(paused: Bool)
Security.whenPaused(paused: Bool)

// Rate limiting
Security.rateLimit(key: String, limit: U32, window: U256)
```

## Memory Model

### Storage vs Memory

#### Storage
- Persistent state yang disimpan di blockchain
- Expensive untuk read/write operations
- Automatically persisted between function calls

```omega
contract MyContract {
    let mut storage_var: U256 = 0;  // Stored in contract storage
    
    function updateStorage(value: U256) {
        storage_var = value;  // Writes to blockchain storage
    }
}
```

#### Memory
- Temporary data yang hanya ada selama function execution
- Cheaper untuk operations
- Cleared after function returns

```omega
function processData(input: [U256]) -> U256 {
    let memory_array: [U256] = input;  // Copied to memory
    let mut sum: U256 = 0;             // Local memory variable
    
    for item in memory_array {
        sum += item;
    }
    
    return sum;  // Memory cleared after return
}
```

### Reference vs Value Types

#### Value Types
- Copied when assigned or passed to functions
- Include: integers, booleans, addresses, fixed arrays

```omega
let a: U256 = 100;
let b: U256 = a;  // b gets a copy of a's value
a = 200;          // b is still 100
```

#### Reference Types
- Passed by reference
- Include: dynamic arrays, mappings, structs, strings

```omega
let mut arr1: [U256] = [1, 2, 3];
let mut arr2: [U256] = arr1;  // arr2 references same data as arr1
arr1.push(4);                 // Both arr1 and arr2 now contain [1, 2, 3, 4]
```

## Compilation Model

### Compilation Phases

1. **Lexical Analysis**: Source code → Tokens
2. **Parsing**: Tokens → Abstract Syntax Tree (AST)
3. **Semantic Analysis**: Type checking, symbol resolution
4. **IR Generation**: AST → Intermediate Representation
5. **Optimization**: IR transformations
6. **Code Generation**: IR → Target code (Solidity/Rust/Go)

### Target-Specific Compilation

#### EVM Target (Solidity)

```omega
// OMEGA source
contract Token {
    let mut balances: Map<Address, U256> = Map::new();
    
    pub function transfer(to: Address, amount: U256) -> Bool {
        balances[msg.sender] -= amount;
        balances[to] += amount;
        return true;
    }
}
```

Compiles to Solidity:
```solidity
// Generated Solidity
pragma solidity ^0.8.0;

contract Token {
    mapping(address => uint256) private balances;
    
    function transfer(address to, uint256 amount) public returns (bool) {
        balances[msg.sender] -= amount;
        balances[to] += amount;
        return true;
    }
}
```

#### Solana Target (Rust/Anchor)

Compiles to Rust:
```rust
// Generated Rust (Anchor)
use anchor_lang::prelude::*;

#[program]
pub mod token {
    use super::*;
    
    pub fn transfer(ctx: Context<Transfer>, amount: u64) -> Result<()> {
        let from_account = &mut ctx.accounts.from;
        let to_account = &mut ctx.accounts.to;
        
        from_account.balance -= amount;
        to_account.balance += amount;
        
        Ok(())
    }
}
```

### Configuration

```toml
# omega.toml
[project]
name = "my-token"
version = "1.0.0"

[targets]
evm = { enabled = true, solidity_version = "0.8.19" }
solana = { enabled = true, anchor_version = "0.28.0" }
cosmos = { enabled = false }

[build]
optimization_level = "balanced"
generate_docs = true
```

## Formal Semantics

### Type System Rules

#### Subtyping Rules

```
T <: T                           (Reflexivity)

T1 <: T2, T2 <: T3 ⟹ T1 <: T3   (Transitivity)

U8 <: U16 <: U32 <: U64 <: U128 <: U256   (Integer widening)

I8 <: I16 <: I32 <: I64 <: I128 <: I256   (Signed integer widening)
```

#### Type Checking Rules

**Variable Declaration:**
```
Γ ⊢ e : T
─────────────────
Γ ⊢ let x: T = e
```

**Function Application:**
```
Γ ⊢ f : T1 → T2    Γ ⊢ e : T1
──────────────────────────────
Γ ⊢ f(e) : T2
```

**Conditional Expression:**
```
Γ ⊢ e1 : Bool    Γ ⊢ e2 : T    Γ ⊢ e3 : T
─────────────────────────────────────────
Γ ⊢ e1 ? e2 : e3 : T
```

### Operational Semantics

#### Expression Evaluation

**Arithmetic Operations:**
```
⟨n1, σ⟩ ⇓ v1    ⟨n2, σ⟩ ⇓ v2    v1, v2 ∈ ℕ
─────────────────────────────────────────
⟨n1 + n2, σ⟩ ⇓ v1 + v2
```

**Variable Access:**
```
σ(x) = v
─────────────
⟨x, σ⟩ ⇓ v
```

**Function Call:**
```
⟨e1, σ⟩ ⇓ v1    ...    ⟨en, σ⟩ ⇓ vn
⟨f(v1, ..., vn), σ⟩ ⇓ ⟨body[x1 ↦ v1, ..., xn ↦ vn], σ⟩
─────────────────────────────────────────────────────────
⟨f(e1, ..., en), σ⟩ ⇓ result
```

#### Statement Execution

**Assignment:**
```
⟨e, σ⟩ ⇓ v
─────────────────────
⟨x = e, σ⟩ → σ[x ↦ v]
```

**Conditional:**
```
⟨e, σ⟩ ⇓ true    ⟨s1, σ⟩ → σ'
──────────────────────────────
⟨if e then s1 else s2, σ⟩ → σ'

⟨e, σ⟩ ⇓ false    ⟨s2, σ⟩ → σ'
──────────────────────────────
⟨if e then s1 else s2, σ⟩ → σ'
```

**While Loop:**
```
⟨e, σ⟩ ⇓ false
─────────────────────
⟨while e do s, σ⟩ → σ

⟨e, σ⟩ ⇓ true    ⟨s, σ⟩ → σ'    ⟨while e do s, σ'⟩ → σ''
────────────────────────────────────────────────────────
⟨while e do s, σ⟩ → σ''
```

### Security Properties

#### Memory Safety
- No buffer overflows
- No null pointer dereferences
- No use-after-free errors

#### Type Safety
- Well-typed programs don't go wrong
- No runtime type errors
- Strong encapsulation

#### Blockchain Safety
- Reentrancy protection
- Integer overflow/underflow protection
- Access control enforcement

---

*Spesifikasi ini akan terus diperbarui seiring perkembangan bahasa OMEGA.*