# OMEGA Native Compiler - Quick Start Implementation Guide

> Langsung mulai implementasi dengan template kode dan checklist praktis

---

## 🚀 Phase 1: Lexer Edge Cases (Week 1-2) - START HERE

### Step 1: Enhance Token Type Enumeration

**File:** `src/lexer/lexer.mega`

**What to add:**
```omega
// In token type enum, add these missing token types:

// Advanced numeric literals
TokenType::HexLiteral;          // 0xDEADBEEF
TokenType::BinaryLiteral;       // 0b1010
TokenType::OctalLiteral;        // 0o755
TokenType::ScientificLiteral;   // 1e18

// String variants
TokenType::RawStringLiteral;    // r"path"
TokenType::MultilineString;     // """text"""
TokenType::TemplateString;      // "Hello {name}"

// Comment types
TokenType::LineComment;
TokenType::BlockComment;
TokenType::DocComment;

// Assembly specific
TokenType::AssemblyBlock;
TokenType::AssemblyLabel;
TokenType::AssemblyJump;
```

### Step 2: Add Number Parsing Functions

**Add to OmegaLexer blockchain:**

```omega
/// Parse hexadecimal number (0x prefix)
function parse_hex_number() private returns (Token memory) {
    // Skip '0x' prefix
    // Read hex digits [0-9a-fA-F]
    // Validate: at least one digit
    // Return HexLiteral token
}

/// Parse binary number (0b prefix)
function parse_binary_number() private returns (Token memory) {
    // Skip '0b' prefix
    // Read binary digits [0-1]
    // Validate: at least one digit
    // Return BinaryLiteral token
}

/// Parse octal number (0o prefix)
function parse_octal_number() private returns (Token memory) {
    // Skip '0o' prefix
    // Read octal digits [0-7]
    // Validate: at least one digit
    // Return OctalLiteral token
}

/// Parse scientific notation (1e18, 3.14e-2)
function parse_scientific_number() private returns (Token memory) {
    // Parse mantissa (decimal number)
    // Parse 'e' or 'E'
    // Optional '+' or '-'
    // Parse exponent (integer)
    // Return ScientificLiteral token
}
```

### Step 3: Add String Variant Support

**Add to OmegaLexer blockchain:**

```omega
/// Parse raw string literal (r"...")
function parse_raw_string() private returns (Token memory) {
    // Skip r" prefix
    // Read until closing "
    // No escape sequence processing
    // Return RawStringLiteral token
}

/// Parse multiline string literal ("""...""")
function parse_multiline_string() private returns (Token memory) {
    // Skip """ prefix
    // Allow newlines inside
    // Track line numbers
    // Read until closing """
    // Return MultilineString token
}

/// Parse template string with interpolation
function parse_template_string() private returns (Token memory) {
    // Parse "text with {expression} inside"
    // Tokenize embedded expressions
    // Return TemplateString token with nested tokens
}
```

### Step 4: Error Recovery

**Add to LexerErrorRecovery blockchain:**

```omega
/// Recover from unterminated string
function recover_from_unterminated_string() private {
    // Current: error message at position
    // Find line end or EOF
    // Create synthetic string end token
    // Continue tokenization from next line
}

/// Recover from invalid character
function recover_from_invalid_char(char invalid_char) private {
    // Log error
    // Skip invalid character
    // Try to find synchronization point
    // Continue tokenization
}

/// Recover from nested comment mismatch
function recover_from_comment_mismatch() private {
    // Track nesting depth
    // Find matching */ for unclosed /*
    // Report all unclosed comments
    // Continue from after */
}
```

### Checklist for Phase 1
- [ ] Add all missing token types to enum
- [ ] Implement hex/binary/octal parsing
- [ ] Implement scientific notation parsing
- [ ] Implement raw string parsing
- [ ] Implement multiline string parsing
- [ ] Implement template string parsing
- [ ] Implement string error recovery
- [ ] Implement comment error recovery
- [ ] Write 20+ unit tests for each feature
- [ ] Performance benchmark: 10,000 lines/sec minimum

---

## 🚀 Phase 2: Parser Expression Parsing (Week 3-4) - NEXT

### Step 1: Precedence Table

**Add to ExpressionParser blockchain:**

