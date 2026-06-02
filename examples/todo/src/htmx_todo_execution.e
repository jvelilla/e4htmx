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
	EWF_GLIMMER_INTEGRATION

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
			filter.append (create {WSF_NO_CACHE_FILTER})
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
			www.set_max_age (0)
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
			c: EWF_GLIMMER_CONTEXT
		do
			create c.make (req, res)
			c.text ("Eiffel Web Framework: 24.11")
		end

	execute_not_found (uri: READABLE_STRING_8; req: WSF_REQUEST; res: WSF_RESPONSE)
			-- `uri' is not found, redirect to default page
		local
			c: EWF_GLIMMER_CONTEXT
		do
			create c.make (req, res)
			c.redirect (req.script_url ("/"))
		end

	handle_root (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle GET / request by redirecting to /todos
		local
			c: EWF_GLIMMER_CONTEXT
		do
			create c.make (req, res)
			c.redirect (req.script_url ("/todos"))
		end

feature -- Handlers

	handle_todos (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle GET and POST /todos requests
		local
			c: EWF_GLIMMER_CONTEXT
			l_description: detachable STRING
		do
			create c.make (req, res)

			if c.is_post then
					-- Handle POST request
				if attached c.form_value ("description") as l_desc then
					l_description := l_desc.to_string_8
					if not l_description.is_empty then
							-- Try to add new todo
						add_todo (c, l_description)
					else
							-- Empty description error
						c.set_status ({HTTP_STATUS_CODE}.bad_request)
						c.html ("<div class=%"error%">Todo description cannot be empty</div>")
					end
				else
					c.set_status ({HTTP_STATUS_CODE}.bad_request)
					c.html ("<div class=%"error%">Missing description parameter</div>")
				end
			else
					-- Handle GET request
				handle_todos_get (c)
			end
		end

	handle_todos_get (c: EWF_GLIMMER_CONTEXT)
			-- Handle GET /todos request
		local
			l_todo_manager: TODO_MANAGER
			l_todos: LIST [TODO]
			l_json: STRING
			l_html: STRING
			l_accept: detachable READABLE_STRING_32
		do
				-- Get Accept header
			l_accept := c.request.meta_string_variable ("HTTP_ACCEPT")

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
				c.json (l_json)
			else
					-- Check if this is a direct browser request (not via HTMX)
				if not c.htmx.is_htmx_request then
						-- Redirect direct browser requests to the index.html page
						-- so the user gets the fully styled web app layout.
					c.redirect (c.request.script_url ("/index.html"))
				else
						-- Return HTML fragment for HTMX requests
					create l_html.make_from_string (
						"<div id=%"todo-list%" x-on:description-change=%"editingId = 0%">")
					across l_todos as todo loop
						l_html.append (todo_item_html (todo.item))
					end

					l_html.append ("</div>")
					c.html (l_html)
				end
			end
		end

	handle_delete_todo (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle DELETE /todos/:id request
		local
			c: EWF_GLIMMER_CONTEXT
			l_id: INTEGER
			l_todo_manager: TODO_MANAGER
		do
			create c.make (req, res)
				-- Get the ID from the URL parameter
			if attached c.param ("id") as l_param and then l_param.is_integer then
				l_id := l_param.to_integer

					-- Delete the todo
				create l_todo_manager
				l_todo_manager.delete (l_id)

					-- Create and set headers including HTMX trigger
				c.set_trigger ("status-change")
				c.empty
			else
					-- Invalid ID parameter
				c.set_status ({HTTP_STATUS_CODE}.bad_request)
				c.text ("Invalid todo ID")
			end
		end

	handle_todos_status (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle GET /todos/status request
		local
			c: EWF_GLIMMER_CONTEXT
			l_todo_manager: TODO_MANAGER
			l_todos: LIST [TODO]
			l_uncompleted_count: INTEGER
			l_response: STRING
		do
			create c.make (req, res)
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

			c.text (l_response)
		end

	handle_update_todo_description (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle PATCH /todos/:id/description request
		local
			c: EWF_GLIMMER_CONTEXT
			l_id: INTEGER
			l_todo_manager: TODO_MANAGER
			l_todo: detachable TODO
			l_description: detachable STRING
		do
			create c.make (req, res)
				-- Get the ID from the URL parameter
			if attached c.param ("id") as l_param and then l_param.is_integer then
				l_id := l_param.to_integer

					-- Get the todo
				create l_todo_manager
				l_todo := l_todo_manager.retrieve_by_id (l_id)

				if l_todo /= Void then
						-- Get description from form data
					if attached c.form_value ("description") as l_desc then
						l_description := l_desc.to_string_8

						if not l_description.is_empty then
								-- Update todo
							l_todo.set_description (l_description)
							l_todo_manager.save (l_todo)

								-- Return updated todo HTML
							c.set_trigger ("description-change")
							c.html (todo_item_html (l_todo))
						else
								-- Empty description error
							c.set_status ({HTTP_STATUS_CODE}.bad_request)
							c.html (todo_item_html (l_todo) +
								"<div class=%"error%">Todo description cannot be empty.</div>")
						end
					end
				else
					c.set_status ({HTTP_STATUS_CODE}.not_found)
					c.text ("Todo not found")
				end
			else
				c.set_status ({HTTP_STATUS_CODE}.bad_request)
				c.text ("Invalid todo ID")
			end
		end

	handle_toggle_todo_complete (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle PATCH /todos/:id/toggle-complete request
		local
			c: EWF_GLIMMER_CONTEXT
			l_id: INTEGER
			l_todo_manager: TODO_MANAGER
			l_todo: detachable TODO
		do
			create c.make (req, res)
				-- Get the ID from the URL parameter
			if attached c.param ("id") as l_param and then l_param.is_integer then
				l_id := l_param.to_integer

					-- Get the todo
				create l_todo_manager
				l_todo := l_todo_manager.retrieve_by_id (l_id)

				if l_todo /= Void then
						-- Toggle completed status (switch between 0 and 1)
					l_todo.set_completed (1 - l_todo.completed)
					l_todo_manager.save (l_todo)

						-- Return updated todo HTML
					c.set_trigger ("status-change")
					c.html (todo_item_html (l_todo))
				else
					c.set_status ({HTTP_STATUS_CODE}.not_found)
					c.text ("Todo not found")
				end
			else
				c.set_status ({HTTP_STATUS_CODE}.bad_request)
				c.text ("Invalid todo ID")
			end
		end

feature {NONE} -- Implementation

	todo_item_html (todo: TODO): STRING
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING_32
		do
			create l_template.make
			l_template.set_variable ("todo", todo)
			l_result := l_template.render_file (document_root.appended ("\todo_item.html").name)
			
			if l_template.has_error and then attached l_template.last_error as err then
				Result := "<div class=%"error%">" + err.to_string_8 + "</div>"
			else
				Result := l_result.to_string_8
			end
		end

	add_todo (c: EWF_GLIMMER_CONTEXT; a_description: STRING)
			-- Add a new todo with `a_description`.
		local
			l_todo_manager: TODO_MANAGER
			l_todo: TODO
			l_html: STRING
		do
				-- Simulate delay for testing spinner (optional)
			{EXECUTION_ENVIRONMENT}.sleep (500_000_000) -- 500ms in nanoseconds

			create l_todo_manager

				-- Try to create the todo
			if not l_todo_manager.has_todo_with_description (a_description) then
					-- Create new todo
				create l_todo.make (0, a_description, 0)
				l_todo_manager.save (l_todo)

					-- Generate HTML for new todo item
				create l_html.make_empty
				l_html.append (todo_item_html (l_todo))
					-- Clear any previous error message
				l_html.append ("<div class=%"error%"></div>")

				c.set_trigger ("status-change")
				c.html (l_html)
			else
					-- Handle duplicate todo
				create l_html.make_from_string ("<div class=%"error%">")
				l_html.append ("duplicate todo %"")
				l_html.append (a_description)
				l_html.append ("%"</div>")

				c.html (l_html)
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

			c.html (l_html)
		end



end
