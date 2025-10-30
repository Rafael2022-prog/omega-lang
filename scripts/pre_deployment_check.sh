#!/bin/bash

# OMEGA Pre-Deployment Comprehensive Check
# Final validation before cloud deployment

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
OMEGA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECK_RESULTS_DIR="${OMEGA_ROOT}/deployment_checks"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
FINAL_REPORT="${CHECK_RESULTS_DIR}/deployment_readiness_${TIMESTAMP}.json"

# Create results directory
mkdir -p "${CHECK_RESULTS_DIR}"

echo -e "${PURPLE}🚀 OMEGA Pre-Deployment Comprehensive Check${NC}"
echo -e "${PURPLE}===========================================${NC}"
echo "Timestamp: $(date)"
echo "OMEGA Root: ${OMEGA_ROOT}"
echo "Final Report: ${FINAL_REPORT}"
echo ""

# Initialize final report
cat > "${FINAL_REPORT}" << EOF
{
  "deployment_check_timestamp": "$(date -Iseconds)",
  "omega_version": "1.0.0",
  "environment": "pre-production",
  "checks": {
EOF

# Global counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0
SKIPPED_CHECKS=0

# Function to log check results
log_check() {
    local check_name="$1"
    local status="$2"
    local message="$3"
    local details="${4:-}"
    
    ((TOTAL_CHECKS++))
    
    case "$status" in
        "PASS")
            echo -e "${GREEN}✅ [$check_name] $message${NC}"
            ((PASSED_CHECKS++))
            ;;
        "FAIL")
            echo -e "${RED}❌ [$check_name] $message${NC}"
            ((FAILED_CHECKS++))
            ;;
        "WARN")
            echo -e "${YELLOW}⚠️  [$check_name] $message${NC}"
            ((WARNING_CHECKS++))
            ;;
        "SKIP")
            echo -e "${BLUE}⏭️  [$check_name] $message${NC}"
            ((SKIPPED_CHECKS++))
            ;;
    esac
    
    # Append to JSON report
    cat >> "${FINAL_REPORT}" << EOF
    "$check_name": {
      "status": "$status",
      "message": "$message",
      "details": "$details",
      "timestamp": "$(date -Iseconds)"
    },
EOF
}

# 1. Environment Validation
echo -e "${CYAN}🌍 Environment Validation${NC}"
echo "=========================="

# Check required tools
REQUIRED_TOOLS=("cargo" "rustc" "git" "docker")
for tool in "${REQUIRED_TOOLS[@]}"; do
    if command -v "$tool" &> /dev/null; then
        VERSION=$($tool --version 2>/dev/null | head -n1 || echo "unknown")
        log_check "tool_$tool" "PASS" "$tool is available" "$VERSION"
    else
        log_check "tool_$tool" "FAIL" "$tool is not available"
    fi
done

# Check Rust version
RUST_VERSION=$(rustc --version | cut -d' ' -f2)
if [[ "$RUST_VERSION" =~ ^1\.(7[0-9]|[8-9][0-9]|[1-9][0-9][0-9]) ]]; then
    log_check "rust_version" "PASS" "Rust version is compatible" "$RUST_VERSION"
else
    log_check "rust_version" "FAIL" "Rust version is too old" "$RUST_VERSION"
fi

# 2. Source Code Validation
echo -e "${CYAN}📝 Source Code Validation${NC}"
echo "=========================="

# Check if all required files exist
REQUIRED_FILES=(
    "Cargo.toml"
    "src/main.mega"
    "src/lexer/lexer.mega"
    "src/parser/parser.mega"
    "src/semantic/analyzer.mega"
    "src/ir/optimizer.mega"
    "src/codegen/codegen.mega"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "${OMEGA_ROOT}/$file" ]; then
        log_check "file_$file" "PASS" "Required file exists" "$file"
    else
        log_check "file_$file" "FAIL" "Required file missing" "$file"
    fi
done

