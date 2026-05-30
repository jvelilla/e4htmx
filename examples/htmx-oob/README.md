# HTMX Out-of-Band (OOB) Swaps & Client Events in Eiffel (htmx-oob)

This educational example demonstrates two advanced capabilities of [HTMX](https://htmx.org/) integrated with the [Eiffel Web Framework (EWF)](https://github.com/EiffelWebFramework/EWF):
1. **Out-of-Band (OOB) Swaps** (`hx-swap-oob="true"`): Updating multiple parts of a webpage simultaneously from a single request.
2. **Server-Triggered Client Events** (`HX-Trigger` and `HX-Target` headers): Dispatching custom events on the client from the server, and handling them using the `hx-on` attribute.

---

## 1. Concept Explanations

### Out-of-Band (OOB) Swaps
By default, HTMX replaces the inner HTML of the target element that triggered the request. However, real-world web applications often need to update other, unrelated areas of the page at the same time (e.g., updating a shopping cart count, changing a status bar, or refreshing a sidebar).

**Out-of-Band swaps** solve this by allowing the server to return additional markup block(s) anywhere in the HTTP response. These block(s) use the `hx-swap-oob="true"` attribute and specify a matching `id`. When HTMX receives the response, it:
1. Swaps the main response content into the default target element (if any).
2. Scans the response for any elements containing `hx-swap-oob="true"`.
3. Finds the elements on the page with matching `id` attributes.
4. Replaces those elements' content with the returned OOB elements.

In this demo, clicking the **Trigger Out-of-Band Swap** button sends a GET request to `/oob-swap`. The server returns two paragraphs:
```html
<p id="para-1" hx-swap-oob="true" class="demo-text swapped">...</p>
<p id="para-2" hx-swap-oob="true" class="demo-text swapped">...</p>
```
HTMX swaps both paragraphs instantly, bypassing the button's standard target.

---

### Server-Triggered Client Events
Sometimes the server needs to command the client to perform an action (like displaying a notification, resetting a form, or opening a modal) rather than just updating HTML. HTMX allows the server to trigger client-side events by including specific response headers:
- `HX-Trigger`: Dispatches custom events as soon as the response is received.
- `HX-Target`: In this example, we set it to match the event name to fulfill specific trigger flows.

To handle these events, HTMX provides the `hx-on:<event-name>` attribute. You can declare this listener directly on the triggering element or on a parent container (since events bubble).

In this demo, clicking the **Trigger Client Event** button sends a GET request to `/trigger-event`. The server sets the following headers in its response:
```http
HX-Trigger: show-alert
HX-Target: show-alert
```
On the button itself, the listener is defined as:
```html
<button hx-on:show-alert="alert('I got the event!')">...</button>
```
When the response is returned, the client intercepts the `show-alert` event and opens the alert popup.

---

## 2. Project Directory Structure

```
examples/htmx-oob/
├── launcher/                  # Platform-agnostic EWF launcher boilerplate
├── src/
│   ├── htmx_oob.e             # Application entry point, configures port 9096
│   └── htmx_oob_execution.e   # Router, endpoint handlers, and response headers
├── www/
│   └── index.html             # Styled front-end page (Glassmorphism layout + live logger)
├── ewf.ini                    # Server port and verbosity settings
├── htmx_oob.ecf               # Eiffel configuration file (ECF)
├── htmx_oob.rc                # Windows resource compiler description file
└── README.md                  # This educational README
```

---

## 3. Eiffel Implementation Highlights

### Endpoint Setup and Routing
In `HTMX_OOB_EXECUTION`, we register our routes:
```eiffel
setup_router
	local
		www: WSF_FILE_SYSTEM_HANDLER
	do
		map_uri_agent ("/oob-swap", agent handle_oob_swap, router.methods_get)
		map_uri_agent ("/trigger-event", agent handle_trigger_event, router.methods_get)
		...
	end
```

### Out-of-Band Swap Handler
This handler returns HTML blocks wrapped with the `hx-swap-oob="true"` attribute:
```eiffel
handle_oob_swap (req: WSF_REQUEST; res: WSF_RESPONSE)
	local
		l_output: STRING_8
	do
		l_output := "<p id=%"para-1%" hx-swap-oob=%"true%" class=%"demo-text swapped%"><strong>Swapped OOB:</strong> This is the new content of Paragraph 1!</p>%N" +
		            "<p id=%"para-2%" hx-swap-oob=%"true%" class=%"demo-text swapped%"><strong>Swapped OOB:</strong> This is the new content of Paragraph 2!</p>"
		new_response_get (req, res, l_output)
	end
```

### Trigger Event Handler
This handler returns a simple string and appends custom headers to the `HTTP_HEADER` object:
```eiffel
handle_trigger_event (req: WSF_REQUEST; res: WSF_RESPONSE)
	local
		h: HTTP_HEADER
		l_output: STRING_8
	do
		l_output := "Event triggered!"
		create h.make
		h.put_content_type_text_html
		h.put_header_key_value ("HX-Trigger", "show-alert")
		h.put_header_key_value ("HX-Target", "show-alert")
		h.put_content_length (l_output.count)
		h.put_current_date
		
		res.set_status_code ({HTTP_STATUS_CODE}.ok)
		res.put_header_text (h.string)
		res.put_string (l_output)
	end
```

---

## 4. How to Compile & Run

### Prerequisites
- Eiffel Studio compiler `ec` available in your PATH.
- EWF library configured in your Eiffel environment.

### Step 1: Compile the Project
Open a command prompt in the repository root and compile the standalone target:
```bash
ec -config examples\htmx-oob\htmx_oob.ecf -target htmx_oob_standalone -c_compile -batch
```

### Step 2: Run the Executable
Start the standalone server by running the compiled executable:
```bash
.\EIFGENs\htmx_oob_standalone\W_code\htmx_oob.exe
```

### Step 3: Access the Application
Open your browser and navigate to:
```
http://localhost:9096
```
You can now test the out-of-band swaps, trigger client events, and view requests captured in real-time by the EWF & HTMX event log console at the bottom of the page!
