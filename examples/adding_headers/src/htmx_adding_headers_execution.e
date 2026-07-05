note
    description: "[
                application execution
            ]"
    date: "$Date$"
    revision: "$Revision$"
class
    HTMX_ADDING_HEADERS_EXECUTION
inherit
    WSF_FILTERED_ROUTED_EXECUTION
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
            
            map_uri_agent ("/request1", agent handle_request1, router.methods_get)
            map_uri_agent ("/request2", agent handle_request2, router.methods_post)
            
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

    handle_request1 (req: WSF_REQUEST; res: WSF_RESPONSE)
        local
            c: EWF_GLIMMER_CONTEXT
        do
            create c.make (req, res)
            if attached req.meta_string_variable ("HTTP_X_TOKEN") as token then
                c.text ("/request1 received the token %"" + token + "%".")
            else
                c.text ("/request1 did not receive a token.")
            end
        end

    handle_request2 (req: WSF_REQUEST; res: WSF_RESPONSE)
        local
            c: EWF_GLIMMER_CONTEXT
        do
            create c.make (req, res)
            if attached req.meta_string_variable ("HTTP_X_TOKEN") as token then
                c.text ("/request2 received the token %"" + token + "%".")
            else
                c.text ("/request2 did not receive a token.")
            end
        end

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
end
