local S = minetest.get_translator("unified_inventory")

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


if unified_inventory.automatic_categorization then
	minetest.register_on_mods_loaded(function()

		-- Add biome nodes to environment category
		for _,def in pairs(minetest.registered_biomes) do
			local env_nodes = {
				def.node_riverbed, def.node_top, def.node_filler, def.node_dust,
			}
			for i,node in pairs(env_nodes) do
				if node then
					unified_inventory.add_category_item('environment', node)
				end
			end
		end

		-- Add minable ores to minerals and everything else (pockets of stone & sand variations) to environment
		for _,item in  pairs(minetest.registered_ores) do
			if item.ore_type == "scatter" then
				local drop = minetest.registered_nodes[item.ore].drop
				if drop and drop ~= "" then
					unified_inventory.add_category_item('minerals', item.ore)
					unified_inventory.add_category_item('minerals', drop)
				else
					unified_inventory.add_category_item('environment', item.ore)
				end
			else
				unified_inventory.add_category_item('environment', item.ore)
			end
		end

		-- Add items by item definition
		for name, def in pairs(minetest.registered_items) do
			local group = def.groups or {}
			if not group.not_in_creative_inventory then
				if group.stair or
				   group.slab or
				   group.wall or
				   group.fence then
					unified_inventory.add_category_item('building', name)
				elseif group.flora or
					   group.flower or
					   group.seed or
					   group.leaves or
					   group.sapling or
					   group.tree then
					unified_inventory.add_category_item('plants', name)
				elseif def.type == 'tool' then
					unified_inventory.add_category_item('tools', name)
				elseif def.liquidtype == 'source' then
					unified_inventory.add_category_item('environment', name)
				elseif def.light_source and def.light_source > 0 then
					unified_inventory.add_category_item('lighting', name)
				elseif group.door or
					   minetest.global_exists("doors") and (
					     doors.registered_doors and doors.registered_doors[name..'_a'] or
					     doors.registered_trapdoors and doors.registered_trapdoors[name]
					   ) then
					unified_inventory.add_category_item('building', name)
				end
			end
		end
	end)
end

