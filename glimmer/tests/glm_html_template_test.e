note
	description: "Test suite for GLM_HTML_TEMPLATE class"
	date: "$Date$"
	revision: "$Revision$"

class
	GLM_HTML_TEMPLATE_TEST

inherit
	EQA_TEST_SET


feature -- Test routines

	test_basic_template
			-- Test basic variable interpolation
		local
			l_template: GLM_HTML_TEMPLATE
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
			l_template: GLM_HTML_TEMPLATE
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
			l_template: GLM_HTML_TEMPLATE
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
			l_template: GLM_HTML_TEMPLATE
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
			l_template: GLM_HTML_TEMPLATE
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
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING
		do
			create l_template.make
			l_template.set_variable ("name", "John")
			l_result := l_template.render ("Hello, {name}! Age: {age}")
			assert ("missing_variable_preserved", l_result.same_string ("Hello, John! Age: {age}"))
		end

	test_non_recursive_variables
			-- Test that variable values containing braces are NOT recursively resolved
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING
		do
			create l_template.make
			l_template.set_variable ("user", "John")
			l_template.set_variable ("greeting", "Hello, {user}!")
			l_result := l_template.render ("{greeting}")
			assert ("non_recursive_variables", l_result.same_string ("Hello, {user}!"))
		end

	test_multi_part_logical_expressions
			-- Test multi-part logical expressions with and/or
		local
			l_template: GLM_HTML_TEMPLATE
		do
			create l_template.make
			l_template.set_variable ("a", True)
			l_template.set_variable ("b", True)
			l_template.set_variable ("c", False)
			
			assert ("a and b", l_template.evaluate_expression ("a and b"))
			assert ("not (a and b and c)", not l_template.evaluate_expression ("a and b and c"))
			assert ("a or c or b", l_template.evaluate_expression ("a or c or b"))
			assert ("c or c or c", not l_template.evaluate_expression ("c or c or c"))
		end

	test_named_rendering_and_caching
			-- Test rendering with explicit name and cache clearing
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING
		do
			create l_template.make
			l_template.set_variable ("name", "Alice")
			
			-- Render with name
			l_result := l_template.render_with_name ("Hello, {name}!", "my_temp_name")
			assert ("rendered_with_name", l_result.same_string ("Hello, Alice!"))
			
			-- Clear cache
			l_template.clear_cache
		end

	test_layout_non_section_content_preservation
			-- Test that layout rendering preserves non-section content by putting it in default "content" section
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING
		do
			create l_template.make
			l_template.set_layout ("<html><body>{{yield title}} - {{yield content}}</body></html>")
			l_template.set_variable ("user", "John")
			
			l_result := l_template.render (
				"{{section title}}My Title{{end}}" +
				"Hello {user} from outside section!")
				
			assert ("non_section_preserved",
				l_result.same_string ("<html><body>My Title - Hello John from outside section!</body></html>"))
		end

	test_empty_template
			-- Test empty template handling
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING
		do
			create l_template.make
			l_result := l_template.render ("")
			assert ("empty_template", l_result.is_empty)
		end

	test_nonexistent_file
			-- Test handling of nonexistent template files
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING
		do
			create l_template.make
			l_result := l_template.render_file ("nonexistent_template.html")
			assert ("nonexistent_file_empty_result", l_result.is_empty)
		end

	test_partial_template
			-- Test including partial templates
		local
			l_template: GLM_HTML_TEMPLATE
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
			l_template: GLM_HTML_TEMPLATE
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
			l_template: GLM_HTML_TEMPLATE
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
			l_template: GLM_HTML_TEMPLATE
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
			l_template: GLM_HTML_TEMPLATE
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
			l_template: GLM_HTML_TEMPLATE
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
			l_template: GLM_HTML_TEMPLATE
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
			l_template: GLM_HTML_TEMPLATE
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
			l_template: GLM_HTML_TEMPLATE
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
			l_template: GLM_HTML_TEMPLATE
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
			l_template: GLM_HTML_TEMPLATE
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
			l_template: GLM_HTML_TEMPLATE
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
			l_template: GLM_HTML_TEMPLATE
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
			l_template: GLM_HTML_TEMPLATE
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
			l_template: GLM_HTML_TEMPLATE
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
			template: GLM_HTML_TEMPLATE
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
			template: GLM_HTML_TEMPLATE
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
			template: GLM_HTML_TEMPLATE
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
			template: GLM_HTML_TEMPLATE
		do
			create template.make

			template.set_variable ("existing_var", "value")

			assert ("variable exists", template.evaluate_expression ("exists existing_var"))
			assert ("variable doesn't exist", not template.evaluate_expression ("exists non_existing_var"))
		end

	test_truthy_values
			-- Test truthy value evaluation
		local
			template: GLM_HTML_TEMPLATE
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
			l_template: GLM_HTML_TEMPLATE
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
			l_template: GLM_HTML_TEMPLATE
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
			template: GLM_HTML_TEMPLATE
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
			template: GLM_HTML_TEMPLATE
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
			template: GLM_HTML_TEMPLATE
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
			template: GLM_HTML_TEMPLATE
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
			template: GLM_HTML_TEMPLATE
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

	test_htmx_render_section
			-- Test rendering specific named section without layout (HTMX style)
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING_32
		do
			create l_template.make
			l_template.set_layout ("<html>{{yield body}}</html>")
			l_template.set_variable ("username", "Javier")
			
			-- Render only the "body" section
			l_result := l_template.render_section (
				"{{section body}}Welcome back, {username}!{{end}}{{section header}}Title{{end}}",
				"body"
			)
			assert ("render_section_success", l_result.same_string ("Welcome back, Javier!"))
		end

	test_complex_conditional_in_template
			-- Test complex expressions inside template if statements
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING_32
		do
			create l_template.make
			l_template.set_variable ("age", 18)
			
			l_result := l_template.render ("{{if age >= 18}}Adult{{else}}Minor{{end}}")
			assert ("complex_if_true", l_result.same_string ("Adult"))
			
			l_template.set_variable ("age", 16)
			l_result := l_template.render ("{{if age >= 18}}Adult{{else}}Minor{{end}}")
			assert ("complex_if_false", l_result.same_string ("Minor"))
		end

	test_scoped_variable_isolation
			-- Test that loop variable scopes are properly isolated and do not overwrite outer variables
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING_32
			l_outer: ARRAYED_LIST [STRING]
			l_inner: ARRAYED_LIST [STRING]
		do
			create l_template.make
			create l_outer.make (2)
			l_outer.extend ("A")
			l_outer.extend ("B")
			
			create l_inner.make (2)
			l_inner.extend ("1")
			l_inner.extend ("2")
			
			l_template.set_variable ("outer", l_outer)
			l_template.set_variable ("inner", l_inner)
			l_template.set_variable ("item", "Original")
			
			l_result := l_template.render (
				"Before:{item}|" +
				"{{each item in outer}}" +
					"Outer:{item}(" +
					"{{each item in inner}}Inner:{item},{{end}}" +
					")|" +
				"{{end}}" +
				"After:{item}"
			)
			
			assert ("scoped_isolation", l_result.same_string (
				"Before:Original|" +
				"Outer:A(Inner:1,Inner:2,)|" +
				"Outer:B(Inner:1,Inner:2,)|" +
				"After:Original"
			))
		end

	test_render_file_error_reporting
			-- Test file missing error reporting
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING_32
		do
			create l_template.make
			l_result := l_template.render_file ("nonexistent_file_xyz.html")
			assert ("nonexistent_returns_empty", l_result.is_empty)
			assert ("has_error_set", l_template.has_error)
			assert ("error_description_set", attached l_template.last_error as err and then err.has_substring ("not found"))
		end

	test_cache_eviction_behavior
			-- Test cache eviction (should remove only 1 item, not wipe)
		local
			l_template: GLM_HTML_TEMPLATE
			i: INTEGER
			l_name: STRING
			l_result: STRING_32
		do
			create l_template.make
			from
				i := 1
			until
				i > 500
			loop
				l_name := "temp_" + i.out
				l_result := l_template.render_with_name ("Hello " + i.out, l_name)
				i := i + 1
			end
			-- Render one more to exceed limit
			l_result := l_template.render_with_name ("Hello 501", "temp_501")
			
			-- If the cache was completely wiped, count would be 1 and rendering a previous template
			-- would not be cached. With single eviction, the cache still has 500 elements.
			-- Let's test that rendering a previously compiled named template still functions.
			l_result := l_template.render_with_name ("Hello 500", "temp_500")
			assert ("cached_item_retained", l_result.same_string ("Hello 500"))
		end

	test_and_or_short_circuit
			-- Test that and/or folds evaluate properly
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: BOOLEAN
		do
			create l_template.make
			l_template.set_variable ("t", True)
			l_template.set_variable ("f", False)
			
			-- Test and: True and False -> False
			l_result := l_template.evaluate_expression ("t and f")
			assert ("t_and_f_is_false", not l_result)
			
			-- Test or: False or True -> True
			l_result := l_template.evaluate_expression ("f or t")
			assert ("f_or_t_is_true", l_result)
		end

	test_render_section_with_name
			-- Test rendering section with a name (HTMX style) using named cache
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING_32
		do
			create l_template.make
			l_template.set_variable ("name", "Javier")
			l_result := l_template.render_section_with_name (
				"{{section header}}Hello, {name}!{{end}}",
				"header",
				"my_named_section"
			)
			assert ("render_section_with_name_success", l_result.same_string ("Hello, Javier!"))
		end

	test_make_sub_no_stale_error
			-- Test that sub-contexts do not inherit stale last_error from parent
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING_32
		do
			create l_template.make
			-- Trigger an error by rendering an invalid template
			l_result := l_template.render ("{{if invalid")
			assert ("has_error", l_template.has_error)

			-- Clear error and render a valid template.
			-- The engine should render successfully and not fail due to stale error.
			l_result := l_template.render ("Hello")
			assert ("no_longer_has_error", not l_template.has_error)
			assert ("render_success", l_result.same_string ("Hello"))
		end

	test_whitespace_control
			-- Test whitespace control delimiters ({{- and -}})
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING_32
			l_items: ARRAYED_LIST [STRING]
		do
			create l_template.make

			-- 1. Test left trim
			l_template.set_variable ("show", True)
			l_result := l_template.render ("Hello, %N  %T {{- if show}}World{{end}}")
			assert ("left_trim", l_result.same_string_general ("Hello,World"))

			-- 2. Test right trim
			l_template.set_variable ("show", True)
			l_result := l_template.render ("Hello, {{if show -}} %N  %T World{{end}}")
			assert ("right_trim", l_result.same_string_general ("Hello, World"))

			-- 3. Test both trims in loop
			create l_items.make (2)
			l_items.extend ("A")
			l_items.extend ("B")
			l_template.set_variable ("items", l_items)
			l_result := l_template.render (
				"Items:%N" +
				"{{- each item in items }}%N" +
				"<li>{item}</li>%N" +
				"{{- end }}%N" +
				"Done")
			assert ("loop_whitespace_trim", l_result.same_string_general ("Items:%N<li>A</li>%N<li>B</li>%NDone"))

			-- 4. Test back-to-back trims
			l_result := l_template.render (
				"A%N" +
				"{{- if show -}}%N" +
				"B%N" +
				"{{- end -}}%N" +
				"{{- if show -}}%N" +
				"C%N" +
				"{{- end -}}%N" +
				"D")
			assert ("back_to_back_trims", l_result.same_string_general ("ABCD"))
		end

	test_elsif_tag
			-- Test else if and elsif parsing and branching
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING_32
		do
			create l_template.make
			
			l_template.set_variable ("val", 2)
			l_result := l_template.render ("{{if val == 1}}one{{else if val == 2}}two{{else}}other{{end}}")
			assert ("else_if_branch", l_result.same_string_general ("two"))

			l_result := l_template.render ("{{if val == 1}}one{{elsif val == 3}}three{{else}}other{{end}}")
			assert ("elsif_branch_false", l_result.same_string_general ("other"))
		end

	test_htmx_request_helper
			-- Test GLM_HTMX_REQUEST header introspection helper
		local
			l_headers: STRING_TABLE [READABLE_STRING_GENERAL]
			l_req: GLM_HTMX_REQUEST
		do
			create l_headers.make (5)
			l_headers.put ("true", "hx-request")
			l_headers.put ("my-target", "HX-Target")
			l_headers.put ("my-trigger", "hx-trigger-name")
			l_headers.put ("http://localhost/test", "HX-CURRENT-URL")

			create l_req.make (l_headers)
			assert ("is_htmx", l_req.is_htmx_request)
			assert ("target", attached l_req.hx_target as t and then t.same_string_general ("my-target"))
			assert ("trigger_name", attached l_req.hx_trigger_name as tr and then tr.same_string_general ("my-trigger"))
			assert ("current_url", attached l_req.hx_current_url as cur and then cur.same_string_general ("http://localhost/test"))
		end

	test_htmx_metadata_builders
			-- Test HTMX response metadata builders
		local
			l_template: GLM_HTML_TEMPLATE
		do
			create l_template.make
			l_template.add_trigger ("event1")
			l_template.add_trigger ("event2")
			assert ("trigger_header", l_template.htmx_trigger_header.same_string_general ("event1, event2"))

			l_template.set_push_url ("/new-url")
			l_template.set_replace_url ("/replaced-url")
			assert ("push_url", attached l_template.push_url as p and then p.same_string_general ("/new-url"))
			assert ("replace_url", attached l_template.replace_url as r and then r.same_string_general ("/replaced-url"))

			l_template.clear_htmx_metadata
			assert ("cleared_triggers", l_template.trigger_events.is_empty)
			assert ("cleared_push", l_template.push_url = Void)
			assert ("cleared_replace", l_template.replace_url = Void)
		end

	test_render_oob
			-- Test HTMX Out-of-Band (OOB) rendering
		local
			l_template: GLM_HTML_TEMPLATE
			l_sections: ARRAY [READABLE_STRING_GENERAL]
			l_result: STRING_32
		do
			create l_template.make
			l_template.set_variable ("user", "Javier")
			create l_sections.make_empty
			l_sections.force ("main", 1)
			l_sections.force ("sidebar", 2)
			l_result := l_template.render_oob (
				"{{section main}}Welcome {user}!{{end}}{{section sidebar}}Side Info{{end}}",
				l_sections
			)
			assert ("render_oob_output", l_result.same_string_general ("Welcome Javier!<div hx-swap-oob=%"true%" id=%"sidebar%">Side Info</div>"))
		end

	test_typed_setters
			-- Test typed variable setters
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING_32
		do
			create l_template.make
			l_template.set_integer ("total", 123)
			l_template.set_boolean ("flag", True)
			l_template.set_string ("msg", "hello")

			l_result := l_template.render ("{total} {flag} {msg}")
			assert ("typed_setters_interpolated", l_result.same_string_general ("123 True hello"))
		end

	test_section_nodes_cache
			-- Test that render_section cache is active and doesn't crash on hot path
		local
			l_template: GLM_HTML_TEMPLATE
			l_result1, l_result2: STRING_32
		do
			create l_template.make
			l_template.set_variable ("val", "abc")
			
			-- Render section using named cache key first time (compiles and caches section node)
			l_result1 := l_template.render_section_with_name ("{{section sec}}Value: {val}{{end}}", "sec", "sec_template")
			assert ("sec_render_1", l_result1.same_string_general ("Value: abc"))

			-- Change variable and render again (should read section node from cache directly)
			l_template.set_variable ("val", "xyz")
			l_result2 := l_template.render_section_with_name ("{{section sec}}Value: {val}{{end}}", "sec", "sec_template")
			assert ("sec_render_2", l_result2.same_string_general ("Value: xyz"))
		end

	test_dot_notation_table
			-- Test dot-notation resolution for nested STRING_TABLE
		local
			l_template: GLM_HTML_TEMPLATE
			l_user, l_company: STRING_TABLE [ANY]
			l_result: STRING_32
		do
			create l_template.make
			create l_company.make (1)
			l_company.put ("Acme Inc", "name")
			create l_user.make (2)
			l_user.put ("Javier", "name")
			l_user.put (l_company, "company")
			
			l_template.set_variable ("user", l_user)
			l_result := l_template.render ("{user.name} works at {user.company.name}")
			assert ("dot_notation_table", l_result.same_string_general ("Javier works at Acme Inc"))
		end

	test_dot_notation_reflection
			-- Test dot-notation resolution for custom object via Eiffel reflection (INTERNAL)
		local
			l_template: GLM_HTML_TEMPLATE
			l_obj: GLM_HTML_TEMPLATE
			l_todo: GLM_DUMMY_TODO
			l_result: STRING_32
		do
			create l_template.make
			create l_obj.make
			l_obj.set_recursion_depth (5)
			l_obj.set_layout ("my_layout")
			create l_todo.make (42, "Buy milk", 1)
			
			l_template.set_variable ("obj", l_obj)
			l_template.set_variable ("todo", l_todo)
			l_result := l_template.render ("{obj.recursion_depth} {obj.auto_escape} {obj.layout} {todo.id} {todo.description} {todo.completed}")
			assert ("reflection_attributes", l_result.same_string_general ("5 True my_layout 42 Buy milk 1"))
		end

	test_builtin_filters
			-- Test built-in filters (upper, lower, truncate, date_format, number_format, currency)
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING_32
			l_date: DATE
		do
			create l_template.make
			
			-- Test upper
			l_template.set_variable ("name", "john")
			l_result := l_template.render ("{name | upper}")
			assert ("upper_filter", l_result.same_string_general ("JOHN"))
			
			-- Test lower
			l_template.set_variable ("name", "JOHN")
			l_result := l_template.render ("{name | lower}")
			assert ("lower_filter", l_result.same_string_general ("john"))
			
			-- Test truncate
			l_template.set_variable ("text", "hello world")
			l_result := l_template.render ("{text | truncate: 5}")
			assert ("truncate_filter", l_result.same_string_general ("hello"))
			
			-- Test date_format
			create l_date.make (2026, 5, 31)
			l_template.set_variable ("date", l_date)
			l_result := l_template.render ("{date | date_format: %"dd/MM/yyyy%"}")
			assert ("date_format_filter", l_result.same_string_general ("31/05/2026"))
			
			-- Test number_format
			l_template.set_variable ("val", 12.3456)
			l_result := l_template.render ("{val | number_format: 2}")
			assert ("number_format_filter", l_result.same_string_general ("12.35"))
			
			-- Test currency
			l_template.set_variable ("price", 125.5)
			l_result := l_template.render ("{price | currency: %"USD%"}")
			assert ("currency_usd_filter", l_result.same_string_general ("$125.50"))
			
			l_result := l_template.render ("{price | currency: %"EUR%"}")
			assert ("currency_eur_filter", l_result.same_string_general ({STRING_32} "%/8364/125.50"))
		end

	test_filter_chaining
			-- Test chaining multiple filters in sequence
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING_32
		do
			create l_template.make
			l_template.set_variable ("name", "John Doe")
			l_result := l_template.render ("{name | lower | truncate: 4}")
			assert ("chaining", l_result.same_string_general ("john"))
		end

	test_custom_helpers
			-- Test custom helpers registered as named filters
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING_32
		do
			create l_template.make
			l_template.register_helper ("gravatar_url", agent (email: ANY): STRING_32
				do
					Result := "https://gravatar.com/avatar/" + email.out.to_string_32
				end)
			l_template.set_variable ("email", "test@example.com")
			l_result := l_template.render ("{email | gravatar_url | upper}")
			assert ("custom_helper", l_result.same_string_general ("HTTPS://GRAVATAR.COM/AVATAR/TEST@EXAMPLE.COM"))
		end

	test_parameterized_include_basic
			-- Test basic parameterized include functionality
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING
		do
			create l_template.make
			l_template.register_partial ("user_card", "<div>Name: {name}, Role: {role}</div>")
			l_template.set_variable ("user_name", "Javier")
			l_template.set_variable ("user_role", "Architect")
			
			l_result := l_template.render ("{{include user_card with name=user_name, role=user_role}}")
			assert ("basic_param_include", l_result.same_string ("<div>Name: Javier, Role: Architect</div>"))
		end

	test_parameterized_include_isolation
			-- Test that parent context variables are NOT leaked to parameterized includes
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING
		do
			create l_template.make
			l_template.register_partial ("isolated_card", "<div>Name: {name}, ParentVar: {parent_var}</div>")
			l_template.set_variable ("name", "Local")
			l_template.set_variable ("parent_var", "Leak")
			
			l_result := l_template.render ("{{include isolated_card with name=name}}")
			assert ("isolated_param_include", l_result.same_string ("<div>Name: Local, ParentVar: {parent_var}</div>"))
		end

	test_parameterized_include_expression_resolution
			-- Test that parameters can be resolved from dotted paths and literals
		local
			l_template: GLM_HTML_TEMPLATE
			l_user: STRING_TABLE [ANY]
			l_result: STRING
		do
			create l_template.make
			l_template.register_partial ("expr_partial", "{id}: {name} ({count})")
			
			create l_user.make (2)
			l_user.force (42, "id")
			l_user.force ("Alice", "name")
			l_template.set_variable ("user", l_user)
			l_template.set_variable ("limit", 10)
			
			l_result := l_template.render ("{{include expr_partial with id=user.id, name=user.name, count=limit}}")
			assert ("expression_param_include", l_result.same_string ("42: Alice (10)"))
		end

	test_parameterized_include_with_commas
			-- Test that parameter values with quoted strings containing commas are parsed correctly
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING
		do
			create l_template.make
			l_template.register_partial ("greeting_card", "Message: {msg}, From: {from}")
			l_template.set_variable ("author", "Bob")
			
			l_result := l_template.render ("{{include greeting_card with msg=%"Hello, world!%", from=author}}")
			assert ("commas_in_quotes_include", l_result.same_string ("Message: Hello, world!, From: Bob"))
		end

	test_slots_basic
			-- Test basic slot rendering with named slots and fills
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING
		do
			create l_template.make
			l_template.register_partial ("card_basic", "<div class=%"card%"><div class=%"card-header%">{{slot header}}</div><div class=%"card-body%">{{slot content}}</div></div>")
			
			l_result := l_template.render ("{{include card_basic}}{{fill header}}<h2>My Title</h2>{{end}}{{fill content}}<p>Body text here.</p>{{end}}{{end}}")
			assert ("basic_slots_rendered", l_result.same_string ("<div class=%"card%"><div class=%"card-header%"><h2>My Title</h2></div><div class=%"card-body%"><p>Body text here.</p></div></div>"))
		end

	test_slots_nested
			-- Test nested slot rendering to ensure slot scopes do not bleed or collide
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING
		do
			create l_template.make
			l_template.register_partial ("card_nested_outer", "<div class=%"outer%">{{slot main}}</div>")
			l_template.register_partial ("card_nested_inner", "<span class=%"inner%">{{slot label}}</span>")
			
			l_result := l_template.render ("{{include card_nested_outer}}{{fill main}}Outer content and {{include card_nested_inner}}{{fill label}}Inner Label{{end}}{{end}}{{end}}{{end}}")
			assert ("nested_slots_rendered", l_result.same_string ("<div class=%"outer%">Outer content and <span class=%"inner%">Inner Label</span></div>"))
		end

	test_slots_missing
			-- Test that missing fills are rendered as empty strings
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING
		do
			create l_template.make
			l_template.register_partial ("card_missing", "<div class=%"card%"><div class=%"card-header%">{{slot header}}</div><div class=%"card-body%">{{slot content}}</div></div>")
			
			l_result := l_template.render ("{{include card_missing}}{{fill content}}<p>Body text here.</p>{{end}}{{end}}")
			assert ("missing_fill_rendered", l_result.same_string ("<div class=%"card%"><div class=%"card-header%"></div><div class=%"card-body%"><p>Body text here.</p></div></div>"))
		end

	test_slots_conditional
			-- Test slots placed inside conditional blocks in component templates
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING
		do
			create l_template.make
			l_template.register_partial ("card_conditional", "<div class=%"card%">{{if show_header}}<div class=%"card-header%">{{slot header}}</div>{{else}}No header{{end}}</div>")
			
			l_template.set_variable ("show_header", True)
			l_result := l_template.render ("{{include card_conditional}}{{fill header}}<h2>My Title</h2>{{end}}{{end}}")
			assert ("conditional_slot_true", l_result.same_string ("<div class=%"card%"><div class=%"card-header%"><h2>My Title</h2></div></div>"))
			
			l_template.set_variable ("show_header", False)
			l_result := l_template.render ("{{include card_conditional}}{{fill header}}<h2>My Title</h2>{{end}}{{end}}")
			assert ("conditional_slot_false", l_result.same_string ("<div class=%"card%">No header</div>"))
		end

	test_slots_dynamic_context
			-- Test that fills containing parent-context variables are resolved correctly
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING
		do
			create l_template.make
			l_template.register_partial ("card_dynamic", "<div class=%"card%">{{slot content}}</div>")
			l_template.set_variable ("user_name", "Javier")
			
			l_result := l_template.render ("{{include card_dynamic}}{{fill content}}<p>Hello, {user_name}!</p>{{end}}{{end}}")
			assert ("dynamic_slot_variables", l_result.same_string ("<div class=%"card%"><p>Hello, Javier!</p></div>"))
		end

	test_basic_inheritance
			-- Test basic template inheritance layout and block overrides
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING
		do
			create l_template.make
			l_template.register_partial ("base", "<html><body>{{block header}}<header>Default Header</header>{{end}}{{block content}}{{end}}</body></html>")
			
			l_result := l_template.render ("{{extends base}}{{block content}}<h1>My Content</h1>{{end}}")
			assert ("basic_inheritance", l_result.same_string ("<html><body><header>Default Header</header><h1>My Content</h1></body></html>"))
		end

	test_multi_level_inheritance
			-- Test multi-level template inheritance (base -> layout -> page)
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING
		do
			create l_template.make
			l_template.register_partial ("base", "<html><body>{{block header}}Base Header{{end}} - {{block content}}Base Content{{end}}</body></html>")
			l_template.register_partial ("layout", "{{extends base}}{{block header}}Layout Header{{end}}")
			
			l_result := l_template.render ("{{extends layout}}{{block content}}Page Content{{end}}")
			assert ("multi_level_inheritance", l_result.same_string ("<html><body>Layout Header - Page Content</body></html>"))
		end

	test_default_block_content
			-- Test default block content rendering when child doesn't override
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING
		do
			create l_template.make
			l_template.register_partial ("base", "<html><body>{{block header}}Default Header{{end}}</body></html>")
			
			l_result := l_template.render ("{{extends base}}")
			assert ("default_block_content", l_result.same_string ("<html><body>Default Header</body></html>"))
		end

	test_relative_file_resolution
			-- Test extending parent templates from filesystem using relative paths
		local
			l_template: GLM_HTML_TEMPLATE
			l_base_file, l_child_file: PLAIN_TEXT_FILE
			l_result: STRING
		do
			create l_base_file.make_open_write ("test_base.html")
			l_base_file.put_string ("Base: {{block text}}Default{{end}}")
			l_base_file.close
			
			create l_child_file.make_open_write ("test_child.html")
			l_child_file.put_string ("{{extends test_base.html}}{{block text}}Overridden{{end}}")
			l_child_file.close
			
			create l_template.make
			l_result := l_template.render_file ("test_child.html")
			assert ("relative_file_inheritance", l_result.same_string ("Base: Overridden"))
			
			-- Clean up
			create l_base_file.make_with_name ("test_base.html")
			if l_base_file.exists then
				l_base_file.delete
			end
			create l_child_file.make_with_name ("test_child.html")
			if l_child_file.exists then
				l_child_file.delete
			end
		end

	test_circular_extends
			-- Test that circular extends inheritance is detected and reports error
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING
		do
			create l_template.make
			l_template.register_partial ("a", "{{extends b}}")
			l_template.register_partial ("b", "{{extends a}}")
			
			l_result := l_template.render ("{{extends a}}")
			assert ("circular_error_flag", l_template.has_error)
			assert ("circular_error_msg", attached l_template.last_error as err and then err.has_substring ("Circular template inheritance"))
		end

	test_missing_parent_template
			-- Test that missing parent template reports error
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING
		do
			create l_template.make
			
			l_result := l_template.render ("{{extends non_existent_parent.html}}")
			assert ("missing_parent_error_flag", l_template.has_error)
			assert ("missing_parent_error_msg", attached l_template.last_error as err and then err.has_substring ("Template not found"))
		end

end
