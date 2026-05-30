note
	description: "Shared database and state services for HTMX Dogs application."
	date: "$Date$"
	revision: "$Revision$"

class
	SHARED_DOG_SERVICES

feature -- Shared Storage

	shared_dogs: STRING_TABLE [DOG]
			-- Thread-safe (process-wide) shared database of dogs
		local
			l_dog: DOG
		once
			create Result.make (10)
			Result.compare_objects

			create l_dog.make ("00000000-0000-0000-0000-000000000001", "Comet", "Whippet")
			Result.force (l_dog, l_dog.id)

			create l_dog.make ("00000000-0000-0000-0000-000000000002", "Oscar", "German Shorthaired Pointer")
			Result.force (l_dog, l_dog.id)

			id_counter.put (2)
		end

	selected_id_cell: CELL [detachable STRING_32]
			-- Thread-safe (process-wide) cell holding currently selected dog ID (Void if none)
		once
			create Result.put (Void)
		end

	id_counter: CELL [INTEGER]
			-- Thread-safe (process-wide) auto-incrementing ID counter
		once
			create Result.put (0)
		end

feature -- Helper Operations

	add_dog (a_name: STRING_32; a_breed: STRING_32): DOG
			-- Add a new dog to the in-memory database
		local
			l_id: STRING_32
			l_counter: INTEGER
			l_dog: DOG
		do
			l_counter := id_counter.item + 1
			id_counter.put (l_counter)
			l_id := generate_formatted_uuid (l_counter)
			create l_dog.make (l_id, a_name, a_breed)
			shared_dogs.force (l_dog, l_id)
			Result := l_dog
		ensure
			dog_added: shared_dogs.has (Result.id)
		end

	generate_formatted_uuid (a_counter: INTEGER): STRING_32
			-- Generate a valid UUID format string from a counter
			-- format: "00000000-0000-0000-0000-XXXXXXXXXXXX"
		local
			l_count_str: STRING_32
			l_padding: STRING_32
		do
			l_count_str := a_counter.out.to_string_32
			create l_padding.make_filled ('0', 12 - l_count_str.count)
			Result := "00000000-0000-0000-0000-" + l_padding + l_count_str
		ensure
			result_length_ok: Result.count = 36
		end

end
