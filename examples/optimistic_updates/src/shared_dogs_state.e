note
	description: "Shared state (database manager) for the HTMX Optimistic Updates application."

class
	SHARED_DOGS_STATE

feature -- Shared Storage

	dogs_mgr: DOGS_DATABASE_MANAGER
			-- Thread-safe database manager for dog breeds.
		once
			create Result
		end

end
