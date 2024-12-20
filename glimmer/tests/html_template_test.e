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
			l_result := l_template.render ("Content: {content}")
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
			create l_file.make_with_name ("test_template.html")
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
			assert ("nested_variables", l_result.same_string ("Hello, John!"))
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
			l_count, l_pos: INTEGER
			l_search: STRING
		do
			create l_template.make
			l_template.set_recursion_depth (3)
			l_template.set_variable ("a", "Value of {b}")
			l_template.set_variable ("b", "Value of {a}")
			l_result := l_template.render ("{a}")

				-- We expect the template engine to detect the circular reference
				-- and stop after reaching the maximum nesting depth (e.g., 3)
			assert ("circular_reference_detected",
				l_result.same_string ("Value of Value of Value of {b}") or else
				l_result.has_substring ("Circular reference detected"))

				-- Count occurrences of "Value of" in the result
			l_search := "Value of"
			from
				l_pos := 1
			until
				l_pos = 0
			loop
				l_pos := l_result.substring_index (l_search, l_pos)
				if l_pos > 0 then
					l_count := l_count + 1
					l_pos := l_pos + l_search.count
				end
			end

			assert ("finite_nesting_depth", l_count <= 3)
		end

	test_partial_template
			-- Test including partial templates
		local
			l_template: HTML_TEMPLATE
			l_result: STRING
		do
			create l_template.make
			l_template.register_partial ("header", "<header>Welcome, {name}!</header>")
			l_template.register_partial ("footer", "<footer>Copyright {year}</footer>")

			l_template.set_variable ("name", "John")
			l_template.set_variable ("year", "2024")

			l_result := l_template.render ("{{include header}}<main>Content</main>{{include footer}}")
			assert ("partial_templates_included",
				l_result.same_string ("<header>Welcome, John!</header><main>Content</main><footer>Copyright 2024</footer>"))
		end

	test_partial_template_file
			-- Test including partial templates from files
		local
			l_template: HTML_TEMPLATE
			l_header_file, l_footer_file: PLAIN_TEXT_FILE
			l_result: STRING
		do
				-- Create temporary partial template files
			create l_header_file.make_open_write ("header.html")
			l_header_file.put_string ("<header>Welcome, {name}!</header>")
			l_header_file.close

			create l_footer_file.make_open_write ("footer.html")
			l_footer_file.put_string ("<footer>Copyright {year}</footer>")
			l_footer_file.close

			create l_template.make
			l_template.register_partial_file ("header", "header.html")
			l_template.register_partial_file ("footer", "footer.html")

			l_template.set_variable ("name", "John")
			l_template.set_variable ("year", "2024")

			l_result := l_template.render ("{{include header}}<main>Content</main>{{include footer}}")
			assert ("partial_files_included",
				l_result.same_string ("<header>Welcome, John!</header><main>Content</main><footer>Copyright 2024</footer>"))

				-- Clean up
			create l_header_file.make_with_name ("header.html")
			if l_header_file.exists then
				l_header_file.delete
			end
			create l_footer_file.make_with_name ("footer.html")
			if l_footer_file.exists then
				l_footer_file.delete
			end
		end

	test_nested_partials
			-- Test nested partial templates
		local
			l_template: HTML_TEMPLATE
			l_result: STRING
		do
			create l_template.make
			l_template.register_partial ("user_info", "<div>{name} ({email})</div>")
			l_template.register_partial ("page", "<main>{{include user_info}}</main>")

			l_template.set_variable ("name", "John")
			l_template.set_variable ("email", "john@example.com")

			l_result := l_template.render ("{{include page}}")
			assert ("nested_partials_resolved",
				l_result.same_string ("<main><div>John (john@example.com)</div></main>"))
		end

	test_auto_escaping
			-- Test automatic HTML escaping
		local
			l_template: HTML_TEMPLATE
			l_result: STRING
		do
			create l_template.make
				-- Auto-escaping is enabled by default
			l_template.set_variable ("content", "<p>Hello & goodbye</p>")
			l_result := l_template.render ("Content: {content}")
			assert ("content_auto_escaped",
				l_result.same_string ("Content: &lt;p&gt;Hello &amp; goodbye&lt;/p&gt;"))

				-- Test raw (unescaped) content
			l_result := l_template.render ("Raw content: {raw:content}")
			assert ("raw_content_not_escaped",
				l_result.same_string ("Raw content: <p>Hello & goodbye</p>"))

				-- Test with auto-escaping disabled
			l_template.set_auto_escape (False)
			l_result := l_template.render ("Content: {content}")
			assert ("content_not_escaped_when_disabled",
				l_result.same_string ("Content: <p>Hello & goodbye</p>"))
		end

	test_conditional_blocks
			-- Test conditional blocks in templates
		local
			l_template: HTML_TEMPLATE
			l_result: STRING
		do
			create l_template.make

				-- Test true condition
			l_template.set_variable ("show_header", True)
			l_template.set_variable ("header", "Welcome")
			l_result := l_template.render ("{{if show_header}}{header}{{end}}")
			assert ("true_condition", l_result.same_string ("Welcome"))

				-- Test false condition
			l_template.set_variable ("show_header", False)
			l_result := l_template.render ("{{if show_header}}{header}{{end}}")
			assert ("false_condition", l_result.is_empty)

				-- Test with else block
			l_template.set_variable ("logged_in", True)
			l_template.set_variable ("username", "John")
			l_result := l_template.render (
					"{{if logged_in}}Welcome, {username}!{{else}}Please log in{{end}}")
			assert ("if_else_true", l_result.same_string ("Welcome, John!"))

			l_template.set_variable ("logged_in", False)
			l_result := l_template.render (
					"{{if logged_in}}Welcome, {username}!{{else}}Please log in{{end}}")
			assert ("if_else_false", l_result.same_string ("Please log in"))

				-- Test truthy values
			l_template.set_variable ("l_count", 1)
			l_result := l_template.render ("{{if l_count}}Has items{{else}}Empty{{end}}")
			assert ("numeric_truthy", l_result.same_string ("Has items"))

			l_template.set_variable ("l_count", 0)
			l_result := l_template.render ("{{if l_count}}Has items{{else}}Empty{{end}}")
			assert ("numeric_falsy", l_result.same_string ("Empty"))

				-- Test with string values
			l_template.set_variable ("name", "John")
			l_result := l_template.render ("{{if name}}Hello, {name}{{else}}Anonymous{{end}}")
			assert ("string_truthy", l_result.same_string ("Hello, John"))

			l_template.set_variable ("name", "")
			l_result := l_template.render ("{{if name}}Hello, {name}{{else}}Anonymous{{end}}")
			assert ("string_falsy", l_result.same_string ("Anonymous"))
		end

	test_basic_loop_iteration
			-- Test basic string list iteration
		local
			l_template: HTML_TEMPLATE
			l_result: STRING
			l_items: ARRAYED_LIST [STRING]
		do
			create l_template.make
			create l_items.make (3)
			l_items.extend ("apple")
			l_items.extend ("banana")
			l_items.extend ("cherry")
			l_template.set_variable ("fruits", l_items)

			l_result := l_template.render ("{{each fruit in fruits}}{fruit}, {{end}}")
			assert ("basic_loop", l_result.same_string ("apple, banana, cherry, "))
		end

	test_html_list_iteration
			-- Test iteration within HTML list structure
		local
			l_template: HTML_TEMPLATE
			l_result: STRING
			l_items: ARRAYED_LIST [STRING]
		do
			create l_template.make
			create l_items.make (3)
			l_items.extend ("apple")
			l_items.extend ("banana")
			l_items.extend ("cherry")
			l_template.set_variable ("fruits", l_items)

			l_result := l_template.render (
					"<ul>{{each fruit in fruits}}<li>{fruit}</li>{{end}}</ul>")
			assert ("html_list_loop",
				l_result.same_string ("<ul><li>apple</li><li>banana</li><li>cherry</li></ul>"))
		end

	test_number_list_iteration
			-- Test iteration with number list
		local
			l_template: HTML_TEMPLATE
			l_result: STRING
			l_numbers: ARRAYED_LIST [INTEGER]
		do
			create l_template.make
			create l_numbers.make (3)
			l_numbers.extend (1)
			l_numbers.extend (2)
			l_numbers.extend (3)
			l_template.set_variable ("numbers", l_numbers)

			l_result := l_template.render ("{{each num in numbers}}{num}*2={num}{{end}}")
			assert ("number_loop", l_result.same_string ("1*2=12*2=23*2=3"))
		end

	test_empty_list_iteration
			-- Test iteration with empty collection
		local
			l_template: HTML_TEMPLATE
			l_result: STRING
			l_items: ARRAYED_LIST [STRING]
		do
			create l_template.make
			create l_items.make (0)
			l_template.set_variable ("empty_list", l_items)
			l_result := l_template.render ("{{each item in empty_list}}{item}{{end}}")
			assert ("empty_collection", l_result.is_empty)
		end

	test_nested_loop_iteration
			-- Test nested loop iteration
		local
			l_template: HTML_TEMPLATE
			l_result: STRING
			l_numbers: ARRAYED_LIST [INTEGER]
			l_items: ARRAYED_LIST [STRING]
		do
			create l_template.make
			create l_numbers.make (3)
			l_numbers.extend (1)
			l_numbers.extend (2)
			l_numbers.extend (3)
			create l_items.make (0)

			l_template.set_variable ("numbers", l_numbers)
			l_template.set_variable ("fruits", l_items)
			l_result := l_template.render (
					"{{each num in numbers}}{{each fruit in fruits}}{num}-{fruit}, {{end}}{{end}}")
			assert ("nested_loops", l_result.is_empty)
		end

	test_layout_templates
			-- Test layout template functionality
		local
			l_template: HTML_TEMPLATE
			l_result: STRING
			l_items: LIST [STRING]
		do
			create l_template.make

				-- Set up a basic layout
			l_template.set_layout (
				"<html><head><title>{{yield title}}</title></head>" +
				"<body><header>{{yield header}}</header>" +
				"<main>{{yield content}}</main>" +
				"<footer>{{yield footer}}</footer></body></html>")

				-- Test basic layout with sections
			l_result := l_template.render (
					"{{section title}}My Page{{end}}" +
					"{{section header}}Welcome{{end}}" +
					"{{section content}}Main content here{{end}}" +
					"{{section footer}}Copyright 2024{{end}}")

			assert ("basic_layout",
				l_result.same_string (
					"<html><head><title>My Page</title></head>" +
					"<body><header>Welcome</header>" +
					"<main>Main content here</main>" +
					"<footer>Copyright 2024</footer></body></html>"))

				-- Test with missing sections
			l_result := l_template.render (
					"{{section title}}My Page{{end}}" +
					"{{section content}}Main content here{{end}}")

			assert ("missing_sections",
				l_result.same_string (
					"<html><head><title>My Page</title></head>" +
					"<body><header></header>" +
					"<main>Main content here</main>" +
					"<footer></footer></body></html>"))

				-- Test with variables in sections
			l_template.set_variable ("user", "John")
			l_template.set_variable ("year", "2024")

			l_result := l_template.render (
					"{{section title}}Welcome {user}{{end}}" +
					"{{section content}}Hello, {user}!{{end}}" +
					"{{section footer}}Copyright {year}{{end}}")

			assert ("sections_with_variables",
				l_result.same_string (
					"<html><head><title>Welcome John</title></head>" +
					"<body><header></header>" +
					"<main>Hello, John!</main>" +
					"<footer>Copyright 2024</footer></body></html>"))

				-- Test without layout
			l_template.clear_layout
			l_result := l_template.render (
					"{{section title}}My Page{{end}}" +
					"{{section content}}Main content{{end}}")

			assert ("no_layout", l_result.is_empty)

				-- Test with conditionals and loops in sections
			l_template.set_layout ("<main>{{yield content}}</main>")
			l_template.set_variable ("show_greeting", True)

			create {ARRAYED_LIST [STRING]} l_items.make (3)
			l_items.extend ("one")
			l_items.extend ("two")
			l_template.set_variable ("items", l_items)

			l_result := l_template.render (
					"{{section content}}" +
					"{{if show_greeting}}Hello!{{end}}" +
					"<ul>{{each item in items}}<li>{item}</li>{{end}}</ul>" +
					"{{end}}")

			assert ("sections_with_logic",
				l_result.same_string (
					"<main>Hello!<ul><li>one</li><li>two</li></ul></main>"))
		end

	test_conditional_with_loop
			-- Test conditional containing a loop
		local
			l_template: HTML_TEMPLATE
			l_result: STRING
			l_users: ARRAYED_LIST [STRING]
		do
			create l_template.make
			create l_users.make (3)
			l_users.extend ("John")
			l_users.extend ("Jane")
			l_users.extend ("Bob")
			l_template.set_variable ("users", l_users)

				-- Test true case
			l_template.set_variable ("show_users", True)
			l_result := l_template.render (
					"{{if show_users}}" +
					"<ul>{{each user in users}}<li>{user}</li>{{end}}</ul>" +
					"{{else}}" +
					"No users to display" +
					"{{end}}")
			assert ("conditional_with_loop_true",
				l_result.same_string ("<ul><li>John</li><li>Jane</li><li>Bob</li></ul>"))

				-- Test false case
			l_template.set_variable ("show_users", False)
			l_result := l_template.render (
					"{{if show_users}}" +
					"<ul>{{each user in users}}<li>{user}</li>{{end}}</ul>" +
					"{{else}}" +
					"No users to display" +
					"{{end}}")
			assert ("conditional_with_loop_false",
				l_result.same_string ("No users to display"))
		end

	test_loop_with_conditional
			-- Test loop containing conditionals
		local
			l_template: HTML_TEMPLATE
			l_result: STRING
			l_counts: ARRAYED_LIST [INTEGER]
		do
			create l_template.make
			create l_counts.make (3)
			l_counts.extend (0) -- Should trigger "Empty" case
			l_counts.extend (3) -- Should show "Count: 3"
			l_counts.extend (0) -- Should trigger "Empty" case
			l_template.set_variable ("counts", l_counts)

			l_result := l_template.render (
					"<ul>{{each c in counts}}" +
					"{{if c}}<li>Count: {c}</li>{{else}}<li>Empty</li>{{end}}" +
					"{{end}}</ul>")
			assert ("loop_with_conditional",
				l_result.same_string ("<ul><li>Empty</li><li>Count: 3</li><li>Empty</li></ul>"))
		end

	test_nested_loops_with_conditional
			-- Test nested loops with a conditional
		local
			l_template: HTML_TEMPLATE
			l_result: STRING
			l_users: ARRAYED_LIST [STRING]
			l_roles: ARRAYED_LIST [STRING]
		do
			create l_template.make

			create l_users.make (3)
			l_users.extend ("John")
			l_users.extend ("Jane")
			l_template.set_variable ("users", l_users)

			create l_roles.make (2)
			l_roles.extend ("admin")
			l_roles.extend ("user")
			l_template.set_variable ("roles", l_roles)

			l_template.set_variable ("show_roles", True)
			l_result := l_template.render (
					"<div>{{each user in users}}" +
					"<h3>{user}'s Roles:</h3>" +
					"{{if show_roles}}" +
					"<ul>{{each role in roles}}" +
					"<li>{user} as {role}</li>" +
					"{{end}}</ul>" +
					"{{else}}" +
					"<p>Roles hidden</p>" +
					"{{end}}" +
					"{{end}}</div>")
			assert ("nested_loops_with_conditional",
				l_result.same_string (
					"<div>" +
					"<h3>John's Roles:</h3>" +
					"<ul><li>John as admin</li><li>John as user</li></ul>" +
					"<h3>Jane's Roles:</h3>" +
					"<ul><li>Jane as admin</li><li>Jane as user</li></ul>" +
					"</div>"))
		end

	test_complex_nested_structure
			-- Test complex nesting with multiple conditions and loops
		local
			l_template: HTML_TEMPLATE
			l_result: STRING
			l_users: ARRAYED_LIST [STRING]
			l_roles: ARRAYED_LIST [STRING]
		do
			create l_template.make

			create l_users.make (3)
			l_users.extend ("John")
			l_users.extend ("Jane")
			l_template.set_variable ("users", l_users)

			create l_roles.make (2)
			l_roles.extend ("admin")
			l_roles.extend ("user")
			l_template.set_variable ("roles", l_roles)

			l_template.set_variable ("show_details", True)
			l_template.set_variable ("show_roles", False)
			l_result := l_template.render (
					"{{if show_details}}" +
					"{{each user in users}}" +
					"<section>" +
					"<h2>{user}</h2>" +
					"{{if show_roles}}" +
					"<ul>{{each role in roles}}" +
					"<li>{role}</li>" +
					"{{end}}</ul>" +
					"{{else}}" +
					"<p>No roles available</p>" +
					"{{end}}" +
					"</section>" +
					"{{end}}" +
					"{{else}}" +
					"<p>Details hidden</p>" +
					"{{end}}")
			assert ("complex_nesting",
				l_result.same_string (
					"<section><h2>John</h2><p>No roles available</p></section>" +
					"<section><h2>Jane</h2><p>No roles available</p></section>"))
		end

	test_basic_comparisons
			-- Test basic comparison operators
		local
			template: HTML_TEMPLATE
		do
			create template.make

				-- Test numeric comparisons
			template.set_variable ("num1", 10)
			template.set_variable ("num2", 20)

			assert ("10 < 20", template.evaluate_expression ("num1 < num2"))
			assert ("not 10 > 20", not template.evaluate_expression ("num1 > num2"))
			assert ("10 <= 20", template.evaluate_expression ("num1 <= num2"))
			assert ("not 10 >= 20", not template.evaluate_expression ("num1 >= num2"))
			assert ("not 10 == 20", not template.evaluate_expression ("num1 == num2"))
			assert ("10 != 20", template.evaluate_expression ("num1 != num2"))
		end

	test_string_comparisons
			-- Test string comparisons
		local
			template: HTML_TEMPLATE
		do
			create template.make

			template.set_variable ("str1", "hello")
			template.set_variable ("str2", "hello")
			template.set_variable ("str3", "world")

			assert ("str1 == str2", template.evaluate_expression ("str1 == str2"))
			assert ("not str1 == str3", not template.evaluate_expression ("str1 == str3"))
			assert ("str1 != str3", template.evaluate_expression ("str1 != str3"))
		end

	test_logical_operators
			-- Test logical operators (and, or, not)
		local
			template: HTML_TEMPLATE
		do
			create template.make

			template.set_variable ("true_val", True)
			template.set_variable ("false_val", False)
			template.set_variable ("num", 10)

			assert ("true and true", template.evaluate_expression ("true_val and true_val"))
			assert ("not (true and false)", not template.evaluate_expression ("true_val and false_val"))
			assert ("true or false", template.evaluate_expression ("true_val or false_val"))
			assert ("not false", template.evaluate_expression ("not false_val"))

				-- Test combined expressions
			assert ("complex expression", template.evaluate_expression ("num > 5 and num < 20"))
		end

	test_exists_operator
			-- Test exists operator
		local
			template: HTML_TEMPLATE
		do
			create template.make

			template.set_variable ("existing_var", "value")

			assert ("variable exists", template.evaluate_expression ("exists existing_var"))
			assert ("variable doesn't exist", not template.evaluate_expression ("exists non_existing_var"))
		end

	test_truthy_values
			-- Test truthy value evaluation
		local
			template: HTML_TEMPLATE
		do
			create template.make

			template.set_variable ("empty_string", "")
			template.set_variable ("non_empty_string", "hello")
			template.set_variable ("zero", 0)
			template.set_variable ("non_zero", 42)
			template.set_variable ("true_val", True)
			template.set_variable ("false_val", False)

			assert ("non-empty string is truthy", template.evaluate_expression ("non_empty_string"))
			assert ("empty string is not truthy", not template.evaluate_expression ("empty_string"))
			assert ("non-zero is truthy", template.evaluate_expression ("non_zero"))
			assert ("zero is not truthy", not template.evaluate_expression ("zero"))
			assert ("true is truthy", template.evaluate_expression ("true_val"))
			assert ("false is not truthy", not template.evaluate_expression ("false_val"))
		end

	test_reserved_words
			-- Test handling of reserved words as variable names
		local
			l_template: HTML_TEMPLATE
		do
			create l_template.make

				-- Test reserved control words
			l_template.set_variable ("if", "value1")
			l_template.set_variable ("else", "value2")
			l_template.set_variable ("end", "value3")
			l_template.set_variable ("each", "value4")
			l_template.set_variable ("in", "value5")
			l_template.set_variable ("section", "value6")
			l_template.set_variable ("yield", "value7")
			l_template.set_variable ("include", "value8")

		end

	test_reserved_operators
			-- Test handling of reserved operator words as variable names
		local
			l_template: HTML_TEMPLATE
		do
			create l_template.make

				-- Test reserved operator words
			l_template.set_variable ("and", "value1")
			l_template.set_variable ("or", "value2")
			l_template.set_variable ("not", "value3")
			l_template.set_variable ("exists", "value4")

		end

