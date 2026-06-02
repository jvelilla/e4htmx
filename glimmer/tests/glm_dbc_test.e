note
	description: "Test suite for Pragmatic DbC ({{require}} and {dump}) features"

class
	GLM_DBC_TEST

inherit
	EQA_TEST_SET

feature -- Test routines

	test_require_simple_success
			-- Test that {{require}} succeeds when variable is present
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING
		do
			create l_template.make
			l_template.set_contract_mode (True)
			l_template.set_variable ("user", "Javier")
			
			l_result := l_template.render ("{{require user}}Hello {user}")
			assert ("no_errors", not l_template.has_error)
			assert ("no_violations", not l_template.has_contract_violation)
			assert ("rendered_correctly", l_result.same_string ("Hello Javier"))
		end

	test_require_simple_failure
			-- Test that {{require}} fails when variable is missing
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING
		do
			create l_template.make
			l_template.set_contract_mode (True)
			-- Do not set variable "user"
			
			l_result := l_template.render ("{{require user}}Hello {user}")
			assert ("has_error", l_template.has_error)
			assert ("has_violation", l_template.has_contract_violation)
			assert ("correct_violation_name", attached l_template.last_contract_violation as v and then v.same_string ("user"))
			assert ("result_empty", l_result.is_empty)
		end

	test_require_multiple_success
			-- Test that multiple variables in {{require}} succeed when all are present
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING
		do
			create l_template.make
			l_template.set_contract_mode (True)
			l_template.set_variable ("user", "Javier")
			l_template.set_variable ("role", "Admin")
			
			l_result := l_template.render ("{{require user, role}}User: {user}, Role: {role}")
			assert ("no_errors", not l_template.has_error)
			assert ("rendered_correctly", l_result.same_string ("User: Javier, Role: Admin"))
		end

	test_require_multiple_failure
			-- Test that multiple variables in {{require}} fail when one is missing
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING
		do
			create l_template.make
			l_template.set_contract_mode (True)
			l_template.set_variable ("user", "Javier")
			-- "role" is missing
			
			l_result := l_template.render ("{{require user, role}}User: {user}")
			assert ("has_error", l_template.has_error)
			assert ("has_violation", l_template.has_contract_violation)
			assert ("correct_violation_name", attached l_template.last_contract_violation as v and then v.same_string ("role"))
			assert ("result_empty", l_result.is_empty)
		end

	test_require_expression_success
			-- Test that expression-based {{require}} succeeds when true
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING
		do
			create l_template.make
			l_template.set_contract_mode (True)
			l_template.set_variable ("item_count", 5)
			
			l_result := l_template.render ("{{require item_count > 0}}Count is {item_count}")
			assert ("no_errors", not l_template.has_error)
			assert ("rendered_correctly", l_result.same_string ("Count is 5"))
		end

	test_require_expression_failure
			-- Test that expression-based {{require}} fails when false
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING
		do
			create l_template.make
			l_template.set_contract_mode (True)
			l_template.set_variable ("item_count", 0)
			
			l_result := l_template.render ("{{require item_count > 0}}Count is {item_count}")
			assert ("has_error", l_template.has_error)
			assert ("has_violation", l_template.has_contract_violation)
			assert ("correct_violation_name", attached l_template.last_contract_violation as v and then v.same_string ("item_count > 0"))
		end

	test_require_disabled_production
			-- Test that {{require}} is ignored in production (contract_mode = False)
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING
		do
			create l_template.make
			l_template.set_contract_mode (False)
			-- Do not set "user"
			
			l_result := l_template.render ("{{require user}}Hello {user}")
			assert ("no_errors", not l_template.has_error)
			assert ("no_violations", not l_template.has_contract_violation)
			assert ("rendered_ignoring_require", l_result.same_string ("Hello {user}"))
		end

	test_dump_variable
			-- Test basic variable dumping
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING
		do
			create l_template.make
			l_template.set_contract_mode (True)
			l_template.set_variable ("name", "Javier")
			
			l_result := l_template.render ("{dump name}")
			assert ("contains_details", l_result.has_substring ("<details"))
			assert ("contains_summary", l_result.has_substring ("dump: name"))
			assert ("contains_value", l_result.has_substring ("Javier"))
		end

	test_dump_context
			-- Test full context dumping
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING
		do
			create l_template.make
			l_template.set_contract_mode (True)
			l_template.set_variable ("name", "Javier")
			l_template.set_variable ("age", 30)
			
			l_result := l_template.render ("{dump_context}")
			assert ("contains_details", l_result.has_substring ("<details"))
			assert ("contains_summary", l_result.has_substring ("dump_context"))
			assert ("contains_name_var", l_result.has_substring ("name"))
			assert ("contains_name_val", l_result.has_substring ("Javier"))
			assert ("contains_age_var", l_result.has_substring ("age"))
		end

	test_dump_disabled_production
			-- Test that dump renders empty string when contract_mode is False
		local
			l_template: GLM_HTML_TEMPLATE
			l_result: STRING
		do
			create l_template.make
			l_template.set_contract_mode (False)
			l_template.set_variable ("name", "Javier")
			
			l_result := l_template.render ("{dump name}")
			assert ("rendered_empty", l_result.is_empty)
		end

end
