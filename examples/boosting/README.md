# EWF with HTMX Integration Demo
This project demonstrates the integration of [Eiffel Web Framework (EWF)](https://github.com/EiffelWebFramework/EWF) with [HTMX](https://htmx.org/), combining Eiffel's robust backend capabilities with HTMX's modern frontend interactivity.
## Project Structure 
```
.
├── src/
│ ├── htmx_boosting.e         # Main application service
│ └── htmx_boosting_execution.e # Request execution handling
├── www/
│ ├── index.html          # Main HTML file
│ └── styles.css          # Application styles
└── htmx_boosting.ecf         # Eiffel configuration file
```
## Overview
This application demonstrates how to:
- Set up an EWF server that can handle HTMX requests
- Serve dynamic content using Eiffel's backend capabilities
- Use HTMX attributes for dynamic frontend updates without JavaScript
## HTMX Integration Details
### Current Implementation
Our demo currently demonstrates HTMX's boosting feature:

1. **Page Boosting**: Using `hx-boost` attribute to enhance regular links:
   ```html
   <!-- Regular link - causes full page reload -->
   <a href="another.html">Without boost</a>
   
   <!-- Boosted link - AJAX-powered, smoother navigation -->
   <a href="another.html" hx-boost="true">With boost</a>
   ```

2. **Linked Resources**:
   - The secondary page (`another.html`) includes:
     - CSS styling (`another.css`)
     - JavaScript initialization (`another.js`)
   - JavaScript confirms page load with an alert:
     ```javascript
     window.onload = () => {
         alert('another.js was loaded.');
     };
     ```

### How It Works
1. **Frontend (HTMX)**:
   - HTMX is included via CDN: `htmx.org@2.0.0`
   - `hx-boost="true"` transforms regular links into AJAX requests
   - When clicking a boosted link:
     - HTMX intercepts the click
     - Makes an AJAX request instead of a full page load
     - Smoothly updates the page content
   - Non-boosted links maintain traditional navigation behavior

2. **Backend (EWF)**:
   - Serves static files from the `www` directory
   - Handles both boosted and regular requests transparently
   - No special server-side handling needed for boosted links
## Getting Started
### Prerequisites
- Eiffel Studio (latest version recommended)
- EWF library
- HTMX (included via CDN)
### Running the Application
1. Compile the project:
   ```bash
   ec -config htmx_boosting.ecf
   ```
2. Run the compiled executable. The server will start on port 9090.
3. Access the application at `http://localhost:9090`
## Technical Details
### Backend (EWF)
The application uses EWF's `WSF_FILTERED_ROUTED_EXECUTION` to create a web server that:
- Implements CORS and logging filters
- Serves static files from the `www` directory
- Handles API endpoints like `/version`
- Provides automatic documentation via `/doc` endpoint
- Runs on port 9090

Key implementation features:
```eiffel
-- Route handling setup
router.handle ("/doc", create {WSF_ROUTER_SELF_DOCUMENTATION_HANDLER}.make (router), router.methods_GET)
router.handle ("/version", agent handle_version, router.methods_get)
```

The version endpoint returns "Eiffel Web Framework: 24.11" as plain text with proper HTTP headers.

### Frontend (HTMX Integration)
Current implementation includes:
1. **Version Check Example**: 
   ```html
   <button hx-get="/version" hx-target="#version">Get EWF Version</button>
   ```
   This makes a GET request to the `/version` endpoint and displays "Eiffel Web Framework: 24.11"
   
## Additional Features
The current implementation includes:
- CORS support via `WSF_CORS_FILTER`
- Request logging via `WSF_LOGGING_FILTER`
- Automatic API documentation at `/doc`
- Static file serving from `www` directory
- Custom 404 handling with redirect to home page
## Resources
- [HTMX Documentation](https://htmx.org/documentation/)
- [Eiffel Web Framework Documentation](https://github.com/EiffelWebFramework/EWF)
- [HTMX Examples](https://htmx.org/examples/)
