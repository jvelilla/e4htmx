note
	description: "HTML templating system using compiled AST representation"

class
	HTML_TEMPLATE

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize template engine
		do
			create variables.make (10)
			create partials.make (10)
			create sections.make (5)
			recursion_depth := DEFAULT_MAX_RECURSION_DEPTH
			auto_escape := True
			last_error := Void
		end

feature -- Access

	variables: STRING_TABLE [ANY]
			-- Storage for template variables

	partials: STRING_TABLE [STRING_32]
			-- Storage for partial templates

	recursion_depth: INTEGER
			-- Current maximum recursion depth

	DEFAULT_MAX_RECURSION_DEPTH: INTEGER = 10
			-- Default and maximum value for recursion depth

	auto_escape: BOOLEAN
			-- Should variables be automatically HTML escaped?

	layout: detachable STRING_32
			-- Base layout template to use

	sections: STRING_TABLE [STRING_32]
			-- Storage for template sections

	last_error: detachable STRING_32
			-- Description of the last rendering or parsing error

feature -- Status Report

	has_error: BOOLEAN
			-- Did the last operation result in an error?
		do
			Result := last_error /= Void
		end

	is_reserved_name (name: READABLE_STRING_GENERAL): BOOLEAN
			-- Check if name is reserved for loop metadata
		local
			l_name: STRING_32
		do
			create l_name.make_from_string (name.to_string_32)
			Result := reserved_names.has (l_name)
		end

feature -- Element Change

	set_recursion_depth (depth: INTEGER)
			-- Set the maximum recursion depth
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

	set_layout (template: READABLE_STRING_GENERAL)
			-- Set the base layout template
		do
			create layout.make_from_string (template.to_string_32)
		ensure
			layout_set: attached layout as l and then l.same_string_general (template)
		end

	clear_layout
			-- Remove the layout template and clear sections
		do
			layout := Void
			sections.wipe_out
		ensure
			layout_cleared: layout = Void
			sections_cleared: sections.is_empty
		end

	set_variable (name: READABLE_STRING_GENERAL; value: ANY)
			-- Set a template variable
		require
			name_not_reserved: not is_reserved_name (name)
		local
			l_name: STRING_32
		do
			create l_name.make_from_string (name.to_string_32)
			variables.force (value, l_name)
		end

	register_partial (name: READABLE_STRING_GENERAL; template: READABLE_STRING_GENERAL)
			-- Register a partial template that can be included in other templates
		local
			l_name: STRING_32
			l_tmpl: STRING_32
		do
			create l_name.make_from_string (name.to_string_32)
			create l_tmpl.make_from_string (template.to_string_32)
			partials.force (l_tmpl, l_name)
		end

	register_partial_file (name: READABLE_STRING_GENERAL; filename: READABLE_STRING_GENERAL)
			-- Register a partial template from a file
		local
			l_file: PLAIN_TEXT_FILE
			l_template: STRING_32
		do
			create l_file.make_with_name (filename.to_string_32)
			if l_file.exists and then l_file.is_readable then
				l_file.open_read
				l_file.read_stream (l_file.count)
				create l_template.make_from_string (l_file.last_string.to_string_32)
				l_file.close
				register_partial (name, l_template)
			else
				last_error := "Partial file not found or not readable: " + filename.to_string_32
			end
		end

feature -- Operations

	render (template: READABLE_STRING_GENERAL): STRING_32
			-- Render the template with current variables
		local
			l_nodes: ARRAYED_LIST [TEMPLATE_NODE]
			l_context: RENDER_CONTEXT
			l_buffer: STRING_32
		do
			last_error := Void
			l_nodes := get_compiled_template (template)
			if has_error then
				create Result.make_empty
			else
				create l_context.make (variables, partials, recursion_depth, auto_escape, Current)
				create l_buffer.make (template.count * 2)
				
				-- Render main template
				across l_nodes as node loop
					node.item.render (l_context, l_buffer)
				end
				
				-- If we have a layout, process it last
				if attached layout as l_layout then
					create l_buffer.make (l_layout.count * 2)
					l_nodes := get_compiled_template (l_layout)
					if not has_error then
						across l_nodes as node loop
							node.item.render (l_context, l_buffer)
						end
					end
				end
				
				-- Wipe sections at the end of rendering
				sections.wipe_out
				
				Result := l_buffer
			end
		end

	render_file (filename: READABLE_STRING_GENERAL): STRING_32
			-- Render template from a file
		local
			l_file: PLAIN_TEXT_FILE
			l_template: STRING_32
		do
			last_error := Void
			create l_file.make_with_name (filename.to_string_32)
			if l_file.exists and then l_file.is_readable then
				l_file.open_read
				l_file.read_stream (l_file.count)
				create l_template.make_from_string (l_file.last_string.to_string_32)
				l_file.close
				Result := render (l_template)
			else
				last_error := "Template file not found or not readable: " + filename.to_string_32
				create Result.make_empty
			end
		end

	render_section (template: READABLE_STRING_GENERAL; section_name: READABLE_STRING_GENERAL): STRING_32
			-- Render only the named section from the template
		local
			l_nodes: ARRAYED_LIST [TEMPLATE_NODE]
			l_context: RENDER_CONTEXT
			l_buffer: STRING_32
			l_sec_name: STRING_32
		do
			last_error := Void
			l_nodes := get_compiled_template (template)
			if has_error then
				create Result.make_empty
			else
				create l_sec_name.make_from_string (section_name.to_string_32)
				if attached find_section_node (l_nodes, l_sec_name) as l_section then
					create l_context.make (variables, partials, recursion_depth, auto_escape, Current)
					create l_buffer.make (128)
					across l_section.body as node loop
						node.item.render (l_context, l_buffer)
					end
					Result := l_buffer
				else
					last_error := "Section not found: " + l_sec_name
					create Result.make_empty
				end
			end
		end

