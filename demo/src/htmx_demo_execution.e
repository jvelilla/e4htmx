note
	description: "[
			application execution
		]"
	date: "$Date$"
	revision: "$Revision$"

class
	HTMX_DEMO_EXECUTION

inherit

	WSF_FILTERED_ROUTED_EXECUTION

	WSF_ROUTED_URI_TEMPLATE_HELPER

	WSF_ROUTED_URI_HELPER

	SHARED_EXECUTION_ENVIRONMENT

	SHARED_SERVICES

	EWF_GLIMMER_INTEGRATION

create
	make

feature {NONE} -- Initialization

feature -- Filter

	create_filter
			-- Create `filter'
		do
				--| Example using Maintenance filter.
			create {WSF_MAINTENANCE_FILTER} filter
		end

	setup_filter
			-- Setup `filter'
		local
			f: like filter
		do
			create {WSF_CORS_FILTER} f
			f.set_next (create {WSF_LOGGING_FILTER})

				--| Chain more filters like {WSF_CUSTOM_HEADER_FILTER}, ...
				--| and your owns filters.

			filter.append (f)
		end

feature -- Router

	setup_router
			-- Setup `router'
		local
			www: WSF_FILE_SYSTEM_HANDLER
			l_dog: DOG
		do
				--| As example:
				--|   /doc is dispatched to self documentated page
				--|   /* are dispatched to serve files/directories contained in "www" directory

				--| Self documentation
			router.handle ("/doc", create {WSF_ROUTER_SELF_DOCUMENTATION_HANDLER}.make (router), router.methods_GET)

			map_uri_agent ("/version", agent handle_version, router.methods_get)
			map_uri_agent ("/table-rows", agent handle_table_rows, router.methods_GET)
			map_uri_agent ("/dog", agent handle_add_dog_post, router.methods_POST)
			map_uri_template_agent ("/dog/{id}", agent handle_delete_dog, router.methods_DELETE)
			map_uri_agent ("/oob", agent handle_oob, router.methods_GET)
			map_uri_agent ("/oob/demo", agent handle_oob_demo, router.methods_GET)
			map_uri_agent ("/event-with-no-data", agent handle_event_with_no_data, router.methods_GET)
			map_uri_agent ("/event-with-string", agent handle_event_with_string, router.methods_GET)
			map_uri_agent ("/event-with-object", agent handle_event_with_object, router.methods_GET)
			map_uri_agent ("/trigger", agent handle_trigger, router.methods_GET)
			map_uri_agent ("/filters-demo", agent handle_filters_demo, router.methods_GET)
			map_uri_agent ("/filters-demo/render", agent handle_filters_playground_render, router.methods_POST)
			map_uri_agent ("/dbc-demo", agent handle_dbc_demo, router.methods_GET)
			map_uri_agent ("/dbc-demo/render", agent handle_dbc_playground_render, router.methods_POST)
			map_uri_agent ("/components-demo", agent handle_components_demo, router.methods_GET)
			map_uri_agent ("/components-demo/render", agent handle_components_playground_render, router.methods_POST)
			map_uri_agent ("/slots-demo", agent handle_slots_demo, router.methods_GET)
			map_uri_agent ("/slots-demo/render", agent handle_slots_playground_render, router.methods_POST)

			create www.make_with_path (document_root)
			www.set_directory_index (<<"index2.html">>)
			www.set_not_found_handler (agent execute_not_found)
			router.handle ("", www, router.methods_GET)


		end

feature -- Configuration

	document_root: PATH
			-- Document root to look for files or directories
		once
				--| As example:
				--|   /doc is dispatched to self documentated page
				--|   /* are dispatched to serve files/directories contained in "www" directory

				--| Self documentation
			Result := execution_environment.current_working_path.extended ("www")
		end

feature -- Events

	handle_version (req: WSF_REQUEST; res: WSF_RESPONSE)
		local
			c: EWF_GLIMMER_CONTEXT
			l_result: STRING_8
			-- l_htmx_req: GLM_HTMX_REQUEST
		do
			-- l_htmx_req := GLM_HTMX_REQUEST (req)
			-- if l_htmx_req.is_htmx_request then
			-- 	l_result := "Eiffel Web Framework: 24.11 (via HTMX)"
			-- else
			-- 	l_result := "Eiffel Web Framework: 24.11"
			-- end
			-- res.set_status_code ({HTTP_STATUS_CODE}.ok)
			-- new_response (req, res, l_result)

			create c.make (req, res)
			if c.htmx.is_htmx_request then
				l_result := "Eiffel Web Framework: 24.11 (via HTMX)"
			else
				l_result := "Eiffel Web Framework: 24.11"
			end
			c.html (l_result)
		end

	new_response (req: WSF_REQUEST; res: WSF_RESPONSE; output: STRING)
		local
			h: HTTP_HEADER
		do
			create h.make
			h.put_content_type_text_html
			h.put_content_length (output.count)
			h.put_current_date
			res.put_header_text (h.string)
			res.put_string (output)
		end

	execute_not_found (uri: READABLE_STRING_8; req: WSF_REQUEST; res: WSF_RESPONSE)
			-- `uri' is not found, redirect to default page
		do
			res.redirect_now_with_content (req.script_url ("/"), uri + ": not found.%NRedirection to " + req.script_url ("/"), "text/html")
		end

	handle_table_rows (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle request for table rows of dogs, sorted by name
		local
			c: EWF_GLIMMER_CONTEXT
			l_dogs: ARRAYED_LIST [DOG]
			l_template: GLM_HTML_TEMPLATE
			-- l_html: STRING
			l_sorter: SORTER [DOG]
		do
				-- Convert hash table to sorted array
			create l_dogs.make_from_iterable (shared_dogs.linear_representation)

				-- Create and apply quick sorter
			create {QUICK_SORTER [DOG]} l_sorter.make (
				create {AGENT_EQUALITY_TESTER [DOG]}.make (
					agent (a_dog1, a_dog2: DOG): BOOLEAN
						do
							Result := a_dog1.name < a_dog2.name
						end))
			l_sorter.sort (l_dogs)

			-- create l_template.make
			-- l_template.set_variable ("dogs", l_dogs)
			-- l_html := l_template.render ("[
			-- 	{{each dog in dogs}}
			-- 	<tr class="on-hover">
			-- 		<td>{dog.name}</td>
			-- 		<td>{dog.breed}</td>
			-- 		<td class="buttons">
			-- 			<button
			-- 				class="show-on-hover"
			-- 				hx-delete="/dog/{dog.id}"
			-- 				hx-confirm="Are you sure?"
			-- 				hx-target="closest tr"
			-- 				hx-swap="delete"
			-- 			>X</button>
			-- 		</td>
			-- 	</tr>
			-- 	{{end}}
			-- ]").to_string_8
			-- res.set_status_code ({HTTP_STATUS_CODE}.ok)
			-- new_response (req, res, l_html)

			create c.make (req, res)
			create l_template.make
			l_template.set_variable ("dogs", l_dogs)
			c.render (l_template, "[
				{{each dog in dogs}}
				<tr class="on-hover">
					<td>{dog.name}</td>
					<td>{dog.breed}</td>
					<td class="buttons">
						<button
							class="show-on-hover"
							hx-delete="/dog/{dog.id}"
							hx-confirm="Are you sure?"
							hx-target="closest tr"
							hx-swap="delete"
						>X</button>
					</td>
				</tr>
				{{end}}
			]")
		end

	handle_add_dog_post (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle POST request to add a new dog and return its row HTML
		local
			c: EWF_GLIMMER_CONTEXT
			l_dog: DOG
			-- l_html: STRING
		do
			-- if
			-- 	attached {WSF_STRING} req.form_parameter ("name") as l_name and then
			-- 	attached {WSF_STRING} req.form_parameter ("breed") as l_breed
			-- then
			-- 	-- Add dog to database
			-- 	l_dog := add_dog (l_name.value, l_breed.value)
			-- 	-- Generate HTML row for the new dog
			-- 	l_html := dog_row (l_dog)
			-- 	-- Send response with 201 Created status
			-- 	res.set_status_code ({HTTP_STATUS_CODE}.created)
			-- 	new_response (req, res, l_html)
			-- else
			-- 	-- Updated error handling
			-- 	res.set_status_code ({HTTP_STATUS_CODE}.bad_request)
			-- 	res.put_string ("Missing required parameters")
			-- end

			create c.make (req, res)
			if
				attached c.form_value ("name") as l_name and then
				attached c.form_value ("breed") as l_breed
			then
				l_dog := add_dog (l_name, l_breed)
				c.set_status ({HTTP_STATUS_CODE}.created)
				c.html (dog_row (l_dog))
			else
				c.set_status ({HTTP_STATUS_CODE}.bad_request)
				c.text ("Missing required parameters")
			end
		end

	handle_delete_dog (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle DELETE request to remove a dog
		local
			c: EWF_GLIMMER_CONTEXT
			-- l_id: STRING
		do
			-- if attached {WSF_STRING} req.path_parameter ("id") as p_id then
			-- 	l_id := p_id.value
			-- 	if shared_dogs.has (l_id) then
			-- 		-- Remove dog from database
			-- 		shared_dogs.remove (l_id)
			-- 		-- Send empty response with 204 No Content status
			-- 		res.set_status_code ({HTTP_STATUS_CODE}.ok)
			-- 		new_response (req, res, "")
			-- 	else
			-- 		-- Updated error handling
			-- 		res.set_status_code ({HTTP_STATUS_CODE}.not_found)
			-- 		res.put_string ("Dog not found")
			-- 	end
			-- else
			-- 	-- Updated error handling
			-- 	res.set_status_code ({HTTP_STATUS_CODE}.bad_request)
			-- 	res.put_string ("Missing dog ID")
			-- end

			create c.make (req, res)
			if attached c.param ("id") as l_id then
				if shared_dogs.has (l_id) then
					shared_dogs.remove (l_id)
					c.empty
				else
					c.not_found
				end
			else
				c.set_status ({HTTP_STATUS_CODE}.bad_request)
				c.text ("Missing dog ID")
			end
		end

	handle_oob (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle request for the out-of-band demo page
		local
			c: EWF_GLIMMER_CONTEXT
			-- l_html: STRING
		do
			-- l_html := oob_page
			-- res.set_status_code ({HTTP_STATUS_CODE}.ok)
			-- new_response (req, res, l_html)

			create c.make (req, res)
			c.html (oob_page)
		end

	handle_oob_demo (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle request for the out-of-band demo response
		local
			c: EWF_GLIMMER_CONTEXT
			l_template: GLM_HTML_TEMPLATE
			-- l_html: STRING
		do
			-- create l_template.make
			-- l_html := l_template.render ("[
			-- 	<div>new 1</div>
			-- 	<div id="target2" hx-swap-oob="true">
			-- 		new 2
			-- 	</div>
			-- 	<div id="target2" hx-swap-oob="afterend">
			-- 		<div>after 2</div>
			-- 	</div>
			-- 	<div hx-swap-oob="innerHTML:#target3">new 3</div>
			-- ]").to_string_8
			-- res.set_status_code ({HTTP_STATUS_CODE}.ok)
			-- new_response (req, res, l_html)

			create c.make (req, res)
			create l_template.make
			c.render (l_template, "[
				<div>new 1</div>
				<div id="target2" hx-swap-oob="true">
					new 2
				</div>
				<div id="target2" hx-swap-oob="afterend">
					<div>after 2</div>
				</div>
				<div hx-swap-oob="innerHTML:#target3">new 3</div>
			]")
		end

	handle_event_with_no_data (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle request that triggers event1 with no data
		local
			c: EWF_GLIMMER_CONTEXT
			-- h: HTTP_HEADER
			-- l_template: GLM_HTML_TEMPLATE
			-- l_output: STRING
		do
			-- create l_template.make
			-- l_template.add_trigger ("event1")
			-- l_output := "dispatched event1"
			-- create h.make
			-- h.put_content_type_text_plain
			-- h.put_content_length (l_output.count)
			-- h.put_current_date
			-- apply_htmx_headers (l_template, h)
			-- res.set_status_code ({HTTP_STATUS_CODE}.ok)
			-- res.put_header_text (h.string)
			-- res.put_string (l_output)

			create c.make (req, res)
			c.set_trigger ("event1")
			c.text ("dispatched event1")
		end

	handle_event_with_string (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle request that triggers event2 with string data
		local
			c: EWF_GLIMMER_CONTEXT
			-- h: HTTP_HEADER
			-- l_trigger: STRING
			-- l_output: STRING
		do
			-- l_trigger := "{%"event2%":%"some string%"}"
			-- l_output := "dispatched event2"
			-- create h.make
			-- h.put_content_type_text_plain
			-- h.put_header_key_value ("HX-Trigger", l_trigger)
			-- h.put_content_length (l_output.count)
			-- h.put_current_date
			-- res.set_status_code ({HTTP_STATUS_CODE}.ok)
			-- res.put_header_text (h.string)
			-- res.put_string (l_output)

			create c.make (req, res)
			c.set_trigger ("{%"event2%":%"some string%"}")
			c.text ("dispatched event2")
		end

	handle_event_with_object (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle request that triggers event3 with object data
		local
			c: EWF_GLIMMER_CONTEXT
			-- h: HTTP_HEADER
			-- l_trigger: STRING
			-- l_output: STRING
		do
			-- l_trigger := "{%"event3%":{%"foo%":1,%"bar%":2}}"
			-- l_output := "dispatched event3"
			-- create h.make
			-- h.put_content_type_text_plain
			-- h.put_header_key_value ("HX-Trigger", l_trigger)
			-- h.put_content_length (l_output.count)
			-- h.put_current_date
			-- res.set_status_code ({HTTP_STATUS_CODE}.ok)
			-- res.put_header_text (h.string)
			-- res.put_string (l_output)

			create c.make (req, res)
			c.set_trigger ("{%"event3%":{%"foo%":1,%"bar%":2}}")
			c.text ("dispatched event3")
		end

	handle_trigger (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle request for the event triggering demo page
		local
			c: EWF_GLIMMER_CONTEXT
			l_template: GLM_HTML_TEMPLATE
			-- l_html: STRING
		do
			-- create l_template.make
			-- l_html := l_template.render ("[
			-- 	<html>
			-- 	  <head>
			-- 	    <title>htmx Event Triggering</title>
			-- 	    <script src="https://unpkg.com/htmx.org@2.0.0"></script>
			-- 	    <script>
			-- 	      function handleEvent1(event) {
			-- 	        const {value} = event.detail;
			-- 	        alert('got event1 with ' + value);
			-- 	      }
			-- 	      function handleEvent2(event) {
			-- 	        const {value} = event.detail;
			-- 	        alert('got event2 with ' + JSON.stringify(value));
			-- 	      }
			-- 	      function handleEvent3(event) {
			-- 	        const {detail} = event;
			-- 	        // detail.elt holds a reference to the element that
			-- 	        // triggered the request.  JSON.stringify encounters a
			-- 	        // circular reference if that is included, so we remove it.
			-- 	        delete detail.elt;
			-- 	        alert('got event3 with ' + JSON.stringify(detail));
			-- 	      }
			-- 	    </script>
			-- 	  </head>
			-- 	  <body
			-- 	    hx-on:event1="handleEvent1(event)"
			-- 	    hx-on:event2="handleEvent2(event)"
			-- 	    hx-on:event3="handleEvent3(event)"
			-- 	  >
			-- 	    <button hx-get="/event-with-no-data" hx-target="#content">
			-- 	      Event w/ no data
			-- 	    </button>
			-- 	    <button hx-get="/event-with-string" hx-target="#content">
			-- 	      Event w/ string
			-- 	    </button>
			-- 	    <button hx-get="/event-with-object" hx-target="#content">
			-- 	      Event w/ object
			-- 	    </button>
			-- 	    <div id="content"></div>
			-- 	  </body>
			-- 	</html>
			-- ]").to_string_8
			-- res.set_status_code ({HTTP_STATUS_CODE}.ok)
			-- new_response (req, res, l_html)

			create c.make (req, res)
			create l_template.make
			c.render (l_template, "[
				<html>
				  <head>
				    <title>htmx Event Triggering</title>
				    <script src="https://unpkg.com/htmx.org@2.0.0"></script>
				    <script>
				      function handleEvent1(event) {
				        const {value} = event.detail;
				        alert('got event1 with ' + value);
				      }
				      function handleEvent2(event) {
				        const {value} = event.detail;
				        alert('got event2 with ' + JSON.stringify(value));
				      }
				      function handleEvent3(event) {
				        const {detail} = event;
				        // detail.elt holds a reference to the element that
				        // triggered the request.  JSON.stringify encounters a
				        // circular reference if that is included, so we remove it.
				        delete detail.elt;
				        alert('got event3 with ' + JSON.stringify(detail));
				      }
				    </script>
				  </head>
				  <body
				    hx-on:event1="handleEvent1(event)"
				    hx-on:event2="handleEvent2(event)"
				    hx-on:event3="handleEvent3(event)"
				  >
				    <button hx-get="/event-with-no-data" hx-target="#content">
				      Event w/ no data
				    </button>
				    <button hx-get="/event-with-string" hx-target="#content">
				      Event w/ string
				    </button>
				    <button hx-get="/event-with-object" hx-target="#content">
				      Event w/ object
				    </button>
				    <div id="content"></div>
				  </body>
				</html>
			]")
		end

feature -- Database Operations

	add_dog (a_name: STRING; a_breed: STRING): DOG
			-- Add a new dog to the in-memory database
			-- Returns the created DOG object
		local
			l_dog: DOG
		do
				-- Create a new DOG instance
			create l_dog.make (a_name, a_breed)

				-- Store in shared dogs (assuming it's a HASH_TABLE[DOG, STRING])
			shared_dogs.force (l_dog, l_dog.id)

				-- Return the created dog
			Result := l_dog
		ensure
			dog_added: shared_dogs.has (Result.id)
			correct_data: Result.name = a_name and Result.breed = a_breed
		end

feature -- HTML Generation

	dog_row (a_dog: DOG): STRING
			-- Generate HTML row for dog table
		local
			l_template: GLM_HTML_TEMPLATE
		do
			create l_template.make
			l_template.set_variable ("dog", a_dog)

			Result := l_template.render ("[
				<tr class="on-hover">
					<td>{dog.name}</td>
					<td>{dog.breed}</td>
					<td class="buttons">
						<button
							class="show-on-hover"
							hx-delete="/dog/{dog.id}"
							hx-confirm="Are you sure?"
							hx-target="closest tr"
							hx-swap="delete"
						>X</button>
					</td>
				</tr>
			]").to_string_8
		ensure
			result_not_empty: not Result.is_empty
			contains_dog_info: Result.has_substring (a_dog.name.to_string_8) and Result.has_substring (a_dog.breed.to_string_8)
		end

	oob_page: STRING
		local
			l_template: GLM_HTML_TEMPLATE
		do
			create l_template.make
			Result := l_template.render ("[
				<html>
				<head>
				<title>Out-of-Band Demo</title>
				<script src="https://unpkg.com/htmx.org@2.0.0"></script>
				</head>
				<body>
				<button hx-get="/oob/demo" hx-target="#target1">Send</button>
				<div id="target1">original 1</div>
				<div id="target2">original 2</div>
				<div id="target3">original 3</div>
				</body>
				</html>
			]").to_string_8
		end

feature -- Glimmer Filters Demo Event Handlers

	handle_filters_demo (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle GET request for Glimmer filters and helpers showcase
		local
			c: EWF_GLIMMER_CONTEXT
			l_template: GLM_HTML_TEMPLATE
			l_date: DATE
			l_datetime: DATE_TIME
		do
			create c.make (req, res)
			create l_template.make
			
			-- Register custom helper agents
			l_template.register_helper ("gravatar_url", agent gravatar_url)
			l_template.register_helper ("status_badge", agent status_badge)
			l_template.register_helper ("slugify", agent slugify)

			-- Set template variables
			l_template.set_variable ("app_title", "Glimmer Filters & Helpers Showcase")
			l_template.set_variable ("user_name", "Javier")
			l_template.set_variable ("email", "javier@eiffel.org")
			l_template.set_variable ("balance", 12500.75)
			
			create l_date.make (2026, 5, 31)
			create l_datetime.make (2026, 5, 31, 12, 30, 0)
			l_template.set_variable ("created_at", l_datetime)
			l_template.set_variable ("created_at_raw", l_datetime.out.to_string_32)
			l_template.set_variable ("score", 94.5678)
			l_template.set_variable ("status", "active")
			l_template.set_variable ("description", "The Glimmer template engine is now equipped with powerful built-in formatting filters and agent-based custom helpers. Try them out!")
			
			-- Render from template file
			c.render_file (l_template, document_root.extended ("filters_demo.html").name)
		end

	handle_filters_playground_render (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle POST request from playground form to dynamically compile and render template
		local
			c: EWF_GLIMMER_CONTEXT
			l_template: GLM_HTML_TEMPLATE
			l_text: STRING_32
			l_price: REAL_64
			l_email: STRING_32
			l_tpl_str: STRING_32
		do
			create c.make (req, res)
			
			-- Retrieve and sanitize inputs
			if attached c.form_value ("val_text") as t then
				l_text := t
			else
				l_text := "Eiffel Web Framework rules"
			end
			
			if attached c.form_value ("val_price") as p and then p.is_double then
				l_price := p.to_double
			else
				l_price := 489.95
			end
			
			if attached c.form_value ("val_email") as e then
				l_email := e
			else
				l_email := "javier@eiffel.org"
			end
			
			if attached c.form_value ("playground_template") as tpl then
				l_tpl_str := tpl
			else
				l_tpl_str := "Hello {val_text | upper}! Price: {val_price | currency: %"USD%"}"
			end
			
			create l_template.make
			
			-- Register custom helper agents
			l_template.register_helper ("gravatar_url", agent gravatar_url)
			l_template.register_helper ("status_badge", agent status_badge)
			l_template.register_helper ("slugify", agent slugify)
			
			-- Set template variables
			l_template.set_variable ("val_text", l_text)
			l_template.set_variable ("val_price", l_price)
			l_template.set_variable ("val_email", l_email)
			
			-- Render playground content
			c.render (l_template, l_tpl_str)
		end

feature -- Template Helpers

	gravatar_url (a_val: detachable ANY): STRING_32
			-- Generate a Dicebear robot avatar SVG URL based on input email `a_val`
		local
			l_email: STRING_32
		do
			if attached a_val as v then
				l_email := v.out.to_string_32
				l_email.left_adjust
				l_email.right_adjust
				Result := "https://api.dicebear.com/7.x/bottts/svg?seed=" + l_email
			else
				Result := "https://api.dicebear.com/7.x/bottts/svg?seed=default"
			end
		ensure
			result_attached: Result /= Void
		end

	status_badge (a_val: detachable ANY): STRING_32
			-- Convert a status string `a_val` into a styled HTML badge span
		local
			l_status: STRING_32
		do
			if attached a_val as v then
				l_status := v.out.to_string_32
				l_status.left_adjust
				l_status.right_adjust
				l_status.to_lower
				
				if l_status.same_string ("active") or l_status.same_string ("completed") or l_status.same_string ("success") then
					Result := "<span class=%"badge badge-success%">" + l_status + "</span>"
				elseif l_status.same_string ("pending") or l_status.same_string ("warning") then
					Result := "<span class=%"badge badge-warning%">" + l_status + "</span>"
				elseif l_status.same_string ("inactive") or l_status.same_string ("failed") or l_status.same_string ("error") then
					Result := "<span class=%"badge badge-danger%">" + l_status + "</span>"
				else
					Result := "<span class=%"badge badge-info%">" + l_status + "</span>"
				end
			else
				Result := "<span class=%"badge badge-muted%">unknown</span>"
			end
		ensure
			result_attached: Result /= Void
		end

	slugify (a_val: detachable ANY): STRING_32
			-- Convert text `a_val` into a URL-friendly lowercase-hyphenated slug
		local
			l_str: STRING_32
			i: INTEGER
			c: CHARACTER_32
		do
			if attached a_val as v then
				l_str := v.out.to_string_32
				l_str.left_adjust
				l_str.right_adjust
				l_str.to_lower
				
				create Result.make (l_str.count)
				from
					i := 1
				until
					i > l_str.count
				loop
					c := l_str.item (i)
					if c.is_alpha_numeric then
						Result.append_character (c)
					elseif c = ' ' or c = '-' or c = '_' then
						if not Result.is_empty and then Result.item (Result.count) /= '-' then
							Result.append_character ('-')
						end
					end
					i := i + 1
				end
			else
				create Result.make_empty
			end
		ensure
			result_attached: Result /= Void
		end

	handle_dbc_demo (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle GET request for Glimmer DbC and playground showcase
		local
			c: EWF_GLIMMER_CONTEXT
			l_template: GLM_HTML_TEMPLATE
			l_user: USER_PROFILE
			l_skills: ARRAYED_LIST [STRING_32]
		do
			create c.make (req, res)
			create l_template.make
			
			-- Enable contract mode by default for playground showcase
			l_template.set_contract_mode (True)

			-- Set template variables
			l_template.set_variable ("app_title", "Glimmer Design by Contract Playground")
			l_template.set_variable ("username", "Javier")
			l_template.set_variable ("age", 30)
			l_template.set_variable ("is_admin", True)
			
			create l_user.make ("Javier", 30, True)
			l_template.set_variable ("user", l_user)
			
			create l_skills.make (3)
			l_skills.extend ("Eiffel")
			l_skills.extend ("HTMX")
			l_skills.extend ("Glimmer")
			l_template.set_variable ("skills", l_skills)
			
			-- Render from template file
			c.render_file (l_template, document_root.extended ("dbc_demo.html").name)
		end

	handle_dbc_playground_render (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle POST request from DbC playground to compile and render template
		local
			c: EWF_GLIMMER_CONTEXT
			l_template: GLM_HTML_TEMPLATE
			l_username: detachable STRING_32
			l_age: INTEGER
			l_is_admin: BOOLEAN
			l_contract_mode: BOOLEAN
			l_validation_mode: BOOLEAN
			l_tpl_str: STRING_32
			l_user: USER_PROFILE
			l_skills: ARRAYED_LIST [STRING_32]
		do
			create c.make (req, res)
			
			-- Retrieve and sanitize inputs
			l_username := c.form_value ("username")
			if l_username /= Void then
				l_username.left_adjust
				l_username.right_adjust
			end
			
			if attached c.form_value ("age") as a and then a.is_integer then
				l_age := a.to_integer
			else
				l_age := 0
			end
			
			l_is_admin := c.form_value ("is_admin") /= Void
			l_contract_mode := c.form_value ("contract_mode") /= Void
			l_validation_mode := c.form_value ("validation_mode") /= Void
			
			if attached c.form_value ("playground_template") as tpl then
				l_tpl_str := tpl
			else
				l_tpl_str := "Hello {username}!"
			end
			
			-- 1. Input Validation Phase (Boundary check in controller)
			if l_validation_mode then
				if l_username = Void or else l_username.is_empty then
					c.set_status ({HTTP_STATUS_CODE}.ok) -- user error is handled flow, 200 OK
					c.html ("[
						<div class="validation-error-banner" style="background-color: rgba(245, 158, 11, 0.08); border: 1px solid rgba(245, 158, 11, 0.2); padding: 1.25rem; border-radius: var(--radius-md); color: #fcd34d;">
							<h4 style="margin: 0 0 0.5rem 0; font-family: var(--font-display); font-weight: 700; font-size: 1.05rem; color: #f59e0b; display: flex; align-items: center; gap: 0.5rem;">
								<span>⚠️</span> User Input Validation Error (Soft Flow)
							</h4>
							<p style="margin: 0; font-size: 0.9rem; color: var(--text-secondary); line-height: 1.5;">
								<strong>Validation failure:</strong> Username is a required field and cannot be blank.
							</p>
							<p style="margin: 0.5rem 0 0 0; font-size: 0.8rem; color: var(--text-muted); line-height: 1.4;">
								<em>Eiffel Controller:</em> "We intercepted the user error at the boundary. We will NOT attempt to render the contracted template because the required data is missing. This is a clean input validation flow."
							</p>
						</div>
					]")
				elseif l_age < 18 then
					c.set_status ({HTTP_STATUS_CODE}.ok)
					c.html ("[
						<div class="validation-error-banner" style="background-color: rgba(245, 158, 11, 0.08); border: 1px solid rgba(245, 158, 11, 0.2); padding: 1.25rem; border-radius: var(--radius-md); color: #fcd34d;">
							<h4 style="margin: 0 0 0.5rem 0; font-family: var(--font-display); font-weight: 700; font-size: 1.05rem; color: #f59e0b; display: flex; align-items: center; gap: 0.5rem;">
								<span>⚠️</span> User Input Validation Error (Soft Flow)
							</h4>
							<p style="margin: 0; font-size: 0.9rem; color: var(--text-secondary); line-height: 1.5;">
								<strong>Validation failure:</strong> Registration is restricted to age 18 or above (Provided: " + l_age.out + ").
							</p>
							<p style="margin: 0.5rem 0 0 0; font-size: 0.8rem; color: var(--text-muted); line-height: 1.4;">
								<em>Eiffel Controller:</em> "We intercepted the user error at the boundary. We will NOT attempt to render the contracted template because the precondition age >= 18 is not met by the input. This is a clean input validation flow."
							</p>
						</div>
					]")
				else
					-- Proceed with valid inputs
					create l_template.make
					l_template.set_contract_mode (l_contract_mode)
					
					l_template.set_variable ("username", l_username)
					create l_user.make (l_username, l_age, l_is_admin)
					l_template.set_variable ("user", l_user)
					l_template.set_variable ("age", l_age)
					l_template.set_variable ("is_admin", l_is_admin)
					
					create l_skills.make (3)
					l_skills.extend ("Eiffel")
					l_skills.extend ("HTMX")
					l_skills.extend ("Glimmer")
					l_template.set_variable ("skills", l_skills)
					
					c.render (l_template, l_tpl_str)
				end
			else
				-- 2. No Input Validation (Direct contract invocation - simulates developer oversight)
				create l_template.make
				l_template.set_contract_mode (l_contract_mode)
				
				-- If username is not empty, set it (otherwise leave it out to trigger presence check)
				if l_username /= Void and then not l_username.is_empty then
					l_template.set_variable ("username", l_username)
					create l_user.make (l_username, l_age, l_is_admin)
					l_template.set_variable ("user", l_user)
				end
				
				l_template.set_variable ("age", l_age)
				l_template.set_variable ("is_admin", l_is_admin)
				
				create l_skills.make (3)
				l_skills.extend ("Eiffel")
				l_skills.extend ("HTMX")
				l_skills.extend ("Glimmer")
				l_template.set_variable ("skills", l_skills)
				
				c.render (l_template, l_tpl_str)
			end
		end

	handle_components_demo (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle GET request for Glimmer components and playground showcase
		local
			c: EWF_GLIMMER_CONTEXT
			l_template: GLM_HTML_TEMPLATE
		do
			create c.make (req, res)
			create l_template.make
			
			-- Enable contract mode by default for playground showcase
			l_template.set_contract_mode (True)

			-- Set template variables
			l_template.set_variable ("app_title", "Glimmer Component Composition Playground")
			l_template.set_variable ("user_name", "Javier")
			l_template.set_variable ("user_role", "Architect")
			l_template.set_variable ("company", "Eiffel Language Foundation")
			
			-- Render from template file
			c.render_file (l_template, document_root.extended ("components_demo.html").name)
		end

	handle_components_playground_render (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle POST request from components playground to render template with custom component
		local
			c: EWF_GLIMMER_CONTEXT
			l_template: GLM_HTML_TEMPLATE
			l_user_name: detachable STRING_32
			l_user_role: detachable STRING_32
			l_company: detachable STRING_32
			l_contract_mode: BOOLEAN
			l_tpl_str: STRING_32
			l_comp_tpl_str: STRING_32
		do
			create c.make (req, res)
			
			-- Retrieve and sanitize inputs
			l_user_name := c.form_value ("user_name")
			if l_user_name /= Void then
				l_user_name.left_adjust
				l_user_name.right_adjust
			end
			
			l_user_role := c.form_value ("user_role")
			if l_user_role /= Void then
				l_user_role.left_adjust
				l_user_role.right_adjust
			end
			
			l_company := c.form_value ("company")
			if l_company /= Void then
				l_company.left_adjust
				l_company.right_adjust
			end
			
			l_contract_mode := c.form_value ("contract_mode") /= Void
			
			if attached c.form_value ("playground_template") as tpl then
				l_tpl_str := tpl
			else
				l_tpl_str := ""
			end
			
			if attached c.form_value ("component_template") as comp_tpl then
				l_comp_tpl_str := comp_tpl
			else
				l_comp_tpl_str := ""
			end
			
			create l_template.make
			l_template.set_contract_mode (l_contract_mode)
			
			-- Register the user's component template as a partial
			l_template.register_partial ("user_badge", l_comp_tpl_str)
			
			-- Bind variables
			if l_user_name /= Void and then not l_user_name.is_empty then
				l_template.set_variable ("user_name", l_user_name)
			end
			if l_user_role /= Void and then not l_user_role.is_empty then
				l_template.set_variable ("user_role", l_user_role)
			end
			if l_company /= Void and then not l_company.is_empty then
				l_template.set_variable ("company", l_company)
			end
			
			-- Render template
			c.render (l_template, l_tpl_str)
		end

	handle_slots_demo (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle GET request for Glimmer slots and playground showcase
		local
			c: EWF_GLIMMER_CONTEXT
			l_template: GLM_HTML_TEMPLATE
		do
			create c.make (req, res)
			create l_template.make
			
			-- Enable contract mode by default for playground showcase
			l_template.set_contract_mode (True)

			-- Set template variables
			l_template.set_variable ("app_title", "Glimmer Slot Composition Playground")
			l_template.set_variable ("user_name", "Javier")
			l_template.set_variable ("user_role", "Architect")
			l_template.set_variable ("company", "Eiffel Language Foundation")
			
			-- Render from template file
			c.render_file (l_template, document_root.extended ("slots_demo.html").name)
		end

	handle_slots_playground_render (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle POST request from slots playground to render template with custom component slots
		local
			c: EWF_GLIMMER_CONTEXT
			l_template: GLM_HTML_TEMPLATE
			l_user_name: detachable STRING_32
			l_user_role: detachable STRING_32
			l_company: detachable STRING_32
			l_tpl_str: STRING_32
			l_comp_tpl_str: STRING_32
		do
			create c.make (req, res)
			
			-- Retrieve and sanitize inputs
			l_user_name := c.form_value ("user_name")
			if l_user_name /= Void then
				l_user_name.left_adjust
				l_user_name.right_adjust
			end
			
			l_user_role := c.form_value ("user_role")
			if l_user_role /= Void then
				l_user_role.left_adjust
				l_user_role.right_adjust
			end
			
			l_company := c.form_value ("company")
			if l_company /= Void then
				l_company.left_adjust
				l_company.right_adjust
			end
			
			if attached c.form_value ("playground_template") as tpl then
				l_tpl_str := tpl
			else
				l_tpl_str := ""
			end
			
			if attached c.form_value ("component_template") as comp_tpl then
				l_comp_tpl_str := comp_tpl
			else
				l_comp_tpl_str := ""
			end
			
			create l_template.make
			l_template.set_contract_mode (True)
			
			-- Register the user's component template as a partial
			l_template.register_partial ("card_component", l_comp_tpl_str)
			
			-- Bind variables
			if l_user_name /= Void and then not l_user_name.is_empty then
				l_template.set_variable ("user_name", l_user_name)
			end
			if l_user_role /= Void and then not l_user_role.is_empty then
				l_template.set_variable ("user_role", l_user_role)
			end
			if l_company /= Void and then not l_company.is_empty then
				l_template.set_variable ("company", l_company)
			end
			
			-- Render template
			c.render (l_template, l_tpl_str)
		end

end
