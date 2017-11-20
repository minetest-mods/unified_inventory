-- Bags for Minetest

-- Copyright (c) 2012 cornernote, Brett O'Donnell <cornernote@gmail.com>
-- License: GPLv3

local S = unified_inventory.gettext
local F = unified_inventory.fgettext

unified_inventory.register_page("bags", {
	get_formspec = function(player)
		local player_name = player:get_player_name()
		local formspec = "background[0.06,0.99;7.92,7.52;ui_bags_main_form.png]"
		formspec = formspec.."label[0,0;"..F("Bags").."]"
		formspec = formspec.."button[0,2;2,0.5;bag1;"..F("Bag 1").."]"
		formspec = formspec.."button[2,2;2,0.5;bag2;"..F("Bag 2").."]"
		formspec = formspec.."button[4,2;2,0.5;bag3;"..F("Bag 3").."]"
		formspec = formspec.."button[6,2;2,0.5;bag4;"..F("Bag 4").."]"
		formspec = formspec.."listcolors[#00000000;#00000000]"
		formspec = formspec.."list[detached:"..minetest.formspec_escape(player_name).."_bags;bag1;0.5,1;1,1;]"
		formspec = formspec.."list[detached:"..minetest.formspec_escape(player_name).."_bags;bag2;2.5,1;1,1;]"
		formspec = formspec.."list[detached:"..minetest.formspec_escape(player_name).."_bags;bag3;4.5,1;1,1;]"
		formspec = formspec.."list[detached:"..minetest.formspec_escape(player_name).."_bags;bag4;6.5,1;1,1;]"
		return {formspec=formspec}
	end,
})

unified_inventory.register_button("bags", {
	type = "image",
	image = "ui_bags_icon.png",
	tooltip = S("Bags"),
	hide_lite=true
})

for i = 1, 4 do
	local bi = i
	unified_inventory.register_page("bag"..bi, {
		get_formspec = function(player)
			local stack = player:get_inventory():get_stack("bag"..bi, 1)
			local image = stack:get_definition().inventory_image
			local formspec = ("image[7,0;1,1;"..image.."]"
					.."label[0,0;"..F("Bag @1", bi).."]"
					.."listcolors[#00000000;#00000000]"
					.."list[current_player;bag"..bi.."contents;0,1;8,3;]"
					.."listring[current_name;bag"..bi.."contents]"
					.."listring[current_player;main]")
			local slots = stack:get_definition().groups.bagslots
			if slots == 8 then
				formspec = formspec.."background[0.06,0.99;7.92,7.52;ui_bags_sm_form.png]"
			elseif slots == 16 then
				formspec = formspec.."background[0.06,0.99;7.92,7.52;ui_bags_med_form.png]"
			elseif slots == 24 then
				formspec = formspec.."background[0.06,0.99;7.92,7.52;ui_bags_lg_form.png]"
			end
			local player_name = player:get_player_name() -- For if statement.
			if unified_inventory.trash_enabled or unified_inventory.is_creative(player_name) or minetest.get_player_privs(player_name).give then
				formspec = (formspec.."background[6.06,0;0.92,0.92;ui_bags_trash.png]"
						.."list[detached:trash;main;6,0.1;1,1;]")
			end
			local inv = player:get_inventory()
			for i = 1, 4 do
				local def = inv:get_stack("bag"..i, 1):get_definition()
				local button
				if def.groups.bagslots then
					local list_name = "bag"..i.."contents"
					local size = inv:get_size(list_name)
					local used = 0
					for si = 1, size do
						local stk = inv:get_stack(list_name, si)
						if not stk:is_empty() then
							used = used + 1
						end
					end
					local img = def.inventory_image
					local label = F("Bag @1", i).."\n"..used.."/"..size
					button = "image_button["..(i+1)..",0;1,1;"..img..";bag"..i..";"..label.."]"
				else
					button = ""
				end
				formspec = formspec..button
			end
			return {formspec=formspec}
		end,
	})
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "" then
		return
	end
	for i = 1, 4 do
		if fields["bag"..i] then
			local stack = player:get_inventory():get_stack("bag"..i, 1)
			if not stack:get_definition().groups.bagslots then
				return
			end
			unified_inventory.set_inventory_formspec(player, "bag"..i)
			return
		end
	end
end)

minetest.register_on_joinplayer(function(player)
	local player_inv = player:get_inventory()
	local player_name = player:get_player_name()
	local bags_inv = minetest.create_detached_inventory(player_name.."_bags",{
		on_put = function(inv, listname, index, stack, player)
			player:get_inventory():set_stack(listname, index, stack)
			player:get_inventory():set_size(listname.."contents",
					stack:get_definition().groups.bagslots)
		end,
		on_take = function(inv, listname, index, stack, player)
			player:get_inventory():set_stack(listname, index, nil)
		end,
		allow_put = function(inv, listname, index, stack, player)
			local new_slots = stack:get_definition().groups.bagslots
			if new_slots then
				local player_inv = player:get_inventory()
				local old_slots = player_inv:get_size(listname.."contents")

				if new_slots >= old_slots then
					return 1
				else
					-- using a smaller bag, make sure it fits
					local old_list = player_inv:get_list(listname.."contents")
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
							player_inv:set_list(listname.."contents", new_list)
						end
						return 1
					end
				end
			end
			return 0
		end,
		allow_take = function(inv, listname, index, stack, player)
			if player:get_inventory():is_empty(listname.."contents") then
				return stack:get_count()
			else
				return 0
			end
		end,
		allow_move = function(inv, from_list, from_index, to_list, to_index, count, player)
			return 0
		end,
	}, player_name)
	for i=1,4 do
		local bag = "bag"..i
		player_inv:set_size(bag, 1)
		bags_inv:set_size(bag, 1)
		bags_inv:set_stack(bag, 1, player_inv:get_stack(bag, 1))
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
