--[[ 
Bags for Minetest

Copyright (c) 2012 cornernote, Brett O'Donnell <cornernote@gmail.com>
License: GPLv3
--]]

local S = minetest.get_translator("unified_inventory")
local F = minetest.formspec_escape

unified_inventory.register_page("bags", {
	get_formspec = function(player)
		local player_name = player:get_player_name()
		return { formspec = table.concat({
			"background[0.06,0.99;7.92,7.52;ui_bags_main_form.png]",
			"label[0,0;" .. F(S("Bags")) .. "]",
			"button[0,2;2,0.5;bag1;" .. F(S("Bag @1", 1)) .. "]",
			"button[2,2;2,0.5;bag2;" .. F(S("Bag @1", 2)) .. "]",
			"button[4,2;2,0.5;bag3;" .. F(S("Bag @1", 3)) .. "]",
			"button[6,2;2,0.5;bag4;" .. F(S("Bag @1", 4)) .. "]",
			"listcolors[#00000000;#00000000]",
			"list[detached:" .. F(player_name) .. "_bags;bag1;0.5,1;1,1;]",
			"list[detached:" .. F(player_name) .. "_bags;bag2;2.5,1;1,1;]",
			"list[detached:" .. F(player_name) .. "_bags;bag3;4.5,1;1,1;]",
			"list[detached:" .. F(player_name) .. "_bags;bag4;6.5,1;1,1;]"
		}) }
	end,
})

unified_inventory.register_button("bags", {
	type = "image",
	image = "ui_bags_icon.png",
	tooltip = S("Bags"),
	hide_lite=true
})

local function get_player_bag_stack(player, i)
	return minetest.get_inventory({
		type = "detached",
		name = player:get_player_name() .. "_bags"
	}):get_stack("bag" .. i, 1)
end

for bag_i = 1, 4 do
	unified_inventory.register_page("bag" .. bag_i, {
		get_formspec = function(player)
			local stack = get_player_bag_stack(player, bag_i)
			local image = stack:get_definition().inventory_image
			local fs = {
				"image[7,0;1,1;" .. image .. "]",
				"label[0,0;" .. F(S("Bag @1", bag_i)) .. "]",
				"listcolors[#00000000;#00000000]",
				"list[current_player;bag" .. bag_i .. "contents;0,1;8,3;]",
				"listring[current_name;bag" .. bag_i .. "contents]",
				"listring[current_player;main]"
			}
			local slots = stack:get_definition().groups.bagslots
			if slots == 8 then
					fs[#fs + 1] = "background[0.06,0.99;7.92,7.52;ui_bags_sm_form.png]"
			elseif slots == 16 then
					fs[#fs + 1] = "background[0.06,0.99;7.92,7.52;ui_bags_med_form.png]"
			elseif slots == 24 then
					fs[#fs + 1] = "background[0.06,0.99;7.92,7.52;ui_bags_lg_form.png]"
			end
			local player_name = player:get_player_name() -- For if statement.
			if unified_inventory.trash_enabled
					or unified_inventory.is_creative(player_name)
					or minetest.get_player_privs(player_name).give then
				fs[#fs + 1] = "background[6.06,0;0.92,0.92;ui_bags_trash.png]"
						.. "list[detached:trash;main;6,0.1;1,1;]"
			end
			local inv = player:get_inventory()
			for i = 1, 4 do
				local def = get_player_bag_stack(player, i):get_definition()
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
					fs[#fs + 1] = string.format("image_button[%i,0;1,1;%s;bag%i;%s]",
							i + 1, img, i, label)
				end
			end
			return { formspec = table.concat(fs) }
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
			if not stack:get_definition().groups.bagslots then
				return
			end
			unified_inventory.set_inventory_formspec(player, "bag" .. i)
			return
		end
	end
end)

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
	local bags_meta = meta:get_string("unified_inventory:bags")
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

	-- Clean up deprecated garbage after saving
	for i = 1, 4 do
		local bag = "bag" .. i
		player_inv:set_size(bag, 0)
	end
end

minetest.register_on_joinplayer(function(player)
	local player_inv = player:get_inventory()
	local player_name = player:get_player_name()
	local bags_inv = minetest.create_detached_inventory(player_name .. "_bags",{
		on_put = function(inv, listname, index, stack, player)
			player:get_inventory():set_size(listname .. "contents",
					stack:get_definition().groups.bagslots)
			save_bags_metadata(player, inv)
		end,
		allow_put = function(inv, listname, index, stack, player)
			local new_slots = stack:get_definition().groups.bagslots
			if not new_slots then
				return 0
			end
			local player_inv = player:get_inventory()
			local old_slots = player_inv:get_size(listname .. "contents")

			if new_slots >= old_slots then
				return 1
			end

			-- using a smaller bag, make sure it fits
			local old_list = player_inv:get_list(listname .. "contents")
			local new_list = {}
			local slots_used = 0
			local use_new_list = false

			for i, v in ipairs(old_list) do
				if v and not v:is_empty() then
					slots_used = slots_used + 1
					use_new_list = i > new_slots
					new_list[slots_used] = v
				end
			end
			if new_slots >= slots_used then
				if use_new_list then
					player_inv:set_list(listname .. "contents", new_list)
				end
				return 1
			end
			-- New bag is smaller: Disallow inserting
			return 0
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
			{"",           "farming:cotton", ""},
			{"group:wool", "group:wool",     "group:wool"},
			{"group:wool", "group:wool",     "group:wool"},
		},
	})

	minetest.register_craft({
		output = "unified_inventory:bag_medium",
		recipe = {
			{"",               "",                            ""},
			{"farming:cotton", "unified_inventory:bag_small", "farming:cotton"},
			{"farming:cotton", "unified_inventory:bag_small", "farming:cotton"},
		},
	})

	minetest.register_craft({
		output = "unified_inventory:bag_large",
		recipe = {
			{"",               "",                             ""},
			{"farming:cotton", "unified_inventory:bag_medium", "farming:cotton"},
			{"farming:cotton", "unified_inventory:bag_medium", "farming:cotton"},
	    },
	})
end