feature -- Expression Evaluation

	evaluate_expression (expression: READABLE_STRING_GENERAL): BOOLEAN
			-- Evaluate a conditional expression
		local
			l_context: RENDER_CONTEXT
		do
			create l_context.make (variables, partials, recursion_depth, auto_escape, Current)
			Result := l_context.evaluate_expression (expression.to_string_32)
		end

feature -- HTML Safety

	escape_html (str: READABLE_STRING_GENERAL): STRING_32
			-- Convert HTML special characters to entities in a single pass
		local
			i: INTEGER
			c: CHARACTER_32
		do
			create Result.make (str.count + 20)
			from
				i := 1
			until
				i > str.count
			loop
				c := str.item (i)
				inspect c
				when '&' then
					Result.append ("&amp;")
				when '<' then
					Result.append ("&lt;")
				when '>' then
					Result.append ("&gt;")
				when '"' then
					Result.append ("&quot;")
				when '%'' then
					Result.append ("&#39;")
				else
					Result.extend (c)
				end
				i := i + 1
			end
		end

	render_safe (template: READABLE_STRING_GENERAL): STRING_32
			-- Render template with HTML-escaped variables
		local
			l_nodes: ARRAYED_LIST [TEMPLATE_NODE]
			l_context: RENDER_CONTEXT
			l_buffer: STRING_32
		do
			last_error := Void
			l_nodes := get_compiled_template (template)
			if has_error then
				create Result.make_empty
			else
				create l_context.make (variables, partials, recursion_depth, False, Current)
				create l_buffer.make (template.count * 2)
				across l_nodes as node loop
					node.item.render (l_context, l_buffer)
				end
				Result := escape_html (l_buffer)
			end
		end

feature {TEMPLATE_NODE} -- Parser and Recursive Helpers

	render_partial (template_str: STRING_32; a_context: RENDER_CONTEXT; a_buffer: STRING_32)
			-- Compile and render partial template directly into `a_buffer` using incremented depth context
		local
			l_nodes: ARRAYED_LIST [TEMPLATE_NODE]
			l_sub_context: RENDER_CONTEXT
		do
			l_nodes := get_compiled_template (template_str)
			if not has_error then
				l_sub_context := a_context.incremented_depth_context
				across l_nodes as node loop
					node.item.render (l_sub_context, a_buffer)
				end
			end
		end

	render_recursive (template_str: STRING_32; a_context: RENDER_CONTEXT): STRING_32
			-- Parse and recursively render `template_str` under an incremented depth context
		local
			l_nodes: ARRAYED_LIST [TEMPLATE_NODE]
			l_sub_context: RENDER_CONTEXT
		do
			l_nodes := get_compiled_template (template_str)
			if has_error then
				create Result.make_empty
			else
				l_sub_context := a_context.incremented_depth_context
				create Result.make (template_str.count)
				across l_nodes as node loop
					node.item.render (l_sub_context, Result)
				end
			end
		end

feature {NONE} -- Implementation

	find_section_node (a_nodes: ARRAYED_LIST [TEMPLATE_NODE]; a_name: STRING_32): detachable SECTION_NODE
			-- Recursively find section node in AST
		local
			i: INTEGER
			l_node: TEMPLATE_NODE
		do
			from
				i := 1
			until
				i > a_nodes.count or else Result /= Void
			loop
				l_node := a_nodes.i_th (i)
				if attached {SECTION_NODE} l_node as l_sec and then l_sec.name.same_string (a_name) then
					Result := l_sec
				elseif attached {LOOP_NODE} l_node as l_loop then
					Result := find_section_node (l_loop.body, a_name)
				elseif attached {CONDITIONAL_NODE} l_node as l_cond then
					Result := find_section_node (l_cond.true_branch, a_name)
					if Result = Void and then attached l_cond.false_branch as l_false then
						Result := find_section_node (l_false, a_name)
					end
				end
				i := i + 1
			end
		end

	get_compiled_template (a_template: READABLE_STRING_GENERAL): ARRAYED_LIST [TEMPLATE_NODE]
			-- Compile template string, returning cached AST if already compiled
		local
			l_key: STRING_32
			l_parser: TEMPLATE_PARSER
		do
			create l_key.make_from_string (a_template.to_string_32)
			if compiled_templates_cache.has (l_key) and then attached compiled_templates_cache.item (l_key) as l_cached then
				Result := l_cached
			else
				create l_parser.make
				Result := l_parser.parse (l_key)
				if l_parser.has_error then
					last_error := l_parser.last_error
				else
					compiled_templates_cache.force (Result, l_key)
				end
			end
		end

	compiled_templates_cache: HASH_TABLE [ARRAYED_LIST [TEMPLATE_NODE], STRING_32]
			-- Process-wide compilation cache
		once
			create Result.make (100)
			Result.compare_objects
		end

	reserved_names: ARRAY [STRING_32]
			-- Names reserved for loop metadata
		once
			Result := {ARRAY [STRING_32]} <<
					"index",
					"count",
					"is_first",
					"is_last",
					"is_even",
					"is_odd"
				>>
			Result.compare_objects
		end

end
