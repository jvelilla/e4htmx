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
- ✓ **Slot Support & Content Projection**:
  - Declare placeholder slots in component templates using `{{slot name}}`
  - Project content into named slots using `{{fill name}}...{{end}}` blocks nested within an `{{include component}}...{{end}}` block include
  - Variable scope isolation between component context and caller template context
- ✓ **Template Inheritance**:
  - Multi-level template inheritance using `{{extends parent}}` and `{{block name}}...{{end}}`
  - Overriding default blocks from layouts and parent templates
  - Circular inheritance path validation to prevent infinite loops
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

## Slot Support & Content Projection

Declare named slots inside component templates (partials) to allow calling templates to inject custom HTML content:

```html
<!-- Inside a component template, e.g. components/card.html -->
<div class="card">
    <div class="card-header">{{slot header}}</div>
    <div class="card-body">{{slot content}}</div>
</div>
```

Then project content into those slots from a calling template using `{{fill name}}` blocks:

```html
<!-- Inside calling template -->
{{include card}}
    {{fill header}}
        <h3>My Custom Header</h3>
    {{end}}
    {{fill content}}
        <p>This paragraph is projected into the card body.</p>
    {{end}}
{{end}}
```

### Slot Isolation Rules:
- **Scope Safety**: Content projected inside `{{fill}}` blocks resolves variable bindings in the **caller's context** where they are defined, not the component's context, preventing unintended variables bleeding.
- **Missing Fills**: If a slot is declared in a component but the caller does not provide a matching `{{fill}}` block, Glimmer renders it safely as an empty string.

## Template Inheritance

Glimmer supports Jinja2-style multi-level template inheritance using `{{extends parent}}` and `{{block name}}...{{end}}` tags. This allows you to define a skeleton layout with overrideable sections (blocks), which child templates can inherit and selectively replace.

### Base Layout
Define named blocks with default content in a layout template (e.g. `base_layout`):

```html
<div class="base-layout">
    <header>
        {{block header}}
            <h1>Default Header</h1>
        {{end}}
    </header>
    <main>
        {{block content}}{{end}}
    </main>
    <footer>
        {{block footer}}
            <p>Built with Glimmer</p>
        {{end}}
    </footer>
</div>
```

### Child Template
Inherit the layout and override specific blocks:

```html
{{extends base_layout}}

{{block header}}
    <h1>Welcome to My Custom Page</h1>
{{end}}

{{block content}}
    <p>This paragraph replaces the content block in base_layout.</p>
{{end}}
```

### Multi-level Inheritance
Inheritance chains can be multiple levels deep. For instance, a child page can extend a mid-level dashboard layout, which in turn extends a generic base layout:

```html
<!-- dashboard_layout -->
{{extends base_layout}}

{{block header}}
    <nav class="dashboard-nav">Dashboard Navigation</nav>
{{end}}
```

```html
<!-- admin_dashboard -->
{{extends dashboard_layout}}

{{block content}}
    <p>Admin panel details...</p>
{{end}}
```

### Rules & Validation:
- **Top of the Template**: The `{{extends}}` tag must be located at the very beginning of the child template.
- **Circular Dependency Guard**: Glimmer automatically checks for inheritance loops (e.g., A extends B, which extends A) and fails fast, raising an error to prevent infinite recursion.
- **Default Blocks**: If a block is defined in a layout but not overridden by any child, its default body is rendered.