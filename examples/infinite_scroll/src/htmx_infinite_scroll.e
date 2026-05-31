note
	description: "Application service launcher for infinite scroll example"

class
	HTMX_INFINITE_SCROLL

inherit
	WSF_LAUNCHABLE_SERVICE
		redefine
			initialize
		end
	APPLICATION_LAUNCHER [HTMX_INFINITE_SCROLL_EXECUTION]

create
	make_and_launch

feature {NONE} -- Initialization

	initialize
			-- Initialize current service.
		do
			Precursor
			set_service_option ("port", 9098)
			set_service_option ("verbose", "yes")
		end

end
