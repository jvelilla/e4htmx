note
	description: "HTML templating system using ESX for variable interpolation"
	date: "$Date$"
	revision: "$Revision$"

class
	HTML_TEMPLATE

inherit
	ESX

create
	make

feature {NONE} -- Initialization

	make
		do
			create variables.make (10)
			create partials.make (10)
			create sections.make (5)
			recursion_depth := DEFAULT_MAX_RECURSION_DEPTH
			auto_escape := True -- Enable auto-escaping by default
		end

feature -- Access

	variables: STRING_TABLE [ANY]
			-- Storage for template variables

	partials: STRING_TABLE [STRING]
			-- Storage for partial templates

	recursion_depth: INTEGER
			-- Current maximum recursion depth
			-- Default and maximum value is DEFAULT_MAX_RECURSION_DEPTH

	DEFAULT_MAX_RECURSION_DEPTH: INTEGER = 10
			-- Default and maximum value for recursion depth

	auto_escape: BOOLEAN
			-- Should variables be automatically HTML escaped?
			-- Default is True for security

	layout: detachable STRING
			-- Base layout template to use

	sections: STRING_TABLE [STRING]
			-- Storage for template sections

feature -- Element Change

	set_recursion_depth (depth: INTEGER)
			-- Set the maximum recursion depth
			-- If depth is greater than DEFAULT_MAX_RECURSION_DEPTH,
			-- DEFAULT_MAX_RECURSION_DEPTH will be used instead
		require
			depth_non_negative: depth >= 0
		do
			if depth <= DEFAULT_MAX_RECURSION_DEPTH then
				recursion_depth := depth
			else
				recursion_depth := DEFAULT_MAX_RECURSION_DEPTH
			end
		ensure
			depth_set: recursion_depth <= DEFAULT_MAX_RECURSION_DEPTH
			depth_non_negative: recursion_depth >= 0
		end

	set_auto_escape (value: BOOLEAN)
			-- Enable or disable automatic HTML escaping
		do
			auto_escape := value
		ensure
			auto_escape_set: auto_escape = value
		end

	set_layout (template: STRING)
			-- Set the base layout template
		require
			template_not_void: template /= Void
		do
			layout := template
		ensure
			layout_set: layout = template
		end

	clear_layout
			-- Remove the layout template
		do
			layout := Void
			if attached sections as s then
				s.wipe_out
			end
		end

feature -- Operations

	set_variable (name: STRING; value: ANY)
			-- Set a template variable
			-- Raises an error if name conflicts with loop metadata
		require
			name_not_void: name /= Void
			value_not_void: value /= Void
			name_not_reserved: not is_reserved_name (name)
		do
			variables.force (value, name)
		end

	render (template: STRING): STRING
			-- Render the template with current variables
		require
			template_not_void: template /= Void
		local
			l_resolved: STRING
		do
				-- First resolve variables
			l_resolved := resolve_variables (template, 0)
				-- Then resolve loops
			l_resolved := resolve_loops (l_resolved)
				-- Then resolve conditionals
			l_resolved := resolve_conditionals (l_resolved)
				-- Then extract sections
			l_resolved := resolve_sections (l_resolved)

				-- If we have a layout, process it last
			if attached layout as l_layout then
					-- Process the layout template, replacing yields with sections
				l_resolved := resolve_yields (l_layout)
			end

			Result := l_resolved

				-- Clear sections after rendering
			sections.wipe_out
		end

	render_file (filename: STRING): STRING
			-- Render template from a file
		require
			filename_not_void: filename /= Void
		local
			l_file: PLAIN_TEXT_FILE
			l_template: STRING
		do
			create l_file.make_with_name (filename)
			if l_file.exists and then l_file.is_readable then
				l_file.open_read
				l_file.read_stream (l_file.count)
				l_template := l_file.last_string
				l_file.close
				Result := render (l_template)
			else
				create Result.make_empty
			end
		end

	register_partial (name: STRING; template: STRING)
			-- Register a partial template that can be included in other templates
		require
			name_not_void: name /= Void
			template_not_void: template /= Void
		do
			if partials = Void then
				create partials.make (10)
			end
			partials.force (template, name)
		end

	register_partial_file (name: STRING; filename: STRING)
			-- Register a partial template from a file
		require
			name_not_void: name /= Void
			filename_not_void: filename /= Void
		local
			l_file: PLAIN_TEXT_FILE
			l_template: STRING
		do
			create l_file.make_with_name (filename)
			if l_file.exists and then l_file.is_readable then
				l_file.open_read
				l_file.read_stream (l_file.count)
				l_template := l_file.last_string
				l_file.close
				register_partial (name, l_template)
			end
		end

