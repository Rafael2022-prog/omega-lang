#!/bin/bash

# OMEGA Performance Benchmarking Script
# Comprehensive performance testing and profiling

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
OMEGA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BENCHMARK_RESULTS_DIR="${OMEGA_ROOT}/benchmark_reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="${BENCHMARK_RESULTS_DIR}/performance_report_${TIMESTAMP}.json"

# Create results directory
mkdir -p "${BENCHMARK_RESULTS_DIR}"

echo -e "${BLUE}⚡ OMEGA Performance Benchmarking Suite${NC}"
echo -e "${BLUE}=======================================${NC}"
echo "Timestamp: $(date)"
echo "OMEGA Root: ${OMEGA_ROOT}"
echo "Report File: ${REPORT_FILE}"
echo ""

# Initialize report
cat > "${REPORT_FILE}" << EOF
{
  "benchmark_timestamp": "$(date -Iseconds)",
  "omega_version": "1.0.0",
  "system_info": {
    "os": "$(uname -s)",
    "arch": "$(uname -m)",
    "cpu_cores": "$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 'unknown')",
    "memory_gb": "$(free -g 2>/dev/null | awk '/^Mem:/{print $2}' || echo 'unknown')"
  },
  "benchmark_results": {
EOF

# Function to log benchmark results
log_benchmark() {
    local test_name="$1"
    local metric="$2"
    local value="$3"
    local unit="$4"
    local status="${5:-PASS}"
    
    echo -e "${BLUE}[$test_name]${NC} $metric: $value $unit"
    
    # Append to JSON report
    cat >> "${REPORT_FILE}" << EOF
    "$test_name": {
      "metric": "$metric",
      "value": $value,
      "unit": "$unit",
      "status": "$status",
      "timestamp": "$(date -Iseconds)"
    },
EOF
}

# Function to measure execution time
measure_time() {
    local start_time=$(date +%s.%N)
    "$@"
    local end_time=$(date +%s.%N)
    echo "$(echo "$end_time - $start_time" | bc -l)"
}

# Ensure OMEGA is built
echo -e "${YELLOW}🔨 Building OMEGA for benchmarking...${NC}"
cargo build --release --bin omega

# 1. Compilation Speed Benchmarks
echo -e "${YELLOW}⚡ Compilation Speed Benchmarks...${NC}"

# Simple contract compilation
if [ -f "${OMEGA_ROOT}/examples/basic_token.omega" ]; then
    COMPILE_TIME=$(measure_time "${OMEGA_ROOT}/target/release/omega" compile "${OMEGA_ROOT}/examples/basic_token.omega" --target evm)
    log_benchmark "simple_compilation" "compilation_time" "${COMPILE_TIME}" "seconds"
else
    echo "Creating test contract for benchmarking..."
    mkdir -p "${OMEGA_ROOT}/benchmark_tests"
    cat > "${OMEGA_ROOT}/benchmark_tests/simple_test.omega" << 'EOF'
blockchain SimpleTest {
    state {
        uint256 value;
        mapping(address => uint256) balances;
    }
    
    constructor(uint256 initial_value) {
        value = initial_value;
    }
    
    function set_value(uint256 new_value) public {
        value = new_value;
    }
    
    function get_value() public view returns (uint256) {
        return value;
    }
}
EOF
    COMPILE_TIME=$(measure_time "${OMEGA_ROOT}/target/release/omega" compile "${OMEGA_ROOT}/benchmark_tests/simple_test.omega" --target evm)
    log_benchmark "simple_compilation" "compilation_time" "${COMPILE_TIME}" "seconds"
fi

# Complex contract compilation
cat > "${OMEGA_ROOT}/benchmark_tests/complex_test.omega" << 'EOF'
blockchain ComplexDeFiProtocol {
    state {
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        mapping(address => uint256) stakes;
        mapping(address => uint256) rewards;
        mapping(address => uint256) last_claim_time;
        
        uint256 total_supply;
        uint256 total_staked;
        uint256 reward_rate;
        uint256 reward_pool;
        
        address owner;
        bool paused;
        
        struct LiquidityPool {
            uint256 token_a_reserve;
            uint256 token_b_reserve;
            uint256 total_liquidity;
            mapping(address => uint256) liquidity_shares;
        }
        
        mapping(bytes32 => LiquidityPool) pools;
        bytes32[] pool_ids;
    }
    
    constructor(uint256 initial_supply, uint256 initial_reward_rate) {
        owner = msg.sender;
        total_supply = initial_supply;
        reward_rate = initial_reward_rate;
        balances[msg.sender] = initial_supply;
    }
    
    function transfer(address to, uint256 amount) public returns (bool) {
        require(!paused, "Contract is paused");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        require(to != address(0), "Invalid recipient");
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
        
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function stake(uint256 amount) public {
        require(!paused, "Contract is paused");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        update_rewards(msg.sender);
        
        balances[msg.sender] -= amount;
        stakes[msg.sender] += amount;
        total_staked += amount;
        
        emit Staked(msg.sender, amount);
    }
    
    function unstake(uint256 amount) public {
        require(stakes[msg.sender] >= amount, "Insufficient stake");
        
        update_rewards(msg.sender);
        
        stakes[msg.sender] -= amount;
        total_staked -= amount;
        balances[msg.sender] += amount;
        
        emit Unstaked(msg.sender, amount);
    }
    
    function claim_rewards() public {
        update_rewards(msg.sender);
        
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards to claim");
        require(reward_pool >= reward, "Insufficient reward pool");
        
        rewards[msg.sender] = 0;
        reward_pool -= reward;
        balances[msg.sender] += reward;
        
        emit RewardsClaimed(msg.sender, reward);
    }
    
    function add_liquidity(bytes32 pool_id, uint256 amount_a, uint256 amount_b) public {
        require(!paused, "Contract is paused");
        require(amount_a > 0 && amount_b > 0, "Invalid amounts");
        
        LiquidityPool storage pool = pools[pool_id];
        
        if (pool.total_liquidity == 0) {
            pool.token_a_reserve = amount_a;
            pool.token_b_reserve = amount_b;
            pool.total_liquidity = sqrt(amount_a * amount_b);
            pool.liquidity_shares[msg.sender] = pool.total_liquidity;
        } else {
            uint256 liquidity_a = (amount_a * pool.total_liquidity) / pool.token_a_reserve;
            uint256 liquidity_b = (amount_b * pool.total_liquidity) / pool.token_b_reserve;
            uint256 liquidity = min(liquidity_a, liquidity_b);
            
            pool.token_a_reserve += amount_a;
            pool.token_b_reserve += amount_b;
            pool.total_liquidity += liquidity;
            pool.liquidity_shares[msg.sender] += liquidity;
        }
        
        emit LiquidityAdded(msg.sender, pool_id, amount_a, amount_b);
    }
    
    function swap(bytes32 pool_id, uint256 amount_in, bool a_for_b) public returns (uint256) {
        require(!paused, "Contract is paused");
        require(amount_in > 0, "Invalid input amount");
        
        LiquidityPool storage pool = pools[pool_id];
        require(pool.total_liquidity > 0, "Pool does not exist");
        
        uint256 amount_out;
        if (a_for_b) {
            amount_out = (amount_in * pool.token_b_reserve) / (pool.token_a_reserve + amount_in);
            pool.token_a_reserve += amount_in;
            pool.token_b_reserve -= amount_out;
        } else {
            amount_out = (amount_in * pool.token_a_reserve) / (pool.token_b_reserve + amount_in);
            pool.token_b_reserve += amount_in;
            pool.token_a_reserve -= amount_out;
        }
        
        emit Swap(msg.sender, pool_id, amount_in, amount_out, a_for_b);
        return amount_out;
    }
    
    function update_rewards(address user) internal {
        if (stakes[user] > 0) {
            uint256 time_diff = block.timestamp - last_claim_time[user];
            uint256 reward = (stakes[user] * reward_rate * time_diff) / (365 days * 100);
            rewards[user] += reward;
        }
        last_claim_time[user] = block.timestamp;
    }
    
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }
    
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event LiquidityAdded(address indexed user, bytes32 indexed pool_id, uint256 amount_a, uint256 amount_b);
    event Swap(address indexed user, bytes32 indexed pool_id, uint256 amount_in, uint256 amount_out, bool a_for_b);
}
EOF

COMPLEX_COMPILE_TIME=$(measure_time "${OMEGA_ROOT}/target/release/omega" compile "${OMEGA_ROOT}/benchmark_tests/complex_test.omega" --target evm)
log_benchmark "complex_compilation" "compilation_time" "${COMPLEX_COMPILE_TIME}" "seconds"

# 2. Memory Usage Benchmarks
echo -e "${YELLOW}💾 Memory Usage Benchmarks...${NC}"

# Measure memory usage during compilation
if command -v /usr/bin/time &> /dev/null; then
    MEMORY_OUTPUT=$(/usr/bin/time -v "${OMEGA_ROOT}/target/release/omega" compile "${OMEGA_ROOT}/benchmark_tests/complex_test.omega" --target evm 2>&1 | grep "Maximum resident set size")
    MEMORY_KB=$(echo "$MEMORY_OUTPUT" | grep -o '[0-9]*')
    MEMORY_MB=$((MEMORY_KB / 1024))
    log_benchmark "memory_usage" "peak_memory" "$MEMORY_MB" "MB"
elif command -v time &> /dev/null; then
    # macOS time command
    TIME_OUTPUT=$(time "${OMEGA_ROOT}/target/release/omega" compile "${OMEGA_ROOT}/benchmark_tests/complex_test.omega" --target evm 2>&1)
    echo "Memory measurement not available on this system"
    log_benchmark "memory_usage" "peak_memory" "0" "MB" "SKIP"
else
    log_benchmark "memory_usage" "peak_memory" "0" "MB" "SKIP"
fi

# 3. Binary Size Analysis
echo -e "${YELLOW}📦 Binary Size Analysis...${NC}"

BINARY_SIZE=$(stat -f%z "${OMEGA_ROOT}/target/release/omega" 2>/dev/null || stat -c%s "${OMEGA_ROOT}/target/release/omega" 2>/dev/null || echo "0")
BINARY_SIZE_MB=$((BINARY_SIZE / 1024 / 1024))
log_benchmark "binary_size" "executable_size" "$BINARY_SIZE_MB" "MB"

# 4. Throughput Benchmarks
echo -e "${YELLOW}🚀 Throughput Benchmarks...${NC}"

# Create multiple test files for batch compilation
mkdir -p "${OMEGA_ROOT}/benchmark_tests/batch"
for i in {1..10}; do
    cat > "${OMEGA_ROOT}/benchmark_tests/batch/test_${i}.omega" << EOF
blockchain BatchTest${i} {
    state {
        uint256 value_${i};
        mapping(address => uint256) balances_${i};
    }
    
    function set_value_${i}(uint256 new_value) public {
        value_${i} = new_value;
    }
    
    function get_value_${i}() public view returns (uint256) {
        return value_${i};
    }
}
EOF
done

# Measure batch compilation time
BATCH_START_TIME=$(date +%s.%N)
for i in {1..10}; do
    "${OMEGA_ROOT}/target/release/omega" compile "${OMEGA_ROOT}/benchmark_tests/batch/test_${i}.omega" --target evm > /dev/null 2>&1
done
BATCH_END_TIME=$(date +%s.%N)
BATCH_TOTAL_TIME=$(echo "$BATCH_END_TIME - $BATCH_START_TIME" | bc -l)
THROUGHPUT=$(echo "scale=2; 10 / $BATCH_TOTAL_TIME" | bc -l)

log_benchmark "throughput" "contracts_per_second" "$THROUGHPUT" "contracts/sec"

# 5. Cross-compilation Performance
echo -e "${YELLOW}🎯 Cross-compilation Performance...${NC}"

# EVM target
EVM_TIME=$(measure_time "${OMEGA_ROOT}/target/release/omega" compile "${OMEGA_ROOT}/benchmark_tests/simple_test.omega" --target evm)
log_benchmark "evm_compilation" "compilation_time" "$EVM_TIME" "seconds"

# Solana target
SOLANA_TIME=$(measure_time "${OMEGA_ROOT}/target/release/omega" compile "${OMEGA_ROOT}/benchmark_tests/simple_test.omega" --target solana)
log_benchmark "solana_compilation" "compilation_time" "$SOLANA_TIME" "seconds"

# 6. Optimization Level Benchmarks
echo -e "${YELLOW}⚙️ Optimization Level Benchmarks...${NC}"

# Debug build
DEBUG_TIME=$(measure_time "${OMEGA_ROOT}/target/release/omega" compile "${OMEGA_ROOT}/benchmark_tests/simple_test.omega" --target evm --optimization debug)
log_benchmark "debug_optimization" "compilation_time" "$DEBUG_TIME" "seconds"

# Release build
RELEASE_TIME=$(measure_time "${OMEGA_ROOT}/target/release/omega" compile "${OMEGA_ROOT}/benchmark_tests/simple_test.omega" --target evm --optimization release)
log_benchmark "release_optimization" "compilation_time" "$RELEASE_TIME" "seconds"

# 7. Concurrent Compilation Test
echo -e "${YELLOW}🔄 Concurrent Compilation Test...${NC}"

# Run multiple compilations in parallel
CONCURRENT_START_TIME=$(date +%s.%N)
for i in {1..5}; do
    "${OMEGA_ROOT}/target/release/omega" compile "${OMEGA_ROOT}/benchmark_tests/batch/test_${i}.omega" --target evm > /dev/null 2>&1 &
done
wait
CONCURRENT_END_TIME=$(date +%s.%N)
CONCURRENT_TIME=$(echo "$CONCURRENT_END_TIME - $CONCURRENT_START_TIME" | bc -l)

log_benchmark "concurrent_compilation" "parallel_compilation_time" "$CONCURRENT_TIME" "seconds"

# 8. Cache Performance
echo -e "${YELLOW}💨 Cache Performance...${NC}"

# First compilation (cold cache)
COLD_CACHE_TIME=$(measure_time "${OMEGA_ROOT}/target/release/omega" compile "${OMEGA_ROOT}/benchmark_tests/simple_test.omega" --target evm --no-cache)
log_benchmark "cold_cache" "compilation_time" "$COLD_CACHE_TIME" "seconds"

# Second compilation (warm cache)
WARM_CACHE_TIME=$(measure_time "${OMEGA_ROOT}/target/release/omega" compile "${OMEGA_ROOT}/benchmark_tests/simple_test.omega" --target evm)
log_benchmark "warm_cache" "compilation_time" "$WARM_CACHE_TIME" "seconds"

# Cache efficiency
if (( $(echo "$COLD_CACHE_TIME > 0" | bc -l) )); then
    CACHE_SPEEDUP=$(echo "scale=2; $COLD_CACHE_TIME / $WARM_CACHE_TIME" | bc -l)
    log_benchmark "cache_efficiency" "speedup_factor" "$CACHE_SPEEDUP" "x"
fi

# Close JSON report
sed -i '$ s/,$//' "${REPORT_FILE}"  # Remove last comma
cat >> "${REPORT_FILE}" << EOF
  },
  "benchmark_completed": "$(date -Iseconds)"
}
EOF