-- [[
unified_inventory.add_category_items('plants', {
	"default:dry_grass_5",
	"default:acacia_sapling",
	"default:blueberry_bush_sapling",
	"default:grass_2",
	"default:pine_bush_stem",
	"default:leaves",
	"default:pine_needles",
	"default:cactus",
	"default:junglegrass",
	"default:pine_sapling",
	"default:sapling",
	"default:bush_stem",
	"default:dry_grass_2",
	"default:fern_1",
	"default:grass_3",
	"default:marram_grass_1",
	"default:pine_tree",
	"default:dry_grass_3",
	"default:dry_shrub",
	"default:grass_4",
	"default:marram_grass_2",
	"default:jungleleaves",
	"default:apple",
	"default:tree",
	"default:aspen_tree",
	"default:bush_sapling",
	"default:grass_5",
	"default:blueberry_bush_leaves_with_berries",
	"default:acacia_bush_sapling",
	"default:grass_1",
	"default:aspen_leaves",
	"default:marram_grass_3",
	"default:large_cactus_seedling",
	"default:junglesapling",
	"default:dry_grass_4",
	"default:acacia_bush_stem",
	"default:papyrus",
	"default:pine_bush_needles",
	"default:bush_leaves",
	"default:fern_3",
	"default:aspen_sapling",
	"default:acacia_tree",
	"default:apple_mark",
	"default:acacia_leaves",
	"default:jungletree",
	"default:dry_grass_1",
	"default:acacia_bush_leaves",
	"default:emergent_jungle_sapling",
	"default:fern_2",
	"default:blueberries",
	"default:sand_with_kelp",
	"default:blueberry_bush_leaves",
	"default:pine_bush_sapling",

	"farming:cotton",
	"farming:cotton_1",
	"farming:cotton_2",
	"farming:cotton_3",
	"farming:cotton_4",
	"farming:cotton_5",
	"farming:cotton_6",
	"farming:cotton_7",
	"farming:cotton_8",
	"farming:cotton_wild",
	"farming:seed_cotton",
	"farming:seed_wheat",
	"farming:straw",
	"farming:wheat",
	"farming:wheat_1",
	"farming:wheat_2",
	"farming:wheat_3",
	"farming:wheat_4",
	"farming:wheat_5",
	"farming:wheat_6",
	"farming:wheat_7",
	"farming:wheat_8",

	"flowers:chrysanthemum_green",
	"flowers:dandelion_white",
	"flowers:dandelion_yellow",
	"flowers:geranium",
	"flowers:mushroom_brown",
	"flowers:mushroom_red",
	"flowers:rose",
	"flowers:tulip",
	"flowers:tulip_black",
	"flowers:viola",
	"flowers:waterlily",
	"flowers:waterlily_waving",
})

unified_inventory.add_category_items('tools', {
	"default:sword_diamond",
	"default:axe_diamond",
	"default:shovel_diamond",
	"default:axe_steel",
	"default:shovel_mese",
	"default:sword_wood",
	"default:pick_bronze",
	"default:axe_stone",
	"default:sword_stone",
	"default:pick_stone",
	"default:shovel_stone",
	"default:sword_mese",
	"default:shovel_bronze",
	"default:sword_bronze",
	"default:axe_bronze",
	"default:shovel_steel",
	"default:sword_steel",
	"default:axe_mese",
	"default:shovel_wood",
	"default:pick_mese",
	"default:axe_wood",
	"default:pick_diamond",
	"default:pick_wood",
	"default:pick_steel",

	"farming:hoe_bronze",
	"farming:hoe_diamond",
	"farming:hoe_mese",
	"farming:hoe_steel",
	"farming:hoe_stone",
	"farming:hoe_wood",

	"fire:flint_and_steel",
	"map:mapping_kit",
	"screwdriver:screwdriver",

	"fireflies:bug_net",
	"bucket:bucket_empty",

	"binoculars:binoculars",
	"default:skeleton_key",
})

unified_inventory.add_category_items('minerals', {
	"default:stone_with_copper",
	"default:stone_with_gold",
	"default:stone_with_iron",
	"default:copper_ingot",
	"default:copper_lump",
	"default:gold_lump",
	"default:diamondblock",
	"default:stone_with_diamond",
	"default:stone_with_mese",
	"default:steel_ingot",
	"default:gold_ingot",
	"default:iron_lump",
	"default:tinblock",
	"default:tin_lump",
	"default:stone_with_tin",
	"default:mese_crystal",
	"default:diamond",
	"default:bronze_ingot",
	"default:mese",
	"default:mese_crystal_fragment",
	"default:copperblock",
	"default:stone_with_coal",
	"default:steelblock",
	"default:tin_ingot",
	"default:coalblock",
	"default:coal_lump",
	"default:bronzeblock",
	"default:goldblock",

	"stairs:slab_bronzeblock",
	"stairs:slab_copperblock",
	"stairs:slab_steelblock",
	"stairs:slab_tinblock",
	"stairs:stair_bronzeblock",
	"stairs:stair_copperblock",
	"stairs:stair_inner_bronzeblock",
	"stairs:stair_inner_copperblock",
	"stairs:stair_inner_steelblock",
	"stairs:stair_inner_tinblock",
	"stairs:stair_outer_bronzeblock",
	"stairs:stair_outer_copperblock",
	"stairs:stair_outer_steelblock",
	"stairs:stair_outer_tinblock",
	"stairs:stair_steelblock",
	"stairs:stair_tinblock",
})

unified_inventory.add_category_items('building', {
	"default:fence_rail_aspen_wood",
	"default:fence_rail_acacia_wood",
	"default:fence_junglewood",
	"default:fence_rail_junglewood",
	"default:fence_aspen_wood",
	"default:fence_pine_wood",
	"default:fence_rail_wood",
	"default:fence_rail_pine_wood",
	"default:fence_acacia_wood",
	"default:junglewood",
	"default:acacia_wood",
	"default:aspen_wood",
	"default:fence_wood",
	"default:pine_wood",
	"default:silver_sandstone",
	"default:desert_sandstone",
	"default:sandstone_block",
	"default:desert_sandstone_brick",
	"default:stone_block",
	"default:stonebrick",
	"default:obsidian_glass",
	"default:desert_sandstone_block",
	"default:silver_sandstone_brick",
	"default:brick",
	"default:obsidianbrick",
	"default:sandstonebrick",
	"default:sandstone",
	"default:desert_stone_block",
	"default:silver_sandstone_block",
	"default:wood",
	"default:obsidian_block",
	"default:glass",
	"default:clay_brick",
	"default:desert_stonebrick",
	"default:desert_cobble",
	"default:cobble",
	"default:mossycobble",

	"doors:door_glass",
	"doors:door_glass_a",
	"doors:door_glass_b",
	"doors:door_glass_c",
	"doors:door_glass_d",
	"doors:door_obsidian_glass",
	"doors:door_obsidian_glass_a",
	"doors:door_obsidian_glass_b",
	"doors:door_obsidian_glass_c",
	"doors:door_obsidian_glass_d",
	"doors:door_steel",
	"doors:door_steel_a",
	"doors:door_steel_b",
	"doors:door_steel_c",
	"doors:door_steel_d",
	"doors:door_wood",
	"doors:door_wood_a",
	"doors:door_wood_b",
	"doors:door_wood_c",
	"doors:door_wood_d",
	"doors:gate_acacia_wood_closed",
	"doors:gate_acacia_wood_open",
	"doors:gate_aspen_wood_closed",
	"doors:gate_aspen_wood_open",
	"doors:gate_junglewood_closed",
	"doors:gate_junglewood_open",
	"doors:gate_pine_wood_closed",
	"doors:gate_pine_wood_open",
	"doors:gate_wood_closed",
	"doors:gate_wood_open",
	"doors:hidden",
	"doors:trapdoor",
	"doors:trapdoor_open",
	"doors:trapdoor_steel",
	"doors:trapdoor_steel_open",

	"stairs:slab_bronzeblock",
	"stairs:slab_copperblock",
	"stairs:slab_steelblock",
	"stairs:slab_tinblock",
	"stairs:stair_bronzeblock",
	"stairs:stair_copperblock",
	"stairs:stair_inner_bronzeblock",
	"stairs:stair_inner_copperblock",
	"stairs:stair_inner_steelblock",
	"stairs:stair_inner_tinblock",
	"stairs:stair_outer_bronzeblock",
	"stairs:stair_outer_copperblock",
	"stairs:stair_outer_steelblock",
	"stairs:stair_outer_tinblock",
	"stairs:stair_steelblock",
	"stairs:stair_tinblock",

	"stairs:slab_acacia_wood",
	"stairs:slab_aspen_wood",
	"stairs:slab_brick",
	"stairs:slab_cobble",
	"stairs:slab_desert_cobble",
	"stairs:slab_desert_sandstone",
	"stairs:slab_desert_sandstone_block",
	"stairs:slab_desert_sandstone_brick",
	"stairs:slab_desert_stone",
	"stairs:slab_desert_stone_block",
	"stairs:slab_desert_stonebrick",
	"stairs:slab_glass",
	"stairs:slab_goldblock",
	"stairs:slab_ice",
	"stairs:slab_junglewood",
	"stairs:slab_mossycobble",
	"stairs:slab_obsidian",
	"stairs:slab_obsidian_block",
	"stairs:slab_obsidian_glass",
	"stairs:slab_obsidianbrick",
	"stairs:slab_pine_wood",
	"stairs:slab_sandstone",
	"stairs:slab_sandstone_block",
	"stairs:slab_sandstonebrick",
	"stairs:slab_silver_sandstone",
	"stairs:slab_silver_sandstone_block",
	"stairs:slab_silver_sandstone_brick",
	"stairs:slab_snowblock",
	"stairs:slab_stone",
	"stairs:slab_stone_block",
	"stairs:slab_stonebrick",
	"stairs:slab_straw",
	"stairs:slab_wood",
	"stairs:stair_acacia_wood",
	"stairs:stair_aspen_wood",
	"stairs:stair_brick",
	"stairs:stair_cobble",
	"stairs:stair_desert_cobble",
	"stairs:stair_desert_sandstone",
	"stairs:stair_desert_sandstone_block",
	"stairs:stair_desert_sandstone_brick",
	"stairs:stair_desert_stone",
	"stairs:stair_desert_stone_block",
	"stairs:stair_desert_stonebrick",
	"stairs:stair_glass",
	"stairs:stair_goldblock",
	"stairs:stair_ice",
	"stairs:stair_inner_acacia_wood",
	"stairs:stair_inner_aspen_wood",
	"stairs:stair_inner_brick",
	"stairs:stair_inner_cobble",
	"stairs:stair_inner_desert_cobble",
	"stairs:stair_inner_desert_sandstone",
	"stairs:stair_inner_desert_sandstone_block",
	"stairs:stair_inner_desert_sandstone_brick",
	"stairs:stair_inner_desert_stone",
	"stairs:stair_inner_desert_stone_block",
	"stairs:stair_inner_desert_stonebrick",
	"stairs:stair_inner_glass",
	"stairs:stair_inner_goldblock",
	"stairs:stair_inner_ice",
	"stairs:stair_inner_junglewood",
	"stairs:stair_inner_mossycobble",
	"stairs:stair_inner_obsidian",
	"stairs:stair_inner_obsidian_block",
	"stairs:stair_inner_obsidian_glass",
	"stairs:stair_inner_obsidianbrick",
	"stairs:stair_inner_pine_wood",
	"stairs:stair_inner_sandstone",
	"stairs:stair_inner_sandstone_block",
	"stairs:stair_inner_sandstonebrick",
	"stairs:stair_inner_silver_sandstone",
	"stairs:stair_inner_silver_sandstone_block",
	"stairs:stair_inner_silver_sandstone_brick",
	"stairs:stair_inner_snowblock",
	"stairs:stair_inner_stone",
	"stairs:stair_inner_stone_block",
	"stairs:stair_inner_stonebrick",
	"stairs:stair_inner_straw",
	"stairs:stair_inner_wood",
	"stairs:stair_junglewood",
	"stairs:stair_mossycobble",
	"stairs:stair_obsidian",
	"stairs:stair_obsidian_block",
	"stairs:stair_obsidian_glass",
	"stairs:stair_obsidianbrick",
	"stairs:stair_outer_acacia_wood",
	"stairs:stair_outer_aspen_wood",
	"stairs:stair_outer_brick",
	"stairs:stair_outer_cobble",
	"stairs:stair_outer_desert_cobble",
	"stairs:stair_outer_desert_sandstone",
	"stairs:stair_outer_desert_sandstone_block",
	"stairs:stair_outer_desert_sandstone_brick",
	"stairs:stair_outer_desert_stone",
	"stairs:stair_outer_desert_stone_block",
	"stairs:stair_outer_desert_stonebrick",
	"stairs:stair_outer_glass",
	"stairs:stair_outer_goldblock",
	"stairs:stair_outer_ice",
	"stairs:stair_outer_junglewood",
	"stairs:stair_outer_mossycobble",
	"stairs:stair_outer_obsidian",
	"stairs:stair_outer_obsidian_block",
	"stairs:stair_outer_obsidian_glass",
	"stairs:stair_outer_obsidianbrick",
	"stairs:stair_outer_pine_wood",
	"stairs:stair_outer_sandstone",
	"stairs:stair_outer_sandstone_block",
	"stairs:stair_outer_sandstonebrick",
	"stairs:stair_outer_silver_sandstone",
	"stairs:stair_outer_silver_sandstone_block",
	"stairs:stair_outer_silver_sandstone_brick",
	"stairs:stair_outer_snowblock",
	"stairs:stair_outer_stone",
	"stairs:stair_outer_stone_block",
	"stairs:stair_outer_stonebrick",
	"stairs:stair_outer_straw",
	"stairs:stair_outer_wood",
	"stairs:stair_pine_wood",
	"stairs:stair_sandstone",
	"stairs:stair_sandstone_block",
	"stairs:stair_sandstonebrick",
	"stairs:stair_silver_sandstone",
	"stairs:stair_silver_sandstone_block",
	"stairs:stair_silver_sandstone_brick",
	"stairs:stair_snowblock",
	"stairs:stair_stone",
	"stairs:stair_stone_block",
	"stairs:stair_stonebrick",
	"stairs:stair_straw",
	"stairs:stair_wood",

	"xpanes:bar",
	"xpanes:bar_flat",
	"xpanes:door_steel_bar",
	"xpanes:door_steel_bar_a",
	"xpanes:door_steel_bar_b",
	"xpanes:door_steel_bar_c",
	"xpanes:door_steel_bar_d",
	"xpanes:obsidian_pane",
	"xpanes:obsidian_pane_flat",
	"xpanes:pane",
	"xpanes:pane_flat",
	"xpanes:trapdoor_steel_bar",
	"xpanes:trapdoor_steel_bar_open",

	"walls:cobble",
	"walls:desertcobble",
	"walls:mossycobble",
})

unified_inventory.add_category_items('environment', {
	"air",
	"default:cave_ice",
	"default:dirt_with_rainforest_litter",
	"default:gravel",
	"default:dry_dirt_with_dry_grass",
	"default:permafrost",
	"default:desert_stone",
	"default:ice",
	"default:dry_dirt",
	"default:obsidian",
	"default:sand",
	"default:river_water_source",
	"default:dirt_with_snow",
	"default:dirt_with_grass",
	"default:water_flowing",
	"default:dirt",
	"default:desert_sand",
	"default:permafrost_with_moss",
	"default:dirt_with_coniferous_litter",
	"default:water_source",
	"default:dirt_with_dry_grass",
	"default:river_water_flowing",
	"default:stone",
	"default:snow",
	"default:lava_flowing",
	"default:lava_source",
	"default:permafrost_with_stones",
	"default:dirt_with_grass_footsteps",
	"default:silver_sand",
	"default:snowblock",
	"default:clay",

	"farming:desert_sand_soil",
	"farming:desert_sand_soil_wet",
	"farming:dry_soil",
	"farming:dry_soil_wet",
	"farming:soil",
	"farming:soil_wet",
})

unified_inventory.add_category_items('lighting', {
	"default:mese_post_light_junglewood",
	"default:torch_ceiling",
	"default:meselamp",
	"default:torch",
	"default:mese_post_light_acacia_wood",
	"default:mese_post_light",
	"default:torch_wall",
	"default:mese_post_light_pine_wood",
	"default:mese_post_light_aspen_wood"
})
--]]


