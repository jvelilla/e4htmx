note
	description: "AST node representing a partial template inclusion"

class
	GLM_INCLUDE_NODE

inherit
	GLM_TEMPLATE_NODE

create
	make, make_with_parameters

feature {NONE} -- Initialization

	make (a_name: READABLE_STRING_GENERAL)
			-- Initialize include node without parameters
		do
			create name.make_from_string (a_name.to_string_32)
			parameters := Void
		ensure
			name_set: name.same_string_general (a_name)
			no_parameters: parameters = Void
		end

	make_with_parameters (a_name: READABLE_STRING_GENERAL; a_params: STRING_TABLE [STRING_32])
			-- Initialize include node with parameters
		do
			create name.make_from_string (a_name.to_string_32)
			parameters := a_params
		ensure
			name_set: name.same_string_general (a_name)
			parameters_set: parameters = a_params
		end

feature -- Access

	name: STRING_32
			-- Name of the partial template to include

	parameters: detachable STRING_TABLE [STRING_32]
			-- Scoped child parameters (if any)

feature -- Rendering

	render (a_context: GLM_RENDER_CONTEXT; a_buffer: STRING_32)
			-- Retrieve and recursively render the partial template
		do
			if not a_context.is_recursion_depth_reached then
				if a_context.partials.has (name) and then attached a_context.partials.item (name) as l_partial then
					if attached parameters as l_params then
						a_context.render_partial_with (l_partial, name, l_params, a_buffer)
					else
						a_context.render_partial (l_partial, name, a_buffer)
					end
				end
			end
		end

end
