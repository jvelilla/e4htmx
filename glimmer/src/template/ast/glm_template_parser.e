note
	description: "Compiler that parses template strings into an Abstract Syntax Tree (AST) in a single pass"

class
	GLM_TEMPLATE_PARSER

create
	make

feature {NONE} -- Initialization

	make
		do
			last_error := Void
			create template.make_empty
			create active_list.make (0)
			create stack.make (0)
			create node_stack.make (0)
		end

feature -- Access

	last_error: detachable STRING_32
			-- Description of the last parsing error

	has_error: BOOLEAN
			-- Was there a parsing error?
		do
			Result := last_error /= Void
		end

feature -- Parsing

	parse (a_template: READABLE_STRING_GENERAL): ARRAYED_LIST [GLM_TEMPLATE_NODE]
			-- Parse `a_template` into a list of AST nodes
		local
			i, n: INTEGER
			l_char: CHARACTER_32
			l_start, l_end_pos: INTEGER
			l_tag: STRING_32
			l_text_start: INTEGER
			l_raw: BOOLEAN
			l_val_end: INTEGER
			l_text_node: GLM_TEXT_NODE
			l_var_node: GLM_VARIABLE_NODE
			l_dump_node: GLM_DUMP_NODE
			l_dump_var: STRING_32
			l_raw_var_content: STRING_32
			l_parsed: TUPLE [var_name: STRING_32; filters: ARRAYED_LIST [GLM_FILTER_INVOCATION]]
		do
			last_error := Void
			create Result.make (20)
			create stack.make (10)
			create node_stack.make (10)
			active_list := Result
			
			create template.make_from_string (a_template.to_string_32)
			n := template.count
			l_text_start := 1
			
			from
				i := 1
			until
				i > n or else has_error
			loop
				l_char := template.item (i)
				if l_char = '{' then
					-- Check if we have block tag "{{ " or variable placeholder "{"
					if i + 1 <= n and then template.item (i + 1) = '{' then
						-- Block tag starts here. First collect preceding static text.
						if i > l_text_start then
							create l_text_node.make (template.substring (l_text_start, i - 1))
							active_list.extend (l_text_node)
						end
						
						l_start := i
						i := i + 2
						
						-- Find matching "}}"
						l_end_pos := template.substring_index ("}}", i)
						if l_end_pos > 0 then
							l_tag := template.substring (l_start + 2, l_end_pos - 1)
							l_tag.left_adjust
							l_tag.right_adjust
							
							process_block_tag (l_tag, l_end_pos + 2)
							
							l_text_start := l_end_pos + 2
							i := l_end_pos + 2
						else
							last_error := "Mismatched block tag: missing '}}'"
							i := n + 1 -- Abort
						end
					else
						-- Regular variable placeholder start. Collect preceding static text.
						if i > l_text_start then
							create l_text_node.make (template.substring (l_text_start, i - 1))
							active_list.extend (l_text_node)
						end
						
						l_val_end := template.index_of ('}', i)
						if l_val_end = 0 then
							-- Unclosed brace. Glimmer treats unclosed brace as static text
							l_text_start := i
							i := i + 1
						else
							l_raw_var_content := template.substring (i + 1, l_val_end - 1)
							l_raw_var_content.left_adjust
							l_raw_var_content.right_adjust
							
							l_raw := l_raw_var_content.starts_with ("raw:")
							if l_raw then
								l_raw_var_content := l_raw_var_content.substring (5, l_raw_var_content.count)
								l_raw_var_content.left_adjust
								l_raw_var_content.right_adjust
							end
							
							if l_raw_var_content.same_string ("dump_context") then
								create l_dump_node.make_context
								active_list.extend (l_dump_node)
							elseif l_raw_var_content.starts_with ("dump ") then
								l_dump_var := l_raw_var_content.substring (6, l_raw_var_content.count)
								l_dump_var.left_adjust
								l_dump_var.right_adjust
								create l_dump_node.make_variable (l_dump_var)
								active_list.extend (l_dump_node)
							else
								l_parsed := parse_placeholder_content (l_raw_var_content)
								create l_var_node.make (l_parsed.var_name, l_raw, l_parsed.filters)
								active_list.extend (l_var_node)
							end
							
							l_text_start := l_val_end + 1
							i := l_val_end + 1
						end
					end
				else
					i := i + 1
				end
			end
			
			-- Collect trailing text
			if not has_error and then n >= l_text_start then
				create l_text_node.make (template.substring (l_text_start, n))
				active_list.extend (l_text_node)
			end
			
			-- Check for mismatched block tags
			if not has_error and then not node_stack.is_empty then
				last_error := "Mismatched block tag: unclosed structure at end of template"
			end
		end

