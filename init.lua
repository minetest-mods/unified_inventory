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
	imgscale = 1.25,
	standard_background = "background9[0,0;1,1;ui_formbg_9_sliced.png;true;16]",
}

local ui = unified_inventory

-- These tables establish position and layout for the two UI styles.
-- UI doesn't use formspec_[xy] anymore, but other mods may need them.

ui.style_full = {
	formspec_x = 1,
	formspec_y = 1,
	pagecols = 8,
	pagerows = 10,
	page_x = 10.75,
	page_y = 1.45,
	craft_x = 2.8,
	craft_y = 1.15,
	resultstr_y = 0.6,
	give_btn_x = 0.25,
	main_button_x = 0.4,
	main_button_y = 11.0,
	page_buttons_x = 11.60,
	page_buttons_y = 10.15,
	searchwidth = 3.4,
	form_header_x = 0.4,
	form_header_y = 0.4,
	btn_spc = 0.85,
	btn_size = 0.75,
	std_inv_x = 0.3,
	std_inv_y = 5.75,
}

ui.style_lite = {
	formspec_x =  0.6,
	formspec_y =  0.6,
	pagecols = 4,
	pagerows = 6,
	page_x = 10.5,
	page_y = 1.25,
	craft_x = 2.6,
	craft_y = 0.75,
	resultstr_y = 0.35,
	give_btn_x = 0.15,
	main_button_x = 10.5,
	main_button_y = 7.9,
	page_buttons_x = 10.5,
	page_buttons_y = 6.3,
	searchwidth = 1.6,
	form_header_x =  0.2,
	form_header_y =  0.2,
	btn_spc = 0.8,
	btn_size = 0.7,
	std_inv_x = 0.1,
	std_inv_y = 4.6,
}

for _, style in ipairs({ui.style_full, ui.style_lite}) do
	style.items_per_page =  style.pagecols * style.pagerows
	style.standard_inv =    string.format("list[current_player;main;%f,%f;8,4;]",
                              style.std_inv_x+0.15, style.std_inv_y+0.15)

	style.standard_inv_bg = string.format("image[%f,%f;%f,%f;ui_main_inventory.png]",
                              style.std_inv_x, style.std_inv_y,
                              ui.imgscale*8, ui.imgscale*4)
end

ui.trash_slot_img =         string.format("%f,%f;ui_single_slot.png^(ui_trash_slot_icon.png^[opacity:95)",
                              ui.imgscale, ui.imgscale)

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
