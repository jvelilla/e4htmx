note
	description: "Application service launcher for pagination example"

class
	HTMX_PAGINATION

inherit
	WSF_LAUNCHABLE_SERVICE
		redefine
			initialize
		end
	APPLICATION_LAUNCHER [HTMX_PAGINATION_EXECUTION]

create
	make_and_launch

feature {NONE} -- Initialization

	initialize
			-- Initialize current service.
		do
			Precursor
			set_service_option ("port", 9090)
			set_service_option ("verbose", "yes")
		end

end
