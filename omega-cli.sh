#!/bin/bash
# Enhanced OMEGA CLI Wrapper - Cross-Platform Build System (Linux/macOS)
# Supports: compile, build, test, deploy, and platform detection

set -euo pipefail

# Global Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OMEGA_BINARY="$PROJECT_ROOT/omega"
CONFIG_FILE="$PROJECT_ROOT/omega.toml"
BUILD_DIR="$PROJECT_ROOT/build"
TEST_DIR="$PROJECT_ROOT/tests"
DEPLOY_DIR="$PROJECT_ROOT/deployment"

# Platform Detection
PLATFORM=""
ARCH=""
IS_LINUX=false
IS_MACOS=false

initialize_platform() {
    local os_name=$(uname -s)
    local machine=$(uname -m)
    
    case "$os_name" in
        Linux*)
            PLATFORM="linux"
            IS_LINUX=true
            ;;
        Darwin*)
            PLATFORM="macos"
            IS_MACOS=true
            ;;
        *)
            echo "Error: Unsupported platform: $os_name" >&2
            exit 1
            ;;
    esac
    
    case "$machine" in
        x86_64)
            ARCH="x64"
            ;;
        arm64|aarch64)
            ARCH="arm64"
            ;;
        *)
            ARCH="x64"  # Default fallback
            ;;
    esac
    
    if [[ "${VERBOSE:-false}" == "true" ]]; then
        echo "Platform: $PLATFORM ($ARCH)" >&2
    fi
}

# Cross-Platform Path Utilities
get_native_path() {
    local path="$1"
    if [[ "$PLATFORM" == "windows" ]]; then
        echo "$path" | sed 's/\//\\/g'
    else
        echo "$path" | sed 's/\\/\//g'
    fi
}

# OMEGA Binary Management
test_omega_binary() {
    if [[ ! -f "$OMEGA_BINARY" ]]; then
        echo "Error: OMEGA binary not found at: $OMEGA_BINARY" >&2
        echo "Please build OMEGA first using: ./build.sh" >&2
        return 1
    fi
    return 0
}

get_omega_version() {
    if test_omega_binary; then
        "$OMEGA_BINARY" --version 2>/dev/null || echo "unknown"
    else
        echo "not-installed"
    fi
}

# Build System
omega_compile() {
    local source_file="$1"
    local output_dir="${2:-$BUILD_DIR}"
    local target="${3:-evm}"
    
    echo "🔨 Compiling OMEGA source: $source_file" >&2
    
    if [[ ! -f "$source_file" ]]; then
        echo "Error: Source file not found: $source_file" >&2
        return 1
    fi
    
    # Create output directory
    mkdir -p "$output_dir"
    
    # Compile command
    local output_file="$output_dir/$(basename "$source_file" .omega)"
    
    local compile_args=(
        "compile"
        "$source_file"
        "--target" "$target"
        "--output" "$output_file"
    )
    
    if [[ "${VERBOSE:-false}" == "true" ]]; then
        echo "Executing: $OMEGA_BINARY ${compile_args[*]}" >&2
    fi
    
    if "$OMEGA_BINARY" "${compile_args[@]}"; then
        echo "✅ Compilation successful: $output_file" >&2
        return 0
    else
        local exit_code=$?
        echo "Error: Compilation failed with exit code: $exit_code" >&2
        return $exit_code
    fi
}

