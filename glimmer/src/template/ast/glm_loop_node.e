note
	description: "AST node representing a loop/iteration construct over an ITERABLE collection"

class
	GLM_LOOP_NODE

inherit
	GLM_TEMPLATE_NODE

create
	make

feature {NONE} -- Initialization

	make (a_iterator: READABLE_STRING_GENERAL; a_collection: READABLE_STRING_GENERAL; a_body: ARRAYED_LIST [GLM_TEMPLATE_NODE])
			-- Initialize loop node
		do
			create iterator_name.make_from_string (a_iterator.to_string_32)
			create collection_name.make_from_string (a_collection.to_string_32)
			body := a_body
		ensure
			iterator_set: iterator_name.same_string_general (a_iterator)
			collection_set: collection_name.same_string_general (a_collection)
			body_set: body = a_body
		end

feature -- Access

	iterator_name: STRING_32
			-- Name of the iterator variable

	collection_name: STRING_32
			-- Name of the collection variable

	body: ARRAYED_LIST [GLM_TEMPLATE_NODE]
			-- Body nodes to execute during iteration

feature -- Rendering

	render (a_context: GLM_RENDER_CONTEXT; a_buffer: STRING_32)
			-- Pre-collect collection, build sub-scopes, and render body for each item
		local
			l_val: detachable ANY
			l_items: ARRAYED_LIST [ANY]
			l_index: INTEGER
			l_total: INTEGER
			sub_context: GLM_RENDER_CONTEXT
		do
			if a_context.has (collection_name) then
				l_val := a_context.item (collection_name)
				if attached {ITERABLE [ANY]} l_val as l_iter then
					-- Pre-collect to avoid double iteration (correctness + database safety)
					if attached {FINITE [ANY]} l_val as l_finite then
						create l_items.make (l_finite.count)
					else
						create l_items.make (10)
					end
					across l_iter as item loop
						l_items.extend (item.item)
					end
					
					l_total := l_items.count
					if l_total > 0 then
						-- Create sub-context once and reuse it for all iterations
						create sub_context.make_sub (a_context)
						from
							l_index := 1
						until
							l_index > l_total
						loop
							sub_context.variables.wipe_out
							
							-- Bind iterator variable and loop metadata
							sub_context.variables.force (l_items.i_th (l_index), iterator_name)
							sub_context.variables.force (l_index, "index")
							sub_context.variables.force (l_total, "count")
							sub_context.variables.force (l_index = 1, "is_first")
							sub_context.variables.force (l_index = l_total, "is_last")
							sub_context.variables.force ((l_index \\ 2) = 0, "is_even")
							sub_context.variables.force ((l_index \\ 2) = 1, "is_odd")
							
							-- Render loop body
							across body as node loop
								node.item.render (sub_context, a_buffer)
							end
							
							l_index := l_index + 1
						end
					end
				end
			end
		end

end
