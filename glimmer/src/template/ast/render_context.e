note
	description: "Rendering context holding variable bindings, partial templates, sections, and recursion depth"

class
	RENDER_CONTEXT

create
	make, make_sub

feature {NONE} -- Initialization

	make (a_variables: STRING_TABLE [ANY]; a_partials: STRING_TABLE [STRING_32]; a_max_recursion_depth: INTEGER; a_auto_escape: BOOLEAN; a_engine: HTML_TEMPLATE)
			-- Initialize root context with initial bindings and config
		do
			variables := a_variables
			partials := a_partials
			max_recursion_depth := a_max_recursion_depth
			auto_escape := a_auto_escape
			engine := a_engine
			current_recursion_depth := 0
			create sections.make (5)
		ensure
			variables_set: variables = a_variables
			partials_set: partials = a_partials
			engine_set: engine = a_engine
		end

	make_sub (a_parent: RENDER_CONTEXT)
			-- Initialize nested sub-context inheriting from `a_parent`
		do
			parent_context := a_parent
			create variables.make (5)
			partials := a_parent.partials
			sections := a_parent.sections
			max_recursion_depth := a_parent.max_recursion_depth
			current_recursion_depth := a_parent.current_recursion_depth
			auto_escape := a_parent.auto_escape
			engine := a_parent.engine
		ensure
			parent_set: parent_context = a_parent
		end

feature -- Access

	variables: STRING_TABLE [ANY]
			-- Variable bindings in current scope

	partials: STRING_TABLE [STRING_32]
			-- Registered partial templates

	sections: STRING_TABLE [STRING_32]
			-- Rendered sections (stored during section evaluation, retrieved during yield)

	max_recursion_depth: INTEGER
			-- Maximum allowed recursion depth

	current_recursion_depth: INTEGER
			-- Current recursion depth

	auto_escape: BOOLEAN
			-- Should variables be automatically HTML escaped?

	engine: HTML_TEMPLATE
			-- Reference to the template engine

	parent_context: detachable RENDER_CONTEXT
			-- Parent scope context if nested

	item (a_key: READABLE_STRING_GENERAL): detachable ANY
			-- Value associated with `a_key` in current or parent scopes
		do
			if variables.has (a_key) then
				Result := variables.item (a_key)
			elseif attached parent_context as parent then
				Result := parent.item (a_key)
			end
		end

	has (a_key: READABLE_STRING_GENERAL): BOOLEAN
			-- Does variable `a_key` exist in current or parent scopes?
		do
			Result := variables.has (a_key) or else (attached parent_context as parent and then parent.has (a_key))
		end

feature -- Status Report

	is_recursion_depth_reached: BOOLEAN
			-- Has the recursion depth limit been reached?
		do
			Result := current_recursion_depth >= max_recursion_depth
		end

feature -- Scoped Context

	incremented_depth_context: RENDER_CONTEXT
			-- Create a new context clone with incremented recursion depth
		do
			create Result.make_sub (Current)
			Result.set_current_recursion_depth (current_recursion_depth + 1)
		ensure
			depth_incremented: Result.current_recursion_depth = current_recursion_depth + 1
		end

feature {RENDER_CONTEXT} -- Implementation

	set_current_recursion_depth (a_depth: INTEGER)
			-- Set the current recursion depth (only for sub-scopes)
		do
			current_recursion_depth := a_depth
		ensure
			depth_set: current_recursion_depth = a_depth
		end

feature -- Expression Evaluation

	evaluate_expression (expression: STRING_32): BOOLEAN
			-- Evaluate a conditional expression
		local
			l_parts: ARRAYED_LIST [STRING_32]
			l_operator: detachable STRING_32
			l_left, l_right: ANY
			l_left_str: STRING_32
			l_value: detachable ANY
		do
			expression.left_adjust
			expression.right_adjust

			if expression.has_substring (" and ") then
				l_parts := split_string (expression, " and ")
				Result := evaluate_expression (l_parts.first) and evaluate_expression (l_parts.last)
			elseif expression.has_substring (" or ") then
				l_parts := split_string (expression, " or ")
				Result := evaluate_expression (l_parts.first) or evaluate_expression (l_parts.last)
			elseif expression.starts_with ("not ") then
				Result := not evaluate_expression (expression.substring (5, expression.count))
			elseif expression.starts_with ("exists ") then
				l_left_str := expression.substring (8, expression.count)
				l_left_str.left_adjust
				l_left_str.right_adjust
				Result := has (l_left_str)
			else
					-- Handle comparison operators
				l_operator := find_operator (expression)
				if l_operator /= Void then
					l_parts := split_string (expression, l_operator)
					if l_parts.count = 2 then
						l_left := resolve_value (l_parts.first)
						l_right := resolve_value (l_parts.last)
						Result := compare_values (l_left, l_right, l_operator)
					end
				else
						-- Simple variable check
					l_value := item (expression)
					if l_value /= Void then
						Result := is_truthy (l_value)
					else
						Result := False
					end
				end
			end
		end

