note
	description: "Summary description for {COMPANY}."
	date: "$Date$"
	revision: "$Revision$"

class
    COMPANY

create
    make

feature {NONE} -- Initialization

    make (a_name: STRING)
            -- Initialize company with given name
        require
            valid_name: not a_name.is_empty
        do
            name := a_name
        ensure
            name_set: name = a_name
        end

feature -- Access
    name: STRING
            -- Name of the company

end
