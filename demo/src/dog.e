note
	description: "Summary description for {DOG}."
	date: "$Date$"
	revision: "$Revision$"

class
	DOG


create
	make

feature {NONE} -- Initialization

	make (n: like name; b: like breed)
			-- Initialize with `n` for `name`, `b` for `breed`.
		local
			l_uuid: UUID
		do
			create l_uuid.make_from_string (n + b)
			id := l_uuid.string
			name := n
			breed := b
		ensure
			name_set: name = n
			breed_set: breed = b
		end

feature -- Access

	id: STRING_32 assign set_id

	name: STRING_32 assign set_name

	breed: STRING_32 assign set_breed

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
