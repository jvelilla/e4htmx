note
    description: "[
                application execution
            ]"
    date: "$Date$"
    revision: "$Revision$"
class
    HTMX_POLLING_EXECUTION
inherit
    WSF_FILTERED_ROUTED_EXECUTION
    WSF_ROUTED_URI_HELPER
    SHARED_EXECUTION_ENVIRONMENT
    EWF_GLIMMER_INTEGRATION
    SHARED_STATE_POLLING
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

            map_uri_agent ("/score", agent handle_score, router.methods_get)
            map_uri_agent ("/progress-bar", agent handle_progress_bar, router.methods_get)
            map_uri_agent ("/progress", agent handle_progress, router.methods_get)

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

feature -- Helpers

    get_points: INTEGER
        local
            dt: DATE_TIME
            number: INTEGER
            touchdown: INTEGER
            field_goal: INTEGER
        do
            create dt.make_now
            number := dt.time.milli_second \\ 10
            touchdown := 7
            field_goal := 3
            if number >= 8 then
                Result := touchdown
            elseif number >= 5 then
                Result := field_goal
            else
                Result := 0
            end
        end

feature -- Events

    handle_score (req: WSF_REQUEST; res: WSF_RESPONSE)
        local
            c: EWF_GLIMMER_CONTEXT
        do
            create c.make (req, res)
            load_state
            
            if team1_has_ball then
                set_score1 (score1 + get_points)
            else
                set_score2 (score2 + get_points)
            end
            set_team1_has_ball (not team1_has_ball)
            
            print ("Current Scores -> " + team1 + ": " + score1.out + ", " + team2 + ": " + score2.out + "%N")
            
            if score1 > 30 or score2 > 30 then
                c.set_status (286) -- Stop polling
            else
                c.set_status (200)
            end
            c.html (team1 + ": " + score1.out + ", " + team2 + ": " + score2.out)
            
            save_state
        end

    handle_progress_bar (req: WSF_REQUEST; res: WSF_RESPONSE)
        local
            c: EWF_GLIMMER_CONTEXT
            tpl: GLM_HTML_TEMPLATE
        do
            create c.make (req, res)
            create tpl.make
            load_state
            c.set ("percentComplete", percent_complete.rounded.out)
            c.set ("isIncomplete", percent_complete < 100.0)
            c.render_file (tpl, document_root.extended ("progress.html").name)
        end

    handle_progress (req: WSF_REQUEST; res: WSF_RESPONSE)
        local
            c: EWF_GLIMMER_CONTEXT
            dt: DATE_TIME
            delta: REAL_64
            tpl: GLM_HTML_TEMPLATE
        do
            create c.make (req, res)
            load_state
            
            if attached c.htmx.hx_trigger as trigger and then trigger.same_string ("reset-btn") then
                set_percent_complete (0.0)
            else
                create dt.make_now
                delta := (dt.time.milli_second \\ 10 + 1) * 3.0
                set_percent_complete (percent_complete + delta)
                if percent_complete > 100.0 then
                    set_percent_complete (100.0)
                end
            end
            
            save_state
            
            create tpl.make
            c.set ("percentComplete", percent_complete.rounded.out)
            c.set ("isIncomplete", percent_complete < 100.0)
            c.render_file (tpl, document_root.extended ("progress.html").name)
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
