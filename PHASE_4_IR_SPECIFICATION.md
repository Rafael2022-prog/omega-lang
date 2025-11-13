# OMEGA Intermediate Representation (IR) - Specification

**Phase:** 4 (Code Generation)  
**Purpose:** Define the intermediate representation for OMEGA programs  
**Target:** Enable code generation to multiple platforms (EVM, JavaScript, Solidity)  
**Status:** Design Phase

---

## Table of Contents

1. [Overview](#overview)
2. [IR Concepts](#ir-concepts)
3. [IR Operations](#ir-operations)
4. [Memory Model](#memory-model)
5. [Control Flow](#control-flow)
6. [Function Representation](#function-representation)
7. [Data Types in IR](#data-types-in-ir)
8. [Examples](#examples)
9. [Optimization Hooks](#optimization-hooks)

---

## Overview

### Purpose

The OMEGA IR is a **three-address code** format that serves as an intermediate step between the semantic analyzer and code generation. It provides:

- **Platform Independence:** Same IR can generate code for EVM, JavaScript, or Solidity
- **Optimization Opportunities:** Clear structure enables multiple optimization passes
- **Simplification:** Reduces complexity of code generation
- **Type Information:** Preserves type data for code generation

### Design Principles

1. **Simplicity:** Single-assignment form (SSA) for clarity
2. **Completeness:** Represent all OMEGA language constructs
3. **Uniformity:** Consistent operation format across all types
4. **Debuggability:** Preserve source location information
5. **Extensibility:** Easy to add new operations for new features

### IR Structure

```
Program IR
  ├── GlobalVariables
  │   └── [IR Variables with initial values]
  │
  ├── Functions
  │   └── FunctionIR
  │       ├── Name & Type
  │       ├── Parameters
  │       ├── BasicBlocks
  │       │   └── Instructions
  │       └── LocalVariables
  │
  ├── Types
  │   └── Custom type definitions
  │
  └── Constants
      └── Global constants
```

---

## IR Concepts

### Basic Blocks

A **basic block** is a sequence of instructions with:
- Single entry point (start of block)
- Single exit point (end of block)
- No branches except at end

```
BasicBlock {
    label: string;              // e.g., "block_1", "loop_header"
    instructions: Instruction[];
    terminator: TerminatorInst; // branch, return, throw
}
```

### Virtual Registers

Each value in IR is stored in a **virtual register**:

```
%0 = load uint256 @global_var
%1 = constant 42 : uint256
%2 = add %0, %1 : uint256
store %2 -> @global_var
```

Registers are:
- Infinite (unlimited supply)
- Unnamed (referred to by %)
- Typed (each has a known type)
- Immutable (assigned once, never changed)

### Single Assignment Form (SSA)

Each virtual register is assigned **exactly once**:

```
// Valid SSA:
%0 = constant 10 : uint256
%1 = constant 20 : uint256
%2 = add %0, %1 : uint256

// Invalid SSA (x assigned twice):
%x = constant 10 : uint256
%x = add %x, 5 : uint256  // ✗ violates SSA
```

Benefits:
- Makes data flow explicit
- Simplifies optimization
- Enables better analysis

### Instructions

Three-address instructions: `result = op(arg1, arg2)`

```
%2 = add %0, %1        // result = arg1 op arg2
%3 = load %2           // result = op(arg)
%4 = call @func(%0)    // result = op(args...)
jump @block_2          // control flow
```

---

## IR Operations

### Literal Operations

```
// Integer literals
%0 = constant 42 : uint256
%1 = constant -5 : int256

// Boolean literals
%2 = constant true : bool
%3 = constant false : bool

// String literals
%4 = constant "hello" : string

// Address literals
%5 = constant 0x1234... : address

// Array literals
%6 = array [%0, %1, %2] : uint256[]

// Null/None
%7 = constant null : void
```

### Arithmetic Operations

```
// Addition, subtraction, multiplication
%0 = add %a, %b : uint256
%1 = sub %a, %b : int256
%2 = mul %a, %b : uint256

// Division, modulo
%3 = div %a, %b : uint256
%4 = mod %a, %b : uint256

// Bitwise operations
%5 = and %a, %b : uint256
%6 = or %a, %b : uint256
%7 = xor %a, %b : uint256
%8 = shl %a, %b : uint256  // shift left
%9 = shr %a, %b : uint256  // shift right

// Unary operations
%10 = neg %a : int256       // negate
%11 = not %a : bool         // boolean not
%12 = bitnot %a : uint256   // bitwise not
```

### Comparison Operations

```
// Returns bool
%0 = eq %a, %b : bool       // equal
%1 = ne %a, %b : bool       // not equal
%2 = lt %a, %b : bool       // less than
%3 = le %a, %b : bool       // less than or equal
%4 = gt %a, %b : bool       // greater than
%5 = ge %a, %b : bool       // greater than or equal
```

### Memory Operations

```
// Load from global state
%0 = load @state_var : uint256
%1 = load_field %struct, "field_name" : uint256

// Store to global state
store %value -> @state_var : uint256
store_field %struct, "field_name" <- %value : uint256

// Load from array
%2 = load_elem %array, %index : uint256

// Store to array
store_elem %array, %index <- %value : uint256

// Get address of variable
%3 = addr_of @var : address
```

### Type Operations

```
// Type casting
%0 = cast %value : uint256 -> int256
%1 = cast %value : address -> uint256

// Get type information (compile-time only)
%2 = typeof %value

// Array operations
%3 = array_len %array : uint256
%4 = array_alloc %size : uint256[]

// Struct operations
%5 = struct_create Point { x: %a, y: %b } : Point
%6 = struct_field %point, "x" : uint256
```

### Control Flow Operations

```
// Unconditional jump
jump @target_block

// Conditional branch
branch %condition, @true_block, @false_block

// Function call
%0 = call @function(%arg1, %arg2) : uint256
%1 = call_method %obj, "method", (%args) : uint256

// Return from function
return %value : uint256
return void

// Exception handling
throw %exception
try_enter @try_block, @catch_block
try_exit
```

### Function Operations

```
// Function parameter
arg %param_name : uint256

// Local variable allocation
%0 = alloca : uint256*

// Variable definition
define %var_name : uint256

// Function entry
entry:
  param %arg0 : uint256
  param %arg1 : uint256
  ...
```

---

## Memory Model

### Global State

```
// In OMEGA source:
blockchain MyContract {
    state counter: uint256;
    state owner: address;
}

// In IR:
@counter : uint256 = 0        // global variable
@owner : address = null       // global variable

// Access in IR:
%0 = load @counter : uint256
store %new_value -> @counter : uint256
```

### Local Variables

```
// In OMEGA source:
function add(x: uint256, y: uint256) -> uint256 {
    let result: uint256 = x + y;
    return result;
}

// In IR:
@function_add:
  entry:
    param %x : uint256
    param %y : uint256
    %result_addr = alloca : uint256*
    %0 = add %x, %y : uint256
    store %0 -> %result_addr
    %1 = load %result_addr : uint256
    return %1 : uint256
```

### Arrays and Structures

```
// Array in memory:
%arr = array_alloc 10 : uint256[]
store_elem %arr, 0 <- %value : uint256
%loaded = load_elem %arr, 0 : uint256

// Struct in memory:
%point = struct_create Point { x: %a, y: %b } : Point
%x = struct_field %point, "x" : uint256
```

---

## Control Flow

### Linear Flow

```
block_0:
  %0 = constant 42 : uint256
  %1 = add %0, %0 : uint256
  jump @block_1

block_1:
  %2 = mul %1, 2 : uint256
  return %2 : uint256
```

### Conditional Flow

```
block_0:
  %0 = load @flag : bool
  branch %0, @block_true, @block_false

block_true:
  %1 = constant 100 : uint256
  jump @block_merge

block_false:
  %2 = constant 50 : uint256
  jump @block_merge

block_merge:
  %3 = phi [%1, @block_true], [%2, @block_false] : uint256
  return %3 : uint256
```

### Loop Control

```
block_0:
  %i = constant 0 : uint256
  jump @loop_header

loop_header:
  %n = constant 10 : uint256
  %cond = lt %i, %n : bool
  branch %cond, @loop_body, @loop_exit

loop_body:
  %0 = load %i : uint256
  %1 = add %0, 1 : uint256
  store %1 -> %i
  jump @loop_header

loop_exit:
  return void
```

### Phi Nodes

Used to merge values from different paths:

```
%result = phi [%val1, @block_a], [%val2, @block_b] : uint256
```

The result gets:
- `%val1` if coming from `block_a`
- `%val2` if coming from `block_b`

---

## Function Representation

### Function Definition

```
@function_name (params) -> return_type {
  entry:
    param %param1 : type1
    param %param2 : type2
    
  block_0:
    %0 = operation
    ...
    
  block_1:
    return %value : return_type
}
```

### Function Calls

```
// Direct function call
%result = call @function(%arg1, %arg2) : return_type

// Method call on object
%result = call_method %object, "method_name", (%arg1, %arg2) : return_type

// Builtin function
%result = call @builtin_print(%value) : void
```

### Function Prologue/Epilogue

Generated by code generator:

```
// Prologue (function entry)
  save registers
  allocate stack space
  move parameters
  
// Epilogue (function exit)
  save return value
  deallocate stack
  restore registers
  return to caller
```

---

## Data Types in IR

### Primitive Types

```
uint8, uint16, ..., uint256      // Unsigned integers
int8, int16, ..., int256         // Signed integers
bool                              // Boolean
address                           // Address (256-bit)
string                            // String (dynamic)
bytes                             // Bytes (dynamic)
bytes1, bytes2, ..., bytes32      // Fixed bytes
void                              // No type (functions)
```

### Composite Types

```
uint256[]                  // Array of uint256
Point                      // Struct named Point
MyStruct[]                 // Array of MyStruct
uint256[10]                // Fixed-size array
```

### Type Annotations

All IR values are explicitly typed:

```
%0 = constant 42 : uint256        // type: uint256
%1 = load @var : string           // type: string
%2 = add %0, %0 : uint256         // type: uint256
```

---

## Examples

### Example 1: Simple Addition

```
// OMEGA source:
function add(x: uint256, y: uint256) -> uint256 {
    return x + y;
}

// IR generated:
@function_add (uint256, uint256) -> uint256 {
  entry:
    param %x : uint256
    param %y : uint256
    %sum = add %x, %y : uint256
    return %sum : uint256
}
```

### Example 2: If Statement

```
// OMEGA source:
function max(a: uint256, b: uint256) -> uint256 {
    if (a > b) {
        return a;
    } else {
        return b;
    }
}

// IR generated:
@function_max (uint256, uint256) -> uint256 {
  entry:
    param %a : uint256
    param %b : uint256
    %cond = gt %a, %b : bool
    branch %cond, @block_if, @block_else
    
  block_if:
    jump @block_merge
    
  block_else:
    jump @block_merge
    
  block_merge:
    %result = phi [%a, @block_if], [%b, @block_else] : uint256
    return %result : uint256
}
```

### Example 3: Loop

```
// OMEGA source:
function sum(n: uint256) -> uint256 {
    let total: uint256 = 0;
    for (let i: uint256 = 0; i < n; i = i + 1) {
        total = total + i;
    }
    return total;
}

// IR generated:
@function_sum (uint256) -> uint256 {
  entry:
    param %n : uint256
    %total_addr = alloca : uint256*
    %zero = constant 0 : uint256
    store %zero -> %total_addr
    %i_addr = alloca : uint256*
    store %zero -> %i_addr
    jump @loop_header
    
  loop_header:
    %i = load %i_addr : uint256
    %cond = lt %i, %n : bool
    branch %cond, @loop_body, @loop_exit
    
  loop_body:
    %total = load %total_addr : uint256
    %i2 = load %i_addr : uint256
    %new_total = add %total, %i2 : uint256
    store %new_total -> %total_addr
    %i3 = load %i_addr : uint256
    %one = constant 1 : uint256
    %new_i = add %i3, %one : uint256
    store %new_i -> %i_addr
    jump @loop_header
    
  loop_exit:
    %result = load %total_addr : uint256
    return %result : uint256
}
```

### Example 4: State Modification

```
// OMEGA source:
blockchain Counter {
    state count: uint256;
    
    function increment() {
        count = count + 1;
    }
}

// IR generated:
@count : uint256 = 0

@function_increment () -> void {
  entry:
    %current = load @count : uint256
    %one = constant 1 : uint256
    %next = add %current, %one : uint256
    store %next -> @count : uint256
    return void
}
```

---

## Optimization Hooks

The IR is designed to enable multiple optimization passes:

### 1. Constant Folding

```
// Before optimization:
%0 = constant 10 : uint256
%1 = constant 20 : uint256
%2 = add %0, %1 : uint256

// After constant folding:
%2 = constant 30 : uint256
```

### 2. Dead Code Elimination

```
// Before optimization:
%0 = constant 100 : uint256
%1 = constant 200 : uint256
%2 = add %0, %1 : uint256   // %2 is never used
return %1 : uint256

// After dead code elimination:
%1 = constant 200 : uint256
return %1 : uint256
```

### 3. Common Subexpression Elimination

```
// Before optimization:
%0 = load @var : uint256
%1 = mul %0, 2 : uint256
%2 = load @var : uint256
%3 = mul %2, 2 : uint256    // same as %1

// After CSE:
%0 = load @var : uint256
%1 = mul %0, 2 : uint256
%3 = %1                     // reuse %1
```

### 4. Register Allocation Hints

```
// IR with hints for code generator:
%0 = constant 42 : uint256
%1 = add %0, %0 : uint256   // use same register as %0
%2 = mul %1, 2 : uint256    // %2 lives long, allocate register
```

---

## IR Validation

The IR must satisfy:

1. **SSA Property:** Each register assigned exactly once
2. **Type Consistency:** All operations type-correct
3. **Dominance:** All predecessors reach a block through same path
4. **Liveness:** Variables used before definition in all paths

Validators should check these properties and report violations.

---

## Phase 4 Tasks Using This IR

### Task 2: IR Generator
- **Input:** Validated AST from Phase 3
- **Output:** Complete IR
- **Process:** AST → IR translation with control flow analysis

### Task 3: Code Generator
- **Input:** Complete IR
- **Output:** Target code (EVM, JavaScript, Solidity)
- **Process:** IR → Target code translation

### Task 4: Optimizer
- **Input:** Complete IR
- **Output:** Optimized IR
- **Process:** Optimization passes on IR

### Task 5: Linker
- **Input:** Generated code and symbols
- **Output:** Executable package
- **Process:** Link references and package

---

## Implementation Checklist

- [ ] IR data structure definitions
- [ ] IR operation types (enum)
- [ ] IR instruction types
- [ ] IR builder utilities
- [ ] IR validation functions
- [ ] IR printer (for debugging)
- [ ] Test suite for IR
- [ ] Documentation and examples

---

*End of OMEGA IR Specification*
