# 🤝 Contributing to OMEGA

> [🏠 Home](Home.md) | [🚀 Getting Started](Getting-Started-Guide.md) | [📖 Language Spec](Language-Specification.md) | [🏗️ Compiler Architecture](Compiler-Architecture.md) | [🔧 API Reference](API-Reference.md)

Thank you for your interest in contributing to OMEGA! We welcome contributions from developers of all skill levels and backgrounds. This guide will help you get started with contributing to the OMEGA blockchain programming language project.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Contributing Guidelines](#contributing-guidelines)
- [Pull Request Process](#pull-request-process)
- [Issue Reporting](#issue-reporting)
- [Development Workflow](#development-workflow)
- [Testing](#testing)
- [Documentation](#documentation)
- [Community](#community)

## 📜 Code of Conduct

This project adheres to a code of conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to [support@omega-lang.org](mailto:support@omega-lang.org).

### Our Standards

- **Be respectful** and inclusive to all community members
- **Be collaborative** and constructive in discussions
- **Be patient** with newcomers and those learning
- **Focus on what's best** for the community and project
- **Show empathy** towards other community members
- **Use welcoming and inclusive language**
- **Respect differing viewpoints and experiences**

## 🚀 Getting Started

### Prerequisites

Before contributing to OMEGA, ensure you have:

- **Node.js** (v18 or higher)
- **Git** for version control
- **PowerShell** (for Windows users) or **Bash** (for Unix-like systems)
- **Basic knowledge** of blockchain development concepts
- **Familiarity** with compiler design (helpful but not required)

### Fork and Clone

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/omega.git
   cd omega
   ```
3. **Add upstream remote**:
   ```bash
   git remote add upstream https://github.com/omega-lang/omega.git
   ```

## 🛠️ Development Setup

### Initial Setup

1. **Install Dependencies**:
   ```bash
   # Install project dependencies
   make install-deps
   
   # Or manually install components
   cd lsp-server && npm install && cd ..
   cd omega-vscode-extension && npm install && cd ..
   ```

2. **Build the Project**:
   ```bash
   # Build all components
   make build
   
   # Or use platform-specific scripts
   # Windows:
   .\build.ps1
   # Unix:
   ./build.sh
   ```

3. **Run Tests**:
   ```bash
   # Run comprehensive test suite
   omega test
   
   # Or use scripts
   # Windows:
   .\run_tests.ps1
   # Unix:
   ./run_tests.sh
   ```

### Development Environment

- **IDE**: VS Code with OMEGA extension (recommended)
- **Language Server**: Built-in LSP support for syntax highlighting and IntelliSense
- **Testing**: Comprehensive test suite with multiple target validation
- **Debugging**: Debug mode available in LSP server and compiler

### Project Structure

```
omega/
├── src/                    # Core compiler source code
│   ├── lexer/             # Lexical analysis
│   ├── parser/            # Syntax analysis
│   ├── semantic/          # Semantic analysis
│   ├── ir/                # Intermediate representation
│   └── codegen/           # Code generators
├── lsp-server/            # Language Server Protocol implementation
├── omega-vscode-extension/ # VS Code extension
├── docs/                  # Documentation
├── examples/              # Example OMEGA contracts
├── tests/                 # Test suites
└── wiki/                  # Wiki documentation
```

## 📝 Contributing Guidelines

### Types of Contributions

We welcome several types of contributions:

- 🐛 **Bug fixes** - Fix issues in compiler, LSP, or tooling
- ✨ **New features** - Add language features or compiler targets
- 📚 **Documentation improvements** - Enhance guides, tutorials, and API docs
- 🧪 **Tests** - Add test cases and improve test coverage
- 🎨 **UI/UX improvements** - Enhance VS Code extension and tooling
- 🔧 **Tooling and infrastructure** - Improve build systems and CI/CD
- 🌐 **Blockchain integrations** - Add support for new blockchain targets
- 🔒 **Security enhancements** - Improve security analysis and validation

### Before You Start

1. **Check existing issues** to avoid duplicating work
2. **Create an issue** for major changes or new features
3. **Discuss your approach** with maintainers in the issue
4. **Follow coding standards** outlined below
5. **Review related documentation** and existing implementations

### Coding Standards

#### OMEGA Language Files (*.mega)

```omega
// Use clear, descriptive contract names
blockchain TokenContract {
    state {
        // Document state variables
        mapping(address => uint256) balances;
        uint256 total_supply;
    }
    
    // Document complex functions with clear comments
    function transfer(address to, uint256 amount) public returns (bool) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
        
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    event Transfer(address indexed from, address indexed to, uint256 value);
}
```

#### JavaScript/TypeScript Files

```javascript
// Use camelCase for variables and functions
const languageServer = new LanguageServer();

// Use PascalCase for classes
class OmegaCompiler {
    constructor(options = {}) {
        this.options = options;
    }
    
    // Document public methods
    compile(sourceCode) {
        // Implementation
    }
}

// Use descriptive function names
function parseOmegaContract(source) {
    // Implementation
}
```

#### General Guidelines

- **Indentation**: 4 spaces (no tabs)
- **Line length**: Maximum 100 characters
- **Comments**: Use clear, concise comments for complex logic
- **Naming**: Use descriptive names for variables, functions, and classes
- **Error handling**: Always handle errors gracefully with meaningful messages
- **Type safety**: Use TypeScript where applicable
- **Documentation**: Document public APIs and complex algorithms

## 🔄 Pull Request Process

### Before Submitting

1. **Update documentation** if your changes affect user-facing features
2. **Add tests** for new functionality or bug fixes
3. **Run all tests** and ensure they pass
4. **Update CHANGELOG.md** if applicable
5. **Rebase** your branch on the latest main branch
6. **Check code formatting** and linting

### PR Requirements

- **Clear title** describing the change
- **Detailed description** explaining what and why
- **Link to related issues** using keywords (fixes #123)
- **Screenshots** for UI changes
- **Test results** showing all tests pass
- **Breaking changes** clearly documented

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Code refactoring

## Testing
- [ ] All existing tests pass
- [ ] New tests added for new functionality
- [ ] Manual testing completed

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No breaking changes (or clearly documented)
```

## 🐛 Issue Reporting

### Bug Reports

When reporting bugs, please include:

- **Clear title** and description
- **Steps to reproduce** the issue
- **Expected vs actual behavior**
- **Environment details** (OS, Node.js version, etc.)
- **Code samples** that demonstrate the issue
- **Error messages** and stack traces

### Feature Requests

For feature requests, please provide:

- **Clear description** of the proposed feature
- **Use case** and motivation
- **Proposed implementation** approach (if any)
- **Potential impact** on existing functionality
- **Alternative solutions** considered

## 🔄 Development Workflow

### Branch Naming

- `feature/description` - New features
- `bugfix/description` - Bug fixes
- `docs/description` - Documentation updates
- `refactor/description` - Code refactoring
- `test/description` - Test improvements

### Commit Messages

Follow conventional commit format:

```
type(scope): description

[optional body]

[optional footer]
```

Examples:
- `feat(compiler): add support for Cosmos SDK integration`
- `fix(lexer): handle unicode characters in string literals`
- `docs(wiki): update getting started guide`
- `test(codegen): add EVM bytecode generation tests`

## 🧪 Testing

### Test Categories

- **Unit Tests**: Test individual components
- **Integration Tests**: Test component interactions
- **End-to-End Tests**: Test complete compilation pipeline
- **Cross-Chain Tests**: Test multi-target compilation
- **Performance Tests**: Benchmark compilation speed and output quality

### Running Tests

```bash
# Run all tests
omega test

# Run specific test suite
omega test --suite compiler
omega test --suite codegen
omega test --suite cross-chain

# Run tests with coverage
omega test --coverage

# Run performance benchmarks
omega test --benchmark
```

### Writing Tests

```javascript
// Example test structure
describe('OMEGA Compiler', () => {
    test('should compile simple token contract', () => {
        const source = `
            blockchain SimpleToken {
                state {
                    mapping(address => uint256) balances;
                }
            }
        `;
        
        const result = compiler.compile(source);
        expect(result.success).toBe(true);
        expect(result.targets).toContain('evm');
    });
});
```

## 📚 Documentation

### Documentation Types

- **API Documentation**: Generated from code comments
- **User Guides**: Step-by-step tutorials
- **Language Specification**: Formal language definition
- **Architecture Docs**: Internal design documentation
- **Wiki Pages**: Community-maintained documentation

### Writing Documentation

- Use clear, concise language
- Include code examples
- Provide step-by-step instructions
- Keep documentation up-to-date with code changes
- Use proper markdown formatting

## 🌐 Community

### Communication Channels

- **Discord**: [Join our community](https://discord.gg/omega-lang)
- **GitHub Discussions**: For technical discussions
- **Twitter**: [@omega_lang](https://twitter.com/omega_lang)
- **Email**: [support@omega-lang.org](mailto:support@omega-lang.org)

### Getting Help

- Check existing documentation and wiki
- Search GitHub issues for similar problems
- Ask questions in Discord or GitHub Discussions
- Attend community calls and events

### Recognition

Contributors are recognized through:
- GitHub contributor graphs
- Release notes acknowledgments
- Community highlights
- Contributor badges and roles

## 📄 License

By contributing to OMEGA, you agree that your contributions will be licensed under the [MIT License](../LICENSE).

## 🙏 Thank You

Thank you for contributing to OMEGA! Your efforts help make blockchain development more accessible and efficient for developers worldwide.

---

*For more information, visit our [main documentation](Home.md) or join our [community Discord](https://discord.gg/omega-lang).*

#### Clone Repository
```bash
# Fork the repository first on GitHub
git clone https://github.com/YOUR_USERNAME/omega-lang.git
cd omega-lang

# Add upstream remote
git remote add upstream https://github.com/Rafael2022-prog/omega-lang.git

# Install dependencies
make build
npm install  # For tooling and tests
```

#### Development Setup
```bash
# Install development tools
omega install dev-tools
omega install coverage-tools

# Setup pre-commit hooks
cp scripts/pre-commit .git/hooks/
chmod +x .git/hooks/pre-commit

# Verify setup
omega test
omega lint
omega format --check
```

### 2. Understand Project Structure

```
omega-lang/
├── compiler/           # Core compiler implementation
│   ├── lexer/         # Lexical analysis
│   ├── parser/        # Syntax analysis
│   ├── semantic/      # Semantic analysis
│   ├── ir/            # Intermediate representation
│   ├── codegen/       # Code generation
│   └── optimizer/     # Optimization passes
├── stdlib/            # Standard library
│   ├── collections/   # Data structures
│   ├── math/          # Mathematical operations
│   ├── crypto/        # Cryptographic functions
│   └── security/      # Security utilities
├── targets/           # Blockchain-specific code generators
│   ├── evm/          # Ethereum Virtual Machine
│   ├── solana/       # Solana runtime
│   ├── cosmos/       # Cosmos SDK
│   └── substrate/    # Substrate framework
├── cli/              # Command line interface
├── lsp/              # Language Server Protocol
├── tests/            # Test suites
├── docs/             # Documentation
├── examples/         # Example contracts
└── tools/            # Development tools
```

## 🎯 Areas of Contribution

### 🔧 Core Development

#### Compiler Development
**Skills Needed**: OMEGA, Compiler Theory, LLVM
**Difficulty**: Advanced

```omega
// Example: Adding new optimization pass
optimization DeadCodeElimination {
    state {
        uint256 removed_instructions;
    }
    
    function run(ir: IR) public returns (bool) {
        // Implementation here
        return true;
    }
}
```

**Current Needs**:
- [ ] Performance optimizations
- [ ] Memory management improvements
- [ ] Error message enhancements
- [ ] New optimization passes

#### Language Features
**Skills Needed**: Language Design, Type Theory
**Difficulty**: Advanced

```omega
// Example: Generic types implementation
struct Container<T> {
    items: Vector<T>,
    capacity: uint256,
}

impl<T> Container<T> {
    function new(capacity: uint256) -> Container<T> {
        Container {
            items: Vector::new(),
            capacity: capacity,
        }
    }
}
```

**Current Needs**:
- [ ] Generic types system
- [ ] Trait implementation
- [ ] Pattern matching
- [ ] Async/await support

### 🌐 Blockchain Integration

#### New Target Support
**Skills Needed**: Blockchain Knowledge, Target Platform
**Difficulty**: Intermediate to Advanced

```omega
// Example: Adding new blockchain target
blockchain AptosCodeGenerator {
    state {
        AptosConfig config;
    }
    
    function generate(ir: IR) public returns (GeneratedCode) {
        // Generate Move language code
        return new GeneratedCode();
    }
}
```

**Current Priorities**:
- [ ] Aptos (Move VM)
- [ ] Sui (Move VM)
- [ ] NEAR Protocol
- [ ] Cardano (Plutus)
- [ ] Tezos (Michelson)

#### Cross-Chain Features
**Skills Needed**: Cross-Chain Protocols, Cryptography
**Difficulty**: Advanced

```omega
// Example: Cross-chain message passing
@cross_chain(target = "polygon")
function bridge_message(bytes32 message, address recipient) public {
    emit CrossChainMessage(message, recipient, "polygon");
}
```

**Current Needs**:
- [ ] IBC protocol integration
- [ ] LayerZero integration
- [ ] Wormhole bridge support
- [ ] Axelar network integration

### 📚 Standard Library

#### Collections & Data Structures
**Skills Needed**: Data Structures, Algorithms
**Difficulty**: Intermediate

```omega
// Example: Implementing new collection
struct BinaryTree<T> {
    root: Option<TreeNode<T>>,
    size: uint256,
}

impl<T: Comparable> BinaryTree<T> {
    function insert(value: T) {
        // Implementation
    }
    
    function search(value: T) -> bool {
        // Implementation
    }
}
```

**Current Needs**:
- [ ] Advanced data structures (Trees, Graphs)
- [ ] Sorting algorithms
- [ ] Search algorithms
- [ ] String manipulation utilities

#### Security & Cryptography
**Skills Needed**: Cryptography, Security
**Difficulty**: Advanced

```omega
// Example: New cryptographic function
library ZKProofs {
    function verify_merkle_proof(
        bytes32 leaf,
        bytes32[] memory proof,
        bytes32 root
    ) -> bool {
        // Implementation
    }
}
```

**Current Needs**:
- [ ] Zero-knowledge proof utilities
- [ ] Advanced signature schemes
- [ ] Homomorphic encryption
- [ ] Multi-party computation

### 🛠️ Developer Tools

#### IDE Integration
**Skills Needed**: TypeScript, LSP, VS Code API
**Difficulty**: Intermediate

```typescript
// Example: VS Code extension feature
export function activate(context: vscode.ExtensionContext) {
    const provider = new OmegaCompletionProvider();
    const disposable = vscode.languages.registerCompletionItemProvider(
        'omega',
        provider,
        '.',
        ':'
    );
    context.subscriptions.push(disposable);
}
```

**Current Needs**:
- [ ] Syntax highlighting improvements
- [ ] IntelliSense enhancements
- [ ] Debugging support
- [ ] Refactoring tools

#### CLI & Tooling
**Skills Needed**: OMEGA, CLI Design
**Difficulty**: Beginner to Intermediate

```omega
// Example: New CLI command
cli OmegaCLI {
    state {
        Commands command;
    }
    
    function analyze(security: bool) public {
        // Implementation for analyze command
    }
}
```

**Current Needs**:
- [ ] Package manager
- [ ] Dependency resolver
- [ ] Security analyzer
- [ ] Performance profiler

### 📖 Documentation & Education

#### Documentation
**Skills Needed**: Technical Writing, Markdown
**Difficulty**: Beginner

**Current Needs**:
- [ ] Tutorial improvements
- [ ] API documentation
- [ ] Best practices guides
- [ ] Migration guides

#### Examples & Templates
**Skills Needed**: Smart Contract Development
**Difficulty**: Beginner to Intermediate

```omega
// Example: DeFi template
blockchain YieldFarm {
    state {
        mapping(address => uint256) staked_amounts;
        mapping(address => uint256) reward_debt;
        uint256 total_staked;
        uint256 reward_per_share;
    }
    
    function stake(uint256 amount) public {
        // Implementation
    }
}
```

**Current Needs**:
- [ ] DeFi protocol templates
- [ ] NFT collection templates
- [ ] Gaming contract examples
- [ ] DAO governance examples

### 🧪 Testing & Quality Assurance

#### Test Development
**Skills Needed**: Testing, Quality Assurance
**Difficulty**: Beginner to Intermediate

```rust
// Example: Integration test
#[test]
fn test_cross_chain_compilation() {
    let source = r#"
        blockchain CrossChainToken {
            @target(evm, solana)
            function transfer(address to, uint256 amount) public {
                // Implementation
            }
        }
    "#;
    
    let result = compile_multi_target(source, vec![Target::EVM, Target::Solana]);
    assert!(result.is_ok());
}
```

**Current Needs**:
- [ ] Unit test coverage
- [ ] Integration tests
- [ ] Performance benchmarks
- [ ] Security tests

## 📋 Contribution Process

### 1. Choose an Issue

#### Finding Issues
- **Good First Issues**: Label `good-first-issue` untuk pemula
- **Help Wanted**: Label `help-wanted` untuk kontribusi yang dibutuhkan
- **Bug Reports**: Label `bug` untuk perbaikan
- **Feature Requests**: Label `enhancement` untuk fitur baru

#### Issue Assignment
```bash
# Comment on the issue
"I'd like to work on this issue. Could you assign it to me?"

# Wait for maintainer response
# Start working after assignment
```

### 2. Development Workflow

#### Branch Strategy
```bash
# Create feature branch
git checkout -b feature/your-feature-name

# Or for bug fixes
git checkout -b fix/issue-number-description

# Keep branch updated
git fetch upstream
git rebase upstream/main
```

#### Code Standards

##### OMEGA Code Style
```omega
// Use omega format for formatting
omega format

// Follow OMEGA naming conventions
blockchain MyContract {
    state {
        string field_name;
    }
    
    function function_name() public returns (bool) {
        // Implementation
        return true;
    }
}

// Add comprehensive documentation
/// Compiles OMEGA source code to target blockchain
/// 
/// # Arguments
/// * `source` - The OMEGA source code
/// * `target` - Target blockchain platform
/// 
/// # Returns
/// * `Ok(CompiledCode)` - Successfully compiled code
/// * `Err(CompilerError)` - Compilation error
pub fn compile(source: &str, target: Target) -> Result<CompiledCode, CompilerError> {
    // Implementation
}
```

##### OMEGA Code Style
```omega
// Use consistent indentation (4 spaces)
blockchain MyContract {
    state {
        mapping(address => uint256) balances;
        uint256 total_supply;
    }
    
    // Document public functions
    /// Transfers tokens from sender to recipient
    function transfer(address to, uint256 amount) public returns (bool) {
        require(to != address(0), "Invalid recipient");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
        
        emit Transfer(msg.sender, to, amount);
        return true;
    }
}
```

#### Testing Requirements
```bash
# Run all tests before submitting
omega test

# Run specific test suite
omega test compiler::tests

# Check code coverage
omega coverage --format html

# Run linter for code quality
omega lint --strict

# Format code
omega format
```

### 3. Pull Request Process

#### PR Preparation
```bash
# Ensure branch is up to date
git fetch upstream
git rebase upstream/main

# Run final checks
omega test
omega lint
omega format --check

# Push to your fork
git push origin feature/your-feature-name
```

#### PR Template
```markdown
## Description
Brief description of changes made.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing performed

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Tests pass locally
```

#### Review Process
1. **Automated Checks**: CI/CD pipeline runs automatically
2. **Code Review**: Maintainers review your code
3. **Feedback**: Address any requested changes
4. **Approval**: PR approved by maintainers
5. **Merge**: Code merged into main branch

## 🏆 Recognition Program

### Contributor Levels

#### 🌱 Newcomer (0-5 PRs)
- Welcome package
- Newcomer badge
- Mentorship program access

#### 🌿 Regular Contributor (6-20 PRs)
- Contributor badge
- OMEGA stickers
- Early feature access

#### 🌳 Core Contributor (21-50 PRs)
- Core contributor badge
- OMEGA t-shirt
- Governance token allocation

#### 🏆 Maintainer (50+ PRs)
- Maintainer status
- Full merchandise package
- Conference speaking opportunities
- Significant token allocation

### Special Recognition

#### 🎯 Bounty Program
- **Critical Bugs**: $500-2000 USDC
- **Security Vulnerabilities**: $1000-5000 USDC
- **Major Features**: $2000-10000 USDC
- **Documentation**: $100-500 USDC

#### 🏅 Monthly Awards
- **Contributor of the Month**: $1000 USDC + Special NFT
- **Best Bug Fix**: $500 USDC
- **Best Feature**: $1000 USDC
- **Best Documentation**: $300 USDC

## 📞 Getting Help

### Communication Channels

#### 💬 Discord Server
- **#contributors**: General contributor discussion
- **#development**: Technical development questions
- **#help**: Get help with setup and issues
- **#announcements**: Important updates

#### 📧 Direct Contact
- **Maintainers**: maintainers@omega-lang.org
- **Security Issues**: security@omega-lang.org
- **General Questions**: hello@omega-lang.org

#### 📋 GitHub
- **Issues**: Bug reports and feature requests
- **Discussions**: Long-form discussions
- **Wiki**: Documentation and guides

### Mentorship Program

#### For New Contributors
- **Mentor Assignment**: Experienced contributor as mentor
- **Weekly Check-ins**: Progress and guidance
- **Pair Programming**: Learn by doing
- **Code Reviews**: Detailed feedback

#### Becoming a Mentor
- **Requirements**: 10+ merged PRs, 6+ months active
- **Training**: Mentorship training program
- **Recognition**: Mentor badge and rewards
- **Impact**: Help grow the community

## 🔒 Security & Responsible Disclosure

### Security Issues
```bash
# DO NOT create public issues for security vulnerabilities
# Instead, email: security@omega-lang.org

# Include:
# - Detailed description
# - Steps to reproduce
# - Potential impact
# - Suggested fix (if any)
```

### Responsible Disclosure Process
1. **Report**: Email security team privately
2. **Acknowledgment**: Response within 24 hours
3. **Investigation**: Security team investigates
4. **Fix**: Patch developed and tested
5. **Disclosure**: Public disclosure after fix
6. **Reward**: Security bounty if applicable

## 📜 Code of Conduct

### Our Pledge
We pledge to make participation in OMEGA a harassment-free experience for everyone, regardless of:
- Age, body size, disability, ethnicity
- Gender identity and expression
- Level of experience, nationality
- Personal appearance, race, religion
- Sexual identity and orientation

### Expected Behavior
- **Respectful**: Be respectful and inclusive
- **Collaborative**: Work together constructively
- **Professional**: Maintain professional standards
- **Helpful**: Help others learn and grow

### Unacceptable Behavior
- Harassment, discrimination, or abuse
- Trolling, insulting, or derogatory comments
- Public or private harassment
- Publishing others' private information
- Unprofessional conduct

### Enforcement
- **Warning**: First offense usually results in warning
- **Temporary Ban**: Repeated violations may result in temporary ban
- **Permanent Ban**: Serious violations result in permanent ban
- **Appeal Process**: Appeals can be made to maintainers

## 🎉 Welcome to the Community!

Terima kasih telah mempertimbangkan untuk berkontribusi ke OMEGA! Setiap kontribusi, sekecil apapun, sangat berarti bagi kami. Mari bersama-sama membangun masa depan pengembangan blockchain yang lebih baik.

### Quick Start Checklist
- [ ] ⭐ Star the repository
- [ ] 🍴 Fork the repository
- [ ] 📥 Clone your fork
- [ ] 🔧 Set up development environment
- [ ] 🎯 Find your first issue
- [ ] 💬 Join our Discord
- [ ] 📖 Read the documentation
- [ ] 🚀 Make your first contribution!

---

## 🔗 Related Resources

- [Getting Started Guide](Getting-Started-Guide.md) - Setup dan basic usage
## 🔗 Related Documentation

- [Language Specification](Language-Specification.md) - Technical language details
- [API Reference](API-Reference.md) - Comprehensive API documentation
- [Getting Started Guide](Getting-Started-Guide.md) - Setup dan basic usage
- [Compiler Architecture](Compiler-Architecture.md) - Internal compiler design
- [Home](Home.md) - Kembali ke halaman utama
- [GitHub Repository](https://github.com/Rafael2022-prog/omega-lang)
- [Discord Community](https://discord.gg/omega-lang)

---

> [🏠 Home](Home.md) | [🚀 Getting Started](Getting-Started-Guide.md) | [📖 Language Spec](Language-Specification.md) | [🏗️ Compiler Architecture](Compiler-Architecture.md) | [🔧 API Reference](API-Reference.md)

**Happy Contributing! 🚀**

*"The best way to predict the future is to create it. Join us in creating the future of blockchain development."*