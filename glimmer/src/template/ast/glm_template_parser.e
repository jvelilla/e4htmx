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
			l_var_name: STRING_32
			l_raw: BOOLEAN
			l_val_end: INTEGER
			l_text_node: GLM_TEXT_NODE
			l_var_node: GLM_VARIABLE_NODE
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
							
							process_block_tag (l_tag)
							
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
							l_var_name := template.substring (i + 1, l_val_end - 1)
							l_var_name.left_adjust
							l_var_name.right_adjust
							
							l_raw := l_var_name.starts_with ("raw:")
							if l_raw then
								l_var_name := l_var_name.substring (5, l_var_name.count)
								l_var_name.left_adjust
								l_var_name.right_adjust
							end
							
							create l_var_node.make (l_var_name, l_raw)
							active_list.extend (l_var_node)
							
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

	process_block_tag (a_tag: STRING_32)
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
			false_branch: ARRAYED_LIST [GLM_TEMPLATE_NODE]
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
				
				create l_inc_node.make (l_inc_name)
				active_list.extend (l_inc_node)
				
			else
				last_error := "Unknown block tag: " + a_tag
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

end