feature {NONE} -- Parser Implementation

	parse_placeholder_content (a_content: STRING_32): TUPLE [var_name: STRING_32; filters: ARRAYED_LIST [GLM_FILTER_INVOCATION]]
			-- Parse the content of a placeholder, returning variable name and its filter chain
		local
			l_var_name: STRING_32
			l_filters: ARRAYED_LIST [GLM_FILTER_INVOCATION]
			i, n: INTEGER
			l_char: CHARACTER_32
			in_double_quotes: BOOLEAN
			in_single_quotes: BOOLEAN
			l_current_segment: STRING_32
			l_segments: ARRAYED_LIST [STRING_32]
		do
			create l_segments.make (5)
			create l_current_segment.make_empty
			n := a_content.count
			
			from
				i := 1
			until
				i > n
			loop
				l_char := a_content.item (i)
				if l_char = '"' and not in_single_quotes then
					in_double_quotes := not in_double_quotes
					l_current_segment.append_character (l_char)
				elseif l_char = '%'' and not in_double_quotes then
					in_single_quotes := not in_single_quotes
					l_current_segment.append_character (l_char)
				elseif l_char = '|' and not in_double_quotes and not in_single_quotes then
					l_current_segment.left_adjust
					l_current_segment.right_adjust
					l_segments.extend (l_current_segment)
					create l_current_segment.make_empty
				else
					l_current_segment.append_character (l_char)
				end
				i := i + 1
			end
			l_current_segment.left_adjust
			l_current_segment.right_adjust
			l_segments.extend (l_current_segment)
			
			if not l_segments.is_empty then
				l_var_name := l_segments.first
			else
				create l_var_name.make_empty
			end
			
			create l_filters.make (l_segments.count - 1)
			from
				i := 2
			until
				i > l_segments.count
			loop
				if attached parse_filter_segment (l_segments.i_th (i)) as l_filter then
					l_filters.extend (l_filter)
				end
				i := i + 1
			end
			
			Result := [l_var_name, l_filters]
		end

	parse_filter_segment (a_segment: STRING_32): detachable GLM_FILTER_INVOCATION
			-- Parse filter name and arguments from a segment
		local
			l_colon_pos: INTEGER
			l_name: STRING_32
			l_args_str: STRING_32
			l_args: ARRAYED_LIST [STRING_32]
			i, n: INTEGER
			l_char: CHARACTER_32
			in_double_quotes, in_single_quotes: BOOLEAN
			l_current_arg: STRING_32
		do
			l_colon_pos := a_segment.index_of (':', 1)
			if l_colon_pos = 0 then
				create l_args.make (0)
				create Result.make (a_segment, l_args)
			else
				l_name := a_segment.substring (1, l_colon_pos - 1)
				l_name.left_adjust
				l_name.right_adjust
				
				l_args_str := a_segment.substring (l_colon_pos + 1, a_segment.count)
				l_args_str.left_adjust
				l_args_str.right_adjust
				
				create l_args.make (2)
				create l_current_arg.make_empty
				n := l_args_str.count
				from
					i := 1
				until
					i > n
				loop
					l_char := l_args_str.item (i)
					if l_char = '"' and not in_single_quotes then
						in_double_quotes := not in_double_quotes
						l_current_arg.append_character (l_char)
					elseif l_char = '%'' and not in_double_quotes then
						in_single_quotes := not in_single_quotes
						l_current_arg.append_character (l_char)
					elseif l_char = ',' and not in_double_quotes and not in_single_quotes then
						l_current_arg.left_adjust
						l_current_arg.right_adjust
						l_args.extend (l_current_arg)
						create l_current_arg.make_empty
					else
						l_current_arg.append_character (l_char)
					end
					i := i + 1
				end
				l_current_arg.left_adjust
				l_current_arg.right_adjust
				l_args.extend (l_current_arg)
				
				create Result.make (l_name, l_args)
			end
		end

