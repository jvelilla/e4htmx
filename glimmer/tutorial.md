# Glimmer Template Engine Tutorial

Glimmer is a powerful HTML template engine written in Eiffel that provides a simple yet flexible way to generate HTML content. This tutorial will walk you through the main features and usage patterns.

## Basic Usage

### Creating a Template Engine

```eiffel
local
    template: GLM_HTML_TEMPLATE
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
```
template.set_variable("items", items)
```

## Filters & Formatters

Glimmer supports pipeline transformations (filters) to format variable output directly in templates using the pipe (`|`) operator:

```html
<!-- Text capitalization -->
<p>Hello, {user_name | upper}!</p>
<p>Lowercase email: {email | lower}</p>

<!-- String truncation (with parameters) -->
<p>Summary: {description | truncate: 50}</p>

<!-- Date & Time formatting -->
<p>Published on: {created_at | date_format: "yyyy-MM-dd HH:mm:ss"}</p>

<!-- Numeric formatting -->
<p>Score: {score | number_format: 2}</p>
<p>Price: {price | currency: "USD"}</p>

<!-- Filter Chaining -->
<p>Slug preview: {title | lower | truncate: 20}</p>
```

### Built-in Filters

| Filter Name | Arguments | Description |
| :--- | :--- | :--- |
| `upper` | None | Converts the string to uppercase. |
| `lower` | None | Converts the string to lowercase. |
| `truncate` | `len: INTEGER` | Truncates a string to the specified number of characters. |
| `date_format` | `format: STRING` | Formats a `DATE`, `DATE_TIME`, or epoch timestamp integer using Eiffel date-time formatting patterns. |
| `number_format` | `decimals: INTEGER` | Formats a numeric value to a specified number of decimal places. |
| `currency` | `code: STRING` | Formats a numeric value as currency (e.g. `USD`, `EUR`, `GBP`). |

---

## Custom Helpers

You can register custom Eiffel `AGENT`s as helper filters on your template instance using `register_helper`:

```eiffel
local
    template: GLM_HTML_TEMPLATE
do
    create template.make
    
    -- Register a custom helper agent
    template.register_helper ("gravatar_url", agent (email: detachable ANY): STRING_32
        do
            Result := "https://api.dicebear.com/7.x/bottts/svg?seed=" + email.out.to_string_32
        end)
end
```

Then invoke your custom helper in the template just like a built-in filter:

```html
<img src="{email | gravatar_url}" class="avatar" />
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

### HTMX Section Rendering (Partial Rendering)

For HTMX applications that perform partial updates, you often want to render only a specific section of a page without returning the entire outer layout. You can do this using `render_section`:

```eiffel
-- Renders only the "content" section, bypassing layout wrapping entirely:
result := template.render_section(page_content, "content")
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

### Passing Parameters to Partials

You can pass parameter key-value pairs directly to included partial templates using the `with` keyword:

```html
<!-- Include partial and bind parameters to its local scope -->
{{include user_card with name="Alice", role="Developer", is_active=True}}
```

---

## Slot Support & Content Projection

Glimmer supports component-based rendering with named slots and content projection. This is ideal for building reusable layout components like cards, modals, or dropdowns.

### 1. Declare Slots in a Component

Inside your reusable component (registered as a partial, e.g. `card`), use the `{{slot}}` tag:

```html
<!-- Inside partial component "card" -->
<div class="card">
    <div class="card-header">
        {{slot header}}
    </div>
    <div class="card-body">
        {{slot content}}
    </div>
</div>
```

### 2. Fill Slots from Caller

When including the component, you can project custom HTML blocks into those slots using the `{{fill}}` block. The call is closed with a matching `{{end}}`:

```html
<!-- Inside calling template -->
{{include card}}
    {{fill header}}
        <h3>Profile Card</h3>
    {{end}}
    {{fill content}}
        <p>This content is projected into the card body slot.</p>
    {{end}}
{{end}}
```

### Scope Isolation Rules:
*   **Variable Context**: Content inside `{{fill}}` blocks is evaluated in the **caller's context**, not the component's context. This ensures that variables referenced in projected HTML resolve exactly where they were written.
*   **Default Behavior**: If a template declares a `{{slot}}` but the caller does not provide a matching `{{fill}}`, Glimmer renders it safely as empty without throwing errors.

---

## Template Inheritance

For larger layouts, Glimmer supports Jinja2-style multi-level template inheritance using `{{extends parent}}` and `{{block name}}...{{end}}`. This allows you to define a skeleton layout with default blocks that child templates can selectively override.

### Base Template (`base_layout.html`)

Define blocks with optional default content:

```html
<!DOCTYPE html>
<html>
<head>
    <title>{{block title}}My Website{{end}}</title>
</head>
<body>
    <header>
        {{block header}}
            <h1>Welcome to the Site</h1>
        {{end}}
    </header>
    <main>
        {{block content}}{{end}}
    </main>
    <footer>
        <p>Powered by Glimmer</p>
    </footer>
