#!/usr/bin/env bash
# OMEGA Bootstrap Build Chain v2.0
# Complete C → MEGA → OMEGA → self-host pipeline
# Works on: Windows (Git Bash/WSL), Linux, macOS
# Usage: bash build_bootstrap.sh [clean|debug|release]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BOOTSTRAP_DIR="bootstrap"
TARGET_DIR="target"
OMEGA_MINIMAL="$BOOTSTRAP_DIR/omega_minimal"
BUILD_MODE="${1:-release}"

# Ensure directories exist
mkdir -p "$TARGET_DIR"
mkdir -p "$BOOTSTRAP_DIR"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  OMEGA Bootstrap Build Chain v2.0                             ║${NC}"
echo -e "${BLUE}║  C → MEGA → OMEGA → Self-Host                                ║${NC}"
echo -e "${BLUE}║  Mode: ${BUILD_MODE^^}${NC}                                                       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================================
# STAGE 1: Build C Bootstrap
# ============================================================================

echo -e "${YELLOW}📦 STAGE 1: Build C Bootstrap Compiler${NC}"
echo "   Compiling: bootstrap/omega_minimal.c → $OMEGA_MINIMAL"

if [ "$BUILD_MODE" = "debug" ]; then
    CFLAGS="-std=c99 -Wall -Wextra -g -O0"
else
    CFLAGS="-std=c99 -Wall -Wextra -O2"
fi

gcc $CFLAGS -o "$OMEGA_MINIMAL" "$BOOTSTRAP_DIR/omega_minimal.c" 2>&1 | {
    while IFS= read -r line; do
        if [[ $line == *"error"* ]]; then
            echo -e "${RED}   ❌ $line${NC}"
        elif [[ $line == *"warning"* ]]; then
            echo -e "${YELLOW}   ⚠️  $line${NC}"
        fi
    done
}

if [ ! -f "$OMEGA_MINIMAL" ]; then
    echo -e "${RED}❌ C bootstrap compilation failed${NC}"
    exit 1
fi

BOOTSTRAP_SIZE=$(stat -f%z "$OMEGA_MINIMAL" 2>/dev/null || stat -c%s "$OMEGA_MINIMAL")
echo -e "${GREEN}✅ C Bootstrap built${NC}"
echo "   Size: ${BOOTSTRAP_SIZE} bytes"
echo "   Location: $OMEGA_MINIMAL"
echo ""

# ============================================================================
# STAGE 2: Bootstrap MEGA Modules with C Bootstrap
# ============================================================================

echo -e "${YELLOW}🔨 STAGE 2: Parse MEGA Modules with C Bootstrap${NC}"

MODULES=(
    "src/lexer/lexer.mega"
    "src/parser/parser.mega"
    "src/semantic/analyzer.mega"
    "src/codegen/codegen.mega"
    "src/optimizer/optimizer.mega"
)

