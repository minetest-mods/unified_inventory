local S = unified_inventory.gettext

minetest.register_privilege("creative", {
	description = "Can use the creative inventory",
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
	action = function(player)
		local player_name = player:get_player_name()
		unified_inventory.set_home(player, player:getpos())
		local home = unified_inventory.home_pos[player_name]
		if home ~= nil then
			minetest.sound_play("dingdong",
					{to_player=player_name, gain = 1.0})
			minetest.chat_send_player(player_name,
				S("Home position set to: %s"):format(minetest.pos_to_string(home)))
		end
	end,
})

unified_inventory.register_button("home_gui_go", {
	type = "image",
	image = "ui_gohome_icon.png",
	tooltip = S("Go home"),
	action = function(player)
		minetest.sound_play("teleport",
				{to_player=player:get_player_name(), gain = 1.0})
		unified_inventory.go_home(player)
	end,
})

unified_inventory.register_button("misc_set_day", {
	type = "image",
	image = "ui_sun_icon.png",
	tooltip = S("Set time to day"),
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
				S("You don't have the settime priviledge!"))
		end
	end,
})

unified_inventory.register_button("misc_set_night", {
	type = "image",
	image = "ui_moon_icon.png",
	tooltip = S("Set time to night"),
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
					S("You don't have the settime priviledge!"))
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
	get_formspec = function(player, formspec)
		local player_name = player:get_player_name()
		local formspec = "background[0,1;8,3;ui_crafting_form.png]"
		formspec = formspec.."background[0,4.5;8,4;ui_main_inventory.png]"
		formspec = formspec.."label[0,0;Crafting]"
		formspec = formspec.."listcolors[#00000000;#00000000]"
		formspec = formspec.."list[current_player;craftpreview;6,1;1,1;]"
		formspec = formspec.."list[current_player;craft;2,1;3,3;]"
		formspec = formspec.."label[7,2.5;" .. S("Trash:") .. "]"
		formspec = formspec.."list[detached:trash;main;7,3;1,1;]"
		if unified_inventory.is_creative(player_name) then
			formspec = formspec.."label[0,2.5;" .. S("Refill:") .. "]"
			formspec = formspec.."list[detached:"..minetest.formspec_escape(player_name).."refill;main;0,3;1,1;]"
		end
		return {formspec=formspec}
	end,
})


-- stack_image_button(): generate a form button displaying a stack of items
--
-- Normally a simple item_image_button[] is used.  If the stack contains
-- more than one item, item_image_button[] doesn't have an option to
-- display an item count in the way that an inventory slot does, so
-- we have to fake it using the label facility.
--
-- The specified item may be a group.  In that case, the group will be
-- represented by some item in the group, along with a flag indicating
-- that it's a group.  If the group contains only one item, it will be
-- treated as if that item had been specified directly.

