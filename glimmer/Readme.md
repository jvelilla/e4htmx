# HTML Template Engine

## Features

- Template caching
- ✓ HTML escaping for variables
  - Automatic HTML escaping by default
  - Raw variable support with {raw:variable}
  - Global auto-escape control
- ✓ Conditional blocks
  - Support for if/else conditions
  - Truthy/falsy value evaluation
  - Syntax: {{if condition}}...{{else}}...{{end}}
- ✓ Loops/iterations
  - Iterate over collections
  - Syntax: {{each item in collection}}...{{end}}
  - Supports nested loops
- ✓ Layout templates
  - Base layouts with content sections
  - Section definitions with {{section name}}...{{end}}
  - Content placement with {{yield section_name}}
  - Nested layouts support

## Loop Iteration

The template engine supports iterating over collections using the following syntax:

```
{{each item in collection}}
    Content with {item}
{{end}}

This implementation provides:
1. Simple iteration over collections using `{{each item in collection}}` syntax
2. Support for any ITERABLE type
3. Nested variable resolution within loops
4. Empty collection handling
5. Proper cleanup of iterator variables
6. Support for nested loops

The loops are processed before conditionals and variable interpolation, allowing for complex template structures.

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