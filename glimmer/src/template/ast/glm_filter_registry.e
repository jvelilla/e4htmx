note
	description: "Registry holding built-in variable transformation filters"

class
	GLM_FILTER_REGISTRY

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize registry and populate built-in filters
		do
			create table.make_equal (10)
			table.compare_objects
			
			table.force (agent upper_filter, "upper")
			table.force (agent lower_filter, "lower")
			table.force (agent truncate_filter, "truncate")
			table.force (agent date_format_filter, "date_format")
			table.force (agent number_format_filter, "number_format")
			table.force (agent currency_filter, "currency")
		end

feature -- Access

	has (a_name: READABLE_STRING_GENERAL): BOOLEAN
			-- Does the registry contain a filter named `a_name`?
		do
			Result := table.has (a_name)
		end

	item (a_name: READABLE_STRING_GENERAL): detachable FUNCTION [TUPLE, STRING_32]
			-- Retrieve filter function for `a_name`
		do
			Result := table.item (a_name)
		end

feature -- Built-in Filters

	upper_filter (val: detachable ANY): STRING_32
			-- Convert value to uppercase
		do
			if attached val as v then
				create Result.make_from_string (to_string_32 (v))
				Result.to_upper
			else
				create Result.make_empty
			end
		end

	lower_filter (val: detachable ANY): STRING_32
			-- Convert value to lowercase
		do
			if attached val as v then
				create Result.make_from_string (to_string_32 (v))
				Result.to_lower
			else
				create Result.make_empty
			end
		end

	truncate_filter (val: detachable ANY; len: INTEGER): STRING_32
			-- Truncate string value to `len` characters
		local
			l_str: STRING_32
		do
			if attached val as v then
				l_str := to_string_32 (v)
				if len <= 0 then
					create Result.make_empty
				elseif l_str.count <= len then
					Result := l_str
				else
					Result := l_str.substring (1, len)
				end
			else
				create Result.make_empty
			end
		end

	date_format_filter (val: detachable ANY; format: detachable READABLE_STRING_GENERAL): STRING_32
			-- Format date, date-time, or timestamp using `format`
		local
			l_dt: detachable DATE_TIME
			l_date: detachable DATE
			l_eiffel_format: STRING_8
		do
			if attached val as v then
				if attached {DATE_TIME} v as dt then
					l_dt := dt
				elseif attached {DATE} v as d then
					l_date := d
				elseif attached {INTEGER} v as ts then
					create l_dt.make_from_epoch (ts)
				elseif attached {INTEGER_64} v as ts64 then
					create l_dt.make_from_epoch (ts64.to_integer_32)
				end
				
				if format /= Void then
					l_eiffel_format := map_date_format (format).to_string_8
				else
					l_eiffel_format := ""
				end
				
				if attached l_dt as dt then
					create Result.make_from_string (dt.formatted_out (l_eiffel_format).to_string_32)
				elseif attached l_date as d then
					create Result.make_from_string (d.formatted_out (l_eiffel_format).to_string_32)
				else
					create Result.make_from_string (to_string_32 (v))
				end
			else
				create Result.make_empty
			end
		end

	number_format_filter (val: detachable ANY; decimals: INTEGER): STRING_32
			-- Format numeric value with a specific number of decimal places
		local
			l_val: REAL_64
			l_is_num: BOOLEAN
		do
			if attached val as v then
				if attached {NUMERIC} v as l_num then
					l_val := resolve_to_double (l_num)
					l_is_num := True
				elseif v.out.is_double then
					l_val := v.out.to_double
					l_is_num := True
				end
				
				if l_is_num then
					Result := format_decimal (l_val, decimals)
				else
					create Result.make_from_string (to_string_32 (v))
				end
			else
				create Result.make_empty
			end
		end

	currency_filter (val: detachable ANY; code: detachable READABLE_STRING_GENERAL): STRING_32
			-- Format numeric value as currency
		local
			l_formatted: STRING_32
		do
			if attached val as v then
				l_formatted := number_format_filter (v, 2)
				create Result.make_empty
				if code /= Void and then code.same_string ("USD") then
					Result.append_character ('$')
					Result.append (l_formatted)
				elseif code /= Void and then code.same_string ("EUR") then
					Result.append_character ('%/8364/')
					Result.append (l_formatted)
				elseif code /= Void and then code.same_string ("GBP") then
					Result.append_character ('%/163/')
					Result.append (l_formatted)
				else
					Result.append (l_formatted)
					if code /= Void and then not code.is_empty then
						Result.append_character (' ')
						Result.append (code.to_string_32)
					end
				end
			else
				create Result.make_empty
			end
		end