```omega
/// Operator precedence table
/// Higher number = tighter binding (higher precedence)
function get_precedence(TokenType op) private pure returns (uint8) {
    if (op == ASSIGN || op == PLUS_ASSIGN || op == MINUS_ASSIGN) return 1;
    if (op == TERNARY_QUESTION) return 2;
    if (op == LOGICAL_OR) return 3;
    if (op == LOGICAL_AND) return 4;
    if (op == BITWISE_OR) return 5;
    if (op == BITWISE_XOR) return 6;
    if (op == BITWISE_AND) return 7;
    if (op == EQUAL || op == NOT_EQUAL) return 8;
    if (op == LESS || op == GREATER || op == LESS_EQUAL || op == GREATER_EQUAL) return 9;
    if (op == BITWISE_LEFT || op == BITWISE_RIGHT) return 10;
    if (op == PLUS || op == MINUS) return 11;
    if (op == MULTIPLY || op == DIVIDE || op == MODULO) return 12;
    if (op == EXPONENT) return 13;
    return 0; // Not a binary operator
}

/// Check if operator is right-associative
function is_right_associative(TokenType op) private pure returns (bool) {
    // Assignment is right-associative: a = b = c = 5
    // Ternary is right-associative: a ? b : c ? d : e
    // Exponent is right-associative: 2^3^2 = 2^(3^2) = 512
    return op == ASSIGN || op == TERNARY_QUESTION || op == EXPONENT;
}
```

### Step 2: Precedence Climbing Algorithm

**Add to ExpressionParser blockchain:**

```omega
/// Parse expression with precedence climbing
function parse_expression_with_precedence(uint8 min_prec) private returns (Expression memory) {
    // 1. Parse primary/prefix expression (highest priority)
    Expression memory left = parse_unary_expression();
    
    // 2. While we have operators with sufficient precedence
    while (is_binary_operator(peek()) && get_precedence(peek()) >= min_prec) {
        TokenType op = advance();  // Consume operator
        
        // 3. Determine next minimum precedence
        uint8 next_min_prec;
        if (is_right_associative(op)) {
            next_min_prec = get_precedence(op);     // Same precedence for right-assoc
        } else {
            next_min_prec = get_precedence(op) + 1; // Higher for left-assoc
        }
        
        // 4. Recursively parse right side
        Expression memory right = parse_expression_with_precedence(next_min_prec);
        
        // 5. Create binary operation node
        left = create_binary_expression(left, op, right);
    }
    
    return left;
}
```

### Step 3: Unary Operators

**Add to ExpressionParser blockchain:**

```omega
/// Parse unary prefix operators
function parse_unary_expression() private returns (Expression memory) {
    // Handle prefix operators: !, ~, -, +, ++, --
    if (check(BANG)) {              // ! (logical NOT)
        return parse_not_expression();
    }
    if (check(TILDE)) {             // ~ (bitwise NOT)
        return parse_bitwise_not_expression();
    }
    if (check(MINUS)) {             // - (unary minus)
        return parse_unary_minus_expression();
    }
    if (check(PLUS)) {              // + (unary plus)
        return parse_unary_plus_expression();
    }
    if (check(INCREMENT)) {         // ++ (pre-increment)
        return parse_pre_increment_expression();
    }
    if (check(DECREMENT)) {         // -- (pre-decrement)
        return parse_pre_decrement_expression();
    }
    if (check(TYPEOF)) {            // typeof
        return parse_typeof_expression();
    }
    if (check(DELETE)) {            // delete
        return parse_delete_expression();
    }
    
    // Otherwise parse primary/postfix
    return parse_postfix_expression();
}

/// Parse logical NOT expression
function parse_not_expression() private returns (Expression memory) {
    advance();  // consume !
    Expression memory operand = parse_unary_expression();
    return create_unary_expression(NOT, operand);
}

/// Parse postfix operators: ++, --, [], ., ()
function parse_postfix_expression() private returns (Expression memory) {
    Expression memory expr = parse_primary_expression();
    
    while (true) {
        if (check(INCREMENT)) {             // post-increment
            advance();
            expr = create_postfix_expression(expr, POST_INCREMENT);
        } else if (check(DECREMENT)) {      // post-decrement
            advance();
            expr = create_postfix_expression(expr, POST_DECREMENT);
        } else if (check(LEFT_BRACKET)) {   // array index []
            advance();
            Expression memory index = parse_expression();
            expect(RIGHT_BRACKET);
            expr = create_index_expression(expr, index);
        } else if (check(DOT)) {            // member access .
            advance();
            string memory member = expect_identifier();
            expr = create_member_expression(expr, member);
        } else if (check(LEFT_PAREN)) {     // function call ()
            advance();
            Expression[] memory args = parse_argument_list();
            expect(RIGHT_PAREN);
            expr = create_call_expression(expr, args);
        } else {
            break;
        }
    }
    
    return expr;
}
```

