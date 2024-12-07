# Glimmer Template Engine Tutorial

Glimmer is a powerful HTML template engine written in Eiffel that provides a simple yet flexible way to generate HTML content. This tutorial will walk you through the main features and usage patterns.

## Basic Usage

### Creating a Template Engine

```eiffel
local
    template: HTML_TEMPLATE
create
    template.make
```

### Simple Variable Interpolation

Variables are interpolated using curly braces:

```html
<h1>Hello, {name}!</h1>
```

```eiffel
template.set_variable("name", "John")
result := template.render(my_template)  -- Outputs: <h1>Hello, John!</h1>
```

### HTML Escaping

By default, all variables are HTML escaped for security. You can use the `raw:` prefix to disable escaping:

```html
<!-- Escaped by default -->
<div>{user_input}</div>

<!-- Raw (unescaped) output -->
<div>{raw:trusted_html}</div>
```

## Conditional Blocks

Use `{{if}}` blocks for conditional rendering:

```html
{{if is_admin}}
    <div class="admin-panel">
        Welcome, Admin!
    </div>
{{else}}
    <div class="user-panel">
        Welcome, User!
    </div>
{{end}}
```

```eiffel
template.set_variable("is_admin", True)
```

## Loops

Iterate over collections using `{{each}}` blocks:

```html
<ul>
    {{each item in items}}
        <!-- Basic iteration -->
        <li>{item}</li>

        <!-- Using loop metadata -->
        <li>#{index}: {item}</li>                    <!-- One-based index -->
        <li class="{if is_even}even{else}odd{end}"> <!-- Even/odd detection -->
        
        <!-- First/last detection -->
        {{if is_first}}
            <li class="first">{item}</li>
        {{else if is_last}}
            <li class="last">{item}</li>
        {{else}}
            <li>{item}</li>
        {{end}}

        <!-- Total items -->
        <li>{item} (Item {index} of {count})</li>
    {{end}}
</ul>
```

### Available Loop Variables
Within each loop iteration, the following metadata variables are automatically available:

- `{index}` - One-based index of the current item (1 to N)
- `{count}` - Total number of items in the collection
- `{is_first}` - Boolean indicating if this is the first item (index = 1)
- `{is_last}` - Boolean indicating if this is the last item (index = count)
- `{is_even}` - Boolean indicating if this is an even-indexed item
- `{is_odd}` - Boolean indicating if this is an odd-indexed item

```eiffel
local
    items: ARRAYED_LIST[STRING]
create
    items.make(3)
items.extend("Apple")    -- index 1
items.extend("Banana")   -- index 2
items.extend("Orange")   -- index 3
template.set_variable("items", items)
```

## Layout Templates

Glimmer supports layout templates for consistent page structure:

```html
-- layout.html
<html>
<head>
    <title>{{yield title}}</title>
</head>
<body>
    <header>{{yield header}}</header>
    <main>{{yield content}}</main>
    <footer>{{yield footer}}</footer>
</body>
</html>

-- page.html
{{section title}}My Page{{end}}
{{section header}}Welcome{{end}}
{{section content}}
    <h1>Main Content</h1>
    <p>This is the page content.</p>
{{end}}
{{section footer}}Copyright 2024{{end}}
```

```eiffel
-- Set up layout
template.set_layout(layout_content)
result := template.render(page_content)
```

## Partial Templates

You can include partial templates:

```html
<!-- partial template -->
{{include header}}
<main>
    Content here
</main>
{{include footer}}
```

```eiffel
template.register_partial("header", "<header>Site Header</header>")
template.register_partial("footer", "<footer>Site Footer</footer>")
```

## Conditional Expressions

Glimmer supports rich expressions in conditional blocks:

### Comparison Operators

```html
{{if age >= 18}}
    <div>Adult content</div>
{{else}}
    <div>Under 18 content</div>
{{end}}

{{if price < 100}}
    <div>Budget item</div>
{{end}}

{{if score == 100}}
    <div>Perfect score!</div>
{{end}}
```

### Logical Operators

Combine multiple conditions with `and`, `or`, and `not`:

```html
{{if is_admin and is_active}}
    <div>Active administrator</div>
{{end}}

{{if is_premium or has_coupon}}
    <div>Special pricing available!</div>
{{end}}

{{if not is_banned}}
    <div>Welcome!</div>
{{end}}
```

### Existence Checks

Check if a variable exists:

```html
{{if exists user_profile}}
    <div>Profile: {user_profile}</div>
{{else}}
    <div>Please complete your profile</div>
{{end}}
```

### Complex Expressions

Combine multiple operators for more complex conditions:

```html
{{if (score >= min_score and score <= max_score) or is_admin}}
    <div>Score is in valid range or admin override</div>
{{end}}

{{if exists discount and price > 100}}
    <div>Discount available for premium items!</div>
{{end}}
```

### Type Support

The expression system supports various numeric types:
- Integers (8, 16, 32, 64-bit)
- Real numbers (32, 64-bit)
- Booleans
- Strings
- Custom objects (using Comparable interface)

```html
{{if temperature > 20.5}}
    <div>It's warm today!</div>
{{end}}

{{if quantity <= max_stock}}
    <div>Item in stock</div>
{{end}}
```

### Truthy Values

The following values are considered "truthy":
- Non-empty strings
- Non-zero numbers
- Boolean True
- Non-void objects

```html
{{if user_name}}  <!-- True if user_name is not empty -->
    <div>Hello, {user_name}!</div>
{{end}}

{{if error_count}}  <!-- True if error_count is not zero -->
    <div>There are errors to fix</div>
{{end}}
```

## Current Limitations

1. **Variable Scope**: Variable scope in nested loops could be improved for better isolation between iterations.

2. **Error Handling**: The current implementation lacks comprehensive error handling and reporting for template syntax errors.

3. **Performance**: Template parsing is done on every render. A caching mechanism for parsed templates would improve performance.

4. **No Built-in Filters**: Unlike some template engines, there's no built-in filter system for formatting output (e.g., date formatting, number formatting).

5. **Limited Debug Support**: No debugging features or template line number reporting for errors.

6. **No Whitespace Control**: No special syntax for controlling whitespace in the output.


These limitations provide opportunities for future enhancements to make the template engine more robust and feature-complete.

## Comparison with Other Template Engines

Glimmer's syntax and features are most similar to Mustache and Handlebars:

### Mustache/Handlebars vs Glimmer

```html
<!-- Mustache/Handlebars -->
{{name}}
{{#if isAdmin}}
    Admin content
{{/if}}
{{#each items}}
    {{this}}
{{/each}}

<!-- Glimmer -->
{name}
{{if is_admin}}
    Admin content
{{end}}
{{each item in items}}
    {item}
{{end}}
```

Key differences:
- Glimmer uses single braces for variables, double for blocks
- Glimmer has explicit `end` tags instead of prefixed tags like `{{/if}}`
- Glimmer's loop syntax is more explicit with `in` keyword
- Glimmer's layout system uses `{{yield}}` and `{{section}}` instead of partials