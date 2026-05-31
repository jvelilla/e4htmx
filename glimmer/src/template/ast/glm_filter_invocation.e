note
	description: "Represents a filter invocation with a name and arguments"

class
	GLM_FILTER_INVOCATION

create
	make

feature {NONE} -- Initialization

	make (a_name: READABLE_STRING_GENERAL; a_args: ARRAYED_LIST [STRING_32])
			-- Initialize filter invocation
		do
			create name.make_from_string (a_name.to_string_32)
			args := a_args
		ensure
			name_set: name.same_string_general (a_name)
			args_set: args = a_args
		end

feature -- Access

	name: STRING_32
			-- Filter name

	args: ARRAYED_LIST [STRING_32]
			-- Filter raw arguments

end
