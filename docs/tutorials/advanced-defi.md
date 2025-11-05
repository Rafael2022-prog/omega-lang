# Tutorial: Membangun Protokol DeFi Advanced dengan OMEGA

> Catatan Penting (Windows Native-Only, Compile-Only)
> - Tutorial ini kompatibel dengan mode wrapper CLI saat ini yang mendukung kompilasi file tunggal (compile-only).
> - Gunakan `build_omega_native.ps1` untuk build, lalu jalankan `./omega.exe` atau `pwsh -NoProfile -ExecutionPolicy Bypass -File ./omega.ps1`.
> - Untuk verifikasi dasar gunakan `omega compile <file.mega>` terhadap kontrak di folder `contracts/`.
> - Anda juga dapat menggunakan Native Runner: `powershell -File scripts/omega_native_runner.ps1` lalu `POST /compile` untuk kompilasi via HTTP.
> - Perintah `omega build/test/deploy` yang muncul di dokumentasi lain bersifat forward-looking dan belum aktif di wrapper CLI pada mode ini.

Tutorial komprehensif untuk membangun protokol DeFi lengkap menggunakan OMEGA, termasuk AMM (Automated Market Maker), Lending Protocol, dan Yield Farming.

## 🎯 Tujuan Tutorial

Setelah menyelesaikan tutorial ini, Anda akan dapat:
- Membangun AMM dengan liquidity pools
- Mengimplementasikan lending dan borrowing protocol
- Membuat yield farming mechanism
- Mengintegrasikan oracle untuk price feeds
- Mengelola cross-chain liquidity
- Mengimplementasikan governance system

## 📋 Prerequisites

- Menyelesaikan [Basic Token Tutorial](./basic-token.md)
- Pemahaman DeFi concepts (AMM, lending, yield farming)
- Pengalaman dengan smart contract security
- Familiarity dengan mathematical calculations dalam DeFi

## 🏗️ Arsitektur Protokol

```
DeFi Protocol Architecture:
├── Core Contracts
│   ├── AMM (Automated Market Maker)
│   ├── LendingPool
│   ├── YieldFarm
│   └── PriceOracle
├── Token Contracts
│   ├── LPToken (Liquidity Provider Token)
│   ├── GovernanceToken
│   └── RewardToken
├── Governance
│   ├── Governor
│   ├── Timelock
│   └── VotingEscrow
└── Cross-Chain
    ├── Bridge
    ├── CrossChainAMM
    └── MultiChainGovernance
```

## 🚀 Langkah 1: Setup Proyek DeFi

### Inisialisasi Proyek

```bash
# Buat proyek DeFi baru
omega init defi-protocol --template defi --targets evm,solana,cosmos

cd defi-protocol

# Lihat struktur proyek
tree contracts/
```

Struktur proyek DeFi:
```
contracts/
├── core/
│   ├── AMM.mega
│   ├── LendingPool.mega
│   ├── YieldFarm.mega
│   └── PriceOracle.mega
├── tokens/
│   ├── LPToken.mega
│   ├── GovernanceToken.mega
│   └── RewardToken.mega
├── governance/
│   ├── Governor.mega
│   ├── Timelock.mega
│   └── VotingEscrow.mega
├── cross-chain/
│   ├── Bridge.mega
│   └── CrossChainAMM.mega
├── interfaces/
│   ├── IAMM.mega
│   ├── ILendingPool.mega
│   └── IPriceOracle.mega
├── libraries/
├── Math.mega
├── SafeTransfer.mega
└── ReentrancyGuard.mega
```

### Konfigurasi Advanced

Edit `omega.toml`:

