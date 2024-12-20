note
	description: "Object to interpolate variables into a template string"
	date: "$Date$"
	revision: "$Revision$"
class
    STRING_TEMPLATE

feature -- Access

    interpolate (a_template: STRING; a_variables: STRING_TABLE [ANY]): STRING
            -- Interpolate variables into template string
        local
            l_result: STRING
            l_var_name: STRING
            l_start, l_end, l_next_char: INTEGER
            l_escaped: BOOLEAN
        do
            create l_result.make_from_string (a_template)

            from
                l_start := l_result.substring_index ("{", 1)
            until
                l_start = 0
            loop
                	-- Check if it's an escaped brace
                l_escaped := l_start < l_result.count and then l_result[l_start + 1] = '{'

                if l_escaped then
                    	-- Remove one of the braces and continue
                    l_result.remove (l_start)
                    l_start := l_result.substring_index ("{", l_start + 1)
                else
                    l_end := l_result.index_of ('}', l_start)

                    if l_end = 0 then
                        	-- Unclosed brace - leave it as is
                        l_start := 0
                    elseif l_end > l_start then
                        l_var_name := l_result.substring (l_start + 1, l_end - 1)
                        l_var_name.trim

                        if a_variables.has (l_var_name) then
                            if attached a_variables.item (l_var_name) as l_var then
                                l_result.replace_substring (
                                    l_var.out,
                                    l_start,
                                    l_end
                                )
                            end
                           		-- Continue search after the replacement
                            l_start := l_result.substring_index ("{", l_start + 1)
                        else
                           	 -- Variable not found - leave the placeholder
                            l_start := l_result.substring_index ("{", l_end + 1)
                        end
                    else
                        	-- Invalid brace order - skip
                        l_start := l_result.substring_index ("{", l_end + 1)
                    end
                end
            end

            Result := l_result
        end

end