</body>
</html>
```

### Child Template (`page.html`)

Extend the base template at the **very start** of the file, and override only the blocks you want to change:

```html
{{extends base_layout}}

{{block title}}Home Page — My Website{{end}}

{{block content}}
    <h2>Home Page</h2>
    <p>This content overrides the empty content block in the layout.</p>
{{end}}
```

### Key Inheritance Rules:
*   **Tag Position**: The `{{extends}}` tag must be the absolute first statement in the child template.
*   **Multi-level Chain**: Inheritance can be multiple levels deep (e.g. `admin_page` extends `dashboard_layout` which extends `base_layout`).
*   **Circular Guard**: Glimmer automatically checks for inheritance loops during parsing to prevent infinite loops.
*   **Fallbacks**: If a block is defined in the parent but not overridden, Glimmer renders the parent's default block body.

---

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

---

## Design by Contract (DbC) in Templates

Templates represent a structural contract between backend controllers (data providers) and frontend views (data consumers). Glimmer brings Eiffel's Design by Contract (DbC) philosophy directly into HTML templates, enabling compile-time syntax check and runtime context assertion validation.

### 1. Variable Preconditions (`{{require}}`)

You can define variables that **must** be present in the rendering context. If any required variable is missing or is `Void`, a contract violation occurs:

```html
<!-- Fails if 'user' or 'title' are missing/Void in the context -->
{{require user, title}}
```

### 2. Complex Preconditions (`{{require <expression>}}`)

You can also run complex assertions using Glimmer's conditional expression parser:

```html
<!-- Fails if 'user' does not exist, or is under 18 -->
{{require exists user and user.age >= 18}}
```

### 3. Enabling and Catching Contract Violations

Contracts are checked when `contract_mode` is enabled. You can inspect violations using `last_contract_violation`:

```eiffel
local
    template: GLM_HTML_TEMPLATE
    html: STRING_32
do
    create template.make
    template.set_contract_mode (True) -- Enable contract checks
    
    html := template.render (my_template_string)
    if template.has_contract_violation then
        print ("Contract failed: " + template.last_contract_violation.out + "%N")
    end
end
```

> [!NOTE]
> **Production Overhead**: Set `template.set_contract_mode (False)` (which is the default) in production. Glimmer will parse but completely ignore the contracts during rendering, resulting in **zero performance cost**.

---

## Developer Debugging & Variable Inspection

Glimmer provides built-in debug utilities to inspect variables or the entire render context at runtime. This uses Eiffel's reflection engine (`INTERNAL` library) to generate formatted debugging HTML tables.

### 1. Variable Dump (`{dump}`)

Inspect a specific variable's fields and runtime values:

```html
<div class="debug-panel">
    {dump user}
</div>
```

### 2. Context Dump (`{dump_context}`)

Inspect all variables currently bound in the rendering scope:

```html
<div class="debug-panel">
    {dump_context}
</div>
```

> [!IMPORTANT]
> **Contract Mode Dependency**: Debug dumps are only evaluated and rendered when `contract_mode` is enabled (`template.set_contract_mode (True)`). If contract mode is disabled, these tags render as empty strings, ensuring no diagnostic leaks in production.

---

## HTMX Integration in Glimmer

Glimmer is designed from the ground up for modern, hypermedia-driven web applications. It includes native features to support partial updates, Out-of-Band (OOB) swaps, and HTMX-specific response header configurations.

### 1. Section Rendering (Partials)

For HTMX requests that request only a small fragment of the page (e.g. updating a table row), you can render a specific section of the page, bypassing layout templates:

```eiffel
-- Renders only the "content" section and ignores any active layout:
result := template.render_section (page_content, "content")
```

### 2. Out-of-Band (OOB) Swaps

HTMX supports updating multiple parts of a webpage simultaneously using Out-of-Band swaps. Glimmer makes this easy via `render_oob`, which takes an array of section names. The second and subsequent sections are automatically wrapped in a `div` containing `hx-swap-oob="true"` and an `id` matching the section name:

```eiffel
-- Renders "main_content" normally, and packages "sidebar" and "notifications" as OOB fragments:
result := template.render_oob (page_content, <<"main_content", "sidebar", "notifications">>)
```

### 3. HTMX Response Metadata

You can configure HTMX response metadata (such as custom event triggers and history push URLs) directly within the template engine instance:

```eiffel
-- Add events to trigger client-side after swap
template.add_trigger ("user-updated")
template.add_trigger ("refresh-sidebar")

-- Set browser history settings
template.set_push_url ("/users/profile")
template.set_replace_url ("/users/edit")

-- You can retrieve the serialized triggers list:
headers.put_header ("HX-Trigger", template.htmx_trigger_header)
```

You can clear these values before the next render using `template.clear_htmx_metadata`.

### 4. HTMX Request Inspector (`GLM_HTMX_REQUEST`)

Glimmer provides a `GLM_HTMX_REQUEST` helper class to inspect incoming HTMX HTTP request headers:

```eiffel
local
    htmx_req: GLM_HTMX_REQUEST
