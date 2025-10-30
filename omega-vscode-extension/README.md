# OMEGA Language Support for VS Code

![OMEGA Logo](https://img.shields.io/badge/OMEGA-VS%20Code%20Extension-blue?style=for-the-badge)

Official VS Code extension for the OMEGA blockchain programming language. Provides comprehensive language support, syntax highlighting, and development tools for OMEGA smart contracts.

## Features

### 🎨 Syntax Highlighting
- Full syntax highlighting for `.mega` files
- Support for OMEGA-specific keywords and constructs
- Cross-chain annotations highlighting
- Blockchain-specific function highlighting

### 📝 Code Completion & Snippets
- Smart code completion for OMEGA language
- Pre-built snippets for common patterns:
  - Blockchain contracts
  - ERC20 tokens
  - Cross-chain functions
  - Access control modifiers

### 🔧 Development Tools
- **Compile**: Build OMEGA contracts with `Ctrl+Shift+B`
- **Deploy**: Deploy contracts to multiple blockchains
- **Test**: Run comprehensive test suites
- **Linting**: Real-time syntax validation

### 🌐 Multi-Chain Support
- EVM targets (Ethereum, Polygon, BSC, etc.)
- Solana runtime
- Cosmos SDK
- Substrate framework

## Installation

1. Open VS Code
2. Go to Extensions (`Ctrl+Shift+X`)
3. Search for "OMEGA Language Support"
4. Click Install

Or install from command line:
```bash
code --install-extension omega-lang.omega-vscode
```

## Quick Start

### 1. Create New OMEGA Project
```bash
omega init my-project --template basic
cd my-project
code .
```

### 2. Open OMEGA File
Create or open a `.mega` file to activate the extension.

### 3. Start Coding
```omega
blockchain SimpleToken {
    state {
        mapping(address => uint256) balances;
        uint256 total_supply;
    }
    
    constructor(uint256 _initial_supply) {
        total_supply = _initial_supply;
        balances[msg.sender] = _initial_supply;
    }
    
    function transfer(address to, uint256 amount) public returns (bool) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
        return true;
    }
}
```

## Commands

| Command | Shortcut | Description |
|---------|----------|-------------|
| `OMEGA: Compile Contract` | `Ctrl+Shift+B` | Compile current OMEGA contract |
| `OMEGA: Deploy Contract` | - | Deploy contract to selected blockchain |
| `OMEGA: Run Tests` | - | Execute test suite |

## Configuration

Configure the extension in VS Code settings:

```json
{
    "omega.compilerPath": "omega",
    "omega.enableLinting": true,
    "omega.targetChains": ["evm", "solana"]
}
```

### Available Settings

- `omega.compilerPath`: Path to OMEGA compiler executable
- `omega.enableLinting`: Enable real-time syntax validation
- `omega.targetChains`: Default target blockchain platforms

## File Associations

The extension automatically recognizes:
- `.mega` files as OMEGA source code
- `omega.toml` as OMEGA configuration files

## Themes

Includes the **OMEGA Dark** theme optimized for blockchain development with:
- Enhanced syntax highlighting for smart contracts
- Cross-chain annotation emphasis
- Security-focused color coding

## Snippets

Type these prefixes and press `Tab`:

| Prefix | Description |
|--------|-------------|
| `blockchain` | Create new blockchain contract |
| `function` | Create function |
| `constructor` | Create constructor |
| `mapping` | Create mapping variable |
| `event` | Create event |
| `require` | Add require statement |
| `crosschain` | Create cross-chain function |
| `erc20` | Create ERC20 token contract |

## Language Features

### Syntax Highlighting
- Keywords: `blockchain`, `state`, `function`, `constructor`
- Types: `uint256`, `address`, `mapping`, `bool`
- Modifiers: `public`, `private`, `view`, `pure`
- Cross-chain: `@cross_chain`, `@evm`, `@solana`

### Auto-completion
- Smart suggestions based on context
- Import statement completion
- Function parameter hints

### Error Detection
- Real-time syntax validation
- Missing semicolon detection
- Bracket matching
- Type checking hints

## Multi-Chain Development

Deploy to multiple blockchains with a single codebase:

```omega
@cross_chain(target = "solana")
function bridge_tokens(bytes32 recipient, uint256 amount) public {
    // Cross-chain logic here
}
```

## Requirements

- VS Code 1.74.0 or higher
- OMEGA compiler installed and in PATH
- Node.js 18+ (for development)

## Extension Development

### Setup
```bash
git clone https://github.com/Rafael2022-prog/omega-lang-vscode
cd omega-vscode
npm install
```

### Build
```bash
npm run compile
```

### Test
```bash
npm test
```

## Contributing

We welcome contributions! Please see our [Contributing Guide](https://github.com/Rafael2022-prog/omega-lang-vscode/blob/main/CONTRIBUTING.md).

### Areas for Contribution
- Language server improvements
- Additional snippets
- Theme enhancements
- Documentation updates

## Support

- 📖 [Documentation](https://docs.omega-lang.org)
- 💬 [Discord Community](https://discord.gg/omega-lang)
- 🐛 [Report Issues](https://github.com/Rafael2022-prog/omega-lang-vscode/issues)
- 📧 [Email Support](mailto:support@omega-lang.org)

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Changelog

### 1.0.0
- Initial release
- Full syntax highlighting for `.mega` files
- Code snippets and completion
- Compile, deploy, and test commands
- OMEGA Dark theme
- Multi-chain support

---

**Made with ❤️ by the OMEGA Team**

*Empowering developers to build the future of blockchain applications.*