note
	description: "Test set for EWF Glimmer Integration library"

class
	EWF_GLIMMER_TEST

inherit
	EQA_TEST_SET

feature -- Test routines

	test_apply_htmx_headers
			-- Test apply_htmx_headers response helper
		local
			l_template: GLM_HTML_TEMPLATE
			l_headers: HTTP_HEADER
			l_integration: EWF_GLIMMER_INTEGRATION
		do
			create l_template.make
			l_template.add_trigger ("status-change")
			l_template.set_push_url ("/new-path")

			create l_headers.make
			create l_integration
			l_integration.apply_htmx_headers (l_template, l_headers)

			assert ("headers_contain_trigger", l_headers.string.has_substring ("HX-Trigger: {%"status-change%":true}"))
			assert ("headers_contain_push", l_headers.string.has_substring ("HX-Push-Url: /new-path"))
		end

end
