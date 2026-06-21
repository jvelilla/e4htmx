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

			assert ("headers_contain_trigger", l_headers.string.has_substring ("HX-Trigger: status-change"))
			assert ("headers_contain_push", l_headers.string.has_substring ("HX-Push-Url: /new-path"))
		end

	test_context_compilation
			-- Verify EWF_GLIMMER_CONTEXT compiles and compiles type-safely.
		local
			l_context: detachable EWF_GLIMMER_CONTEXT
		do
			assert ("context_compiled", l_context = Void)
		end

	test_utf8_response
			-- Test response boundary encoding and character validation helper
		local
			l_headers: HTTP_HEADER
			l_unicode: STRING_32
			l_utf8: STRING_8
		do
			create l_headers.make
			l_headers.put_content_type ("text/html; charset=utf-8")
			assert ("header_content_type", l_headers.string.has_substring ("Content-Type: text/html; charset=utf-8"))

			l_unicode := {STRING_32} "¡Hola Mundo! 👋 Ramón 🇪🇸"
			l_utf8 := {GLM_STRING_HELPERS}.utf_32_to_utf_8 (l_unicode)
			assert ("is_valid_utf_8", {GLM_STRING_HELPERS}.is_valid_utf_8 (l_utf8))
			assert ("utf_8_roundtrip", {GLM_STRING_HELPERS}.utf_8_to_utf_32 (l_utf8).same_string (l_unicode))
		end

end
