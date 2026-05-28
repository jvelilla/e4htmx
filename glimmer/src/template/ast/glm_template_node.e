note
	description: "Abstract representation of an AST node in a compiled template"

deferred class
	GLM_TEMPLATE_NODE

feature -- Rendering

	render (a_context: GLM_RENDER_CONTEXT; a_buffer: STRING_32)
			-- Render current node into `a_buffer` using `a_context`
		deferred
		end

end