local function stack_image_button(x, y, w, h, buttonname_prefix, item)
	local name = item:get_name()
	local count = item:get_count()
	local show_is_group = false
	local displayitem = name
	local selectitem = name
	if name:sub(1, 6) == "group:" then
		local group_name = name:sub(7)
		local group_item = unified_inventory.get_group_item(group_name)
		show_is_group = not group_item.sole
		displayitem = group_item.item or "unknown"
		selectitem = group_item.sole and displayitem or name
	end
	local label = string.format("\n\n%s%7d", show_is_group and "G" or "  ", count):gsub(" 1$", " .")
	if label == "\n\n        ." then label = "" end
	return string.format("item_image_button[%u,%u;%u,%u;%s;%s;%s]",
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
	get_formspec = function(player)
		local player_name = player:get_player_name()
		local player_privs = minetest.get_player_privs(player_name)
		local formspec = ""
		formspec = formspec.."background[0,4.5;8,4;ui_main_inventory.png]"
		formspec = formspec.."label[0,0;" .. S("Crafting Guide") .. "]"
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

		formspec = formspec.."background[0,1;8,3;ui_craftguide_form.png]"
		formspec = formspec.."textarea[0.3,0.6;10,1;;"..minetest.formspec_escape(role_text[dir]..": "..item_name)..";]"
		formspec = formspec..stack_image_button(0, 1, 1.1, 1.1, "item_button_" .. rdir .. "_", ItemStack(item_name))

		if not craft then
			formspec = formspec.."label[6,3.35;"..minetest.formspec_escape(no_recipe_text[dir]).."]"
			local no_pos = dir == "recipe" and 4 or 6
			local item_pos = dir == "recipe" and 6 or 4
			formspec = formspec.."image["..no_pos..",1;1.1,1.1;ui_no.png]"
			formspec = formspec..stack_image_button(item_pos, 1, 1.1, 1.1, "item_button_"..other_dir[dir].."_", ItemStack(item_name))
			if player_privs.give == true then
				formspec = formspec.."label[0,3.10;" .. S("Give me:") .. "]"
						.."button[0,  3.70;0.6,0.5;craftguide_giveme_1;1]"
						.."button[0.6,3.70;0.7,0.5;craftguide_giveme_10;10]"
						.."button[1.3,3.70;0.8,0.5;craftguide_giveme_99;99]"
			end
			return {formspec = formspec}
		end

		local craft_type = unified_inventory.registered_craft_types[craft.type] or
				unified_inventory.craft_type_defaults(craft.type, {})
		formspec = formspec.."label[6,3.35;" .. S("Method:") .. "]"
		formspec = formspec.."label[6,3.75;"
				..minetest.formspec_escape(craft_type.description).."]"
		formspec = formspec..stack_image_button(6, 1, 1.1, 1.1, "item_button_usage_", ItemStack(craft.output))
		local display_size = craft_type.dynamic_display_size and craft_type.dynamic_display_size(craft) or { width = craft_type.width, height = craft_type.height }
		local craft_width = craft_type.get_shaped_craft_width and craft_type.get_shaped_craft_width(craft) or display_size.width

		-- This keeps recipes aligned to the right,
		-- so that they're close to the arrow.
		local xoffset = 1 + (3 - display_size.width)
		for y = 1, display_size.height do
		for x = 1, display_size.width do
			local item
			if craft and x <= craft_width then
				item = craft.items[(y-1) * craft_width + x]
			end
			if item then
				formspec = formspec..stack_image_button(
						xoffset + x, y, 1.1, 1.1,
						"item_button_recipe_",
						ItemStack(item))
			else
				-- Fake buttons just to make grid
				formspec = formspec.."image_button["
					..tostring(xoffset + x)..","..tostring(y)
					..";1,1;ui_blank_image.png;;]"
			end
		end
		end

		if craft_type.uses_crafting_grid then
			formspec = formspec.."label[0,1.90;" .. S("To craft grid:") .. "]"
					.."button[0,  2.5;0.6,0.5;craftguide_craft_1;1]"
					.."button[0.6,2.5;0.7,0.5;craftguide_craft_10;10]"
					.."button[1.3,2.5;0.8,0.5;craftguide_craft_max;" .. S("All") .. "]"
		end
		if player_privs.give then
			formspec = formspec.."label[0,3.10;" .. S("Give me:") .. "]"
					.."button[0,  3.70;0.6,0.5;craftguide_giveme_1;1]"
					.."button[0.6,3.70;0.7,0.5;craftguide_giveme_10;10]"
					.."button[1.3,3.70;0.8,0.5;craftguide_giveme_99;99]"
		end

		if alternates and alternates > 1 then
			formspec = formspec.."label[6,1.95;"..recipe_text[dir].." "
					..tostring(alternate).." of "
					..tostring(alternates).."]"
					.."button[6,2.3;2,1;alternate;" .. S("Alternate") .. "]"
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

	if amount == "max" then
		amount = 99 -- Arbitrary; need better way to do this.
	else
		amount = tonumber(amount)
	end

	for iter = 1, amount do
		local index = 1
		for y = 1, 3 do
			for x = 1, width do
				local needed_item = needed[index]
				if needed_item then
					local craft_index = ((y - 1) * 3) + x
					local craft_item = craft_list[craft_index]
					if (not craft_item) or (craft_item:is_empty()) or (craft_item:get_name() == needed_item) then
						itemname = craft_item and craft_item:get_name() or needed_item
						local needed_stack = ItemStack(needed_item)
						if player_inv:contains_item("main", needed_stack) then
							local count = (craft_item and craft_item:get_count() or 0) + 1
							if count <= needed_stack:get_definition().stack_max then
								local stack = ItemStack({name=needed_item, count=count})
								craft_list[craft_index] = stack
								player_inv:remove_item("main", needed_stack)
							end
						end
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
			break
		elseif k:match("craftguide_giveme_") then
			craftguide_giveme(player, formname, fields)
			break
		end
	end
end)
