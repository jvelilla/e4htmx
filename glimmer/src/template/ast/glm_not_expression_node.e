note
	description: "Logical NOT expression node"

class
	GLM_NOT_EXPRESSION_NODE

inherit
	GLM_EXPRESSION_NODE

create
	make

feature {NONE} -- Initialization

	make (a_node: GLM_EXPRESSION_NODE)
			-- Initialize with single sub-expression
		do
			node := a_node
		ensure
			node_set: node = a_node
		end

feature -- Access

	node: GLM_EXPRESSION_NODE
			-- Sub-expression to negate

feature -- Evaluation

	evaluate (a_context: GLM_RENDER_CONTEXT): BOOLEAN
			-- Negate the sub-expression evaluation
		do
			Result := not node.evaluate (a_context)
		end

end
