-- Unified Inventory

if not minetest.features.formspec_version_element then
	-- At least formspec_version[] is the minimal feature requirement
	error("Unified Inventory requires Minetest version 5.4.0 or newer.\n" ..
		" Please update Minetest or use an older version of Unified Inventory.")
end

local modpath = minetest.get_modpath(minetest.get_current_modname())
local worldpath = minetest.get_worldpath()

-- Data tables definitions
unified_inventory = {
	activefilter = {},
	active_search_direction = {},
	alternate = {},
	current_page = {},
	current_searchbox = {},
	current_category = {},
	current_category_scroll = {},
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
	initialized_callbacks = {},
	craft_registered_callbacks = {},

	-- Homepos stuff
	home_pos = {},
	home_filename =	worldpath.."/unified_inventory_home.home",

	-- Default inventory page
	default = "craft",

	-- "Lite" mode
	lite_mode = minetest.settings:get_bool("unified_inventory_lite"),

	-- Items automatically added to categories based on item definitions
	automatic_categorization = (minetest.settings:get_bool("unified_inventory_automatic_categorization") ~= false),

	-- Trash enabled
	trash_enabled = (minetest.settings:get_bool("unified_inventory_trash") ~= false),
	imgscale = 1.25,
	list_img_offset = 0.13,
	standard_background = "bgcolor[#0000]background9[0,0;1,1;ui_formbg_9_sliced.png;true;16]",

	hide_disabled_buttons = minetest.settings:get_bool("unified_inventory_hide_disabled_buttons", false),
	hide_uncraftable_items = minetest.settings:get_bool("unified_inventory_hide_uncraftable_items", false),

	version = 5
}

local ui = unified_inventory

-- These tables establish position and layout for the two UI styles.
-- UI doesn't use formspec_[xy] anymore, but other mods may need them.

ui.style_full = {
	formspec_x = 1,
	formspec_y = 1,
	formw = 17.75,
	formh = 12.25,
	-- Item browser size, pos
	pagecols = 8,
	pagerows = 9,
	page_x = 10.75,
	page_y = 2.30,
	-- Item browser controls
	page_buttons_x = 11.60,
	page_buttons_y = 10.15,
	searchwidth = 3.4,
	-- Crafting grid positions
	craft_x = 2.8,
	craft_y = 1.15,
	craftresult_x = 7.8,
	craft_arrow_x = 6.55,
	craft_guide_x = 3.3,
	craft_guide_y = 1.15,
	craft_guide_arrow_x = 7.05,
	craft_guide_result_x = 8.3,
	craft_guide_resultstr_x = 0.3,
	craft_guide_resultstr_y = 0.6,
	give_btn_x = 0.25,
	-- Tab switching buttons
	main_button_x = 0.4,
	main_button_y = 11.0,
	main_button_cols = 12,
	main_button_rows = 1,
	-- Tab title position
	form_header_x = 0.4,
	form_header_y = 0.4,
	-- Generic sizes
	btn_spc = 0.85,
	btn_size = 0.75,
	std_inv_x = 0.3,
	std_inv_y = 5.75,
}

ui.style_lite = {
	formspec_x =  0.6,
	formspec_y =  0.6,
	formw = 14,
	formh = 9.75,
	-- Item browser size, pos
	pagecols = 4,
	pagerows = 5,
	page_x = 10.5,
	page_y = 2.15,
	-- Item browser controls
	page_buttons_x = 10.5,
	page_buttons_y = 6.15,
	searchwidth = 1.6,
	-- Crafting grid positions
	craft_x = 2.6,
	craft_y = 0.75,
	craftresult_x = 5.75,
	craft_arrow_x = 6.35,
	craft_guide_x = 3.1,
	craft_guide_y = 0.75,
	craft_guide_arrow_x = 7.05,
	craft_guide_result_x = 8.3,
	craft_guide_resultstr_x = 0.15,
	craft_guide_resultstr_y = 0.35,
	give_btn_x = 0.15,
	-- Tab switching buttons
	main_button_x = 10.5,
	main_button_y = 8.15,
	main_button_cols = 4,
	main_button_rows = 2,
	-- Tab title position
	form_header_x =  0.2,
	form_header_y =  0.2,
	-- Generic sizes
	btn_spc = 0.8,
	btn_size = 0.7,
	std_inv_x = 0.1,
	std_inv_y = 4.6,
}

dofile(modpath.."/api.lua")

for _, style in ipairs({ui.style_full, ui.style_lite}) do
	style.items_per_page =  style.pagecols * style.pagerows
	style.standard_inv = string.format("list[current_player;main;%f,%f;8,4;]",
							style.std_inv_x + ui.list_img_offset, style.std_inv_y + ui.list_img_offset)

	style.standard_inv_bg = ui.make_inv_img_grid(style.std_inv_x, style.std_inv_y, 8, 1, true)..
							ui.make_inv_img_grid(style.std_inv_x, style.std_inv_y + ui.imgscale, 8, 3)

	style.craft_grid =	table.concat({
							ui.make_inv_img_grid(style.craft_x, style.craft_y, 3, 3),
							ui.single_slot(style.craft_x + ui.imgscale*4, style.craft_y), -- the craft result slot
							string.format("image[%f,%f;%f,%f;ui_crafting_arrow.png]",
							style.craft_arrow_x, style.craft_y, ui.imgscale, ui.imgscale),
							string.format("list[current_player;craft;%f,%f;3,3;]",
								style.craft_x + ui.list_img_offset, style.craft_y + ui.list_img_offset),
							string.format("list[current_player;craftpreview;%f,%f;1,1;]",
								style.craftresult_x + ui.list_img_offset, style.craft_y + ui.list_img_offset)
						})
end

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
dofile(modpath.."/category.lua")
dofile(modpath.."/default-categories.lua")
dofile(modpath.."/internal.lua")
dofile(modpath.."/callbacks.lua")
dofile(modpath.."/match_craft.lua")
dofile(modpath.."/register.lua")

if minetest.settings:get_bool("unified_inventory_bags") ~= false then
	dofile(modpath.."/bags.lua")
end
if minetest.settings:get_bool("unified_inventory_item_names") ~= false then
	dofile(modpath.."/item_names.lua")
end
if minetest.settings:get_bool("unified_inventory_waypoints") ~= false then
	dofile(modpath.."/waypoints.lua")
end
dofile(modpath.."/legacy.lua") -- mod compatibility
