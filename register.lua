local S = unified_inventory.gettext

minetest.register_privilege("creative", {
	description = "Can use the creative inventory",
	give_to_singleplayer = false,
})

minetest.register_privilege("ui_full", {
	description = "Forces UI to display in Full mode when Lite mode is configured globally",
	give_to_singleplayer = false,
})


local trash = minetest.create_detached_inventory("trash", {
	--allow_put = function(inv, listname, index, stack, player)
	--	if unified_inventory.is_creative(player:get_player_name()) then
	--		return stack:get_count()
	--	else
	--		return 0
	--	end
	--end,
	on_put = function(inv, listname, index, stack, player)
		inv:set_stack(listname, index, nil)
		local player_name = player:get_player_name()
		minetest.sound_play("trash", {to_player=player_name, gain = 1.0})
	end,
})
trash:set_size("main", 1)

unified_inventory.register_button("craft", {
	type = "image",
	image = "ui_craft_icon.png",
	tooltip = S("Crafting Grid")
})

unified_inventory.register_button("craftguide", {
	type = "image",
	image = "ui_craftguide_icon.png",
	tooltip = S("Crafting Guide")
})

unified_inventory.register_button("home_gui_set", {
	type = "image",
	image = "ui_sethome_icon.png",
	tooltip = S("Set home position"),
	hide_lite=true,
	action = function(player)
		local player_name = player:get_player_name()
		if minetest.check_player_privs(player_name, {home=true}) then
			unified_inventory.set_home(player, player:getpos())
			local home = unified_inventory.home_pos[player_name]
			if home ~= nil then
				minetest.sound_play("dingdong",
						{to_player=player_name, gain = 1.0})
				minetest.chat_send_player(player_name,
					S("Home position set to: %s"):format(minetest.pos_to_string(home)))
			end
		else
			minetest.chat_send_player(player_name,
				S("You don't have the \"home\" privilege!"))
		end
	end,
})

unified_inventory.register_button("home_gui_go", {
	type = "image",
	image = "ui_gohome_icon.png",
	tooltip = S("Go home"),
	hide_lite=true,
	action = function(player)
		local player_name = player:get_player_name()
		if minetest.check_player_privs(player_name, {home=true}) then
			minetest.sound_play("teleport",
				{to_player=player:get_player_name(), gain = 1.0})
			unified_inventory.go_home(player)
		else
			minetest.chat_send_player(player_name,
				S("You don't have the \"home\" privilege!"))
		end
	end,
})

unified_inventory.register_button("misc_set_day", {
	type = "image",
	image = "ui_sun_icon.png",
	tooltip = S("Set time to day"),
	hide_lite=true,
	action = function(player)
		local player_name = player:get_player_name()
		if minetest.check_player_privs(player_name, {settime=true}) then
			minetest.sound_play("birds",
					{to_player=player_name, gain = 1.0})
			minetest.set_timeofday((6000 % 24000) / 24000)
			minetest.chat_send_player(player_name,
				S("Time of day set to 6am"))
		else
			minetest.chat_send_player(player_name,
				S("You don't have the settime privilege!"))
		end
	end,
})

unified_inventory.register_button("misc_set_night", {
	type = "image",
	image = "ui_moon_icon.png",
	tooltip = S("Set time to night"),
	hide_lite=true,
	action = function(player)
		local player_name = player:get_player_name()
		if minetest.check_player_privs(player_name, {settime=true}) then
			minetest.sound_play("owl",
					{to_player=player_name, gain = 1.0})
			minetest.set_timeofday((21000 % 24000) / 24000)
			minetest.chat_send_player(player_name,
					S("Time of day set to 9pm"))
		else
			minetest.chat_send_player(player_name,
					S("You don't have the settime privilege!"))
		end
	end,
})

unified_inventory.register_button("clear_inv", {
	type = "image",
	image = "ui_trash_icon.png",
	tooltip = S("Clear inventory"),
	action = function(player)
		local player_name = player:get_player_name()
		if not unified_inventory.is_creative(player_name) then
			minetest.chat_send_player(player_name,
					S("This button has been disabled outside"
					.." of creative mode to prevent"
					.." accidental inventory trashing."
					.."\nUse the trash slot instead."))
			return
		end
		player:get_inventory():set_list("main", {})
		minetest.chat_send_player(player_name, 'Inventory Cleared!')
		minetest.sound_play("trash_all",
				{to_player=player_name, gain = 1.0})
	end,
})

