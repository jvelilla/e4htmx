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
            map_uri_agent ("/email-validate", agent handle_email_validation, router.methods_get)
            map_uri_agent ("/password-validate", agent handle_password_validation, router.methods_get)
            map_uri_agent ("/form", agent handle_form, router.methods_get)
            map_uri_agent ("/account", agent handle_account_creation, router.methods_post)
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

    handle_email_validation (req: WSF_REQUEST; res: WSF_RESPONSE)
            -- Handle email validation request
        local
            c: EWF_GLIMMER_CONTEXT
            l_email: STRING
        do
            create c.make (req, res)
            if attached c.query ("email") as email then
                l_email := email.to_string_8
                if is_valid_email (l_email) then
                    c.empty
                else
                    c.html ("email in use")
                end
            else
                c.html ("email parameter required")
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
            c: EWF_GLIMMER_CONTEXT
            l_password: STRING
        do
            create c.make (req, res)
            if attached c.query ("password") as password then
                l_password := password.to_string_8
                if is_valid_password (l_password) then
                    c.empty
                else
                    c.html ("invalid password")
                end
            else
                c.empty  -- Empty password is considered valid
            end
        end

    handle_form (req: WSF_REQUEST; res: WSF_RESPONSE)
            -- Handle form request
        local
            c: EWF_GLIMMER_CONTEXT
            l_template: GLM_HTML_TEMPLATE
        do
            create c.make (req, res)
            create l_template.make

            	-- Set up the form template with HTMX attributes
            c.render (l_template,
                "[
                    <form hx-post="/account" hx-target="#result" hx-on:htmx:after-request="if (event.detail.pathInfo.requestPath === '/account' && event.detail.successful) this.reset()" class="auth-form">
                        <div class="form-group">
                            <label for="email">Email Address</label>
                            <div class="input-wrapper">
                                <input
                                    id="email"
                                    hx-get="/email-validate"
                                    hx-sync="closest form:abort"
                                    hx-target="#email-error"
                                    hx-trigger="keyup changed delay:200ms"
                                    name="email"
                                    placeholder="you@example.com"
                                    required
                                    type="email"
                                />
                                <span class="error-message" id="email-error"></span>
                            </div>
                        </div>
                        <div class="form-group">
                            <label for="password">Password</label>
                            <div class="input-wrapper">
                                <div style="position: relative; width: 100%;">
                                    <input
                                        id="password"
                                        hx-get="/password-validate"
                                        hx-target="#password-error"
                                        hx-trigger="blur"
                                        minlength="8"
                                        name="password"
                                        placeholder="At least 8 characters"
                                        required
                                        type="password"
                                        style="padding-right: 2.75rem;"
                                    />
                                    <button type="button" class="toggle-password" onclick="const p = document.getElementById('password'); p.type = p.type === 'password' ? 'text' : 'password'; this.querySelector('svg').style.opacity = p.type === 'password' ? '0.5' : '1';">
                                        <svg class="eye-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="opacity: 0.5; transition: opacity 0.2s ease;">
                                            <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
                                            <circle cx="12" cy="12" r="3"/>
                                        </svg>
                                    </button>
                                </div>
                                <span class="error-message" id="password-error"></span>
                            </div>
                        </div>
                        <button type="submit" class="submit-btn">
                            <span>Create Account</span>
                            <svg class="arrow-icon" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M5 12h14M12 5l7 7-7 7"/></svg>
                        </button>
                    </form>
                ]"
            )
        end

    handle_account_creation (req: WSF_REQUEST; res: WSF_RESPONSE)
            -- Handle account creation POST request
        local
            c: EWF_GLIMMER_CONTEXT
            l_email, l_password, l_response: STRING
            l_valid_email, l_valid_password: BOOLEAN
        do
            create c.make (req, res)
            if attached c.form_value ("email") as email then
                l_email := email.to_string_8
            else
                create l_email.make_empty
            end

            if attached c.form_value ("password") as password then
                l_password := password.to_string_8
            else
                create l_password.make_empty
            end

            l_valid_email := is_valid_email (l_email)
            l_valid_password := is_valid_password (l_password)

            create l_response.make_empty

            if not l_valid_email then
                l_response.append ("<span class=%"error-message%" hx-swap-oob=%"true%" id=%"email-error%">email in use</span>")
            end

            if not l_valid_password then
                l_response.append ("<span class=%"error-message%" hx-swap-oob=%"true%" id=%"password-error%">invalid password</span>")
            end

            if l_valid_email and l_valid_password then
                c.set_status ({HTTP_STATUS_CODE}.ok)
                l_response.append ("<span>A new account was created.</span>")
            else
                c.set_status ({HTTP_STATUS_CODE}.bad_request)
            end

            c.html (l_response)
        end

end
