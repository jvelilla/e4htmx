note
	description: "Company representation for active search example"

class
	COMPANY

create
	make

feature {NONE} -- Initialization

	make (a_name: STRING)
		do
			name := a_name
		end

feature -- Access

	name: STRING

end
