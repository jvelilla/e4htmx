note
	description: "Router execution for active search example"

class
	HTMX_ACTIVE_SEARCH_EXECUTION

inherit
	WSF_FILTERED_ROUTED_EXECUTION
	WSF_ROUTED_URI_HELPER
	SHARED_EXECUTION_ENVIRONMENT
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
			map_uri_agent ("/search", agent handle_search, router.methods_get)

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

	handle_search (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Handle GET /search?search=...
		local
			c: EWF_GLIMMER_CONTEXT
			l_query: STRING
			l_db: USER_DATABASE
			l_users: ARRAYED_LIST [USER]
			l_template: GLM_HTML_TEMPLATE
		do
			create c.make (req, res)

			-- Simulate active search delay (300ms) to show search indicator
			{EXECUTION_ENVIRONMENT}.sleep (300_000_000)

			-- Extract search query parameter
			if attached c.query ("search") as query_val then
				l_query := query_val.to_string_8
			else
				create l_query.make_empty
			end

			-- Perform search
			create l_db.make
			l_users := l_db.search (l_query)

			-- Render template using Glimmer
			create l_template.make
			l_template.set_variable ("users", l_users)
			l_template.set_variable ("query", l_query)
			c.render_file (l_template, document_root.appended ("\search_results.html").name)
		end

end
