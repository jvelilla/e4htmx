# e4htmx

**e4htmx** is an integration library that brings the power of [htmx](https://htmx.org/) to the Eiffel Web Framework (EWF), utilizing the robust `glimmer` HTML templating engine. It correctly maps HTMX request and response headers, allowing you to easily build modern, reactive web applications in Eiffel.

## Features

- **Full Request Parsing**: Access `HX-Request`, `HX-Target`, `HX-Trigger`, `HX-Current-URL`, and other headers easily through the `GLM_HTMX_REQUEST` helper.
- **Full Response Headers**: Set headers such as `HX-Trigger`, `HX-Push-Url`, `HX-Redirect`, `HX-Refresh`, `HX-Retarget`, `HX-Reswap`, `HX-Reselect`, and `HX-Location` directly from the `EWF_GLIMMER_CONTEXT`.
- **JSON-payload HX-Trigger**: Push events to the client containing a JSON detail payload (e.g., `{"showMessage": {"level": "info"}}`), seamlessly integrating with client-side event listeners and toasts.
- **Design by Contract (DbC) Triggers**: Harness Eiffel's native Design by Contract! `{{require user}}` failures in templates can automatically fire an `HX-Trigger` to handle errors gracefully on the client.
- **OOB (Out Of Band) Swaps**: Full support for updating multiple parts of the DOM at once using `render_oob`.
- **Security & CSRF Helpers**: Generate and verify CSRF tokens. Built-in mechanisms to apply `Content-Security-Policy`, `Strict-Transport-Security`, `X-Content-Type-Options`, and `X-Frame-Options` headers.
- **SSE Support**: Includes an easy-to-use `sse_event` helper to stream text/event-stream payloads to HTMX `hx-ext="sse"`.

## Quick Start

### 1. The Context

Your typical handler receives a `WSF_REQUEST` and `WSF_RESPONSE`. Wrap them in `EWF_GLIMMER_CONTEXT` to get htmx superpowers.

```eiffel
class MY_HANDLER inherit WSF_URI_HANDLER

feature
	execute (req: WSF_REQUEST; res: WSF_RESPONSE)
		local
			ctx: EWF_GLIMMER_CONTEXT
			template: GLM_HTML_TEMPLATE
		do
			create ctx.make (req, res)
			create template.make

			-- Check if this is an HTMX request
			if ctx.htmx.is_htmx_request then
				-- We might just want to render a specific section or partial
				ctx.set_trigger ("my-custom-event")
				ctx.render (template, "<div>Just a fragment!</div>")
			else
				-- Standard full-page render
				ctx.render_file (template, "index.html")
			end
		end
```

### 2. Triggers with JSON Details

You can trigger client-side events that include JSON data for robust interactivity:

```eiffel
template.add_trigger_with_detail ("showMessage", "{ %"level%": %"info%", %"message%": %"Saved!%" }")
```

When HTMX receives this, it will fire an event `showMessage` on the client whose `event.detail` contains the parsed JSON object.

### 3. Out-Of-Band Swaps

Instead of rendering a single section, render multiple sections dynamically into the response. The `render_oob` method automatically wraps subsequent sections in `<div hx-swap-oob="true" id="...">` tags.

```eiffel
ctx.render_oob (template, << "content-section", "alert-banner" >>)
```

## Security headers

Add sensible defaults using the security response helper:

```eiffel
apply_security_headers (ctx.headers, "default-src 'self'", 31536000)
```

## License
MIT
