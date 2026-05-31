note
	description: "Helper class representing the HTTP request and response context, inspired by Hono"

class
	EWF_GLIMMER_CONTEXT

inherit
	EWF_GLIMMER_INTEGRATION

create
	make

feature {NONE} -- Initialization

	make (a_req: WSF_REQUEST; a_res: WSF_RESPONSE)
			-- Create context from EWF request and response.
		do
			request := a_req
			response := a_res
			status := {HTTP_STATUS_CODE}.ok
			create headers.make
			htmx := GLM_HTMX_REQUEST (a_req)
		ensure
			request_set: request = a_req
			response_set: response = a_res
			status_set: status = {HTTP_STATUS_CODE}.ok
			htmx_set: htmx /= Void
		end

feature -- Access

	request: WSF_REQUEST
			-- The underlying EWF request.

	response: WSF_RESPONSE
			-- The underlying EWF response.

	headers: HTTP_HEADER
			-- The headers to be sent with the response.

	htmx: GLM_HTMX_REQUEST
			-- The HTMX request wrapper.

	status: INTEGER
			-- The HTTP status code of the response.

feature -- Request Queries

	param (a_name: READABLE_STRING_GENERAL): detachable STRING_32
			-- Path parameter value by `a_name`.
		do
			if attached {WSF_STRING} request.path_parameter (a_name) as l_str then
				Result := l_str.value
			end
		end

	query (a_name: READABLE_STRING_GENERAL): detachable STRING_32
			-- Query parameter value by `a_name`.
		do
			if attached {WSF_STRING} request.query_parameter (a_name) as l_str then
				Result := l_str.value
			end
		end

	form_value (a_name: READABLE_STRING_GENERAL): detachable STRING_32
			-- Form parameter value by `a_name`.
		do
			if attached {WSF_STRING} request.form_parameter (a_name) as l_str then
				Result := l_str.value
			end
		end

	request_body: STRING_8
			-- The raw request body.
		local
			l_body: STRING_8
		do
			if attached request.raw_input_data as l_raw then
				Result := l_raw.to_string_8
			else
				create l_body.make (request.content_length_value.to_integer_32)
				request.read_input_data_into (l_body)
				Result := l_body
			end
		ensure
			result_attached: Result /= Void
		end

feature -- Response Commands

	set_status (a_code: INTEGER)
			-- Set the response status code.
		do
			status := a_code
		ensure
			status_set: status = a_code
		end

	put_header (a_name: READABLE_STRING_GENERAL; a_value: READABLE_STRING_GENERAL)
			-- Put a response header key-value pair.
		do
			headers.put_header_key_value (a_name.to_string_8, a_value.to_string_8)
		end

	set_trigger (a_event: READABLE_STRING_GENERAL)
			-- Set the HX-Trigger header.
		do
			put_header (Hx_trigger, a_event)
		end

	set_target (a_target: READABLE_STRING_GENERAL)
			-- Set the HX-Target header.
		do
			put_header (Hx_target, a_target)
		end

	set_push_url (a_url: READABLE_STRING_GENERAL)
			-- Set the HX-Push-Url header.
		do
			put_header (Hx_push_url, a_url)
		end

	set_replace_url (a_url: READABLE_STRING_GENERAL)
			-- Set the HX-Replace-Url header.
		do
			put_header (Hx_replace_url, a_url)
		end