feature {NONE} -- Helpers

	table: STRING_TABLE [FUNCTION [TUPLE, STRING_32]]
			-- Internal storage for filters

	map_date_format (a_format: READABLE_STRING_GENERAL): STRING_32
			-- Map common Java/JS date format patterns to Eiffel standard codes
		do
			create Result.make_from_string (a_format.to_string_32)
			Result.replace_substring_all ("mm", "[0]mi")
			Result.replace_substring_all ("MM", "[0]mm")
			Result.replace_substring_all ("dd", "[0]dd")
			Result.replace_substring_all ("HH", "[0]hh")
			Result.replace_substring_all ("ss", "[0]ss")
		end

	format_decimal (val: REAL_64; decimals: INTEGER): STRING_32
			-- Format real value to a specific number of decimal places
		local
			l_int_part: INTEGER_64
			l_frac_part: INTEGER_64
			l_factor: REAL_64
			l_rounded: REAL_64
			l_is_negative: BOOLEAN
			l_val: REAL_64
		do
			l_val := val
			if l_val < 0 then
				l_is_negative := True
				l_val := -l_val
			end
			l_factor := 10.0 ^ decimals
			l_rounded := (l_val * l_factor + 0.5).floor.to_double
			l_int_part := (l_rounded / l_factor).floor.to_integer_64
			l_frac_part := (l_rounded - l_int_part.to_double * l_factor).floor.to_integer_64
			
			create Result.make_empty
			if l_is_negative then
				Result.append_character ('-')
			end
			Result.append (l_int_part.out.to_string_32)
			if decimals > 0 then
				Result.append_character ('.')
				Result.append (padded_string (l_frac_part, decimals))
			end
		end

	padded_string (val: INTEGER_64; width: INTEGER): STRING_32
			-- Pad integer with leading zeros to meet width
		local
			l_str: STRING_32
		do
			l_str := val.out.to_string_32
			create Result.make_empty
			from
			until
				Result.count + l_str.count >= width
			loop
				Result.append_character ('0')
			end
			Result.append (l_str)
		end

	resolve_to_double (a_val: ANY): REAL_64
			-- Convert numeric value to REAL_64
		do
			if attached {REAL_64} a_val as r64 then
				Result := r64
			elseif attached {REAL_32} a_val as r32 then
				Result := r32.to_double
			elseif attached {INTEGER_64} a_val as i64 then
				Result := i64.to_double
			elseif attached {INTEGER_32} a_val as i32 then
				Result := i32.to_double
			elseif attached {INTEGER_16} a_val as i16 then
				Result := i16.to_double
			elseif attached {INTEGER_8} a_val as i8 then
				Result := i8.to_double
			elseif attached {INTEGER} a_val as i then
				Result := i.to_double
			elseif attached {REAL} a_val as r then
				Result := r.to_double
			end
		end

	to_string_32 (a_val: ANY): STRING_32
			-- Convert `a_val` to STRING_32, preserving Unicode characters if already a string
		do
			if attached {READABLE_STRING_GENERAL} a_val as l_str then
				Result := l_str.to_string_32
			else
				Result := a_val.out.to_string_32
			end
		ensure
			result_attached: Result /= Void
		end

end
