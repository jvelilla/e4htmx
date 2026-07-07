note
	description: "Filter to add Content-Security-Policy headers."

class
	WSF_CSP_FILTER

inherit
	WSF_FILTER

create
	make

feature {NONE} -- Initialization

	make (a_policy: READABLE_STRING_8)
			-- Initialize with `a_policy`
		do
			set_policy (a_policy)
		end

feature -- Access

	policy: STRING_8
			-- The CSP policy string.

feature -- Element change

	set_policy (a_policy: READABLE_STRING_8)
			-- Set the CSP policy.
		do
			create policy.make_from_string (a_policy.to_string_8)
		end

feature -- Basic operations

	execute (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Execute the filter
		do
			res.header.put_header_key_value ("Content-Security-Policy", policy)
			execute_next (req, res)
		end

end
