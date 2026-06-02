note
	description: "JSON to POKEMON object converter"

class
	JSON_POKEMON_CONVERTER

feature -- Conversion

	from_json (a_json: JSON_OBJECT): detachable POKEMON
			-- Create a new POKEMON instance from JSON object.
		do
			if attached {JSON_STRING} a_json.item ("name") as l_name and then
			   attached {JSON_STRING} a_json.item ("url") as l_url then
				create Result.make (l_name.item, l_url.item)
			end
		end

	from_json_array (a_json_array: JSON_ARRAY): ARRAYED_LIST [POKEMON]
			-- Create a list of Pokemon from JSON array.
		local
			l_pokemon: POKEMON
		do
			create Result.make (a_json_array.count)
			across
				a_json_array as ic
			loop
				if attached {JSON_OBJECT} ic.item as json_object then
					l_pokemon := from_json (json_object)
					if attached l_pokemon then
						Result.extend (l_pokemon)
					end
				end
			end
		end

end