feature {NONE} -- Parser State

	template: STRING_32
			-- Template string being parsed

	active_list: ARRAYED_LIST [GLM_TEMPLATE_NODE]
			-- Currently active list being compiled into

	stack: ARRAYED_LIST [ARRAYED_LIST [GLM_TEMPLATE_NODE]]
			-- Stack of active lists

	node_stack: ARRAYED_LIST [GLM_TEMPLATE_NODE]
			-- Stack of active nesting nodes

feature {NONE} -- Tag Processing

	process_block_tag (a_tag: STRING_32; a_next_pos: INTEGER)
			-- Process trimmed tag string `a_tag` and mutate parser state
		local
			l_parts: ARRAYED_LIST [STRING_32]
			l_cond: STRING_32
			l_loop_decl: STRING_32
			l_iterator, l_collection: STRING_32
			l_sec_name: STRING_32
			l_y_name: STRING_32
			l_inc_name: STRING_32
			l_cond_node: GLM_CONDITIONAL_NODE
			l_loop_node: GLM_LOOP_NODE
			l_sec_node: GLM_SECTION_NODE
			l_y_node: GLM_YIELD_NODE
			l_inc_node: GLM_INCLUDE_NODE
			l_fill_node: GLM_FILL_NODE
			l_slot_node: GLM_SLOT_NODE
			l_body: ARRAYED_LIST [GLM_TEMPLATE_NODE]
			false_branch: ARRAYED_LIST [GLM_TEMPLATE_NODE]
			l_req_content: STRING_32
			l_req_vars: ARRAYED_LIST [STRING_32]
			l_req_node: GLM_REQUIRE_NODE
			l_expr_parser: GLM_EXPRESSION_PARSER
			l_expr: GLM_EXPRESSION_NODE
			i: INTEGER
		do
			if a_tag.starts_with ("if ") then
				l_cond := a_tag.substring (4, a_tag.count)
				l_cond.left_adjust
				l_cond.right_adjust
				
				create l_cond_node.make (l_cond, create {ARRAYED_LIST [GLM_TEMPLATE_NODE]}.make (10), Void)
				active_list.extend (l_cond_node)
				
				stack.extend (active_list)
				node_stack.extend (l_cond_node)
				active_list := l_cond_node.true_branch
				
			elseif a_tag.starts_with ("else if ") or else a_tag.starts_with ("elsif ") then
				if not node_stack.is_empty and then attached {GLM_CONDITIONAL_NODE} node_stack.last as l_cn then
					if a_tag.starts_with ("else if ") then
						l_cond := a_tag.substring (9, a_tag.count)
					else
						l_cond := a_tag.substring (6, a_tag.count)
					end
					l_cond.left_adjust
					l_cond.right_adjust
					
					create l_cond_node.make (l_cond, create {ARRAYED_LIST [GLM_TEMPLATE_NODE]}.make (10), Void)
					
					create false_branch.make (5)
					false_branch.extend (l_cond_node)
					l_cn.set_false_branch (false_branch)
					
					node_stack.remove_i_th (node_stack.count)
					node_stack.extend (l_cond_node)
					active_list := l_cond_node.true_branch
				else
					last_error := "Mismatched {{else if}} tag: no matching {{if}}"
				end
				
			elseif a_tag.same_string ("else") then
				if not node_stack.is_empty and then attached {GLM_CONDITIONAL_NODE} node_stack.last as l_cn then
					-- Create false branch
					create false_branch.make (10)
					l_cn.set_false_branch (false_branch)
					active_list := false_branch
				else
					last_error := "Mismatched {{else}} tag: no matching {{if}}"
				end
				
			elseif a_tag.same_string ("end") then
				if not node_stack.is_empty then
					node_stack.remove_i_th (node_stack.count)
					if not stack.is_empty then
						active_list := stack.i_th (stack.count)
						stack.remove_i_th (stack.count)
					else
						last_error := "Mismatched {{end}} tag"
					end
				else
					last_error := "Mismatched {{end}} tag: no block is currently open"
				end
				
			elseif a_tag.starts_with ("each ") then
				l_loop_decl := a_tag.substring (6, a_tag.count)
				l_loop_decl.left_adjust
				l_loop_decl.right_adjust
				
				l_parts := split_string (l_loop_decl, " in ")
				if l_parts.count = 2 then
					l_iterator := l_parts.first
					l_iterator.left_adjust
					l_iterator.right_adjust
					
					l_collection := l_parts.last
					l_collection.left_adjust
					l_collection.right_adjust
					
					create l_loop_node.make (l_iterator, l_collection, create {ARRAYED_LIST [GLM_TEMPLATE_NODE]}.make (10))
					active_list.extend (l_loop_node)
					
					stack.extend (active_list)
					node_stack.extend (l_loop_node)
					active_list := l_loop_node.body
				else
					last_error := "Invalid {{each}} syntax: expected {{each item in collection}}"
				end
				
			elseif a_tag.starts_with ("section ") then
				l_sec_name := a_tag.substring (9, a_tag.count)
				l_sec_name.left_adjust
				l_sec_name.right_adjust
				
				create l_sec_node.make (l_sec_name, create {ARRAYED_LIST [GLM_TEMPLATE_NODE]}.make (10))
				active_list.extend (l_sec_node)
				
				stack.extend (active_list)
				node_stack.extend (l_sec_node)
				active_list := l_sec_node.body
				
			elseif a_tag.starts_with ("yield ") then
				l_y_name := a_tag.substring (7, a_tag.count)
				l_y_name.left_adjust
				l_y_name.right_adjust
				
				create l_y_node.make (l_y_name)
				active_list.extend (l_y_node)
				
			elseif a_tag.starts_with ("include ") then
				l_inc_name := a_tag.substring (9, a_tag.count)
				l_inc_name.left_adjust
				l_inc_name.right_adjust
				
				i := l_inc_name.substring_index (" with ", 1)
				if i > 0 then
					l_cond := l_inc_name.substring (1, i - 1)
					l_cond.left_adjust
					l_cond.right_adjust
					
					l_req_content := l_inc_name.substring (i + 6, l_inc_name.count)
					l_req_content.left_adjust
					l_req_content.right_adjust
					
					create l_inc_node.make_with_parameters (l_cond, parse_include_parameters (l_req_content))
				else
					create l_inc_node.make (l_inc_name)
				end
				
				if is_block_include (a_next_pos) then
					create l_body.make (5)
					l_inc_node.set_body (l_body)
					active_list.extend (l_inc_node)
					
					stack.extend (active_list)
					node_stack.extend (l_inc_node)
					active_list := l_body
				else
					active_list.extend (l_inc_node)
				end
				
			elseif a_tag.starts_with ("fill ") then
				l_cond := a_tag.substring (6, a_tag.count)
				l_cond.left_adjust
				l_cond.right_adjust
				
				create l_body.make (10)
				create l_fill_node.make (l_cond, l_body)
				active_list.extend (l_fill_node)
				
				stack.extend (active_list)
				node_stack.extend (l_fill_node)
				active_list := l_body
				
			elseif a_tag.starts_with ("slot ") then
				l_cond := a_tag.substring (6, a_tag.count)
				l_cond.left_adjust
				l_cond.right_adjust
				
				create l_slot_node.make (l_cond)
				active_list.extend (l_slot_node)
				
			elseif a_tag.starts_with ("require ") then
				l_req_content := a_tag.substring (9, a_tag.count)
				l_req_content.left_adjust
				l_req_content.right_adjust
				
				if l_req_content.has (',') then
					l_parts := split_string (l_req_content, ",")
					create l_req_vars.make (l_parts.count)
					from
						i := 1
					until
						i > l_parts.count
					loop
						l_cond := l_parts.i_th (i)
						l_cond.left_adjust
						l_cond.right_adjust
						if not l_cond.is_empty then
							l_req_vars.extend (l_cond)
						end
						i := i + 1
					end
					create l_req_node.make_variables (l_req_content, l_req_vars)
					active_list.extend (l_req_node)
				elseif is_simple_path (l_req_content) then
					create l_req_vars.make (1)
					l_req_vars.extend (l_req_content)
					create l_req_node.make_variables (l_req_content, l_req_vars)
					active_list.extend (l_req_node)
				else
					create l_expr_parser.make
					l_expr := l_expr_parser.parse (l_req_content)
					create l_req_node.make_expression (l_req_content, l_expr)
					active_list.extend (l_req_node)
				end
				
			end
		end

	is_block_include (a_start_pos: INTEGER): BOOLEAN
			-- Does the include tag starting at index `a_start_pos` have fill blocks?
		local
			l_pos: INTEGER
			l_next_tag: STRING_32
			l_end: INTEGER
		do
			l_pos := template.substring_index ("{{", a_start_pos)
			if l_pos > 0 then
				l_end := template.substring_index ("}}", l_pos + 2)
				if l_end > 0 then
					l_next_tag := template.substring (l_pos + 2, l_end - 1)
					l_next_tag.left_adjust
					l_next_tag.right_adjust
					Result := l_next_tag.starts_with ("fill ")
				end
			end
		end

	parse_include_parameters (a_params_str: STRING_32): STRING_TABLE [STRING_32]
			-- Parse parameter key-value pairs (e.g. "key1=val1, key2=val2")
		local
			i_idx, n_len: INTEGER
			l_char: CHARACTER_32
			in_double_quotes, in_single_quotes: BOOLEAN
			l_pair: STRING_32
			l_pairs: ARRAYED_LIST [STRING_32]
			l_eq_pos: INTEGER
			l_key, l_val: STRING_32
		do
			create Result.make (5)
			create l_pairs.make (5)
			create l_pair.make_empty
			n_len := a_params_str.count
			
			from
				i_idx := 1
			until
				i_idx > n_len
			loop
				l_char := a_params_str.item (i_idx)
				if l_char = '"' and not in_single_quotes then
					in_double_quotes := not in_double_quotes
					l_pair.append_character (l_char)
				elseif l_char = '%'' and not in_double_quotes then
					in_single_quotes := not in_single_quotes
					l_pair.append_character (l_char)
				elseif l_char = ',' and not in_double_quotes and not in_single_quotes then
					l_pair.left_adjust
					l_pair.right_adjust
					if not l_pair.is_empty then
						l_pairs.extend (l_pair)
					end
					create l_pair.make_empty
				else
					l_pair.append_character (l_char)
				end
				i_idx := i_idx + 1
			end
			l_pair.left_adjust
			l_pair.right_adjust
			if not l_pair.is_empty then
				l_pairs.extend (l_pair)
			end
			
			across l_pairs as pair loop
				l_eq_pos := pair.item.index_of ('=', 1)
				if l_eq_pos > 1 then
					l_key := pair.item.substring (1, l_eq_pos - 1)
					l_key.left_adjust
					l_key.right_adjust
					
					l_val := pair.item.substring (l_eq_pos + 1, pair.item.count)
					l_val.left_adjust
					l_val.right_adjust
					
					if not l_key.is_empty then
						Result.force (l_val, l_key)
					end
				end
			end
		end

	split_string (s: STRING_32; separator: STRING_32): ARRAYED_LIST [STRING_32]
			-- Split string `s` by `separator`
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

	is_simple_path (s: STRING_32): BOOLEAN
			-- Is `s` a simple variable path name (alphanumeric, underscore, dot, no spaces or operators)?
		local
			j: INTEGER
			c: CHARACTER_32
		do
			Result := not s.is_empty
			from
				j := 1
			until
				j > s.count or not Result
			loop
				c := s.item (j)
				Result := c.is_alpha_numeric or c = '_' or c = '.'
				j := j + 1
			end
		end

end
