note
	description: "Logical AND expression node with short-circuiting"

class
	GLM_AND_EXPRESSION_NODE

inherit
	GLM_EXPRESSION_NODE

create
	make

feature {NONE} -- Initialization

	make (a_nodes: ARRAYED_LIST [GLM_EXPRESSION_NODE])
			-- Initialize with sub-expressions
		do
			nodes := a_nodes
		ensure
			nodes_set: nodes = a_nodes
		end

feature -- Access

	nodes: ARRAYED_LIST [GLM_EXPRESSION_NODE]
			-- Sub-expressions to evaluate

feature -- Evaluation

	evaluate (a_context: GLM_RENDER_CONTEXT): BOOLEAN
			-- Evaluate sub-expressions with short-circuiting
		local
			i: INTEGER
		do
			Result := True
			from
				i := 1
			until
				i > nodes.count or else not Result
			loop
				Result := nodes.i_th (i).evaluate (a_context)
				i := i + 1
			end
		end

end
