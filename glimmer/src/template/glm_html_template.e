note
	description: "HTML templating system using compiled AST representation"

class
	GLM_HTML_TEMPLATE

inherit
	GLM_HTML_ESCAPER

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize template engine
		do
			create variables.make (10)
			create partials.make (10)
			create sections.make (5)
			create trigger_events.make (5)
			trigger_events.compare_objects
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
		do
			Result := reserved_names_set.has (name.to_string_32)
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

	set_integer (name: READABLE_STRING_GENERAL; value: INTEGER)
			-- Set an integer template variable
		require
			name_not_reserved: not is_reserved_name (name)
		do
			set_variable (name, value)
		end

	set_boolean (name: READABLE_STRING_GENERAL; value: BOOLEAN)
			-- Set a boolean template variable
		require
			name_not_reserved: not is_reserved_name (name)
		do
			set_variable (name, value)
		end

	set_string (name: READABLE_STRING_GENERAL; value: READABLE_STRING_GENERAL)
			-- Set a string template variable
		require
			name_not_reserved: not is_reserved_name (name)
		do
			set_variable (name, value.to_string_32)
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
		do
			Result := render_internal (template, Void)
		end

	render_with_name (template: READABLE_STRING_GENERAL; template_name: READABLE_STRING_GENERAL): STRING_32
			-- Render the template with current variables, using named cache entry
		do
			Result := render_internal (template, template_name)
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
				Result := render_with_name (l_template, filename)
			else
				last_error := "Template file not found or not readable: " + filename.to_string_32
				create Result.make_empty
			end
		end

	render_section (template: READABLE_STRING_GENERAL; section_name: READABLE_STRING_GENERAL): STRING_32
			-- Render only the named section from the template
		do
			Result := render_section_internal (template, section_name, Void)
		end

	render_section_with_name (template: READABLE_STRING_GENERAL; section_name: READABLE_STRING_GENERAL; template_name: READABLE_STRING_GENERAL): STRING_32
			-- Render only the named section from the template, using named cache entry
		do
			Result := render_section_internal (template, section_name, template_name)
		end

	render_oob (template: READABLE_STRING_GENERAL; sections_to_render: ARRAY [READABLE_STRING_GENERAL]): STRING_32
			-- Render multiple sections as an OOB response
		do
			Result := render_oob_internal (template, sections_to_render, Void)
		end

	render_oob_with_name (template: READABLE_STRING_GENERAL; sections_to_render: ARRAY [READABLE_STRING_GENERAL]; template_name: READABLE_STRING_GENERAL): STRING_32
			-- Render multiple sections as an OOB response, using named cache entry
		do
			Result := render_oob_internal (template, sections_to_render, template_name)
		end

	render_oob_internal (template: READABLE_STRING_GENERAL; sections_to_render: ARRAY [READABLE_STRING_GENERAL]; a_name: detachable READABLE_STRING_GENERAL): STRING_32
			-- Implementation of OOB rendering
		local
			i: INTEGER
			l_sec_name: STRING_32
			l_sec_content: STRING_32
		do
			create Result.make_empty
			if not sections_to_render.is_empty then
				-- Render first section normally
				l_sec_name := sections_to_render.item (sections_to_render.lower).to_string_32
				Result := render_section_internal (template, l_sec_name, a_name)
				
				-- Render subsequent sections wrapped in hx-swap-oob divs
				from
					i := sections_to_render.lower + 1
				until
					i > sections_to_render.upper
				loop
					l_sec_name := sections_to_render.item (i).to_string_32
					l_sec_content := render_section_internal (template, l_sec_name, a_name)
					
					Result.append ("<div hx-swap-oob=%"true%" id=%"" + l_sec_name + "%">")
					Result.append (l_sec_content)
					Result.append ("</div>")
					
					i := i + 1
				end
			end
		end

	clear_cache
			-- Clear the compilation cache
		do
			compiled_templates_cache.wipe_out
			section_nodes_cache.wipe_out
		end

	max_cache_size: INTEGER = 500
			-- Maximum capacity of the compilation cache

