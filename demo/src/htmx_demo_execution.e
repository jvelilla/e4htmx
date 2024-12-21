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
			l_result: STRING_8
		do
			l_result := "Eiffel Web Framework: 24.11"
			res.set_status_code ({HTTP_STATUS_CODE}.ok)
			new_response (req, res, l_result)
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
			l_dogs: ARRAYED_LIST [DOG]
			l_html: STRING
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

				-- Generate HTML for all dogs
			create l_html.make_empty
			across l_dogs as dog loop
				l_html.append (dog_row (dog.item))
			end

			res.set_status_code ({HTTP_STATUS_CODE}.ok)
			new_response (req, res, l_html)
		end

	handle_add_dog_post (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle POST request to add a new dog and return its row HTML
		local
			l_dog: DOG
			l_html: STRING
		do
			if
				attached {WSF_STRING} req.form_parameter ("name") as l_name and then
				attached {WSF_STRING} req.form_parameter ("breed") as l_breed
			then
				-- Add dog to database
				l_dog := add_dog (l_name.value, l_breed.value)

				-- Generate HTML row for the new dog
				l_html := dog_row (l_dog)

				-- Send response with 201 Created status
				res.set_status_code ({HTTP_STATUS_CODE}.created)
				new_response (req, res, l_html)
			else
				-- Updated error handling
				res.set_status_code ({HTTP_STATUS_CODE}.bad_request)
				res.put_string ("Missing required parameters")
			end
		end

	handle_delete_dog (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle DELETE request to remove a dog
		local
			l_id: STRING
		do
			if attached {WSF_STRING} req.path_parameter ("id") as p_id then
				l_id := p_id.value

				if shared_dogs.has (l_id) then
					-- Remove dog from database
					shared_dogs.remove (l_id)

					-- Send empty response with 204 No Content status
					res.set_status_code ({HTTP_STATUS_CODE}.ok)
					new_response (req, res, "")
				else
					-- Updated error handling
					res.set_status_code ({HTTP_STATUS_CODE}.not_found)
					res.put_string ("Dog not found")
				end
			else
				-- Updated error handling
				res.set_status_code ({HTTP_STATUS_CODE}.bad_request)
				res.put_string ("Missing dog ID")
			end
		end

	handle_oob (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle request for the out-of-band demo page
		local
			l_html: STRING
		do
			l_html := oob_page

			res.set_status_code ({HTTP_STATUS_CODE}.ok)
			new_response (req, res, l_html)
		end

	handle_oob_demo (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle request for the out-of-band demo response
		local
			l_html: STRING
			l_esx: ESX
			l_variables: STRING_TABLE [ANY]
		do
			create l_esx
			create l_variables.make (0)
			l_html := l_esx.esx ("[
				<div>new 1</div>
				<div id="target2" hx-swap-oob="true">
					new 2
				</div>
				<div id="target2" hx-swap-oob="afterend">
					<div>after 2</div>
				</div>
				<div hx-swap-oob="innerHTML:#target3">new 3</div>
			]", l_variables)

			res.set_status_code ({HTTP_STATUS_CODE}.ok)
			new_response (req, res, l_html)
		end

	handle_event_with_no_data (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle request that triggers event1 with no data
		local
			h: HTTP_HEADER
		do
			create h.make
			h.put_content_type_text_plain
			h.put_header_key_value ("HX-Trigger", "event1")
			h.put_content_length (17)
			h.put_current_date

			res.set_status_code ({HTTP_STATUS_CODE}.ok)
			res.put_header_text (h.string)
			res.put_string ("dispatched event1")
		end

	handle_event_with_string (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle request that triggers event2 with string data
		local
			h: HTTP_HEADER
			l_trigger: STRING
		do
				-- Create JSON string for the trigger
			l_trigger := "{%"event2%":%"some string%"}"

			create h.make
			h.put_content_type_text_plain
			h.put_header_key_value ("HX-Trigger", l_trigger)
			h.put_content_length (17)
			h.put_current_date

			res.set_status_code ({HTTP_STATUS_CODE}.ok)
			res.put_header_text (h.string)
			res.put_string ("dispatched event2")
		end

	handle_event_with_object (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle request that triggers event3 with object data
		local
			h: HTTP_HEADER
			l_trigger: STRING
		do
				-- Create JSON string for the trigger with nested object
			l_trigger := "{%"event3%":{%"foo%":1,%"bar%":2}}"

			create h.make
			h.put_content_type_text_plain
			h.put_header_key_value ("HX-Trigger", l_trigger)
			h.put_content_length (17)
			h.put_current_date

			res.set_status_code ({HTTP_STATUS_CODE}.ok)
			res.put_header_text (h.string)
			res.put_string ("dispatched event3")
		end

	handle_trigger (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle request for the event triggering demo page
		local
			l_html: STRING
			l_esx: ESX
			l_variables: STRING_TABLE [ANY]
		do
			create l_esx
			create l_variables.make (0)
			l_html := l_esx.esx ("[
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
			]", l_variables)

			res.set_status_code ({HTTP_STATUS_CODE}.ok)
			new_response (req, res, l_html)
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
			l_esx: ESX
			l_variables: STRING_TABLE [ANY]
		do
			create l_esx
			create l_variables.make (2)
			l_variables.put (a_dog.name, "name")
			l_variables.put (a_dog.breed, "breed")
			l_variables.put (a_dog.id, "id")

			Result := l_esx.esx ("[
				<tr class="on-hover">
					<td>{name}</td>
					<td>{breed}</td>
					<td class="buttons">
						<button
							class="show-on-hover"
							hx-delete="/dog/{id}"
							hx-confirm="Are you sure?"
							hx-target="closest tr"
							hx-swap="delete"
						>X</button>
					</td>
				</tr>
			]", l_variables)
		ensure
			result_not_empty: not Result.is_empty
			contains_dog_info: Result.has_substring (a_dog.name) and Result.has_substring (a_dog.breed)
		end

	oob_page: STRING
		local
			l_esx: ESX
					l_variables: STRING_TABLE [ANY]
		do
			create l_esx
			create l_variables.make (0)
			Result := l_esx.esx("[
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
			]", l_variables)
		end

end
