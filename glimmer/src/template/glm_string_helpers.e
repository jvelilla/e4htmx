note
	description: "Utility class for handling UTF-8/UTF-32 conversions explicitly"

class
	GLM_STRING_HELPERS

feature -- Conversions

	utf_8_to_utf_32 (a_utf8: READABLE_STRING_8): STRING_32
			-- Convert UTF-8 encoded `a_utf8` to UTF-32 `STRING_32`
		note
			testing: "covers/{UTF_CONVERTER}.utf_8_string_8_to_string_32"
		local
			l_conv: UTF_CONVERTER
		do
			Result := l_conv.utf_8_string_8_to_string_32 (a_utf8)
		ensure
			instance_free: class
		end

	utf_32_to_utf_8 (a_unicode: READABLE_STRING_GENERAL): STRING_8
			-- Convert UTF-32/Unicode `a_unicode` to UTF-8 encoded `STRING_8`
		note
			testing: "covers/{UTF_CONVERTER}.utf_32_string_to_utf_8_string_8"
		local
			l_conv: UTF_CONVERTER
		do
			Result := l_conv.utf_32_string_to_utf_8_string_8 (a_unicode)
		ensure
			instance_free: class
		end

	is_valid_utf_8 (a_str: READABLE_STRING_8): BOOLEAN
			-- Is `a_str` a valid UTF-8 sequence?
		note
			testing: "covers/{UTF_CONVERTER}.is_valid_utf_8_string_8"
		local
			l_conv: UTF_CONVERTER
		do
			Result := l_conv.is_valid_utf_8_string_8 (a_str)
		ensure
			instance_free: class
		end

end
