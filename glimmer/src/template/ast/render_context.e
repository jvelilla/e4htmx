note
	description: "Rendering context holding variable bindings, partial templates, sections, and recursion depth"

class
	RENDER_CONTEXT

inherit
	HTML_ESCAPER

create
	make, make_sub

feature {NONE} -- Initialization

	make (a_variables: STRING_TABLE [ANY]; a_partials: STRING_TABLE [STRING_32]; a_max_recursion_depth: INTEGER; a_auto_escape: BOOLEAN; a_cache: HASH_TABLE [ARRAYED_LIST [TEMPLATE_NODE], STRING_32]; a_max_cache_size: INTEGER)
			-- Initialize root context with initial bindings and config
		do
			variables := a_variables
			partials := a_partials
			max_recursion_depth := a_max_recursion_depth
			auto_escape := a_auto_escape
			cache := a_cache
			max_cache_size := a_max_cache_size
			current_recursion_depth := 0
			create sections.make (5)
			last_error := Void
		ensure
			variables_set: variables = a_variables
			partials_set: partials = a_partials
			cache_set: cache = a_cache
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
			cache := a_parent.cache
			max_cache_size := a_parent.max_cache_size
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

	cache: HASH_TABLE [ARRAYED_LIST [TEMPLATE_NODE], STRING_32]
			-- Compilation cache passed from the engine

	max_cache_size: INTEGER
			-- Maximum capacity of the compilation cache

	last_error: detachable STRING_32
			-- Description of the last parsing or compilation error

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

	has_error: BOOLEAN
			-- Was there an error?
		do
			Result := last_error /= Void
		end

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

feature -- Operations and Parsing

	set_error (a_error: STRING_32)
			-- Set the last error and propagate to parent context
		do
			last_error := a_error
			if attached parent_context as p then
				p.set_error (a_error)
			end
		end


	get_compiled_template_with_name (a_template: READABLE_STRING_GENERAL; a_name: detachable READABLE_STRING_GENERAL): ARRAYED_LIST [TEMPLATE_NODE]
			-- Compile template string, returning cached AST if already compiled
		local
			l_key: STRING_32
			l_parser: TEMPLATE_PARSER
		do
			if attached a_name as n then
				create l_key.make_from_string (n.to_string_32)
				if cache.has (l_key) and then attached cache.item (l_key) as l_cached then
					Result := l_cached
				else
					create l_parser.make
					Result := l_parser.parse (a_template.to_string_32)
					if l_parser.has_error and then attached l_parser.last_error as err then
						set_error (err)
					else
						if cache.count >= max_cache_size then
							cache.start
							if not cache.off then
								cache.remove (cache.key_for_iteration)
							end
						end
						cache.force (Result, l_key)
					end
				end
			else
				create l_parser.make
				Result := l_parser.parse (a_template.to_string_32)
				if l_parser.has_error and then attached l_parser.last_error as err then
					set_error (err)
				end
			end
		end

	render_partial (template_str: STRING_32; a_name: STRING_32; a_buffer: STRING_32)
			-- Compile and render partial template directly into `a_buffer` using incremented depth context
		local
			l_nodes: ARRAYED_LIST [TEMPLATE_NODE]
			l_sub_context: RENDER_CONTEXT
		do
			l_nodes := get_compiled_template_with_name (template_str, a_name)
			if not has_error then
				l_sub_context := incremented_depth_context
				across l_nodes as node loop
					node.item.render (l_sub_context, a_buffer)
				end
			end
		end

feature -- Expression Evaluation

	evaluate_expression (expression: STRING_32): BOOLEAN
			-- Evaluate a conditional expression.
			-- Note: This is part of the public ad-hoc evaluation API and is not
			-- invoked on the template rendering hot path (which uses pre-compiled AST nodes).
		local
			l_parser: EXPRESSION_PARSER
			l_expr_node: EXPRESSION_NODE
		do
			create l_parser.make
			l_expr_node := l_parser.parse (expression)
			Result := l_expr_node.evaluate (Current)
		end

feature {EXPRESSION_NODE, RENDER_CONTEXT, HTML_TEMPLATE} -- Expression Implementation

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
				if left.generating_type ~ right.generating_type then
					Result := l_num.is_equal (r_num)
				else
					Result := resolve_to_double (left) = resolve_to_double (right)
				end
			else
				Result := left ~ right
			end
		end

	resolve_to_double (a_val: ANY): REAL_64
			-- Convert any numeric value to double
		do
			if attached {REAL_64} a_val as r64 then
				Result := r64
			elseif attached {REAL_32} a_val as r32 then
				Result := r32.to_double
			elseif attached {INTEGER_64} a_val as i64 then
				Result := i64.to_double
			elseif attached {INTEGER_32} a_val as i32 then
				Result := i32.to_double
			elseif attached {INTEGER_16} a_val as i16 then
				Result := i16.to_double
			elseif attached {INTEGER_8} a_val as i8 then
				Result := i8.to_double
			elseif attached {INTEGER} a_val as i then
				Result := i.to_double
			elseif attached {REAL} a_val as r then
				Result := r.to_double
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
