note
	description: "Dog breed with liked status for optimistic updates example."

class
	DOG_BREED

create
	make

feature {NONE} -- Initialization

	make (a_breed: READABLE_STRING_GENERAL; a_is_liked: BOOLEAN)
			-- Initialize with `a_breed` name and `a_is_liked` status.
		do
			breed := a_breed.to_string_32
			is_liked := a_is_liked
			update_heart_html
		ensure
			breed_set: breed ~ a_breed.to_string_32
			is_liked_set: is_liked = a_is_liked
		end

feature -- Access

	breed: STRING_32
			-- Name of the breed

	is_liked: BOOLEAN
			-- Is this breed liked?

	heart_html: STRING_32
			-- HTML representation of the heart

feature -- Element change

	set_liked (a_is_liked: BOOLEAN)
			-- Set liked status to `a_is_liked`.
		do
			is_liked := a_is_liked
			update_heart_html
		ensure
			is_liked_set: is_liked = a_is_liked
		end

feature {NONE} -- Helper

	update_heart_html
			-- Update heart HTML based on liked status.
		do
			if is_liked then
				heart_html := {STRING_32} "&#x1F496;" --"&#x2764;"
			else
				heart_html := {STRING_32} "&#x1F90D;"
			end
		ensure
			heart_html_updated: (is_liked implies heart_html ~ {STRING_32} "&#x2764;") and (not is_liked implies heart_html ~ {STRING_32} "&#x1F90D;")
		end

end
