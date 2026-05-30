note
	description: "Object to interpolate variables into a template string"
	date: "$Date$"
	revision: "$Revision$"

class
	GLM_STRING_TEMPLATE

feature -- Access

	interpolate (a_template: STRING; a_variables: STRING_TABLE [ANY]): STRING
			-- Interpolate variables into template string
		local
			i, n: INTEGER
			c: CHARACTER
			l_var_name: STRING
			l_end: INTEGER
		do
			create Result.make (a_template.count)
			n := a_template.count
			from
				i := 1
			until
				i > n
			loop
				c := a_template.item (i)
				if c = '{' then
					if i + 1 <= n and then a_template.item (i + 1) = '{' then
						-- Escaped brace '{'
						Result.extend ('{')
						i := i + 2
					else
						-- Variable placeholder start
						l_end := a_template.index_of ('}', i)
						if l_end = 0 then
							-- Unclosed brace, treat as text
							Result.extend ('{')
							i := i + 1
						else
							l_var_name := a_template.substring (i + 1, l_end - 1)
							l_var_name.left_adjust
							l_var_name.right_adjust
							if a_variables.has (l_var_name) and then attached a_variables.item (l_var_name) as l_var then
								Result.append (l_var.out)
								i := l_end + 1
							else
								-- Variable not found, leave placeholder as is
								Result.extend ('{')
								i := i + 1
							end
						end
					end
				elseif c = '}' then
					if i + 1 <= n and then a_template.item (i + 1) = '}' then
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