feature {NONE} -- Expression Implementation

	find_operator (expression: STRING_32): detachable STRING_32
			-- Find the first operator in the expression
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

	resolve_value (value_str: STRING_32): ANY
			-- Resolve a value string to its actual value
		local
			l_str: STRING_32
			l_val: detachable ANY
		do
			create l_str.make_from_string (value_str)
			l_str.left_adjust
			l_str.right_adjust

			if l_str.is_integer_8 then
				Result := l_str.to_integer_8
			elseif l_str.is_integer_16 then
				Result := l_str.to_integer_16
			elseif l_str.is_integer_32 then
				Result := l_str.to_integer_32
			elseif l_str.is_integer_64 then
				Result := l_str.to_integer_64
			elseif l_str.is_real_32 then
				Result := l_str.to_real_32
			elseif l_str.is_real_64 then
				Result := l_str.to_real_64
			elseif l_str.is_double then
				Result := l_str.to_double
			elseif l_str.is_boolean then
				Result := l_str.to_boolean
			else
				l_val := item (l_str)
				if l_val /= Void then
					Result := l_val
				else
					Result := l_str
				end
			end
		end

	compare_values (left, right: ANY; operator: STRING_32): BOOLEAN
			-- Compare two values using the given operator
		do
			if operator.same_string_general ("==") then
				Result := are_equal (left, right)
			elseif operator.same_string_general ("!=") then
				Result := not are_equal (left, right)
			elseif operator.same_string_general (">") then
				Result := is_greater (left, right)
			elseif operator.same_string_general ("<") then
				Result := is_less (left, right)
			elseif operator.same_string_general (">=") then
				Result := is_greater_equal (left, right)
			elseif operator.same_string_general ("<=") then
				Result := is_less_equal (left, right)
			end
		end

	are_equal (left, right: ANY): BOOLEAN
			-- Check if two values are equal
		do
			if attached {NUMERIC} left as l_num and attached {NUMERIC} right as r_num then
				Result := l_num.is_equal (r_num)
			else
				Result := left ~ right
			end
		end

	is_greater (left, right: ANY): BOOLEAN
			-- Check if left is greater than right
		do
			if attached {COMPARABLE} left as l_comp and attached {COMPARABLE} right as r_comp then
				Result := l_comp > r_comp
			end
		end

	is_less (left, right: ANY): BOOLEAN
			-- Check if left is less than right
		do
			if attached {COMPARABLE} left as l_comp and attached {COMPARABLE} right as r_comp then
				Result := l_comp < r_comp
			end
		end

	is_greater_equal (left, right: ANY): BOOLEAN
			-- Check if left is greater than or equal to right
		do
			if attached {COMPARABLE} left as l_comp and attached {COMPARABLE} right as r_comp then
				Result := l_comp >= r_comp
			end
		end

	is_less_equal (left, right: ANY): BOOLEAN
			-- Check if left is less than or equal to right
		do
			if attached {COMPARABLE} left as l_comp and attached {COMPARABLE} right as r_comp then
				Result := l_comp <= r_comp
			end
		end

	is_truthy (value: ANY): BOOLEAN
			-- Determines if a value should be considered true in conditional statements
		do
			if attached {BOOLEAN} value as b then
				Result := b
			elseif attached {READABLE_STRING_GENERAL} value as s then
				Result := not s.is_empty
			elseif attached {INTEGER_8} value as i8 then
				Result := i8 /= 0
			elseif attached {INTEGER_16} value as i16 then
				Result := i16 /= 0
			elseif attached {INTEGER_32} value as i32 then
				Result := i32 /= 0
			elseif attached {INTEGER_64} value as i64 then
				Result := i64 /= 0
			elseif attached {INTEGER} value as i then
				Result := i /= 0
			elseif attached {REAL_32} value as r32 then
				Result := r32 /= 0.0
			elseif attached {REAL_64} value as r64 then
				Result := r64 /= 0.0
			elseif attached {REAL} value as r then
				Result := r /= 0.0
			else
				Result := value /= Void
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
