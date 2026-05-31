note
	description: "Application launcher service for active search"

class
	HTMX_OPTIMISTIC_UPDATES

inherit
	WSF_LAUNCHABLE_SERVICE
		redefine
			initialize
		end
	APPLICATION_LAUNCHER [HTMX_OPTIMISTIC_UPDATES_EXECUTION]

create
	make_and_launch

feature {NONE} -- Initialization

	initialize
			-- Initialize service on port 9097
		do
			Precursor
			set_service_option ("port", 9097)
			set_service_option ("verbose", "yes")
		end

end