--[[ UNCATEGORISED

	"farming:string",

	"beds:bed_bottom",
	"beds:bed_top",
	"beds:fancy_bed_bottom",
	"beds:fancy_bed_top",
	"boats:boat",
	"bones:bones",

	"bucket:bucket_lava",
	"bucket:bucket_river_water",
	"bucket:bucket_water",

	"butterflies:butterfly_red",
	"butterflies:butterfly_violet",
	"butterflies:butterfly_white",
	"butterflies:hidden_butterfly_red",
	"butterflies:hidden_butterfly_violet",
	"butterflies:hidden_butterfly_white",

	"carts:brakerail",
	"carts:cart",
	"carts:powerrail",
	"carts:rail",

	"default:book",
	"default:book_written",
	"default:bookshelf",
	"default:chest",
	"default:chest_locked",
	"default:chest_locked_open",
	"default:chest_open",
	"default:clay_lump",
	"default:cloud",
	"default:coral_brown",
	"default:coral_cyan",
	"default:coral_green",
	"default:coral_orange",
	"default:coral_pink",
	"default:coral_skeleton",
	"default:flint",
	"default:furnace",
	"default:furnace_active",
	"default:key",
	"default:ladder_steel",
	"default:ladder_wood",
	"default:obsidian_shard",
	"default:paper",
	"default:sign_wall_steel",
	"default:sign_wall_wood",
	"default:stick",

	"fire:basic_flame",
	"fire:permanent_flame",
	"fireflies:firefly",
	"fireflies:firefly_bottle",
	"fireflies:hidden_firefly",

	"ignore",
	"unknown",

	"tnt:boom",
	"tnt:gunpowder",
	"tnt:gunpowder_burning",
	"tnt:tnt",
	"tnt:tnt_burning",
	"tnt:tnt_stick",

	"vessels:drinking_glass",
	"vessels:glass_bottle",
	"vessels:glass_fragments",
	"vessels:shelf",
	"vessels:steel_bottle",

	"dye:black",
	"dye:blue",
	"dye:brown",
	"dye:cyan",
	"dye:dark_green",
	"dye:dark_grey",
	"dye:green",
	"dye:grey",
	"dye:magenta",
	"dye:orange",
	"dye:pink",
	"dye:red",
	"dye:violet",
	"dye:white",
	"dye:yellow",

	"wool:black",
	"wool:blue",
	"wool:brown",
	"wool:cyan",
	"wool:dark_green",
	"wool:dark_grey",
	"wool:green",
	"wool:grey",
	"wool:magenta",
	"wool:orange",
	"wool:pink",
	"wool:red",
	"wool:violet",
	"wool:white",
	"wool:yellow",

	"unified_inventory:bag_large",
	"unified_inventory:bag_medium",
	"unified_inventory:bag_small",
--]]

--[[ LIST UNCATEGORIZED AFTER LOAD
minetest.register_on_mods_loaded(function()
	minetest.after(1, function ( )
		local l = {}
		for name,_ in pairs(minetest.registered_items) do
			if not unified_inventory.find_category(name) then
				-- minetest.log("error", minetest.serialize(minetest.registered_items[name]))
				table.insert(l, name)
			end
		end
		table.sort(l)
		minetest.log(table.concat(l, '",'.."\n"..'"'))
	end)
end)
--]]