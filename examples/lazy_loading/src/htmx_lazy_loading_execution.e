note
	description: "[
			application execution
		]"
	date: "$Date$"
	revision: "$Revision$"

class
	htmx_lazy_loading_EXECUTION

inherit

	WSF_FILTERED_ROUTED_EXECUTION

	WSF_ROUTED_URI_TEMPLATE_HELPER

	WSF_ROUTED_URI_HELPER

	SHARED_EXECUTION_ENVIRONMENT

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

	handle_users (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle GET request for /users
		local
			l_html: STRING
			l_parser: JSON_PARSER
			l_converter: JSON_USER_CONVERTER
			l_users: ARRAYED_LIST [USER]
			l_file: PLAIN_TEXT_FILE
		do
				-- Simulate delay (1 second)
			{EXECUTION_ENVIRONMENT}.sleep (1_000_000_000)

				-- Create file handle
			create l_file.make_with_path (document_root.appended ("\users.json"))

			if l_file.exists and then l_file.is_readable then
				l_file.open_read

					-- Parse JSON and convert to users
				create l_parser.make_with_string (file_content (l_file))
				l_parser.parse_content
				l_file.close

					-- Generate HTML table
				create l_html.make_from_string ("[
							<table>
							    <thead>
							        <tr>
							            <th>ID</th>
							            <th>Name</th>
							            <th>Email</th>
							            <th>Company</th>
							        </tr>
							    </thead>
							    <tbody>
						]")

					-- Convert JSON to user objects and generate table rows
				if l_parser.is_valid and then attached {JSON_ARRAY} l_parser.parsed_json_array as json_array then
					create l_converter
					l_users := l_converter.from_json_array (json_array)

					across l_users as user loop
						l_html.append ("<tr>")
						l_html.append ("<td>" + user.item.id.out + "</td>")
						l_html.append ("<td>" + user.item.name + "</td>")
						l_html.append ("<td>" + user.item.email + "</td>")
						l_html.append ("<td>" + user.item.company.name + "</td>")
						l_html.append ("</tr>%N")
					end
				end

				l_html.append ("</tbody></table>")

					-- Send response
				new_response_get (req, res, l_html)
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
