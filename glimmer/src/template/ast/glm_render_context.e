note
	description: "Rendering context holding variable bindings, partial templates, sections, and recursion depth"

class
	GLM_RENDER_CONTEXT

inherit
	GLM_HTML_ESCAPER

create
	make, make_sub

feature {NONE} -- Initialization

	make (a_variables: STRING_TABLE [ANY]; a_partials: STRING_TABLE [STRING_32]; a_filter_registry: GLM_FILTER_REGISTRY; a_helper_registry: STRING_TABLE [FUNCTION [TUPLE, STRING_32]]; a_max_recursion_depth: INTEGER; a_auto_escape: BOOLEAN; a_cache: HASH_TABLE [ARRAYED_LIST [GLM_TEMPLATE_NODE], STRING_32]; a_max_cache_size: INTEGER; a_contract_mode: BOOLEAN)
			-- Initialize root context with initial bindings and config
		do
			variables := a_variables
			partials := a_partials
			filter_registry := a_filter_registry
			helper_registry := a_helper_registry
			max_recursion_depth := a_max_recursion_depth
			auto_escape := a_auto_escape
			cache := a_cache
			max_cache_size := a_max_cache_size
			current_recursion_depth := 0
			contract_mode := a_contract_mode
			create sections.make (5)
			last_error := Void
			is_isolated := False
		ensure
			variables_set: variables = a_variables
			partials_set: partials = a_partials
			filter_registry_set: filter_registry = a_filter_registry
			helper_registry_set: helper_registry = a_helper_registry
			cache_set: cache = a_cache
			contract_mode_set: contract_mode = a_contract_mode
		end

	make_sub (a_parent: GLM_RENDER_CONTEXT)
			-- Initialize nested sub-context inheriting from `a_parent`
		do
			parent_context := a_parent
			create variables.make (5)
			partials := a_parent.partials
			filter_registry := a_parent.filter_registry
			helper_registry := a_parent.helper_registry
			sections := a_parent.sections
			max_recursion_depth := a_parent.max_recursion_depth
			current_recursion_depth := a_parent.current_recursion_depth
			auto_escape := a_parent.auto_escape
			cache := a_parent.cache
			max_cache_size := a_parent.max_cache_size
			contract_mode := a_parent.contract_mode
			is_isolated := False
		ensure
			parent_set: parent_context = a_parent
			contract_mode_inherited: contract_mode = a_parent.contract_mode
		end

feature -- Access

	variables: STRING_TABLE [ANY]
			-- Variable bindings in current scope

	partials: STRING_TABLE [STRING_32]
			-- Registered partial templates

	filter_registry: GLM_FILTER_REGISTRY
			-- Built-in filters registry

	helper_registry: STRING_TABLE [FUNCTION [TUPLE, STRING_32]]
			-- Custom helper registry

	sections: STRING_TABLE [STRING_32]
			-- Rendered sections (stored during section evaluation, retrieved during yield)

	max_recursion_depth: INTEGER
			-- Maximum allowed recursion depth

	current_recursion_depth: INTEGER
			-- Current recursion depth

	auto_escape: BOOLEAN
			-- Should variables be automatically HTML escaped?

	cache: HASH_TABLE [ARRAYED_LIST [GLM_TEMPLATE_NODE], STRING_32]
			-- Compilation cache passed from the engine

	max_cache_size: INTEGER
			-- Maximum capacity of the compilation cache

	last_error: detachable STRING_32
			-- Description of the last parsing or compilation error

	last_contract_violation: detachable STRING_32
			-- Description of the last contract violation

	contract_mode: BOOLEAN
			-- Is contract mode enabled?

	is_isolated: BOOLEAN
			-- Is this context isolated from parent variable lookups?

	parent_context: detachable GLM_RENDER_CONTEXT
			-- Parent scope context if nested

	item (a_key: READABLE_STRING_GENERAL): detachable ANY
			-- Value associated with `a_key` in current or parent scopes
		do
			if a_key.to_string_32.has ('.') then
				Result := resolve_dotted_path (a_key)
			elseif variables.has (a_key) then
				Result := variables.item (a_key)
			elseif not is_isolated and then attached parent_context as parent then
				Result := parent.item (a_key)
			end
		end

	has (a_key: READABLE_STRING_GENERAL): BOOLEAN
			-- Does variable `a_key` exist in current or parent scopes?
		do
			if a_key.to_string_32.has ('.') then
				Result := resolve_dotted_path (a_key) /= Void
			else
				Result := variables.has (a_key) or else (not is_isolated and then attached parent_context as parent and then parent.has (a_key))
			end
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

	incremented_depth_context: GLM_RENDER_CONTEXT
			-- Create a new context clone with incremented recursion depth
		do
			create Result.make_sub (Current)
			Result.set_current_recursion_depth (current_recursion_depth + 1)
		ensure
			depth_incremented: Result.current_recursion_depth = current_recursion_depth + 1
		end

	make_child_with (a_params: STRING_TABLE [ANY]): GLM_RENDER_CONTEXT
			-- Create an isolated child context with initial variables `a_params` and incremented recursion depth
		do
			create Result.make_sub (Current)
			Result.set_is_isolated (True)
			Result.set_current_recursion_depth (current_recursion_depth + 1)
			across a_params as param_cursor loop
				Result.variables.force (param_cursor.item, param_cursor.key)
			end
		ensure
			depth_incremented: Result.current_recursion_depth = current_recursion_depth + 1
			is_isolated: Result.is_isolated
		end

	set_is_isolated (a_val: BOOLEAN)
			-- Set `is_isolated` status
		do
			is_isolated := a_val
		ensure
			is_isolated_set: is_isolated = a_val
		end

