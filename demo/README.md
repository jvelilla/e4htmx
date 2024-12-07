# EWF with HTMX Integration Demo

This project demonstrates the integration of [Eiffel Web Framework (EWF)](https://github.com/EiffelWebFramework/EWF) with [HTMX](https://htmx.org/), combining Eiffel's robust backend capabilities with HTMX's modern frontend interactivity.

## Project Structure 

```
.
├── src/
│ ├── htmx_demo.e         # Main application service
│ └── htmx_demo_execution.e # Request execution handling
├── www/
│ ├── index.html          # Main HTML file
│ └── styles.css          # Application styles
└── htmx_demo.ecf         # Eiffel configuration file
```

## Overview

This application demonstrates how to:
- Set up an EWF server that can handle HTMX requests
- Serve dynamic content using Eiffel's backend capabilities
- Use HTMX attributes for dynamic frontend updates without JavaScript

## HTMX Integration Details

### Current Implementation
Our demo currently uses these HTMX features:

1. **Requests via Attributes**: Using `hx-get` attribute to make HTTP requests:
   ```html
   <button hx-get="/version" hx-target="#version">Get EWF Version</button>
   ```
   - `hx-get`: Makes a GET request to `/version` endpoint
   - `hx-target`: Specifies where to put the response (#version div)

2. **Dynamic Content Updates**: The response from the server replaces the content of the target div without a full page reload

### How It Works

1. **Frontend (HTMX)**:
   - HTMX is included via CDN: `htmx.org@2.0.0`
   - HTML elements use HTMX attributes to declare behavior
   - No custom JavaScript required

2. **Backend (EWF)**:
   - EWF handles the HTMX requests like regular HTTP requests
   - Returns HTML fragments instead of full pages
   - Responses are automatically inserted into the DOM by HTMX

## Getting Started

### Prerequisites

- Eiffel Studio (latest version recommended)
- EWF library
- HTMX (included via CDN)

### Running the Application

1. Compile the project:
   ```bash
   ec -config htmx_demo.ecf
   ```

2. Run the compiled executable. The server will start on port 9090.

3. Access the application at `http://localhost:9090`

## Technical Details

### Backend (EWF)

The application uses EWF's `WSF_LAUNCHABLE_SERVICE` to create a web server that:
- Handles both standard HTTP requests and HTMX-specific requests
- Returns appropriate HTML fragments for HTMX requests
- Runs on port 9090 with verbose logging enabled

### Frontend (HTMX Features Available)

HTMX provides several powerful features we can utilize:
- **HTTP Verbs**: Beyond GET/POST (PUT, PATCH, DELETE)
- **Triggers**: Various events can trigger requests (click, change, submit, etc.)
- **Targets**: Control where responses are inserted in the DOM
- **Indicators**: Loading states and progress updates
- **Validation**: Client-side validation with server round-trips
- **WebSockets**: Real-time updates (available but not implemented in demo)

## Planned Enhancements

Future versions of this demo could showcase:
1. Form submissions with `hx-post`
2. Validation feedback
3. Progress indicators
4. WebSocket integration
5. CSS transitions

## Resources

- [HTMX Documentation](https://htmx.org/documentation/)
- [Eiffel Web Framework Documentation](https://github.com/EiffelWebFramework/EWF)
- [HTMX Examples](https://htmx.org/examples/)