# Check for TODO/FIXME comments
TODO_COUNT=$(find "${OMEGA_ROOT}/src" -name "*.mega" -exec grep -c "TODO\|FIXME\|XXX" {} + 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
if [ "$TODO_COUNT" -eq 0 ]; then
    log_check "code_todos" "PASS" "No TODO/FIXME comments found"
elif [ "$TODO_COUNT" -lt 5 ]; then
    log_check "code_todos" "WARN" "$TODO_COUNT TODO/FIXME comments found"
else
    log_check "code_todos" "FAIL" "Too many TODO/FIXME comments: $TODO_COUNT"
fi

# 3. Build System Validation
echo -e "${CYAN}🔨 Build System Validation${NC}"
echo "==========================="

# Clean build test
if cargo clean && cargo build --release; then
    log_check "clean_build" "PASS" "Clean build successful"
else
    log_check "clean_build" "FAIL" "Clean build failed"
fi

# Check binary exists and is executable
if [ -x "${OMEGA_ROOT}/target/release/omega" ]; then
    log_check "binary_executable" "PASS" "Binary is executable"
else
    log_check "binary_executable" "FAIL" "Binary is not executable"
fi

# Test basic functionality
if "${OMEGA_ROOT}/target/release/omega" --version > /dev/null 2>&1; then
    log_check "basic_functionality" "PASS" "Basic functionality works"
else
    log_check "basic_functionality" "FAIL" "Basic functionality failed"
fi

# 4. Testing Validation
echo -e "${CYAN}🧪 Testing Validation${NC}"
echo "====================="

# Run unit tests
if cargo test --release > "${CHECK_RESULTS_DIR}/test_output_${TIMESTAMP}.log" 2>&1; then
    TEST_RESULTS=$(grep -E "test result:|passed|failed" "${CHECK_RESULTS_DIR}/test_output_${TIMESTAMP}.log" | tail -1)
    log_check "unit_tests" "PASS" "Unit tests passed" "$TEST_RESULTS"
else
    log_check "unit_tests" "FAIL" "Unit tests failed"
fi

# Check test coverage (if available)
if command -v cargo-tarpaulin &> /dev/null; then
    if cargo tarpaulin --out Json --output-dir "${CHECK_RESULTS_DIR}" > /dev/null 2>&1; then
        COVERAGE=$(jq -r '.files | map(.coverage) | add / length' "${CHECK_RESULTS_DIR}/tarpaulin-report.json" 2>/dev/null || echo "0")
        if (( $(echo "$COVERAGE >= 80" | bc -l) )); then
            log_check "test_coverage" "PASS" "Test coverage is adequate" "${COVERAGE}%"
        else
            log_check "test_coverage" "WARN" "Test coverage is low" "${COVERAGE}%"
        fi
    else
        log_check "test_coverage" "SKIP" "Coverage analysis failed"
    fi
else
    log_check "test_coverage" "SKIP" "Tarpaulin not available"
fi

# 5. Security Validation
echo -e "${CYAN}🔒 Security Validation${NC}"
echo "======================"

# Run security scan if script exists
if [ -x "${OMEGA_ROOT}/scripts/security_scan.sh" ]; then
    if "${OMEGA_ROOT}/scripts/security_scan.sh" > "${CHECK_RESULTS_DIR}/security_scan_${TIMESTAMP}.log" 2>&1; then
        log_check "security_scan" "PASS" "Security scan passed"
    else
        SCAN_EXIT_CODE=$?
        if [ "$SCAN_EXIT_CODE" -eq 2 ]; then
            log_check "security_scan" "WARN" "Security scan completed with warnings"
        else
            log_check "security_scan" "FAIL" "Security scan failed"
        fi
    fi
else
    log_check "security_scan" "SKIP" "Security scan script not available"
fi

# Check for hardcoded secrets
if grep -r -i -E "(password|secret|key|token|api_key)\s*=\s*['\"][^'\"]{8,}" "${OMEGA_ROOT}/src" > /dev/null 2>&1; then
    log_check "hardcoded_secrets" "FAIL" "Potential hardcoded secrets found"
else
    log_check "hardcoded_secrets" "PASS" "No hardcoded secrets detected"
fi

# 6. Performance Validation
echo -e "${CYAN}⚡ Performance Validation${NC}"
echo "========================="

# Run performance benchmarks if script exists
if [ -x "${OMEGA_ROOT}/scripts/performance_benchmark.sh" ]; then
    if "${OMEGA_ROOT}/scripts/performance_benchmark.sh" > "${CHECK_RESULTS_DIR}/performance_${TIMESTAMP}.log" 2>&1; then
        log_check "performance_benchmark" "PASS" "Performance benchmarks passed"
    else
        log_check "performance_benchmark" "WARN" "Performance benchmarks completed with concerns"
    fi
else
    log_check "performance_benchmark" "SKIP" "Performance benchmark script not available"
fi

# Check binary size
BINARY_SIZE=$(stat -f%z "${OMEGA_ROOT}/target/release/omega" 2>/dev/null || stat -c%s "${OMEGA_ROOT}/target/release/omega" 2>/dev/null || echo "0")
BINARY_SIZE_MB=$((BINARY_SIZE / 1024 / 1024))
if [ "$BINARY_SIZE_MB" -lt 50 ]; then
    log_check "binary_size" "PASS" "Binary size is reasonable" "${BINARY_SIZE_MB}MB"
elif [ "$BINARY_SIZE_MB" -lt 100 ]; then
    log_check "binary_size" "WARN" "Binary size is large" "${BINARY_SIZE_MB}MB"
else
    log_check "binary_size" "FAIL" "Binary size is too large" "${BINARY_SIZE_MB}MB"
fi

# 7. Documentation Validation
echo -e "${CYAN}📚 Documentation Validation${NC}"
echo "============================"

# Check required documentation files
DOC_FILES=("README.md" "LANGUAGE_SPECIFICATION.md" "COMPILER_ARCHITECTURE.md")
for doc in "${DOC_FILES[@]}"; do
    if [ -f "${OMEGA_ROOT}/$doc" ]; then
        WORD_COUNT=$(wc -w < "${OMEGA_ROOT}/$doc")
        if [ "$WORD_COUNT" -gt 100 ]; then
            log_check "doc_$doc" "PASS" "Documentation file is substantial" "${WORD_COUNT} words"
        else
            log_check "doc_$doc" "WARN" "Documentation file is too short" "${WORD_COUNT} words"
        fi
    else
        log_check "doc_$doc" "FAIL" "Documentation file missing" "$doc"
    fi
done

# 8. Container Validation
echo -e "${CYAN}🐳 Container Validation${NC}"
echo "======================="

# Check Dockerfile exists
if [ -f "${OMEGA_ROOT}/Dockerfile" ]; then
    log_check "dockerfile_exists" "PASS" "Dockerfile exists"
    
    # Try to build container
    if docker build -t omega-deployment-test:latest "${OMEGA_ROOT}" > "${CHECK_RESULTS_DIR}/docker_build_${TIMESTAMP}.log" 2>&1; then
        log_check "docker_build" "PASS" "Docker build successful"
        
        # Test container run
        if docker run --rm omega-deployment-test:latest omega --version > /dev/null 2>&1; then
            log_check "docker_run" "PASS" "Container runs successfully"
        else
            log_check "docker_run" "FAIL" "Container run failed"
        fi
        
        # Clean up test image
        docker rmi omega-deployment-test:latest > /dev/null 2>&1 || true
    else
        log_check "docker_build" "FAIL" "Docker build failed"
    fi
else
    log_check "dockerfile_exists" "FAIL" "Dockerfile missing"
fi

# 9. Kubernetes Validation
echo -e "${CYAN}☸️  Kubernetes Validation${NC}"
echo "========================="

# Check Kubernetes manifests
if [ -f "${OMEGA_ROOT}/kubernetes/deployment.yaml" ]; then
    log_check "k8s_manifests" "PASS" "Kubernetes manifests exist"
    
    # Validate YAML syntax
    if command -v kubectl &> /dev/null; then
        if kubectl apply --dry-run=client -f "${OMEGA_ROOT}/kubernetes/deployment.yaml" > /dev/null 2>&1; then
            log_check "k8s_validation" "PASS" "Kubernetes manifests are valid"
        else
            log_check "k8s_validation" "FAIL" "Kubernetes manifests validation failed"
        fi
    else
        log_check "k8s_validation" "SKIP" "kubectl not available"
    fi
else
    log_check "k8s_manifests" "WARN" "Kubernetes manifests missing"
fi

# 10. License and Legal Validation
echo -e "${CYAN}⚖️  License and Legal Validation${NC}"
echo "================================="

# Check license file
if [ -f "${OMEGA_ROOT}/LICENSE" ]; then
    log_check "license_file" "PASS" "License file exists"
else
    log_check "license_file" "FAIL" "License file missing"
fi

# Check copyright notices
if grep -r "Copyright" "${OMEGA_ROOT}/src" > /dev/null 2>&1; then
    log_check "copyright_notices" "PASS" "Copyright notices found"
else
    log_check "copyright_notices" "WARN" "No copyright notices found"
fi

# 11. Final Integration Test
echo -e "${CYAN}🔄 Final Integration Test${NC}"
echo "========================="

# Create a comprehensive test
mkdir -p "${CHECK_RESULTS_DIR}/integration_test"
cat > "${CHECK_RESULTS_DIR}/integration_test/final_test.omega" << 'EOF'
blockchain FinalDeploymentTest {
    state {
        uint256 deployment_timestamp;
        mapping(address => bool) verified_users;
        string version;
    }
    
    constructor() {
        deployment_timestamp = block.timestamp;
        version = "1.0.0";
    }
    
    function verify_deployment() public view returns (bool) {
        return deployment_timestamp > 0 && bytes(version).length > 0;
    }
    
    function get_version() public view returns (string memory) {
        return version;
    }
}
EOF

# Test compilation for all targets
INTEGRATION_PASSED=true
for target in evm solana; do
    if "${OMEGA_ROOT}/target/release/omega" compile "${CHECK_RESULTS_DIR}/integration_test/final_test.omega" --target "$target" > /dev/null 2>&1; then
        log_check "integration_$target" "PASS" "Integration test passed for $target"
    else
        log_check "integration_$target" "FAIL" "Integration test failed for $target"
        INTEGRATION_PASSED=false
    fi
done

if [ "$INTEGRATION_PASSED" = true ]; then
    log_check "integration_overall" "PASS" "All integration tests passed"
else
    log_check "integration_overall" "FAIL" "Some integration tests failed"
fi

# Close JSON report
sed -i '$ s/,$//' "${FINAL_REPORT}"  # Remove last comma
cat >> "${FINAL_REPORT}" << EOF
  },
  "summary": {
    "total_checks": $TOTAL_CHECKS,
    "passed": $PASSED_CHECKS,
    "failed": $FAILED_CHECKS,
    "warnings": $WARNING_CHECKS,
    "skipped": $SKIPPED_CHECKS,
    "success_rate": "$(echo "scale=2; $PASSED_CHECKS * 100 / $TOTAL_CHECKS" | bc -l)%"
  },
  "deployment_ready": $([ $FAILED_CHECKS -eq 0 ] && echo "true" || echo "false"),
  "check_completed": "$(date -Iseconds)"
}
EOF

