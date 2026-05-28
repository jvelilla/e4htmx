note
	description: "Helper to introspect HTMX-specific request headers"

class
	GLM_HTMX_REQUEST

create
	make

feature {NONE} -- Initialization

	make (a_headers: STRING_TABLE [READABLE_STRING_GENERAL])
			-- Initialize with HTTP headers and normalize keys to lowercase.
		local
			l_key: STRING_32
		do
			create headers.make (a_headers.count)
			headers.compare_objects
			across a_headers as h loop
				create l_key.make_from_string (h.key.to_string_32)
				l_key.to_lower
				headers.force (h.item, l_key)
			end
		ensure
			headers_set: headers.count = a_headers.count
		end



feature -- Access

	headers: STRING_TABLE [READABLE_STRING_GENERAL]
			-- The request headers table normalized to lowercase keys

	is_htmx_request: BOOLEAN
			-- Is this an HTMX request?
		do
			Result := headers.has ("hx-request")
		end

	hx_target: detachable STRING_32
			-- ID of the target element
		do
			if attached headers.item ("hx-target") as l_val then
				Result := l_val.to_string_32
			end
		end

	hx_trigger: detachable STRING_32
			-- ID of the triggering element
		do
			if attached headers.item ("hx-trigger") as l_val then
				Result := l_val.to_string_32
			end
		end

	hx_trigger_name: detachable STRING_32
			-- Name of the triggering element
		do
			if attached headers.item ("hx-trigger-name") as l_val then
				Result := l_val.to_string_32
			end
		end

	hx_current_url: detachable STRING_32
			-- Current URL of the browser
		do
			if attached headers.item ("hx-current-url") as l_val then
				Result := l_val.to_string_32
			end
		end

	hx_prompt: detachable STRING_32
			-- User response to prompt
		do
			if attached headers.item ("hx-prompt") as l_val then
				Result := l_val.to_string_32
			end
		end

	hx_boosted: BOOLEAN
			-- Is this a boosted request?
		do
			Result := headers.has ("hx-boosted")
		end

	hx_history_restore_request: BOOLEAN
			-- Is this a history restore request?
		do
			Result := headers.has ("hx-history-restore-request")
		end

end
