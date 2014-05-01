-- Unified Inventory for Minetest 0.4.8+

local modpath = minetest.get_modpath(minetest.get_current_modname())
local worldpath = minetest.get_worldpath()

-- Data tables definitions
unified_inventory = {}
unified_inventory.activefilter = {}
unified_inventory.alternate = {}
unified_inventory.current_page = {}
unified_inventory.current_index = {}
unified_inventory.current_item = {}
unified_inventory.crafts_table = {}
unified_inventory.crafts_table_count = 0
unified_inventory.players = {}
unified_inventory.items_list_size = 0
unified_inventory.items_list = {}
unified_inventory.filtered_items_list_size = {}
unified_inventory.filtered_items_list = {}
unified_inventory.pages = {}
unified_inventory.buttons = {}

-- Homepos stuff
unified_inventory.home_pos = {}
unified_inventory.home_filename =
		worldpath.."/unified_inventory_home.home"

-- Default inventory page
unified_inventory.default = "craft"

-- Items to hide from the craftguide; eg: {"technic:concrete", "wool:yellow"}
unified_inventory.item_hide_list = {	"bushes:blackberry_bush",
					"bushes:blackberry",
					"bushes:blueberry_bush",
					"bushes:blueberry",
					"bushes:fruitless_bush",
					"bushes:gooseberry_bush",
					"bushes:gooseberry",
					"bushes:raspberry_bush",
					"bushes:raspberry",
					"bushes:strawberry_bush",
					"bushes:strawberry",
					"cooked_rat",
					"rat",
					"default:apple",
					"default:cactus",
					"default:cobble",
					"default:desert_sand",
					"default:desert_stone",
					"default:dirt",
					"default:dirt_with_snow",
					"default:dry_shrub",
					"default:glass",
					"default:grass_1",
					"default:ice",
					"default:junglegrass",
					"default:jungleleaves",
					"default:junglesapling",
					"default:lava_source",
					"default:leaves",
					"default:papyrus",
					"default:sapling",
					"default:stone",
					"default:stone_with_coal",
					"default:stone_with_copper",
					"default:stone_with_diamond",
					"default:stone_with_gold",
					"default:stone_with_iron",
					"default:stone_with_mese",
					"default:stonebrick",
					"default:tree",
					"default:water_source",
					"farming:pumpkin",
					"farming:pumpkin_face",
					"farming:weed",
					"farming_plus:banana",
					"farming_plus:banana_sapling",
					"farming_plus:cocoa",
					"farming_plus:cocoa_sapling",
					"farming_plus:strawberry_item",
					"flowers:dandelion_white",
					"flowers:dandelion_yellow",
					"flowers:geranium",
					"flowers:rose",
					"flowers:seaweed",
					"flowers:tulip",
					"flowers:viola",
					"flowers:waterlily",
					"gloopblocks:basalt",
					"gloopblocks:pumice",
					"homedecor:air_conditioner",
					"homedecor:utility_table_top",
					"mesecons_commandblock:commandblock_off",
					"mesecons_microcontroller:microcontroller0000",
					"moreores:mineral_mithril",
					"moreores:mineral_silver",
					"moreores:mineral_tin",
					"moretrees:acorn",
					"moretrees:apple_tree_leaves",
					"moretrees:apple_tree_sapling",
					"moretrees:beech_leaves",
					"moretrees:beech_sapling",
					"moretrees:birch_leaves",
					"moretrees:birch_sapling",
					"moretrees:coconut",
					"moretrees:fir_cone",
					"moretrees:fir_leaves",
					"moretrees:fir_leaves_bright",
					"moretrees:fir_sapling",
					"moretrees:jungletree_leaves_green",
					"moretrees:jungletree_leaves_red",
					"moretrees:jungletree_leaves_yellow",
					"moretrees:jungletree_sapling",
					"moretrees:oak_leaves",
					"moretrees:oak_sapling",
					"moretrees:palm_leaves",
					"moretrees:palm_sapling",
					"moretrees:pine_cone",
					"moretrees:pine_leaves",
					"moretrees:pine_sapling",
					"moretrees:rubber_tree_leaves",
					"moretrees:rubber_tree_sapling",
					"moretrees:rubber_tree_trunk_empty",
					"moretrees:sequoia_leaves",
					"moretrees:sequoia_sapling",
					"moretrees:spruce_cone",
					"moretrees:spruce_leaves",
					"moretrees:spruce_sapling",
					"moretrees:willow_leaves",
					"moretrees:willow_sapling",
					"nether:glowstone",
					"nether:rack",
					"nether:sand",
					"technic:marble",
					"technic:granite",
					"technic:mineral_chromium",
					"technic:mineral_uranium",
					"technic:mineral_zinc",
					"vendor:signal_vendor_on",
					"travelnet:travelnet",
					"technic:music_player",
					"technic:template",
					"technic:template_motor",
					"technic:template_tool" }

-- Disable default creative inventory
if creative_inventory then
	function creative_inventory.set_creative_formspec(player, start_i, pagenum)
		return
	end
end

dofile(modpath.."/api.lua")
dofile(modpath.."/internal.lua")
dofile(modpath.."/callbacks.lua")
dofile(modpath.."/register.lua")
dofile(modpath.."/bags.lua")
