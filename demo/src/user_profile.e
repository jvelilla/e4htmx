note
	description: "Simple user profile model class for DbC playground reflection demonstration"

class
	USER_PROFILE

create
	make

feature {NONE} -- Initialization

	make (a_username: STRING_32; a_age: INTEGER; a_is_admin: BOOLEAN)
			-- Initialize user profile attributes
		do
			username := a_username
			age := a_age
			is_admin := a_is_admin
		ensure
			username_set: username = a_username
			age_set: age = a_age
			is_admin_set: is_admin = a_is_admin
		end

feature -- Access

	username: STRING_32
			-- User name

	age: INTEGER
			-- Age of the user

	is_admin: BOOLEAN
			-- Is the user an administrator?

end
