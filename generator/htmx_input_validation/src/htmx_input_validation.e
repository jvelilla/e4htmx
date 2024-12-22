note
    description: "[
                application service
            ]"
    date: "$Date$"
    revision: "$Revision$"
class
    htmx_input_validation
inherit
    WSF_LAUNCHABLE_SERVICE
        redefine
            initialize
        end
    APPLICATION_LAUNCHER [htmx_input_validation_EXECUTION]
create
    make_and_launch
feature {NONE} -- Initialization
    initialize
            -- Initialize current service.
        do
            Precursor
            set_service_option ("port", 9090)
            set_service_option ("verbose", "yes")
        end
end 
