note
    description: "Shared access to database API."

class
    SHARED_DATABASE_API

feature -- API

    todo_mgr: TODO_MANAGER
            -- Shared access to todo manager
        once
            create Result
        end

    clean
            -- Clean the database
        do
            (create {SHARED_DATABASE_MANAGER}).clean_db
        end
end