feature -- Response Rendering

	html (a_html: READABLE_STRING_GENERAL)
			-- Send HTML response.
		do
			headers.put_content_type_text_html
			send (a_html.to_string_8)
		end

	text (a_text: READABLE_STRING_GENERAL)
			-- Send plain text response.
		do
			headers.put_content_type_text_plain
			send (a_text.to_string_8)
		end

	json (a_json: READABLE_STRING_GENERAL)
			-- Send JSON response.
		do
			headers.put_content_type (Content_type_json)
			send (a_json.to_string_8)
		end

	empty
			-- Send empty response.
		do
			send ("")
		end

	redirect (a_url: READABLE_STRING_8)
			-- Redirect response to `a_url`.
		do
			response.redirect_now (a_url)
		end

	body (a_body: READABLE_STRING_8)
			-- Send raw response with `a_body`.
		do
			send (a_body)
		end

	not_found
			-- Send a 404 Not Found response.
		do
			set_status ({HTTP_STATUS_CODE}.not_found)
			text (Not_found_message)
		end

	render (a_template: GLM_HTML_TEMPLATE; a_template_text: READABLE_STRING_GENERAL)
			-- Render `a_template_text` using `a_template`, apply HTMX headers, and send HTML response.
		local
			l_html: STRING_32
		do
			l_html := a_template.render (a_template_text)
			apply_htmx_headers (a_template, headers)
			if a_template.has_contract_violation and then attached a_template.last_contract_violation as l_violation then
				set_status ({HTTP_STATUS_CODE}.unprocessable_entity)
				headers.put_header_key_value ("HX-Trigger", "{\%"glimmer:contract-violation\%": \%"" + l_violation.to_string_8 + "%"}")
				html (Error_div_start + "Contract violation: " + l_violation.to_string_8 + Error_div_end)
			elseif a_template.has_error and then attached a_template.last_error as l_err then
				set_status ({HTTP_STATUS_CODE}.internal_server_error)
				html (Error_div_start + l_err.to_string_8 + Error_div_end)
			else
				html (l_html)
			end
		end

	render_file (a_template: GLM_HTML_TEMPLATE; a_file_path: READABLE_STRING_GENERAL)
			-- Render template from `a_file_path` using `a_template`, apply HTMX headers, and send HTML response.
		local
			l_html: STRING_32
		do
			l_html := a_template.render_file (a_file_path)
			apply_htmx_headers (a_template, headers)
			if a_template.has_contract_violation and then attached a_template.last_contract_violation as l_violation then
				set_status ({HTTP_STATUS_CODE}.unprocessable_entity)
				headers.put_header_key_value ("HX-Trigger", "{\%"glimmer:contract-violation\%": \%"" + l_violation.to_string_8 + "%"}")
				html (Error_div_start + "Contract violation: " + l_violation.to_string_8 + Error_div_end)
			elseif a_template.has_error and then attached a_template.last_error as l_err then
				set_status ({HTTP_STATUS_CODE}.internal_server_error)
				html (Error_div_start + l_err.to_string_8 + Error_div_end)
			else
				html (l_html)
			end
		end

feature -- Request Method Helpers

	is_get: BOOLEAN
			-- Is GET request?
		do
			Result := request.is_get_request_method
		end

	is_post: BOOLEAN
			-- Is POST request?
		do
			Result := request.is_post_request_method
		end

	is_put: BOOLEAN
			-- Is PUT request?
		do
			Result := request.is_put_request_method
		end

	is_delete: BOOLEAN
			-- Is DELETE request?
		do
			Result := request.is_delete_request_method
		end

	is_patch: BOOLEAN
			-- Is PATCH request?
		do
			Result := request.request_method.same_string (Method_patch)
		end

feature {NONE} -- Constants

	Hx_trigger: STRING = "HX-Trigger"
	Hx_target: STRING = "HX-Target"
	Hx_push_url: STRING = "HX-Push-Url"
	Hx_replace_url: STRING = "HX-Replace-Url"
	Content_type_json: STRING = "application/json"
	Method_patch: STRING = "PATCH"
	Error_div_start: STRING = "<div class=%"error%">"
	Error_div_end: STRING = "</div>"
	Not_found_message: STRING = "Not Found"

feature {NONE} -- Internal Helpers

	send (a_body: READABLE_STRING_8)
			-- Send response headers and `a_body`.
		do
			headers.put_content_length (a_body.count)
			headers.put_current_date
			response.set_status_code (status)
			response.put_header_text (headers.string)
			response.put_string (a_body)
		end

end
