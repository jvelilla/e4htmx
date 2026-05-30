note
	description: "Existence check expression node (exists <variable>)"

class
	GLM_EXISTS_EXPRESSION_NODE

inherit
	GLM_EXPRESSION_NODE

create
	make

feature {NONE} -- Initialization

	make (a_name: STRING_32)
			-- Initialize with variable name
		do
			name := a_name
		ensure
			name_set: name = a_name
		end

feature -- Access

	name: STRING_32
			-- Name of the variable to check

feature -- Evaluation

	evaluate (a_context: GLM_RENDER_CONTEXT): BOOLEAN
			-- Check if variable exists in the render context
		do
			Result := a_context.has (name)
		end

end
