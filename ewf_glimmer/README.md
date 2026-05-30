# EWF Glimmer Integration (`ewf_glimmer`)

This library provides seamless integration helpers between the **Eiffel Web Framework (EWF)** and the **Glimmer Template Engine**, specifically tailored for building interactive, modern web applications using **HTMX**.

---

## Core Components

The library contains two primary components:

1. **`EWF_GLIMMER_CONTEXT`**: A lightweight, Hono-inspired context helper that wraps EWF's request (`WSF_REQUEST`) and response (`WSF_RESPONSE`) objects. It drastically reduces handler boilerplate code by offering a clean, fluent interface for parameter parsing, response rendering, and header management.
2. **`EWF_GLIMMER_INTEGRATION`**: Internal integration routines that bridge the template engine with EWF headers (e.g., converting HTMX push-urls, replacement-urls, and client-side triggers from Glimmer templates into corresponding HTTP headers).

---

## When to Use `EWF_GLIMMER_CONTEXT`

You should use `EWF_GLIMMER_CONTEXT` inside your EWF handlers whenever you want to:
- Parse path, query, or form parameters without verbose type casting.
- Render HTML templates using Glimmer.
- Respond with plain text, HTML fragments, or JSON.
- Trigger client-side HTMX events (e.g., via `HX-Trigger`).
- Return custom status codes or redirect the client.

---

## API & Usage Examples

### Initializing the Context
At the beginning of any routed EWF handler, instantiate `EWF_GLIMMER_CONTEXT` using the current request and response objects:

```eiffel
handle_endpoint (req: WSF_REQUEST; res: WSF_RESPONSE)
	local
		c: EWF_GLIMMER_CONTEXT
	do
		create c.make (req, res)
		-- Use context `c` from here
	end
```

### 1. Retrieving Request Parameters & Body
Instead of dealing with `WSF_VALUE` and conditional class type assertions, retrieve parameters directly:

```eiffel
-- Path parameters (e.g., /todos/{id})
if attached c.param ("id") as l_id and then l_id.is_integer then
	-- ...
end

-- Query parameters (e.g., /search?q=query)
if attached c.query ("q") as l_query then
	-- ...
end

-- Form variables (POST payloads)
if attached c.form_value ("description") as l_desc then
	-- ...
end

-- Raw Request Body (JSON or raw byte streams)
l_raw_body := c.request_body
```

### 2. Sending Basic Responses
Exposes clean wrappers for typical web responses:

```eiffel
-- Plain text
c.text ("Hello World")

-- HTML Fragment or page
c.html ("<h1>Welcome</h1>")

-- JSON String payload
c.json ("{\"status\": \"success\"}")

-- Empty 200 OK
c.empty

-- Custom Status Codes (e.g., 400 Bad Request)
c.set_status ({HTTP_STATUS_CODE}.bad_request)
c.text ("Invalid payload")
```

### 3. Rendering Glimmer Templates (with HTMX Triggers)
Integrating template rendering, HTMX headers, and error handling in one line of code:

```eiffel
handle_form (req: WSF_REQUEST; res: WSF_RESPONSE)
	local
		c: EWF_GLIMMER_CONTEXT
		l_template: GLM_HTML_TEMPLATE
	do
		create c.make (req, res)
		create l_template.make
		
		-- Setup template context variables
		l_template.set_boolean ("is_editing", True)
		l_template.set_string ("title", "Edit Task")
		
		-- Triggers can be registered on the template...
		l_template.add_trigger ("task-loaded")
		
		-- Renders form.html, automatically applies the HX-Trigger header, 
		-- and returns the HTML response (or error template if parsing fails).
		c.render_file (l_template, "www/form.html")
	end
```

### 4. Direct HTMX Headers
You can also set HTMX-specific response headers explicitly:

```eiffel
c.set_trigger ("item-deleted")      -- Set HX-Trigger header
c.set_target ("#todo-list")         -- Set HX-Target header
c.set_push_url ("/new-location")    -- Set HX-Push-Url header
c.empty                             -- Send empty response
```

### 5. Redirects and 404s
```eiffel
-- Redirects
c.redirect ("/home")

-- 404 Not Found
c.not_found
```
