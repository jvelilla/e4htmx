note
    description: "[
                application execution
            ]"
    date: "$Date$"
    revision: "$Revision$"
class
    HTMX_CUSTOM_DIALOGS_EXECUTION
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
            
            map_uri_agent ("/images", agent handle_images, router.methods_get)
            
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

    handle_images (req: WSF_REQUEST; res: WSF_RESPONSE)
        local
            c: EWF_GLIMMER_CONTEXT
            env: EXECUTION_ENVIRONMENT
        do
            create c.make (req, res)
            create env
            env.sleep (1000000000) -- Sleep 1 second to simulate long running request
            
            c.text ("[
                <img alt="book cover" class="cover" src="https://htmx.org/img/htmx-logo.svg" style="max-width: 100px;" />
            ]")
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
