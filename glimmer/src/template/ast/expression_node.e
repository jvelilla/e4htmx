note
	description: "Deferred representation of a conditional expression node"

deferred class
	EXPRESSION_NODE

feature -- Evaluation

	evaluate (a_context: RENDER_CONTEXT): BOOLEAN
			-- Evaluate expression in the given render context
		deferred
		end

end
