# EWF with HTMX Integration Demo
This project demonstrates the integration of [Eiffel Web Framework (EWF)](https://github.com/EiffelWebFramework/EWF) with [HTMX](https://htmx.org/), combining Eiffel's robust backend capabilities with HTMX's modern frontend interactivity.
## Project Structure 
```
.
├── src/
│ ├── htmx_lazy_loading.e         # Main application service
│ └── htmx_lazy_loading_execution.e # Request execution handling
├── www/
│ ├── index.html          # Main HTML file
│ └── styles.css          # Application styles
└── htmx_lazy_loading.ecf         # Eiffel configuration file
```
## Overview
This application demonstrates how to:
- Set up an EWF server that can handle HTMX requests
- Serve dynamic content using Eiffel's backend capabilities
- Use HTMX attributes for dynamic frontend updates without JavaScript
## HTMX Integration Details
### Current Implementation
Our demo currently demonstrates lazy loading using these HTMX features:
1. **Lazy Loading with Reveal**: Using `hx-trigger="revealed"` for loading content when scrolled into view:
   ```html
   <div
     hx-get="/users"
     hx-indicator=".htmx-indicator"
     hx-trigger="revealed"
   />
   ```
   - `hx-trigger="revealed"`: Triggers request when element becomes visible
   - `hx-get`: Makes GET request to `/users` endpoint
   - `hx-indicator`: Shows loading spinner while request is in progress

2. **Loading Indicators**: Using a spinner gif to show loading state:
   ```html
   <img alt="loading" class="htmx-indicator" src="/spinner.gif" />
   ```

### How It Works
1. **Frontend (HTMX)**:
   - HTMX is included via CDN
   - Uses scroll-based lazy loading to fetch data
   - Shows loading indicator during requests
   - Automatically replaces content when loaded

2. **Backend (EWF)**:
   - Handles `/users` endpoint
   - Reads from JSON file and converts to HTML table
   - Simulates network delay (1 second)
   - Returns formatted HTML table of users
## Getting Started
### Prerequisites
- Eiffel Studio (latest version recommended)
- EWF library
- HTMX (included via CDN)
### Running the Application
1. Compile the project:
   ```bash
   ec -config htmx_lazy_loading.ecf
   ```
2. Run the compiled executable. The server will start on port 9090.
3. Access the application at `http://localhost:9090`
## Technical Details
### Backend (EWF)
The application uses EWF's `WSF_LAUNCHABLE_SERVICE` to create a web server that:
- Handles both standard HTTP requests and HTMX-specific requests
- Returns appropriate HTML fragments for HTMX requests
- Runs on port 9090 with verbose logging enabled
## Resources
- [HTMX Documentation](https://htmx.org/documentation/)
- [Eiffel Web Framework Documentation](https://github.com/EiffelWebFramework/EWF)
- [HTMX Examples](https://htmx.org/examples/)