feature {NONE} -- Implementation

	resolve_variables (template: STRING; depth: INTEGER): STRING
			-- Recursively resolve variables and partial includes in the template
		require
			template_not_void: template /= Void
			depth_non_negative: depth >= 0
		local
			l_start, l_end, l_next_start: INTEGER
			l_var_name: STRING
			l_value: ANY
			l_resolved: STRING
			l_partial: STRING
			l_partial_start, l_partial_end: INTEGER
			l_raw: BOOLEAN
		do
			if depth >= recursion_depth then
				Result := template
			else
				create Result.make_from_string (template)

					-- First handle partial includes
				from
					l_partial_start := Result.substring_index ("{{include ", 1)
				until
					l_partial_start = 0
				loop
					l_partial_end := Result.substring_index ("}}", l_partial_start)
					if l_partial_end > l_partial_start then
						l_var_name := Result.substring (l_partial_start + 10, l_partial_end - 1).twin
						l_var_name.left_adjust
						l_var_name.right_adjust

						if attached partials as p and then attached p.item (l_var_name) as partial_template then
							l_resolved := resolve_variables (partial_template, depth + 1)
							Result.replace_substring (l_resolved, l_partial_start, l_partial_end + 1)
						end
					end
					l_partial_start := Result.substring_index ("{{include ", l_partial_end + 2)
				end

					-- Then handle regular variables
				from
					l_start := Result.substring_index ("{", 1)
				until
					l_start = 0
				loop
					l_end := Result.index_of ('}', l_start)
					if l_end > l_start then
						l_var_name := Result.substring (l_start + 1, l_end - 1)
							-- Check if this is a raw (unescaped) variable
						l_raw := l_var_name.starts_with ("raw:")
						if l_raw then
							l_var_name := l_var_name.substring (5, l_var_name.count)
						end

						l_value := variables.item (l_var_name)
						if l_value /= Void then
								-- Recursively resolve the value
							l_resolved := resolve_variables (l_value.out, depth + 1)
								-- Apply HTML escaping if auto_escape is enabled and not a raw variable
							if auto_escape and not l_raw then
								l_resolved := escape_html (l_resolved)
							end
							Result.replace_substring (l_resolved, l_start, l_end)
							l_next_start := l_start + l_resolved.count
						else
							l_next_start := l_start + 1
						end
					else
						l_next_start := l_start + 1
					end
					if l_next_start <= Result.count then
						l_start := Result.substring_index ("{", l_next_start)
					else
						l_start := 0
					end
				end
			end
		end

	resolve_conditionals (template: STRING): STRING
			-- Resolve conditional blocks in the template, including nested conditionals
		require
			template_not_void: template /= Void
		local
			l_start, l_else, l_end, l_nested_start: INTEGER
			l_condition: STRING
			l_true_block, l_false_block: STRING
			l_value: ANY
			l_result_block: STRING
			l_condition_end: INTEGER
			l_end_tag_length: INTEGER
			l_processed_block: STRING
			l_nesting_level: INTEGER
			l_loop_start: INTEGER
			l_else_start: INTEGER
		do
			create Result.make_from_string (template)
			l_end_tag_length := 7 -- "{{end}}" length

			from
				l_start := Result.substring_index ("{{if ", 1)
			until
				l_start = 0
			loop
					-- Initialize nesting level
				l_nesting_level := 1
					-- Find the end of the conditional, considering nested ones
				from
					l_end := Result.substring_index ("{{end}}", l_start)
					l_nested_start := Result.substring_index ("{{if ", l_start + 1)
					l_loop_start := Result.substring_index ("{{each ", l_start + 1)
					l_else_start := Result.substring_index ("{{else}}", l_start + 1)
				until
					l_end = 0 or l_nesting_level = 0
				loop
					if (l_nested_start > 0 and l_nested_start < l_end) or
						(l_loop_start > 0 and l_loop_start < l_end) then
							-- Found a nested conditional or loop before the end tag
						l_nesting_level := l_nesting_level + 1
						if l_nested_start > 0 and l_nested_start < l_end then
							l_nested_start := Result.substring_index ("{{if ", l_nested_start + 1)
						end
						if l_loop_start > 0 and l_loop_start < l_end then
							l_loop_start := Result.substring_index ("{{each ", l_loop_start + 1)
						end
					elseif l_else_start > 0 and l_else_start < l_end then
							-- Found an else tag, continue to find the matching end tag
						l_else_start := Result.substring_index ("{{else}}", l_else_start + 1)
					else
							-- Found an end tag
						l_nesting_level := l_nesting_level - 1
						if l_nesting_level > 0 then
								-- Still need to find more end tags
							l_end := Result.substring_index ("{{end}}", l_end + 1)
								-- Look for potential nested conditionals or loops after current end tag
							if l_end > 0 then
								l_nested_start := Result.substring_index ("{{if ", l_end + 1)
								l_loop_start := Result.substring_index ("{{each ", l_end + 1)
								l_else_start := Result.substring_index ("{{else}}", l_end + 1)
							end
						end
					end
				end

				if l_end > 0 then
						-- Find optional else block (only for current nesting level)
					l_else := find_matching_else (Result, l_start, l_end)

						-- Rest of the existing conditional processing logic...
					l_condition_end := Result.substring_index ("}}", l_start)

					if l_else > l_start and l_else < l_end then
							-- We have an else block
						l_condition := Result.substring (l_start + 5, l_condition_end - 1)
						l_condition.left_adjust
						l_condition.right_adjust

						l_true_block := Result.substring (
								l_condition_end + 2,
								l_else - 1)
						l_false_block := Result.substring (l_else + 8, l_end - 1)

							-- Evaluate condition
						l_value := variables.item (l_condition)
						if l_value /= Void and then evaluate_expression (l_condition) then
								-- Process any nested conditionals in the true block
							l_processed_block := resolve_conditionals (l_true_block)
							l_result_block := l_processed_block
						else
								-- Process any nested conditionals in the false block
							l_processed_block := resolve_conditionals (l_false_block)
							l_result_block := l_processed_block
						end
					else
							-- No else block
						l_condition := Result.substring (l_start + 5, l_condition_end - 1)
						l_condition.left_adjust
						l_condition.right_adjust

						l_true_block := Result.substring (
								l_condition_end + 2,
								l_end - 1)

							-- Evaluate condition
						l_value := variables.item (l_condition)
						if l_value /= Void and then evaluate_expression (l_condition) then
								-- Process any nested conditionals in the true block
							l_processed_block := resolve_conditionals (l_true_block)
							l_result_block := l_processed_block
						else
							l_result_block := ""
						end
					end

						-- Replace the entire conditional block with the result
					if l_result_block.is_empty then
						Result.remove_substring (l_start, l_end + l_end_tag_length - 1)
					else
						Result.replace_substring (l_result_block, l_start, l_end + l_end_tag_length - 1)
					end
				else
						-- No matching end tag found, move to next
					l_start := Result.substring_index ("{{if ", l_start + 1)
				end

					-- Find next conditional after processing this one
				if not Result.is_empty then
					l_start := Result.substring_index ("{{if ", 1)
				else
					l_start := 0
				end
			end
		end

