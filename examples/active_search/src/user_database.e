note
	description: "Mock database for user search operations"

class
	USER_DATABASE

create
	make

feature {NONE} -- Initialization

	make
		local
			l_google, l_apple, l_meta: COMPANY
		do
			create users.make (10)
			create l_google.make ("Google")
			create l_apple.make ("Apple")
			create l_meta.make ("Meta")

			users.extend (create {USER}.make (1, "Javier Velilla", "jvelilla@eiffel.com", "Architect", "Active", l_google))
			users.extend (create {USER}.make (2, "John Doe", "john.doe@apple.com", "Developer", "Active", l_apple))
			users.extend (create {USER}.make (3, "Jane Smith", "jane.smith@meta.com", "Manager", "Inactive", l_meta))
			users.extend (create {USER}.make (4, "Alice Johnson", "alice@google.com", "Designer", "Active", l_google))
			users.extend (create {USER}.make (5, "Bob Miller", "bob@apple.com", "QA Engineer", "Active", l_apple))
			users.extend (create {USER}.make (6, "Charlie Brown", "charlie@meta.com", "Developer", "Inactive", l_meta))
			users.extend (create {USER}.make (7, "Diana Prince", "diana@google.com", "Director", "Active", l_google))
			users.extend (create {USER}.make (8, "Ethan Hunt", "ethan@apple.com", "SecOps", "Inactive", l_apple))
			users.extend (create {USER}.make (9, "Fiona Gallagher", "fiona@meta.com", "Developer", "Active", l_meta))
			users.extend (create {USER}.make (10, "George Clark", "george@google.com", "Support", "Active", l_google))
		end

feature -- Access

	users: ARRAYED_LIST [USER]
			-- All users

feature -- Query

	search (a_query: READABLE_STRING_GENERAL): ARRAYED_LIST [USER]
			-- Search users matching `a_query` in name, email, role, or company
		local
			l_q: STRING_32
			l_user: USER
		do
			create Result.make (users.count)
			create l_q.make_from_string (a_query.to_string_32)
			l_q.to_lower
			l_q.left_adjust
			l_q.right_adjust

			if l_q.is_empty then
				Result.append (users)
			else
				across users as cur loop
					l_user := cur.item
					if l_user.name.to_string_32.as_lower.has_substring (l_q)
						or else l_user.email.to_string_32.as_lower.has_substring (l_q)
						or else l_user.role.to_string_32.as_lower.has_substring (l_q)
						or else l_user.company.name.to_string_32.as_lower.has_substring (l_q)
					then
						Result.extend (l_user)
					end
				end
			end
		end

end
