note
	description: "AST node representing the {dump} development inspection statement"

class
	GLM_DUMP_NODE

inherit
	GLM_TEMPLATE_NODE

create
	make_variable, make_context

feature {NONE} -- Initialization

	make_variable (a_name: STRING_32)
			-- Initialize to dump a specific variable
		do
			variable_name := a_name
			is_context_dump := False
		ensure
			variable_name_set: variable_name = a_name
			not_context_dump: not is_context_dump
		end

	make_context
			-- Initialize to dump the entire context
		do
			variable_name := Void
			is_context_dump := True
		ensure
			variable_name_void: variable_name = Void
			is_context_dump: is_context_dump
		end

feature -- Access

	variable_name: detachable STRING_32
			-- Name of the variable to dump

	is_context_dump: BOOLEAN
			-- Should the entire context be dumped?

feature -- Rendering

	render (a_context: GLM_RENDER_CONTEXT; a_buffer: STRING_32)
			-- Render detailed dump if contract mode is active.
		local
			l_renderer: GLM_DEBUG_RENDERER
		do
			if a_context.contract_mode then
				create l_renderer
				if is_context_dump then
					l_renderer.render_context (a_context, a_buffer)
				elseif attached variable_name as var then
					l_renderer.render_dump (var, a_context.item (var), a_buffer)
				end
			end
		end

end
