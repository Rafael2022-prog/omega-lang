# OMEGA API Documentation

> Catatan (Windows Native-Only, Compile-Only)
> - Dokumentasi API ini mencakup interface penuh. Pada CI Windows-only saat ini, fokus alur kerja adalah kompilasi file tunggal (compile-only) melalui wrapper CLI dan Native Runner.
> - Gunakan `build_omega_native.ps1` untuk build, jalankan `./omega.exe` atau `pwsh -NoProfile -ExecutionPolicy Bypass -File ./omega.ps1`.
> - Endpoint Native Runner yang relevan: `POST /compile` untuk kompilasi/parse sederhana; `GET /version`, `GET /health`, `GET /info` untuk observasi.
> - Perintah `omega build/test/deploy` pada dokumen CLI bersifat forward-looking; gunakan `omega compile <file.mega>` untuk verifikasi dasar pada Windows.

## Overview

OMEGA Compiler menyediakan API yang komprehensif untuk parsing, kompilasi, dan code generation ke berbagai target blockchain. Dokumentasi ini mencakup semua public interfaces yang tersedia.

## Core Modules

### 1. Lexer Module (`omega::lexer`)

#### `struct Lexer`
Lexical analyzer untuk OMEGA source code.

```rust
pub struct Lexer {
    input: String,
    position: usize,
    current_char: Option<char>,
}
```

**Methods:**
- `new(input: String) -> Self` - Membuat lexer baru
- `next_token() -> Result<Token, LexError>` - Mengambil token berikutnya
- `peek_token() -> Result<Token, LexError>` - Melihat token berikutnya tanpa mengkonsumsi

### 2. IR Module (`omega::ir`)

#### `struct IRGenerator`
Mengkonversi AST menjadi Intermediate Representation.

```rust
pub struct IRGenerator {
    instructions: Vec<IRInstruction>,
    symbol_table: SymbolTable,
}
```

**Methods:**
- `new() -> Self` - Membuat IR generator baru
- `generate(program: &Program) -> Result<IRModule, IRError>` - Generate IR dari AST
- `optimize_ir(module: &mut IRModule) -> Result<(), IRError>` - Optimasi IR

#### `struct IRModule`
Representasi IR untuk seluruh program.

```rust
pub struct IRModule {
    pub functions: Vec<IRFunction>,
    pub globals: Vec<IRGlobal>,
    pub metadata: IRMetadata,
}
```

### 3. Optimizer Module (`omega::optimizer`)

#### `struct Optimizer`
Melakukan optimasi pada IR.

```rust
pub struct Optimizer {
    passes: Vec<Box<dyn OptimizationPass>>,
    level: OptimizationLevel,
}
```

**Methods:**
- `new(level: OptimizationLevel) -> Self` - Membuat optimizer baru
- `add_pass(pass: Box<dyn OptimizationPass>) -> &mut Self` - Tambah optimization pass
- `optimize(module: &mut IRModule) -> Result<(), OptimizerError>` - Jalankan optimasi

#### `trait OptimizationPass`
Interface untuk optimization passes.

```rust
pub trait OptimizationPass {
    fn run(&self, module: &mut IRModule) -> Result<bool, OptimizerError>;
    fn name(&self) -> &str;
}

#### `enum Token`
Representasi token dalam OMEGA.

```rust
pub enum Token {
    // Keywords
    Blockchain,
    State,
    Function,
    Constructor,
    Event,
    Mapping,
    
    // Types
    Address,
    Uint256,
    String,
    Bool,
    
    // Literals
    StringLiteral(String),
    NumberLiteral(u64),
    BoolLiteral(bool),
    
    // Operators
    Plus,
    Minus,
    Multiply,
    Divide,
    Assign,
    Equal,
    NotEqual,
    
    // Delimiters
    LeftParen,
    RightParen,
    LeftBrace,
    RightBrace,
    Semicolon,
    Comma,
    
