note
	description: "AST node representing a named layout section definition"

class
	SECTION_NODE

inherit
	TEMPLATE_NODE

create
	make

feature {NONE} -- Initialization

	make (a_name: READABLE_STRING_GENERAL; a_body: ARRAYED_LIST [TEMPLATE_NODE])
			-- Initialize section node
		do
			create name.make_from_string (a_name.to_string_32)
			body := a_body
		ensure
			name_set: name.same_string_general (a_name)
			body_set: body = a_body
		end

feature -- Access

	name: STRING_32
			-- Section name

	body: ARRAYED_LIST [TEMPLATE_NODE]
			-- Body nodes of the section

feature -- Rendering

	render (a_context: RENDER_CONTEXT; a_buffer: STRING_32)
			-- Render body into a temporary buffer and store it in context sections
		local
			l_buf: STRING_32
		do
			create l_buf.make (100)
			across body as node loop
				node.item.render (a_context, l_buf)
			end
			a_context.sections.force (l_buf, name)
		end

end
