note
	description: "Deferred representation of a conditional expression node"

deferred class
	GLM_EXPRESSION_NODE

feature -- Evaluation

	evaluate (a_context: GLM_RENDER_CONTEXT): BOOLEAN
			-- Evaluate expression in the given render context
		deferred
		end

end
