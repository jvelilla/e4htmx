note
	description: "Integration helper class for EWF and Glimmer"

class
	EWF_GLIMMER_INTEGRATION

feature -- HTMX Request Helper

	GLM_HTMX_REQUEST (req: WSF_REQUEST): GLM_HTMX_REQUEST
			-- Create an GLM_HTMX_REQUEST from an EWF request
		local
			l_headers: STRING_TABLE [READABLE_STRING_GENERAL]
		do
			create l_headers.make (8)
			if attached meta_string (req, "HTTP_HX_REQUEST") as v then l_headers.put (v, "hx-request") end
			if attached meta_string (req, "HTTP_HX_TARGET") as v then l_headers.put (v, "hx-target") end
			if attached meta_string (req, "HTTP_HX_TRIGGER") as v then l_headers.put (v, "hx-trigger") end
			if attached meta_string (req, "HTTP_HX_TRIGGER_NAME") as v then l_headers.put (v, "hx-trigger-name") end
			if attached meta_string (req, "HTTP_HX_CURRENT_URL") as v then l_headers.put (v, "hx-current-url") end
			if attached meta_string (req, "HTTP_HX_PROMPT") as v then l_headers.put (v, "hx-prompt") end
			if attached meta_string (req, "HTTP_HX_BOOSTED") as v then l_headers.put (v, "hx-boosted") end
			if attached meta_string (req, "HTTP_HX_HISTORY_RESTORE_REQUEST") as v then l_headers.put (v, "hx-history-restore-request") end
			create Result.make (l_headers)
		ensure
			result_attached: Result /= Void
		end

feature -- HTMX Response Helper

	apply_htmx_headers (a_template: GLM_HTML_TEMPLATE; h: HTTP_HEADER)
			-- Apply registered HTMX triggers, push-url, and replace-url headers from `a_template` to EWF header `h`.
		do
			if not a_template.trigger_events.is_empty then
				h.put_header_key_value ("HX-Trigger", a_template.htmx_trigger_header.to_string_8)
			end
			if attached a_template.push_url as url then
				h.put_header_key_value ("HX-Push-Url", url.to_string_8)
			end
			if attached a_template.replace_url as url then
				h.put_header_key_value ("HX-Replace-Url", url.to_string_8)
			end
		end

feature {NONE} -- Internal Helpers

	meta_string (req: WSF_REQUEST; a_name: READABLE_STRING_8): detachable READABLE_STRING_32
			-- Get meta string variable by `a_name` case-insensitively from `req`.
		do
			if attached req.meta_string_variable (a_name.as_upper) as l_upper_val then
				Result := l_upper_val
			elseif attached req.meta_string_variable (a_name.as_lower) as l_lower_val then
				Result := l_lower_val
			elseif attached req.meta_string_variable (a_name) as l_orig_val then
				Result := l_orig_val
			end
		end

end
