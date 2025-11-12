# 🛠️ OMEGA Developer Guide

## 📋 Table of Contents
1. [Quick Start](#quick-start)
2. [Development Environment](#development-environment)
3. [VS Code Extension Development](#vs-code-extension-development)
4. [Testing](#testing)
5. [Best Practices](#best-practices)
6. [Troubleshooting](#troubleshooting)

## 🚀 Quick Start

### Prerequisites
- Node.js 18.x+
- VS Code
- Git

### Setup VS Code Extension
```bash
cd ide/vscode-extension
npm install
npm run compile
npm test
```

## 🔧 Development Environment

### Project Structure
```
omega/
├── ide/vscode-extension/     # VS Code extension
├── docs/                       # Documentation
├── .github/workflows/          # CI/CD pipelines
└── scripts/                    # Build scripts
```

### Key Commands
```bash
# Install dependencies
npm install

# Compile TypeScript
npm run compile

# Run tests
npm test

# Run linting
npm run lint

# Package extension
npm run package
```

## 🔵 VS Code Extension Development

### Architecture
- **Entry Point**: `src/extension.ts`
- **Language Features**: `src/enhanced_extension.ts`
- **Tests**: `src/test/suite/`

### Available Commands
- `omega.compile` - Compile contracts
- `omega.format` - Format documents
- `omega.securityScan` - Security analysis
- `omega.showCommands` - Show all commands

### Configuration Options
```json
{
  "omega.autoCompile": false,
  "omega.enableDiagnostics": true,
  "omega.formatOnSave": true
}
```

## 🧪 Testing

### Run Tests
```bash
# All tests
npm test

# With coverage
npm run test:coverage
```

### Test Structure
```
test/
├── suite/extension.test.ts    # Main tests
├── fixtures/                   # Test data
└── mocks/                      # Mock data
```

### Current Test Status
✅ All 11 tests passing:
- Extension activation
- Command registration
- Language support
- Document formatting
- Configuration handling
- Error handling

## ✅ Best Practices

### Code Quality
- Use TypeScript strict mode
- Add JSDoc comments
- Handle errors gracefully
- Write comprehensive tests

### Performance
- Minimize activation time
- Use lazy loading
- Cache expensive operations
- Profile regularly

### Git Workflow
- Use feature branches
- Write clear commit messages
- Include tests for new features
- Update documentation

## 🔧 Troubleshooting

### Common Issues

**Extension not loading:**
- Check VS Code version
- Verify extension is enabled
- Review logs in Output panel

**Test failures:**
- Clear node_modules and reinstall
- Check Node.js version
- Run tests in clean environment

**Compilation errors:**
- Run `npm run compile`
- Check TypeScript errors
- Verify all dependencies installed

### Debug Commands
```bash
# Check compilation
npm run compile

# Run linting
npm run lint

# Package extension
npm run package

# Clean build
npm run clean
```

## 📚 Resources

- [VS Code Extension API](https://code.visualstudio.com/api)
- [Language Server Protocol](https://microsoft.github.io/language-server-protocol/)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Make changes with tests
4. Submit pull request
5. Pass all CI checks

---

**Happy coding! 🚀**