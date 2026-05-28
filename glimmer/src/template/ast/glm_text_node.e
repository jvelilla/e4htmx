note
	description: "AST node representing static text"

class
	GLM_TEXT_NODE

inherit
	GLM_TEMPLATE_NODE

create
	make

feature {NONE} -- Initialization

	make (a_text: READABLE_STRING_GENERAL)
			-- Initialize text node
		do
			create text.make_from_string (a_text.to_string_32)
		ensure
			text_set: text.same_string_general (a_text)
		end

feature -- Access

	text: STRING_32
			-- Static text content

feature -- Rendering

	render (a_context: GLM_RENDER_CONTEXT; a_buffer: STRING_32)
			-- Append static text to buffer
		do
			a_buffer.append (text)
		end

end
