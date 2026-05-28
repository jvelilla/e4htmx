note
	description: "Comparison expression node representing binary relational operations"

class
	COMPARISON_EXPRESSION_NODE

inherit
	EXPRESSION_NODE

create
	make

feature {NONE} -- Initialization

	make (a_left, a_right: STRING_32; a_operator: STRING_32)
			-- Initialize with operands and operator
		do
			create left.make_from_string (a_left)
			left.left_adjust
			left.right_adjust
			create right.make_from_string (a_right)
			right.left_adjust
			right.right_adjust
			operator := a_operator
		ensure
			operator_set: operator = a_operator
		end

feature -- Access

	left: STRING_32
			-- Left operand (variable or constant)

	right: STRING_32
			-- Right operand (variable or constant)

	operator: STRING_32
			-- Relational operator (e.g. "==", ">=")

feature -- Evaluation

	evaluate (a_context: RENDER_CONTEXT): BOOLEAN
			-- Compare left and right values using the operator
		local
			l_left_val, l_right_val: ANY
		do
			l_left_val := a_context.resolve_value (left)
			l_right_val := a_context.resolve_value (right)
			Result := a_context.compare_values (l_left_val, l_right_val, operator)
		end

end