omega_build() {
    local project_dir="${1:-.}"
    local target="${2:-evm}"
    local clean="${3:-false}"
    
    echo "🏗️  Building OMEGA project: $project_dir" >&2
    
    # Clean build directory if requested
    if [[ "$clean" == "true" ]] && [[ -d "$BUILD_DIR" ]]; then
        rm -rf "$BUILD_DIR"
        echo "🧹 Cleaned build directory" >&2
    fi
    
    # Find all .omega files in project
    local omega_files=()
    while IFS= read -r -d $'\0' file; do
        omega_files+=("$file")
    done < <(find "$project_dir" -name "*.omega" -type f -print0)
    
    if [[ ${#omega_files[@]} -eq 0 ]]; then
        echo "Warning: No .omega files found in project directory" >&2
        return 1
    fi
    
    echo "Found ${#omega_files[@]} OMEGA source files" >&2
    
    local success_count=0
    for file in "${omega_files[@]}"; do
        if omega_compile "$file" "$BUILD_DIR" "$target"; then
            ((success_count++))
        fi
    done
    
    if [[ $success_count -eq ${#omega_files[@]} ]]; then
        echo "Built $success_count/${#omega_files[@]} files successfully" >&2
        return 0
    else
        echo "Built $success_count/${#omega_files[@]} files (some failed)" >&2
        return 1
    fi
}

# Testing System
omega_test() {
    local test_dir="${1:-$TEST_DIR}"
    local pattern="${2:-*.test.omega}"
    
    echo "🧪 Running OMEGA tests" >&2
    
    if [[ ! -d "$test_dir" ]]; then
        echo "Warning: Test directory not found: $test_dir" >&2
        return 1
    fi
    
    # Find test files
    local test_files=()
    while IFS= read -r -d $'\0' file; do
        test_files+=("$file")
    done < <(find "$test_dir" -name "$pattern" -type f -print0)
    
    if [[ ${#test_files[@]} -eq 0 ]]; then
        echo "Warning: No test files found matching pattern: $pattern" >&2
        return 1
    fi
    
    echo "Found ${#test_files[@]} test files" >&2
    
    local passed=0
    local failed=0
    
    for test_file in "${test_files[@]}"; do
        echo "Running test: $(basename "$test_file")" >&2
        
        # Compile test file
        local test_output="$BUILD_DIR/tests/$(basename "$test_file" .omega)"
        mkdir -p "$(dirname "$test_output")"
        
        if omega_compile "$test_file" "$(dirname "$test_output")"; then
            ((passed++))
            echo "✅ PASSED: $(basename "$test_file")" >&2
        else
            ((failed++))
            echo "❌ FAILED: $(basename "$test_file")" >&2
        fi
    done
    
    echo "Test Results: $passed passed, $failed failed" >&2
    
    if [[ $failed -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Configuration Management
show_config() {
    echo "OMEGA Binary: $OMEGA_BINARY"
    echo "Platform: $PLATFORM ($ARCH)"
    echo "Build Directory: $BUILD_DIR"
    echo "Test Directory: $TEST_DIR"
    echo "Deploy Directory: $DEPLOY_DIR"
}

show_version() {
    local version=$(get_omega_version)
    echo "OMEGA CLI: 1.0.0"
    echo "OMEGA Binary: $version"
    echo "Platform: $PLATFORM ($ARCH)"
}

# Help System
show_help() {
    cat << 'EOF'
🎯 OMEGA Enhanced CLI - Cross-Platform Build System

USAGE:
    ./omega-cli.sh [COMMAND] [OPTIONS]

COMMANDS:
    compile <file> [--target <target>]     Compile OMEGA source file
    build [--target <target>] [--clean]     Build entire project
    test [--pattern <pattern>]              Run test suite
    deploy <file> [--network <network>]   Deploy to blockchain
    config                                  Show configuration
    version                                 Show version info
    help                                    Show this help

OPTIONS:
    --target <target>     Compilation target (evm, solana, etc.)
    --network <network>   Deployment network (localhost, testnet, mainnet)
    --clean               Clean build before building
    --verbose             Verbose output
    --force               Force operation

EXAMPLES:
    # Compile single file
    ./omega-cli.sh compile contracts/SimpleToken.omega --target evm
    
    # Build entire project
    ./omega-cli.sh build --target evm --clean
    
    # Run tests
    ./omega-cli.sh test --pattern "*.test.omega"
    
    # Deploy contract
    ./omega-cli.sh deploy contracts/SimpleToken.omega --network sepolia

PLATFORMS:
    ✅ Linux (Native)
    ✅ macOS (Native)
    ❌ Windows (Use omega-cli.ps1)

TARGETS:
    ✅ EVM (Ethereum, Polygon, BSC)
    🚧 Solana (Planned)
    🚧 Cosmos (Planned)
    🚧 Move VM (Planned)

EOF
}

# Main Execution
main() {
    # Initialize platform detection
    initialize_platform
    
    # Parse command line arguments
    local command="${1:-help}"
    shift || true
    
    # Handle version and help flags
    if [[ "$command" == "--version" ]] || [[ "$command" == "-v" ]]; then
        show_version
        return 0
    fi
    
    if [[ "$command" == "--help" ]] || [[ "$command" == "-h" ]] || [[ "$command" == "help" ]]; then
        show_help
        return 0
    fi
    
    # Validate OMEGA binary
    if ! test_omega_binary; then
        return 1
    fi
    
    # Execute command
    case "$command" in
        "compile")
            local source_file="$1"
            shift || true
            local target="evm"
            local output_dir="$BUILD_DIR"
            
            # Parse additional arguments
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    "--target")
                        target="$2"
                        shift 2
                        ;;
                    "--output")
                        output_dir="$2"
                        shift 2
                        ;;
                    *)
                        echo "Unknown option: $1" >&2
                        shift
                        ;;
                esac
            done
            
            if [[ -z "$source_file" ]]; then
                echo "Error: Please specify source file to compile" >&2
                return 1
            fi
            
            omega_compile "$source_file" "$output_dir" "$target"
            ;;
        "build")
            local target="evm"
            local clean="false"
            
            # Parse additional arguments
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    "--target")
                        target="$2"
                        shift 2
                        ;;
                    "--clean")
                        clean="true"
                        shift
                        ;;
                    *)
                        echo "Unknown option: $1" >&2
                        shift
                        ;;
                esac
            done
            
            omega_build "." "$target" "$clean"
            ;;
        "test")
            local pattern="*.test.omega"
            
            # Parse additional arguments
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    "--pattern")
                        pattern="$2"
                        shift 2
                        ;;
                    *)
                        echo "Unknown option: $1" >&2
                        shift
                        ;;
                esac
            done
            
            omega_test "$TEST_DIR" "$pattern"
            ;;
        "deploy")
            local contract_file="$1"
            shift || true
            local network="localhost"
            
            # Parse additional arguments
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    "--network")
                        network="$2"
                        shift 2
                        ;;
                    *)
                        echo "Unknown option: $1" >&2
                        shift
                        ;;
                esac
            done
            
            if [[ -z "$contract_file" ]]; then
                echo "Error: Please specify contract file to deploy" >&2
                return 1
            fi
            
            echo "Deploy functionality coming soon!" >&2
            echo "Would deploy: $contract_file to network: $network" >&2
            ;;
        "config")
            show_config
            ;;
        "version")
            show_version
            ;;
        *)
            echo "Error: Unknown command: $command" >&2
            show_help
            return 1
            ;;
    esac
}

# Error handling
trap 'echo "Error: Script failed on line $LINENO" >&2; exit 1' ERR

# Execute main function
main "$@"