do
    -- Initialize with HTTP headers map from your web request
    create htmx_req.make (request_headers)
    
    if htmx_req.is_htmx_request then
        if attached htmx_req.hx_target as target then
            print ("Request targets element: " + target + "%N")
        end
        if htmx_req.hx_boosted then
            print ("Request was boosted%N")
        end
    end
end
```

---

## EWF Glimmer Integration (`ewf_glimmer`)

The `ewf_glimmer` utility library provides a bridge between the **Eiffel Web Framework (EWF)** and **Glimmer**, making HTMX-based web development in Eiffel elegant and boilerplate-free.

### 1. `EWF_GLIMMER_CONTEXT`

Inspired by modern web microframeworks like Hono, `EWF_GLIMMER_CONTEXT` wraps EWF's raw request and response objects, offering a clean, unified interface.

#### Context Initialization
In your EWF handler (routed request entry point), instantiate the context:

```eiffel
handle_request (req: WSF_REQUEST; res: WSF_RESPONSE)
    local
        c: EWF_GLIMMER_CONTEXT
    do
        create c.make (req, res)
        -- use context `c` from here
    end
```

### 2. Request Handling API

Instead of dealing with type casting and querying `WSF_VALUE` structures manually, retrieve parameters directly:

```eiffel
-- Path parameters (e.g. /users/:id)
if attached c.param ("id") as l_id then
    -- ...
end

-- Query parameters (e.g. /search?q=term)
if attached c.query ("q") as l_query then
    -- ...
end

-- Form parameters (POST request payloads)
if attached c.form_value ("email") as l_email then
    -- ...
end

-- Raw payload/body (e.g. JSON payloads)
l_body := c.request_body
```

### 3. Response Generation API

#### Sending Basic Responses
```eiffel
c.text ("Hello, World!")          -- text/plain
c.html ("<h1>Welcome</h1>")       -- text/html
c.json ("{\"status\": \"ok\"}")   -- application/json
c.empty                           -- 200 OK with no body
c.not_found                       -- 404 Not Found
c.redirect ("/dashboard")         -- Redirects client
```

#### Status & Header Management
```eiffel
c.set_status ({HTTP_STATUS_CODE}.created)
c.put_header ("Cache-Control", "no-cache")
```

### 4. Template Rendering & HTMX Propagation

Instead of manually invoking the Glimmer template engine, rendering output, and copy-pasting response headers, use `render` or `render_file`. This automatically:
1. Renders the template or file using Glimmer.
2. Propagates all template-level HTMX response metadata (e.g. registered `add_trigger`, `set_push_url`, `set_replace_url` headers).
3. Handles rendering and contract violations, returning appropriate HTTP error status codes (e.g. 500 or 422) and debug divs.

```eiffel
handle_user_update (req: WSF_REQUEST; res: WSF_RESPONSE)
    local
        c: EWF_GLIMMER_CONTEXT
        t: GLM_HTML_TEMPLATE
    do
        create c.make (req, res)
        create t.make
        
        t.set_string ("name", "Bob")
        t.add_trigger ("user-saved")
        
        -- Renders file, sets 'HX-Trigger: user-saved', and sends response
        c.render_file (t, "templates/user_badge.html")
    end
```

### 5. HTMX Specific Header Commands
You can also manipulate HTMX headers directly via the context helper:

```eiffel
c.set_trigger ("item-deleted")      -- HX-Trigger
c.set_target ("#todo-list")         -- HX-Target
c.set_push_url ("/new-location")    -- HX-Push-Url
c.set_replace_url ("/old-location") -- HX-Replace-Url
```

### 6. HTTP Method Helpers
Determine the HTTP request method quickly:

```eiffel
if c.is_get then
    -- Handle GET request
elseif c.is_post then
    -- Handle POST request
elseif c.is_put then
    -- Handle PUT request
elseif c.is_delete then
    -- Handle DELETE request
elseif c.is_patch then
    -- Handle PATCH request
end
```

---

## Design Strengths & Optimizations

1. **Template Caching**: The engine caches compiled Abstract Syntax Trees (ASTs) process-wide in `compiled_templates_cache`. If a template has been compiled once, subsequent renders reuse the parsed AST, avoiding parsing overhead.
2. **Scoped Variable Isolation**: Each loop iteration and nested block creates a local sub-scope via `GLM_RENDER_CONTEXT`, avoiding variable leakage and ensuring loop variables (like `index`, `is_first`, etc.) are fully isolated.
3. **Linear Single-Pass Parser**: The parser scans input in a single pass using a stack to resolve block nesting (`{{if}}`, `{{each}}`, `{{section}}`) efficiently in $O(N)$ time with zero redundant substring allocations.
4. **Single-Pass Escaper**: Character escaping is handled via a single-pass inspection, minimizing string allocation and garbage collection pressure.
5. **Detailed Error Reporting**: Comprehensive error capture with `last_error` and `has_error` attributes tracks syntax and file loading errors.

## Current Limitations & Future Work

1. **No Whitespace Control**: No special syntax (like `{{-` or `-}}`) for controlling whitespace.

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