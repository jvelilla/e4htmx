note
    description: "[
                application execution
            ]"
    date: "$Date$"
    revision: "$Revision$"
class
    HTMX_BOOSTING_EXECUTION
inherit
    WSF_FILTERED_ROUTED_EXECUTION
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
end
