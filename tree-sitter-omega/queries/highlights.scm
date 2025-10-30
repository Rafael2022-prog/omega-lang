; Keywords
[
  "contract"
  "function"
  "struct"
  "enum"
  "impl"
  "use"
  "const"
  "type"
  "let"
  "mut"
  "if"
  "else"
  "while"
  "for"
  "in"
  "return"
  "break"
  "continue"
  "true"
  "false"
] @keyword

; Types
[
  "bool"
  "u8" "u16" "u32" "u64" "u128" "u256"
  "i8" "i16" "i32" "i64" "i128" "i256"
  "f32" "f64"
  "address"
  "bytes"
  "string"
] @type.builtin

; Visibility modifiers
[
  "public"
  "private"
  "internal"
] @keyword.modifier

; Operators
[
  "+"
  "-"
  "*"
  "/"
  "%"
  "=="
  "!="
  "<"
  "<="
  ">"
  ">="
  "&&"
  "||"
  "!"
  "="
] @operator

; Punctuation
[
  "("
  ")"
  "["
  "]"
  "{"
  "}"
] @punctuation.bracket

[
  ","
  ";"
  ":"
  "::"
  "."
  "->"
] @punctuation.delimiter

; Literals
(boolean_literal) @constant.builtin.boolean
(integer_literal) @constant.numeric.integer
(float_literal) @constant.numeric.float
(string_literal) @string
(address_literal) @constant.numeric

; Comments
(comment) @comment

; Identifiers
(identifier) @variable

; Function names
(function_declaration name: (identifier) @function)
(call_expression function: (identifier) @function.call)

; Type names
(struct_declaration name: (identifier) @type)
(enum_declaration name: (identifier) @type)
(contract_declaration name: (identifier) @type)

; Field names
(struct_field name: (identifier) @property)
(field_expression field: (identifier) @property)

; Parameter names
(parameter name: (identifier) @parameter)

; Constants
(const_declaration name: (identifier) @constant)

; Enum variants
(enum_variant name: (identifier) @constant)

; Generic parameters
(generic_parameter name: (identifier) @type.parameter)

; Escape sequences in strings
(string_literal) @string {
  (#match? @string "\\\\.")
}