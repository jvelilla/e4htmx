note
	description: "Variable or constant expression node"

class
	VARIABLE_EXPRESSION_NODE

inherit
	EXPRESSION_NODE

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
			-- Name of the variable or constant value

feature -- Evaluation

	evaluate (a_context: RENDER_CONTEXT): BOOLEAN
			-- Evaluate variable truthiness in the render context
		local
			l_val: detachable ANY
		do
			l_val := a_context.item (name)
			if l_val /= Void then
				Result := a_context.is_truthy (l_val)
			else
				Result := False
			end
		end

end
