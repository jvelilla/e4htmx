note
	description: "Object to interpolate variables into a template string"
	date: "$Date$"
	revision: "$Revision$"

class
	GLM_STRING_TEMPLATE

feature -- Access

	interpolate (a_template: READABLE_STRING_GENERAL; a_variables: STRING_TABLE [ANY]): STRING_32
			-- Interpolate variables into template string
		local
			i, n: INTEGER
			c: CHARACTER_32
			l_var_name: STRING_32
			l_end: INTEGER
			l_template: STRING_32
		do
			l_template := a_template.to_string_32
			create Result.make (l_template.count)
			n := l_template.count
			from
				i := 1
			until
				i > n
			loop
				c := l_template.item (i)
				if c = '{' then
					if i + 1 <= n and then l_template.item (i + 1) = '{' then
						-- Escaped brace '{'
						Result.extend ('{')
						i := i + 2
					else
						-- Variable placeholder start
						l_end := l_template.index_of ('}', i)
						if l_end = 0 then
							-- Unclosed brace, treat as text
							Result.extend ('{')
							i := i + 1
						else
							l_var_name := l_template.substring (i + 1, l_end - 1)
							l_var_name.left_adjust
							l_var_name.right_adjust
							if a_variables.has (l_var_name) and then attached a_variables.item (l_var_name) as l_var then
								if attached {READABLE_STRING_GENERAL} l_var as l_str then
									Result.append (l_str.to_string_32)
								else
									Result.append (l_var.out.to_string_32)
								end
								i := l_end + 1
							else
								-- Variable not found, leave placeholder as is
								Result.extend ('{')
								i := i + 1
							end
						end
					end
				elseif c = '}' then
					if i + 1 <= n and then l_template.item (i + 1) = '}' then
						-- Escaped brace '}'
						Result.extend ('}')
						i := i + 2
					else
						-- Single '}', leave as is
						Result.extend ('}')
						i := i + 1
					end
				else
					Result.extend (c)
					i := i + 1
				end
			end
		end

end
