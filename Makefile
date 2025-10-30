# OMEGA Native Makefile
# Self-hosting build system untuk OMEGA compiler
# Menggantikan Cargo dengan build system native

# Project configuration
PROJECT_NAME = omega
VERSION = 1.9.0
MAIN_FILE = src/main.mega
TARGET_DIR = target
BUILD_DIR = build
OUTPUT_NAME = omega

# Compiler configuration
OMEGA_COMPILER = omega
OMEGA_FLAGS = --optimize --target native
OMEGA_DEBUG_FLAGS = --debug --verbose

# Platform detection
ifeq ($(OS),Windows_NT)
    PLATFORM = windows
    EXE_EXT = .exe
    PATH_SEP = \\
else
    PLATFORM = unix
    EXE_EXT = 
    PATH_SEP = /
endif

# Build targets
.PHONY: all build clean test docs install help bootstrap

# Default target
all: build

# Build the OMEGA compiler
build:
	@echo "🔨 Building OMEGA Self-Hosting Compiler..."
	@echo "📦 Project: $(PROJECT_NAME) v$(VERSION)"
	@echo "🎯 Platform: $(PLATFORM)"
	@echo ""
	
	# Create target directories
	@mkdir -p $(TARGET_DIR)
	@mkdir -p $(BUILD_DIR)
	
	# Execute OMEGA native build system
	@echo "⚙️ Executing OMEGA native build..."
	@omega build --config omega.toml --output $(TARGET_DIR)/$(OUTPUT_NAME)$(EXE_EXT)
	
	@echo ""
	@echo "✅ Build completed successfully!"
	@echo "📍 Output: $(TARGET_DIR)/$(OUTPUT_NAME)$(EXE_EXT)"

# Debug build
debug:
	@echo "🐛 Building OMEGA compiler (debug mode)..."
	@mkdir -p $(TARGET_DIR)
	@omega build --debug --config omega.toml --output $(TARGET_DIR)/$(OUTPUT_NAME)-debug$(EXE_EXT)
	@echo "✅ Debug build completed!"

# Release build with optimizations
release:
	@echo "🚀 Building OMEGA compiler (release mode)..."
	@mkdir -p $(TARGET_DIR)
	@omega build --release --optimize --config omega.toml --output $(TARGET_DIR)/$(OUTPUT_NAME)$(EXE_EXT)
	@echo "✅ Release build completed!"

# Bootstrap build (for first-time compilation)
bootstrap:
	@echo "🌱 Bootstrap build for OMEGA compiler..."
	@echo "⚠️  This requires an existing OMEGA compiler or bootstrap binary"
	
	# Check if bootstrap compiler exists
	@if command -v omega >/dev/null 2>&1; then \
		echo "✅ Found existing OMEGA compiler"; \
		$(MAKE) build; \
	else \
		echo "❌ No OMEGA compiler found"; \
		echo "📥 Please install OMEGA bootstrap compiler first"; \
		echo "   Download from: https://github.com/omega-lang/omega/releases"; \
		exit 1; \
	fi

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf $(TARGET_DIR)
	@rm -rf $(BUILD_DIR)
	@rm -rf .omega/cache
	@echo "✅ Clean completed!"

# Run tests
test:
	@echo "🧪 Running OMEGA tests..."
	@omega test --config omega.toml
	@echo "✅ Tests completed!"

# Run specific test suite
test-unit:
	@echo "🔬 Running unit tests..."
	@omega test --suite unit --config omega.toml

test-integration:
	@echo "🔗 Running integration tests..."
	@omega test --suite integration --config omega.toml

test-cross-chain:
	@echo "🌐 Running cross-chain tests..."
	@omega test --suite cross-chain --config omega.toml

# Generate documentation
docs:
	@echo "📚 Generating documentation..."
	@omega docs --config omega.toml --output docs/generated
	@echo "✅ Documentation generated!"

# Install OMEGA compiler system-wide
install: build
	@echo "📦 Installing OMEGA compiler..."
	@echo "🎯 Installing to system PATH..."
	
	# Platform-specific installation
ifeq ($(PLATFORM),windows)
	@copy "$(TARGET_DIR)$(PATH_SEP)$(OUTPUT_NAME)$(EXE_EXT)" "C:\Program Files\OMEGA\bin\"
	@echo "✅ OMEGA installed to C:\Program Files\OMEGA\bin\"
