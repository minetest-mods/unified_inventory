--[[
Bags for Minetest

Copyright (c) 2012 cornernote, Brett O'Donnell <cornernote@gmail.com>
License: GPLv3
--]]

local S = minetest.get_translator("unified_inventory")
local F = minetest.formspec_escape
local ui = unified_inventory

ui.register_page("bags", {
	get_formspec = function(player)
		local player_name = player:get_player_name()
		return { formspec = table.concat({
			ui.style_full.standard_inv_bg,
			ui.single_slot(0.925, 1.5),
			ui.single_slot(3.425, 1.5),
			ui.single_slot(5.925, 1.5),
			ui.single_slot(8.425, 1.5),
			"label["..ui.style_full.form_header_x..","..ui.style_full.form_header_y..";" .. F(S("Bags")) .. "]",
			"button[0.6125,2.75;1.875,0.75;bag1;" .. F(S("Bag @1", 1)) .. "]",
			"button[3.1125,2.75;1.875,0.75;bag2;" .. F(S("Bag @1", 2)) .. "]",
			"button[5.6125,2.75;1.875,0.75;bag3;" .. F(S("Bag @1", 3)) .. "]",
			"button[8.1125,2.75;1.875,0.75;bag4;" .. F(S("Bag @1", 4)) .. "]",
			"listcolors[#00000000;#00000000]",
			"list[detached:" .. F(player_name) .. "_bags;bag1;1.075,1.65;1,1;]",
			"list[detached:" .. F(player_name) .. "_bags;bag2;3.575,1.65;1,1;]",
			"list[detached:" .. F(player_name) .. "_bags;bag3;6.075,1.65;1,1;]",
			"list[detached:" .. F(player_name) .. "_bags;bag4;8.575,1.65;1,1;]"
		}) }
	end,
})

ui.register_button("bags", {
	type = "image",
	image = "ui_bags_icon.png",
	tooltip = S("Bags"),
	hide_lite=true
})

local function get_player_bag_stack(player, i)
	local inventory = minetest.get_inventory({
		type = "detached",
		name = player:get_player_name() .. "_bags"
	})
	if not inventory then return nil end
	return inventory:get_stack("bag" .. i, 1)
end

for bag_i = 1, 4 do
	ui.register_page("bag" .. bag_i, {
		get_formspec = function(player)
			local stack = get_player_bag_stack(player, bag_i)
			if not stack then return end
			local image = stack:get_definition().inventory_image
			local slots = stack:get_definition().groups.bagslots

			local formspec = {
				ui.style_full.standard_inv_bg,
				ui.make_inv_img_grid(0.3, 1.5, 8, slots/8),
				"image[9.2,0.4;1,1;" .. image .. "]",
				"label[0.3,0.65;" .. F(S("Bag @1", bag_i)) .. "]",
				"listcolors[#00000000;#00000000]",
				"listring[current_player;main]",
				string.format("list[current_player;bag%icontents;%f,%f;8,3;]",
				    bag_i, 0.3 + ui.list_img_offset, 1.5 + ui.list_img_offset),
				"listring[current_name;bag" .. bag_i .. "contents]",
			}
			local n = #formspec + 1

			local player_name = player:get_player_name() -- For if statement.
			if ui.trash_enabled
				or ui.is_creative(player_name)
				or minetest.get_player_privs(player_name).give then
					formspec[n] = ui.make_trash_slot(7.8, 0.25)
					n = n + 1
			end
			local inv = player:get_inventory()
			for i = 1, 4 do
				local def_stack = get_player_bag_stack(player, i)
				if def_stack then
					local def = def_stack:get_definition()
					if def.groups.bagslots then
						local list_name = "bag" .. i .. "contents"
						local size = inv:get_size(list_name)
						local used = 0
						for si = 1, size do
							local stk = inv:get_stack(list_name, si)
							if not stk:is_empty() then
								used = used + 1
							end
						end
						local img = def.inventory_image
						local label = F(S("Bag @1", i)) .. "\n" .. used .. "/" .. size
						formspec[n] = string.format("image_button[%f,0.4;1,1;%s;bag%i;%s]",
								(i + 1.35)*1.25, img, i, label)
						n = n + 1
					end
				end
			end
			return { formspec = table.concat(formspec) }
		end,
	})
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "" then
		return
	end
	for i = 1, 4 do
		if fields["bag" .. i] then
			local stack = get_player_bag_stack(player, i)
			if not stack or not stack:get_definition().groups.bagslots then
				return
			end
			ui.set_inventory_formspec(player, "bag" .. i)
			return
		end
	end
end)