### Checklist for Phase 2A (Expressions)
- [ ] Implement operator precedence table
- [ ] Implement precedence climbing algorithm
- [ ] Implement unary prefix operators (!, ~, -, +)
- [ ] Implement pre/post increment/decrement
- [ ] Implement postfix operators ([], ., ())
- [ ] Implement typeof, delete, as, is, in operators
- [ ] Implement ternary conditional operator (?:)
- [ ] Implement assignment operators
- [ ] Write 30+ expression parsing tests
- [ ] Test operator precedence with complex expressions

---

## 🚀 Phase 3: Symbol Table (Week 6-7) - CRITICAL

### Step 1: Basic Symbol Definition

**Create file:** `src/semantic/symbol_table_simple.mega`

```omega
/// Simple symbol table without blockchain overhead
blockchain SimpleSymbolTable {
    state {
        // Scope stack: each scope has local symbols
        mapping(uint256 => Scope) scopes;  // scope_id -> symbols
        uint256 current_scope_id;
        uint256 next_scope_id;
        
        // Symbol storage
        mapping(string => Symbol) symbols;  // name -> symbol info
    }
    
    struct Scope {
        uint256 parent_id;              // Parent scope
        string[] local_symbols;         // Symbols in this scope
        string scope_name;
    }
    
    struct Symbol {
        string name;
        string symbol_type;             // Type name
        uint256 scope_id;               // Where defined
        bool is_defined;
        bool is_mutable;
    }
    
    /// Define symbol in current scope
    function define(string memory name, string memory type) public {
        // Check if already in current scope
        if (exists_in_current_scope(name)) {
            error("Redefined: " + name);
            return;
        }
        
        // Create symbol
        Symbol memory sym;
        sym.name = name;
        sym.symbol_type = type;
        sym.scope_id = current_scope_id;
        sym.is_defined = true;
        
        symbols[name] = sym;
        
        // Add to current scope
        scopes[current_scope_id].local_symbols.push(name);
    }
    
    /// Lookup symbol in scope chain
    function lookup(string memory name) public view returns (Symbol memory) {
        // Check current scope and parents
        uint256 scope_id = current_scope_id;
        
        while (true) {
            // Check local scope
            Scope memory scope = scopes[scope_id];
            for (uint i = 0; i < scope.local_symbols.length; i++) {
                if (equal(scope.local_symbols[i], name)) {
                    return symbols[name];
                }
            }
            
            // Check parent
            if (scope.parent_id == 0) break;
            scope_id = scope.parent_id;
        }
        
        // Not found
        Symbol memory empty;
        return empty;
    }
    
    /// Enter new scope
    function enter_scope(string memory name) public {
        uint256 new_scope_id = next_scope_id++;
        
        Scope memory new_scope;
        new_scope.parent_id = current_scope_id;
        new_scope.scope_name = name;
        
        scopes[new_scope_id] = new_scope;
        current_scope_id = new_scope_id;
    }
    
    /// Exit scope
    function exit_scope() public {
        Scope memory current = scopes[current_scope_id];
        current_scope_id = current.parent_id;
    }
    
    /// Helper: check if symbol exists in current scope only
    function exists_in_current_scope(string memory name) private view returns (bool) {
        Scope memory scope = scopes[current_scope_id];
        for (uint i = 0; i < scope.local_symbols.length; i++) {
            if (equal(scope.local_symbols[i], name)) {
                return true;
            }
        }
        return false;
    }
    
    /// Helper: string equality
    function equal(string memory a, string memory b) private pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}
```

### Step 2: Type System Integration

**Create file:** `src/semantic/type_system.mega`

