note
    description: "Manager for TODO items"

class
    TODO_MANAGER

inherit
    SHARED_DATABASE_MANAGER

feature -- Query

    retrieve_by_id (an_id: INTEGER): detachable TODO
            -- Retrieve todo by id from database
        local
            l_query: SQLITE_QUERY_STATEMENT
        do
        		-- clean all the previous results
			last_retrieve_by_id_result := Void

            create l_query.make (
                "SELECT id, description, completed FROM todos WHERE id = :TODO_ID;",
                db
            )
            check l_query_is_compiled: l_query.is_compiled end

            l_query.execute_with_arguments (
                agent (ia_row: SQLITE_RESULT_ROW): BOOLEAN
                    local
                        l_todo: TODO
                    do
                        if not ia_row.is_null (1) then
                            create l_todo.make (
                                ia_row.integer_value (1),
                                ia_row.string_value (2),
                                ia_row.integer_value (3)
                            )
                           last_retrieve_by_id_result := l_todo
                        end
                    end,
                <<create {SQLITE_INTEGER_ARG}.make (":TODO_ID", an_id)>>
            )
            Result := last_retrieve_by_id_result
        end

    retrieve_all: LIST [TODO]
            -- Retrieve all todos from database
        local
            l_query: SQLITE_QUERY_STATEMENT
            l_result: ARRAYED_LIST [TODO]
        do
            create {ARRAYED_LIST [TODO]} last_retrieve_all_result.make (0)
            create {ARRAYED_LIST [TODO]} Result.make (0)
            create l_query.make (
                "SELECT id, description, completed FROM todos;",
                db
            )
            check l_query_is_compiled: l_query.is_compiled end

            l_query.execute (agent (ia_row: SQLITE_RESULT_ROW): BOOLEAN
                local
                    l_todo: TODO
                do
                    create l_todo.make (
                        ia_row.integer_value (1),
                        ia_row.string_value (2),
                        ia_row.integer_value (3)
                    )
                   if attached last_retrieve_all_result as lr  then
                   		lr.force (l_todo)
                   end
                end)
            if attached last_retrieve_all_result as lr then
				Result := lr
			end
        end

    has_todo_with_description (a_description: READABLE_STRING_GENERAL): BOOLEAN
            -- Returns true if a todo with the given description exists
        local
            l_query: SQLITE_QUERY_STATEMENT
        do
        	last_counts := 0;
            create l_query.make (
                "SELECT COUNT(*) FROM todos WHERE description = :DESC;",
                db
            )
            check l_query_is_compiled: l_query.is_compiled end

            l_query.execute_with_arguments (
                agent (ia_row: SQLITE_RESULT_ROW): BOOLEAN
                    do
                        last_counts := ia_row.integer_value (1)
                    end,
                <<create {SQLITE_STRING_ARG}.make (":DESC", a_description.to_string_8)>>
            )
            if last_counts > 0 then
            	Result := True
            end
        end

feature -- Update

    save (a_todo: TODO)
            -- Save or update a todo
        local
            l_modify: SQLITE_MODIFY_STATEMENT
            l_array: ARRAY [ANY]
        do
            if a_todo.id = 0 then
                	-- Insert new todo
                create l_modify.make (
                    "INSERT INTO todos (description, completed) VALUES (:DESC, :COMP);",
                    db
                )
                l_array := <<
               		 create {SQLITE_STRING_ARG}.make (":DESC", a_todo.description),
               		 create {SQLITE_INTEGER_ARG}.make (":COMP", a_todo.completed)
            		>>
            else
                	-- Update existing todo
                create l_modify.make (
                    "UPDATE todos SET description = :DESC, completed = :COMP WHERE id = :ID;",
                    db
                )
               l_array := <<
               		 create {SQLITE_STRING_ARG}.make (":DESC", a_todo.description),
               		 create {SQLITE_INTEGER_ARG}.make (":COMP", a_todo.completed),
               		 create {SQLITE_INTEGER_ARG}.make (":ID", a_todo.id)
            	>>

            end

            check l_modify_is_compiled: l_modify.is_compiled end

            db.begin_transaction (False)
            l_modify.execute_with_arguments (l_array)
            db.commit
        end

feature -- Delete

    delete (an_id: INTEGER)
            -- Delete todo with given id
        local
            l_delete: SQLITE_MODIFY_STATEMENT
        do
            create l_delete.make (
                "DELETE FROM todos WHERE id = :ID;",
                db
            )
            check l_delete_is_compiled: l_delete.is_compiled end

            db.begin_transaction (False)
            l_delete.execute_with_arguments (<<
                create {SQLITE_INTEGER_ARG}.make (":ID", an_id)
            >>)
            db.commit
        end


feature {NONE} -- Implementation

	last_retrieve_all_result: detachable LIST [TODO]
	last_retrieve_by_id_result: detachable TODO
	last_row_id : INTEGER_64
	last_counts: INTEGER_64
end