else
	@sudo cp $(TARGET_DIR)/$(OUTPUT_NAME) /usr/local/bin/
	@sudo chmod +x /usr/local/bin/$(OUTPUT_NAME)
	@echo "✅ OMEGA installed to /usr/local/bin/"
endif

# Uninstall OMEGA compiler
uninstall:
	@echo "🗑️ Uninstalling OMEGA compiler..."
ifeq ($(PLATFORM),windows)
	@del "C:\Program Files\OMEGA\bin\$(OUTPUT_NAME)$(EXE_EXT)"
else
	@sudo rm -f /usr/local/bin/$(OUTPUT_NAME)
endif
	@echo "✅ OMEGA uninstalled!"

# Format source code
fmt:
	@echo "🎨 Formatting OMEGA source code..."
	@omega fmt src/
	@echo "✅ Code formatting completed!"

# Lint source code
lint:
	@echo "🔍 Linting OMEGA source code..."
	@omega lint src/
	@echo "✅ Code linting completed!"

# Run benchmarks
bench:
	@echo "⚡ Running OMEGA benchmarks..."
	@omega bench --config omega.toml
	@echo "✅ Benchmarks completed!"

# Check code quality
check: lint test
	@echo "✅ Code quality check completed!"

# Development workflow
dev: clean debug test
	@echo "✅ Development build completed!"

# Production workflow  
prod: clean release test bench
	@echo "✅ Production build completed!"

# Package for distribution
package: release
	@echo "📦 Creating distribution package..."
	@mkdir -p dist
	@cp $(TARGET_DIR)/$(OUTPUT_NAME)$(EXE_EXT) dist/
	@cp README.md dist/
	@cp LICENSE dist/
	@cp -r docs dist/
	@echo "✅ Distribution package created in dist/"

# Show project status
status:
	@echo "📊 OMEGA Project Status"
	@echo "======================="
	@echo "Project: $(PROJECT_NAME) v$(VERSION)"
	@echo "Platform: $(PLATFORM)"
	@echo "Main file: $(MAIN_FILE)"
	@echo "Target dir: $(TARGET_DIR)"
	@echo ""
	@echo "📁 Source files:"
	@find src -name "*.mega" | wc -l | xargs echo "   MEGA files:"
	@echo ""
	@echo "🔧 Build artifacts:"
	@if [ -f "$(TARGET_DIR)/$(OUTPUT_NAME)$(EXE_EXT)" ]; then \
		echo "   ✅ Compiler binary exists"; \
		ls -lh $(TARGET_DIR)/$(OUTPUT_NAME)$(EXE_EXT) | awk '{print "   Size: " $$5}'; \
	else \
		echo "   ❌ Compiler binary not found"; \
	fi

# Show help
help:
	@echo "OMEGA Native Build System"
	@echo "========================="
	@echo ""
	@echo "Available targets:"
	@echo "  build      - Build OMEGA compiler (default)"
	@echo "  debug      - Build with debug symbols"
	@echo "  release    - Build optimized release version"
	@echo "  bootstrap  - Bootstrap build (requires existing compiler)"
	@echo "  clean      - Clean build artifacts"
	@echo "  test       - Run all tests"
	@echo "  test-unit  - Run unit tests only"
	@echo "  test-integration - Run integration tests only"
	@echo "  test-cross-chain - Run cross-chain tests only"
	@echo "  docs       - Generate documentation"
	@echo "  install    - Install compiler system-wide"
	@echo "  uninstall  - Remove installed compiler"
	@echo "  fmt        - Format source code"
	@echo "  lint       - Lint source code"
	@echo "  bench      - Run benchmarks"
	@echo "  check      - Run lint + test"
	@echo "  dev        - Development workflow (clean + debug + test)"
	@echo "  prod       - Production workflow (clean + release + test + bench)"
	@echo "  package    - Create distribution package"
	@echo "  status     - Show project status"
	@echo "  help       - Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make build          # Build the compiler"
	@echo "  make clean build    # Clean and build"
	@echo "  make test           # Run tests"
	@echo "  make prod           # Full production build"

# Version information
version:
	@echo "OMEGA Build System v$(VERSION)"
	@echo "Universal Blockchain Programming Language"
	@echo "Self-hosting implementation"