Test Adapter Bridging Guidelines

> Note (Windows Native-Only, Compile-Only)
> - CI currently runs compile-only validation; the `omega test` subcommand is forward-looking and may be inactive in the wrapper.
> - To validate parser adapter tests on Windows CI, compile test suites: `omega compile tests\parser_tests.mega` (and other `*_tests.mega`).
> - For runtime E2E coverage, use `scripts\http_e2e_tests.ps1`; the `run_tests.ps1` aggregator combines compile-only and E2E flows.

Overview
- Some parser-focused tests in this repository validate structure using a lightweight ASTNode representation for simplicity.
- The production parser returns a richer Program/Item/Function/Type/... model. To bridge between them, use the adapter helpers in tests/test_adapter.mega.

Key adapter helpers
- convert_program_to_test_ast(program): Converts a production Program into test ASTNode.
- parse_program_from_source_as_ast(lexer, parser, source): Centralized shim that tokenizes, parses to Program, then converts to test ASTNode.
- parse_function_declaration_as_ast(parser): Parses a single function declaration and converts it to test ASTNode.
- parse_expression_as_ast(parser), parse_statement_as_ast(parser), parse_state_declaration_as_ast(parser), parse_type_as_ast(parser), parse_struct_declaration_as_ast(parser): Parse production constructs and convert to test ASTNode.

When to use adapter vs. Program/IR
- Use adapter (ASTNode) for parser tests that assert structure, node types, names, and simple relationships.
- Use the production Program (and downstream IR/Codegen) for semantic, IR, optimizer, codegen, and pipeline tests.

Usage examples
- Parsing a full source as test ASTNode:
  ASTNode programNode = parse_program_from_source_as_ast(lexer, parser, source);

- Parsing a function declaration:
  ASTNode functionNode = parse_function_declaration_as_ast(parser);

Notes
- parser_tests.mega has been refactored to use the centralized parse_program_from_source_as_ast shim.
- Keep imports consistent: tests that call adapter helpers should import tests/test_adapter.mega and the necessary parser/lexer modules when needed.
- For new tests: prefer the centralized shim for source→Program→ASTNode conversions to reduce duplication and ensure consistent bridging.