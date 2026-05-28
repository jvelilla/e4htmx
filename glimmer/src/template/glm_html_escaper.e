note
	description: "HTML escaping utilities"

class
	GLM_HTML_ESCAPER

feature -- Operations

	escape_html (str: READABLE_STRING_GENERAL): STRING_32
			-- Convert HTML special characters to entities in a single pass
		local
			i: INTEGER
			c: CHARACTER_32
		do
			create Result.make (str.count + 20)
			from
				i := 1
			until
				i > str.count
			loop
				c := str.item (i)
				inspect c
				when '&' then
					Result.append ("&amp;")
				when '<' then
					Result.append ("&lt;")
				when '>' then
					Result.append ("&gt;")
				when '"' then
					Result.append ("&quot;")
				when '%'' then
					Result.append ("&#39;")
				else
					Result.extend (c)
				end
				i := i + 1
			end
		end

end
