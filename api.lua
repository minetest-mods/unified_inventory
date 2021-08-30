local S = minetest.get_translator("unified_inventory")
local F = minetest.formspec_escape
local ui = unified_inventory

-- Create detached creative inventory after loading all mods
minetest.after(0.01, function()
	local rev_aliases = {}
	for source, target in pairs(minetest.registered_aliases) do
		if not rev_aliases[target] then rev_aliases[target] = {} end
		table.insert(rev_aliases[target], source)
	end
	ui.items_list = {}
	for name, def in pairs(minetest.registered_items) do
		if (not def.groups.not_in_creative_inventory or
		   def.groups.not_in_creative_inventory == 0) and
		   def.description and def.description ~= "" then
			table.insert(ui.items_list, name)
			local all_names = rev_aliases[name] or {}
			table.insert(all_names, name)
			for _, player_name in ipairs(all_names) do
				local recipes = minetest.get_all_craft_recipes(player_name)
				if recipes then
					for _, recipe in ipairs(recipes) do

						local unknowns

						for _,chk in pairs(recipe.items) do
							local groupchk = string.find(chk, "group:")
							if (not groupchk and not minetest.registered_items[chk])
							  or (groupchk and not ui.get_group_item(string.gsub(chk, "group:", "")).item)
							  or minetest.get_item_group(chk, "not_in_craft_guide") ~= 0 then
								unknowns = true
							end
						end

						if not unknowns then
							ui.register_craft(recipe)
						end
					end
				end
			end
		end
	end
	table.sort(ui.items_list)
	ui.items_list_size = #ui.items_list
	print("Unified Inventory. inventory size: "..ui.items_list_size)
	for _, name in ipairs(ui.items_list) do
		local def = minetest.registered_items[name]
		-- Simple drops
		if type(def.drop) == "string" then
			local dstack = ItemStack(def.drop)
			if not dstack:is_empty() and dstack:get_name() ~= name then
				ui.register_craft({
					type = "digging",
					items = {name},
					output = def.drop,
					width = 0,
				})

			end
		-- Complex drops. Yes, it's really complex!
		elseif type(def.drop) == "table" then
			--[[ Extract single items from the table and save them into dedicated tables
			to register them later, in order to avoid duplicates. These tables counts
			the total number of guaranteed drops and drops by chance (“maybes”) for each item.
			For “maybes”, the final count is the theoretical maximum number of items, not
			neccessarily the actual drop count. ]]
			local drop_guaranteed = {}
			local drop_maybe = {}
			-- This is for catching an obscure corner case: If the top items table has
			-- only items with rarity = 1, but max_items is set, then only the first
			-- max_items will be part of the drop, any later entries are logically
			-- impossible, so this variable is for keeping track of this
			local max_items_left = def.drop.max_items
			-- For checking whether we still encountered only guaranteed only so far;
			-- for the first “maybe” item it will become false which will cause ALL
			-- later items to be considered “maybes”.
			-- A common idiom is:
			-- { max_items 1, { items = {
			--	{ items={"example:1"}, rarity = 5 },
			-- 	{ items={"example:2"}, rarity = 1 }, }}}
			-- example:2 must be considered a “maybe” because max_items is set and it
			-- appears after a “maybe”
			local max_start = true
			-- Let's iterate through the items madness!
			-- Handle invalid drop entries gracefully.
			local drop_items = def.drop.items or { }
			for i=1,#drop_items do
				if max_items_left ~= nil and max_items_left <= 0 then break end
				local itit = drop_items[i]
				for j=1,#itit.items do
					local dstack = ItemStack(itit.items[j])
					if not dstack:is_empty() and dstack:get_name() ~= name then
						local dname = dstack:get_name()
						local dcount = dstack:get_count()
						-- Guaranteed drops AND we are not yet in “maybe mode”
						if #itit.items == 1 and itit.rarity == 1 and max_start then
							if drop_guaranteed[dname] == nil then
								drop_guaranteed[dname] = 0
							end
							drop_guaranteed[dname] = drop_guaranteed[dname] + dcount

							if max_items_left ~= nil then
								max_items_left = max_items_left - 1
								if max_items_left <= 0 then break end
							end
						-- Drop was a “maybe”
						else
							if max_items_left ~= nil then max_start = false end
							if drop_maybe[dname] == nil then
								drop_maybe[dname] = 0
							end
							drop_maybe[dname] = drop_maybe[dname] + dcount
						end
					end
				end
			end
			for itemstring, count in pairs(drop_guaranteed) do
				ui.register_craft({
					type = "digging",
					items = {name},
					output = itemstring .. " " .. count,
					width = 0,
				})
			end
			for itemstring, count in pairs(drop_maybe) do
				ui.register_craft({
					type = "digging_chance",
					items = {name},
					output = itemstring .. " " .. count,
					width = 0,
				})
			end
		end
	end
	for _, recipes in pairs(ui.crafts_for.recipe) do
		for _, recipe in ipairs(recipes) do
			local ingredient_items = {}
			for _, spec in pairs(recipe.items) do
				local matches_spec = ui.canonical_item_spec_matcher(spec)
				for _, name in ipairs(ui.items_list) do
					if matches_spec(name) then
						ingredient_items[name] = true
					end
				end
			end
			for name, _ in pairs(ingredient_items) do
				if ui.crafts_for.usage[name] == nil then
					ui.crafts_for.usage[name] = {}
				end
				table.insert(ui.crafts_for.usage[name], recipe)
			end
		end
	end
	for item_name, recipes in pairs(ui.crafts_for.recipe) do
		local craft_sorter = ui.craft_sorters[item_name] or ui.craft_sorters._default_
		if craft_sorter then
			table.sort(recipes, craft_sorter)
		end
	end
	ui.crafts_sorted = true
end)