    // Special
    Identifier(String),
    EOF,
}
```

### 2. Parser Module (`omega::parser`)

#### `struct Parser`
Syntax analyzer yang mengkonversi tokens menjadi AST.

```rust
pub struct Parser {
    lexer: Lexer,
    current_token: Token,
}
```

**Methods:**
- `new(lexer: Lexer) -> Result<Self, ParseError>` - Membuat parser baru
- `parse() -> Result<Program, ParseError>` - Parse seluruh program
- `parse_blockchain() -> Result<BlockchainDecl, ParseError>` - Parse blockchain declaration
- `parse_function() -> Result<FunctionDecl, ParseError>` - Parse function declaration
- `parse_statement() -> Result<Statement, ParseError>` - Parse statement
- `parse_expression() -> Result<Expression, ParseError>` - Parse expression

#### `struct Program`
Root node dari AST.

```rust
pub struct Program {
    pub blockchains: Vec<BlockchainDecl>,
}
```

#### `struct BlockchainDecl`
Representasi blockchain declaration.

```rust
pub struct BlockchainDecl {
    pub name: String,
    pub state_vars: Vec<StateVar>,
    pub constructor: Option<Constructor>,
    pub functions: Vec<FunctionDecl>,
    pub events: Vec<EventDecl>,
}
```

### 3. Semantic Analysis Module (`omega::semantic`)

#### `struct SemanticAnalyzer`
Melakukan type checking dan semantic validation.

```rust
pub struct SemanticAnalyzer {
    symbol_table: SymbolTable,
    errors: Vec<SemanticError>,
}
```

**Methods:**
- `new() -> Self` - Membuat analyzer baru
- `analyze(program: &Program) -> Result<(), Vec<SemanticError>>` - Analyze program
- `check_types(expr: &Expression) -> Result<Type, SemanticError>` - Type checking
- `resolve_symbol(name: &str) -> Option<Symbol>` - Symbol resolution

#### `enum Type`
Sistem type OMEGA.

```rust
pub enum Type {
    Address,
    Uint256,
    String,
    Bool,
    Mapping(Box<Type>, Box<Type>),
    Array(Box<Type>),
    Void,
}
```

### 4. Code Generation Module (`omega::codegen`)

#### `struct OmegaCodeGenerator`
Main code generator yang mendukung multiple targets.

```rust
pub struct OmegaCodeGenerator {
    targets: Vec<GenerationTarget>,
    template_engine: TemplateEngine,
    config: GenerationConfig,
}
```

**Methods:**
- `new(config: GenerationConfig) -> Self` - Membuat code generator baru
- `add_target(target: GenerationTarget) -> &mut Self` - Tambah target generation
- `generate(ir_module: &IRModule) -> Result<GenerationResult, CodeGenError>` - Generate code
- `generate_for_target(ir_module: &IRModule, target: GenerationTarget) -> Result<GeneratedFile, CodeGenError>`

#### `struct GenerationResult`
Hasil code generation untuk semua targets.

```rust
pub struct GenerationResult {
    pub files: Vec<GeneratedFile>,
    pub stats: TargetStats,
    pub warnings: Vec<CodeGenWarning>,
}
```

#### `struct EVMCodeGenerator`
Specialized generator untuk Ethereum Virtual Machine.

```rust
pub struct EVMCodeGenerator {
    solidity_version: String,
    optimization_enabled: bool,
    gas_optimizations: bool,
}
```

**Methods:**
- `new() -> Self` - Membuat EVM code generator
- `with_solidity_version(version: String) -> Self` - Set Solidity version
- `with_optimizations(enabled: bool) -> Self` - Enable/disable optimizations
- `generate_contract(ir_module: &IRModule) -> Result<String, EVMCodeGenError>`

#### `struct SolanaCodeGenerator`
Specialized generator untuk Solana runtime.

```rust
pub struct SolanaCodeGenerator {
    program_id: Option<String>,
    anchor_framework: bool,
    cluster: SolanaCluster,
}
```

**Methods:**
- `new() -> Self` - Membuat Solana code generator
- `with_program_id(id: String) -> Self` - Set program ID
- `with_anchor(enabled: bool) -> Self` - Enable Anchor framework
- `generate_program(ir_module: &IRModule) -> Result<String, SolanaCodeGenError>`

### 6. Compiler Module (`omega::compiler`)

#### `struct OmegaCompiler`
Main compiler interface dengan arsitektur modular.

```rust
pub struct OmegaCompiler {
    config: CompilerConfig,
    ir_generator: IRGenerator,
    optimizer: Optimizer,
    code_generator: OmegaCodeGenerator,
}
```

**Methods:**
- `new(config: CompilerConfig) -> Self` - Membuat compiler baru
- `add_target(target: GenerationTarget) -> &mut Self` - Tambah compilation target
- `compile(source: &str) -> Result<CompilationResult, CompilerError>` - Compile source code
- `compile_file(path: &Path) -> Result<CompilationResult, CompilerError>` - Compile file
- `compile_with_ir(source: &str) -> Result<(IRModule, CompilationResult), CompilerError>` - Compile dan return IR

#### `struct CompilerConfig`
Konfigurasi compiler dengan opsi baru.

```rust
pub struct CompilerConfig {
    pub optimization_level: OptimizationLevel,
    pub debug_info: bool,
    pub warnings_as_errors: bool,
    pub output_dir: PathBuf,
    pub ir_output: bool,
    pub optimization_passes: Vec<String>,
}
```

#### `enum OptimizationLevel`
Level optimasi yang tersedia.

```rust
pub enum OptimizationLevel {
    None,        // Tidak ada optimasi
    Basic,       // Optimasi dasar (constant folding, dead code elimination)
    Aggressive,  // Optimasi agresif (loop unrolling, inlining)
}
```

#### `enum GenerationTarget`
Target generation yang didukung.

```rust
pub enum GenerationTarget {
    EVM {
        version: EVMVersion,
        solidity_version: String,
        gas_optimizations: bool,
    },
    Solana {
        program_id: Option<String>,
        anchor_framework: bool,
        cluster: SolanaCluster,
    },
    Cosmos {
        sdk_version: String,
        wasm_enabled: bool,
    },
}
```

#### `struct CompilationResult`
Hasil kompilasi.

```rust
pub struct CompilationResult {
    pub success: bool,
    pub outputs: HashMap<Target, String>,
    pub warnings: Vec<Warning>,
    pub errors: Vec<CompilerError>,
    pub gas_estimates: Option<GasEstimate>,
}
```

## Error Types

### `enum CompilerError`
```rust
pub enum CompilerError {
    LexError(LexError),
    ParseError(ParseError),
    SemanticError(SemanticError),
    CodeGenError(CodeGenError),
    IOError(std::io::Error),
}
```

### `enum LexError`
```rust
pub enum LexError {
    UnexpectedCharacter(char),
    UnterminatedString,
    InvalidNumber(String),
    EOF,
}
```

### `enum ParseError`
```rust
pub enum ParseError {
    UnexpectedToken(Token),
    ExpectedToken(Token, Token),
    InvalidSyntax(String),
    EOF,
}
```

### `enum SemanticError`
```rust
pub enum SemanticError {
    UndefinedSymbol(String),
    TypeMismatch(Type, Type),
    DuplicateDeclaration(String),
    InvalidOperation(String),
}
```

## Usage Examples

### Basic Compilation dengan Arsitektur Baru
```rust
use omega::compiler::{OmegaCompiler, CompilerConfig, GenerationTarget, OptimizationLevel};