unified_inventory.register_page("craft", {
	get_formspec = function(player, perplayer_formspec)

		local formspecy = perplayer_formspec.formspec_y
		local formheadery =  perplayer_formspec.form_header_y

		local player_name = player:get_player_name()
		local formspec = "background[2,"..formspecy..";6,3;ui_crafting_form.png]"
		formspec = formspec.."background[0,"..(formspecy + 3.5)..";8,4;ui_main_inventory.png]"
		formspec = formspec.."label[0,"..formheadery..";Crafting]"
		formspec = formspec.."listcolors[#00000000;#00000000]"
		formspec = formspec.."list[current_player;craftpreview;6,"..formspecy..";1,1;]"
		formspec = formspec.."list[current_player;craft;2,"..formspecy..";3,3;]"
		formspec = formspec.."label[7,"..(formspecy + 1.5)..";" .. S("Trash:") .. "]"
		formspec = formspec.."list[detached:trash;main;7,"..(formspecy + 2)..";1,1;]"
		formspec = formspec.."listring[current_player;main]"
		if unified_inventory.is_creative(player_name) then
			formspec = formspec.."listring[detached:trash;main]"
			formspec = formspec.."label[0,"..(formspecy + 1.5)..";" .. S("Refill:") .. "]"
			formspec = formspec.."list[detached:"..minetest.formspec_escape(player_name).."refill;main;0,"..(formspecy +2)..";1,1;]"
		else
			formspec = formspec.."listring[current_name;craft]"
		end
		return {formspec=formspec}
	end,
})

-- stack_image_button(): generate a form button displaying a stack of items
--
-- The specified item may be a group.  In that case, the group will be
-- represented by some item in the group, along with a flag indicating
-- that it's a group.  If the group contains only one item, it will be
-- treated as if that item had been specified directly.

local function stack_image_button(x, y, w, h, buttonname_prefix, item)
	local name = item:get_name()
	local count = item:get_count()
	local show_is_group = false
	local displayitem = name.." "..count
	local selectitem = name
	if name:sub(1, 6) == "group:" then
		local group_name = name:sub(7)
		local group_item = unified_inventory.get_group_item(group_name)
		show_is_group = not group_item.sole
		displayitem = group_item.item or "unknown"
		selectitem = group_item.sole and displayitem or name
	end
	local label = show_is_group and "G" or ""
	return string.format("item_image_button[%f,%f;%u,%u;%s;%s;%s]",
			x, y, w, h,
			minetest.formspec_escape(displayitem),
			minetest.formspec_escape(buttonname_prefix..unified_inventory.mangle_for_formspec(selectitem)),
			label)
end

local recipe_text = {
	recipe = "Recipe",
	usage = "Usage",
}
local no_recipe_text = {
	recipe = "No recipes",
	usage = "No usages",
}
local role_text = {
	recipe = "Result",
	usage = "Ingredient",
}
local other_dir = {
	recipe = "usage",
	usage = "recipe",
}

