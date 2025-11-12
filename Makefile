# OMEGA Native Compiler - Cross-Platform Makefile
# Build system untuk Windows, Linux, dan macOS

# Platform detection
ifeq ($(OS),Windows_NT)
    PLATFORM := windows
    EXEC_EXT := .exe
    SHELL_EXT := .cmd
else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux)
        PLATFORM := linux
    else ifeq ($(UNAME_S),Darwin)
        PLATFORM := macos
    else
        PLATFORM := unix
    endif
    EXEC_EXT :=
    SHELL_EXT :=
endif

# Version configuration
VERSION ?= 1.3.0
BUILD_DATE := $(shell date +%Y%m%d.%H%M)
COMMIT_HASH := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Directories
SRC_DIR := src
BUILD_DIR := build
DIST_DIR := dist
BIN_DIR := bin

# Targets
TARGETS := omega$(EXEC_EXT)
ifeq ($(PLATFORM),windows)
    TARGETS += omega.cmd
endif

# Build flags
CFLAGS := -Wall -Wextra -std=c99 -O2
LDFLAGS := 

# Installation
PREFIX ?= /usr/local
BINDIR := $(PREFIX)/bin

.PHONY: all clean install uninstall test build-native

# Default target
all: build-native

# Build native executables
build-native: $(TARGETS)

# Create omega executable
omega$(EXEC_EXT): omega$(SHELL_EXT)
	@echo "Building OMEGA native compiler for $(PLATFORM)..."
	@chmod +x omega$(SHELL_EXT)
	@echo "✅ OMEGA native compiler built successfully for $(PLATFORM)"

# Platform-specific builds
build-windows: PLATFORM=windows
build-windows: omega.cmd
	@echo "✅ Windows build completed"

build-linux: PLATFORM=linux
build-linux: omega
	@echo "✅ Linux build completed"

build-macos: PLATFORM=macos
build-macos: omega
	@echo "✅ macOS build completed"

# Cross-platform build
build-all: build-windows build-linux build-macos
	@echo "✅ All platform builds completed"

# Install
install: build-native
	@echo "Installing OMEGA to $(BINDIR)..."
	@mkdir -p $(BINDIR)
	@cp omega$(EXEC_EXT) $(BINDIR)/
ifeq ($(PLATFORM),windows)
	@cp omega.cmd $(BINDIR)/
endif
	@chmod +x $(BINDIR)/omega$(EXEC_EXT)
	@echo "✅ OMEGA installed successfully to $(BINDIR)"

# Uninstall
uninstall:
	@echo "Removing OMEGA from $(BINDIR)..."
	@rm -f $(BINDIR)/omega$(EXEC_EXT)
	@rm -f $(BINDIR)/omega.cmd
	@echo "✅ OMEGA uninstalled successfully"

# Test
 test: build-native
	@echo "Testing OMEGA native compiler..."
	@./omega$(EXEC_EXT) --version
	@./omega$(EXEC_EXT) --help
	@echo "✅ All tests passed"

# Package for distribution
package: build-all
	@echo "Creating distribution packages..."
	@mkdir -p $(DIST_DIR)
	
	# Windows package
	@mkdir -p $(DIST_DIR)/omega-$(VERSION)-windows-amd64
	@cp omega.cmd $(DIST_DIR)/omega-$(VERSION)-windows-amd64/
	@cp omega.ps1 $(DIST_DIR)/omega-$(VERSION)-windows-amd64/
	@cp VERSION $(DIST_DIR)/omega-$(VERSION)-windows-amd64/
	@cp README.md $(DIST_DIR)/omega-$(VERSION)-windows-amd64/
	
	# Linux package  
	@mkdir -p $(DIST_DIR)/omega-$(VERSION)-linux-amd64
	@cp omega $(DIST_DIR)/omega-$(VERSION)-linux-amd64/
	@cp VERSION $(DIST_DIR)/omega-$(VERSION)-linux-amd64/
	@cp README.md $(DIST_DIR)/omega-$(VERSION)-linux-amd64/
	
	# macOS package
	@mkdir -p $(DIST_DIR)/omega-$(VERSION)-darwin-amd64
	@cp omega $(DIST_DIR)/omega-$(VERSION)-darwin-amd64/
	@cp VERSION $(DIST_DIR)/omega-$(VERSION)-darwin-amd64/
	@cp README.md $(DIST_DIR)/omega-$(VERSION)-darwin-amd64/
	
	@echo "✅ Distribution packages created in $(DIST_DIR)"

# Clean
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR) $(DIST_DIR)
	@echo "✅ Clean completed"

# Help
help:
	@echo "OMEGA Native Compiler Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  all              - Build native executables (default)"
	@echo "  build-native     - Build for current platform"
	@echo "  build-windows    - Build for Windows"
	@echo "  build-linux      - Build for Linux"
	@echo "  build-macos      - Build for macOS"
	@echo "  build-all        - Build for all platforms"
	@echo "  install          - Install OMEGA system-wide"
	@echo "  uninstall        - Remove OMEGA from system"
	@echo "  test             - Run tests"
	@echo "  package          - Create distribution packages"
	@echo "  clean            - Remove build artifacts"
	@echo "  help             - Show this help"
	@echo ""
	@echo "Platform: $(PLATFORM)"
	@echo "Version: $(VERSION)"

# Version info
version-info:
	@echo "OMEGA Native Compiler Build Information"
	@echo "Platform: $(PLATFORM)"
	@echo "Version: $(VERSION)"
	@echo "Build Date: $(BUILD_DATE)"
	@echo "Commit: $(COMMIT_HASH)"
	@echo "Install Prefix: $(PREFIX)"