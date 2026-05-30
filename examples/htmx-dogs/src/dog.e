note
	description: "Dog domain model."
	date: "$Date$"
	revision: "$Revision$"

class
	DOG

create
	make

feature {NONE} -- Initialization

	make (a_id: like id; a_name: like name; a_breed: like breed)
			-- Initialize with `a_id`, `a_name`, `a_breed`.
		do
			id := a_id
			name := a_name
			breed := a_breed
		ensure
			id_set: id = a_id
			name_set: name = a_name
			breed_set: breed = a_breed
		end

feature -- Access

	id: STRING_32 assign set_id
			-- Unique identifier for the dog.

	name: STRING_32 assign set_name
			-- Name of the dog.

	breed: STRING_32 assign set_breed
			-- Breed of the dog.

feature -- Element change

	set_name (v: like name)
			-- Assign `name` with `v`.
		do
			name := v
		ensure
			name_assigned: name = v
		end

	set_breed (v: like breed)
			-- Assign `breed` with `v`.
		do
			breed := v
		ensure
			breed_assigned: breed = v
		end

	set_id (v: like id)
			-- Assign `id` with `v`.
		do
			id := v
		ensure
			id_assigned: id = v
		end

end
