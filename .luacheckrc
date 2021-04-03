unused_args = false
allow_defined_top = true
max_line_length = 999

globals = {
	"unified_inventory",
}

read_globals = {
	string = {fields = {"split", "trim"}},
	table = {fields = {"copy", "getn"}},

	"minetest", "vector",
	"ItemStack", "datastorage",

	"hb",
	"doors",
}

files["callbacks.lua"].ignore = { "player", "draw_lite_mode" }
files["bags.lua"].ignore = { "player" }
