note
	description: "Test suite for STRING_TEMPLATE"
	date: "$Date$"
	revision: "$Revision$"

class
	STRING_TEMPLATE_TEST

inherit
	EQA_TEST_SET
		select
			default_create
		end
	EQA_COMMONLY_USED_ASSERTIONS
		rename
			default_create as default_create_cua,
			assert as assert_cua
		end

feature -- Tests

	test_basic_substitution
		local
			template: STRING
			variables: STRING_TABLE [ANY]
			st: STRING_TEMPLATE
		do
			create variables.make (1)
			variables["name"] := "Alice"
			template := "Hello {name}!"

			create st
			assert_equal ("Basic substitution", "Hello Alice!", st.interpolate (template, variables))
		end

	test_escaped_braces
		local
			template: STRING
			st: STRING_TEMPLATE
		do
			template := "Escaped {{brace}}"
			create st
			assert_equal ("Escaped braces", "Escaped {brace}", st.interpolate (template, create {STRING_TABLE [ANY]}.make (0)))
		end

	test_missing_variable
		local
			template: STRING
			st: STRING_TEMPLATE
		do
			template := "Missing {var}"
			create st
			assert_equal ("Missing variable", "Missing {var}", st.interpolate (template, create {STRING_TABLE [ANY]}.make (0)))
		end

	test_unclosed_brace
		local
			template: STRING
			st: STRING_TEMPLATE
		do
			template := "Unclosed {brace"
			create st
			assert_equal ("Unclosed brace", "Unclosed {brace", st.interpolate (template, create {STRING_TABLE [ANY]}.make (0)))
		end

	test_variable_with_spaces
		local
			template: STRING
			variables: STRING_TABLE [ANY]
			st: STRING_TEMPLATE
		do
			create variables.make (1)
			variables["var_name"] := "value"
			template := "Var {  var_name  }"
			create st
			assert_equal ("Trimmed variable name", "Var value", st.interpolate (template, variables))
		end

	test_different_data_types
		local
			template: STRING
			variables: STRING_TABLE [ANY]
			st: STRING_TEMPLATE
		do
			create variables.make (2)
			variables["int"] := 42
			variables["bool"] := True
			template := "Int {int}, Bool {bool}"
			create st
			assert_equal ("Different data types", "Int 42, Bool True", st.interpolate (template, variables))
		end

	test_nested_placeholders_in_value
		local
			template: STRING
			variables: STRING_TABLE [ANY]
			st: STRING_TEMPLATE
		do
			create variables.make (1)
			variables["a"] := "{b}"
			template := "{a}"
			create st
			assert_equal ("Nested in value", "{b}", st.interpolate (template, variables))
		end

	test_empty_template
		local
			template: STRING
			st: STRING_TEMPLATE
		do
			template := ""
			create st
			assert_equal ("Empty template", "", st.interpolate (template, create {STRING_TABLE [ANY]}.make (0)))
		end

	test_empty_variables
		local
			template: STRING
			st: STRING_TEMPLATE
		do
			template := "Hello {name}"
			create st
			assert_equal ("Empty variables", "Hello {name}", st.interpolate (template, create {STRING_TABLE [ANY]}.make (0)))
		end

	test_case_sensitivity
		local
			template: STRING
			variables: STRING_TABLE [ANY]
			st: STRING_TEMPLATE
		do
			create variables.make (1)
			variables["Name"] := "Alice"
			template := "{name}"
			create st
			assert_equal ("Case sensitivity", "{name}", st.interpolate (template, variables))
		end

	test_multiple_placeholders
		local
			template: STRING
			variables: STRING_TABLE [ANY]
			st: STRING_TEMPLATE
		do
			create variables.make (2)
			variables["greeting"] := "Hi"
			variables["name"] := "Bob"
			template := "{greeting}, {name}!"
			create st
			assert_equal ("Multiple placeholders", "Hi, Bob!", st.interpolate (template, variables))
		end

end
