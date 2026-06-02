note
	description: "Represent a Pokemon species entry"

class
	POKEMON

create
	make

feature -- Initialization

	make (a_name: READABLE_STRING_8; a_url: READABLE_STRING_8)
			-- Initialize the Pokemon with name and url, and compute ID and image URL.
		do
			create name.make_from_string (a_name)
			create url.make_from_string (a_url)
			id := extract_id (a_url)
			image_url := "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/" + id + ".png"
		end

feature -- Access

	name: STRING_8
			-- Species name

	url: STRING_8
			-- API url reference

	id: STRING_8
			-- Pokemon integer identifier

	image_url: STRING_8
			-- Calculated sprite image URL

feature {NONE} -- Implementation

	extract_id (a_url: READABLE_STRING_8): STRING_8
			-- Extract Pokemon ID from URL (e.g., https://pokeapi.co/api/v2/pokemon-species/1/).
		local
			l_parts: LIST [like a_url]
		do
			l_parts := a_url.split ('/')
			create Result.make_empty
			across
				l_parts as p
			loop
				if not p.item.is_empty and then p.item.is_integer then
					create Result.make_from_string (p.item)
				end
			end
		end

end
