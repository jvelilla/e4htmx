note
	description: "[
				application service
			]"
	date: "$Date$"
	revision: "$Revision$"

class
	HTMX_DEMO


inherit
	WSF_LAUNCHABLE_SERVICE
		redefine
			initialize
		end
	APPLICATION_LAUNCHER [HTMX_DEMO_EXECUTION]


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

feature -- HTML Template Example

    show_template_example: STRING
        local
            l_template: HTML_TEMPLATE
            l_html: STRING
        do
            create l_template.make
            
            -- Set some variables
            l_template.set_variable ("title", "My Page")
            l_template.set_variable ("user_name", "John Doe")
            
            -- Create a template string
            l_html := "[
                <!DOCTYPE html>
                <html>
                <head>
                    <title>{title}</title>
                </head>
                <body>
                    <h1>Welcome, {user_name}!</h1>
                    <p>This is a simple template example.</p>
                </body>
                </html>
            ]"
            
            Result := l_template.render (l_html)
        end

end
