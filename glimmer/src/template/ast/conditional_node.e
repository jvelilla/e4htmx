note
	description: "AST node representing a conditional (if-else) control structure"

class
	CONDITIONAL_NODE

inherit
	TEMPLATE_NODE

create
	make

feature {NONE} -- Initialization

	make (a_condition: READABLE_STRING_GENERAL; a_true_branch: ARRAYED_LIST [TEMPLATE_NODE]; a_false_branch: detachable ARRAYED_LIST [TEMPLATE_NODE])
			-- Initialize conditional node
		local
			l_parser: EXPRESSION_PARSER
		do
			create condition.make_from_string (a_condition.to_string_32)
			create l_parser.make
			condition_expr := l_parser.parse (condition)
			true_branch := a_true_branch
			false_branch := a_false_branch
		ensure
			condition_set: condition.same_string_general (a_condition)
			true_branch_set: true_branch = a_true_branch
			false_branch_set: false_branch = a_false_branch
		end

feature -- Access

	condition: STRING_32
			-- Condition expression

	condition_expr: EXPRESSION_NODE
			-- Compiled condition expression

	true_branch: ARRAYED_LIST [TEMPLATE_NODE]
			-- AST nodes for the true branch

	false_branch: detachable ARRAYED_LIST [TEMPLATE_NODE]
			-- AST nodes for the false branch (else block)

feature -- Element Change

	set_false_branch (a_false_branch: ARRAYED_LIST [TEMPLATE_NODE])
			-- Set the false branch nodes
		do
			false_branch := a_false_branch
		ensure
			false_branch_set: false_branch = a_false_branch
		end

feature -- Rendering

	render (a_context: RENDER_CONTEXT; a_buffer: STRING_32)
			-- Evaluate condition and render the corresponding branch
		do
			if condition_expr.evaluate (a_context) then
				across true_branch as node loop
					node.item.render (a_context, a_buffer)
				end
			elseif attached false_branch as l_false then
				across l_false as node loop
					node.item.render (a_context, a_buffer)
				end
			end
		end

end
