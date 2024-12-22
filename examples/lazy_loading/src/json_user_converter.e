note
description:"[
			JSON to USER converter
		]"
date: "$Date$"
revision: "$Revision$"

class
	JSON_USER_CONVERTER

feature -- Conversion

	from_json (a_json: JSON_OBJECT): detachable USER
			-- Create a new USER instance from JSON object
		require
			json_not_void: a_json /= Void
		local
			l_id: INTEGER
			l_name, l_email: STRING
			l_company: COMPANY
			l_company_obj: JSON_OBJECT
		do
				-- Extract basic user information
			if attached {JSON_NUMBER} a_json.item ("id") as l_json_id and then
			   attached {JSON_STRING} a_json.item ("name") as l_json_name and then
			   attached {JSON_STRING} a_json.item ("email") as l_json_email and then
			   attached {JSON_OBJECT} a_json.item ("company") as l_json_company and then
			   attached {JSON_STRING} l_json_company.item ("name") as l_company_name then


				l_id := l_json_id.integer_64_item.to_integer
				l_name := l_json_name.item
				l_email := l_json_email.item
				create l_company.make (l_company_name.item)
					-- Create user instance
				create Result.make (l_id, l_name, l_email, l_company)
			end
		end

	from_json_array (a_json_array: JSON_ARRAY): ARRAYED_LIST [USER]
			-- Create a list of users from JSON array
		local
			l_user: USER
		do
			create Result.make (a_json_array.count)
			across a_json_array as ic loop
				if attached {JSON_OBJECT} ic.item as json_object then
					l_user := from_json (json_object)
					if attached l_user then
						Result.extend (l_user)
					end
				end
			end
		ensure
			result_not_void: attached Result
		end

end