```toml
[project]
name = "defi-protocol"
version = "1.0.0"
description = "Advanced DeFi Protocol built with OMEGA"
authors = ["DeFi Team <team@defi-protocol.com>"]
license = "MIT"

[targets]
evm = { enabled = true, network = "mainnet" }
solana = { enabled = true, network = "mainnet-beta" }
cosmos = { enabled = true, network = "cosmoshub-4" }

[build]
optimization = true
output_dir = "build"
source_dir = "contracts"
parallel = true
include_debug_info = false

[security]
enable_static_analysis = true
require_formal_verification = true
max_gas_limit = 15000000

[evm]
solidity_version = "0.8.19"
optimizer_runs = 1000000
via_ir = true

[solana]
anchor_version = "0.28.0"
rust_version = "1.70.0"
optimize_for_size = false

[cosmos]
cosmwasm_version = "1.3.0"
rust_version = "1.70.0"

[deployment]
evm = { 
    rpc_url = "${MAINNET_RPC_URL}",
    gas_price_strategy = "eip1559",
    verify_contracts = true
}
solana = { 
    rpc_url = "${SOLANA_MAINNET_RPC}",
    commitment = "finalized"
}
cosmos = {
    rpc_url = "${COSMOS_RPC_URL}",
    chain_id = "cosmoshub-4"
}
```

## 💱 Langkah 2: Implementasi AMM (Automated Market Maker)

### Core AMM Contract

Buat `contracts/core/AMM.mega`:

