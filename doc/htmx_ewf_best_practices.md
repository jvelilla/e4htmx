# Best Practices: HTMX with Eiffel Web Framework (EWF) and Glimmer

This document outlines the recommended best practices for building modern, secure, and maintainable web applications using HTMX, the Eiffel Web Framework (EWF), and the Glimmer templating library.

## 1. Security First
### Always Escape User Input
By default, Glimmer has `auto_escape` enabled (`auto_escape := True`). Always rely on this to safely render user-supplied data in templates. This protects your application against Reflected and Stored Cross-Site Scripting (XSS) attacks. Avoid bypassing this mechanism unless you are rendering fully trusted, pre-sanitized HTML.

### Apply Security HTTP Headers
Use the built-in `apply_security_headers` feature in `EWF_GLIMMER_INTEGRATION` to enforce a strict security posture.
- **Content-Security-Policy (CSP):** Restrict where resources (like scripts and images) can be loaded from.
- **Strict-Transport-Security (HSTS):** Ensure browsers only communicate with your app over HTTPS.
- **X-Content-Type-Options / X-Frame-Options:** Prevent MIME sniffing and Clickjacking.
```eiffel
integration.apply_security_headers (res.header, "default-src 'self'", 31536000)
```

### Secure Cookies
When setting session cookies or authentication tokens using EWF's `WSF_COOKIE`, always ensure they are protected from client-side access and cross-site requests:
```eiffel
create cookie.make ("session_id", my_token)
cookie.set_http_only (True)
cookie.set_secure (True)
-- EWF can also be configured to set SameSite=Lax or Strict depending on the router version
```

## 2. HTMX Request & Response Handling
### Leverage the HTMX Request Helper
Use `GLM_HTMX_REQUEST` to elegantly detect if an incoming EWF request was triggered by HTMX. This allows your endpoints to conditionally serve full HTML pages (for direct browser hits) or partial HTML snippets (for HTMX requests).
```eiffel
l_htmx := integration.glm_htmx_request (req)
if l_htmx.is_htmx_request then
    -- Serve partial template
else
    -- Serve full layout
end
```

### Utilize Server-Side Triggers
When you need to trigger a client-side event from the server (e.g., to tell the frontend to refresh a specific component after a database update), use Glimmer's trigger system instead of returning messy JavaScript.
```eiffel
template.add_trigger ("itemAdded")
integration.apply_htmx_headers (template, res.header)
```

### Out-of-Band (OOB) Swaps
When an action updates multiple disconnected parts of the UI (like a shopping cart counter and an item list), use Glimmer's `render_oob` feature. It generates clean `hx-swap-oob="true"` blocks, allowing you to update multiple targets in a single HTTP response without full page reloads.

## 3. Separation of Concerns & JavaScript
### Embrace Declarative UI
Keep your HTML declarative. Rely on HTMX attributes (`hx-get`, `hx-post`, `hx-target`) to define interaction. This keeps your business logic firmly in Eiffel and reduces frontend complexity.

### Keep Client-Side JavaScript Minimal
If you need client-side logic (like animations, clearing inputs, or interacting with the HTMX JS API), avoid dynamically generating JavaScript strings in Eiffel. Instead, write static JavaScript in your `.js` files or use `hx-on:*` attributes directly in your HTML templates.

## 4. Eiffel Concurrency & State (SCOOP)
### Careful with Shared State
Because EWF can run in concurrent environments (e.g., multithreaded servers), be cautious when using Eiffel `once` routines or shared variables for state that changes. Use appropriate SCOOP concurrency models or thread-safe database connection pools when handling user sessions or caching.
