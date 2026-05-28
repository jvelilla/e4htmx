note
	description: "Parser that compiles conditional expression strings into expression AST nodes"

class
	EXPRESSION_PARSER

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize parser
		do
		end

feature -- Parsing

	parse (expression: STRING_32): EXPRESSION_NODE
			-- Parse expression string into an AST of EXPRESSION_NODEs
		local
			l_expr: STRING_32
			l_parts: ARRAYED_LIST [STRING_32]
			l_operator: detachable STRING_32
			l_left_str: STRING_32
			l_and_nodes: ARRAYED_LIST [EXPRESSION_NODE]
			l_or_nodes: ARRAYED_LIST [EXPRESSION_NODE]
			i: INTEGER
		do
			create l_expr.make_from_string (expression)
			l_expr.left_adjust
			l_expr.right_adjust

			if l_expr.has_substring (" and ") then
				l_parts := split_string (l_expr, " and ")
				create l_and_nodes.make (l_parts.count)
				from
					i := 1
				until
					i > l_parts.count
				loop
					l_and_nodes.extend (parse (l_parts.i_th (i)))
					i := i + 1
				end
				create {AND_EXPRESSION_NODE} Result.make (l_and_nodes)
			elseif l_expr.has_substring (" or ") then
				l_parts := split_string (l_expr, " or ")
				create l_or_nodes.make (l_parts.count)
				from
					i := 1
				until
					i > l_parts.count
				loop
					l_or_nodes.extend (parse (l_parts.i_th (i)))
					i := i + 1
				end
				create {OR_EXPRESSION_NODE} Result.make (l_or_nodes)
			elseif l_expr.starts_with ("not ") then
				Result := create {NOT_EXPRESSION_NODE}.make (parse (l_expr.substring (5, l_expr.count)))
			elseif l_expr.starts_with ("exists ") then
				l_left_str := l_expr.substring (8, l_expr.count)
				l_left_str.left_adjust
				l_left_str.right_adjust
				create {EXISTS_EXPRESSION_NODE} Result.make (l_left_str)
			else
				l_operator := find_operator (l_expr)
				if l_operator /= Void then
					l_parts := split_string (l_expr, l_operator)
					if l_parts.count = 2 then
						create {COMPARISON_EXPRESSION_NODE} Result.make (l_parts.first, l_parts.last, l_operator)
					else
						create {VARIABLE_EXPRESSION_NODE} Result.make (l_expr)
					end
				else
					create {VARIABLE_EXPRESSION_NODE} Result.make (l_expr)
				end
			end
		end

feature {NONE} -- Implementation

	find_operator (expression: STRING_32): detachable STRING_32
			-- Find the first operator in the expression.
			-- Note: Checks multi-character operators first to prevent precedence errors (e.g. >= before >).
		do
			if expression.has_substring ("==") then
				Result := "=="
			elseif expression.has_substring ("!=") then
				Result := "!="
			elseif expression.has_substring (">=") then
				Result := ">="
			elseif expression.has_substring ("<=") then
				Result := "<="
			elseif expression.has_substring (">") then
				Result := ">"
			elseif expression.has_substring ("<") then
				Result := "<"
			end
		end

	split_string (s: STRING_32; separator: STRING_32): ARRAYED_LIST [STRING_32]
			-- Split string `s` by `separator`
		require
			separator_not_empty: not separator.is_empty
		local
			l_pos, l_start: INTEGER
			l_item: STRING_32
		do
			create Result.make (5)
			from
				l_start := 1
				l_pos := s.substring_index (separator, l_start)
			until
				l_pos = 0
			loop
				create l_item.make_from_string (s.substring (l_start, l_pos - 1))
				Result.extend (l_item)
				l_start := l_pos + separator.count
				l_pos := s.substring_index (separator, l_start)
			end
			create l_item.make_from_string (s.substring (l_start, s.count))
			Result.extend (l_item)
		end

end
