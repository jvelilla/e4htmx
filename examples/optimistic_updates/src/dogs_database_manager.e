note
	description: "Database manager for dog breeds in optimistic updates example"

class
	DOGS_DATABASE_MANAGER

inherit
	SQLITE_SHARED_API

feature -- Database Connection

	db: SQLITE_DATABASE
			-- Shared database instance
		local
			l_modify: SQLITE_MODIFY_STATEMENT
			l_query: SQLITE_QUERY_STATEMENT
			has_dogs_table: BOOLEAN
			l_names: ARRAY [STRING_32]
			l_name: STRING_32
		once
			create Result.make_create_read_write ("dogs.sqlite")

			-- Check if dogs table exists
			create l_query.make ("SELECT name FROM sqlite_master WHERE type='table' AND name='dogs';", Result)
			has_dogs_table := False
			across l_query.execute_new as c loop
				has_dogs_table := True
			end

			-- Create dogs table if it doesn't exist
			if not has_dogs_table then
				create l_modify.make (
					"[
						CREATE TABLE IF NOT EXISTS dogs (
							breed TEXT PRIMARY KEY,
							is_liked INTEGER DEFAULT 0
						);
					]",
					Result
				)
				l_modify.execute

				-- Insert initial rows
				l_names := <<
					{STRING_32} "Beagle", {STRING_32} "Bulldog", {STRING_32} "Dachshund",
					{STRING_32} "French Bulldog", {STRING_32} "German Shepard",
					{STRING_32} "German Shorthaired Pointer", {STRING_32} "Golden Retriever",
					{STRING_32} "Labrador", {STRING_32} "Poodle", {STRING_32} "Rottweiler",
					{STRING_32} "Whippet"
				>>
				
				across l_names as name loop
					l_name := name.item
					create l_modify.make ("INSERT INTO dogs (breed, is_liked) VALUES (:BREED, 0);", Result)
					l_modify.execute_with_arguments (<<create {SQLITE_STRING_ARG}.make (":BREED", l_name.to_string_8)>>)
				end
			end
		end

feature -- Queries

	retrieve_all: LIST [DOG_BREED]
			-- Retrieve all dog breeds from database sorted by name
		local
			l_query: SQLITE_QUERY_STATEMENT
		do
			create {ARRAYED_LIST [DOG_BREED]} last_retrieve_all_result.make (0)
			create {ARRAYED_LIST [DOG_BREED]} Result.make (0)
			create l_query.make ("SELECT breed, is_liked FROM dogs ORDER BY breed ASC;", db)
			check l_query_is_compiled: l_query.is_compiled end

			l_query.execute (agent (ia_row: SQLITE_RESULT_ROW): BOOLEAN
				local
					l_breed: DOG_BREED
					l_is_liked: BOOLEAN
				do
					l_is_liked := ia_row.integer_value (2) = 1
					create l_breed.make (ia_row.string_value (1), l_is_liked)
					if attached last_retrieve_all_result as lr then
						lr.force (l_breed)
					end
				end)
			if attached last_retrieve_all_result as lr then
				Result := lr
			end
		end

	retrieve_by_breed (a_breed_name: READABLE_STRING_GENERAL): detachable DOG_BREED
			-- Retrieve a dog breed by its name
		local
			l_query: SQLITE_QUERY_STATEMENT
		do
			last_retrieve_result := Void
			create l_query.make ("SELECT breed, is_liked FROM dogs WHERE breed = :BREED;", db)
			check l_query_is_compiled: l_query.is_compiled end

			l_query.execute_with_arguments (
				agent (ia_row: SQLITE_RESULT_ROW): BOOLEAN
					local
						l_breed: DOG_BREED
						l_is_liked: BOOLEAN
					do
						if not ia_row.is_null (1) then
							l_is_liked := ia_row.integer_value (2) = 1
							create l_breed.make (ia_row.string_value (1), l_is_liked)
							last_retrieve_result := l_breed
						end
					end,
				<<create {SQLITE_STRING_ARG}.make (":BREED", a_breed_name.to_string_8)>>
			)
			Result := last_retrieve_result
		end

feature -- Updates

	toggle_like (a_breed_name: READABLE_STRING_GENERAL): detachable DOG_BREED
			-- Toggle liked status of a breed and return it
		local
			l_modify: SQLITE_MODIFY_STATEMENT
			l_breed: detachable DOG_BREED
			l_new_liked: INTEGER
		do
			l_breed := retrieve_by_breed (a_breed_name)
			if attached l_breed as b then
				if b.is_liked then
					l_new_liked := 0
				else
					l_new_liked := 1
				end

				create l_modify.make ("UPDATE dogs SET is_liked = :LIKED WHERE breed = :BREED;", db)
				check l_modify_is_compiled: l_modify.is_compiled end

				db.begin_transaction (False)
				l_modify.execute_with_arguments (<<
					create {SQLITE_INTEGER_ARG}.make (":LIKED", l_new_liked),
					create {SQLITE_STRING_ARG}.make (":BREED", a_breed_name.to_string_8)
				>>)
				db.commit

				-- Return updated object
				create Result.make (b.breed, l_new_liked = 1)
			end
		end

feature {NONE} -- Implementation

	last_retrieve_all_result: detachable LIST [DOG_BREED]
			-- Temp storage for query callbacks

	last_retrieve_result: detachable DOG_BREED
			-- Temp storage for query callbacks

end
