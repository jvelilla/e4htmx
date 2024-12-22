note
description:"[
			Object representing a User
		]"
date: "$Date$"
revision: "$Revision$"

class
    USER

create
    make

feature {NONE} -- Initialization

    make (a_id: INTEGER; a_name, a_email: STRING; a_company: COMPANY)
            -- Initialize user with given attributes
        require
            valid_id: a_id > 0
            valid_name:  not a_name.is_empty
            valid_email: not a_email.is_empty
        do
            id := a_id
            name := a_name
            email := a_email
            company := a_company
        ensure
            id_set: id = a_id
            name_set: name = a_name
            email_set: email = a_email
            company_set: company = a_company
        end

feature -- Access

    id: INTEGER
            -- Unique identifier for the user

    name: STRING
            -- Full name of the user

    email: STRING
            -- Email address of the user

    company: COMPANY
            -- Associated company information

invariant
    valid_id: id > 0
    valid_name: not name.is_empty
    valid_email: not email.is_empty
end