-- load_home
local function load_home()
	local input = io.open(ui.home_filename, "r")
	if not input then
		ui.home_pos = {}
		return
	end
	while true do
		local x = input:read("*n")
		if not x then break end
		local y = input:read("*n")
		local z = input:read("*n")
		local name = input:read("*l")
		ui.home_pos[name:sub(2)] = {x = x, y = y, z = z}
	end
	io.close(input)
end
load_home()

function ui.set_home(player, pos)
	local player_name = player:get_player_name()
	ui.home_pos[player_name] = vector.round(pos)

	-- save the home data from the table to the file
	local output = io.open(ui.home_filename, "w")
	if not output then
		minetest.log("warning", "[unified_inventory] Failed to save file: "
			.. ui.home_filename)
		return
	end
	for k, v in pairs(ui.home_pos) do
		output:write(v.x.." "..v.y.." "..v.z.." "..k.."\n")
	end
	io.close(output)
end

function ui.go_home(player)
	local pos = ui.home_pos[player:get_player_name()]
	if pos then
		player:set_pos(pos)
		return true
	end
	return false
end

-- register_craft
function ui.register_craft(options)
	if not options.output then
		return
	end
	local itemstack = ItemStack(options.output)
	if itemstack:is_empty() then
		return
	end
	if options.type == "normal" and options.width == 0 then
		options = { type = "shapeless", items = options.items, output = options.output, width = 0 }
	end
	local item_name = itemstack:get_name()
	if not ui.crafts_for.recipe[item_name] then
		ui.crafts_for.recipe[item_name] = {}
	end
	table.insert(ui.crafts_for.recipe[item_name],options)

	if ui.crafts_sorted then
		local craft_sorter = ui.craft_sorters[item_name] or ui.craft_sorters._default_
		if craft_sorter then
			table.sort(ui.crafts_for.recipe[item_name], craft_sorter)
		end
	end
end


local craft_type_defaults = {
	width = 3,
	height = 3,
	uses_crafting_grid = false,
}


function ui.craft_type_defaults(name, options)
	if not options.description then
		options.description = name
	end
	setmetatable(options, {__index = craft_type_defaults})
	return options
end


function ui.register_craft_type(name, options)
	ui.registered_craft_types[name] =
			ui.craft_type_defaults(name, options)
end


ui.register_craft_type("normal", {
	description = F(S("Crafting")),
	icon = "ui_craftgrid_icon.png",
	width = 3,
	height = 3,
	get_shaped_craft_width = function (craft) return craft.width end,
	dynamic_display_size = function (craft)
		local w = craft.width
		local h = math.ceil(table.maxn(craft.items) / craft.width)
		local g = w < h and h or w
		return { width = g, height = g }
	end,
	uses_crafting_grid = true,
})


ui.register_craft_type("shapeless", {
	description = F(S("Mixing")),
	icon = "ui_craftgrid_icon.png",
	width = 3,
	height = 3,
	dynamic_display_size = function (craft)
		local maxn = table.maxn(craft.items)
		local g = 1
		while g*g < maxn do g = g + 1 end
		return { width = g, height = g }
	end,
	uses_crafting_grid = true,
})


ui.register_craft_type("cooking", {
	description = F(S("Cooking")),
	icon = "default_furnace_front.png",
	width = 1,
	height = 1,
})


ui.register_craft_type("digging", {
	description = F(S("Digging")),
	icon = "default_tool_steelpick.png",
	width = 1,
	height = 1,
})

ui.register_craft_type("digging_chance", {
	description = "Digging (by chance)",
	icon = "default_tool_steelpick.png^[transformFY.png",
	width = 1,
	height = 1,
})

function ui.register_page(name, def)
	ui.pages[name] = def
end


function ui.register_button(name, def)
	if not def.action then
		def.action = function(player)
			ui.set_inventory_formspec(player, name)
		end
	end
	def.name = name
	table.insert(ui.buttons, def)
end

ui.crafts_sorted = false
ui.craft_sorters = {}
function ui.register_craft_sorter(method, item_name)
	if type(method) ~= "function" then
		error(("Craft sorter method must be a function, %s given."):format(type(method)))
	end
	if not item_name then item_name = "_default_" end
	ui.craft_sorters[item_name] = method
end

function ui.is_creative(playername)
	return minetest.check_player_privs(playername, {creative=true})
		or minetest.settings:get_bool("creative_mode")
end

function ui.single_slot(xpos, ypos, bright)
	return string.format("background9[%f,%f;%f,%f;ui_single_slot%s.png;false;16]",
	xpos, ypos, ui.imgscale, ui.imgscale, (bright and "_bright" or "") )
end

function ui.make_trash_slot(xpos, ypos)
	return
		ui.single_slot(xpos, ypos)..
		"image["..xpos..","..ypos..";1.25,1.25;ui_trash_slot_icon.png]"..
		"list[detached:trash;main;"..(xpos + ui.list_img_offset)..","..(ypos + ui.list_img_offset)..";1,1;]"
end

function ui.make_inv_img_grid(xpos, ypos, width, height, bright)
	local tiled = {}
	local n=1
	for y = 0, (height - 1) do
		for x = 0, (width -1) do
			tiled[n] = ui.single_slot(xpos + (ui.imgscale * x), ypos + (ui.imgscale * y), bright)
			n = n + 1
		end
	end
	return table.concat(tiled)
end
