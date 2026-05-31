# EWF with HTMX & Glimmer Integration Demo

This project demonstrates the integration of the [Eiffel Web Framework (EWF)](https://github.com/EiffelWebFramework/EWF) with [HTMX](https://htmx.org/) and the **Glimmer Template Engine**, combining Eiffel's robust backend capabilities with HTMX's modern frontend interactivity.

## Project Structure 

```
.
├── src/
│   ├── dog.e                  # Dog domain model
│   ├── htmx_demo.e            # Main application launcher
│   ├── htmx_demo_execution.e  # EWF request router & event handlers
│   └── shared_services.e      # In-memory shared database state
├── www/
│   ├── index.html             # Basic fallback HTML file
│   ├── index2.html            # Redesigned Dogs CRUD frontend
│   ├── filters_demo.html      # Educational filters & helpers template
│   ├── dbc_demo.html          # Design by Contract playground
│   ├── components_demo.html   # Component composition sandbox
│   └── styles.css             # Premium dark-theme stylesheet
└── htmx_demo.ecf              # Eiffel configuration file (targets & libraries)
```

## Features

This application demonstrates how to:
- Set up an EWF server that can handle HTMX requests.
- Serve dynamic content and HTML templates utilizing Glimmer.
- Use HTMX attributes for real-time frontend updates (CRUD + inline deletions) without writing custom JavaScript.
- Apply Glimmer's **built-in filters** and **custom Eiffel agents** as template formatting helper pipelines.
- Support **Component Model (Composition)** with parameterized includes, variable scope isolation, and DbC preconditions.
- Build interactive, live-reloading playgrounds that parse and render Glimmer templates on-the-fly.

---

## Interactive Pages

The application serves two main interactive routes:

### 1. Dogs Database CRUD (`/`)
- A beautiful dark-theme table displaying dog names and breeds.
- Add new dogs dynamically via a card form (`hx-post="/dog"`), which prepends new rows instantly.
- Delete dogs inline using a confirmation overlay (`hx-delete="/dog/{id}"` with `hx-confirm`).

### 2. Filters & Helpers Showcase (`/filters-demo`)
- **Educational Grid**: Interactive cards displaying and explaining built-in formatting filters:
  - Text Cases: `{user_name | upper}`, `{user_name | lower}`
  - String Truncating: `{description | truncate: 45}`
  - Date and Time formatting: `{created_at | date_format: "dd/MM/yyyy"}`
  - Floating decimals: `{score | number_format: 2}`
  - Currency representation: `{balance | currency: "USD"}` or `{balance | currency: "EUR"}`
  - Filter chaining: `{user_name | lower | truncate: 4}`
- **Custom Eiffel Agents**: Visual showcases of user-registered agent helpers:
  - `gravatar_url`: Maps email to a Dicebear robot SVG URL (`{email | gravatar_url}`).
  - `status_badge`: Converts raw text statuses into color-coded HTML status pills (`{raw:status | status_badge}`).
  - `slugify`: Converts titles to URL-safe hyphenated slugs (`{app_title | slugify}`).
- **Interactive Live Playground**: An inline form where you can edit variables and write a custom Glimmer template. As you type, HTMX triggers a POST request to `/filters-demo/render` which renders the template dynamically and displays the result inside a terminal container.

### 3. Design by Contract Sandbox (`/dbc-demo`)
- Experiment with preconditions (`{{require}}`) and inline inspection (`{dump}`, `{dump_context}`).
- Verify development (fails-fast with 422 on breach) vs. production lifecycle modes.

### 4. Component Composition Playground (`/components-demo`)
- **Isolated Context**: Try out parameterized includes (`{{include component with param=val}}`) and witness that parent context variables do not leak into the component.
- **Dynamic Sandboxing**: Edit both the sub-component template and the calling page template in real-time.
- **DbC boundaries**: Toggle required component inputs to trigger fast-failing preconditions.

---

## Getting Started

### Prerequisites
- Eiffel Studio (v24.11+ / v25.12+ recommended)
- EWF library
- HTMX (loaded via CDN)

### Running the Application

1. Compile the project using the Eiffel compiler:
   ```bash
   ec -config htmx_demo.ecf -target htmx_demo -clean -batch
   ```

2. Perform the C compilation (freeze):
   On Windows, run the `finish_freezing` command in the generated code directory:
   ```bash
   cd EIFGENs\htmx_demo\W_code
   finish_freezing
   ```

3. Run the compiled executable from the `demo/` subdirectory to ensure static assets are loaded correctly:
   ```bash
   cd ..\..\..   # navigate back to demo/ directory
   EIFGENs\htmx_demo\W_code\htmx_demo.exe
   ```
   *The server will start on port **9999** by default.*

4. Access the application at:
   - Dashboard: [http://localhost:9999/](http://localhost:9999/)
   - Filters Showcase: [http://localhost:9999/filters-demo](http://localhost:9999/filters-demo)
   - DbC Playground: [http://localhost:9999/dbc-demo](http://localhost:9999/dbc-demo)
   - Components Playground: [http://localhost:9999/components-demo](http://localhost:9999/components-demo)

## Technical Integration

### EWF Glimmer Context (`EWF_GLIMMER_CONTEXT`)
The application uses the `EWF_GLIMMER_CONTEXT` to process requests:
- **`c.form_value ("key")`**: Extracts form-data inputs cleanly.
- **`c.render (template, text)`**: Renders string templates.
- **`c.render_file (template, path)`**: Loads template files, binds context variables, and returns layout-integrated HTML with appropriate headers.

### Custom Helper Registration
In `htmx_demo_execution.e`, custom helpers are bound as Eiffel agent functions:
```eiffel
l_template.register_helper ("gravatar_url", agent gravatar_url)
l_template.register_helper ("status_badge", agent status_badge)
l_template.register_helper ("slugify", agent slugify)
```
These agents are invoked dynamically by Glimmer whenever the filter name is matched in a template placeholder.