let config = CompilerConfig {
    optimization_level: OptimizationLevel::Basic,
    debug_info: true,
    warnings_as_errors: false,
    output_dir: PathBuf::from("build"),
    ir_output: true,
    optimization_passes: vec!["constant_folding".to_string(), "dead_code_elimination".to_string()],
};

let mut compiler = OmegaCompiler::new(config);

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

let source = r#"
blockchain SimpleToken {
    state {
        mapping(address => uint256) balances;
        uint256 total_supply;
    }
    
    constructor(uint256 initial_supply) {
        total_supply = initial_supply;
        balances[msg.sender] = initial_supply;
    }
    
    function transfer(address to, uint256 amount) public returns (bool) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
        return true;
    }
}
"#;

let result = compiler.compile(source)?;
println!("Compilation successful: {}", result.success);

// Access generated files
for file in result.outputs.files {
    println!("Generated {}: {} lines", file.filename, file.content.lines().count());
}
```

### Advanced IR dan Optimization
```rust
use omega::ir::{IRGenerator, IRModule};
use omega::optimizer::{Optimizer, OptimizationLevel, ConstantFoldingPass, DeadCodeEliminationPass};
use omega::codegen::{OmegaCodeGenerator, GenerationConfig};

// Generate IR
let mut ir_generator = IRGenerator::new();
let ir_module = ir_generator.generate(&program)?;

