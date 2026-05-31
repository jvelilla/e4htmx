note
	description: "AST node representing a variable placeholder like {name} or {raw:name} with optional filters"

class
	GLM_VARIABLE_NODE

inherit
	GLM_TEMPLATE_NODE

create
	make

feature {NONE} -- Initialization

	make (a_name: READABLE_STRING_GENERAL; a_is_raw: BOOLEAN; a_filters: detachable ARRAYED_LIST [GLM_FILTER_INVOCATION])
			-- Initialize variable node
		do
			create name.make_from_string (a_name.to_string_32)
			is_raw := a_is_raw
			filters := a_filters
		ensure
			name_set: name.same_string_general (a_name)
			is_raw_set: is_raw = a_is_raw
			filters_set: filters = a_filters
		end

feature -- Access

	name: STRING_32
			-- Variable name

	is_raw: BOOLEAN
			-- Should HTML escaping be bypassed?

	filters: detachable ARRAYED_LIST [GLM_FILTER_INVOCATION]
			-- Optional chain of filters to apply

feature -- Rendering

	render (a_context: GLM_RENDER_CONTEXT; a_buffer: STRING_32)
			-- Resolve, apply filters, and append variable value to buffer
		local
			l_val: detachable ANY
			l_resolved: STRING_32
			l_filter_val: detachable ANY
		do
			if a_context.has (name) then
				l_val := a_context.item (name)
				
				-- Apply filter chain if present
				if attached filters as l_filters and then not l_filters.is_empty then
					l_filter_val := l_val
					across l_filters as filter_cursor loop
						l_filter_val := apply_filter (filter_cursor.item, l_filter_val, a_context)
					end
					l_val := l_filter_val
				end
				
				if attached l_val as val then
					create l_resolved.make_from_string (val.out.to_string_32)

					-- Apply HTML escaping if needed
					if a_context.auto_escape and not is_raw then
						l_resolved := a_context.escape_html (l_resolved)
					end
					a_buffer.append (l_resolved)
				end
			else
				-- Variable not found - leave the placeholder as is
				a_buffer.append_character ('{')
				if is_raw then
					a_buffer.append ("raw:")
				end
				a_buffer.append (name)
				if attached filters as l_filters then
					across l_filters as filter_cursor loop
						a_buffer.append (" | ")
						a_buffer.append (filter_cursor.item.name)
						if not filter_cursor.item.args.is_empty then
							a_buffer.append_character (':')
							across filter_cursor.item.args as arg_cursor loop
								a_buffer.append_character (' ')
								a_buffer.append (arg_cursor.item)
							end
						end
					end
				end
				a_buffer.append_character ('}')
			end
		end

feature {NONE} -- Filter Application

	apply_filter (a_filter: GLM_FILTER_INVOCATION; a_val: detachable ANY; a_context: GLM_RENDER_CONTEXT): detachable ANY
			-- Apply `a_filter` to `a_val` using registries in `a_context`
		local
			l_agent: detachable FUNCTION [TUPLE, STRING_32]
			l_args: ARRAYED_LIST [ANY]
			l_tuple: TUPLE
		do
			if a_context.filter_registry.has (a_filter.name) then
				l_agent := a_context.filter_registry.item (a_filter.name)
			elseif a_context.helper_registry.has (a_filter.name) then
				l_agent := a_context.helper_registry.item (a_filter.name)
			end
			
			if attached l_agent as agent_obj then
				create l_args.make (a_filter.args.count)
				across a_filter.args as arg_cursor loop
					l_args.extend (parse_argument (arg_cursor.item, a_context))
				end
				l_tuple := create_tuple (a_val, l_args)
				Result := agent_obj.flexible_item (l_tuple)
			else
				Result := a_val
			end
		end

	parse_argument (a_arg_str: STRING_32; a_context: GLM_RENDER_CONTEXT): ANY
			-- Parse argument from string, stripping quotes or resolving variables
		local
			l_str: STRING_32
			l_val: ANY
		do
			create l_str.make_from_string (a_arg_str)
			l_str.left_adjust
			l_str.right_adjust
			if l_str.count >= 2 and then
				((l_str.item (1) = '"' and then l_str.item (l_str.count) = '"') or else
				 (l_str.item (1) = '%'' and then l_str.item (l_str.count) = '%'')) then
				Result := l_str.substring (2, l_str.count - 1)
			else
				l_val := a_context.resolve_value (l_str)
				if attached {INTEGER_8} l_val as i8 then
					Result := i8.to_integer_32
				elseif attached {INTEGER_16} l_val as i16 then
					Result := i16.to_integer_32
				elseif attached {INTEGER_64} l_val as i64 then
					Result := i64.to_integer_32
				else
					Result := l_val
				end
			end
		end

	create_tuple (a_val: detachable ANY; a_args: ARRAYED_LIST [ANY]): TUPLE
			-- Dynamically build a type-safe TUPLE for agent invocation
		do
			inspect a_args.count
			when 0 then
				Result := [a_val]
			when 1 then
				Result := [a_val, a_args.first]
			when 2 then
				Result := [a_val, a_args.first, a_args.i_th (2)]
			when 3 then
				Result := [a_val, a_args.first, a_args.i_th (2), a_args.i_th (3)]
			else
				Result := [a_val]
			end
		end

end
