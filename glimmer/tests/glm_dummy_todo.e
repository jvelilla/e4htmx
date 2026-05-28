class
	GLM_DUMMY_TODO

create
	make

feature

	make (a_id: INTEGER; a_desc: STRING; a_comp: INTEGER)
		do
			id := a_id
			description := a_desc
			completed := a_comp
		end

	id: INTEGER assign set_id
	description: STRING assign set_description
	completed: INTEGER assign set_completed

	set_id (v: like id)
		do
			id := v
		end

	set_description (v: like description)
		do
			description := v
		end

	set_completed (v: like completed)
		do
			completed := v
		end

end