unified_inventory.register_page("craftguide", {
	get_formspec = function(player, perplayer_formspec)

		local formspecy =    perplayer_formspec.formspec_y
		local formheadery =  perplayer_formspec.form_header_y
		local craftresultx = perplayer_formspec.craft_result_x
		local craftresulty = perplayer_formspec.craft_result_y

		local player_name = player:get_player_name()
		local player_privs = minetest.get_player_privs(player_name)
		local formspec = ""
		formspec = formspec.."background[0,"..(formspecy + 3.5)..";8,4;ui_main_inventory.png]"
		formspec = formspec.."label[0,"..formheadery..";" .. S("Crafting Guide") .. "]"
		formspec = formspec.."listcolors[#00000000;#00000000]"
		local item_name = unified_inventory.current_item[player_name]
		if not item_name then return {formspec=formspec} end

		local dir = unified_inventory.current_craft_direction[player_name]
		local rdir
		if dir == "recipe" then rdir = "usage" end
		if dir == "usage" then rdir = "recipe" end
		local crafts = unified_inventory.crafts_for[dir][item_name]
		local alternate = unified_inventory.alternate[player_name]
		local alternates, craft
		if crafts ~= nil and #crafts > 0 then
			alternates = #crafts
			craft = crafts[alternate]
		end

		formspec = formspec.."background[0.5,"..(formspecy + 0.2)..";8,3;ui_craftguide_form.png]"
		formspec = formspec.."textarea["..craftresultx..","..craftresulty
                           ..";10,1;;"..minetest.formspec_escape(role_text[dir]..": "..item_name)..";]"
		formspec = formspec..stack_image_button(0, formspecy, 1.1, 1.1, "item_button_"
		                   .. rdir .. "_", ItemStack(item_name))

		if not craft then
			formspec = formspec.."label[5.5,"..(formspecy + 2.35)..";"
			                   ..minetest.formspec_escape(no_recipe_text[dir]).."]"
			local no_pos = dir == "recipe" and 4.5 or 6.5
			local item_pos = dir == "recipe" and 6.5 or 4.5
			formspec = formspec.."image["..no_pos..","..formspecy..";1.1,1.1;ui_no.png]"
			formspec = formspec..stack_image_button(item_pos, formspecy, 1.1, 1.1, "item_button_"
			                   ..other_dir[dir].."_", ItemStack(item_name))
			if player_privs.give == true then
				formspec = formspec.."label[0,"..(formspecy + 2.10)..";" .. S("Give me:") .. "]"
						.."button[0,  "..(formspecy + 2.7)..";0.6,0.5;craftguide_giveme_1;1]"
						.."button[0.6,"..(formspecy + 2.7)..";0.7,0.5;craftguide_giveme_10;10]"
						.."button[1.3,"..(formspecy + 2.7)..";0.8,0.5;craftguide_giveme_99;99]"
			end
			return {formspec = formspec}
		end

		local craft_type = unified_inventory.registered_craft_types[craft.type] or
				unified_inventory.craft_type_defaults(craft.type, {})
		if craft_type.icon then
			formspec = formspec..string.format(" image[%f,%f;%f,%f;%s]",5.7,(formspecy + 0.05),0.5,0.5,craft_type.icon)
		end
		formspec = formspec.."label[5.5,"..(formspecy + 1)..";" .. minetest.formspec_escape(craft_type.description).."]"
		formspec = formspec..stack_image_button(6.5, formspecy, 1.1, 1.1, "item_button_usage_", ItemStack(craft.output))
		local display_size = craft_type.dynamic_display_size and craft_type.dynamic_display_size(craft) or { width = craft_type.width, height = craft_type.height }
		local craft_width = craft_type.get_shaped_craft_width and craft_type.get_shaped_craft_width(craft) or display_size.width

		-- This keeps recipes aligned to the right,
		-- so that they're close to the arrow.
		local xoffset = 1.5 + (3 - display_size.width)
		for y = 1, display_size.height do
		for x = 1, display_size.width do
			local item
			if craft and x <= craft_width then
				item = craft.items[(y-1) * craft_width + x]
			end
			if item then
				formspec = formspec..stack_image_button(
						xoffset + x, formspecy - 1 + y, 1.1, 1.1,
						"item_button_recipe_",
						ItemStack(item))
			else
				-- Fake buttons just to make grid
				formspec = formspec.."image_button["
					..tostring(xoffset + x)..","..tostring(formspecy - 1 + y)
					..";1,1;ui_blank_image.png;;]"
			end
		end
		end

		if craft_type.uses_crafting_grid then
			formspec = formspec.."label[0,"..(formspecy + 0.9)..";" .. S("To craft grid:") .. "]"
					.."button[0,  "..(formspecy + 1.5)..";0.6,0.5;craftguide_craft_1;1]"
					.."button[0.6,"..(formspecy + 1.5)..";0.7,0.5;craftguide_craft_10;10]"
					.."button[1.3,"..(formspecy + 1.5)..";0.8,0.5;craftguide_craft_max;" .. S("All") .. "]"
		end
		if player_privs.give then
			formspec = formspec.."label[0,"..(formspecy + 2.1)..";" .. S("Give me:") .. "]"
					.."button[0,  "..(formspecy + 2.7)..";0.6,0.5;craftguide_giveme_1;1]"
					.."button[0.6,"..(formspecy + 2.7)..";0.7,0.5;craftguide_giveme_10;10]"
					.."button[1.3,"..(formspecy + 2.7)..";0.8,0.5;craftguide_giveme_99;99]"
		end

		if alternates and alternates > 1 then
			formspec = formspec.."label[5.5,"..(formspecy + 1.6)..";"..recipe_text[dir].." "
					..tostring(alternate).." of "
					..tostring(alternates).."]"
					.."button[5.5,"..(formspecy + 2)..";2,1;alternate;" .. S("Alternate") .. "]"
		end
		return {formspec = formspec}
	end,
})

