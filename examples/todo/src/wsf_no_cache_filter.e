note
	description: "Filter to disable browser caching by adding Cache-Control headers."

class
	WSF_NO_CACHE_FILTER

inherit
	WSF_FILTER

feature -- Basic operations

	execute (req: WSF_REQUEST; res: WSF_RESPONSE)
			-- Execute the filter.
		do
			if not res.header_committed then
				res.put_header_line ("Cache-Control: no-store, no-cache, must-revalidate, max-age=0")
				res.put_header_line ("Pragma: no-cache")
				res.put_header_line ("Expires: 0")
			end
			execute_next (req, res)
		end

end