# Generate performance summary
echo ""
echo -e "${BLUE}📊 Performance Benchmark Summary${NC}"
echo -e "${BLUE}=================================${NC}"

echo -e "${GREEN}⚡ Compilation Performance:${NC}"
echo "  Simple Contract: ${COMPILE_TIME}s"
echo "  Complex Contract: ${COMPLEX_COMPILE_TIME}s"
echo "  Throughput: ${THROUGHPUT} contracts/sec"

echo -e "${GREEN}💾 Resource Usage:${NC}"
echo "  Binary Size: ${BINARY_SIZE_MB}MB"
if [ "$MEMORY_MB" != "0" ]; then
    echo "  Peak Memory: ${MEMORY_MB}MB"
fi

echo -e "${GREEN}🎯 Target Performance:${NC}"
echo "  EVM: ${EVM_TIME}s"
echo "  Solana: ${SOLANA_TIME}s"

echo -e "${GREEN}💨 Cache Performance:${NC}"
echo "  Cold Cache: ${COLD_CACHE_TIME}s"
echo "  Warm Cache: ${WARM_CACHE_TIME}s"
if (( $(echo "$COLD_CACHE_TIME > 0" | bc -l) )); then
    echo "  Speedup: ${CACHE_SPEEDUP}x"
fi

