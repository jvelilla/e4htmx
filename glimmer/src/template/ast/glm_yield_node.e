note
	description: "AST node representing a yield placement for layout sections"

class
	GLM_YIELD_NODE

inherit
	GLM_TEMPLATE_NODE

create
	make

feature {NONE} -- Initialization

	make (a_name: READABLE_STRING_GENERAL)
			-- Initialize yield node
		do
			create name.make_from_string (a_name.to_string_32)
		ensure
			name_set: name.same_string_general (a_name)
		end

feature -- Access

	name: STRING_32
			-- Name of the section to yield

feature -- Rendering

	render (a_context: GLM_RENDER_CONTEXT; a_buffer: STRING_32)
			-- Append the rendered section content to the buffer
		do
			if a_context.sections.has (name) and then attached a_context.sections.item (name) as l_section then
				a_buffer.append (l_section)
			end
		end

end
