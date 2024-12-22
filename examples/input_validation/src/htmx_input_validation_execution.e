note
    description: "[
                application execution
            ]"
    date: "$Date$"
    revision: "$Revision$"

class
    HTMX_INPUT_VALIDATION_EXECUTION
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
            map_uri_agent ("/email-validate", agent handle_email_validation, router.methods_get)
            map_uri_agent ("/password-validate", agent handle_password_validation, router.methods_get)
            map_uri_agent ("/form", agent handle_form, router.methods_get)
            map_uri_agent ("/account", agent handle_account_creation, router.methods_post)
            create www.make_with_path (document_root)
            www.set_directory_index (<<"index.html">>)
            www.set_not_found_handler (agent execute_not_found)
            router.handle ("", www, router.methods_GET)
            router.handle ("/", www, router.methods_GET)
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

    handle_email_validation (req: WSF_REQUEST; res: WSF_RESPONSE)
            -- Handle email validation request
        local
            l_email: STRING
            l_valid: BOOLEAN
        do
            if attached {WSF_STRING}req.query_parameter ("email") as email then
                l_email := email.value.to_string_8
                l_valid := is_valid_email (l_email)
                if l_valid then
                    new_response_get (req, res, "")
                else
                    new_response_get (req, res, "email in use")
                end
            else
                new_response_get (req, res, "email parameter required")
            end
        end

    is_valid_email (email: STRING): BOOLEAN
            -- Check if email is valid and not in use
            -- TODO: Implement your email validation logic here
        do
            Result := not {SHARED_CONSTANTS}.existing_emails.has (email)
        end

    is_valid_password (password: detachable STRING): BOOLEAN
            -- Check if password is valid:
            -- - Must be at least 8 characters
            -- - Must not be in list of common passwords
            -- Note: Empty/void password is considered valid (for optional password fields)
        local
            l_constants: SHARED_CONSTANTS
        do
            if password = Void or else password.is_empty then
                Result := True
            else
                create l_constants
                Result := password.count >= 8 and then
                          not l_constants.bad_passwords.has (password)
            end
        end

    handle_password_validation (req: WSF_REQUEST; res: WSF_RESPONSE)
            -- Handle password validation request
        local
            l_password: STRING
        do
            if attached {WSF_STRING}req.query_parameter ("password") as password then
                l_password := password.value.to_string_8
                if is_valid_password (l_password) then
                    new_response_get (req, res, "")
                else
                    new_response_get (req, res, "invalid password")
                end
            else
                new_response_get (req, res, "")  -- Empty password is considered valid
            end
        end

    handle_form (req: WSF_REQUEST; res: WSF_RESPONSE)
            -- Handle form request
        local
            l_template: HTML_TEMPLATE
            l_result: STRING
        do
            create l_template.make

            	-- Set up the form template with HTMX attributes
            l_result := l_template.render (
                "[
                    <form hx-post="/account" hx-target="#result" hx-on:htmx:after-request: "if (event.detail.pathInfo.requestPath === '/account' && event.detail.successful) this.reset()">
                        <div>
                            <label for="email">Email</label>
                            <input
                                id="email"
                                hx-get="/email-validate"
                                hx-sync="closest form:abort"
                                hx-target="#email-error"
                                hx-trigger="keyup changed delay:200ms"
                                name="email"
                                placeholder="email"
                                required
                                size="30"
                                type="email"
                            />
                            <span class="error" id="email-error"></span>
                        </div>
                        <div>
                            <label for="password">Password</label>
                            <input
                                id="password"
                                hx-get="/password-validate"
                                hx-target="#password-error"
                                hx-trigger="blur"
                                minlength="8"
                                name="password"
                                placeholder="password"
                                required
                                size="20"
                                type="password"
                            />
                            <span class="error" id="password-error"></span>
                        </div>
                        <button>Submit</button>
                    </form>
                ]"
            )

            new_response_get (req, res, l_result)
        end

    handle_account_creation (req: WSF_REQUEST; res: WSF_RESPONSE)
            -- Handle account creation POST request
        local
            l_email, l_password, l_response: STRING
            l_valid_email, l_valid_password: BOOLEAN
        do
            if attached {WSF_STRING} req.form_parameter ("email") as email then
                l_email := email.value.to_string_8
            else
                create l_email.make_empty
            end

            if attached {WSF_STRING} req.form_parameter ("password") as password then
                l_password := password.value.to_string_8
            else
                create l_password.make_empty
            end

            l_valid_email := is_valid_email (l_email)
            l_valid_password := is_valid_password (l_password)

            create l_response.make_empty

            if not l_valid_email then
                l_response.append ("<span class=%"error%" hx-swap-oob=%"true%" id=%"email-error%">email in use</span>")
            end

            if not l_valid_password then
                l_response.append ("<span class=%"error%" hx-swap-oob=%"true%" id=%"password-error%">invalid password</span>")
            end

            if l_valid_email and l_valid_password then
                res.set_status_code ({HTTP_STATUS_CODE}.ok)
                l_response.append ("<span>A new account was created.</span>")
            else
                res.set_status_code ({HTTP_STATUS_CODE}.bad_request)
            end

            new_response_get (req, res, l_response)
        end

end