-- Player slots are preserved when unified_inventory is disabled. Do not allow modification.
-- Fix: use a detached inventory and store the data separately.
local function save_bags_metadata(player, bags_inv)
	local is_empty = true
	local bags = {}
	for i = 1, 4 do
		local bag = "bag" .. i
		if not bags_inv:is_empty(bag) then
			-- Stack limit is 1, otherwise use stack:to_string()
			bags[i] = bags_inv:get_stack(bag, 1):get_name()
			is_empty = false
		end
	end
	local meta = player:get_meta()
	if is_empty then
		meta:set_string("unified_inventory:bags", nil)
	else
		meta:set_string("unified_inventory:bags",
			minetest.serialize(bags))
	end
end

local function load_bags_metadata(player, bags_inv)
	local player_inv = player:get_inventory()
	local meta = player:get_meta()
	local bags_meta = meta:get("unified_inventory:bags")
	local bags = bags_meta and minetest.deserialize(bags_meta) or {}
	local dirty_meta = false
	if not bags_meta then
		-- Backwards compatiblity
		for i = 1, 4 do
			local bag = "bag" .. i
			if not player_inv:is_empty(bag) then
				-- Stack limit is 1, otherwise use stack:to_string()
				bags[i] = player_inv:get_stack(bag, 1):get_name()
				dirty_meta = true
			end
		end
	end
	-- Fill detached slots
	for i = 1, 4 do
		local bag = "bag" .. i
		bags_inv:set_size(bag, 1)
		bags_inv:set_stack(bag, 1, bags[i] or "")
	end

	if dirty_meta then
		-- Requires detached inventory to be set up
		save_bags_metadata(player, bags_inv)
	end

	-- Legacy: Clean up old player lists
	for i = 1, 4 do
		local bag = "bag" .. i
		player_inv:set_size(bag, 0)
	end
end

minetest.register_on_joinplayer(function(player)
	local player_name = player:get_player_name()
	local bags_inv = minetest.create_detached_inventory(player_name .. "_bags", {
		allow_put = function(inv, listname, index, stack, player)
			local new_slots = stack:get_definition().groups.bagslots
			if not new_slots then
				return 0 -- ItemStack is not a bag.
			end

			-- The execution order of `allow_put`/`allow_take` is not defined.
			-- We do not know the replacement ItemStack if the items are swapped.
			-- Hence, bag slot upgrades and downgrades are not possible with the
			-- current API.

			if not player:get_inventory():is_empty(listname .. "contents") then
				-- Legacy: in case `allow_take` is not executed on old Minetest versions.
				return 0
			end
			return 1
		end,
		on_put = function(inv, listname, index, stack, player)
			player:get_inventory():set_size(listname .. "contents",
					stack:get_definition().groups.bagslots)
			save_bags_metadata(player, inv)
		end,
		allow_take = function(inv, listname, index, stack, player)
			if player:get_inventory():is_empty(listname .. "contents") then
				return stack:get_count()
			end
			return 0
		end,
		on_take = function(inv, listname, index, stack, player)
			player:get_inventory():set_size(listname .. "contents", 0)
			save_bags_metadata(player, inv)
		end,
		allow_move = function()
			return 0
		end,
	}, player_name)

	load_bags_metadata(player, bags_inv)
end)


minetest.register_allow_player_inventory_action(function(player, action, inventory, info)
	-- From detached inventory -> player inventory: put & take callbacks
	if action ~= "put" or not info.listname:find("bag%dcontents") then
		return
	end
	if info.stack:get_definition().groups.bagslots then
		-- Problem 1: empty bags could be moved into their own slots
		-- Problem 2: cannot reliably keep track of ItemStack ownership due to
		--> Disallow all external bag movements into this list
		return 0
	end
end)

-- register bag tools
minetest.register_tool("unified_inventory:bag_small", {
	description = S("Small Bag"),
	inventory_image = "bags_small.png",
	groups = {bagslots=8},
})

minetest.register_tool("unified_inventory:bag_medium", {
	description = S("Medium Bag"),
	inventory_image = "bags_medium.png",
	groups = {bagslots=16},
})

minetest.register_tool("unified_inventory:bag_large", {
	description = S("Large Bag"),
	inventory_image = "bags_large.png",
	groups = {bagslots=24},
})

-- register bag crafts
if minetest.get_modpath("farming") ~= nil then
	minetest.register_craft({
		output = "unified_inventory:bag_small",
		recipe = {
			{"",           "farming:string", ""},
			{"group:wool", "group:wool",     "group:wool"},
			{"group:wool", "group:wool",     "group:wool"},
		},
	})

	minetest.register_craft({
		output = "unified_inventory:bag_medium",
		recipe = {
			{"",               "",                            ""},
			{"farming:string", "unified_inventory:bag_small", "farming:string"},
			{"farming:string", "unified_inventory:bag_small", "farming:string"},
		},
	})

	minetest.register_craft({
		output = "unified_inventory:bag_large",
		recipe = {
			{"",               "",                             ""},
			{"farming:string", "unified_inventory:bag_medium", "farming:string"},
			{"farming:string", "unified_inventory:bag_medium", "farming:string"},
	    },
	})
end
