-- Unified Inventory for Minetest >= 0.4.16

local modpath = minetest.get_modpath(minetest.get_current_modname())
local worldpath = minetest.get_worldpath()

-- Data tables definitions
unified_inventory = {
	activefilter = {},
	active_search_direction = {},
	alternate = {},
	current_page = {},
	current_searchbox = {},
	current_index = {},
	current_item = {},
	current_craft_direction = {},
	registered_craft_types = {},
	crafts_for = {usage = {}, recipe = {} },
	players = {},
	items_list_size = 0,
	items_list = {},
	filtered_items_list_size = {},
	filtered_items_list = {},
	pages = {},
	buttons = {},

	-- Homepos stuff
	home_pos = {},
	home_filename =	worldpath.."/unified_inventory_home.home",

	-- Default inventory page
	default = "craft",

	-- "Lite" mode
	lite_mode = minetest.settings:get_bool("unified_inventory_lite"),

	-- Trash enabled
	trash_enabled = (minetest.settings:get_bool("unified_inventory_trash") ~= false),

	formspec_x = 1,  -- UI doesn't use these first two anymore, but other mods
	formspec_y = 1,  -- may need them.
	pagecols = 8,
	pagerows = 10,
	page_x = 10.75,
	page_y = 1.25,
	craft_x = 2.8,
	craft_y = 1,
	resultstr_y = 0.6,
	main_button_x = 0.4,
	main_button_y = 11.0,
	page_buttons_x = 11.60,
	page_buttons_y = 10.15,
	searchwidth = 3.4,
	form_header_x = 0.4,
	form_header_y = 0.4,
	btn_spc = 0.85,
	btn_size = 0.75,
	imgscale = 1.25,
	std_inv_x = 0.3,
	std_inv_y = 5.5,
	standard_background = "background[0,0;1,1;ui_form_bg.png;true]",
}

uninv = unified_inventory

uninv.standard_inv =       "list[current_player;main;"..(uninv.std_inv_x+0.15)..","..(uninv.std_inv_y+0.15)..";8,4;]"
uninv.standard_inv_bg =    "image["..uninv.std_inv_x..","..uninv.std_inv_y..";"..(uninv.imgscale*8)..
                              ","..(uninv.imgscale*4)..";ui_main_inventory.png]"

-- Disable default creative inventory
local creative = rawget(_G, "creative") or rawget(_G, "creative_inventory")
if creative then
	function creative.set_creative_formspec(player, start_i, pagenum)
		return
	end
end

-- Disable sfinv inventory
local sfinv = rawget(_G, "sfinv")
if sfinv then
	sfinv.enabled = false
end

dofile(modpath.."/group.lua")
dofile(modpath.."/api.lua")
dofile(modpath.."/internal.lua")
dofile(modpath.."/callbacks.lua")
dofile(modpath.."/match_craft.lua")
dofile(modpath.."/register.lua")

if minetest.settings:get_bool("unified_inventory_bags") ~= false then
	dofile(modpath.."/bags.lua")
end

dofile(modpath.."/item_names.lua")

if minetest.get_modpath("datastorage") then
	dofile(modpath.."/waypoints.lua")
end
