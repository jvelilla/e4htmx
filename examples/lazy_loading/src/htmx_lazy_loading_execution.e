note
	description: "[
			application execution
		]"
	date: "$Date$"
	revision: "$Revision$"

class
	HTMX_LAZY_LOADING_EXECUTION

inherit

	WSF_FILTERED_ROUTED_EXECUTION

	WSF_ROUTED_URI_TEMPLATE_HELPER

	WSF_ROUTED_URI_HELPER

	SHARED_EXECUTION_ENVIRONMENT

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
		end

feature -- Router

	setup_router
			-- Setup `router'
		local
			www: WSF_FILE_SYSTEM_HANDLER
		do
			router.handle ("/doc", create {WSF_ROUTER_SELF_DOCUMENTATION_HANDLER}.make (router), router.methods_GET)
			map_uri_agent ("/version", agent handle_version, router.methods_get)
			map_uri_agent ("/users", agent handle_users, router.methods_get)

			create www.make_with_path (document_root)
			www.set_directory_index (<<"index.html">>)
			www.set_not_found_handler (agent execute_not_found)
			router.handle ("", www, router.methods_GET)

		end
feature -- Configuration

	document_root: PATH
			-- Document root to look for files or directories
		once
			Result := execution_environment.current_working_path.extended ("www")
		end

feature -- Constants

	One_second_ns: INTEGER_64 = 1_000_000_000
			-- One second in nanoseconds.

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

	handle_users (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle GET request for /users
		local
			c: EWF_GLIMMER_CONTEXT
			l_parser: JSON_PARSER
			l_converter: JSON_USER_CONVERTER
			l_users: ARRAYED_LIST [USER]
			l_file: PLAIN_TEXT_FILE
			l_template: GLM_HTML_TEMPLATE
		do
			create c.make (req, res)

				-- Simulate delay (1 second)
			{EXECUTION_ENVIRONMENT}.sleep (One_second_ns)

				-- Create file handle
			create l_file.make_with_path (document_root.appended ("\users.json"))

			if l_file.exists and then l_file.is_readable then
				l_file.open_read

					-- Parse JSON and convert to users
				create l_parser.make_with_string (file_content (l_file))
				l_parser.parse_content
				l_file.close

					-- Convert JSON to user objects and render template
				if l_parser.is_valid and then attached {JSON_ARRAY} l_parser.parsed_json_array as json_array then
					create l_converter
					l_users := l_converter.from_json_array (json_array)

					create l_template.make
					l_template.set_variable ("users", l_users)
					c.render_file (l_template, document_root.appended ("\users_table.html").name)
				else
					c.set_status ({HTTP_STATUS_CODE}.bad_request)
					c.html ("<div class=%"error%">Invalid users data</div>")
				end
			else
				c.not_found
			end
		end

feature {NONE} -- Implementation

	file_content (a_file: PLAIN_TEXT_FILE): STRING
			-- Read entire file content
		require
			file_open: a_file.is_open_read
		do
			create Result.make (a_file.count)
			from
				a_file.start
			until
				a_file.off
			loop
				a_file.read_stream (a_file.count)
				Result.append (a_file.last_string)
			end
		end

end