// Setup optimizer dengan custom passes
let mut optimizer = Optimizer::new(OptimizationLevel::Aggressive);
optimizer.add_pass(Box::new(ConstantFoldingPass::new()));
optimizer.add_pass(Box::new(DeadCodeEliminationPass::new()));

// Optimize IR
let mut optimized_module = ir_module.clone();
optimizer.optimize(&mut optimized_module)?;

// Generate code
let config = GenerationConfig::default();
let mut code_generator = OmegaCodeGenerator::new(config);
code_generator.add_target(GenerationTarget::EVM {
    version: EVMVersion::London,
    solidity_version: "0.8.19".to_string(),
    gas_optimizations: true,
});

let result = code_generator.generate(&optimized_module)?;
println!("Generated {} files", result.files.len());
```

### Custom Code Generation
```rust
use omega::codegen::{EVMCodeGenerator, SolanaCodeGenerator};

// EVM-specific generation
let mut evm_generator = EVMCodeGenerator::new()
    .with_solidity_version("0.8.19".to_string())
    .with_optimizations(true);

let solidity_code = evm_generator.generate_contract(&ir_module)?;
println!("Generated Solidity:\n{}", solidity_code);

// Solana-specific generation
let mut solana_generator = SolanaCodeGenerator::new()
    .with_program_id("11111111111111111111111111111112".to_string())
    .with_anchor(true);

let rust_code = solana_generator.generate_program(&ir_module)?;
println!("Generated Rust:\n{}", rust_code);
```

### IR Analysis dan Debugging
```rust
use omega::ir::{IRModule, IRAnalyzer};

// Analyze IR module
let analyzer = IRAnalyzer::new();
let analysis = analyzer.analyze(&ir_module)?;

println!("IR Statistics:");
println!("  Functions: {}", analysis.function_count);
println!("  Instructions: {}", analysis.instruction_count);
println!("  Basic Blocks: {}", analysis.basic_block_count);
println!("  Memory Usage: {} bytes", analysis.estimated_memory_usage);

// Print IR in human-readable format
println!("IR Dump:\n{}", ir_module.to_string());
```

### Semantic Analysis
```rust
use omega::semantic::SemanticAnalyzer;

let mut analyzer = SemanticAnalyzer::new();
match analyzer.analyze(&program) {
    Ok(()) => println!("Semantic analysis passed"),
    Err(errors) => {
        for error in errors {
            println!("Error: {:?}", error);
        }
    }
}
```

## CLI Integration

### Command Line Interface
```bash
# Compile untuk EVM
omega compile --target evm --input contract.omega --output build/

# Compile untuk multiple targets
omega compile --target evm,solana --input contract.omega --output build/

# Dengan optimizations
omega compile --target evm --optimize --input contract.omega

# Debug mode
omega compile --target evm --debug --input contract.omega
```

### Configuration File
```toml
# omega.toml
[compiler]
optimization_level = "high"
debug_info = true
warnings_as_errors = false
output_dir = "build"

[[targets]]
type = "evm"
version = "london"
gas_optimizations = true

[[targets]]
type = "solana"
cluster = "devnet"
```

## Extension Points

### Custom Code Generators
```rust
use omega::codegen::CodeGenerator;

struct CustomCodeGen;

