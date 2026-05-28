# HTML Template Engine

## Features

- ✓ **High Performance**: Single-pass AST-based parsing and interpretation.
- ✓ **Template Caching**: Process-wide caching of compiled ASTs to eliminate re-parsing overhead.
- ✓ **HTML Escaping**:
  - Automatic HTML escaping by default (single-pass character escaping)
  - Raw variable support with `{raw:variable}`
  - Global auto-escape control
- ✓ **Conditional Blocks**:
  - Support for `if/else` conditions
  - Truthy/falsy value evaluation (correctly evaluates falsy inputs like `0`, `False`, or empty strings)
  - Rich conditional expressions supporting operators (`==`, `!=`, `<`, `>`, `<=`, `>=`), existence checks (`exists`), and logic (`and`, `or`, `not`)
  - Syntax: `{{if condition}}...{{else}}...{{end}}`
- ✓ **Loops/Iterations**:
  - Safe iteration over collections (pre-collected to avoid double-iteration overhead)
  - Scoped variable stacks to ensure loop-local variables (like `index`, `count`, `is_first`, `is_last`, `is_even`, `is_odd`) are isolated
  - Syntax: `{{each item in collection}}...{{end}}`
  - Supports nested loops
- ✓ **Layout Templates & Partials**:
  - Base layouts with content sections
  - Section definitions with `{{section name}}...{{end}}`
  - Content placement with `{{yield section_name}}`
  - Inclusion of partial templates via `{{include partial_name}}`
- ✓ **HTMX Partials**:
  - Targeted section rendering via `render_section` to support returning layout-free HTML fragments
- ✓ **Error Reporting**:
  - Error capture with `last_error` and `has_error` for templates and missing files

## Loop Iteration

The template engine supports iterating over collections using the following syntax:

```
{{each item in collection}}
    Content with {item}
{{end}}
```

This implementation provides:
1. Simple iteration over collections using `{{each item in collection}}` syntax
2. Support for any `ITERABLE` type
3. Nested variable resolution within loops
4. Empty collection handling
5. Isolated scoping of iterator variables via parent-child context stacks
6. Support for nested loops

Templates are parsed into an Abstract Syntax Tree (AST) and rendered in a single pass using a scoped context stack.

## Conditional Blocks

The template engine supports conditional blocks with the following syntax:

```
{{if condition}}
Content if condition is true
{{else}}
Content if condition is false
{{end}}
```

## Layout Templates

The template engine supports layout templates for consistent page structure:

```
-- Define a layout template
<html>
<head><title>{{yield title}}</title></head>
<body>
    <header>{{yield header}}</header>
    <main>{{yield content}}</main>
    <footer>{{yield footer}}</footer>
</body>
</html>

-- Use the layout in a page template
{{section title}}My Page{{end}}
{{section header}}Welcome{{end}}
{{section content}}
    Main content here
{{end}}
{{section footer}}Copyright 2024{{end}}
```

Layout features:
1. Multiple named sections
2. Optional sections (empty if not defined)
3. Variables, conditionals, and loops within sections
4. Nested layout support
5. Easy to disable with clear_layout