feature {GLM_RENDER_CONTEXT} -- Implementation

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

	set_contract_violation (a_violation: STRING_32)
			-- Set the last contract violation and propagate to parent context
		do
			last_contract_violation := a_violation
			set_error ("Contract violation: " + a_violation)
			if attached parent_context as p then
				p.set_contract_violation (a_violation)
			end
		ensure
			violation_set: last_contract_violation = a_violation
		end


	get_compiled_template_with_name (a_template: READABLE_STRING_GENERAL; a_name: detachable READABLE_STRING_GENERAL): ARRAYED_LIST [GLM_TEMPLATE_NODE]
			-- Compile template string, returning cached AST if already compiled
		local
			l_key: STRING_32
			l_parser: GLM_TEMPLATE_PARSER
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
			l_nodes: ARRAYED_LIST [GLM_TEMPLATE_NODE]
			l_sub_context: GLM_RENDER_CONTEXT
		do
			l_nodes := get_compiled_template_with_name (template_str, a_name)
			if not has_error then
				l_sub_context := incremented_depth_context
				across l_nodes as node loop
					node.item.render (l_sub_context, a_buffer)
				end
			end
		end

	render_partial_with (template_str: STRING_32; a_name: STRING_32; a_params: STRING_TABLE [STRING_32]; a_buffer: STRING_32)
			-- Compile and render partial template with parameters in an isolated child context directly into `a_buffer`
		local
			l_nodes: ARRAYED_LIST [GLM_TEMPLATE_NODE]
			l_sub_context: GLM_RENDER_CONTEXT
			l_resolved_vars: STRING_TABLE [ANY]
		do
			l_nodes := get_compiled_template_with_name (template_str, a_name)
			if not has_error then
				create l_resolved_vars.make (a_params.count)
				across a_params as param_cursor loop
					l_resolved_vars.force (resolve_value (param_cursor.item), param_cursor.key)
				end
				l_sub_context := make_child_with (l_resolved_vars)
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
			l_parser: GLM_EXPRESSION_PARSER
			l_expr_node: GLM_EXPRESSION_NODE
		do
			create l_parser.make
			l_expr_node := l_parser.parse (expression)
			Result := l_expr_node.evaluate (Current)
		end

feature {GLM_EXPRESSION_NODE, GLM_RENDER_CONTEXT, GLM_HTML_TEMPLATE, GLM_VARIABLE_NODE} -- Expression Implementation

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

			if l_str.count >= 2 and then ((l_str.starts_with ("%"") and l_str.ends_with ("%"")) or else (l_str.starts_with ("'") and l_str.ends_with ("'"))) then
				Result := l_str.substring (2, l_str.count - 1)
			elseif l_str.is_integer_8 then
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

	resolve_dotted_path (a_path: READABLE_STRING_GENERAL): detachable ANY
			-- Resolve a dotted path like "user.name" starting from the context variables
		local
			l_parts: ARRAYED_LIST [STRING_32]
			l_current: detachable ANY
			i: INTEGER
			l_part: STRING_32
		do
			l_parts := split_string (a_path.to_string_32, ".")
			if not l_parts.is_empty then
				l_current := item (l_parts.first)
				from
					i := 2
				until
					i > l_parts.count or l_current = Void
				loop
					l_part := l_parts.i_th (i)
					l_current := resolve_field (l_current, l_part)
					i := i + 1
				end
				Result := l_current
			end
		end

	resolve_field (obj: ANY; field_name: READABLE_STRING_GENERAL): detachable ANY
			-- Resolve a field or key of `obj` by name
		local
			l_internal: INTERNAL
			i: INTEGER
			l_found: BOOLEAN
			l_part: STRING_32
			l_field_name_8: STRING_8
		do
			create l_part.make_from_string (field_name.to_string_32)
			l_part.to_lower
			
			if attached {STRING_TABLE [ANY]} obj as l_table then
				if l_table.has (l_part) then
					Result := l_table.item (l_part)
				else
					across l_table as cursor loop
						if cursor.key.to_string_32.as_lower ~ l_part then
							Result := cursor.item
						end
					end
				end
			elseif attached {HASH_TABLE [ANY, READABLE_STRING_GENERAL]} obj as l_hash then
				if l_hash.has (l_part) then
					Result := l_hash.item (l_part)
				else
					across l_hash as cursor loop
						if cursor.key.to_string_32.as_lower ~ l_part then
							Result := cursor.item
						end
					end
				end
			else
				-- Custom object: use reflection (INTERNAL)
				create l_internal
				if not l_internal.is_special (obj) then
					l_field_name_8 := l_part.to_string_8
					from
						i := 1
					until
						i > l_internal.field_count (obj) or l_found
					loop
						if l_internal.field_name (i, obj).as_lower ~ l_field_name_8 then
							Result := l_internal.field (i, obj)
							l_found := True
						end
						i := i + 1
					end
				end
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
