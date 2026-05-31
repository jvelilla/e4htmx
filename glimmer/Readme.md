# HTML Template Engine (Glimmer)

## Features

- ✓ **High Performance**: Single-pass AST-based parsing and interpretation.
- ✓ **Template Caching**: Process-wide caching of compiled ASTs to eliminate re-parsing overhead.
- ✓ **HTML Escaping**:
  - Automatic HTML escaping by default (single-pass character escaping)
  - Raw variable support with `{raw:variable}`
  - Global auto-escape control
- ✓ **Filters & Formatters**:
  - Pipeline transformations using the pipe (`|`) operator.
  - Built-in formatters: `upper`, `lower`, `truncate`, `date_format`, `number_format`, and `currency`.
  - Support for filter arguments (e.g. `{price | currency: "USD"}`).
  - Support for filter chaining (e.g. `{name | lower | truncate: 10}`).
- ✓ **Custom Helpers**:
  - Register custom agent-based filters via `register_helper` for custom string transformations.
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

```html
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

```html
{{if condition}}
Content if condition is true
{{else}}
Content if condition is false
{{end}}
```

## Filters & Formatters

Glimmer supports pipeline transformations (filters) to format variable output directly in templates:

```html
<!-- Text capitalization -->
<p>Hello, {user_name | upper}!</p>
<p>Lowercase email: {email | lower}</p>

<!-- String truncation -->
<p>Summary: {description | truncate: 50}</p>

<!-- Date & Time formatting -->
<p>Published on: {created_at | date_format: "yyyy-MM-dd HH:mm:ss"}</p>

<!-- Numeric formatting -->
<p>Score: {score | number_format: 2}</p>
<p>Price: {price | currency: "USD"}</p>

<!-- Filter Chaining -->
<p>Slug preview: {title | lower | truncate: 20}</p>
```

## Custom Helpers

You can register custom Eiffel agents as filters on a template instance using `register_helper`:

```eiffel
local
    l_template: GLM_HTML_TEMPLATE
do
    create l_template.make
    
    -- Register a custom helper agent
    l_template.register_helper ("gravatar_url", agent (email: detachable ANY): STRING_32
        do
            Result := "https://api.dicebear.com/7.x/bottts/svg?seed=" + email.out.to_string_32
        end)
end
```

Then invoke it in the template:

```html
<img src="{email | gravatar_url}" class="avatar" />
```

## Layout Templates

The template engine supports layout templates for consistent page structure:

```html
-- Define a layout template (e.g. layout.html)
<html>
<head><title>{{yield title}}</title></head>
<body>
    <header>{{yield header}}</header>
    <main>{{yield content}}</main>
    <footer>{{yield footer}}</footer>
</body>
</html>

-- Use the layout in a page template (e.g. page.html)
{{section title}}My Page{{end}}
{{section header}}Welcome{{end}}
{{section content}}
    Main content here
{{end}}
{{section footer}}Copyright 2026{{end}}
```

Layout features:
1. Multiple named sections
2. Optional sections (empty if not defined)
3. Variables, conditionals, and loops within sections
4. Nested layout support
5. Easy to disable with clear_layout