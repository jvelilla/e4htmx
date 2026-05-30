note
	description: "[
				Application service for the HTMX Out-of-Band swaps and Events example
			]"
	date: "$Date$"
	revision: "$Revision$"

class
	HTMX_OOB

inherit
	WSF_LAUNCHABLE_SERVICE
		redefine
			initialize
		end
	APPLICATION_LAUNCHER [HTMX_OOB_EXECUTION]

create
	make_and_launch

feature {NONE} -- Initialization

	initialize
			-- Initialize current service.
		do
			Precursor
			set_service_option ("port", 9096)
			set_service_option ("verbose", "yes")
		end

end
