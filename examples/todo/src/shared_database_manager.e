note
    description: "Database manager for TODO items"

class
    SHARED_DATABASE_MANAGER

inherit
    SQLITE_SHARED_API

feature -- Database Manager

    db: SQLITE_DATABASE
            -- Shared database instance
        local
            l_modify: SQLITE_MODIFY_STATEMENT
            l_query: SQLITE_QUERY_STATEMENT
            has_todos_table: BOOLEAN
        once
            create Result.make_create_read_write ("todos.sqlite")

            	-- Check if todos table exists
            create l_query.make ("SELECT name FROM sqlite_master ORDER BY name;", Result)
            across l_query.execute_new as c loop
                if c.item.count >= 1 and then attached c.item.string_value (1) as l_table_name then
                    if l_table_name.is_case_insensitive_equal ("todos") then
                        has_todos_table := True
                    end
                end
            end

            	-- Create todos table if it doesn't exist
            if not has_todos_table then
                create l_modify.make (
                    "[
                        CREATE TABLE IF NOT EXISTS todos (
                            id INTEGER PRIMARY KEY AUTOINCREMENT,
                            description STRING NOT NULL,
                            completed NUMERIC DEFAULT 0,
                            UNIQUE (description COLLATE NOCASE)
                        );
                    ]",
                    Result
                )
                l_modify.execute

                    -- Insert initial rows
                create l_modify.make ("INSERT INTO todos (description, completed) VALUES ('cut grass', 0);", Result)
                l_modify.execute
                create l_modify.make ("INSERT INTO todos (description, completed) VALUES ('buy milk', 0);", Result)
                l_modify.execute

                    -- Verify insertions
                create l_query.make ("SELECT * FROM todos;", Result)
                across l_query.execute_new as c loop
                    print ("ID: " + c.item.integer_value (1).out + ", Description: " + c.item.string_value (2) +
                          ", Completed: " + c.item.integer_value (3).out + "%N")
                end
            end
        end

    clean_db
            -- Clean the database
        local
            l_query: SQLITE_QUERY_STATEMENT
            l_delete: SQLITE_MODIFY_STATEMENT
            l_db: SQLITE_DATABASE
        do
            create l_db.make_create_read_write ("todos.sqlite")
            create l_query.make ("SELECT name FROM sqlite_master ORDER BY name;", l_db)

            across l_query.execute_new as c loop
                if c.item.count >= 1 and then attached c.item.string_value (1) as l_table_name then
                    create l_delete.make ("DELETE FROM " + l_table_name + ";", db)
                    check l_delete_is_compiled: l_delete.is_compiled end
                    l_delete.execute
                end
            end
        end
end
