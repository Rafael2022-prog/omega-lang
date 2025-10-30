#!/bin/bash

# OMEGA Security Scanning Script
# Comprehensive security assessment before deployment

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
OMEGA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCAN_RESULTS_DIR="${OMEGA_ROOT}/security_reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="${SCAN_RESULTS_DIR}/security_report_${TIMESTAMP}.json"

# Create results directory
mkdir -p "${SCAN_RESULTS_DIR}"

echo -e "${BLUE}🔒 OMEGA Security Scanning Suite${NC}"
echo -e "${BLUE}=================================${NC}"
echo "Timestamp: $(date)"
echo "OMEGA Root: ${OMEGA_ROOT}"
echo "Report File: ${REPORT_FILE}"
echo ""

# Initialize report
cat > "${REPORT_FILE}" << EOF
{
  "scan_timestamp": "$(date -Iseconds)",
  "omega_version": "1.0.0",
  "scan_results": {
EOF

# Function to log results
log_result() {
    local category="$1"
    local status="$2"
    local message="$3"
    local details="${4:-}"
    
    echo -e "${BLUE}[$category]${NC} $message"
    
    # Append to JSON report
    cat >> "${REPORT_FILE}" << EOF
    "$category": {
      "status": "$status",
      "message": "$message",
      "details": "$details",
      "timestamp": "$(date -Iseconds)"
    },
EOF
}

# 1. Dependency Vulnerability Scanning
echo -e "${YELLOW}🔍 Scanning Dependencies...${NC}"
if command -v cargo-audit &> /dev/null; then
    if cargo audit --json > "${SCAN_RESULTS_DIR}/cargo_audit_${TIMESTAMP}.json" 2>&1; then
        log_result "dependency_scan" "PASS" "No known vulnerabilities found in dependencies"
    else
        log_result "dependency_scan" "FAIL" "Vulnerabilities found in dependencies" "$(cat "${SCAN_RESULTS_DIR}/cargo_audit_${TIMESTAMP}.json")"
    fi
else
    echo "Installing cargo-audit..."
    cargo install cargo-audit
    cargo audit --json > "${SCAN_RESULTS_DIR}/cargo_audit_${TIMESTAMP}.json" 2>&1
    log_result "dependency_scan" "PASS" "Dependency scan completed"
fi

# 2. Static Code Analysis
echo -e "${YELLOW}🔍 Static Code Analysis...${NC}"
if command -v clippy &> /dev/null; then
    if cargo clippy --all-targets --all-features -- -D warnings > "${SCAN_RESULTS_DIR}/clippy_${TIMESTAMP}.log" 2>&1; then
        log_result "static_analysis" "PASS" "No clippy warnings found"
    else
        log_result "static_analysis" "WARN" "Clippy warnings found" "$(cat "${SCAN_RESULTS_DIR}/clippy_${TIMESTAMP}.log")"
    fi
else
    log_result "static_analysis" "SKIP" "Clippy not available"
fi

# 3. Memory Safety Analysis
echo -e "${YELLOW}🔍 Memory Safety Analysis...${NC}"
if command -v valgrind &> /dev/null; then
    # Build debug version for valgrind
    cargo build --bin omega
    if valgrind --tool=memcheck --leak-check=full --show-leak-kinds=all --track-origins=yes \
       ./target/debug/omega --version > "${SCAN_RESULTS_DIR}/valgrind_${TIMESTAMP}.log" 2>&1; then
        log_result "memory_safety" "PASS" "No memory leaks detected"
    else
        log_result "memory_safety" "WARN" "Memory issues detected" "$(cat "${SCAN_RESULTS_DIR}/valgrind_${TIMESTAMP}.log")"
    fi
else
    log_result "memory_safety" "SKIP" "Valgrind not available"
fi

# 4. Container Security Scanning
echo -e "${YELLOW}🔍 Container Security Scanning...${NC}"
if command -v docker &> /dev/null && [ -f "${OMEGA_ROOT}/Dockerfile" ]; then
    # Build container
    docker build -t omega-security-scan:latest "${OMEGA_ROOT}"
    
    # Scan with Trivy if available
    if command -v trivy &> /dev/null; then
        if trivy image --format json --output "${SCAN_RESULTS_DIR}/trivy_${TIMESTAMP}.json" omega-security-scan:latest; then
            log_result "container_security" "PASS" "Container security scan completed"
        else
            log_result "container_security" "FAIL" "Container vulnerabilities found"
        fi
    else
        log_result "container_security" "SKIP" "Trivy not available"
    fi
else
    log_result "container_security" "SKIP" "Docker or Dockerfile not available"
fi

# 5. Secrets Detection
echo -e "${YELLOW}🔍 Secrets Detection...${NC}"
if command -v gitleaks &> /dev/null; then
    if gitleaks detect --source "${OMEGA_ROOT}" --report-format json --report-path "${SCAN_RESULTS_DIR}/gitleaks_${TIMESTAMP}.json"; then
        log_result "secrets_detection" "PASS" "No secrets detected"
    else
        log_result "secrets_detection" "FAIL" "Potential secrets found"
    fi
else
    # Manual basic secrets check
    if grep -r -i -E "(password|secret|key|token|api_key)" "${OMEGA_ROOT}/src" --exclude-dir=target > "${SCAN_RESULTS_DIR}/manual_secrets_${TIMESTAMP}.log" 2>&1; then
        log_result "secrets_detection" "WARN" "Potential secrets found in manual scan"
    else
        log_result "secrets_detection" "PASS" "No obvious secrets found in manual scan"
    fi
fi

# 6. License Compliance Check
echo -e "${YELLOW}🔍 License Compliance...${NC}"
if command -v cargo-license &> /dev/null; then
    cargo license --json > "${SCAN_RESULTS_DIR}/licenses_${TIMESTAMP}.json" 2>&1
    log_result "license_compliance" "PASS" "License information collected"
else
    echo "Installing cargo-license..."
    cargo install cargo-license
    cargo license --json > "${SCAN_RESULTS_DIR}/licenses_${TIMESTAMP}.json" 2>&1
    log_result "license_compliance" "PASS" "License information collected"
fi

# 7. Binary Analysis
echo -e "${YELLOW}🔍 Binary Analysis...${NC}"
if [ -f "${OMEGA_ROOT}/target/release/omega" ]; then
    # Check for debug symbols
    if file "${OMEGA_ROOT}/target/release/omega" | grep -q "not stripped"; then
        log_result "binary_analysis" "WARN" "Binary contains debug symbols"
    else
        log_result "binary_analysis" "PASS" "Binary is properly stripped"
    fi
    
    # Check binary size
    BINARY_SIZE=$(stat -f%z "${OMEGA_ROOT}/target/release/omega" 2>/dev/null || stat -c%s "${OMEGA_ROOT}/target/release/omega" 2>/dev/null || echo "0")
    if [ "$BINARY_SIZE" -gt 50000000 ]; then  # 50MB
        log_result "binary_size" "WARN" "Binary size is large: ${BINARY_SIZE} bytes"
    else
        log_result "binary_size" "PASS" "Binary size is acceptable: ${BINARY_SIZE} bytes"
    fi
else
    log_result "binary_analysis" "SKIP" "Release binary not found"
fi

# 8. Configuration Security
echo -e "${YELLOW}🔍 Configuration Security...${NC}"
CONFIG_ISSUES=0

# Check Cargo.toml for security settings
if ! grep -q "overflow-checks = true" "${OMEGA_ROOT}/Cargo.toml"; then
    ((CONFIG_ISSUES++))
fi

if ! grep -q "panic = \"abort\"" "${OMEGA_ROOT}/Cargo.toml"; then
    ((CONFIG_ISSUES++))
fi

if [ "$CONFIG_ISSUES" -eq 0 ]; then
    log_result "config_security" "PASS" "Security configurations are properly set"
else
    log_result "config_security" "WARN" "Some security configurations missing: $CONFIG_ISSUES issues"
fi

# 9. Network Security (if applicable)
echo -e "${YELLOW}🔍 Network Security...${NC}"
if [ -f "${OMEGA_ROOT}/src/main.mega" ]; then
    if grep -q "bind\|listen\|server" "${OMEGA_ROOT}/src/main.mega"; then
        log_result "network_security" "INFO" "Network functionality detected - manual review recommended"
    else
        log_result "network_security" "PASS" "No network functionality detected"
    fi
fi

# 10. File Permissions Check
echo -e "${YELLOW}🔍 File Permissions...${NC}"
PERM_ISSUES=0

# Check for world-writable files
if find "${OMEGA_ROOT}" -type f -perm -002 | grep -q .; then
    ((PERM_ISSUES++))
fi

# Check for executable files that shouldn't be
if find "${OMEGA_ROOT}/src" -name "*.mega" -perm -111 | grep -q .; then
    ((PERM_ISSUES++))
fi

if [ "$PERM_ISSUES" -eq 0 ]; then
    log_result "file_permissions" "PASS" "File permissions are secure"
else
    log_result "file_permissions" "WARN" "File permission issues found: $PERM_ISSUES issues"
fi

# Close JSON report
sed -i '$ s/,$//' "${REPORT_FILE}"  # Remove last comma
cat >> "${REPORT_FILE}" << EOF
  },
  "scan_completed": "$(date -Iseconds)"
}
EOF

