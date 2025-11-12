# Contributing to OMEGA Language v1.3.0

> Note (Windows Native-Only, Compile-Only)
> - This guide describes the full ecosystem and contribution workflow. The current active CI is Windows-only, with a CLI wrapper that supports single-file compilation (compile-only) and the Native Runner.
> - For building, prefer `build_omega_native.ps1` (or use `omega.exe` / `omega.ps1` for compiling). For testing, use compile-only verification via `omega compile <file.mega>` and E2E scripts like `scripts\\http_e2e_tests.ps1`. The `omega test` subcommand is forward-looking and may be inactive in the wrapper.
> - Non-native tooling and full pipeline steps (`omega build/test/deploy`) are documented for roadmap/optional use and will be enabled once the wrapper reaches feature parity.

Thank you for your interest in contributing to OMEGA! We welcome contributions from developers of all skill levels.

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

## 📜 Code of Conduct

This project adheres to a code of conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to [support@omegalang.xyz](mailto:support@omegalang.xyz).

### Our Standards

- **Be respectful** and inclusive
- **Be collaborative** and constructive
- **Be patient** with newcomers
- **Focus on what's best** for the community
- **Show empathy** towards other community members

## 🚀 Getting Started

### Prerequisites

- **Node.js** (v16 or higher)
- **Git**
- **PowerShell** (for Windows users)
- **Basic knowledge** of blockchain development

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/omega-lang.git
   cd omega-lang
   ```

## 🛠️ Development Setup

### Initial Setup

1. **Install Dependencies**:
   ```bash
   # Install LSP server dependencies
   cd lsp-server
   npm install
   cd ..
   
   # Install VS Code extension dependencies
   cd omega-vscode-extension
   npm install
   cd ..
   ```

2. **Build the Project**:
   ```powershell
   # Run build script
   .\build.ps1
   ```

3. **Run Tests**:
   ```powershell
   # Run comprehensive tests
   .\run_tests.ps1
   ```

### Development Environment

- **IDE**: VS Code with OMEGA extension (recommended)
- **Testing**: Use provided PowerShell scripts
- **Debugging**: Enable debug mode in LSP server

## 📝 Contributing Guidelines

### Types of Contributions

We welcome several types of contributions:

- 🐛 **Bug fixes**
- ✨ **New features**
- 📚 **Documentation improvements**
- 🧪 **Tests**
- 🎨 **UI/UX improvements**
- 🔧 **Tooling and infrastructure**

### Before You Start

1. **Check existing issues** to avoid duplicates
2. **Create an issue** for major changes
3. **Discuss your approach** with maintainers
4. **Follow coding standards** outlined below

### Coding Standards

#### OMEGA Language Files (*.mega)

```mega
// Use clear, descriptive names
contract TokenContract {
    // Document complex functions
    function transfer(address to, uint256 amount) -> bool {
        // Implementation
    }
}
```

#### JavaScript/TypeScript Files

```javascript
// Use camelCase for variables and functions
const languageServer = new LanguageServer();

// Use PascalCase for classes
class OmegaCompiler {
    constructor() {
        // Implementation
    }
}
```

#### General Guidelines

- **Indentation**: 4 spaces (no tabs)
- **Line length**: Maximum 100 characters
- **Comments**: Use clear, concise comments
- **Naming**: Use descriptive names
- **Error handling**: Always handle errors gracefully

## 🔄 Pull Request Process

### Before Submitting

1. **Update documentation** if needed
2. **Add tests** for new functionality
3. **Run all tests** and ensure they pass
4. **Update CHANGELOG.md** if applicable
5. **Rebase** your branch on latest main

### PR Requirements

- **Clear title** describing the change
- **Detailed description** of what and why
- **Link to related issues**
- **Screenshots** for UI changes
- **Test results** confirmation

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Other (please describe)

## Testing
- [ ] Tests pass locally
- [ ] Added new tests
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No breaking changes (or documented)
```

## 🐛 Issue Reporting

### Bug Reports

Use the bug report template and include:

- **Environment details** (OS, Node.js version, etc.)
- **Steps to reproduce**
- **Expected vs actual behavior**
- **Error messages** or logs
- **Minimal code example**

### Feature Requests

Use the feature request template and include:

- **Problem description**
- **Proposed solution**
- **Alternative solutions**
- **Use cases**
- **Implementation ideas**

## 🔄 Development Workflow

### Branch Naming

- `feature/description` - New features
- `fix/description` - Bug fixes
- `docs/description` - Documentation
- `refactor/description` - Code refactoring
- `test/description` - Test improvements

### Commit Messages

Follow conventional commits:

```
type(scope): description

feat(compiler): add support for cross-chain calls
fix(lexer): handle unicode characters correctly
docs(readme): update installation instructions
test(parser): add edge case tests
```

### Development Cycle

1. **Create branch** from main
2. **Make changes** following guidelines
3. **Test thoroughly**
4. **Commit with clear messages**
5. **Push and create PR**
6. **Address review feedback**
7. **Merge after approval**

## 🧪 Testing

### Test Categories

- **Unit tests**: Individual component testing
- **Integration tests**: Component interaction testing
- **End-to-end tests**: Full workflow testing
- **Performance tests**: Benchmark testing

### Running Tests

```powershell
# Run all tests
.\run_tests.ps1

# Run specific test category
.\scripts\simple_test.ps1

# Run performance benchmarks
.\scripts\performance_benchmark.ps1
```

### Writing Tests

- **Test file naming**: `*_tests.mega`
- **Test function naming**: `test_function_name`
- **Assertions**: Use built-in assertion functions
- **Coverage**: Aim for >80% code coverage

## 📚 Documentation

### Documentation Types

- **API documentation**: Function and class docs
- **User guides**: How-to guides and tutorials
- **Developer docs**: Architecture and design docs
- **Examples**: Code samples and demos

### Documentation Standards

- **Clear and concise** language
- **Code examples** for complex concepts
- **Up-to-date** with current implementation
- **Proper formatting** using Markdown

## 🏷️ Labels and Milestones

### Issue Labels

- `bug` - Something isn't working
- `enhancement` - New feature or request
- `documentation` - Documentation improvements
- `good first issue` - Good for newcomers
- `help wanted` - Extra attention needed
- `priority: high/medium/low` - Priority levels

### Milestones

- **v1.3.0** - Next minor release
- **v2.0.0** - Next major release
- **Future** - Long-term goals

## 🎯 Areas for Contribution

### High Priority

- **Cross-chain interoperability** improvements
- **Performance optimizations**
- **Security enhancements**
- **Documentation improvements**

### Medium Priority

- **IDE plugin enhancements**
- **Additional blockchain targets**
- **Developer tooling**
- **Example applications**

### Good First Issues

- **Documentation fixes**
- **Simple bug fixes**
- **Test improvements**
- **Code cleanup**

## 📞 Getting Help

### Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General questions and ideas
- **Email**: [support@omegalang.xyz](mailto:support@omegalang.xyz)

### Response Times

- **Issues**: Within 48 hours
- **Pull requests**: Within 72 hours
- **Security issues**: Within 24 hours

## 🙏 Recognition

Contributors will be recognized in:

- **CONTRIBUTORS.md** file
- **Release notes**
- **Project documentation**
- **Social media** (with permission)

## 📄 License

By contributing to OMEGA, you agree that your contributions will be licensed under the same license as the project.

---

**Thank you for contributing to OMEGA! Together, we're building the future of blockchain development.** 🚀