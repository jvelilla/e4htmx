note
	description: "AST node representing the {{require}} precondition contract"

class
	GLM_REQUIRE_NODE

inherit
	GLM_TEMPLATE_NODE

create
	make_variables, make_expression

feature {NONE} -- Initialization

	make_variables (a_raw: STRING_32; a_vars: ARRAYED_LIST [STRING_32])
			-- Initialize as a list of required variable names
		do
			raw_content := a_raw
			variables := a_vars
			expression := Void
		ensure
			raw_set: raw_content = a_raw
			variables_set: variables = a_vars
			expression_void: expression = Void
		end

	make_expression (a_raw: STRING_32; a_expr: GLM_EXPRESSION_NODE)
			-- Initialize as a boolean expression
		do
			raw_content := a_raw
			variables := Void
			expression := a_expr
		ensure
			raw_set: raw_content = a_raw
			variables_void: variables = Void
			expression_set: expression = a_expr
		end

feature -- Access

	raw_content: STRING_32
			-- The raw precondition statement string

	variables: detachable ARRAYED_LIST [STRING_32]
			-- The required variable/path names

	expression: detachable GLM_EXPRESSION_NODE
			-- The parsed boolean expression

feature -- Rendering

	render (a_context: GLM_RENDER_CONTEXT; a_buffer: STRING_32)
			-- Evaluate precondition if contract mode is enabled.
		local
			l_var: STRING_32
			i: INTEGER
			l_violation: BOOLEAN
		do
			if a_context.contract_mode then
				if attached variables as vars then
					from
						i := 1
					until
						i > vars.count or l_violation
					loop
						l_var := vars.i_th (i)
						if a_context.item (l_var) = Void then
							a_context.set_contract_violation (l_var)
							l_violation := True
						end
						i := i + 1
					end
				elseif attached expression as expr then
					if not expr.evaluate (a_context) then
						a_context.set_contract_violation (raw_content)
					end
				end
			end
		end

end
