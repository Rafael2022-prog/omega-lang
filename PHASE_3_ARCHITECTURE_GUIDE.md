# OMEGA Semantic Analysis - Phase 3 Architecture Guide

**Purpose:** Deep dive into the semantic analysis layer architecture  
**Audience:** Compiler developers, code generator implementers  
**Related Files:** analyzer.mega, symbol_table.mega, type_checker.mega  

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Component Descriptions](#component-descriptions)
3. [Data Flow](#data-flow)
4. [Symbol Table Design](#symbol-table-design)
5. [Type System Design](#type-system-design)
6. [Type Checking Algorithm](#type-checking-algorithm)
7. [Integration Points](#integration-points)
8. [Error Handling](#error-handling)
9. [Extension Points](#extension-points)

---

## Architecture Overview

### High-Level View

```
                    ┌─────────────────┐
                    │   AST from      │
                    │   Parser        │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │                 │
                    │ Semantic        │
                    │ Analyzer        │
                    │                 │
                    └────────┬────────┘
                             │
            ┌────────────────┼────────────────┐
            │                │                │
      ┌─────▼──────┐  ┌──────▼────┐  ┌──────▼──────┐
      │  Symbol    │  │   Type    │  │ Blockchain │
      │  Table     │  │  Checker  │  │ Validator  │
      │  Manager   │  │           │  │            │
      └────────────┘  └───────────┘  └────────────┘
            │                │              │
            └────────────────┼──────────────┘
                             │
                    ┌────────▼────────┐
                    │                 │
                    │ Semantic        │
                    │ Analysis        │
                    │ Results         │
                    │                 │
                    └─────────────────┘
```

### Three-Phase Analysis

The semantic analyzer uses a **pipeline architecture** with three distinct phases:

```
Input: Program (AST from parser)
  │
  ├─ Phase 1: Definition Collection ──────┐
  │  (collect_definitions)                 │
  │  ✓ Extract all symbol definitions      │
  │  ✓ Build symbol table                  │
  │  ✓ Register types                      │
  │                                        │
  ├─ Phase 2: Type Checking ──────────────┤
  │  (type_check_program)                  │
  │  ✓ Validate all types                  │
  │  ✓ Check compatibility                 │
  │  ✓ Infer missing types                 │
  │                                        │
  ├─ Phase 3: Blockchain Validation ──────┤
  │  (validate_blockchain_rules)           │
  │  ✓ Check blockchain-specific rules     │
  │  ✓ Validate state transitions          │
  │  ✓ Check contract invariants           │
  │                                        │
Output: AnalysisResults
   ├─ symbols_collected (count)
   ├─ type_errors (errors array)
   ├─ blockchain_warnings (warnings)
   └─ analysis_time (duration)
```

---

## Component Descriptions

### 1. OmegaSemanticAnalyzer (analyzer.mega)

**Responsibility:** Orchestrate and coordinate the three analysis phases

#### Key Methods

```mega
function analyze(program: Program, file_path: string) 
    -> AnalysisResults
```
Main entry point. Orchestrates all three phases and returns results.

```mega
function collect_definitions(program: Program) -> void
```
Phase 1: Walk AST and build symbol table. Populates:
- Function definitions
- State variable definitions
- Type definitions
- Module-level declarations

```mega
function type_check_program(program: Program) -> void
```
Phase 2: Validate all types in AST. Ensures:
- All variables are defined before use
- All types are compatible in expressions
- Function calls match signatures
- Return types are correct

```mega
function validate_blockchain_rules(program: Program) -> void
```
Phase 3: Check blockchain-specific invariants. Validates:
- State modification rules
- Access control
- Reentrancy safety (basic)
- Cross-chain compatibility

#### State

```mega
state {
    symbol_manager: SymbolTableManager;
    type_checker: TypeChecker;
    blockchain_validator: BlockchainValidator;
    
    current_phase: uint8;           // 1=collection, 2=typing, 3=validation
    current_file: string;           // File being analyzed
    error_handler: OmegaErrorHandler;
    
    symbols_collected: uint256;
    type_errors: SemanticError[];
    blockchain_warnings: string[];
}
```

---

### 2. SymbolTableManager (symbol_table.mega)

**Responsibility:** Manage symbol definitions and scope hierarchy

#### Key Data Structures

```mega
struct Symbol {
    name: string;                    // Symbol identifier
    symbol_type: Type;              // Type information
    location: SourceLocation;       // Where it was defined
    scope_level: uint8;             // Nesting depth
    is_const: bool;                 // Constant/mutable
}

struct Scope {
    symbols: Mapping(string => Symbol);
    parent_scope: Scope*;
    scope_name: string;
    scope_type: ScopeType;  // Global, Function, Block, etc
}
```

#### Key Methods

```mega
function define_symbol(name: string, symbol: Symbol) -> void
```
Add symbol to current scope. Errors if duplicate exists.

```mega
function lookup_symbol(name: string) -> Symbol
```
Search for symbol in current scope chain. Returns closest match.

```mega
function enter_scope(scope_name: string) -> void
```
Create new nested scope. Increases scope depth.

```mega
function exit_scope() -> void
```
Exit current scope. Decreases scope depth.

```mega
function lookup_symbol_in_scope(name: string, scope: Scope) -> Symbol*
```
Look up symbol in specific scope without chain traversal.

#### Scope Chain Algorithm

```
Lookup "x" in nested scopes:
  
  Global Scope
  ├─ x: uint256
  │
  └─ Function foo() Scope
     ├─ x: string (shadows global)
     │
     └─ Block { } Scope
        ├─ lookup("x") starts here
        ├─ Not found locally
        ├─ Check parent (Function foo)
        ├─ Found: x is string
        
Result: x is string (shadowed by function scope)
```

#### Scope Types

| Type | Created By | Purpose |
|------|-----------|---------|
| Global | Program | Top-level definitions |
| Function | Function declaration | Function parameters & locals |
| Block | {}, if, for, while | Local control flow variables |
| Struct | struct definition | Field definitions |
| Module | import statement | Module-level imports |

---

### 3. TypeChecker (type_checker.mega)

**Responsibility:** Validate type correctness throughout AST

#### Type System

```mega
struct Type {
    base_type: BaseType;        // What kind of type
    is_array: bool;             // Is this array?
    array_size: uint256;        // Size if fixed array
    array_depth: uint8;         // Nested array depth
    custom_info: UserType*;     // Extra info for custom types
}

enum BaseType {
    Uint256, Int256,            // 256-bit integers
    Uint8-248, Int8-248,        // Various sizes
    Bool,                       // Boolean
    Address,                    // Blockchain address
    String,                     // Dynamic string
    Bytes,                      // Dynamic bytes
    Bytes1-32,                  // Fixed-size bytes
    Void,                       // No return value
    Custom                      // User-defined type
}
```

#### Builtin Types Environment

```mega
TypeEnvironment {
    uint256: Type,              // All builtin types
    int256: Type,
    bool: Type,
    address: Type,
    string: Type,
    bytes: Type,
    void: Type,
    // ... and sized variants
}
```

#### Key Methods

```mega
function type_check_program(program: Program) -> void
```
Entry point for type checking. Validates all items.

```mega
function types_compatible(type_a: Type, type_b: Type) -> bool
```
Check if type_a can be assigned to type_b.

Compatibility rules:
- Same base type → compatible
- Signed/unsigned integer → compatible (with warning)
- Subtype → compatible
- Everything else → incompatible

```mega
function infer_literal_type(literal: Literal) -> Type
```
Determine type from literal value.

Examples:
- `42` → uint256
- `true` → bool
- `"hello"` → string
- `0x123...` → address
- `[1,2,3]` → uint256[]

```mega
function infer_expression_type(expr: Expression) -> Type
```
Determine expression type from structure.

Examples:
- `a + b` → type of a (if compatible with b)
- `a > b` → bool
- `[a, b, c]` → array of type(a)

```mega
function type_check_expression(expr: Expression) -> void
```
Validate expression is well-typed.

Checks all sub-expressions and operators.

```mega
function type_check_statement(stmt: Statement) -> void
```
Validate statement is well-typed.

Examples:
- Variable declarations have matching types
- If conditions are boolean
- Return values match function return type

```mega
function register_custom_type(name: string, type_info: UserType) -> void
```
Register user-defined type (struct, etc).

```mega
function custom_type_exists(name: string) -> bool
```
Check if custom type is defined.

#### Type Compatibility Matrix

```
FROM/TO      | uint256 | int256 | bool | address | string | bytes |
─────────────┼─────────┼────────┼──────┼─────────┼────────┼───────┤
uint256      |    ✓    |   ✓    |  ✗   |    ✗    |   ✗    |   ✗   |
int256       |    ✓    |   ✓    |  ✗   |    ✗    |   ✗    |   ✗   |
bool         |    ✗    |   ✗    |  ✓   |    ✗    |   ✗    |   ✗   |
address      |    ✗    |   ✗    |  ✗   |    ✓    |   ✗    |   ✗   |
string       |    ✗    |   ✗    |  ✗   |    ✗    |   ✓    |   ✗   |
bytes        |    ✗    |   ✗    |  ✗   |    ✗    |   ✗    |   ✓   |

✓ = Can assign | ✗ = Type error
```

---

### 4. BlockchainValidator (blockchain_validator.mega)

**Responsibility:** Enforce blockchain-specific semantic rules

#### Blockchain-Specific Rules

```
1. State Modification Rules
   ├─ Public functions can modify state
   ├─ Read-only functions cannot modify state
   └─ Events can only be emitted from state-modifying functions

2. Access Control
   ├─ public functions accessible from outside
   ├─ private functions only within contract
   ├─ protected functions only within hierarchy
   └─ Proper access control on state variables

3. Reentrancy Safety (Basic)
   ├─ External calls tracked
   ├─ State modifications ordered correctly
   └─ Critical sections identified

4. Cross-Chain Compatibility
   ├─ All types transmissible
   ├─ No local-only constructs used
   └─ Bridge compatibility verified
```

---

## Data Flow

### From Parser to Analysis

```
AST Program
    │
    ├─ Blockchains (contracts)
    │  ├─ FunctionDeclaration items
    │  ├─ StateVariable items
    │  └─ TypeDeclaration items
    │
    ├─ Structs
    ├─ Enums
    └─ Imports

         ↓ Analyzer.analyze(program, file)

AnalysisResults
    ├─ symbols_collected: 42
    ├─ type_errors: []
    ├─ blockchain_warnings: []
    └─ analysis_time: 5ms
```

### Symbol Resolution Example

```
Code:
    let x: uint256 = 42;
    {
        let x: string = "hi";
        let y: uint256 = x;  // ← Type error: can't assign string to uint256
    }

Symbol Table During Analysis:
    
    Global Scope
    ├─ x: Type{Uint256} at line 1
    │
    └─ Block Scope (from line 3)
       ├─ x: Type{String} at line 4  (shadows outer x)
       └─ y: Type{Uint256} at line 5
               ↑ Lookup("x") returns String type
               ✗ Type error: String ≠ Uint256
```

### Type Checking Example

```
Code:
    function add(a: uint256, b: uint256) -> uint256 {
        return a + b;
    }
    
    let result: uint256 = add(1, 2);

Type Checking Phases:

Phase 1: Definition Collection
    ├─ Register function "add"
    │  ├─ Parameters: a: uint256, b: uint256
    │  └─ Return type: uint256
    └─ Create symbol for "result"

Phase 2: Type Checking
    ├─ Check function body
    │  ├─ "a + b" where a: uint256, b: uint256
    │  ├─ Operator + requires same types
    │  ├─ Returns uint256 ✓
    │  └─ Return type matches declared ✓
    │
    └─ Check function call
       ├─ add(1, 2) has 2 arguments ✓
       ├─ 1 is uint256 ✓
       ├─ 2 is uint256 ✓
       ├─ Return type uint256 matches result ✓
       └─ All checks pass ✓

Phase 3: Blockchain Validation
    └─ Function is public, can modify state ✓
```

---

## Symbol Table Design

### Scope Hierarchy

```
Program
  │
  └─ Global Scope
     ├─ imports
     ├─ type_declarations (structs, enums)
     ├─ blockchain "MyContract"
     │  ├─ Contract Scope
     │  ├─ state_variables
     │  │
     │  └─ function foo()
     │     ├─ Function Scope
     │     ├─ parameters: (x: uint256, y: uint256)
     │     ├─ local_variables: (sum: uint256)
     │     │
     │     └─ if (x > y) { }
     │        ├─ Block Scope
     │        └─ local_to_block: (diff: uint256)
     │
     └─ blockchain "OtherContract"
        └─ ...
```

### Symbol Lookup Algorithm

```
lookup_symbol("x", current_scope):
    
    if x found in current_scope:
        return x
    
    if current_scope.parent == null:
        error "x not defined"
    
    return lookup_symbol("x", current_scope.parent)
    
Time Complexity: O(scope_depth)
Space Complexity: O(scope_depth) for call stack
```

### Duplicate Detection

```
define_symbol("x", symbol):
    
    if "x" already in current_scope:
        error "Duplicate definition of x"
    
    current_scope.symbols["x"] = symbol
```

---

## Type System Design

### Type Inference Rules

```
Expression Type Inference:

Literal("42")
    → Infer as smallest integer type that fits
    → uint256 (safest for blockchain)

Literal("true")
    → bool

Literal("\"hello\"")
    → string

Identifier("x")
    → Look up x in symbol table
    → Return registered type

BinaryOp(a, "+", b)
    → if a.type == b.type and numeric(a.type)
      → return a.type
      → else type error

UnaryOp("-", a)
    → if numeric(a.type)
      → return a.type
      → else type error

Ternary(cond, true_expr, false_expr)
    → if cond.type != bool → type error
      if true_expr.type != false_expr.type → type error
      → return true_expr.type

FunctionCall(func, args)
    → Look up func signature
    → Check argument count matches
    → Check each arg type matches parameter type
    → Return function return type
```

### Type Compatibility Rules

```
assignment_check(from_type, to_type):
    
    if from_type == to_type:
        return OK
    
    if numeric(from_type) and numeric(to_type):
        return OK  // Implicit conversion between numeric types
    
    if from_type is subtype of to_type:
        return OK
    
    if explicit_cast requested:
        return OK  // Explicit type cast allowed
    
    return ERROR  // Incompatible types
```

---

## Type Checking Algorithm

### Expression Type Checking

```
function check_expression(expr: Expression):
    
    match expr.type:
        case Literal:
            inferred = infer_literal_type(expr)
            expr.inferred_type = inferred
            
        case Identifier:
            symbol = symbol_table.lookup(expr.name)
            if symbol == null:
                error("Symbol " + expr.name + " not defined")
            expr.inferred_type = symbol.type
            
        case BinaryOp:
            check_expression(expr.left)
            check_expression(expr.right)
            left_type = expr.left.inferred_type
            right_type = expr.right.inferred_type
            
            if not compatible(left_type, right_type):
                error("Incompatible types in " + expr.operator)
            
            expr.inferred_type = result_type(expr.operator, left_type, right_type)
            
        case FunctionCall:
            check_function_call(expr)
            
        ... handle other cases ...
```

### Statement Type Checking

```
function check_statement(stmt: Statement):
    
    match stmt.type:
        case Declaration:
            check_declaration(stmt)
            
        case Assignment:
            check_expression(stmt.value)
            value_type = stmt.value.inferred_type
            symbol = symbol_table.lookup(stmt.target)
            
            if not types_compatible(value_type, symbol.type):
                error("Type mismatch in assignment")
            
        case IfStatement:
            check_expression(stmt.condition)
            if stmt.condition.inferred_type != bool:
                error("If condition must be bool")
            
            check_statement(stmt.then_body)
            if stmt.else_body != null:
                check_statement(stmt.else_body)
            
        case WhileStatement:
            check_expression(stmt.condition)
            if stmt.condition.inferred_type != bool:
                error("While condition must be bool")
            check_statement(stmt.body)
            
        case ReturnStatement:
            if stmt.value != null:
                check_expression(stmt.value)
                value_type = stmt.value.inferred_type
                expected_type = current_function.return_type
                
                if not types_compatible(value_type, expected_type):
                    error("Return type mismatch")
            
        ... handle other cases ...
```

---

## Integration Points

### 1. With Parser

**Input:** `Program` (AST)

Parser produces complete AST with:
- All declarations extracted
- All expressions structured
- All statements parsed
- Location information preserved

**Output:** Validated `AnalysisResults`

Semantic analyzer enriches AST with:
- Type information for each node
- Symbol resolution
- Semantic error details

### 2. With Code Generator

**Input:** Validated `Program` + `AnalysisResults`

Code generator uses:
- Symbol table for variable allocation
- Type information for type-specific code
- Blockchain validation results for optimizations
- Semantic errors to skip code generation if needed

### 3. With Error Handler

**Input:** Semantic errors during analysis

Error handler receives:
- Type mismatch errors
- Undefined symbol errors
- Invalid operation errors
- Scope violation errors

**Output:** User-friendly error messages

### 4. With Source Location

Every symbol and error tracks:
- File path
- Line number
- Column number
- Length in characters

Enables precise error reporting:
```
error at file.omega:42:15:
    let x: string = 42;  // Type error
               ^        // Points to exact location
    Cannot assign int to string
```

---

## Error Handling

### Error Types

```
SemanticError {
    error_type: ErrorType;
    message: string;
    location: SourceLocation;
    suggestion: string;  // How to fix
}

enum ErrorType {
    UndefinedSymbol,           // Symbol not in scope
    DuplicateDefinition,       // Symbol already defined
    TypeMismatch,              // Incompatible types
    InvalidOperation,          // Operation not valid for types
    FunctionCallMismatch,      // Arguments don't match signature
    ReturnTypeMismatch,        // Return value wrong type
    UnreachableCode,           // Code after unconditional return
    InvalidStateModification,  // State modified in read-only function
    AccessControlViolation,    // Accessing private member
    ReentrancyRisk,            // Potential reentrancy
    UnusedVariable,            // Variable declared but never used
}
```

### Error Recovery

The analyzer continues analyzing despite errors to report **multiple issues at once**:

```
Phase 1: Definition Collection
    ├─ Collect all symbols despite some errors
    ├─ Continue to Phase 2

Phase 2: Type Checking
    ├─ Check all expressions despite type errors
    ├─ Accumulate all errors found
    ├─ Continue to Phase 3

Phase 3: Blockchain Validation
    ├─ Check all rules despite errors
    ├─ Continue to completion

Result: AnalysisResults with all errors collected
    ├─ User sees multiple issues at once
    ├─ Not just the first error
```

---

## Extension Points

### 1. Adding New Builtin Types

```mega
// In TypeChecker initialization:
add_builtin_type("uint256", Type{BaseType.Uint256, ...});
add_builtin_type("my_custom_int", Type{BaseType.Uint256, ...});
```

### 2. Adding New Validation Rules

```mega
// In BlockchainValidator:
function validate_my_rule(program: Program) -> void {
    // Implement custom validation
    // Add errors to results
}
```

### 3. Adding Custom Symbol Information

```mega
// Extend Symbol struct:
struct Symbol {
    // ... existing fields ...
    custom_metadata: string;  // Store extra info
    access_control: AccessLevel;
    is_deprecated: bool;
}
```

### 4. Adding Type Inference Rules

```mega
// In TypeChecker.infer_expression_type():
case CustomExpression:
    // Add custom type inference logic
    return infer_custom_type(...);
```

### 5. Adding New Analysis Phases

```mega
// In SemanticAnalyzer:
function analyze(...) -> AnalysisResults {
    collect_definitions(...);
    type_check_program(...);
    validate_blockchain_rules(...);
    validate_my_new_rules(...);      // ← Add new phase
    return results;
}
```

---

## Performance Characteristics

### Time Complexity

| Operation | Complexity | Notes |
|-----------|-----------|-------|
| Symbol lookup | O(d) | d = scope depth (usually <10) |
| Symbol definition | O(1) | Hash map insertion |
| Type check expr | O(n) | n = AST node count |
| Type check stmt | O(n) | n = AST node count |
| Full analysis | O(n) | Single pass through AST |

### Space Complexity

| Component | Complexity | Notes |
|-----------|-----------|-------|
| Symbol table | O(s) | s = symbol count |
| Type environment | O(1) | Fixed number of builtin types |
| Results | O(e) | e = error count (usually small) |

**Typical Analysis:**
- 100 symbols: <1ms
- 1000 lines of code: 5-10ms
- 10,000 lines of code: 50-100ms

---

## Testing Strategy

### Unit Tests
- Symbol table operations
- Type compatibility checking
- Type inference
- Error detection

### Integration Tests
- Multi-phase analysis
- Symbol lookup across scopes
- Complex type checking
- Error accumulation

### Regression Tests
- New features don't break existing
- Error messages remain clear
- Performance stays acceptable

---

## Future Enhancements

1. **Advanced Type Inference**
   - Constraint-based type inference
   - Generic types and templates
   - Type bounds and constraints

2. **Flow-Sensitive Analysis**
   - Unreachable code detection
   - Variable use-before-definition detection
   - Dead code elimination

3. **Advanced Optimizations**
   - Constant folding during semantic analysis
   - Dead code removal
   - Type specialization hints

4. **Reentrancy Analysis**
   - Call graph analysis
   - State modification tracking
   - Reentrancy pattern detection

5. **Contract Verification**
   - Invariant verification
   - Precondition/postcondition checking
   - Safety property verification

---

*End of Phase 3 Architecture Guide*
