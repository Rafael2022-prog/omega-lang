module.exports = grammar({
  name: 'omega',

  extras: $ => [
    /\s/,
    $.comment,
  ],

  rules: {
    source_file: $ => repeat($._item),

    _item: $ => choice(
      $.contract_declaration,
      $.function_declaration,
      $.struct_declaration,
      $.enum_declaration,
      $.impl_declaration,
      $.use_declaration,
      $.const_declaration,
      $.type_alias,
    ),

    // Comments
    comment: $ => choice(
      seq('//', /.*/),
      seq('/*', /[^*]*\*+([^/*][^*]*\*+)*/, '/'),
    ),

    // Contract declaration
    contract_declaration: $ => seq(
      'contract',
      field('name', $.identifier),
      optional(seq(':', $.type_list)),
      field('body', $.contract_body),
    ),

    contract_body: $ => seq(
      '{',
      repeat($._contract_item),
      '}',
    ),

    _contract_item: $ => choice(
      $.function_declaration,
      $.struct_declaration,
      $.enum_declaration,
      $.const_declaration,
      $.state_variable,
    ),

    // Function declaration
    function_declaration: $ => seq(
      optional($.visibility_modifier),
      'function',
      field('name', $.identifier),
      field('parameters', $.parameter_list),
      optional(seq('->', field('return_type', $.type))),
      choice(
        field('body', $.block),
        ';',
      ),
    ),

    parameter_list: $ => seq(
      '(',
      optional(seq(
        $.parameter,
        repeat(seq(',', $.parameter)),
        optional(','),
      )),
      ')',
    ),

    parameter: $ => seq(
      field('name', $.identifier),
      ':',
      field('type', $.type),
    ),

    // Struct declaration
    struct_declaration: $ => seq(
      'struct',
      field('name', $.identifier),
      optional($.generic_parameters),
      field('body', $.struct_body),
    ),

    struct_body: $ => seq(
      '{',
      repeat($.struct_field),
      '}',
    ),

    struct_field: $ => seq(
      optional($.visibility_modifier),
      field('name', $.identifier),
      ':',
      field('type', $.type),
      ',',
    ),

    // Enum declaration
    enum_declaration: $ => seq(
      'enum',
      field('name', $.identifier),
      optional($.generic_parameters),
      field('body', $.enum_body),
    ),

    enum_body: $ => seq(
      '{',
      optional(seq(
        $.enum_variant,
        repeat(seq(',', $.enum_variant)),
        optional(','),
      )),
      '}',
    ),

    enum_variant: $ => seq(
      field('name', $.identifier),
      optional(choice(
        seq('(', $.type_list, ')'),
        seq('{', repeat($.struct_field), '}'),
      )),
    ),

    // Impl declaration
    impl_declaration: $ => seq(
      'impl',
      optional($.generic_parameters),
      field('type', $.type),
      optional(seq('for', field('target', $.type))),
      field('body', $.impl_body),
    ),

    impl_body: $ => seq(
      '{',
      repeat($._impl_item),
      '}',
    ),

    _impl_item: $ => choice(
      $.function_declaration,
      $.const_declaration,
      $.type_alias,
    ),

    // Use declaration
    use_declaration: $ => seq(
      'use',
      $.use_path,
      ';',
    ),

    use_path: $ => choice(
      $.identifier,
      seq($.identifier, '::', $.use_path),
      seq($.identifier, '::', '{', $.use_list, '}'),
      seq($.identifier, '::', '*'),
    ),

    use_list: $ => seq(
      $.use_item,
      repeat(seq(',', $.use_item)),
      optional(','),
    ),

    use_item: $ => choice(
      $.identifier,
      seq($.identifier, 'as', $.identifier),
    ),

    // Const declaration
    const_declaration: $ => seq(
      'const',
      field('name', $.identifier),
      ':',
      field('type', $.type),
      '=',
      field('value', $.expression),
      ';',
    ),

    // Type alias
    type_alias: $ => seq(
      'type',
      field('name', $.identifier),
      optional($.generic_parameters),
      '=',
      field('type', $.type),
      ';',
    ),

    // State variable
    state_variable: $ => seq(
      optional($.visibility_modifier),
      field('name', $.identifier),
      ':',
      field('type', $.type),
      optional(seq('=', field('value', $.expression))),
      ';',
    ),

    // Types
    type: $ => choice(
      $.primitive_type,
      $.array_type,
      $.tuple_type,
      $.function_type,
      $.generic_type,
      $.path_type,
    ),

    primitive_type: $ => choice(
      'bool',
      'u8', 'u16', 'u32', 'u64', 'u128', 'u256',
      'i8', 'i16', 'i32', 'i64', 'i128', 'i256',
      'f32', 'f64',
      'address',
      'bytes',
      'string',
    ),

    array_type: $ => seq(
      '[',
      field('element', $.type),
      optional(seq(';', field('size', $.expression))),
      ']',
    ),

    tuple_type: $ => seq(
      '(',
      optional($.type_list),
      ')',
    ),

    function_type: $ => seq(
      'fn',
      $.parameter_list,
      optional(seq('->', $.type)),
    ),

    generic_type: $ => seq(
      field('name', $.identifier),
      '<',
      $.type_list,
      '>',
    ),

    path_type: $ => seq(
      $.identifier,
      repeat(seq('::', $.identifier)),
    ),

    type_list: $ => seq(
      $.type,
      repeat(seq(',', $.type)),
      optional(','),
    ),

    // Generic parameters
    generic_parameters: $ => seq(
      '<',
      $.generic_parameter_list,
      '>',
    ),

    generic_parameter_list: $ => seq(
      $.generic_parameter,
      repeat(seq(',', $.generic_parameter)),
      optional(','),
    ),

    generic_parameter: $ => seq(
      field('name', $.identifier),
      optional(seq(':', $.type_bounds)),
    ),

    type_bounds: $ => seq(
      $.type,
      repeat(seq('+', $.type)),
    ),

    // Expressions
    expression: $ => choice(
      $.literal,
      $.identifier,
      $.binary_expression,
      $.unary_expression,
      $.call_expression,
      $.field_expression,
      $.index_expression,
      $.parenthesized_expression,
    ),

    literal: $ => choice(
      $.boolean_literal,
      $.integer_literal,
      $.float_literal,
      $.string_literal,
      $.address_literal,
    ),

    boolean_literal: $ => choice('true', 'false'),
    
    integer_literal: $ => /\d+/,
    
    float_literal: $ => /\d+\.\d+/,
    
    string_literal: $ => seq(
      '"',
      repeat(choice(
        /[^"\\]/,
        seq('\\', /./),
      )),
      '"',
    ),

    address_literal: $ => /0x[0-9a-fA-F]+/,

    binary_expression: $ => choice(
      prec.left(1, seq($.expression, '||', $.expression)),
      prec.left(2, seq($.expression, '&&', $.expression)),
      prec.left(3, seq($.expression, '==', $.expression)),
      prec.left(3, seq($.expression, '!=', $.expression)),
      prec.left(4, seq($.expression, '<', $.expression)),
      prec.left(4, seq($.expression, '<=', $.expression)),
      prec.left(4, seq($.expression, '>', $.expression)),
      prec.left(4, seq($.expression, '>=', $.expression)),
      prec.left(5, seq($.expression, '+', $.expression)),
      prec.left(5, seq($.expression, '-', $.expression)),
      prec.left(6, seq($.expression, '*', $.expression)),
      prec.left(6, seq($.expression, '/', $.expression)),
      prec.left(6, seq($.expression, '%', $.expression)),
    ),

    unary_expression: $ => choice(
      prec(7, seq('!', $.expression)),
      prec(7, seq('-', $.expression)),
      prec(7, seq('+', $.expression)),
    ),

    call_expression: $ => seq(
      field('function', $.expression),
      field('arguments', $.argument_list),
    ),

    argument_list: $ => seq(
      '(',
      optional(seq(
        $.expression,
        repeat(seq(',', $.expression)),
        optional(','),
      )),
      ')',
    ),

    field_expression: $ => seq(
      field('object', $.expression),
      '.',
      field('field', $.identifier),
    ),

    index_expression: $ => seq(
      field('object', $.expression),
      '[',
      field('index', $.expression),
      ']',
    ),

    parenthesized_expression: $ => seq(
      '(',
      $.expression,
      ')',
    ),

    // Statements
    block: $ => seq(
      '{',
      repeat($._statement),
      '}',
    ),

    _statement: $ => choice(
      $.expression_statement,
      $.let_statement,
      $.assignment_statement,
      $.if_statement,
      $.while_statement,
      $.for_statement,
      $.return_statement,
      $.break_statement,
      $.continue_statement,
      $.block,
    ),

    expression_statement: $ => seq(
      $.expression,
      ';',
    ),

    let_statement: $ => seq(
      'let',
      optional('mut'),
      field('name', $.identifier),
      optional(seq(':', field('type', $.type))),
      optional(seq('=', field('value', $.expression))),
      ';',
    ),

    assignment_statement: $ => seq(
      field('left', $.expression),
      '=',
      field('right', $.expression),
      ';',
    ),

    if_statement: $ => seq(
      'if',
      field('condition', $.expression),
      field('then', $.block),
      optional(seq('else', field('else', choice($.block, $.if_statement)))),
    ),

    while_statement: $ => seq(
      'while',
      field('condition', $.expression),
      field('body', $.block),
    ),

    for_statement: $ => seq(
      'for',
      field('variable', $.identifier),
      'in',
      field('iterable', $.expression),
      field('body', $.block),
    ),

    return_statement: $ => seq(
      'return',
      optional($.expression),
      ';',
    ),

    break_statement: $ => seq('break', ';'),
    
    continue_statement: $ => seq('continue', ';'),

    // Modifiers
    visibility_modifier: $ => choice(
      'public',
      'private',
      'internal',
    ),

    // Identifiers
    identifier: $ => /[a-zA-Z_][a-zA-Z0-9_]*/,
  },
});