impl CodeGenerator for CustomCodeGen {
    type Output = String;
    type Error = String;
    
    fn generate(&mut self, program: &Program) -> Result<String, String> {
        // Custom implementation
        Ok("Generated code".to_string())
    }
    
    fn optimize(&mut self, code: &mut String) -> Result<(), String> {
        // Custom optimizations
        Ok(())
    }
}
```

### Custom Semantic Rules
```rust
use omega::semantic::{SemanticAnalyzer, SemanticRule};

struct CustomRule;

impl SemanticRule for CustomRule {
    fn check(&self, node: &ASTNode) -> Result<(), SemanticError> {
        // Custom semantic validation
        Ok(())
    }
}

let mut analyzer = SemanticAnalyzer::new();
analyzer.add_rule(Box::new(CustomRule));
```

## Performance Considerations

- **Lexing**: O(n) time complexity untuk input size n
- **Parsing**: O(n) untuk most cases, O(n²) untuk deeply nested expressions
- **Semantic Analysis**: O(n) dengan symbol table lookups
- **Code Generation**: O(n) dengan optional optimization passes

## Thread Safety

- `Lexer`: Not thread-safe (mutable state)
- `Parser`: Not thread-safe (mutable state)  
- `SemanticAnalyzer`: Not thread-safe (mutable symbol table)
- `CodeGenerator`: Not thread-safe (mutable output)
- `Compiler`: Thread-safe untuk read operations, not thread-safe untuk compilation

## Memory Usage

- Typical memory usage: 10-50MB untuk medium-sized contracts
- AST nodes: ~100 bytes per node average
- Symbol table: ~50 bytes per symbol
- Generated code: 2-5x source code size

---

*Generated by OMEGA Compiler v1.0.0*

## HTTP API Server (Example)

OMEGA menyediakan contoh server HTTP backend yang dapat digunakan sebagai API untuk tooling dan integrasi.
Server dibangun di atas `std/net/http/server` yang sekarang menjalankan loop persisten untuk menangani banyak permintaan.

### Endpoint
- `GET /health` → Mengembalikan status server:
  ```json
  {"status":"ok","server":"omega-native-runner"}
  ```
- `GET /version` → Mengembalikan versi compiler yang digunakan oleh runner:
  ```json
  {"compiler_version":"1.1.0"}
  ```
- `GET /info` → Informasi status runtime server:
  ```json
  {
    "server": "omega-native-runner",
    "version": "1.1.0",
    "requests_handled": 12,
    "started_at_ms": 1730512345678,
    "address": "127.0.0.1",
    "port": 8080
  }
  ```
- `POST /compile` → Body berisi source code OMEGA sebagai teks (Content-Type: text/plain). Server akan melakukan tokenisasi dan parsing dasar, lalu mengembalikan statistik kompilasi:
  ```json
  {
    "success": true,
    "tokens_count": 42,
    "imports_count": 1,
    "message": "Parsed source successfully"
  }
  ```

### Menjalankan Server
- Disarankan menggunakan skrip:
  ```powershell
  scripts\run_api_server.ps1 -Port 8080 -Address 127.0.0.1
  ```
- Atau melalui CLI:
  ```powershell
  .\omega.cmd run examples\omega_api_server.mega
  ```

Catatan: Perintah `omega run` kini menjalankan runner native sementara berbasis PowerShell/.NET HttpListener. Ini belum merupakan runtime OMEGA penuh, tetapi cukup untuk menjalankan server API contoh secara persisten hingga runtime OMEGA tersedia.

### Variabel Lingkungan
- `OMEGA_SERVER_PORT` → Port server (default 8080)
- `OMEGA_SERVER_IP` → Alamat bind (default 0.0.0.0)

### Contoh Permintaan
- Cek kesehatan:
  ```bash
  curl -s http://127.0.0.1:8080/health
  ```
- Kompilasi sederhana dari file:
  ```bash
  curl -s -X POST \
       -H "Content-Type: text/plain" \
       --data-binary @examples/contracts/SimpleToken.mega \
       http://127.0.0.1:8080/compile
  ```