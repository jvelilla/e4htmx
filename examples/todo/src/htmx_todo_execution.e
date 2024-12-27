note
	description: "[
			application execution
		]"
	date: "$Date$"
	revision: "$Revision$"

class
	HTMX_TODO_EXECUTION

inherit
	WSF_FILTERED_ROUTED_EXECUTION
	WSF_ROUTED_URI_HELPER
	WSF_ROUTED_URI_TEMPLATE_HELPER
	SHARED_EXECUTION_ENVIRONMENT
	SHARED_DATABASE_MANAGER

create
	make

feature -- Filter

	create_filter
			-- Create `filter'
		do
			create {WSF_MAINTENANCE_FILTER} filter
		end

	setup_filter
			-- Setup `filter'
		local
			f: like filter
		do
			create {WSF_CORS_FILTER} f
			f.set_next (create {WSF_LOGGING_FILTER})
			filter.append (f)
		end

feature -- Router

	setup_router
			-- Setup `router'
		local
			www: WSF_FILE_SYSTEM_HANDLER
		do
			router.handle ("/doc", create {WSF_ROUTER_SELF_DOCUMENTATION_HANDLER}.make (router), router.methods_GET)
			map_uri_agent ("/version", agent handle_version, router.methods_get)
			map_uri_agent ("/todos", agent handle_todos, router.methods_get_post)
			map_uri_template_agent ("/todos/{id}", agent handle_delete_todo, router.methods_delete)
			map_uri_agent ("/todos/status", agent handle_todos_status, router.methods_get)
			map_uri_template_agent ("/todos/{id}/description", agent handle_update_todo_description, methods_patch)
			map_uri_template_agent ("/todos/{id}/toggle-complete", agent handle_toggle_todo_complete, methods_patch)

			create www.make_with_path (document_root)
			www.set_directory_index (<<"index.html">>)
			www.set_not_found_handler (agent execute_not_found)
			router.handle ("", www, router.methods_GET)
			map_uri_agent ("/", agent handle_root, router.methods_GET)
			map_uri_agent ("", agent handle_root, router.methods_GET)

		end

	methods_patch: WSF_REQUEST_METHODS
		once ("THREAD")
			create Result
			Result.enable_patch
			Result.lock
		ensure
			methods_get_not_void: Result /= Void
		end

feature -- Configuration

	document_root: PATH
			-- Document root to look for files or directories
		once
			Result := execution_environment.current_working_path.extended ("www")
		end

feature -- Events

	handle_version (req: WSF_REQUEST; res: WSF_RESPONSE)
		local
			l_result: STRING_8
		do
			l_result := "Eiffel Web Framework: 24.11"
			new_response_get (req, res, l_result)
		end

	new_response_get (req: WSF_REQUEST; res: WSF_RESPONSE; output: STRING)
		local
			h: HTTP_HEADER
		do
			create h.make
			h.put_content_type_text_html
			h.put_content_length (output.count)
			h.put_current_date
			res.set_status_code ({HTTP_STATUS_CODE}.ok)
			res.put_header_text (h.string)
			res.put_string (output)
		end

	execute_not_found (uri: READABLE_STRING_8; req: WSF_REQUEST; res: WSF_RESPONSE)
			-- `uri' is not found, redirect to default page
		do
			res.redirect_now_with_content (req.script_url ("/"), uri + ": not found.%NRedirection to " + req.script_url ("/"), "text/html")
		end

	handle_root (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle GET / request by redirecting to /todos
		do
			res.redirect_now (req.script_url ("/todos"))
		end

feature -- Handlers

	handle_todos (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle GET and POST /todos requests
		local
			l_todo_manager: TODO_MANAGER
			l_description: detachable STRING
		do
			create l_todo_manager

			if req.is_post_request_method then
					-- Handle POST request
				if attached {WSF_STRING} req.form_parameter ("description") as l_desc then
					l_description := l_desc.value
					if l_description /= Void and then not l_description.is_empty then
							-- Try to add new todo
						add_todo (req, res, l_description)
					else
							-- Empty description error
						res.set_status_code ({HTTP_STATUS_CODE}.bad_request)
						new_response_html (req, res, "<div class=%"error%">Todo description cannot be empty</div>")
					end
				else
					res.set_status_code ({HTTP_STATUS_CODE}.bad_request)
					new_response_html (req, res, "<div class=%"error%">Missing description parameter</div>")
				end
			else
					-- Handle GET request
				handle_todos_get (req, res)
			end
		end

	handle_todos_get (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle GET /todos request
		local
			l_todo_manager: TODO_MANAGER
			l_todos: LIST [TODO]
			l_json: STRING
			l_html: STRING
			l_accept: detachable READABLE_STRING_32
		do
				-- Get Accept header
			l_accept := req.meta_string_variable ("HTTP_ACCEPT")

			create l_todo_manager
			l_todos := l_todo_manager.retrieve_all

			if l_accept /= Void and then l_accept.has_substring ("application/json") then
					-- Return JSON response
				create l_json.make_from_string ("[")
				across l_todos as todo loop
					if not todo.is_first then
						l_json.append (",")
					end
					l_json.append ("{%"id%":" + todo.item.id.out +
						",%"description%":%"" + todo.item.description +
						"%",%"completed%":" + todo.item.completed.out + "}")
				end
				l_json.append ("]")
				new_response_json (req, res, l_json)
			else
					-- Return HTML response
				create l_html.make_from_string (
					"<div id=%"todo-list%" x-on:description-change=%"editingId = 0%">")
				across l_todos as todo loop
					l_html.append (todo_item_html (todo.item))
				end

				l_html.append ("</div>")
				new_response_html (req, res, l_html)
			end
		end

	new_response_json (req: WSF_REQUEST; res: WSF_RESPONSE; output: STRING)
			-- Send JSON response
		local
			h: HTTP_HEADER
		do
			create h.make
			h.put_content_type ("application/json")
			h.put_content_length (output.count)
			h.put_current_date
			res.set_status_code ({HTTP_STATUS_CODE}.ok)
			res.put_header_text (h.string)
			res.put_string (output)
		end

	new_response_html (req: WSF_REQUEST; res: WSF_RESPONSE; output: STRING)
			-- Send HTML response
		local
			h: HTTP_HEADER
		do
			create h.make
			h.put_content_type_text_html
			h.put_content_length (output.count)
			h.put_current_date
			res.set_status_code ({HTTP_STATUS_CODE}.ok)
			res.put_header_text (h.string)
			res.put_string (output)
		end

	handle_delete_todo (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle DELETE /todos/:id request
		local
			l_id: INTEGER
			l_todo_manager: TODO_MANAGER
			l_id_param: WSF_VALUE
			h: HTTP_HEADER
		do
				-- Get the ID from the URL parameter
			l_id_param := req.path_parameter ("id")
			if attached {WSF_STRING} l_id_param as l_param and then l_param.is_integer then
				l_id := l_param.value.to_integer

					-- Delete the todo
				create l_todo_manager
				l_todo_manager.delete (l_id)

					-- Create and set headers including HTMX trigger
				create h.make
				h.put_header_key_value ("hx-trigger", "status-change")
				h.put_content_type_text_html
				h.put_content_length (0)
				h.put_current_date
				res.set_status_code ({HTTP_STATUS_CODE}.ok)
				res.put_header_text (h.string)
				res.put_string ("")

			else
					-- Invalid ID parameter
				res.set_status_code ({HTTP_STATUS_CODE}.bad_request)
				res.put_string ("Invalid todo ID")
			end
		end

	handle_todos_status (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle GET /todos/status request
		local
			l_todo_manager: TODO_MANAGER
			l_todos: LIST [TODO]
			l_uncompleted_count: INTEGER
			l_response: STRING
		do
			create l_todo_manager
			l_todos := l_todo_manager.retrieve_all

				-- Count uncompleted todos
			across l_todos as todo loop
				if todo.item.completed = 0 then
					l_uncompleted_count := l_uncompleted_count + 1
				end
			end

				-- Create status text
			create l_response.make_from_string (l_uncompleted_count.out)
			l_response.append (" of ")
			l_response.append (l_todos.count.out)
			l_response.append (" remaining")

			new_response_text (req, res, l_response)
		end

	handle_update_todo_description (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle PATCH /todos/:id/description request
		local
			l_id: INTEGER
			l_todo_manager: TODO_MANAGER
			l_todo: detachable TODO
			l_id_param: WSF_VALUE
			l_description: detachable STRING
			h: HTTP_HEADER
		do
				-- Get the ID from the URL parameter
			l_id_param := req.path_parameter ("id")
			if attached {WSF_STRING} l_id_param as l_param and then l_param.is_integer then
				l_id := l_param.value.to_integer

					-- Get the todo
				create l_todo_manager
				l_todo := l_todo_manager.retrieve_by_id (l_id)

				if l_todo /= Void then
						-- Get description from form data
					if attached {WSF_STRING} req.form_parameter ("description") as l_desc then
						l_description := l_desc.value

						if l_description /= Void and then not l_description.is_empty then
								-- Update todo
							l_todo.set_description (l_description)
							l_todo_manager.save (l_todo)

								-- Set HTMX trigger header
							create h.make
							h.put_header_key_value ("HX-Trigger", "description-change")
							h.put_current_date
							res.put_header_text (h.string)

								-- Return updated todo HTML
							new_response_html (req, res, todo_item_html (l_todo))
						else
								-- Empty description error
							res.set_status_code ({HTTP_STATUS_CODE}.bad_request)
							new_response_html (req, res,
								todo_item_html (l_todo) +
								"<div class=%"error%">Todo description cannot be empty.</div>")
						end
					end
				else
					res.set_status_code ({HTTP_STATUS_CODE}.not_found)
					res.put_string ("Todo not found")
				end
			else
				res.set_status_code ({HTTP_STATUS_CODE}.bad_request)
				res.put_string ("Invalid todo ID")
			end
		end

	new_response_text (req: WSF_REQUEST; res: WSF_RESPONSE; output: STRING)
			-- Send plain text response
		local
			h: HTTP_HEADER
		do
			create h.make
			h.put_content_type_text_plain
			h.put_content_length (output.count)
			h.put_current_date
			res.set_status_code ({HTTP_STATUS_CODE}.ok)
			res.put_header_text (h.string)
			res.put_string (output)
		end

	handle_toggle_todo_complete (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle PATCH /todos/:id/toggle-complete request
		local
			l_id: INTEGER
			l_todo_manager: TODO_MANAGER
			l_todo: detachable TODO
			l_id_param: WSF_VALUE
			h: HTTP_HEADER
		do
				-- Get the ID from the URL parameter
			l_id_param := req.path_parameter ("id")
			if attached {WSF_STRING} l_id_param as l_param and then l_param.is_integer then
				l_id := l_param.value.to_integer

					-- Get the todo
				create l_todo_manager
				l_todo := l_todo_manager.retrieve_by_id (l_id)

				if l_todo /= Void then
						-- Toggle completed status (switch between 0 and 1)
					l_todo.set_completed (1 - l_todo.completed)
					l_todo_manager.save (l_todo)

						-- Set HTMX trigger header for status update
					create h.make
					h.put_header_key_value ("HX-Trigger", "status-change")
					h.put_current_date
					res.put_header_text (h.string)

						-- Return updated todo HTML
					new_response_html (req, res, todo_item_html (l_todo))
				else
					res.set_status_code ({HTTP_STATUS_CODE}.not_found)
					res.put_string ("Todo not found")
				end
			else
				res.set_status_code ({HTTP_STATUS_CODE}.bad_request)
				res.put_string ("Invalid todo ID")
			end
		end

feature {NONE} -- Implementation

	todo_item_html (todo: TODO): STRING
		do
			create Result.make_from_string ("")
			Result.append ("<div class=%"todo-item%" x-data=%"{id: " + todo.id.out + "}%">")

				-- Checkbox with proper HTMX attributes
			Result.append ("<input type=%"checkbox%" ")

			if todo.completed = 1  then
				Result.append ("checked ")
			end

			Result.append ("hx-patch=%"/todos/" + todo.id.out +
				"/toggle-complete%" hx-target=%"closest div%" " +
				"hx-swap=%"outerHTML%">")

				-- Description text with Alpine.js click handling
			Result.append ("<div class=%"description%" x-show=%"id !== editingId%" x-on:click.stop=%"editingId = id%" >" + todo.description + "</div>")

				-- Edit input with proper HTMX triggers
			Result.append ("<input type=%"text%" name=%"description%" " +
				"value=%"" + todo.description + "%"" +
				"hx-trigger=%"blur, keyup[keyCode === 13]%" " +
				"hx-patch=%"/todos/" + todo.id.out + "/description%" " +
				"hx-target=%"closest div%" hx-swap=%"outerHTML%" " +
				"x-show=%"id === editingId%" x-on:click.stop=%"%" >")

				-- Delete button with confirmation and animation
			Result.append ("<button class=%"plain%" " +
				"hx-confirm=%"Really delete %"" + todo.description + "%"?%" " +
				"hx-delete=%"/todos/" + todo.id.out + "%"" +
				"hx-target=%"closest div%" hx-swap=%"delete swap:1s%">Delete</button>")

			Result.append ("</div>")
		end

	add_todo (req: WSF_REQUEST; res: WSF_RESPONSE; a_description: STRING)
			-- Add a new todo with `a_description`.
			-- Return True if successful, False if error occurred.
		local
			l_todo_manager: TODO_MANAGER
			l_todo: TODO
			l_html: STRING
			h: HTTP_HEADER
		do
				-- Simulate delay for testing spinner (optional)
			{EXECUTION_ENVIRONMENT}.sleep (500_000_000) -- 500ms in nanoseconds

			create l_todo_manager

				-- Try to create the todo
			if not l_todo_manager.has_todo_with_description (a_description) then
					-- Create new todo
				create l_todo.make (0, a_description, 0)
				l_todo_manager.save (l_todo)

					-- Set HTMX trigger for status update
				create h.make
				h.put_header_key_value ("HX-Trigger", "status-change")
				h.put_current_date
				res.put_header_text (h.string)

					-- Generate HTML for new todo item
				create l_html.make_empty
				l_html.append (todo_item_html (l_todo))
					-- Clear any previous error message
				l_html.append ("<div class=%"error%"></div>")

				new_response_html (req, res, l_html)
			else
					-- Handle duplicate todo
				create l_html.make_from_string ("<div class=%"error%">")
				l_html.append ("duplicate todo %"")
				l_html.append (a_description)
				l_html.append ("%"</div>")

				new_response_html (req, res, l_html)
			end
		rescue
				-- Handle other errors
			create l_html.make_from_string ("<div class=%"error%">")
--            if attached {EXCEPTION} exception_manager.last_exception as e then
--                l_html.append (e.description)
--            else
--                l_html.append ("An unknown error occurred")
--            end
			l_html.append ("</div>")

			new_response_html (req, res, l_html)
		end

	new_error_html (req: WSF_REQUEST; res: WSF_RESPONSE; message: STRING)
			-- Send error HTML response
		do
			new_response_html (req, res,
				"<div id=%"error%" hx-swap-oob=%"true%">" + message + "</div>")
		end

end