feature -- Expression

	evaluate_expression (expression: STRING): BOOLEAN
			-- Evaluate a conditional expression
			-- Supports:
			-- - Comparison: ==, !=, >, <, >=, <=
			-- - Logical: and, or, not
			-- - Existence: exists
			-- - Basic math comparisons
		local
			l_parts: LIST [STRING]
			l_operator: STRING
			l_left, l_right: ANY
			l_left_str, l_right_str: STRING
			l_value: ANY
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
				Result := variables.has (l_left_str)
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
					l_value := variables.item (expression)
					if l_value /= Void then
						Result := is_truthy (l_value)
					else
						Result := False
					end
				end
			end
		end

feature {NONE} -- Implementation

	find_operator (expression: STRING): detachable STRING
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

	resolve_value (value_str: STRING): ANY
			-- Resolve a value string to its actual value
		local
			l_str: STRING
		do
			l_str := value_str.twin
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
			elseif attached variables.item (l_str) as ls then
				Result := ls
			else
				Result := l_str
			end
		end

	compare_values (left, right: ANY; operator: STRING): BOOLEAN
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
			elseif attached {STRING} value as s then
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
				Result := i /= 0 -- For backward compatibility
			elseif attached {REAL_32} value as r32 then
				Result := r32 /= 0.0
			elseif attached {REAL_64} value as r64 then
				Result := r64 /= 0.0
			elseif attached {REAL} value as r then
				Result := r /= 0.0 -- For backward compatibility
			else
				Result := value /= Void
			end
		end

	process_nested_structures (template: STRING): STRING
			-- Process nested loops and conditionals while preserving outer scope
		local
			l_current_vars: STRING_TABLE [ANY]
			l_resolved: STRING
		do
				-- Store current variables state
			create l_current_vars.make (variables.count)
			across variables as var loop
				l_current_vars.force (var.item, var.key)
			end

				-- Process in order: variables, loops, and conditionals
			l_resolved := resolve_variables (template, 0)
			l_resolved := resolve_loops (l_resolved)
			l_resolved := resolve_conditionals (l_resolved)

				-- Restore variables state
			restore_variables (l_current_vars)

			Result := l_resolved
		end

	resolve_loops (template: STRING): STRING
			-- Resolve loop blocks in the template
		local
			l_start, l_end: INTEGER
			l_iterator_name, l_collection_name: STRING
			l_loop_body, l_processed_body, l_result_block: STRING
			l_parts: LIST [STRING]
			l_outer_vars: STRING_TABLE [ANY]
			l_index: INTEGER
			l_total: INTEGER
			l_current_value: ANY
		do
			create Result.make_from_string (template)

			from
				l_start := Result.substring_index ("{{each ", 1)
			until
				l_start = 0
			loop
					-- Store outer scope
				create l_outer_vars.make (variables.count)
				across variables as var loop
					l_outer_vars.force (var.item, var.key)
				end

				l_end := find_matching_end (Result, l_start)

				if l_end > 0 then
					l_parts := split_loop_declaration (Result, l_start, l_end)

					if l_parts.count = 2 then
						l_iterator_name := l_parts.first
						l_collection_name := l_parts.last

						l_loop_body := Result.substring (
								Result.substring_index ("}}", l_start) + 2,
								l_end - 1)

						if attached {ITERABLE [ANY]} variables.item (l_collection_name) as l_iter then
							create l_result_block.make_empty

								-- Calculate total items
							l_total := 0
							across l_iter as count_item loop
								l_total := l_total + 1
							end

								-- Process items
							l_index := 0
							across l_iter as item loop
								l_index := l_index + 1
								l_current_value := item.item

									-- Restore outer scope for each iteration
								restore_variables (l_outer_vars)

									-- Set current iterator value and metadata
								variables.force (l_current_value, l_iterator_name)
								set_loop_metadata (l_index, l_total)

									-- Process nested structures
								l_processed_body := process_nested_structures (l_loop_body)
								l_result_block.append (l_processed_body)

									-- Clean up metadata
								clear_loop_metadata
							end

								-- Restore outer scope after loop
							restore_variables (l_outer_vars)

								-- Replace loop block with result
							Result.replace_substring (l_result_block, l_start, l_end + 6)
						else
							Result.remove_substring (l_start, l_end + 6)
						end
					end
				end

					-- Find next loop
				l_start := Result.substring_index ("{{each ", 1)
			end
		end

	find_matching_end (template: STRING; start_pos: INTEGER): INTEGER
			-- Find matching end tag considering nested structures
		local
			l_nesting_level: INTEGER
			l_pos, l_next_start: INTEGER
			l_struct_start: INTEGER
		do
			from
				l_nesting_level := 1
				l_pos := start_pos
			until
				l_nesting_level = 0 or l_pos = 0
			loop
					-- Find next structure start (loop or conditional)
				l_struct_start := find_next_structure_start (template, l_pos + 1)

					-- Find next end tag
				l_next_start := template.substring_index ("{{end}}", l_pos + 1)

				if l_struct_start > 0 and l_struct_start < l_next_start then
					l_nesting_level := l_nesting_level + 1
					l_pos := l_struct_start
				elseif l_next_start > 0 then
					l_nesting_level := l_nesting_level - 1
					l_pos := l_next_start
					if l_nesting_level = 0 then
						Result := l_next_start
					end
				else
					l_pos := 0
				end
			end
		end

	find_next_structure_start (template: STRING; start_pos: INTEGER): INTEGER
			-- Find start of next nested structure (loop or conditional)
		local
			l_loop_start, l_if_start: INTEGER
		do
			l_loop_start := template.substring_index ("{{each ", start_pos)
			l_if_start := template.substring_index ("{{if ", start_pos)

			if l_loop_start > 0 and l_if_start > 0 then
				Result := l_loop_start.min (l_if_start)
			elseif l_loop_start > 0 then
				Result := l_loop_start
			else
				Result := l_if_start
			end
		end

	restore_variables (stored_vars: STRING_TABLE [ANY])
			-- Restore variables from stored state
		do
			variables.wipe_out
			across stored_vars as var loop
				variables.force (var.item, var.key)
			end
		end

	split_loop_declaration (template: STRING; start_pos, end_pos: INTEGER): ARRAYED_LIST [STRING]
			-- Split loop declaration into iterator and collection names
		local
			l_declaration: STRING
			l_end_decl: INTEGER
		do
			l_end_decl := template.substring_index ("}}", start_pos)
			l_declaration := template.substring (start_pos + 7, l_end_decl - 1)
			Result := split_string (l_declaration, " in ")
			if Result.count = 2 then
				Result.first.left_adjust
				Result.first.right_adjust
				Result.last.left_adjust
				Result.last.right_adjust
			end
		end

	split_string (s: STRING; separator: STRING): ARRAYED_LIST [STRING]
			-- Split string `s` by `separator`
		require
			s_not_void: s /= Void
			separator_not_void: separator /= Void
			separator_not_empty: not separator.is_empty
		local
			l_pos, l_start: INTEGER
		do
			create Result.make (5)
			from
				l_start := 1
				l_pos := s.substring_index (separator, l_start)
			until
				l_pos = 0
			loop
				Result.extend (s.substring (l_start, l_pos - 1))
				l_start := l_pos + separator.count
				l_pos := s.substring_index (separator, l_start)
			end
			Result.extend (s.substring (l_start, s.count))
		end

