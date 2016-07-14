local S = unified_inventory.gettext

-- Create detached creative inventory after loading all mods
minetest.after(0.01, function()
	local rev_aliases = {}
	for source, target in pairs(minetest.registered_aliases) do
		if not rev_aliases[target] then rev_aliases[target] = {} end
		table.insert(rev_aliases[target], source)
	end

	local circular_saw_patterns = {}
	if minetest.setting_getbool("unified_inventory.exclude_saw_recipes")
	   and rawget(_G, "circular_saw") then
		-- Make a list of different patterns that when found in a node
		-- name, it's assumed to mean that they are registered by the
		-- circular saw. At the time of writing, that list is:
		-- ":stair_", ":panel_", ":micro_", ":slab_", ":slope_"
		-- Unfortunately, "" is included as a suffix, which prevents
		-- refining the search by matching by suffix too.

		local circular_saw_words = {}
		-- Find unique prefix words in circular_saw.names
		for _, v in ipairs(circular_saw.names) do
			circular_saw_words[v[1]] = true
		end

		-- Make a sequence with the unique names
		for k, _ in pairs(circular_saw_words) do
			circular_saw_patterns[#circular_saw_patterns + 1] = ":" .. k .. "_"
		end
	end
	unified_inventory.items_list = {}
	for name, def in pairs(minetest.registered_items) do
		if (not def.groups.not_in_creative_inventory or
		   def.groups.not_in_creative_inventory == 0) and
		   def.description and def.description ~= "" then
			table.insert(unified_inventory.items_list, name)
			local all_names = rev_aliases[name] or {}
			table.insert(all_names, name)
			for _, name in ipairs(all_names) do
				local recipes = minetest.get_all_craft_recipes(name)
				if recipes then
					for _, recipe in ipairs(recipes) do

						local unknowns
						local has_non_saw_element

						for _,chk in pairs(recipe.items) do
							local groupchk = string.find(chk, "group:")
							if (not groupchk and not minetest.registered_items[chk])
							  or (groupchk and not unified_inventory.get_group_item(string.gsub(chk, "group:", "")).item) then
								unknowns = true
								break -- no point checking further
							end

							local found
							-- check if node name matches any of the patterns
							for _,v in ipairs(circular_saw_patterns) do
								if chk:find(v, 1, true) then
									found = true
									break
								end
							end
							if not found then
								has_non_saw_element = true
								break
							end
						end

						if not unknowns and has_non_saw_element then
							unified_inventory.register_craft(recipe)
						end
					end
				end
			end
		end
	end
	table.sort(unified_inventory.items_list)
	unified_inventory.items_list_size = #unified_inventory.items_list
	print("Unified Inventory. inventory size: "..unified_inventory.items_list_size)
	for _, name in ipairs(unified_inventory.items_list) do
		local def = minetest.registered_items[name]
		if type(def.drop) == "string" then
			local dstack = ItemStack(def.drop)
			if not dstack:is_empty() and dstack:get_name() ~= name then
				unified_inventory.register_craft({
					type = "digging",
					items = {name},
					output = def.drop,
					width = 0,
				})

			end
		end
	end
	for _, recipes in pairs(unified_inventory.crafts_for.recipe) do
		for _, recipe in ipairs(recipes) do
			local ingredient_items = {}
			for _, spec in ipairs(recipe.items) do
				local matches_spec = unified_inventory.canonical_item_spec_matcher(spec)
				for _, name in ipairs(unified_inventory.items_list) do
					if matches_spec(name) then
						ingredient_items[name] = true
					end
				end
			end
			for name, _ in pairs(ingredient_items) do
				if unified_inventory.crafts_for.usage[name] == nil then
					unified_inventory.crafts_for.usage[name] = {}
				end
				table.insert(unified_inventory.crafts_for.usage[name], recipe)
			end
		end
	end
end)


-- load_home
local function load_home()
	local input = io.open(unified_inventory.home_filename, "r")
	if not input then
		unified_inventory.home_pos = {}
		return
	end
	while true do
		local x = input:read("*n")
		if not x then break end
		local y = input:read("*n")
		local z = input:read("*n")
		local name = input:read("*l")
		unified_inventory.home_pos[name:sub(2)] = {x = x, y = y, z = z}
	end
	io.close(input)
end
load_home()

function unified_inventory.set_home(player, pos)
	local player_name = player:get_player_name()
	unified_inventory.home_pos[player_name] = vector.round(pos)
	-- save the home data from the table to the file
	local output = io.open(unified_inventory.home_filename, "w")
	for k, v in pairs(unified_inventory.home_pos) do
		output:write(v.x.." "..v.y.." "..v.z.." "..k.."\n")
	end
	io.close(output)
end

function unified_inventory.go_home(player)
	local pos = unified_inventory.home_pos[player:get_player_name()]
	if pos then
		player:setpos(pos)
	end
end

-- register_craft
function unified_inventory.register_craft(options)
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
	if not unified_inventory.crafts_for.recipe[itemstack:get_name()] then
		unified_inventory.crafts_for.recipe[itemstack:get_name()] = {}
	end
	table.insert(unified_inventory.crafts_for.recipe[itemstack:get_name()],options)
end


local craft_type_defaults = {
	width = 3,
	height = 3,
	uses_crafting_grid = false,
}


function unified_inventory.craft_type_defaults(name, options)
	if not options.description then
		options.description = name
	end
	setmetatable(options, {__index = craft_type_defaults})
	return options
end


function unified_inventory.register_craft_type(name, options)
	unified_inventory.registered_craft_types[name] =
			unified_inventory.craft_type_defaults(name, options)
end


unified_inventory.register_craft_type("normal", {
	description = "Crafting",
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


unified_inventory.register_craft_type("shapeless", {
	description = "Mixing",
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


unified_inventory.register_craft_type("cooking", {
	description = "Cooking",
	icon = "default_furnace_front.png",
	width = 1,
	height = 1,
})


unified_inventory.register_craft_type("digging", {
	description = "Digging",
	icon = "default_tool_steelpick.png",
	width = 1,
	height = 1,
})


function unified_inventory.register_page(name, def)
	unified_inventory.pages[name] = def
end


function unified_inventory.register_button(name, def)
	if not def.action then
		def.action = function(player)
			unified_inventory.set_inventory_formspec(player, name)
		end
	end
	def.name = name
	table.insert(unified_inventory.buttons, def)
end


function unified_inventory.is_creative(playername)
	return minetest.check_player_privs(playername, {creative=true})
	or minetest.setting_getbool("creative_mode")
end