```omega
/// Type system for OMEGA
blockchain OmegaTypeSystem {
    state {
        // Built-in types registry
        mapping(string => TypeDef) types;
        
        // Type compatibility rules
        mapping(string => string[]) compatible_types;  // type -> compatible types
    }
    
    struct TypeDef {
        string name;
        string category;            // "primitive", "struct", "array", etc.
        uint256 size_bytes;         // For storage
        bool is_mutable;
        bool is_dynamic;            // string, bytes, array
    }
    
    constructor() {
        // Register built-in types
        register_primitive("bool", 1);
        register_primitive("uint8", 1);
        register_primitive("uint16", 2);
        register_primitive("uint32", 4);
        register_primitive("uint64", 8);
        register_primitive("uint128", 16);
        register_primitive("uint256", 32);
        register_primitive("int8", 1);
        register_primitive("int16", 2);
        register_primitive("int32", 4);
        register_primitive("int64", 8);
        register_primitive("int128", 16);
        register_primitive("int256", 32);
        register_primitive("address", 20);
        register_dynamic("string");
        register_dynamic("bytes");
    }
    
    /// Register primitive type
    function register_primitive(string memory name, uint256 size) private {
        TypeDef memory t;
        t.name = name;
        t.category = "primitive";
        t.size_bytes = size;
        t.is_mutable = true;
        t.is_dynamic = false;
        types[name] = t;
    }
    
    /// Register dynamic type
    function register_dynamic(string memory name) private {
        TypeDef memory t;
        t.name = name;
        t.category = "primitive";
        t.size_bytes = 0;  // Dynamic
        t.is_mutable = true;
        t.is_dynamic = true;
        types[name] = t;
    }
    
    /// Check if type is assignable
    function is_assignable_to(string memory from_type, string memory to_type) public view returns (bool) {
        // Same type: always OK
        if (equal(from_type, to_type)) return true;
        
        // Integer widening (uint8 -> uint256)
        if (is_integer(from_type) && is_integer(to_type)) {
            return get_bit_width(to_type) >= get_bit_width(from_type);
        }
        
        return false;
    }
    
    /// Helper: is integer type
    function is_integer(string memory type_name) private pure returns (bool) {
        bytes memory name = bytes(type_name);
        return name.length >= 3 && 
               (name[0] == 'u' || name[0] == 'i') &&
               (name[1] == 'n' || name[1] == 'n');
    }
    
    /// Helper: get integer bit width
    function get_bit_width(string memory type_name) private pure returns (uint256) {
        if (equal(type_name, "uint") || equal(type_name, "int")) return 256;
        if (equal(type_name, "uint8") || equal(type_name, "int8")) return 8;
        if (equal(type_name, "uint256") || equal(type_name, "int256")) return 256;
        return 0;
    }
    
    /// Helper: string equality
    function equal(string memory a, string memory b) private pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}
```

### Checklist for Phase 3
- [ ] Implement SimpleSymbolTable
- [ ] Implement scope stack management
- [ ] Implement symbol lookup with scope chain
- [ ] Implement type system
- [ ] Implement type compatibility rules
- [ ] Integrate symbol table with parser
- [ ] Test symbol redefinition detection
- [ ] Test scope entering/exiting
- [ ] Test type compatibility checking
- [ ] Write 25+ semantic tests

---

## 📋 Testing Strategy for Each Phase

```omega
/// Test pattern for each component

function test_lexer_hex_numbers() public {
    OmegaLexer lexer = new OmegaLexer();
    Token[] tokens = lexer.tokenize("0xDEADBEEF");
    
    assert(tokens[0].type == HexLiteral);
    assert(equal(tokens[0].value, "0xDEADBEEF"));
}

function test_parser_precedence() public {
    Parser parser = new Parser();
    Expression expr = parser.parse_expression("1 + 2 * 3");
    
    // Should parse as: 1 + (2 * 3)
    // Not as: (1 + 2) * 3
    assert(expr is Binary with operator=Plus);
    assert(expr.right is Binary with operator=Multiply);
}

function test_symbol_table_scope() public {
    SymbolTable st = new SymbolTable();
    
    st.define("x", "uint256");
    assert(st.lookup("x").is_defined);
    
    st.enter_scope("function");
    st.define("y", "address");
    assert(st.lookup("y").is_defined);
    assert(st.lookup("x").is_defined);  // Can see parent scope
    
    st.exit_scope();
    assert(!st.lookup("y").is_defined);  // Can't see child scope
    assert(st.lookup("x").is_defined);   // Still see own scope
}
```

---

## 🎯 Immediate Next Steps

1. **Week 1:** Start with Lexer edge case implementation (highest impact)
2. **Week 2:** Complete Parser precedence climbing (foundation for rest)
3. **Week 3:** Implement Symbol Table (blocker for semantic analysis)
4. **Continuously:** Write tests as you go (test-driven development)

---

## 📞 Quick Reference

### Common Patterns

**String comparison in OMEGA:**
```omega
function equal(string memory a, string memory b) private pure returns (bool) {
    return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
}
```

**Dynamic array push:**
```omega
string[] memory arr;
arr.push("value");  // Note: OMEGA syntax may differ
```

**Mapping iteration:**
```omega
// OMEGA blockchains don't support enumeration of mappings
// Use parallel arrays: keys[] and values[] or symbols list
```

**Error handling:**
```omega
// Use OmegaErrorHandler for consistent error reporting
error_handler.add_error(message, line, file);
```

---

**Status:** Ready to implement starting Week 1
**First Task:** Complete Lexer edge cases (number parsing, string variants, error recovery)

