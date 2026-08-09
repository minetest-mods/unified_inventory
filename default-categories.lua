local S = core.get_translator("unified_inventory")
local ui = unified_inventory

unified_inventory.register_category('plants', {
	symbol = "flowers:tulip",
	label = S("Plant Life")
})
unified_inventory.register_category('building', {
	symbol = "default:brick",
	label = S("Building Materials")
})
unified_inventory.register_category('tools', {
	symbol = "default:pick_diamond",
	label = S("Tools")
})
unified_inventory.register_category('minerals', {
	symbol = "default:iron_lump",
	label = S("Minerals and Metals")
})
unified_inventory.register_category('environment', {
	symbol = "default:dirt_with_grass",
	label = S("Environment and Worldgen")
})
unified_inventory.register_category('lighting', {
	symbol = "default:torch",
	label = S("Lighting")
})

local function get_item_category(name)
	local def = core.registered_items[name]
	local group = def.groups

	if def.type == 'tool' and def.tool_capabilities or
			group.tool or
			group.hoe then
		return 'tools'
	end

	-- May be a craftitem
	if group.door or
		   core.global_exists("doors") and (
			 doors.registered_doors and doors.registered_doors[name..'_a'] or
			 doors.registered_trapdoors and doors.registered_trapdoors[name]
		   ) then
		return 'building'
	end

	if def.type == "node" then
		if def.liquidtype == 'source' then
			return 'environment'
		end
		if def.light_source and def.light_source > 0 then
			ui.add_category_item('lighting', def.name)
			-- allow multiple categories
		end
		if group.stair or
		   group.slab or
		   group.pane or -- MTG xpanes
		   group.wall or -- MTG walls
		   group.fence or
		   group.door then -- not used by MTG
			return 'building'
		end
		if group.flora or
			   group.flower or
			   group.mushroom or
			   group.seed or
			   group.leaves or
			   group.sapling or
			   group.tree then
			return 'plants'
		end
		if group.snappy and (def.waving or 0) > 0 and
				(def.drawtype == "plantlike" or def.drawtype == "plantlike_rooted") then
			return 'plants'
		end
	end
end

local function register_automatic_categorization()
	-- Add biome nodes to environment category
	for _,def in pairs(core.registered_biomes) do
		local env_nodes = {
			def.node_riverbed, def.node_top, def.node_filler, def.node_dust,
		}
		for i,node in pairs(env_nodes) do
			if node then
				unified_inventory.add_category_item('environment', node)
			end
		end
	end

	-- Preparation for ore registration: find all possible drops (digging)
	local possible_node_dig_drops = {
		-- ["default:stone_with_coal"] = { "default:coal_lump", "mymod:raregem" }
		-- Ores may be contained multiple times, depending on drop chances.
	}
	local ores_names = {
		-- ["default:gold_in_stone"] = true
	}
	for itemname, recipes in pairs(ui.crafts_for.usage) do
		for _, recipe in ipairs(recipes) do
			if recipe.type == "digging" or recipe.type == "digging_chance" then
				local drops = possible_node_dig_drops[itemname]
				if not drops then
					drops = {}
					possible_node_dig_drops[itemname] = drops
				end

				for _, stack in ipairs(recipe.output) do
					table.insert(drops, stack:get_name())
				end

			elseif recipe.type == "mapgen_ore" then
				for _, stack in ipairs(recipe.output) do
					ores_names[stack:get_name()] = true
				end
			end
		end
	end

	for ore_name, _ in pairs(ores_names) do
		local drops = possible_node_dig_drops[ore_name]
		if drops then
			ui.add_category_item('minerals', ore_name) -- ore in stone
			ui.add_category_items('minerals', drops)   -- usually lumps
		else
			ui.add_category_item('environment', ore_name) -- gravel, clay, ...
		end
	end

	-- Add items by item definition
	for _, name in ipairs(ui.items_list) do
		local cat = get_item_category(name)
		if cat then
			-- meow
			ui.add_category_item(cat, name)
		end
	end
end

ui.register_on_initialized(register_automatic_categorization)

unified_inventory.add_category_items('minerals', {
	"default:copper_ingot",
	"default:diamondblock",
	"default:steel_ingot",
	"default:gold_ingot",
	"default:tinblock",
	"default:bronze_ingot",
	"default:mese",
	"default:mese_crystal_fragment",
	"default:copperblock",
	"default:steelblock",
	"default:tin_ingot",
	"default:coalblock",
	"default:bronzeblock",
	"default:goldblock",
})

-- luacheck: push ignore 511
if false then
	core.after(1, function ()
		local l = {}
		for _, name in ipairs(ui.items_list) do
			if not unified_inventory.find_category(name) then
				table.insert(l, name)
			end
		end
		table.sort(l)
		core.log(table.concat(l, "\n"))
	end)
end
-- luacheck: pop
