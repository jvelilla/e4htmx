note
	description: "Router execution for HTMX Optimistic Updates example"

class
	HTMX_OPTIMISTIC_UPDATES_EXECUTION

inherit
	WSF_FILTERED_ROUTED_EXECUTION
	WSF_ROUTED_URI_HELPER
	WSF_ROUTED_URI_TEMPLATE_HELPER
	SHARED_EXECUTION_ENVIRONMENT
	SHARED_DOGS_STATE
	EWF_GLIMMER_INTEGRATION

create
	make

feature -- Filter

	create_filter
		do
			create {WSF_MAINTENANCE_FILTER} filter
		end

	setup_filter
		local
			f: like filter
		do
			create {WSF_CORS_FILTER} f
			f.set_next (create {WSF_LOGGING_FILTER})
			filter.append (f)
		end

feature -- Router

	setup_router
		local
			www: WSF_FILE_SYSTEM_HANDLER
		do
			router.handle ("/doc", create {WSF_ROUTER_SELF_DOCUMENTATION_HANDLER}.make (router), router.methods_GET)
			map_uri_agent ("/version", agent handle_version, router.methods_get)
			map_uri_agent ("/table-rows", agent handle_table_rows, router.methods_get)
			map_uri_template_agent ("/dog/{breed}", agent handle_toggle_like, router.methods_PUT)

			create www.make_with_path (document_root)
			www.set_directory_index (<<"index.html">>)
			www.set_not_found_handler (agent execute_not_found)
			router.handle ("", www, router.methods_GET)
		end

feature -- Configuration

	document_root: PATH
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

	handle_table_rows (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle GET /table-rows request
		local
			c: EWF_GLIMMER_CONTEXT
			l_dogs_list: LIST [DOG_BREED]
			l_template: GLM_HTML_TEMPLATE
			l_html: STRING_32
		do
			create c.make (req, res)

			-- We retrieve all dog breeds from the SQLite database
			l_dogs_list := dogs_mgr.retrieve_all

			-- Render template using Glimmer
			create l_template.make
			l_template.set_variable ("dogs", l_dogs_list)
			
			l_html := l_template.render_file (document_root.extended ("table_rows.html").name)
			
			if l_template.has_error and then attached l_template.last_error as err then
				c.set_status ({HTTP_STATUS_CODE}.internal_server_error)
				c.html ("<div class=%"error%">" + err.to_string_8 + "</div>")
			else
				c.html (l_html)
			end
		end

	handle_toggle_like (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle PUT /dog/{breed}
		local
			c: EWF_GLIMMER_CONTEXT
			l_breed_name: STRING_32
			l_breed: detachable DOG_BREED
		do
			create c.make (req, res)

			-- Simulate server delay of 1 second (1000ms) to show optimistic updates
			{EXECUTION_ENVIRONMENT}.sleep (1_000_000_000) -- 1000ms in nanoseconds

			if attached c.param ("breed") as p_breed then
				l_breed_name := p_breed.to_string_32
				
				l_breed := dogs_mgr.toggle_like (l_breed_name)
				if attached l_breed as b then
					-- Return new heart representation as HTML
					c.html (b.heart_html)
				else
					c.set_status ({HTTP_STATUS_CODE}.not_found)
					c.text ("Breed not found")
				end
			else
				c.set_status ({HTTP_STATUS_CODE}.bad_request)
				c.text ("Missing breed parameter")
			end
		end

end
