note
	description: "AST node representing a template inheritance extends declaration"

class
	GLM_EXTENDS_NODE

inherit
	GLM_TEMPLATE_NODE

create
	make

feature {NONE} -- Initialization

	make (a_parent_name: READABLE_STRING_GENERAL)
			-- Initialize extends node
		do
			create parent_name.make_from_string (a_parent_name.to_string_32)
		ensure
			parent_name_set: parent_name.same_string_general (a_parent_name)
		end

feature -- Access

	parent_name: STRING_32
			-- Name/path of the parent template to extend

feature -- Rendering

	render (a_context: GLM_RENDER_CONTEXT; a_buffer: STRING_32)
			-- Extends is a metadata node, does not render anything directly.
		do
			-- Do nothing
		end

end
