note
    description: "Test suite for HTML_TEMPLATE class"
    date: "$Date$"
    revision: "$Revision$"

class
    HTML_TEMPLATE_TEST

inherit
    EQA_TEST_SET

feature -- Test routines

    test_basic_template
            -- Test basic variable interpolation
        local
            l_template: HTML_TEMPLATE
            l_result: STRING
        do
            create l_template.make
            l_template.set_variable ("name", "John")
            l_result := l_template.render ("Hello, {name}!")
            assert ("basic_interpolation", l_result.same_string ("Hello, John!"))
        end

    test_multiple_variables
            -- Test multiple variable interpolation
        local
            l_template: HTML_TEMPLATE
            l_result: STRING
        do
            create l_template.make
            l_template.set_variable ("first", "John")
            l_template.set_variable ("last", "Doe")
            l_result := l_template.render ("Name: {first} {last}")
            assert ("multiple_variables", l_result.same_string ("Name: John Doe"))
        end

    test_html_escaping
            -- Test HTML escaping functionality
        local
            l_template: HTML_TEMPLATE
            l_result: STRING
        do
            create l_template.make
            l_template.set_variable ("content", "<script>alert('xss')</script>")
            l_result := l_template.render_safe ("Content: {content}")
            assert ("html_escaped", l_result.same_string ("Content: &lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;"))
        end

    test_escape_html
            -- Test individual HTML escaping
        local
            l_template: HTML_TEMPLATE
            l_result: STRING
        do
            create l_template.make
            l_result := l_template.escape_html ("<p>Hello & goodbye</p>")
            assert ("special_chars_escaped", 
                l_result.same_string ("&lt;p&gt;Hello &amp; goodbye&lt;/p&gt;"))
        end

    test_file_rendering
            -- Test template file rendering
        local
            l_template: HTML_TEMPLATE
            l_file: PLAIN_TEXT_FILE
            l_result: STRING
        do
            -- Create a temporary template file
            create l_file.make_open_write ("test_template.html")
            l_file.put_string ("Hello, {name}!")
            l_file.close

            create l_template.make
            l_template.set_variable ("name", "John")
            l_result := l_template.render_file ("test_template.html")
            
            assert ("file_template_rendered", l_result.same_string ("Hello, John!"))

            -- Clean up
            create l_file.make ("test_template.html")
            if l_file.exists then
                l_file.delete
            end
        end

    test_missing_variable
            -- Test behavior with missing variables
        local
            l_template: HTML_TEMPLATE
            l_result: STRING
        do
            create l_template.make
            l_template.set_variable ("name", "John")
            l_result := l_template.render ("Hello, {name}! Age: {age}")
            assert ("missing_variable_preserved", l_result.same_string ("Hello, John! Age: {age}"))
        end

    test_nested_variables
            -- Test nested variable interpolation
        local
            l_template: HTML_TEMPLATE
            l_result: STRING
        do
            create l_template.make
            l_template.set_variable ("user", "John")
            l_template.set_variable ("greeting", "Hello, {user}!")
            l_result := l_template.render ("{greeting}")
            assert ("nested_variables", l_result.same_string ("Hello, {user}!"))
        end

    test_empty_template
            -- Test empty template handling
        local
            l_template: HTML_TEMPLATE
            l_result: STRING
        do
            create l_template.make
            l_result := l_template.render ("")
            assert ("empty_template", l_result.is_empty)
        end

    test_nonexistent_file
            -- Test handling of nonexistent template files
        local
            l_template: HTML_TEMPLATE
            l_result: STRING
        do
            create l_template.make
            l_result := l_template.render_file ("nonexistent_template.html")
            assert ("nonexistent_file_empty_result", l_result.is_empty)
        end

    test_deep_nested_variables
            -- Test deeply nested variable interpolation
        local
            l_template: HTML_TEMPLATE
            l_result: STRING
        do
            create l_template.make
            l_template.set_variable ("name", "John")
            l_template.set_variable ("user", "{name} Doe")
            l_template.set_variable ("greeting", "Hello, {user}!")
            l_result := l_template.render ("{greeting}")
            assert ("deep_nested_variables", l_result.same_string ("Hello, John Doe!"))
        end

    test_circular_nested_variables
            -- Test handling of circular nested variables
        local
            l_template: HTML_TEMPLATE
            l_result: STRING
        do
            create l_template.make
            l_template.set_variable ("a", "Value of {b}")
            l_template.set_variable ("b", "Value of {a}")
            l_result := l_template.render ("{a}")
            -- Should prevent infinite loop and return partially resolved string
            assert ("circular_variables_handled", l_result.same_string ("Value of Value of {a}"))
        end

end 