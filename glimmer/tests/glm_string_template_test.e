note
	description: "Test suite for GLM_STRING_TEMPLATE"
	date: "$Date$"
	revision: "$Revision$"

class
	GLM_STRING_TEMPLATE_TEST

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
			template: STRING_32
			variables: STRING_TABLE [ANY]
			st: GLM_STRING_TEMPLATE
		do
			create variables.make (1)
			variables["name"] := {STRING_32} "Alice"
			template := {STRING_32} "Hello {name}!"

			create st
			assert_equal ("Basic substitution", {STRING_32} "Hello Alice!", st.interpolate (template, variables))
		end

	test_escaped_braces
		local
			template: STRING_32
			st: GLM_STRING_TEMPLATE
		do
			template := {STRING_32} "Escaped {{brace}}"
			create st
			assert_equal ("Escaped braces", {STRING_32} "Escaped {brace}", st.interpolate (template, create {STRING_TABLE [ANY]}.make (0)))
		end

	test_missing_variable
		local
			template: STRING_32
			st: GLM_STRING_TEMPLATE
		do
			template := {STRING_32} "Missing {var}"
			create st
			assert_equal ("Missing variable", {STRING_32} "Missing {var}", st.interpolate (template, create {STRING_TABLE [ANY]}.make (0)))
		end

	test_unclosed_brace
		local
			template: STRING_32
			st: GLM_STRING_TEMPLATE
		do
			template := {STRING_32} "Unclosed {brace"
			create st
			assert_equal ("Unclosed brace", {STRING_32} "Unclosed {brace", st.interpolate (template, create {STRING_TABLE [ANY]}.make (0)))
		end

	test_variable_with_spaces
		local
			template: STRING_32
			variables: STRING_TABLE [ANY]
			st: GLM_STRING_TEMPLATE
		do
			create variables.make (1)
			variables["var_name"] := {STRING_32} "value"
			template := {STRING_32} "Var {  var_name  }"
			create st
			assert_equal ("Trimmed variable name", {STRING_32} "Var value", st.interpolate (template, variables))
		end

	test_different_data_types
		local
			template: STRING_32
			variables: STRING_TABLE [ANY]
			st: GLM_STRING_TEMPLATE
		do
			create variables.make (2)
			variables["int"] := 42
			variables["bool"] := True
			template := {STRING_32} "Int {int}, Bool {bool}"
			create st
			assert_equal ("Different data types", {STRING_32} "Int 42, Bool True", st.interpolate (template, variables))
		end

	test_nested_placeholders_in_value
		local
			template: STRING_32
			variables: STRING_TABLE [ANY]
			st: GLM_STRING_TEMPLATE
		do
			create variables.make (1)
			variables["a"] := {STRING_32} "{b}"
			template := {STRING_32} "{a}"
			create st
			assert_equal ("Nested in value", {STRING_32} "{b}", st.interpolate (template, variables))
		end

	test_empty_template
		local
			template: STRING_32
			st: GLM_STRING_TEMPLATE
		do
			template := {STRING_32} ""
			create st
			assert_equal ("Empty template", {STRING_32} "", st.interpolate (template, create {STRING_TABLE [ANY]}.make (0)))
		end

	test_empty_variables
		local
			template: STRING_32
			st: GLM_STRING_TEMPLATE
		do
			template := {STRING_32} "Hello {name}"
			create st
			assert_equal ("Empty variables", {STRING_32} "Hello {name}", st.interpolate (template, create {STRING_TABLE [ANY]}.make (0)))
		end

	test_case_sensitivity
		local
			template: STRING_32
			variables: STRING_TABLE [ANY]
			st: GLM_STRING_TEMPLATE
		do
			create variables.make (1)
			variables["Name"] := {STRING_32} "Alice"
			template := {STRING_32} "{name}"
			create st
			assert_equal ("Case sensitivity", {STRING_32} "{name}", st.interpolate (template, variables))
		end

	test_multiple_placeholders
		local
			template: STRING_32
			variables: STRING_TABLE [ANY]
			st: GLM_STRING_TEMPLATE
		do
			create variables.make (2)
			variables["greeting"] := {STRING_32} "Hi"
			variables["name"] := {STRING_32} "Bob"
			template := {STRING_32} "{greeting}, {name}!"
			create st
			assert_equal ("Multiple placeholders", {STRING_32} "Hi, Bob!", st.interpolate (template, variables))
		end

	test_unicode_substitution
		local
			template: STRING_32
			variables: STRING_TABLE [ANY]
			st: GLM_STRING_TEMPLATE
		do
			create variables.make (2)
			variables["name"] := {STRING_32} "Javier 🌟"
			variables["city"] := {STRING_32} "Buenos Aires 🇦🇷"
			template := {STRING_32} "Hello {name} from {city}!"

			create st
			assert_equal ("Unicode substitution", {STRING_32} "Hello Javier 🌟 from Buenos Aires 🇦🇷!", st.interpolate (template, variables))
		end

end