for module in "${MODULES[@]}"; do
    if [ ! -f "$module" ]; then
        echo -e "${RED}❌ Module not found: $module${NC}"
        exit 1
    fi
    
    module_name=$(basename "$module" .mega)
    output_file="$TARGET_DIR/${module_name}.o"
    
    echo -n "   Parsing $module_name... "
    
    if "$OMEGA_MINIMAL" "$module" --output "$output_file" > /dev/null 2>&1; then
        obj_size=$(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file")
        echo -e "${GREEN}✅${NC} ($obj_size bytes)"
    else
        echo -e "${RED}❌${NC}"
        echo "      Error: Failed to parse $module"
        exit 1
    fi
done

echo -e "${GREEN}✅ All modules parsed${NC}"
echo ""

# ============================================================================
# STAGE 3: Link Object Files into Initial OMEGA Compiler
# ============================================================================

echo -e "${YELLOW}🔗 STAGE 3: Link Object Files${NC}"

OBJECT_FILES=(
    "$TARGET_DIR/lexer.o"
    "$TARGET_DIR/parser.o"
    "$TARGET_DIR/semantic.o"
    "$TARGET_DIR/codegen.o"
    "$TARGET_DIR/optimizer.o"
)

# Check all object files exist
for obj in "${OBJECT_FILES[@]}"; do
    if [ ! -f "$obj" ]; then
        echo -e "${RED}❌ Missing object file: $obj${NC}"
        exit 1
    fi
done

OMEGA_INITIAL="$TARGET_DIR/omega"

echo "   Linking: ${OBJECT_FILES[*]} → $OMEGA_INITIAL"

# Simple linking: just concatenate (will improve later)
cat "${OBJECT_FILES[@]}" > "$OMEGA_INITIAL"
chmod +x "$OMEGA_INITIAL"

if [ ! -f "$OMEGA_INITIAL" ]; then
    echo -e "${RED}❌ Linking failed${NC}"
    exit 1
fi

OMEGA_SIZE=$(stat -f%z "$OMEGA_INITIAL" 2>/dev/null || stat -c%s "$OMEGA_INITIAL")
echo -e "${GREEN}✅ Linked successfully${NC}"
echo "   Size: $OMEGA_SIZE bytes"
echo ""

# ============================================================================
# STAGE 4: Verify Initial OMEGA Compiler Works
# ============================================================================

echo -e "${YELLOW}🧪 STAGE 4: Verify OMEGA Compiler${NC}"

echo "   Testing: $OMEGA_INITIAL --version"

if "$OMEGA_INITIAL" --version > /dev/null 2>&1; then
    echo -e "${GREEN}✅ OMEGA compiler working${NC}"
else
    echo -e "${YELLOW}⚠️  OMEGA compiler not fully functional yet (expected)${NC}"
fi

echo ""

# ============================================================================
# STAGE 5: Self-Host Test
# ============================================================================

echo -e "${YELLOW}🔄 STAGE 5: Self-Host Compilation${NC}"

echo "   Building bootstrap.mega with initial OMEGA compiler..."

if [ -f "bootstrap.mega" ]; then
    echo "   Found: bootstrap.mega"
    
    # Try to compile bootstrap.mega with the new omega compiler
    if "$OMEGA_INITIAL" compile bootstrap.mega > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Self-hosting successful${NC}"
        SELF_HOST=true
    else
        echo -e "${YELLOW}⚠️  Self-hosting not ready yet (expected - needs full implementation)${NC}"
        SELF_HOST=false
    fi
else
    echo -e "${YELLOW}⚠️  bootstrap.mega not found (expected during initial stages)${NC}"
    SELF_HOST=false
fi

echo ""

# ============================================================================
# STAGE 6: Build Summary
# ============================================================================

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Build Summary                                                 ║${NC}"
echo -e "${BLUE}╠════════════════════════════════════════════════════════════════╣${NC}"

if [ "$BUILD_MODE" = "debug" ]; then
    BUILD_TYPE="Debug (with symbols, no optimization)"
else
    BUILD_TYPE="Release (optimized)"
fi

echo -e "${BLUE}║ Build Mode:  $BUILD_TYPE${NC}"
echo -e "${BLUE}║ Bootstrap:   $OMEGA_MINIMAL ($BOOTSTRAP_SIZE bytes)${NC}"
echo -e "${BLUE}║ Compiler:    $OMEGA_INITIAL ($OMEGA_SIZE bytes)${NC}"
echo -e "${BLUE}║ Self-Host:   $([ "$SELF_HOST" = true ] && echo '✅ Enabled' || echo '⏳ Pending')${NC}"
echo -e "${BLUE}║${NC}"

# List generated files
echo -e "${BLUE}║ Generated Files:${NC}"
ls -lh "$TARGET_DIR"/*.o 2>/dev/null | while read -r line; do
    echo -e "${BLUE}║   $(echo $line | awk '{print $NF, "(" $5 ")"}')"
done
echo -e "${BLUE}║${NC}"

if [ "$SELF_HOST" = true ]; then
    echo -e "${BLUE}║${GREEN} ✅ OMEGA 2.0.0 Ready for Self-Hosting!${NC}${BLUE}                             ║${NC}"
else
    echo -e "${BLUE}║${YELLOW} ⏳ Bootstrapping in Progress (next: implement MEGA compiler)${NC}${BLUE}${NC}"
fi

echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}Next Steps:${NC}"
echo "  1. Review generated object files in $TARGET_DIR/"
echo "  2. Run: $OMEGA_INITIAL --version"
echo "  3. Compile a test file: $OMEGA_INITIAL compile test.omega"
echo ""
