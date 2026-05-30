note
	description: "Application launcher service for active search"

class
	HTMX_ACTIVE_SEARCH

inherit
	WSF_LAUNCHABLE_SERVICE
		redefine
			initialize
		end
	APPLICATION_LAUNCHER [HTMX_ACTIVE_SEARCH_EXECUTION]

create
	make_and_launch

feature {NONE} -- Initialization

	initialize
			-- Initialize service on port 9091
		do
			Precursor
			set_service_option ("port", 9091)
			set_service_option ("verbose", "yes")
		end

end
