note
	description: "AST node representing a named block in template inheritance"

class
	GLM_BLOCK_NODE

inherit
	GLM_TEMPLATE_NODE

create
	make

feature {NONE} -- Initialization

	make (a_name: READABLE_STRING_GENERAL; a_body: ARRAYED_LIST [GLM_TEMPLATE_NODE])
			-- Initialize block node
		do
			create name.make_from_string (a_name.to_string_32)
			body := a_body
		ensure
			name_set: name.same_string_general (a_name)
			body_set: body = a_body
		end

feature -- Access

	name: STRING_32
			-- Block name

	body: ARRAYED_LIST [GLM_TEMPLATE_NODE]
			-- Default body nodes of the block

feature -- Rendering

	render (a_context: GLM_RENDER_CONTEXT; a_buffer: STRING_32)
			-- Render block, using override body if registered in context, otherwise default body
		local
			l_body: ARRAYED_LIST [GLM_TEMPLATE_NODE]
		do
			if a_context.block_overrides.has (name) and then attached a_context.block_overrides.item (name) as l_override then
				l_body := l_override
			else
				l_body := body
			end
			across l_body as node loop
				node.item.render (a_context, a_buffer)
			end
		end

end
