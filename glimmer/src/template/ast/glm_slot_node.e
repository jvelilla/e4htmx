note
	description: "AST node representing a slot declaration inside a component"

class
	GLM_SLOT_NODE

inherit
	GLM_TEMPLATE_NODE

create
	make

feature {NONE} -- Initialization

	make (a_name: READABLE_STRING_GENERAL)
			-- Initialize slot node
		do
			create name.make_from_string (a_name.to_string_32)
		ensure
			name_set: name.same_string_general (a_name)
		end

feature -- Access

	name: STRING_32
			-- Slot name

feature -- Rendering

	render (a_context: GLM_RENDER_CONTEXT; a_buffer: STRING_32)
			-- Append the pre-rendered slot content to the buffer
		do
			if attached a_context.slot (name) as l_slot_content then
				a_buffer.append (l_slot_content)
			end
		end

end
