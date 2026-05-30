note
	description: "User representation for active search example"

class
	USER

create
	make

feature {NONE} -- Initialization

	make (a_id: INTEGER; a_name, a_email, a_role, a_status: STRING; a_company: COMPANY)
		do
			id := a_id
			name := a_name
			email := a_email
			role := a_role
			status := a_status
			company := a_company
		end

feature -- Access

	id: INTEGER

	name: STRING

	email: STRING

	role: STRING

	status: STRING

	company: COMPANY

end
