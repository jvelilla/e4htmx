note
	description: "A hash set implementation wrapper around HASH_TABLE"

class
	GLM_HASH_SET [G -> HASHABLE]

create
	make,
	make_equal

feature {NONE} -- Initialization

	make (n: INTEGER_32)
			-- Allocate hash set for at least `n` items using reference comparison.
		require
			n_non_negative: n >= 0
		do
			create table.make (n)
		ensure
			not_object_comparison: not table.object_comparison
		end

	make_equal (n: INTEGER_32)
			-- Allocate hash set for at least `n` items using object comparison (`~`).
		require
			n_non_negative: n >= 0
		do
			create table.make_equal (n)
		ensure
			object_comparison: table.object_comparison
		end

feature -- Access

	has (v: G): BOOLEAN
			-- Does set contain `v`?
		do
			Result := table.has (v)
		end

	count: INTEGER_32
			-- Number of items in set
		do
			Result := table.count
		end

feature -- Element change

	put (v: G)
			-- Insert `v` into set.
		do
			table.force (True, v)
		ensure
			has: has (v)
		end

	remove (v: G)
			-- Remove `v` from set.
		do
			table.remove (v)
		ensure
			removed: not has (v)
		end

feature {NONE} -- Implementation

	table: HASH_TABLE [BOOLEAN, G]
			-- Storage table

end
