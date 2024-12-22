# EWF with HTMX Integration Demo
This project demonstrates the integration of [Eiffel Web Framework (EWF)](https://github.com/EiffelWebFramework/EWF) with [HTMX](https://htmx.org/), combining Eiffel's robust backend capabilities with HTMX's modern frontend interactivity.
## Project Structure 
```
.
├── src/
│ ├── htmx_input_validation.e         # Main application service
│ └── htmx_input_validation_execution.e # Request execution handling
├── www/
│ ├── index.html          # Main HTML file
│ └── styles.css          # Application styles
└── htmx_input_validation.ecf         # Eiffel configuration file
```
## Overview
This application demonstrates how to:
- Set up an EWF server that can handle HTMX requests
- Implement real-time form validation
- Process form submissions with proper error handling
- Serve dynamic content using Eiffel's backend capabilities
## HTMX Integration Details
### Current Implementation
Our demo implements these HTMX features:
1. **Real-time Form Validation**:
   ```html
   <input
       hx-get="/email-validate"
       hx-sync="closest form:abort"
       hx-target="#email-error"
       hx-trigger="keyup changed delay:200ms"
       type="email"
   />
   ```
   - Real-time email validation with 200ms delay
   - Password validation on blur
   - Server-side validation against existing emails and common passwords
2. **Form Submission**:
   ```html
   <form hx-post="/account" 
         hx-target="#result" 
         hx-on:htmx:after-request="if (event.detail.pathInfo.requestPath === '/account' && event.detail.successful) this.reset()">
   ```
   - Asynchronous form submission
   - Automatic form reset on successful submission
   - Out-of-band error updates using `hx-swap-oob`
3. **Endpoints**:
   - `/email-validate`: Real-time email validation
   - `/password-validate`: Password strength checking
   - `/form`: Returns the form HTML template
   - `/account`: Handles account creation
   - `/version`: Returns EWF version information
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
   ec -config htmx_input_validation.ecf
   ```
2. Run the compiled executable. The server will start on port 9090.
3. Access the application at `http://localhost:9090`
## Technical Details
### Backend (EWF)
The application implements several key features:
- Email validation against existing user database
- Password validation (minimum 8 characters, checks against common passwords)
- CORS and logging middleware
- Proper HTTP status codes for success/failure responses
- HTML templating for form generation
### Frontend (HTMX Features Used)
The implementation leverages these HTMX features:
- `hx-sync`: For managing concurrent validation requests
- `hx-trigger`: Custom triggers with delays for validation
- `hx-swap-oob`: Out-of-band swaps for error messages
- `hx-on`: Event handling for form reset
- `hx-target`: Dynamic content updating
## Resources
- [HTMX Documentation](https://htmx.org/documentation/)
- [Eiffel Web Framework Documentation](https://github.com/EiffelWebFramework/EWF)
- [HTMX Examples](https://htmx.org/examples/)
