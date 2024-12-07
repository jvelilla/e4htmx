note
	description: "Summary description for {SHARED_SERVICES}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	SHARED_SERVICES


feature -- Counter

	shared_dogs: STRING_TABLE[DOG]
            -- An object that can be shared among threads
            -- without being reinitialized.
        once
            create Result.make (1)
         	Result.compare_objects
        end
end