# Generate summary
echo ""
echo -e "${BLUE}📊 Security Scan Summary${NC}"
echo -e "${BLUE}========================${NC}"

PASS_COUNT=$(grep -c '"status": "PASS"' "${REPORT_FILE}" || echo "0")
WARN_COUNT=$(grep -c '"status": "WARN"' "${REPORT_FILE}" || echo "0")
FAIL_COUNT=$(grep -c '"status": "FAIL"' "${REPORT_FILE}" || echo "0")
SKIP_COUNT=$(grep -c '"status": "SKIP"' "${REPORT_FILE}" || echo "0")

echo -e "${GREEN}✅ PASS: $PASS_COUNT${NC}"
echo -e "${YELLOW}⚠️  WARN: $WARN_COUNT${NC}"
echo -e "${RED}❌ FAIL: $FAIL_COUNT${NC}"
echo -e "${BLUE}⏭️  SKIP: $SKIP_COUNT${NC}"

echo ""
echo "Detailed report saved to: ${REPORT_FILE}"

# Exit with appropriate code
if [ "$FAIL_COUNT" -gt 0 ]; then
    echo -e "${RED}❌ Security scan failed with $FAIL_COUNT critical issues${NC}"
    exit 1
elif [ "$WARN_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Security scan completed with $WARN_COUNT warnings${NC}"
    exit 2
else
    echo -e "${GREEN}✅ Security scan passed successfully${NC}"
    exit 0
fi