feature -- HTMX Metadata

	trigger_events: ARRAYED_LIST [STRING_32]
			-- Events to include in HX-Trigger response header

	push_url: detachable STRING_32
			-- URL to push into the browser history (HX-Push-Url)

	replace_url: detachable STRING_32
			-- URL to replace in the browser history (HX-Replace-Url)

	add_trigger (event_name: READABLE_STRING_GENERAL)
			-- Register an HTMX event to fire after swap
		do
			trigger_events.extend (event_name.to_string_32)
		ensure
			trigger_added: trigger_events.has (event_name.to_string_32)
		end

	htmx_trigger_header: STRING_32
			-- Serialise `trigger_events' as a comma-separated list of event names for the HX-Trigger header.
		local
			l_first: BOOLEAN
		do
			create Result.make (100)
			l_first := True
			across trigger_events as event loop
				if not l_first then
					Result.append (", ")
				end
				Result.append (event.item)
				l_first := False
			end
		end

	set_push_url (url: READABLE_STRING_GENERAL)
			-- Set URL to push into browser history (HX-Push-Url)
		do
			create push_url.make_from_string (url.to_string_32)
		ensure
			push_url_set: attached push_url as p and then p.same_string_general (url)
		end

	set_replace_url (url: READABLE_STRING_GENERAL)
			-- Set URL to replace in browser history (HX-Replace-Url)
		do
			create replace_url.make_from_string (url.to_string_32)
		ensure
			replace_url_set: attached replace_url as r and then r.same_string_general (url)
		end

	clear_push_url
			-- Clear push URL metadata
		do
			push_url := Void
		ensure
			push_url_cleared: push_url = Void
		end

	clear_replace_url
			-- Clear replace URL metadata
		do
			replace_url := Void
		ensure
			replace_url_cleared: replace_url = Void
		end

	clear_trigger_events
			-- Clear registered trigger events
		do
			trigger_events.wipe_out
		ensure
			trigger_events_cleared: trigger_events.is_empty
		end

	clear_htmx_metadata
			-- Clear all HTMX-specific response metadata
		do
			clear_trigger_events
			clear_push_url
			clear_replace_url
		ensure
			trigger_events_cleared: trigger_events.is_empty
			push_url_cleared: push_url = Void
			replace_url_cleared: replace_url = Void
		end



feature -- Expression Evaluation

	evaluate_expression (expression: READABLE_STRING_GENERAL): BOOLEAN
			-- Evaluate a conditional expression
		local
			l_context: GLM_RENDER_CONTEXT
		do
			create l_context.make (variables, partials, recursion_depth, auto_escape, compiled_templates_cache, max_cache_size)
			Result := l_context.evaluate_expression (expression.to_string_32)
		end

feature -- HTML Safety


	render_safe (template: READABLE_STRING_GENERAL): STRING_32
			-- Render template with HTML-escaped variables
		local
			l_nodes: ARRAYED_LIST [GLM_TEMPLATE_NODE]
			l_context: GLM_RENDER_CONTEXT
			l_buffer: STRING_32
		do
			last_error := Void
			l_nodes := get_compiled_template (template)
			if has_error then
				create Result.make_empty
			else
				create l_context.make (variables, partials, recursion_depth, False, compiled_templates_cache, max_cache_size)
				create l_buffer.make (template.count * 8)
				across l_nodes as node loop
					node.item.render (l_context, l_buffer)
				end
				Result := escape_html (l_buffer)
			end
		end

feature {NONE} -- Implementation

	render_internal (template: READABLE_STRING_GENERAL; a_name: detachable READABLE_STRING_GENERAL): STRING_32
			-- Render the template with current variables, optionally using cache key `a_name`
		local
			l_nodes: ARRAYED_LIST [GLM_TEMPLATE_NODE]
			l_context: GLM_RENDER_CONTEXT
			l_buffer: STRING_32
			l_main_buffer: STRING_32
		do
			last_error := Void
			l_nodes := get_compiled_template_with_name (template, a_name)
			if has_error then
				create Result.make_empty
			else
				create l_context.make (variables, partials, recursion_depth, auto_escape, compiled_templates_cache, max_cache_size)
				
				if attached layout as l_layout then
					-- Layout is present. Render main template into a temporary buffer
					create l_main_buffer.make (template.count * 8)
					across l_nodes as node loop
						node.item.render (l_context, l_main_buffer)
					end
					-- If there is non-section content and "content" is not already defined, store it in "content"
					if not l_main_buffer.is_empty and then not l_context.sections.has ("content") then
						l_context.sections.force (l_main_buffer, "content")
					end
					
					-- Render layout
					create l_buffer.make (l_layout.count * 8)
					l_nodes := get_compiled_template_with_name (l_layout, Void)
					if not has_error then
						across l_nodes as node loop
							node.item.render (l_context, l_buffer)
						end
					end
				else
					-- No layout, render main template directly to l_buffer
					create l_buffer.make (template.count * 8)
					across l_nodes as node loop
						node.item.render (l_context, l_buffer)
					end
				end
				
				if l_context.has_error then
					last_error := l_context.last_error
					create Result.make_empty
				else
					-- Wipe sections at the end of rendering
					sections.wipe_out
					Result := l_buffer
				end
			end
		end

	render_section_internal (template: READABLE_STRING_GENERAL; section_name: READABLE_STRING_GENERAL; a_name: detachable READABLE_STRING_GENERAL): STRING_32
			-- Render only the named section from the template, optionally using cache key `a_name`
		local
			l_nodes: ARRAYED_LIST [GLM_TEMPLATE_NODE]
			l_context: GLM_RENDER_CONTEXT
			l_buffer: STRING_32
			l_sec_name: STRING_32
			l_cache_key: detachable STRING_32
			l_section: detachable GLM_SECTION_NODE
		do
			last_error := Void
			create l_sec_name.make_from_string (section_name.to_string_32)
			
			if attached a_name as n then
				create l_cache_key.make (n.count + l_sec_name.count + 1)
				l_cache_key.append (n.to_string_32)
				l_cache_key.append_character ('#')
				l_cache_key.append (l_sec_name)
				
				if section_nodes_cache.has (l_cache_key) and then attached section_nodes_cache.item (l_cache_key) as l_cached then
					l_section := l_cached
				end
			end
			
			if l_section = Void then
				l_nodes := get_compiled_template_with_name (template, a_name)
				if not has_error then
					l_section := find_section_node (l_nodes, l_sec_name)
					if l_section /= Void and then attached l_cache_key as k then
						if section_nodes_cache.count >= max_cache_size then
							section_nodes_cache.start
							if not section_nodes_cache.off then
								section_nodes_cache.remove (section_nodes_cache.key_for_iteration)
							end
						end
						section_nodes_cache.force (l_section, k)
					end
				end
			end
			
			if has_error then
				create Result.make_empty
			elseif l_section /= Void then
				create l_context.make (variables, partials, recursion_depth, auto_escape, compiled_templates_cache, max_cache_size)
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

	find_section_node (a_nodes: ARRAYED_LIST [GLM_TEMPLATE_NODE]; a_name: STRING_32): detachable GLM_SECTION_NODE
			-- Recursively find section node in AST
		local
			i: INTEGER
			l_node: GLM_TEMPLATE_NODE
		do
			from
				i := 1
			until
				i > a_nodes.count or else Result /= Void
			loop
				l_node := a_nodes.i_th (i)
				if attached {GLM_SECTION_NODE} l_node as l_sec and then l_sec.name.same_string (a_name) then
					Result := l_sec
				elseif attached {GLM_LOOP_NODE} l_node as l_loop then
					Result := find_section_node (l_loop.body, a_name)
				elseif attached {GLM_CONDITIONAL_NODE} l_node as l_cond then
					Result := find_section_node (l_cond.true_branch, a_name)
					if Result = Void and then attached l_cond.false_branch as l_false then
						Result := find_section_node (l_false, a_name)
					end
				end
				i := i + 1
			end
		end

	get_compiled_template (a_template: READABLE_STRING_GENERAL): ARRAYED_LIST [GLM_TEMPLATE_NODE]
			-- Compile template string, returning cached AST if already compiled
		do
			Result := get_compiled_template_with_name (a_template, Void)
		end

	get_compiled_template_with_name (a_template: READABLE_STRING_GENERAL; a_name: detachable READABLE_STRING_GENERAL): ARRAYED_LIST [GLM_TEMPLATE_NODE]
			-- Compile template string, returning cached AST if already compiled, optionally using named cache key
		local
			l_key: STRING_32
			l_parser: GLM_TEMPLATE_PARSER
		do
			if attached a_name as n then
				create l_key.make_from_string (n.to_string_32)
				if compiled_templates_cache.has (l_key) and then attached compiled_templates_cache.item (l_key) as l_cached then
					Result := l_cached
				else
					create l_parser.make
					Result := l_parser.parse (a_template.to_string_32)
					if l_parser.has_error then
						last_error := l_parser.last_error
					else
						if compiled_templates_cache.count >= max_cache_size then
							compiled_templates_cache.start
							if not compiled_templates_cache.off then
								compiled_templates_cache.remove (compiled_templates_cache.key_for_iteration)
							end
						end
						compiled_templates_cache.force (Result, l_key)
					end
				end
			else
				create l_parser.make
				Result := l_parser.parse (a_template.to_string_32)
				if l_parser.has_error then
					last_error := l_parser.last_error
				end
			end
		end

	compiled_templates_cache: HASH_TABLE [ARRAYED_LIST [GLM_TEMPLATE_NODE], STRING_32]
			-- Process-wide compilation cache
		once
			create Result.make (100)
			Result.compare_objects
		end

	section_nodes_cache: HASH_TABLE [GLM_SECTION_NODE, STRING_32]
			-- Process-wide section AST node cache
		once
			create Result.make (100)
			Result.compare_objects
		end

	reserved_names_set: GLM_HASH_SET [STRING_32]
			-- Set of reserved names for loop metadata
		once
			create Result.make_equal (10)
			Result.put ("index")
			Result.put ("count")
			Result.put ("is_first")
			Result.put ("is_last")
			Result.put ("is_even")
			Result.put ("is_odd")
		end

end