echo ""
echo "Detailed benchmark report saved to: ${REPORT_FILE}"

# Performance thresholds check
PERFORMANCE_ISSUES=0

# Check if compilation times are reasonable
if (( $(echo "$COMPILE_TIME > 5.0" | bc -l) )); then
    echo -e "${YELLOW}⚠️  Simple compilation time is high: ${COMPILE_TIME}s${NC}"
    ((PERFORMANCE_ISSUES++))
fi

if (( $(echo "$COMPLEX_COMPILE_TIME > 30.0" | bc -l) )); then
    echo -e "${YELLOW}⚠️  Complex compilation time is high: ${COMPLEX_COMPILE_TIME}s${NC}"
    ((PERFORMANCE_ISSUES++))
fi

# Check binary size
if [ "$BINARY_SIZE_MB" -gt 100 ]; then
    echo -e "${YELLOW}⚠️  Binary size is large: ${BINARY_SIZE_MB}MB${NC}"
    ((PERFORMANCE_ISSUES++))
fi

# Final assessment
if [ "$PERFORMANCE_ISSUES" -eq 0 ]; then
    echo -e "${GREEN}✅ All performance benchmarks passed${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  Performance benchmarks completed with $PERFORMANCE_ISSUES concerns${NC}"
    exit 1
fi