local function craftguide_giveme(player, formname, fields)
	local amount
	for k, v in pairs(fields) do
		amount = k:match("craftguide_giveme_(.*)")
		if amount then break end
	end
	if not amount then return end

	amount = tonumber(amount)
	if amount == 0 then return end

	local player_name = player:get_player_name()

	local output = unified_inventory.current_item[player_name]
	if (not output) or (output == "") then return end

	local player_inv = player:get_inventory()

	player_inv:add_item("main", {name = output, count = amount})
end

-- tells if an item can be moved and returns an index if so
local function item_fits(player_inv, craft_item, needed_item)
	local need_group = string.sub(needed_item, 1, 6) == "group:"
	if need_group then
		need_group = string.sub(needed_item, 7)
	end
	if craft_item
	and not craft_item:is_empty() then
		local ciname = craft_item:get_name()

		-- abort if the item there isn't usable
		if ciname ~= needed_item
		and not need_group then
			return
		end

		-- abort if no item fits onto it
		if craft_item:get_count() >= craft_item:get_definition().stack_max then
			return
		end

		-- use the item there if it's in the right group and a group item is needed
		if need_group then
			if minetest.get_item_group(ciname, need_group) == 0 then
				return
			end
			needed_item = ciname
			need_group = false
		end
	end

	if need_group then
		-- search an item of the specific group
		for i,item in pairs(player_inv:get_list("main")) do
			if not item:is_empty()
			and minetest.get_item_group(item:get_name(), need_group) > 0 then
				return i
			end
		end

		-- no index found
		return
	end

	-- search an item with a the name needed_item
	for i,item in pairs(player_inv:get_list("main")) do
		if not item:is_empty()
		and item:get_name() == needed_item then
			return i
		end
	end

	-- no index found
end

-- modifies the player inventory and returns the changed craft_item if possible
local function move_item(player_inv, craft_item, needed_item)
	local stackid = item_fits(player_inv, craft_item, needed_item)
	if not stackid then
		return
	end
	local wanted_stack = player_inv:get_stack("main", stackid)
	local taken_item = wanted_stack:take_item()
	player_inv:set_stack("main", stackid, wanted_stack)

	if not craft_item
	or craft_item:is_empty() then
		return taken_item
	end

	craft_item:add_item(taken_item)
	return craft_item
end

local function craftguide_craft(player, formname, fields)
	local amount
	for k, v in pairs(fields) do
		amount = k:match("craftguide_craft_(.*)")
		if amount then break end
	end
	if not amount then return end
	local player_name = player:get_player_name()

	local output = unified_inventory.current_item[player_name]
	if (not output) or (output == "") then return end

	local player_inv = player:get_inventory()

	local crafts = unified_inventory.crafts_for[unified_inventory.current_craft_direction[player_name]][output]
	if (not crafts) or (#crafts == 0) then return end

	local alternate = unified_inventory.alternate[player_name]

	local craft = crafts[alternate]
	if craft.width > 3 then return end

	local needed = craft.items

	local craft_list = player_inv:get_list("craft")

	local width = craft.width
	if width == 0 then
		-- Shapeless recipe
		width = 3
	end

	amount = tonumber(amount) or 99
	--[[
	if amount == "max" then
		amount = 99 -- Arbitrary; need better way to do this.
	else
		amount = tonumber(amount)
	end--]]

	for iter = 1, amount do
		local index = 1
		for y = 1, 3 do
			for x = 1, width do
				local needed_item = needed[index]
				if needed_item then
					local craft_index = ((y - 1) * 3) + x
					local craft_item = craft_list[craft_index]
					local newitem = move_item(player_inv, craft_item, needed_item)
					if newitem then
						craft_list[craft_index] = newitem
					end
				end
				index = index + 1
			end
		end
	end

	player_inv:set_list("craft", craft_list)

	unified_inventory.set_inventory_formspec(player, "craft")
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	for k, v in pairs(fields) do
		if k:match("craftguide_craft_") then
			craftguide_craft(player, formname, fields)
			return
		end
		if k:match("craftguide_giveme_") then
			craftguide_giveme(player, formname, fields)
			return
		end
	end
end)
