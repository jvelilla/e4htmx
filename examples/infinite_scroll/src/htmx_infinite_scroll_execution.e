note
	description: "Router execution for HTMX Infinite Scroll example"

class
	HTMX_INFINITE_SCROLL_EXECUTION

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
			map_uri_agent ("/pokemon-rows", agent handle_pokemon_rows, router.methods_get)

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

	Rows_per_page: INTEGER = 10
			-- Maximum number of rows per page.

	Pokeapi_base_url: STRING = "https://pokeapi.co"
			-- Base URL for PokeAPI service.

feature -- Events

	handle_version (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle GET request for /version.
		local
			c: EWF_GLIMMER_CONTEXT
		do
			create c.make (req, res)
			c.text ("Eiffel Web Framework: 24.11")
		end

	execute_not_found (uri: READABLE_STRING_8; req: WSF_REQUEST; res: WSF_RESPONSE)
			-- `uri' is not found, redirect to default page.
		local
			c: EWF_GLIMMER_CONTEXT
		do
			create c.make (req, res)
			c.redirect (req.script_url ("/"))
		end

	handle_pokemon_rows (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle GET request for /pokemon-rows.
		local
			c: EWF_GLIMMER_CONTEXT
			l_client: DEFAULT_HTTP_CLIENT
			l_session: HTTP_CLIENT_SESSION
			l_response: detachable HTTP_CLIENT_RESPONSE
			l_parser: JSON_PARSER
			l_converter: JSON_POKEMON_CONVERTER
			l_pokemon_list: ARRAYED_LIST [POKEMON]
			l_page, l_offset, l_limit: INTEGER
			l_template: GLM_HTML_TEMPLATE
			l_html: STRING_32
		do
			create c.make (req, res)

			-- Simulate delay (600ms) to allow shimmer indicator visualization
			{EXECUTION_ENVIRONMENT}.sleep (600_000_000)

			-- Retrieve page parameter
			if attached c.query ("page") as query_val and then query_val.to_string_8.is_integer then
				l_page := query_val.to_string_8.to_integer
			else
				l_page := 1
			end

			l_offset := (l_page - 1) * Rows_per_page
			l_limit := Rows_per_page

			create l_client
			l_client.force_default_client ("curl")
			l_session := l_client.new_session (Pokeapi_base_url)

			l_response := l_session.get ("/api/v2/pokemon-species?offset=" + l_offset.out + "&limit=" + l_limit.out, Void)

			if attached l_response as resp and then not resp.error_occurred and then attached resp.body as body_str then
				create l_parser.make_with_string (body_str)
				l_parser.parse_content
				if l_parser.is_valid and then attached {JSON_OBJECT} l_parser.parsed_json_value as json_obj then
					if attached {JSON_ARRAY} json_obj.item ("results") as results_arr then
						create l_converter
						l_pokemon_list := l_converter.from_json_array (results_arr)

						create l_template.make
						l_template.set_variable ("pokemon_list", l_pokemon_list)
						l_template.set_variable ("page", l_page)
						l_template.set_variable ("next_page", l_page + 1)

						l_html := l_template.render_file (document_root.extended ("pokemon_rows.html").name)

						if l_template.has_error and then attached l_template.last_error as err then
							c.set_status ({HTTP_STATUS_CODE}.internal_server_error)
							c.html ("<div class=%"error%">Template compilation error: " + err.to_string_8 + "</div>")
						else
							c.html (l_html)
						end
					else
						c.set_status ({HTTP_STATUS_CODE}.bad_request)
						c.html ("<div class=%"error%">Missing results in PokeAPI response</div>")
					end
				else
					c.set_status ({HTTP_STATUS_CODE}.bad_request)
					c.html ("<div class=%"error%">Invalid JSON from PokeAPI</div>")
				end
			else
				c.set_status ({HTTP_STATUS_CODE}.bad_request)
				c.html ("<div class=%"error%">Failed to query PokeAPI</div>")
			end
		end

end
