# OMEGA Deploy Configuration Examples

## Example 1: Deploy to Ethereum Mainnet

```bash
omega deploy ethereum \
  --contract=target/evm/MyContract.abi \
  --key=~/.ethereum/mainnet.key \
  --verify
```

## Example 2: Deploy to Polygon

```bash
omega deploy polygon \
  --contract=target/evm/MyContract.abi \
  --key=~/.ethereum/polygon.key \
  --gas-price=50
```

## Example 3: Deploy to Solana Mainnet

```bash
omega deploy solana \
  --contract=target/solana/my_program.so \
  --key=~/.solana/mainnet.json
```

## Example 4: Deploy with Custom Gas

```bash
omega deploy ethereum \
  --contract=target/evm/HighGasContract.abi \
  --key=keys/mainnet.pem \
  --gas-limit=5000000 \
  --gas-price=100 \
  --verify
```

## Example 5: Deploy to Multiple Networks

```bash
# Deploy same contract to three different EVM networks

# Ethereum
omega deploy ethereum --contract=target/evm/Contract.abi --key=eth.key

# Polygon
omega deploy polygon --contract=target/evm/Contract.abi --key=poly.key

# BSC
omega deploy bsc --contract=target/evm/Contract.abi --key=bsc.key
```

## Key Management Best Practices

### Store Keys Securely

```bash
# Never commit keys to git
echo "*.key" >> .gitignore
echo ".env" >> .gitignore

# Use environment variables
export OMEGA_PRIVATE_KEY="0x..."
omega deploy ethereum --contract=target/evm/Contract.abi --key=$OMEGA_PRIVATE_KEY
```

### Key File Formats Supported

1. **Hex String** (EVM)
   ```
   0x1234567890abcdef...
   ```

2. **JSON Keystore** (EVM)
   ```json
   {
     "address": "0x...",
     "crypto": {...}
   }
   ```

3. **Solana JSON**
   ```json
   [123, 45, 67, ...]
   ```

4. **PEM Format**
   ```
   -----BEGIN PRIVATE KEY-----
   ...
   -----END PRIVATE KEY-----
   ```

## Deployment Workflow

1. **Compile Contract**
   ```bash
   omega build --release
   ```

2. **Test on Testnet**
   ```bash
   omega deploy goerli --contract=target/evm/Contract.abi --key=testnet.key
   ```

3. **Verify Deployment**
   Check block explorer for contract address

4. **Deploy to Mainnet**
   ```bash
   omega deploy ethereum --contract=target/evm/Contract.abi --key=mainnet.key --verify
   ```

## Error Handling

### Insufficient Balance
```
❌ Error: Insufficient balance for deployment
   Required: 1.5 ETH
   Available: 0.5 ETH
   
Solution: Transfer funds to your account
```

### Invalid Contract Bytecode
```
❌ Error: Invalid contract bytecode
   
Solution: Make sure contract was compiled successfully
         omega build --release
```

### Network Connection Failed
```
❌ Error: Failed to connect to RPC endpoint
   RPC: https://eth.llamarpc.com
   
Solution: Check network connection
         Try alternative RPC: --rpc https://...
```

### Deployment Timeout
```
⏳ Deployment still waiting for confirmations
   Tx: 0x...
   
Solution: Check on block explorer manually
         View at: https://etherscan.io/tx/0x...
```

## Verification

After deployment, verify contract on block explorer:

```bash
# Automatic verification (requires block explorer API key)
omega deploy ethereum \
  --contract=target/evm/Contract.abi \
  --key=mainnet.key \
  --verify \
  --explorer-api-key=$ETHERSCAN_API_KEY
```

## Gas Estimation

The deploy command automatically estimates gas:

```
💰 Cost Estimation:
   Gas estimate: 2,500,000
   Gas price: 25 gwei
   Total cost: 0.0625 ETH (~$175)
```

## Post-Deployment

### Interact with Deployed Contract

```omega
import "src/blockchain/evm";

function main() {
    address contract = address("0x...");
    
    // Call contract functions
    string result = call_contract(contract, "getData", []);
}
```

### Monitor Deployment

```bash
# Check transaction status
omega status --tx 0x...

# Get contract address
omega info --contract MyContract
```

## Supported Networks

| Network | Chain ID | Status | RPC |
|---------|----------|--------|-----|
| Ethereum | 1 | ✅ | https://eth.llamarpc.com |
| Polygon | 137 | ✅ | https://polygon-rpc.com |
| BSC | 56 | ✅ | https://bsc-dataseed1.binance.org |
| Avalanche | 43114 | ✅ | https://api.avax.network |
| Arbitrum | 42161 | ✅ | https://arb1.arbitrum.io |
| Solana | mainnet-beta | ✅ | https://api.mainnet-beta.solana.com |
| Cosmos | cosmoshub-4 | ⏳ | WIP |
| Substrate | kusama | ⏳ | WIP |

## Testnet Deployments

Use testnet before mainnet:

```bash
# Ethereum Goerli Testnet
omega deploy goerli --contract=target/evm/Contract.abi --key=testnet.key

# Solana Devnet
omega deploy solana --network devnet --contract=target/solana/program.so --key=devnet.json
```

## Troubleshooting

See `DEPLOYMENT_TROUBLESHOOTING.md` for common issues.
