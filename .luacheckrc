unused_args = false
max_line_length = 131

globals = {
	"unified_inventory",
}

read_globals = {
	string = {fields = {"split", "trim"}},
	table = {fields = {"copy", "getn"}},

	"dump",
	"core", "minetest",
	"ItemStack", "datastorage",
	"vector",

	"hb",
	"doors",
}

files["callbacks.lua"].ignore = { "player" }
files["bags.lua"].ignore = { "player" }