feature -- HTML Safety

	escape_html (str: STRING): STRING
			-- Convert HTML special characters to entities
		require
			str_not_void: str /= Void
		do
			create Result.make_from_string (str)
			Result.replace_substring_all ("&", "&amp;")
			Result.replace_substring_all ("<", "&lt;")
			Result.replace_substring_all (">", "&gt;")
			Result.replace_substring_all ("%"", "&quot;")
			Result.replace_substring_all ("'", "&#39;")
		end

	render_safe (template: STRING): STRING
			-- Render template with HTML-escaped variables
		require
			template_not_void: template /= Void
		local
			l_safe_vars: STRING_TABLE [ANY]
			l_resolved: STRING
		do
			l_resolved := resolve_variables (template, 0)
			Result := escape_html (l_resolved)
		end

	resolve_sections (template: STRING): STRING
			-- Extract sections from template and store them
		local
			l_start, l_end: INTEGER
			l_section_name: STRING
			l_section_content: STRING
			l_condition_end: INTEGER
			l_end_tag_length: INTEGER
		do
			create Result.make_from_string (template)
			l_end_tag_length := 7 -- "{{end}}" length

			from
				l_start := Result.substring_index ("{{section ", 1)
			until
				l_start = 0
			loop
					-- Find the end of the section
				l_end := Result.substring_index ("{{end}}", l_start)
				if l_end > 0 then
						-- Find where the section declaration ends
					l_condition_end := Result.substring_index ("}}", l_start)

						-- Get section name
					l_section_name := Result.substring (l_start + 10, l_condition_end - 1)
					l_section_name.left_adjust
					l_section_name.right_adjust

						-- Get section content
					l_section_content := Result.substring (
							l_condition_end + 2,
							l_end - 1)

						-- Store the section
					sections.force (l_section_content, l_section_name)

						-- Remove the section declaration from the template
					Result.remove_substring (l_start, l_end + l_end_tag_length - 1)
				else
						-- No matching end tag found, move to next
					if Result.is_empty then
						l_start := 0 -- Exit the loop if Result is empty
					else
						l_start := Result.substring_index ("{{section ", l_start + 1)
					end
				end
			end
		end

	resolve_yields (template: STRING): STRING
			-- Replace yield tags with section content
		require
			template_not_void: template /= Void
		local
			l_start, l_end: INTEGER
			l_section_name: STRING
			l_section_content: STRING
		do
			create Result.make_from_string (template)

			from
				l_start := Result.substring_index ("{{yield ", 1)
			until
				l_start = 0
			loop
				l_end := Result.substring_index ("}}", l_start)
				if l_end > 0 then
						-- Get section name
					l_section_name := Result.substring (l_start + 8, l_end - 1)
					l_section_name.left_adjust
					l_section_name.right_adjust

						-- Get section content
					if attached sections.item (l_section_name) as content then
						l_section_content := content
					else
						l_section_content := "" -- Section not found
					end

						-- Replace yield with section content
					Result.replace_substring (l_section_content, l_start, l_end + 1)
				end
				l_start := Result.substring_index ("{{yield ", l_end + 1)
			end
		end

	find_matching_else (template: STRING; start_pos, end_pos: INTEGER): INTEGER
			-- Find the matching else tag for the current nesting level
			-- Returns 0 if no matching else is found
		local
			l_pos, l_if_count: INTEGER
			l_current_pos: INTEGER
		do
			Result := 0
			l_current_pos := start_pos

			from
				l_pos := template.substring_index ("{{else}}", l_current_pos)
			until
				l_pos = 0 or l_pos >= end_pos or Result > 0
			loop
					-- Count number of if statements before this else
				l_if_count := count_occurrences (
						template.substring (start_pos, l_pos),
						"{{if ")

					-- Count number of end statements before this else
				if l_if_count = count_occurrences (
							template.substring (start_pos, l_pos),
							"{{end}}") + 1 then
						-- This else belongs to our if statement
					Result := l_pos
				else
						-- Keep searching
					l_current_pos := l_pos + 1
					l_pos := template.substring_index ("{{else}}", l_current_pos)
				end
			end
		end

	count_occurrences (str: STRING; substr: STRING): INTEGER
			-- Count number of occurrences of substr in str
		local
			l_pos: INTEGER
		do
			from
				l_pos := str.substring_index (substr, 1)
			until
				l_pos = 0
			loop
				Result := Result + 1
				l_pos := str.substring_index (substr, l_pos + substr.count)
			end
		end

feature {NONE} -- Loop Metadata

	set_loop_metadata (index: INTEGER; total: INTEGER)
			-- Set metadata variables for current loop iteration
		require
			valid_index: index > 0
			valid_total: total > 0
			index_in_range: index <= total
		do
			variables.force (index, "index")
			variables.force (total, "count")
			variables.force (index = 1, "is_first")
			variables.force (index = total, "is_last")
			variables.force ((index \\ 2) = 0, "is_even")
			variables.force ((index \\ 2) = 1, "is_odd")
		end

	clear_loop_metadata
			-- Remove loop metadata variables
		do
			variables.remove ("index")
			variables.remove ("count")
			variables.remove ("is_first")
			variables.remove ("is_last")
			variables.remove ("is_even")
			variables.remove ("is_odd")
		end

feature {NONE} -- Constants

	reserved_names: ARRAY [STRING]
			-- Names reserved for loop metadata
		once
			Result := <<
					"index", -- Current iteration index
					"count", -- Total items in collection
					"is_first", -- First item indicator
					"is_last", -- Last item indicator
					"is_even", -- Even index indicator
					"is_odd" -- Odd index indicator
				>>
			Result.compare_objects
		end

feature -- Status Report

	is_reserved_name (name: STRING): BOOLEAN
			-- Check if name is reserved for loop metadata
		require
			name_not_void: name /= Void
		do
			Result := reserved_names.has (name)
		end

end
