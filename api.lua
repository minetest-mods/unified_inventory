local S = minetest.get_translator("unified_inventory")
local F = minetest.formspec_escape
local ui = unified_inventory

local function is_recipe_craftable(recipe)
	-- Ensure the ingedients exist
	for _, itemname in pairs(recipe.items) do
		local groups = string.find(itemname, "group:")
		if groups then
			if not ui.get_group_item(string.sub(groups, 8)).item then
				return false
			end
		else
			-- Possibly an item
			local itemname_cleaned = ItemStack(itemname):get_name()
			if not minetest.registered_items[itemname_cleaned]
					or minetest.get_item_group(itemname_cleaned, "not_in_craft_guide") ~= 0 then
				return false
			end
		end
	end
	return true
end

-- Create detached creative inventory after loading all mods
minetest.after(0.01, function()
	local rev_aliases = {}
	for original, newname in pairs(minetest.registered_aliases) do
		if not rev_aliases[newname] then
			rev_aliases[newname] = {}
		end
		table.insert(rev_aliases[newname], original)
	end

	-- Filtered item list
	ui.items_list = {}
	for name, def in pairs(minetest.registered_items) do
		if ui.is_itemdef_listable(def) then
			table.insert(ui.items_list, name)

			-- Alias processing: Find recipes that belong to the current item name
			local all_names = rev_aliases[name] or {}
			table.insert(all_names, name)
			for _, itemname in ipairs(all_names) do
				local recipes = minetest.get_all_craft_recipes(itemname)
				for _, recipe in ipairs(recipes or {}) do
					if is_recipe_craftable(recipe) then
						ui.register_craft(recipe)
					end
				end
			end
		end
	end

	table.sort(ui.items_list)
	ui.items_list_size = #ui.items_list
	print("Unified Inventory. Inventory size: "..ui.items_list_size)

	-- Analyse dropped items -> custom "digging" recipes
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

	-- Step 1: Initialize cache for looking up groups
	unified_inventory.init_matching_cache()

	-- Step 2: Find all matching items for the given spec (groups)
	local get_matching_spec_items = unified_inventory.get_matching_items

	for outputitemname, recipes in pairs(ui.crafts_for.recipe) do
		-- List of crafts that return this item string (variable "_")

		-- Problem: The group cache must be initialized after all mods finished loading
		-- thus, invalid recipes might be indexed. Hence perform filtering with `new_recipe_list`
		local new_recipe_list = {}
		for _, recipe in ipairs(recipes) do
			local ingredient_items = {}
			for _, spec in pairs(recipe.items) do
				-- Get items that fit into this spec (group or item name)
				local specname = ItemStack(spec):get_name()
				for item_name, _ in pairs(get_matching_spec_items(specname)) do
					ingredient_items[item_name] = true
				end
			end
			for name, _ in pairs(ingredient_items) do
				if not ui.crafts_for.usage[name] then
					ui.crafts_for.usage[name] = {}
				end
				table.insert(ui.crafts_for.usage[name], recipe)
			end

			if next(ingredient_items) then
				-- There's at least one known ingredient: mark as good recipe
				-- PS: What whatll be done about partially incomplete recipes?
				table.insert(new_recipe_list, recipe)
			end
		end
		ui.crafts_for.recipe[outputitemname] = new_recipe_list
	end

	for _, callback in ipairs(ui.initialized_callbacks) do
		callback()
	end
end)

---------------- Home API ----------------

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

---------------- Crafting API ----------------

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

	for _, callback in ipairs(ui.craft_registered_callbacks) do
		callback(item_name, options)
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
	ui.registered_craft_types[name] = ui.craft_type_defaults(name, options)
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

---------------- GUI registrations ----------------

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

---------------- Callback registrations ----------------

function ui.register_on_initialized(callback)
	if type(callback) ~= "function" then
		error(("Initialized callback must be a function, %s given."):format(type(callback)))
	end
	table.insert(ui.initialized_callbacks, callback)
end

function ui.register_on_craft_registered(callback)
	if type(callback) ~= "function" then
		error(("Craft registered callback must be a function, %s given."):format(type(callback)))
	end
	table.insert(ui.craft_registered_callbacks, callback)
end

---------------- List getters ----------------

function ui.get_recipe_list(output)
	return ui.crafts_for.recipe[output]
end

function ui.get_registered_outputs()
	local outputs = {}
	for item_name, _ in pairs(ui.crafts_for.recipe) do
		table.insert(outputs, item_name)
	end
	return outputs
end

---------------- Player utilities ----------------

function ui.is_creative(playername)
	return minetest.check_player_privs(playername, {creative=true})
		or minetest.settings:get_bool("creative_mode")
end

---------------- Formspec helpers ----------------

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
