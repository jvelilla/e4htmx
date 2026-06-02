note
	description: "Helper class responsible for reflection-based object and context dumps during development"

class
	GLM_DEBUG_RENDERER

inherit
	GLM_HTML_ESCAPER

feature -- Rendering

	render_dump (a_name: STRING_32; a_value: detachable ANY; a_buffer: STRING_32)
			-- Render a collapsible dump block for a single variable
		local
			l_type_name: STRING_32
		do
			a_buffer.append ("<details open style=%"margin: 10px 0; border: 1px solid #e2e8f0; border-radius: 6px; font-family: monospace; background: #f8fafc;%">%N")
			a_buffer.append ("  <summary style=%"cursor: pointer; padding: 10px; font-weight: bold; background: #edf2f7; border-bottom: 1px solid #e2e8f0; user-select: none;%">🔍 dump: ")
			a_buffer.append (escape_html (a_name))
			if a_value /= Void then
				l_type_name := a_value.generating_type.name.to_string_32
				a_buffer.append (" (" + escape_html (l_type_name) + ")")
			else
				a_buffer.append (" (Void)")
			end
			a_buffer.append ("</summary>%N")
			a_buffer.append ("  <div style=%"padding: 10px; overflow-x: auto;%">%N")
			
			if a_value = Void then
				a_buffer.append ("    <span style=%"color: #718096;%">Void</span>%N")
			else
				render_value_details (a_value, a_buffer)
			end
			
			a_buffer.append ("  </div>%N")
			a_buffer.append ("</details>%N")
		end

	render_context (a_context: GLM_RENDER_CONTEXT; a_buffer: STRING_32)
			-- Render a collapsible dump block for the entire context
		do
			a_buffer.append ("<details open style=%"margin: 10px 0; border: 1px solid #cbd5e0; border-radius: 6px; font-family: monospace; background: #f7fafc;%">%N")
			a_buffer.append ("  <summary style=%"cursor: pointer; padding: 10px; font-weight: bold; background: #e2e8f0; border-bottom: 1px solid #cbd5e0; user-select: none;%">🔍 dump_context</summary>%N")
			a_buffer.append ("  <div style=%"padding: 10px; overflow-x: auto;%">%N")
			
			a_buffer.append ("    <table style=%"width: 100%%; border-collapse: collapse; font-size: 13px;%">%N")
			a_buffer.append ("      <thead>%N")
			a_buffer.append ("        <tr style=%"border-bottom: 2px solid #cbd5e0; text-align: left;%">%N")
			a_buffer.append ("          <th style=%"padding: 8px;%">Variable</th>%N")
			a_buffer.append ("          <th style=%"padding: 8px;%">Type</th>%N")
			a_buffer.append ("          <th style=%"padding: 8px;%">Value</th>%N")
			a_buffer.append ("        </tr>%N")
			a_buffer.append ("      </thead>%N")
			a_buffer.append ("      <tbody>%N")
			
			render_context_variables (a_context, a_buffer)
			
			a_buffer.append ("      </tbody>%N")
			a_buffer.append ("    </table>%N")
			a_buffer.append ("  </div>%N")
			a_buffer.append ("</details>%N")
		end

feature {NONE} -- Value Type Checks

	is_basic_value (obj: ANY): BOOLEAN
			-- Is `obj` a basic type or string?
		do
			Result := attached {BOOLEAN} obj or else
				attached {INTEGER_8} obj or else
				attached {INTEGER_16} obj or else
				attached {INTEGER_32} obj or else
				attached {INTEGER_64} obj or else
				attached {INTEGER} obj or else
				attached {REAL_32} obj or else
				attached {REAL_64} obj or else
				attached {REAL} obj or else
				attached {DOUBLE} obj or else
				attached {CHARACTER_8} obj or else
				attached {CHARACTER_32} obj or else
				attached {CHARACTER} obj or else
				attached {POINTER} obj or else
				attached {READABLE_STRING_GENERAL} obj
		end

feature {NONE} -- Formatting Implementation

	render_context_variables (a_context: GLM_RENDER_CONTEXT; a_buffer: STRING_32)
		local
			l_keys: HASH_TABLE [BOOLEAN, STRING_32]
		do
			create l_keys.make (20)
			l_keys.compare_objects
			render_context_variables_recursive (a_context, l_keys, a_buffer)
		end

	render_context_variables_recursive (a_context: GLM_RENDER_CONTEXT; a_rendered_keys: HASH_TABLE [BOOLEAN, STRING_32]; a_buffer: STRING_32)
		local
			l_val: detachable ANY
			l_type_name: STRING_32
			l_row_style: STRING_32
			l_count: INTEGER
		do
			l_count := 0
			across a_context.variables as cursor loop
				if not a_rendered_keys.has (cursor.key) then
					a_rendered_keys.put (True, cursor.key)
					l_val := cursor.item
					
					if l_count \\ 2 = 0 then
						l_row_style := "background: #fafafb; border-bottom: 1px solid #e2e8f0;"
					else
						l_row_style := "background: #ffffff; border-bottom: 1px solid #e2e8f0;"
					end
					
					a_buffer.append ("        <tr style=%"" + l_row_style + "%">%N")
					a_buffer.append ("          <td style=%"padding: 8px; font-weight: bold; color: #4a5568;%">" + escape_html (cursor.key) + "</td>%N")
					if l_val /= Void then
						l_type_name := l_val.generating_type.name.to_string_32
						a_buffer.append ("          <td style=%"padding: 8px; color: #718096;%">" + escape_html (l_type_name) + "</td>%N")
						a_buffer.append ("          <td style=%"padding: 8px;%">")
						render_value_short (l_val, a_buffer)
						a_buffer.append ("</td>%N")
					else
						a_buffer.append ("          <td style=%"padding: 8px; color: #718096;%">Void</td>%N")
						a_buffer.append ("          <td style=%"padding: 8px; color: #a0aec0;%">Void</td>%N")
					end
					a_buffer.append ("        </tr>%N")
					l_count := l_count + 1
				end
			end
			
			if attached a_context.parent_context as parent then
				render_context_variables_recursive (parent, a_rendered_keys, a_buffer)
			end
		end

	render_value_short (obj: ANY; a_buffer: STRING_32)
		local
			l_internal: INTERNAL
			i: INTEGER
			l_val: detachable ANY
			l_first: BOOLEAN
		do
			if is_basic_value (obj) then
				if attached {READABLE_STRING_GENERAL} obj as s then
					a_buffer.append ("&quot;" + escape_html (s.to_string_32) + "&quot;")
				else
					a_buffer.append (escape_html (obj.out.to_string_32))
				end
			elseif attached {ITERABLE [detachable ANY]} obj as l_iterable then
				a_buffer.append ("[Collection of " + escape_html (obj.generating_type.name.to_string_32) + "]")
			else
				a_buffer.append ("[" + escape_html (obj.generating_type.name.to_string_32) + " ")
				create l_internal
				l_first := True
				from
					i := 1
				until
					i > l_internal.field_count (obj) or i > 4
				loop
					if not l_first then
						a_buffer.append (", ")
					end
					a_buffer.append (escape_html (l_internal.field_name (i, obj).to_string_32) + "=")
					l_val := l_internal.field (i, obj)
					if l_val /= Void then
						if is_basic_value (l_val) then
							if attached {READABLE_STRING_GENERAL} l_val as s then
								a_buffer.append ("&quot;" + escape_html (s.to_string_32) + "&quot;")
							else
								a_buffer.append (escape_html (l_val.out.to_string_32))
							end
						else
							a_buffer.append ("...")
						end
					else
						a_buffer.append ("Void")
					end
					l_first := False
					i := i + 1
				end
				if l_internal.field_count (obj) > 4 then
					a_buffer.append (", ...")
				end
				a_buffer.append ("]")
			end
		end

	render_value_details (obj: ANY; a_buffer: STRING_32)
		local
			l_internal: INTERNAL
			i: INTEGER
			l_val: detachable ANY
			l_row_style: STRING_32
			l_count: INTEGER
		do
			if is_basic_value (obj) then
				a_buffer.append ("<pre style=%"margin: 0; padding: 5px; font-size: 14px;%">")
				if attached {READABLE_STRING_GENERAL} obj as s then
					a_buffer.append ("&quot;" + escape_html (s.to_string_32) + "&quot;")
				else
					a_buffer.append (escape_html (obj.out.to_string_32))
				end
				a_buffer.append ("</pre>%N")
			elseif attached {ITERABLE [detachable ANY]} obj as l_iterable then
				render_collection_details (l_iterable, a_buffer)
			else
				a_buffer.append ("    <table style=%"width: 100%%; border-collapse: collapse; font-size: 13px;%">%N")
				a_buffer.append ("      <thead>%N")
				a_buffer.append ("        <tr style=%"border-bottom: 2px solid #e2e8f0; text-align: left;%">%N")
				a_buffer.append ("          <th style=%"padding: 8px;%">Field</th>%N")
				a_buffer.append ("          <th style=%"padding: 8px;%">Type</th>%N")
				a_buffer.append ("          <th style=%"padding: 8px;%">Value</th>%N")
				a_buffer.append ("        </tr>%N")
				a_buffer.append ("      </thead>%N")
				a_buffer.append ("      <tbody>%N")
				
				create l_internal
				l_count := 0
				from
					i := 1
				until
					i > l_internal.field_count (obj)
				loop
					l_val := l_internal.field (i, obj)
					if l_count \\ 2 = 0 then
						l_row_style := "background: #fafafb; border-bottom: 1px solid #e2e8f0;"
					else
						l_row_style := "background: #ffffff; border-bottom: 1px solid #e2e8f0;"
					end
					
					a_buffer.append ("        <tr style=%"" + l_row_style + "%">%N")
					a_buffer.append ("          <td style=%"padding: 8px; font-weight: bold; color: #4a5568;%">" + escape_html (l_internal.field_name (i, obj).to_string_32) + "</td>%N")
					if l_val /= Void then
						a_buffer.append ("          <td style=%"padding: 8px; color: #718096;%">" + escape_html (l_val.generating_type.name.to_string_32) + "</td>%N")
						a_buffer.append ("          <td style=%"padding: 8px;%">")
						render_value_short (l_val, a_buffer)
						a_buffer.append ("</td>%N")
					else
						a_buffer.append ("          <td style=%"padding: 8px; color: #718096;%">Void</td>%N")
						a_buffer.append ("          <td style=%"padding: 8px; color: #a0aec0;%">Void</td>%N")
					end
					a_buffer.append ("        </tr>%N")
					l_count := l_count + 1
					i := i + 1
				end
				
				a_buffer.append ("      </tbody>%N")
				a_buffer.append ("    </table>%N")
			end
		end

	render_collection_details (l_iterable: ITERABLE [detachable ANY]; a_buffer: STRING_32)
		local
			l_items: ARRAYED_LIST [detachable ANY]
			l_first_item: detachable ANY
			l_internal: INTERNAL
			i, j: INTEGER
			l_val: detachable ANY
			l_row_style: STRING_32
		do
			create l_items.make (50)
			across l_iterable as cursor loop
				if l_items.count < 50 then
					l_items.extend (cursor.item)
				end
			end
			
			if l_items.is_empty then
				a_buffer.append ("    <span style=%"color: #718096; font-style: italic;%">Empty collection</span>%N")
			else
				l_first_item := Void
				from
					i := 1
				until
					i > l_items.count or l_first_item /= Void
				loop
					l_first_item := l_items.i_th (i)
					i := i + 1
				end
				
				if l_first_item = Void then
					a_buffer.append ("    <span style=%"color: #718096; font-style: italic;%">Collection contains only Void values</span>%N")
				elseif is_basic_value (l_first_item) then
					a_buffer.append ("    <table style=%"width: 100%%; border-collapse: collapse; font-size: 13px;%">%N")
					a_buffer.append ("      <thead>%N")
					a_buffer.append ("        <tr style=%"border-bottom: 2px solid #e2e8f0; text-align: left;%">%N")
					a_buffer.append ("          <th style=%"padding: 8px; width: 60px;%">Index</th>%N")
					a_buffer.append ("          <th style=%"padding: 8px;%">Value</th>%N")
					a_buffer.append ("        </tr>%N")
					a_buffer.append ("      </thead>%N")
					a_buffer.append ("      <tbody>%N")
					
					from
						i := 1
					until
						i > l_items.count
					loop
						l_val := l_items.i_th (i)
						if i \\ 2 = 1 then
							l_row_style := "background: #fafafb; border-bottom: 1px solid #e2e8f0;"
						else
							l_row_style := "background: #ffffff; border-bottom: 1px solid #e2e8f0;"
						end
						
						a_buffer.append ("        <tr style=%"" + l_row_style + "%">%N")
						a_buffer.append ("          <td style=%"padding: 8px; color: #718096;%">" + i.out + "</td>%N")
						a_buffer.append ("          <td style=%"padding: 8px;%">")
						if l_val /= Void then
							render_value_short (l_val, a_buffer)
						else
							a_buffer.append ("Void")
						end
						a_buffer.append ("</td>%N")
						a_buffer.append ("        </tr>%N")
						i := i + 1
					end
					a_buffer.append ("      </tbody>%N")
					a_buffer.append ("    </table>%N")
				else
					create l_internal
					if l_internal.field_count (l_first_item) = 0 then
						a_buffer.append ("    <table style=%"width: 100%%; border-collapse: collapse; font-size: 13px;%">%N")
						a_buffer.append ("      <thead>%N")
						a_buffer.append ("        <tr style=%"border-bottom: 2px solid #e2e8f0; text-align: left;%">%N")
						a_buffer.append ("          <th style=%"padding: 8px; width: 60px;%">Index</th>%N")
						a_buffer.append ("          <th style=%"padding: 8px;%">Object</th>%N")
						a_buffer.append ("        </tr>%N")
						a_buffer.append ("      </thead>%N")
						a_buffer.append ("      <tbody>%N")
						
						from
							i := 1
						until
							i > l_items.count
						loop
							l_val := l_items.i_th (i)
							if i \\ 2 = 1 then
								l_row_style := "background: #fafafb; border-bottom: 1px solid #e2e8f0;"
							else
								l_row_style := "background: #ffffff; border-bottom: 1px solid #e2e8f0;"
							end
							
							a_buffer.append ("        <tr style=%"" + l_row_style + "%">%N")
							a_buffer.append ("          <td style=%"padding: 8px; color: #718096;%">" + i.out + "</td>%N")
							a_buffer.append ("          <td style=%"padding: 8px;%">")
							if l_val /= Void then
								render_value_short (l_val, a_buffer)
							else
								a_buffer.append ("Void")
							end
							a_buffer.append ("</td>%N")
							a_buffer.append ("        </tr>%N")
							i := i + 1
						end
						a_buffer.append ("      </tbody>%N")
						a_buffer.append ("    </table>%N")
					else
						a_buffer.append ("    <table style=%"width: 100%%; border-collapse: collapse; font-size: 13px;%">%N")
						a_buffer.append ("      <thead>%N")
						a_buffer.append ("        <tr style=%"border-bottom: 2px solid #e2e8f0; text-align: left;%">%N")
						a_buffer.append ("          <th style=%"padding: 8px; width: 60px;%">Index</th>%N")
						
						from
							j := 1
						until
							j > l_internal.field_count (l_first_item)
						loop
							a_buffer.append ("          <th style=%"padding: 8px;%">" + escape_html (l_internal.field_name (j, l_first_item).to_string_32) + "</th>%N")
							j := j + 1
						end
						a_buffer.append ("        </tr>%N")
						a_buffer.append ("      </thead>%N")
						a_buffer.append ("      <tbody>%N")
						
						from
							i := 1
						until
							i > l_items.count
						loop
							l_val := l_items.i_th (i)
							if i \\ 2 = 1 then
								l_row_style := "background: #fafafb; border-bottom: 1px solid #e2e8f0;"
							else
								l_row_style := "background: #ffffff; border-bottom: 1px solid #e2e8f0;"
							end
							
							a_buffer.append ("        <tr style=%"" + l_row_style + "%">%N")
							a_buffer.append ("          <td style=%"padding: 8px; color: #718096;%">" + i.out + "</td>%N")
							
							if l_val /= Void then
								from
									j := 1
								until
									j > l_internal.field_count (l_first_item)
								loop
									l_val := resolve_field (l_items.i_th (i), l_internal.field_name (j, l_first_item))
									a_buffer.append ("          <td style=%"padding: 8px;%">")
									if l_val /= Void then
										render_value_short (l_val, a_buffer)
									else
										a_buffer.append ("Void")
									end
									a_buffer.append ("</td>%N")
									j := j + 1
								end
							else
								from
									j := 1
								until
									j > l_internal.field_count (l_first_item)
								loop
									a_buffer.append ("          <td style=%"padding: 8px; color: #a0aec0;%">Void</td>%N")
									j := j + 1
								end
							end
							a_buffer.append ("        </tr>%N")
							i := i + 1
						end
						a_buffer.append ("      </tbody>%N")
						a_buffer.append ("    </table>%N")
					end
				end
			end
		end

	resolve_field (obj: detachable ANY; field_name: STRING_8): detachable ANY
		local
			l_internal: INTERNAL
			i: INTEGER
			l_found: BOOLEAN
		do
			if obj /= Void then
				create l_internal
				from
					i := 1
				until
					i > l_internal.field_count (obj) or l_found
				loop
					if l_internal.field_name (i, obj).as_lower ~ field_name.as_lower then
						Result := l_internal.field (i, obj)
						l_found := True
					end
					i := i + 1
				end
			end
		end

end
