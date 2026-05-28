note
	description: "AST node representing a variable placeholder like {name} or {raw:name}"

class
	VARIABLE_NODE

inherit
	TEMPLATE_NODE

create
	make

feature {NONE} -- Initialization

	make (a_name: READABLE_STRING_GENERAL; a_is_raw: BOOLEAN)
			-- Initialize variable node
		do
			create name.make_from_string (a_name.to_string_32)
			is_raw := a_is_raw
		ensure
			name_set: name.same_string_general (a_name)
			is_raw_set: is_raw = a_is_raw
		end

feature -- Access

	name: STRING_32
			-- Variable name

	is_raw: BOOLEAN
			-- Should HTML escaping be bypassed?

feature -- Rendering

	render (a_context: RENDER_CONTEXT; a_buffer: STRING_32)
			-- Resolve and append variable value to buffer
		local
			l_val: detachable ANY
			l_resolved: STRING_32
		do
			if a_context.has (name) then
				l_val := a_context.item (name)
				if attached l_val as val then
					create l_resolved.make_from_string (val.out.to_string_32)

					-- Apply HTML escaping if needed
					if a_context.auto_escape and not is_raw then
						l_resolved := a_context.escape_html (l_resolved)
					end
					a_buffer.append (l_resolved)
				end
			else
				-- Variable not found - leave the placeholder as is
				a_buffer.append_character ('{')
				if is_raw then
					a_buffer.append ("raw:")
				end
				a_buffer.append (name)
				a_buffer.append_character ('}')
			end
		end

end
