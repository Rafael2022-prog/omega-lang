# OMEGA Compiler Architecture

> Catatan Penting (Windows Native-Only, Compile-Only)
> - Dokumentasi ini menggambarkan arsitektur lengkap. Namun, pada CI Windows-only saat ini, CLI wrapper mendukung kompilasi file tunggal (compile-only).
> - Gunakan `build_omega_native.ps1` untuk build, jalankan `./omega.exe` atau `pwsh -NoProfile -ExecutionPolicy Bypass -File ./omega.ps1`.
> - Untuk debugging/eksperimen, Anda dapat memakai Native Runner (`scripts/omega_native_runner.ps1`) dan endpoint `POST /compile`.
> - Perintah `omega build/test/deploy` di halaman ini bersifat forward-looking; gunakan `omega compile <file.mega>` sebagai alternatif untuk verifikasi dasar.

Dokumentasi arsitektur compiler OMEGA yang menjelaskan desain internal, pipeline kompilasi, dan implementasi cross-chain code generation.

## 📋 Table of Contents

1. [Overview](#overview)
2. [Compiler Pipeline](#compiler-pipeline)
3. [Core Components](#core-components)
4. [Intermediate Representation (IR)](#intermediate-representation-ir)
5. [Code Generation](#code-generation)
6. [Optimization](#optimization)
7. [Target-Specific Backends](#target-specific-backends)
8. [Configuration System](#configuration-system)
9. [Caching and Performance](#caching-and-performance)
10. [Error Handling](#error-handling)

## Overview

OMEGA compiler adalah multi-target compiler yang mentranslasi kode OMEGA (`.mega` files) ke berbagai blockchain targets. Arsitektur compiler dirancang dengan prinsip:

- **Modular Design**: Setiap komponen dapat dikembangkan dan ditest secara independen
- **Extensible**: Mudah menambahkan target blockchain baru
- **Performance**: Optimasi untuk kecepatan kompilasi dan kualitas output
- **Type Safety**: Strong type system dengan compile-time verification
- **Cross-Chain Compatibility**: Abstraksi yang konsisten untuk berbagai blockchain

```
┌─────────────────┐    ┌──────────────┐    ┌─────────────────┐
│   .mega files   │───▶│    OMEGA     │───▶│  Target Code    │
│                 │    │   Compiler   │    │ (Sol/Rust/Go)   │
└─────────────────┘    └──────────────┘    └─────────────────┘
```

## Compiler Pipeline

OMEGA compiler menggunakan multi-stage pipeline yang memproses kode sumber melalui beberapa tahap transformasi:

```
Source Code (.mega)
        │
        ▼
┌───────────────┐
│    Lexer      │ ◄── Tokenization
└───────┬───────┘
        │
        ▼
┌───────────────┐
│    Parser     │ ◄── AST Generation
└───────┬───────┘
        │
        ▼
┌───────────────┐
│   Semantic    │ ◄── Type Checking & Analysis
│   Analyzer    │
└───────┬───────┘
        │
        ▼
┌───────────────┐
│ IR Generator  │ ◄── Intermediate Representation
└───────┬───────┘
        │
        ▼
┌───────────────┐
│  Optimizer    │ ◄── Code Optimization
└───────┬───────┘
        │
        ▼
┌───────────────┐
│ Code Generator│ ◄── Target-Specific Code
└───────────────┘
        │
        ▼
┌─────────────────────────────────┐
│  EVM     │ Solana  │  Cosmos   │
│ (Solidity)│ (Rust)  │   (Go)    │
└─────────────────────────────────┘
```

### Pipeline Stages

1. **Lexical Analysis**: Mengkonversi source code menjadi tokens
2. **Parsing**: Membangun Abstract Syntax Tree (AST)
3. **Semantic Analysis**: Type checking, symbol resolution, dan validasi
4. **IR Generation**: Konversi AST ke Intermediate Representation
5. **Optimization**: Berbagai optimasi pada IR level
6. **Code Generation**: Menghasilkan target-specific code

## Core Components

OMEGA compiler terdiri dari beberapa modul inti yang telah direfactor untuk meningkatkan maintainability dan extensibility:

### 1. Lexer (`src/lexer/lexer.mega`)

Lexer bertanggung jawab untuk tokenization:

```rust
pub struct Lexer {
    input: String,
    position: usize,
    current_char: Option<char>,
    line: usize,
    column: usize,
}

pub enum Token {
    // Keywords
    Blockchain, Contract, Function, Let, Mut, Pub,
    
    // Types
    U8, U16, U32, U64, U128, U256,
    I8, I16, I32, I64, I128, I256,
    Bool, String, Address, Hash,
    
    // Operators
    Plus, Minus, Multiply, Divide, Modulo,
    Assign, Equal, NotEqual, Less, Greater,
    
    // Delimiters
    LeftParen, RightParen, LeftBrace, RightBrace,
    LeftBracket, RightBracket, Semicolon, Comma,
    
    // Literals
    IntegerLiteral(String),
    StringLiteral(String),
    BooleanLiteral(bool),
    AddressLiteral(String),
    
    // Special
    Identifier(String),
    EOF,
}
```

**Features:**
- Unicode support untuk identifiers
- Precise error location tracking
- Efficient string interning
- Support untuk blockchain-specific literals (addresses, hashes)

### 2. Parser (`src/parser/parser.mega`)

Parser membangun AST dari token stream:

```rust
pub enum ASTNode {
    Program {
        blockchain_targets: Vec<String>,
        imports: Vec<ImportNode>,
        contracts: Vec<ContractNode>,
    },
    
    Contract {
        name: String,
        state_variables: Vec<StateVariableNode>,
        functions: Vec<FunctionNode>,
        events: Vec<EventNode>,
        modifiers: Vec<ModifierNode>,
    },
    
    Function {
        name: String,
        parameters: Vec<ParameterNode>,
        return_type: Option<TypeNode>,
        visibility: Visibility,
        modifiers: Vec<String>,
        body: BlockNode,
    },
    
    // ... other node types
}
```

**Parsing Strategy:**
- Recursive descent parser
- Operator precedence parsing untuk expressions
- Error recovery untuk better error messages
- Support untuk blockchain-specific syntax

### 3. Semantic Analyzer (`src/semantic/analyzer.mega`)

Semantic analyzer melakukan type checking dan validasi:

```rust
pub struct SemanticAnalyzer {
    symbol_table: SymbolTable,
    type_checker: TypeChecker,
    current_scope: ScopeId,
    errors: Vec<SemanticError>,
}

pub struct TypeChecker {
    builtin_types: HashMap<String, Type>,
    user_defined_types: HashMap<String, Type>,
    function_signatures: HashMap<String, FunctionSignature>,
}
```

**Responsibilities:**
- Symbol resolution dan scope management
- Type inference dan checking
- Function signature validation
- Blockchain-specific constraint checking
- Dead code detection

### 4. IR Core Module (`src/ir/ir_core.mega`)

**🆕 REFACTORED MODULE** - Modul IR yang telah direfactor untuk struktur yang lebih modular:

```rust
pub struct OmegaIR {
    config: IRConfig,
    current_module: Option<IRModule>,
    symbol_table: IRSymbolTable,
    type_system: IRTypeSystem,
    statistics: IRStatistics,
    errors: Vec<IRError>,
    warnings: Vec<IRWarning>,
}

pub struct IRModule {
    name: String,
    version: String,
    metadata: IRMetadata,
    blockchains: Vec<IRBlockchain>,
    functions: Vec<IRFunction>,
    types: Vec<IRType>,
    constants: Vec<IRConstant>,
}

pub struct IRBlockchain {
    name: String,
    state_variables: Vec<IRStateVariable>,
    functions: Vec<IRFunction>,
    events: Vec<IREvent>,
    constructor: Option<IRFunction>,
    metadata: IRBlockchainMetadata,
}
```

**Key Features:**
- Modular IR generation dengan clear separation of concerns
- Comprehensive error handling dan validation
- Built-in statistics tracking
- Extensible type system
- Memory-efficient representation

### 5. Optimizer Core Module (`src/optimizer/optimizer_core.mega`)

**🆕 REFACTORED MODULE** - Sistem optimasi yang telah direfactor dengan arsitektur pass-based:

```rust
pub struct OmegaOptimizer {
    config: OptimizationConfig,
    registered_passes: HashMap<String, Box<dyn OptimizationPass>>,
    pass_manager: PassManager,
    statistics: OptimizationStats,
    cache: OptimizationCache,
}

pub struct OptimizationConfig {
    level: OptimizationLevel,
    target: OptimizationTarget,
    aggressive_mode: bool,
    enabled_passes: HashSet<String>,
    pass_priorities: HashMap<String, u32>,
}

pub enum OptimizationLevel {
    None,
    Basic,
    Aggressive,
}

pub trait OptimizationPass {
    fn name(&self) -> &str;
    fn description(&self) -> &str;
    fn priority(&self) -> u32;
    fn run(&self, module: &mut IRModule) -> OptimizationResult;
    fn is_applicable(&self, module: &IRModule) -> bool;
}
```

**Available Optimization Passes:**
- **Constant Folding Pass**: Evaluasi konstanta pada compile time
- **Dead Code Elimination Pass**: Penghapusan kode yang tidak terpakai
- **Peephole Optimizer Pass**: Optimasi lokal pada instruction sequences
- **Loop Optimizer Pass**: Optimasi loop termasuk unrolling dan invariant motion

### 6. Code Generator Module (`src/codegen/codegen.mega`)

**🆕 REFACTORED MODULE** - Generator kode yang telah direfactor untuk multi-target support:

```rust
pub struct OmegaCodeGenerator {
    config: CodeGenConfig,
    registered_generators: HashMap<String, Box<dyn PlatformCodeGenerator>>,
    template_engine: TemplateEngine,
    statistics: CodeGenStatistics,
    cache: CodeGenCache,
}

pub struct GenerationResult {
    success: bool,
    generated_files: Vec<GeneratedFile>,
    target_statistics: HashMap<String, TargetStats>,
    errors: Vec<CodeGenError>,
    warnings: Vec<CodeGenWarning>,
}

pub trait PlatformCodeGenerator {
    fn platform_name(&self) -> &str;
    fn supported_features(&self) -> Vec<String>;
    fn generate(&self, module: &IRModule) -> Result<Vec<GeneratedFile>>;
    fn validate_ir(&self, module: &IRModule) -> Result<()>;
}
```

**Supported Platforms:**
- **EVM Generator**: Solidity code generation dengan gas optimization
- **Solana Generator**: Rust/Anchor code generation
- **Cosmos Generator**: Go/Cosmos SDK code generation
- **Move Generator**: Move language code generation

### 7. Symbol Table (`src/semantic/analyzer.mega`)

Hierarchical symbol table untuk scope management:

```rust
pub struct SymbolTable {
    scopes: Vec<Scope>,
    current_scope: ScopeId,
    global_scope: ScopeId,
}

pub struct Scope {
    id: ScopeId,
    parent: Option<ScopeId>,
    symbols: HashMap<String, Symbol>,
    scope_type: ScopeType,
}

pub enum Symbol {
    Variable {
        name: String,
        type_info: Type,
        mutability: Mutability,
        location: SourceLocation,
    },
    Function {
        name: String,
        signature: FunctionSignature,
        visibility: Visibility,
        location: SourceLocation,
    },
    Contract {
        name: String,
        fields: Vec<Symbol>,
        methods: Vec<Symbol>,
        location: SourceLocation,
    },
}
```

## Intermediate Representation (IR)

**🆕 UPDATED ARCHITECTURE** - OMEGA IR telah direfactor menjadi sistem modular yang lebih powerful:

### IR Core Architecture

```rust
// Core IR Module Structure
pub struct OmegaIR {
    config: IRConfig,
    current_module: Option<IRModule>,
    symbol_table: IRSymbolTable,
    type_system: IRTypeSystem,
    statistics: IRStatistics,
    errors: Vec<IRError>,
    warnings: Vec<IRWarning>,
}

// IR Configuration
pub struct IRConfig {
    target_platforms: Vec<String>,
    optimization_hints: OptimizationHints,
    debug_info: bool,
    validation_level: ValidationLevel,
}

// IR Module - Top-level container
pub struct IRModule {
    name: String,
    version: String,
    metadata: IRMetadata,
    blockchains: Vec<IRBlockchain>,
    functions: Vec<IRFunction>,
    types: Vec<IRType>,
    constants: Vec<IRConstant>,
    imports: Vec<IRImport>,
}
```

### IR Node Types

OMEGA IR menggunakan hierarki node yang comprehensive:

```rust
pub enum IRNode {
    // Top-level constructs
    Module(IRModule),
    Blockchain(IRBlockchain),
    Function(IRFunction),
    
    // Statements
    Assignment(IRAssignment),
    FunctionCall(IRFunctionCall),
    Return(IRReturn),
    If(IRIf),
    While(IRWhile),
    For(IRFor),
    
    // Expressions
    Binary(IRBinary),
    Unary(IRUnary),
    Literal(IRLiteral),
    Variable(IRVariable),
    FieldAccess(IRFieldAccess),
    ArrayAccess(IRArrayAccess),
    
    // Blockchain-specific
    StateAccess(IRStateAccess),
    EventEmit(IREventEmit),
    CrossChainCall(IRCrossChainCall),
}

pub struct IRFunction {
    name: String,
    parameters: Vec<IRParameter>,
    return_type: Option<IRType>,
    visibility: IRVisibility,
    modifiers: Vec<IRModifier>,
    body: Vec<IRStatement>,
    metadata: IRFunctionMetadata,
}

pub struct IRBlockchain {
    name: String,
    state_variables: Vec<IRStateVariable>,
    functions: Vec<IRFunction>,
    events: Vec<IREvent>,
    constructor: Option<IRFunction>,
    metadata: IRBlockchainMetadata,
}
```

### Type System Integration

```rust
pub struct IRTypeSystem {
    builtin_types: HashMap<String, IRType>,
    user_types: HashMap<String, IRType>,
    type_aliases: HashMap<String, IRType>,
    generic_constraints: HashMap<String, Vec<IRTypeConstraint>>,
}

pub enum IRType {
    // Primitive types
    Integer { bits: u32, signed: bool },
    Boolean,
    String,
    Address,
    Hash,
    
    // Complex types
    Array { element_type: Box<IRType>, size: Option<u64> },
    Mapping { key_type: Box<IRType>, value_type: Box<IRType> },
    Struct { name: String, fields: Vec<IRField> },
    Enum { name: String, variants: Vec<IREnumVariant> },
    
    // Blockchain-specific
    Contract { name: String },
    Event { name: String, fields: Vec<IRField> },
    
    // Generic types
    Generic { name: String, constraints: Vec<IRTypeConstraint> },
}
```

### IR Generation Process

**🆕 IMPROVED PIPELINE** - Proses generasi IR yang telah diperbaiki:

```rust
impl OmegaIR {
    pub fn generate_from_ast(&mut self, ast: &ASTNode) -> Result<IRModule> {
        // 1. Initialize new module
        let mut module = IRModule::new();
        
        // 2. Process imports and dependencies
        self.process_imports(&ast, &mut module)?;
        
        // 3. Generate type definitions
        self.generate_types(&ast, &mut module)?;
        
        // 4. Generate blockchain contracts
        self.generate_blockchains(&ast, &mut module)?;
        
        // 5. Generate global functions
        self.generate_functions(&ast, &mut module)?;
        
        // 6. Validate IR consistency
        self.validate_module(&module)?;
        
        // 7. Update statistics
        self.update_statistics(&module);
        
        Ok(module)
    }
    
    fn generate_blockchains(&mut self, ast: &ASTNode, module: &mut IRModule) -> Result<()> {
        for contract in ast.get_contracts() {
            let ir_blockchain = self.convert_contract_to_blockchain(contract)?;
            module.blockchains.push(ir_blockchain);
        }
        Ok(())
    }
    
    fn validate_module(&self, module: &IRModule) -> Result<()> {
        // Type checking
        self.validate_types(module)?;
        
        // Function signature validation
        self.validate_function_signatures(module)?;
        
        // Cross-reference validation
        self.validate_cross_references(module)?;
        
        // Blockchain-specific validation
        self.validate_blockchain_constraints(module)?;
        
        Ok(())
    }
}
```

### IR Optimization Integration

IR terintegrasi dengan sistem optimasi yang baru:

```rust
pub struct IROptimizationContext {
    module: IRModule,
    optimization_level: OptimizationLevel,
    target_hints: TargetHints,
    statistics: OptimizationStats,
}

impl IROptimizationContext {
    pub fn apply_optimizations(&mut self, optimizer: &OmegaOptimizer) -> Result<()> {
        // Apply optimization passes
        let passes = optimizer.get_applicable_passes(&self.module);
        
        for pass in passes {
            if pass.is_applicable(&self.module) {
                let result = pass.run(&mut self.module)?;
                self.statistics.merge(result.statistics);
            }
        }
        
        Ok(())
    }
}
```

### Benefits of New IR Architecture

1. **Modularity**: Clear separation antara IR generation, optimization, dan code generation
2. **Extensibility**: Mudah menambahkan node types dan transformations baru
3. **Type Safety**: Strong typing system dengan comprehensive validation
4. **Performance**: Memory-efficient representation dengan lazy evaluation
5. **Debugging**: Rich metadata untuk debugging dan error reporting
6. **Cross-Platform**: Platform-agnostic representation yang mudah ditargetkan ke berbagai blockchain

### IR Statistics and Metrics

```rust
pub struct IRStatistics {
    nodes_generated: u64,
    functions_processed: u64,
    types_defined: u64,
    optimizations_applied: u64,
    memory_usage: u64,
    generation_time: Duration,
}

impl IRStatistics {
    pub fn report(&self) -> String {
        format!(
            "IR Generation Stats:\n\
             - Nodes: {}\n\
             - Functions: {}\n\
             - Types: {}\n\
             - Memory: {} KB\n\
             - Time: {:?}",
            self.nodes_generated,
            self.functions_processed,
            self.types_defined,
            self.memory_usage / 1024,
            self.generation_time
        )
    }
}
```

## Code Generation

**🆕 REFACTORED ARCHITECTURE** - Sistem code generation yang telah direfactor dengan arsitektur modular:

### Core Code Generation Architecture

```rust
pub struct OmegaCodeGenerator {
    config: CodeGenConfig,
    registered_generators: HashMap<String, Box<dyn PlatformCodeGenerator>>,
    template_engine: TemplateEngine,
    statistics: CodeGenStatistics,
    cache: CodeGenCache,
}

pub struct CodeGenConfig {
    target_platforms: Vec<String>,
    output_directory: String,
    optimization_level: OptimizationLevel,
    debug_info: bool,
    template_paths: Vec<String>,
}

pub trait PlatformCodeGenerator {
    fn platform_name(&self) -> &str;
    fn supported_features(&self) -> Vec<String>;
    fn generate(&self, module: &IRModule) -> Result<Vec<GeneratedFile>>;
    fn validate_ir(&self, module: &IRModule) -> Result<()>;
    fn get_dependencies(&self) -> Vec<String>;
}
```

### Generation Result Structure

```rust
pub struct GenerationResult {
    success: bool,
    generated_files: Vec<GeneratedFile>,
    target_statistics: HashMap<String, TargetStats>,
    errors: Vec<CodeGenError>,
    warnings: Vec<CodeGenWarning>,
}

pub struct GeneratedFile {
    path: String,
    content: String,
    file_type: FileType,
    target_platform: String,
    metadata: FileMetadata,
}

pub struct TargetStats {
    files_generated: u32,
    lines_of_code: u32,
    binary_size_estimate: u64,
    compilation_time: Duration,
    dependencies: Vec<String>,
}
```

### Platform-Specific Generators

#### 1. EVM Code Generator

```rust
pub struct EVMCodeGenerator {
    config: EVMConfig,
    solidity_version: String,
    gas_optimizer: GasOptimizer,
    template_engine: SolidityTemplateEngine,
}

impl PlatformCodeGenerator for EVMCodeGenerator {
    fn platform_name(&self) -> &str { "evm" }
    
    fn generate(&self, module: &IRModule) -> Result<Vec<GeneratedFile>> {
        let mut files = Vec::new();
        
        // Generate main contract files
        for blockchain in &module.blockchains {
            let solidity_code = self.generate_solidity_contract(blockchain)?;
            files.push(GeneratedFile {
                path: format!("{}.sol", blockchain.name),
                content: solidity_code,
                file_type: FileType::Solidity,
                target_platform: "evm".to_string(),
                metadata: FileMetadata::new(),
            });
        }
        
        // Generate deployment scripts
        let deployment_script = self.generate_deployment_script(module)?;
        files.push(GeneratedFile {
            path: "deploy.js".to_string(),
            content: deployment_script,
            file_type: FileType::JavaScript,
            target_platform: "evm".to_string(),
            metadata: FileMetadata::new(),
        });
        
        // Generate package.json
        let package_json = self.generate_package_json(module)?;
        files.push(GeneratedFile {
            path: "package.json".to_string(),
            content: package_json,
            file_type: FileType::JSON,
            target_platform: "evm".to_string(),
            metadata: FileMetadata::new(),
        });
        
        Ok(files)
    }
    
    fn validate_ir(&self, module: &IRModule) -> Result<()> {
        // Validate EVM-specific constraints
        self.validate_gas_limits(module)?;
        self.validate_storage_layout(module)?;
        self.validate_function_signatures(module)?;
        Ok(())
    }
}

impl EVMCodeGenerator {
    fn generate_solidity_contract(&self, blockchain: &IRBlockchain) -> Result<String> {
        let mut code = String::new();
        
        // SPDX license and pragma
        code.push_str("// SPDX-License-Identifier: MIT\n");
        code.push_str(&format!("pragma solidity {};\n\n", self.solidity_version));
        
        // Contract declaration
        code.push_str(&format!("contract {} {{\n", blockchain.name));
        
        // State variables
        for state_var in &blockchain.state_variables {
            code.push_str(&self.generate_state_variable(state_var)?);
        }
        
        // Events
        for event in &blockchain.events {
            code.push_str(&self.generate_event(event)?);
        }
        
        // Constructor
        if let Some(constructor) = &blockchain.constructor {
            code.push_str(&self.generate_constructor(constructor)?);
        }
        
        // Functions
        for function in &blockchain.functions {
            code.push_str(&self.generate_function(function)?);
        }
        
        code.push_str("}\n");
        
        // Apply gas optimizations
        code = self.gas_optimizer.optimize_code(code)?;
        
        Ok(code)
    }
}
```

#### 2. Solana Code Generator

```rust
pub struct SolanaCodeGenerator {
    config: SolanaConfig,
    anchor_version: String,
    template_engine: RustTemplateEngine,
}

impl PlatformCodeGenerator for SolanaCodeGenerator {
    fn platform_name(&self) -> &str { "solana" }
    
    fn generate(&self, module: &IRModule) -> Result<Vec<GeneratedFile>> {
        let mut files = Vec::new();
        
        // Generate lib.rs
        let lib_rs = self.generate_lib_rs(module)?;
        files.push(GeneratedFile {
            path: "src/lib.rs".to_string(),
            content: lib_rs,
            file_type: FileType::Rust,
            target_platform: "solana".to_string(),
            metadata: FileMetadata::new(),
        });
        
        // Generate Cargo.toml
        let cargo_toml = self.generate_cargo_toml(module)?;
        files.push(GeneratedFile {
            path: "Cargo.toml".to_string(),
            content: cargo_toml,
            file_type: FileType::TOML,
            target_platform: "solana".to_string(),
            metadata: FileMetadata::new(),
        });
        
        // Generate Anchor.toml
        let anchor_toml = self.generate_anchor_toml(module)?;
        files.push(GeneratedFile {
            path: "Anchor.toml".to_string(),
            content: anchor_toml,
            file_type: FileType::TOML,
            target_platform: "solana".to_string(),
            metadata: FileMetadata::new(),
        });
        
        Ok(files)
    }
}
```

### Template Engine System

```rust
pub struct TemplateEngine {
    templates: HashMap<String, Template>,
    template_cache: HashMap<String, CompiledTemplate>,
    config: TemplateConfig,
}

impl TemplateEngine {
    pub fn render(&self, template_name: &str, context: &TemplateContext) -> Result<String> {
        let template = self.get_compiled_template(template_name)?;
        template.render(context)
    }
    
    pub fn register_template(&mut self, name: String, content: String) -> Result<()> {
        let template = Template::compile(content)?;
        self.templates.insert(name.clone(), template);
        Ok(())
    }
}

pub struct TemplateContext {
    variables: HashMap<String, TemplateValue>,
    functions: HashMap<String, Box<dyn TemplateFunction>>,
}
```

## Optimization

**🆕 REFACTORED ARCHITECTURE** - Sistem optimasi yang telah direfactor dengan arsitektur pass-based yang modular:

### Core Optimization Architecture

```rust
pub struct OmegaOptimizer {
    config: OptimizationConfig,
    registered_passes: HashMap<String, Box<dyn OptimizationPass>>,
    pass_manager: PassManager,
    statistics: OptimizationStats,
    cache: OptimizationCache,
}

pub struct OptimizationConfig {
    level: OptimizationLevel,
    target: OptimizationTarget,
    aggressive_mode: bool,
    enabled_passes: HashSet<String>,
    pass_priorities: HashMap<String, u32>,
    max_iterations: u32,
}

pub enum OptimizationLevel {
    None,        // No optimizations
    Basic,       // Basic optimizations (constant folding, dead code elimination)
    Aggressive,  // All optimizations including experimental ones
}

pub enum OptimizationTarget {
    Size,        // Optimize for smaller code size
    Speed,       // Optimize for execution speed
    Gas,         // Optimize for lower gas consumption (EVM)
    Balanced,    // Balance between size and speed
}
```

### Optimization Pass System

```rust
pub trait OptimizationPass {
    fn name(&self) -> &str;
    fn description(&self) -> &str;
    fn priority(&self) -> u32;
    fn run(&self, module: &mut IRModule) -> OptimizationResult;
    fn is_applicable(&self, module: &IRModule) -> bool;
    fn dependencies(&self) -> Vec<String>;
    fn invalidates(&self) -> Vec<String>;
}

pub struct OptimizationResult {
    success: bool,
    transformations_applied: u32,
    instructions_eliminated: u32,
    performance_improvement: f64,
    statistics: PassStatistics,
    errors: Vec<OptimizationError>,
    warnings: Vec<OptimizationWarning>,
}

pub struct PassManager {
    passes: Vec<Box<dyn OptimizationPass>>,
    dependency_graph: DependencyGraph,
    execution_order: Vec<String>,
}
```

### Available Optimization Passes

#### 1. Constant Folding Pass

```rust
pub struct ConstantFoldingPass {
    config: ConstantFoldingConfig,
}

impl OptimizationPass for ConstantFoldingPass {
    fn name(&self) -> &str { "constant_folding" }
    
    fn run(&self, module: &mut IRModule) -> OptimizationResult {
        let mut result = OptimizationResult::new();
        
        for blockchain in &mut module.blockchains {
            for function in &mut blockchain.functions {
                result.merge(self.fold_constants_in_function(function));
            }
        }
        
        result
    }
}
```

#### 2. Dead Code Elimination Pass

```rust
pub struct DeadCodeEliminationPass {
    config: DeadCodeConfig,
}

impl OptimizationPass for DeadCodeEliminationPass {
    fn name(&self) -> &str { "dead_code_elimination" }
    
    fn run(&self, module: &mut IRModule) -> OptimizationResult {
        let mut result = OptimizationResult::new();
        
        // Build usage graph
        let usage_graph = self.build_usage_graph(module);
        
        // Mark reachable code
        let reachable = self.mark_reachable_code(&usage_graph);
        
        // Remove unreachable code
        result.instructions_eliminated = self.remove_unreachable_code(module, &reachable);
        
        result.success = true;
        result
    }
}
```

#### 3. Gas Optimization Pass (EVM-specific)

```rust
pub struct GasOptimizationPass {
    config: GasOptimizationConfig,
    gas_costs: HashMap<String, u64>,
}

impl OptimizationPass for GasOptimizationPass {
    fn name(&self) -> &str { "gas_optimization" }
    
    fn run(&self, module: &mut IRModule) -> OptimizationResult {
        let mut result = OptimizationResult::new();
        
        for blockchain in &mut module.blockchains {
            // Optimize storage access patterns
            result.merge(self.optimize_storage_access(blockchain));
            
            // Optimize function call patterns
            result.merge(self.optimize_function_calls(blockchain));
            
            // Optimize loop structures
            result.merge(self.optimize_loops(blockchain));
        }
        
        result
    }
}
```

### Optimization Statistics

```rust
pub struct OptimizationStats {
    total_passes_run: u32,
    total_transformations: u32,
    total_instructions_eliminated: u32,
    performance_improvement: f64,
    optimization_time: Duration,
    memory_usage: u64,
    pass_statistics: HashMap<String, PassStatistics>,
}

impl OptimizationStats {
    pub fn report(&self) -> String {
        format!(
            "Optimization Report:\n\
             - Passes Run: {}\n\
             - Transformations: {}\n\
             - Instructions Eliminated: {}\n\
             - Performance Improvement: {:.2}%\n\
             - Time: {:?}\n\
             - Memory: {} KB",
            self.total_passes_run,
            self.total_transformations,
            self.total_instructions_eliminated,
            self.performance_improvement * 100.0,
            self.optimization_time,
            self.memory_usage / 1024
        )
    }
}
```

## Configuration System

OMEGA menggunakan hierarchical configuration system:

```rust
pub struct Config {
    pub project: ProjectConfig,
    pub targets: TargetConfig,
    pub build: BuildConfig,
    pub networks: NetworkConfig,
    pub deployment: DeploymentConfig,
}

pub struct TargetConfig {
    pub evm: Option<EVMTargetConfig>,
    pub solana: Option<SolanaTargetConfig>,
    pub cosmos: Option<CosmosTargetConfig>,
}

pub struct EVMTargetConfig {
    pub enabled: bool,
    pub solidity_version: String,
    pub evm_version: String,
    pub optimization_runs: u32,
    pub libraries: Vec<String>,
}
```

Configuration sources (priority order):
1. Command line arguments
2. Environment variables
3. `omega.toml` file
4. Default values

## Caching and Performance

### Compilation Cache

```rust
pub struct CompilerCache {
    pub ast_cache: HashMap<PathBuf, ASTNode>,
    pub ir_cache: HashMap<PathBuf, OmegaIR>,
    pub dependency_graph: HashMap<PathBuf, Vec<PathBuf>>,
}
```

**Caching Strategy:**
- File-level AST caching dengan timestamp checking
- IR caching untuk expensive transformations
- Dependency tracking untuk incremental compilation
- Target-specific output caching

### Performance Optimizations

1. **Parallel Compilation**: Multiple files compiled concurrently
2. **Incremental Compilation**: Only recompile changed files
3. **Lazy Loading**: Load modules on-demand
4. **Memory Management**: Efficient memory usage untuk large projects

## Error Handling

OMEGA compiler menggunakan comprehensive error handling system:

```rust
pub enum CompilerError {
    LexerError(LexerError),
    ParserError(ParserError),
    SemanticError(SemanticError),
    IRError(IRError),
    CodeGenError(CodeGenError),
    ConfigError(ConfigError),
}

pub struct CompilerWarning {
    pub message: String,
    pub file: Option<PathBuf>,
    pub line: Option<usize>,
    pub column: Option<usize>,
    pub severity: WarningSeverity,
}
```

**Error Features:**
- Precise source location tracking
- Helpful error messages dengan suggestions
- Multiple error reporting
- Warning levels dan filtering
- IDE integration support

## Extension Points

OMEGA compiler dirancang untuk extensibility:

### Adding New Targets

1. Implement `CodeGenerator` trait
2. Add target-specific configuration
3. Register dalam compiler pipeline
4. Add tests dan documentation

### Custom Optimization Passes

1. Implement `OptimizationPass` trait
2. Register dalam optimizer
3. Configure execution order
4. Add performance benchmarks

### Language Extensions

1. Extend lexer untuk new tokens
2. Update parser grammar
3. Add semantic analysis rules
4. Update IR generation
5. Implement code generation

## Development Workflow

### Building the Compiler

```bash
# Debug build
cargo build

# Release build dengan optimizations
cargo build --release

# Run tests
cargo test

# Run benchmarks
cargo bench

# Generate documentation
cargo doc --open

> Catatan (Windows Native-Only, CI Windows-only):
> - Di pipeline CI Windows-only, gunakan `build_omega_native.ps1` untuk proses build native dan `scripts/generate_coverage.ps1` untuk laporan cakupan.
> - Perintah `cargo build/test/bench/doc` bersifat opsi untuk pengembangan lokal lintas platform dan mungkin tidak digunakan pada mode compile-only di CI.
```

### Testing Strategy

1. **Unit Tests**: Individual component testing
2. **Integration Tests**: End-to-end compilation testing
3. **Regression Tests**: Prevent breaking changes
4. **Performance Tests**: Compilation speed benchmarks
5. **Cross-Platform Tests**: Windows, macOS, Linux compatibility

### Debugging

Catatan (Windows Native-Only, Compile-Only): Gunakan `omega compile <file.mega>` untuk verifikasi karena `omega build` belum aktif di wrapper CLI pada mode ini. Anda juga dapat memanfaatkan Native Runner untuk observabilitas yang lebih baik.

```powershell
# Enable debug logging (PowerShell)
$env:RUST_LOG = 'debug'

# Compile single file (wrapper CLI)
omega compile contracts\examples\SimpleToken.mega

# Compile via Native Runner (HTTP)
# 1) Start runner
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts\omega_native_runner.ps1
# 2) POST code to /compile
Invoke-RestMethod -Method Post -Uri http://localhost:8080/compile -InFile contracts\examples\SimpleToken.mega -ContentType 'text/plain'
```

Forward-looking flags (belum aktif pada wrapper CLI):
- --dump-ast
- --dump-ir
- --verbose

Saat fitur-fitur tersebut tersedia, perintah akan berbentuk:
```bash
omega build --dump-ast
omega build --dump-ir
omega build --verbose
```

## Future Enhancements

### Planned Features

1. **Language Server Protocol (LSP)**: IDE integration
2. **Debugger Support**: Source-level debugging
3. **Hot Reloading**: Development server dengan auto-reload
4. **Package Manager**: Dependency management system
5. **Cross-Chain Bridges**: Automated bridge generation
6. **Formal Verification**: Mathematical proof generation
7. **WebAssembly Target**: WASM code generation
8. **More Blockchains**: Cardano, Tezos, Algorand support

### Performance Goals

- **Compilation Speed**: <1s untuk small projects, <10s untuk large projects
- **Memory Usage**: <500MB untuk typical projects
- **Code Quality**: Generated code performance within 5% of hand-written
- **Error Recovery**: Continue compilation after errors untuk better IDE experience

## Contributing

Untuk berkontribusi pada OMEGA compiler:

1. Fork repository
2. Create feature branch
3. Implement changes dengan tests
4. Update documentation
5. Submit pull request

Lihat [CONTRIBUTING.md](../CONTRIBUTING.md) untuk guidelines lengkap.

## References

- [OMEGA Language Specification](language-specification.md)
- [API Reference](api-reference.md)
- [Best Practices](best-practices.md)
- [Tutorials](tutorials/)

---

*Dokumentasi ini akan terus diupdate seiring perkembangan OMEGA compiler.*