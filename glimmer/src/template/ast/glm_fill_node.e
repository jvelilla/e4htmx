note
	description: "AST node representing caller-provided slot content"

class
	GLM_FILL_NODE

inherit
	GLM_TEMPLATE_NODE

create
	make

feature {NONE} -- Initialization

	make (a_name: READABLE_STRING_GENERAL; a_body: ARRAYED_LIST [GLM_TEMPLATE_NODE])
			-- Initialize fill node
		do
			create name.make_from_string (a_name.to_string_32)
			body := a_body
		ensure
			name_set: name.same_string_general (a_name)
			body_set: body = a_body
		end

feature -- Access

	name: STRING_32
			-- Name of the slot to fill

	body: ARRAYED_LIST [GLM_TEMPLATE_NODE]
			-- Body nodes of the fill block

feature -- Rendering

	render (a_context: GLM_RENDER_CONTEXT; a_buffer: STRING_32)
			-- Do nothing when rendered directly (filled content is projected via slots)
		do
			-- No-op
		end

	render_to_string (a_context: GLM_RENDER_CONTEXT): STRING_32
			-- Render body nodes to a string buffer
		do
			create Result.make (100)
			across body as node loop
				node.item.render (a_context, Result)
			end
		end

end
