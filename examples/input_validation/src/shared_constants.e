note
    description: "Shared constants for validation"
    date: "$Date$"
    revision: "$Revision$"

class
    SHARED_CONSTANTS

feature -- Access

    bad_passwords: LIST [STRING]
            -- List of commonly used passwords that should be rejected
        do
            create {ARRAYED_LIST [STRING]} Result.make_from_array (<<
                "password",
                "12345678"
            >>)
            Result.compare_objects
        ensure
            instance_free: class
        end

    existing_emails: LIST [STRING]
            -- List of email addresses that are already in use
        do
            create {ARRAYED_LIST [STRING]} Result.make_from_array (<<
                "old@aol.com",
                "existing@gmail.com",
                "test@hotmail.com"
            >>)
            Result.compare_objects
        ensure
           instance_free: class
        end

end