```omega
// AMM.mega - Automated Market Maker dengan Constant Product Formula
blockchain AMM {
    import "std/math/SafeMath.mega";
    import "std/security/ReentrancyGuard.mega";
    import "std/security/Pausable.mega";
    import "../interfaces/IERC20.mega";
    import "../libraries/Math.mega";
    
    extends ReentrancyGuard, Pausable {
        
        state {
            // Pool structure
            struct Pool {
                address token0;
                address token1;
                uint256 reserve0;
                uint256 reserve1;
                uint256 total_liquidity;
                uint256 fee_rate;           // Basis points (30 = 0.3%)
                uint256 last_update;
                bool active;
            }
            
            // Pool management
            mapping(bytes32 => Pool) public pools;
            mapping(address => mapping(bytes32 => uint256)) public liquidity_balances;
            mapping(bytes32 => address) public lp_tokens;
            
            // Protocol settings
            address public factory;
            address public fee_collector;
            uint256 public protocol_fee_rate;  // Basis points
            uint256 public minimum_liquidity;
            
            // Price oracle integration
            address public price_oracle;
            mapping(bytes32 => uint256) public cumulative_prices;
            
            // Constants
            uint256 constant MINIMUM_LIQUIDITY = 1000;
            uint256 constant MAX_FEE_RATE = 1000; // 10%
        }
        
        constructor(address _factory, address _fee_collector, address _price_oracle) {
            factory = _factory;
            fee_collector = _fee_collector;
            price_oracle = _price_oracle;
            protocol_fee_rate = 5; // 0.05%
            minimum_liquidity = MINIMUM_LIQUIDITY;
        }
        
        // Pool creation
        function create_pool(
            address token0,
            address token1,
            uint256 fee_rate
        ) public returns (bytes32 pool_id) {
            require(token0 != token1, "AMM: identical tokens");
            require(token0 != address(0) && token1 != address(0), "AMM: zero address");
            require(fee_rate <= MAX_FEE_RATE, "AMM: fee too high");
            
            // Sort tokens
            if (token0 > token1) {
                (token0, token1) = (token1, token0);
            }
            
            pool_id = keccak256(abi.encodePacked(token0, token1, fee_rate));
            require(pools[pool_id].token0 == address(0), "AMM: pool exists");
            
            // Create pool
            pools[pool_id] = Pool({
                token0: token0,
                token1: token1,
                reserve0: 0,
                reserve1: 0,
                total_liquidity: 0,
                fee_rate: fee_rate,
                last_update: block.timestamp,
                active: true
            });
            
            // Deploy LP token
            address lp_token = _deploy_lp_token(token0, token1, fee_rate);
            lp_tokens[pool_id] = lp_token;
            
            emit PoolCreated(pool_id, token0, token1, fee_rate, lp_token);
        }
        
        // Add liquidity
        function add_liquidity(
            bytes32 pool_id,
            uint256 amount0_desired,
            uint256 amount1_desired,
            uint256 amount0_min,
            uint256 amount1_min,
            address to,
            uint256 deadline
        ) public non_reentrant when_not_paused ensure_deadline(deadline) returns (
            uint256 amount0,
            uint256 amount1,
            uint256 liquidity
        ) {
            Pool storage pool = pools[pool_id];
            require(pool.active, "AMM: pool inactive");
            
            // Calculate optimal amounts
            (amount0, amount1) = _calculate_liquidity_amounts(
                pool,
                amount0_desired,
                amount1_desired,
                amount0_min,
                amount1_min
            );
            
            // Transfer tokens
            IERC20(pool.token0).transfer_from(msg.sender, address(this), amount0);
            IERC20(pool.token1).transfer_from(msg.sender, address(this), amount1);
            
            // Calculate liquidity tokens to mint
            if (pool.total_liquidity == 0) {
                liquidity = Math.sqrt(amount0 * amount1) - minimum_liquidity;
                // Lock minimum liquidity forever
                liquidity_balances[address(0)][pool_id] = minimum_liquidity;
            } else {
                liquidity = Math.min(
                    (amount0 * pool.total_liquidity) / pool.reserve0,
                    (amount1 * pool.total_liquidity) / pool.reserve1
                );
            }
            
            require(liquidity > 0, "AMM: insufficient liquidity minted");
            
            // Update pool state
            pool.reserve0 += amount0;
            pool.reserve1 += amount1;
            pool.total_liquidity += liquidity;
            pool.last_update = block.timestamp;
            
            // Update user balance
            liquidity_balances[to][pool_id] += liquidity;
            
            // Mint LP tokens
            ILPToken(lp_tokens[pool_id]).mint(to, liquidity);
            
            // Update price oracle
            _update_price_oracle(pool_id, pool.reserve0, pool.reserve1);
            
            emit LiquidityAdded(pool_id, to, amount0, amount1, liquidity);
        }
        
        // Remove liquidity
        function remove_liquidity(
            bytes32 pool_id,
            uint256 liquidity,
            uint256 amount0_min,
            uint256 amount1_min,
            address to,
            uint256 deadline
        ) public non_reentrant ensure_deadline(deadline) returns (
            uint256 amount0,
            uint256 amount1
        ) {
            Pool storage pool = pools[pool_id];
            require(liquidity > 0, "AMM: insufficient liquidity");
            require(liquidity_balances[msg.sender][pool_id] >= liquidity, "AMM: insufficient balance");
            
            // Calculate amounts to return
            amount0 = (liquidity * pool.reserve0) / pool.total_liquidity;
            amount1 = (liquidity * pool.reserve1) / pool.total_liquidity;
            
            require(amount0 >= amount0_min, "AMM: insufficient amount0");
            require(amount1 >= amount1_min, "AMM: insufficient amount1");
            
            // Update state
            liquidity_balances[msg.sender][pool_id] -= liquidity;
            pool.reserve0 -= amount0;
            pool.reserve1 -= amount1;
            pool.total_liquidity -= liquidity;
            pool.last_update = block.timestamp;
            
            // Burn LP tokens
            ILPToken(lp_tokens[pool_id]).burn(msg.sender, liquidity);
            
            // Transfer tokens
            IERC20(pool.token0).transfer(to, amount0);
            IERC20(pool.token1).transfer(to, amount1);
            
            // Update price oracle
            _update_price_oracle(pool_id, pool.reserve0, pool.reserve1);
            
            emit LiquidityRemoved(pool_id, to, amount0, amount1, liquidity);
        }
        
        // Swap tokens
        function swap_exact_tokens_for_tokens(
            uint256 amount_in,
            uint256 amount_out_min,
            bytes32[] calldata path,
            address to,
            uint256 deadline
        ) external non_reentrant when_not_paused ensure_deadline(deadline) returns (
            uint256[] memory amounts
        ) {
            amounts = get_amounts_out(amount_in, path);
            require(amounts[amounts.length - 1] >= amount_out_min, "AMM: insufficient output amount");
            
            // Execute swaps
            _execute_swap_path(amounts, path, to);
            
            emit Swap(msg.sender, path[0], amount_in, amounts[amounts.length - 1]);
        }
        
        // Internal swap execution
        function _execute_swap_path(
            uint256[] memory amounts,
            bytes32[] memory path,
            address to
        ) internal {
            for (uint256 i = 0; i < path.length; i++) {
                bytes32 pool_id = path[i];
                Pool storage pool = pools[pool_id];
                
                uint256 amount_in = amounts[i];
                uint256 amount_out = amounts[i + 1];
                
                // Determine token direction
                bool zero_for_one = _determine_swap_direction(pool_id, i == 0 ? msg.sender : address(this));
                
                // Execute swap
                if (zero_for_one) {
                    _swap(pool_id, amount_in, 0, amount_out, 0, i == path.length - 1 ? to : address(this));
                } else {
                    _swap(pool_id, 0, amount_in, 0, amount_out, i == path.length - 1 ? to : address(this));
                }
            }
        }
        
        // Core swap function
        function _swap(
            bytes32 pool_id,
            uint256 amount0_in,
            uint256 amount1_in,
            uint256 amount0_out,
            uint256 amount1_out,
            address to
        ) internal {
            Pool storage pool = pools[pool_id];
            require(amount0_out > 0 || amount1_out > 0, "AMM: insufficient output amount");
            require(amount0_out < pool.reserve0 && amount1_out < pool.reserve1, "AMM: insufficient liquidity");
            
            // Transfer tokens out
            if (amount0_out > 0) IERC20(pool.token0).transfer(to, amount0_out);
            if (amount1_out > 0) IERC20(pool.token1).transfer(to, amount1_out);
            
            // Transfer tokens in
            if (amount0_in > 0) {
                IERC20(pool.token0).transfer_from(msg.sender, address(this), amount0_in);
            }
            if (amount1_in > 0) {
                IERC20(pool.token1).transfer_from(msg.sender, address(this), amount1_in);
            }
            
            // Update reserves
            uint256 balance0 = IERC20(pool.token0).balance_of(address(this));
            uint256 balance1 = IERC20(pool.token1).balance_of(address(this));
            
            // Apply fees and validate constant product
            uint256 amount0_in_with_fee = amount0_in * (10000 - pool.fee_rate) / 10000;
            uint256 amount1_in_with_fee = amount1_in * (10000 - pool.fee_rate) / 10000;
            
            require(
                balance0 * balance1 >= 
                (pool.reserve0 - amount0_out + amount0_in_with_fee) * 
                (pool.reserve1 - amount1_out + amount1_in_with_fee),
                "AMM: K invariant violated"
            );
            
            // Update pool state
            pool.reserve0 = balance0;
            pool.reserve1 = balance1;
            pool.last_update = block.timestamp;
            
            // Collect protocol fees
            _collect_protocol_fees(pool_id, amount0_in, amount1_in);
            
            // Update price oracle
            _update_price_oracle(pool_id, pool.reserve0, pool.reserve1);
        }
        
        // Price calculation functions
        function get_amounts_out(uint256 amount_in, bytes32[] memory path) 
            public view returns (uint256[] memory amounts) {
            require(path.length >= 1, "AMM: invalid path");
            amounts = new uint256[](path.length + 1);
            amounts[0] = amount_in;
            
            for (uint256 i = 0; i < path.length; i++) {
                Pool storage pool = pools[path[i]];
                amounts[i + 1] = get_amount_out(amounts[i], pool.reserve0, pool.reserve1, pool.fee_rate);
            }
        }
        
        function get_amount_out(uint256 amount_in, uint256 reserve_in, uint256 reserve_out, uint256 fee_rate) 
            public pure returns (uint256 amount_out) {
            require(amount_in > 0, "AMM: insufficient input amount");
            require(reserve_in > 0 && reserve_out > 0, "AMM: insufficient liquidity");
            
            uint256 amount_in_with_fee = amount_in * (10000 - fee_rate);
            uint256 numerator = amount_in_with_fee * reserve_out;
            uint256 denominator = (reserve_in * 10000) + amount_in_with_fee;
            amount_out = numerator / denominator;
        }
        
        // Price oracle integration
        function _update_price_oracle(bytes32 pool_id, uint256 reserve0, uint256 reserve1) internal {
            if (price_oracle != address(0)) {
                IPriceOracle(price_oracle).update_price(pool_id, reserve0, reserve1);
            }
            
            // Update cumulative prices for TWAP
            Pool storage pool = pools[pool_id];
            uint256 time_elapsed = block.timestamp - pool.last_update;
            if (time_elapsed > 0 && reserve0 != 0 && reserve1 != 0) {
                cumulative_prices[pool_id] += (reserve1 * 1e18 / reserve0) * time_elapsed;
            }
        }
        
        // Administrative functions
        function set_protocol_fee_rate(uint256 new_rate) external only_owner {
            require(new_rate <= 100, "AMM: fee too high"); // Max 1%
            protocol_fee_rate = new_rate;
            emit ProtocolFeeRateUpdated(new_rate);
        }
        
        function pause_pool(bytes32 pool_id) external only_owner {
            pools[pool_id].active = false;
            emit PoolPaused(pool_id);
        }
        
        function unpause_pool(bytes32 pool_id) external only_owner {
            pools[pool_id].active = true;
            emit PoolUnpaused(pool_id);
        }
        
        // Helper functions
        function _calculate_liquidity_amounts(
            Pool storage pool,
            uint256 amount0_desired,
            uint256 amount1_desired,
            uint256 amount0_min,
            uint256 amount1_min
        ) internal view returns (uint256 amount0, uint256 amount1) {
            if (pool.reserve0 == 0 && pool.reserve1 == 0) {
                (amount0, amount1) = (amount0_desired, amount1_desired);
            } else {
                uint256 amount1_optimal = (amount0_desired * pool.reserve1) / pool.reserve0;
                if (amount1_optimal <= amount1_desired) {
                    require(amount1_optimal >= amount1_min, "AMM: insufficient amount1");
                    (amount0, amount1) = (amount0_desired, amount1_optimal);
                } else {
                    uint256 amount0_optimal = (amount1_desired * pool.reserve0) / pool.reserve1;
                    assert(amount0_optimal <= amount0_desired);
                    require(amount0_optimal >= amount0_min, "AMM: insufficient amount0");
                    (amount0, amount1) = (amount0_optimal, amount1_desired);
                }
            }
        }
        
        function _collect_protocol_fees(bytes32 pool_id, uint256 amount0_in, uint256 amount1_in) internal {
            if (protocol_fee_rate > 0) {
                Pool storage pool = pools[pool_id];
                uint256 fee0 = (amount0_in * protocol_fee_rate) / 10000;
                uint256 fee1 = (amount1_in * protocol_fee_rate) / 10000;
                
                if (fee0 > 0) IERC20(pool.token0).transfer(fee_collector, fee0);
                if (fee1 > 0) IERC20(pool.token1).transfer(fee_collector, fee1);
            }
        }
        
        function _deploy_lp_token(address token0, address token1, uint256 fee_rate) internal returns (address) {
            // Deploy new LP token contract
            // Implementation depends on target blockchain
            return address(0); // Placeholder
        }
        
        // Modifiers
        modifier ensure_deadline(uint256 deadline) {
            require(deadline >= block.timestamp, "AMM: expired");
            _;
        }
        
        modifier only_owner() {
            require(msg.sender == factory, "AMM: only factory");
            _;
        }
        
        // Events
        event PoolCreated(bytes32 indexed pool_id, address indexed token0, address indexed token1, uint256 fee_rate, address lp_token);
        event LiquidityAdded(bytes32 indexed pool_id, address indexed provider, uint256 amount0, uint256 amount1, uint256 liquidity);
        event LiquidityRemoved(bytes32 indexed pool_id, address indexed provider, uint256 amount0, uint256 amount1, uint256 liquidity);
        event Swap(address indexed user, bytes32 indexed pool_id, uint256 amount_in, uint256 amount_out);
        event ProtocolFeeRateUpdated(uint256 new_rate);
        event PoolPaused(bytes32 indexed pool_id);
        event PoolUnpaused(bytes32 indexed pool_id);
    }
}