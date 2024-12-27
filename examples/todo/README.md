# EWF with HTMX Integration Demo
This project demonstrates the integration of [Eiffel Web Framework (EWF)](https://github.com/EiffelWebFramework/EWF) with [HTMX](https://htmx.org/), combining Eiffel's robust backend capabilities with HTMX's modern frontend interactivity.

## Project Structure 
```
.
├── src/
│ ├── htmx_todo.e              # Main application service
│ ├── htmx_todo_execution.e    # Request execution handling
│ ├── todo.e                   # Todo item class
│ ├── todo_manager.e           # Todo management logic
│ ├── shared_database_api.e    # Shared database API access
│ └── shared_database_manager.e # Database management
├── www/
│ ├── index.html              # Main HTML file
│ └── styles.css              # Application styles
└── htmx_todo.ecf             # Eiffel configuration file
```

## Overview
This application implements a full-featured Todo list manager that demonstrates:
- RESTful API endpoints for todo management
- SQLite database integration
- HTMX-powered interactive UI
- Alpine.js for enhanced client-side interactions

## Features
### Backend Capabilities
- **Database Management**: SQLite database with automatic initialization
- **Todo Operations**:
  - Create new todos
  - Read todo list and individual items
  - Update todo descriptions
  - Toggle todo completion status
  - Delete todos
- **Data Validation**: Prevents duplicate todos and empty descriptions

### Frontend Features
1. **Dynamic Updates**:
   ```html
   <div hx-get="/todos" hx-trigger="load">
   ```
   - Real-time list updates
   - Inline editing of todo descriptions
   - Completion toggling
   - Delete confirmation

2. **Status Tracking**:
   - Displays remaining/total todos count
   - Auto-updates on changes

3. **Error Handling**:
   - Duplicate todo prevention
   - Empty description validation
   - User-friendly error messages

## Technical Implementation
### Database Layer
- SQLite database with automatic table creation
- Unique constraints on todo descriptions
- Transaction support for data integrity

### API Endpoints
- `GET /todos`: Retrieve all todos
- `POST /todos`: Create new todo
- `PUT /todos/{id}/description`: Update todo description
- `PATCH /todos/{id}/toggle-complete`: Toggle completion status
- `DELETE /todos/{id}`: Remove todo
- `GET /todos/status`: Get todo statistics

### Frontend Integration
- HTMX for server communication
- Alpine.js for client-side state management
- CSS transitions for smooth animations

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
   ec -config htmx_todo.ecf
   ```
2. Run the compiled executable. The server will start on port 9090.
3. Access the application at `http://localhost:9090`

## Resources
- [HTMX Documentation](https://htmx.org/documentation/)
- [Eiffel Web Framework Documentation](https://github.com/EiffelWebFramework/EWF)
- [HTMX Examples](https://htmx.org/examples/)