# Generate final summary
echo ""
echo -e "${PURPLE}📊 Deployment Readiness Summary${NC}"
echo -e "${PURPLE}===============================${NC}"

echo -e "${GREEN}✅ PASSED: $PASSED_CHECKS${NC}"
echo -e "${YELLOW}⚠️  WARNINGS: $WARNING_CHECKS${NC}"
echo -e "${RED}❌ FAILED: $FAILED_CHECKS${NC}"
echo -e "${BLUE}⏭️  SKIPPED: $SKIPPED_CHECKS${NC}"
echo -e "${CYAN}📈 SUCCESS RATE: $(echo "scale=1; $PASSED_CHECKS * 100 / $TOTAL_CHECKS" | bc -l)%${NC}"

echo ""
echo "Detailed deployment readiness report: ${FINAL_REPORT}"

# Final decision
if [ "$FAILED_CHECKS" -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 OMEGA IS READY FOR DEPLOYMENT! 🎉${NC}"
    echo -e "${GREEN}All critical checks passed successfully.${NC}"
    if [ "$WARNING_CHECKS" -gt 0 ]; then
        echo -e "${YELLOW}Note: $WARNING_CHECKS warnings were found but don't block deployment.${NC}"
    fi
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo "1. Review the detailed report above"
    echo "2. Address any warnings if desired"
    echo "3. Proceed with cloud deployment"
    echo "4. Monitor deployment metrics"
    exit 0
else
    echo ""
    echo -e "${RED}❌ DEPLOYMENT BLOCKED${NC}"
    echo -e "${RED}$FAILED_CHECKS critical issues must be resolved before deployment.${NC}"
    echo ""
    echo -e "${CYAN}Required actions:${NC}"
    echo "1. Review failed checks in the detailed report"
    echo "2. Fix all critical issues"
    echo "3. Re-run this deployment check"
    echo "4. Ensure all checks pass before proceeding"
    exit 1
fi