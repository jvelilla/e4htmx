# Best Practices: HTMX JavaScript API (Chapter 6)

## Overview
Chapter 6 of the book "Server-Driven Web Apps with htmx" ("Utilizing the htmx JS API") focuses exclusively on client-side JavaScript functions provided by HTMX. This includes:

- **DOM Methods**: `htmx.closest`, `htmx.find`, `htmx.findAll`, `htmx.remove`, `htmx.values`
- **Styling Methods**: `htmx.addClass`, `htmx.removeClass`, `htmx.takeClass`, `htmx.toggleClass`
- **Event Methods**: `htmx.on`, `htmx.off`, `htmx.trigger`
- **Other Methods**: `htmx.ajax`, `htmx.config`, `htmx.process`

Since `glimmer` and `ewf_glimmer` are server-side Eiffel libraries, they do not inherently require any new features or components to support this chapter. The JavaScript API is intended to be executed in the browser, either within `<script>` blocks or inline event attributes (e.g., `hx-on:click`).

## Considered Options (Not Implemented)

While no additions are strictly required, the following convenience features were considered for the `glimmer` library but deliberately omitted to maintain simplicity and separation of concerns.

### 1. HTMX Configuration Helper
**Idea:** A template helper method to easily generate the `<meta name="htmx-config" content='...'>` tag.
**Use Case:** Setting global HTMX options such as `allowEval = false` or `allowScriptTags = false` for improved security.
**Why it was skipped:** Users can effortlessly write the standard HTML `<meta>` tag directly in their layout templates. Introducing a dedicated helper for this creates unnecessary coupling and learning overhead for a feature that is fundamentally just static HTML configuration.

### 2. JS Snippet Helpers
**Idea:** Custom template helpers (e.g., Handlebars-style tags like `{{htmx_ajax 'GET' '/endpoint' '#target'}}`) designed to output common HTMX JS boilerplate.
**Use Case:** Simplifying the invocation of methods like `htmx.ajax()` or `htmx.trigger()` without writing raw JavaScript.
**Why it was skipped:** `glimmer` aims to be a clean, generic HTML templating engine. Generating specific JavaScript snippets from the server side tightly couples the backend templates to frontend logic. Developers are better served by writing pure JavaScript in their `.js` files or `<script>` tags, which benefits from IDE support, better readability, and a clear separation of frontend behavior from backend rendering.

## Conclusion
We determined that `glimmer` and `ewf_glimmer` are already well-equipped to serve web applications using the HTMX JS API. Leaving the implementation of client-side JavaScript to the developer using standard HTML `<script>` tags keeps the Eiffel server-side implementation clean and focused on HTTP and template generation.