feature -- Test routines

	test_reserved_names
			-- Test that all expected names are properly reserved
		local
			template: HTML_TEMPLATE
		do
			create template.make

				-- Test all reserved names
			assert ("index should be reserved", template.is_reserved_name ("index"))
			assert ("count should be reserved", template.is_reserved_name ("count"))
			assert ("is_first should be reserved", template.is_reserved_name ("is_first"))
			assert ("is_last should be reserved", template.is_reserved_name ("is_last"))
			assert ("is_even should be reserved", template.is_reserved_name ("is_even"))
			assert ("is_odd should be reserved", template.is_reserved_name ("is_odd"))
		end

	test_non_reserved_names
			-- Test that non-reserved names are properly identified
		local
			template: HTML_TEMPLATE
		do
			create template.make

				-- Test some non-reserved names
			assert ("user should not be reserved", not template.is_reserved_name ("user"))
			assert ("name should not be reserved", not template.is_reserved_name ("name"))
			assert ("empty string should not be reserved", not template.is_reserved_name (""))
			assert ("random_var should not be reserved", not template.is_reserved_name ("random_var"))
		end

	test_set_variable_with_reserved_name
			-- Test that setting variables with reserved names raises an error
		local
			template: HTML_TEMPLATE
			has_exception: BOOLEAN
		do
			create template.make

				-- Try to set a variable with a reserved name
			if not has_exception then
				template.set_variable ("index", "some value")
				assert ("Should have raised an exception", False)
			end
		rescue
			has_exception := True
			retry
		end

	test_case_sensitivity
			-- Test that reserved names are case-sensitive
		local
			template: HTML_TEMPLATE
		do
			create template.make

				-- Test case variations of reserved names
			assert ("INDEX should not be reserved", not template.is_reserved_name ("INDEX"))
			assert ("Index should not be reserved", not template.is_reserved_name ("Index"))
			assert ("IS_FIRST should not be reserved", not template.is_reserved_name ("IS_FIRST"))
			assert ("Is_Last should not be reserved", not template.is_reserved_name ("Is_Last"))
		end

	test_loop_metadata_presence
			-- Test that loop metadata variables are properly set during iteration
		local
			template: HTML_TEMPLATE
			result_string: STRING
			test_array: ARRAY [INTEGER]
		do
			create template.make
			create test_array.make_filled (0, 1, 3)
			test_array [1] := 1
			test_array [2] := 2
			test_array [3] := 3

			template.set_variable ("items", test_array)

			result_string := template.render ("{{each item in items}}{index},{count},{is_first},{is_last},{is_even},{is_odd}|{{end}}")

			assert ("Loop metadata should be correctly rendered",
				result_string.same_string ("1,3,True,False,False,True|2,3,False,False,True,False|3,3,False,True,False,True|"))
		end

end
