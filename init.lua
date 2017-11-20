-- Unified Inventory for Minetest 0.4.8+

local modpath = minetest.get_modpath(minetest.get_current_modname())
local worldpath = minetest.get_worldpath()
local mygettext
if rawget(_G, "intllib") then
	mygettext = intllib.Getter()
else
	function mygettext(s, ...)
		local t = { ... }
		return (s:gsub("@(%d+)", function(n) return t[tonumber(n)] end))
	end
end

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

	-- intllib
	gettext = mygettext,
	fgettext = function(...) return minetest.formspec_escape(mygettext(...)) end,

	-- "Lite" mode
	lite_mode = minetest.setting_getbool("unified_inventory_lite"),
	
	-- Trash enabled
	trash_enabled = (minetest.setting_getbool("unified_inventory_trash") ~= false),

	pagecols = 8,
	pagerows = 10,
	page_y = 0,
	formspec_y = 1,
	main_button_x = 0,
	main_button_y = 9,
	craft_result_x = 0.3,
	craft_result_y = 0.5,
	form_header_y = 0
}

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
dofile(modpath.."/register.lua")

if minetest.setting_getbool("unified_inventory_bags") ~= false then
	dofile(modpath.."/bags.lua")
end

dofile(modpath.."/item_names.lua")

if minetest.get_modpath("datastorage") then
	dofile(modpath.."/waypoints.lua")
end
