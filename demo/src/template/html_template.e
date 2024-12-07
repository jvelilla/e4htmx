note
    description: "HTML templating system using ESX for variable interpolation"
    date: "$Date$"
    revision: "$Revision$"

class
    HTML_TEMPLATE

inherit
    ESX

create
    make

feature {NONE} -- Initialization

    make
        do
            create variables.make (10)
        end

feature -- Access

    variables: STRING_TABLE [ANY]
            -- Storage for template variables

feature -- Operations

    set_variable (name: STRING; value: ANY)
            -- Set a template variable
        require
            name_not_void: name /= Void
            value_not_void: value /= Void
        do
            variables.force (value, name)
        end

    render (template: STRING): STRING
            -- Render the template with current variables
        require
            template_not_void: template /= Void
        do
            Result := esx (template, variables)
        end

    render_file (filename: STRING): STRING
            -- Render template from a file
        require
            filename_not_void: filename /= Void
        local
            l_file: PLAIN_TEXT_FILE
            l_template: STRING
        do
            create l_file.make_with_name (filename)
            if l_file.exists and then l_file.is_readable then
                l_file.open_read
                l_file.read_stream (l_file.count)
                l_template := l_file.last_string
                l_file.close
                Result := render (l_template)
            else
                create Result.make_empty
            end
        end

feature -- HTML Safety

    escape_html (str: STRING): STRING
            -- Convert HTML special characters to entities
        require
            str_not_void: str /= Void
        do
            create Result.make_from_string (str)
            Result.replace_substring_all ("&", "&amp;")
            Result.replace_substring_all ("<", "&lt;")
            Result.replace_substring_all (">", "&gt;")
            Result.replace_substring_all ("%"", "&quot;")
            Result.replace_substring_all ("'", "&#39;")
        end

    render_safe (template: STRING): STRING
            -- Render template with HTML-escaped variables
        require
            template_not_void: template /= Void
        local
            l_safe_vars: STRING_TABLE [ANY]
        do
            create l_safe_vars.make (variables.count)
            across variables as l_var loop
                l_safe_vars.force (escape_html (l_var.item.out), l_var.key)
            end
            Result := esx (template, l_safe_vars)
        end

end 