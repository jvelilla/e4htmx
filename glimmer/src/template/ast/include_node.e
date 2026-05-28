note
	description: "AST node representing a partial template inclusion"

class
	INCLUDE_NODE

inherit
	TEMPLATE_NODE

create
	make

feature {NONE} -- Initialization

	make (a_name: READABLE_STRING_GENERAL)
			-- Initialize include node
		do
			create name.make_from_string (a_name.to_string_32)
		ensure
			name_set: name.same_string_general (a_name)
		end

feature -- Access

	name: STRING_32
			-- Name of the partial template to include

feature -- Rendering

	render (a_context: RENDER_CONTEXT; a_buffer: STRING_32)
			-- Retrieve and recursively render the partial template
		do
			if not a_context.is_recursion_depth_reached then
				if a_context.partials.has (name) and then attached a_context.partials.item (name) as l_partial then
					a_context.engine.render_partial (l_partial, a_context, a_buffer)
				end
			end
		end

end
