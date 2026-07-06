note
    description: "[
                application service
            ]"
    date: "$Date$"
    revision: "$Revision$"
class
    HTMX_polling
inherit
    WSF_LAUNCHABLE_SERVICE
        redefine
            initialize
        end
    APPLICATION_LAUNCHER [HTMX_polling_EXECUTION]

create
    make_and_launch

feature {NONE} -- Initialization

    initialize
            -- Initialize current service.
        do
            Precursor
            set_service_option ("port", 9091)
            set_service_option ("verbose", "yes")
        end
end
