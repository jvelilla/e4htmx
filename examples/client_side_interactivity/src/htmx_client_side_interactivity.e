note
    description: "Launcher for Adding Headers example"

class
    HTMX_CLIENT_SIDE_INTERACTIVITY
inherit
    WSF_LAUNCHABLE_SERVICE
        redefine
            initialize
        end
    APPLICATION_LAUNCHER [HTMX_CLIENT_SIDE_INTERACTIVITY_EXECUTION]

create
    make_and_launch

feature {NONE} -- Initialization
    initialize
            -- Initialize current service.
        do
            Precursor
            set_service_option ("port", 9099)
            set_service_option ("verbose", "yes")
        end
end
