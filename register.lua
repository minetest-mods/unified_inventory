local S = minetest.get_translator("unified_inventory")
local NS = function(s) return s end
local F = minetest.formspec_escape
local ui = unified_inventory

minetest.register_privilege("creative", {
	description = S("Can use the creative inventory"),
	give_to_singleplayer = false,
})

minetest.register_privilege("ui_full", {
	description = S("Forces Unified Inventory to be displayed in Full mode if Lite mode is configured globally"),
	give_to_singleplayer = false,
})

local trash = minetest.create_detached_inventory("trash", {
	--allow_put = function(inv, listname, index, stack, player)
	--	if ui.is_creative(player:get_player_name()) then
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

ui.register_button("craft", {
	type = "image",
	image = "ui_craft_icon.png",
	tooltip = S("Crafting Grid")
})

ui.register_button("craftguide", {
	type = "image",
	image = "ui_craftguide_icon.png",
	tooltip = S("Crafting Guide")
})

ui.register_button("home_gui_set", {
	type = "image",
	image = "ui_sethome_icon.png",
	tooltip = S("Set home position"),
	hide_lite=true,
	action = function(player)
		local player_name = player:get_player_name()
		if minetest.check_player_privs(player_name, {home=true}) then
			ui.set_home(player, player:get_pos())
			local home = ui.home_pos[player_name]
			if home ~= nil then
				minetest.sound_play("dingdong",
						{to_player=player_name, gain = 1.0})
				minetest.chat_send_player(player_name,
					S("Home position set to: @1", minetest.pos_to_string(home)))
			end
		else
			minetest.chat_send_player(player_name,
				S("You don't have the \"home\" privilege!"))
			ui.set_inventory_formspec(player, ui.current_page[player_name])
		end
	end,
	condition = function(player)
		return minetest.check_player_privs(player:get_player_name(), {home=true})
	end,
})

ui.register_button("home_gui_go", {
	type = "image",
	image = "ui_gohome_icon.png",
	tooltip = S("Go home"),
	hide_lite=true,
	action = function(player)
		local player_name = player:get_player_name()
		if minetest.check_player_privs(player_name, {home=true}) then
			if ui.go_home(player) then
				minetest.sound_play("teleport", {to_player = player_name})
			end
		else
			minetest.chat_send_player(player_name,
				S("You don't have the \"home\" privilege!"))
			ui.set_inventory_formspec(player, ui.current_page[player_name])
		end
	end,
	condition = function(player)
		return minetest.check_player_privs(player:get_player_name(), {home=true})
	end,
})

ui.register_button("misc_set_day", {
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
			ui.set_inventory_formspec(player, ui.current_page[player_name])
		end
	end,
	condition = function(player)
		return minetest.check_player_privs(player:get_player_name(), {settime=true})
	end,
})

ui.register_button("misc_set_night", {
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
			ui.set_inventory_formspec(player, ui.current_page[player_name])
		end
	end,
	condition = function(player)
		return minetest.check_player_privs(player:get_player_name(), {settime=true})
	end,
})

ui.register_button("clear_inv", {
	type = "image",
	image = "ui_trash_icon.png",
	tooltip = S("Clear inventory"),
	action = function(player)
		local player_name = player:get_player_name()
		if not ui.is_creative(player_name) then
			minetest.chat_send_player(player_name,
					S("This button has been disabled outside"
					.." of creative mode to prevent"
					.." accidental inventory trashing."
					.."\nUse the trash slot instead."))
			ui.set_inventory_formspec(player, ui.current_page[player_name])
			return
		end
		player:get_inventory():set_list("main", {})
		minetest.chat_send_player(player_name, S('Inventory cleared!'))
		minetest.sound_play("trash_all",
				{to_player=player_name, gain = 1.0})
	end,
	condition = function(player)
		return ui.is_creative(player:get_player_name())
	end,
})

ui.register_page("craft", {
	get_formspec = function(player, perplayer_formspec)

		local formheaderx = perplayer_formspec.form_header_x
		local formheadery = perplayer_formspec.form_header_y
		local craftx = perplayer_formspec.craft_x
		local crafty = perplayer_formspec.craft_y

		local player_name = player:get_player_name()
		local formspec = {
			perplayer_formspec.standard_inv_bg,
			perplayer_formspec.craft_grid,
			"label["..formheaderx..","..formheadery..";" ..F(S("Crafting")).."]",
			"listcolors[#00000000;#00000000]",
			"listring[current_name;craft]",
			"listring[current_player;main]"
		}
		local n=#formspec+1

		if ui.trash_enabled or ui.is_creative(player_name) or minetest.get_player_privs(player_name).give then
			formspec[n] = string.format("label[%f,%f;%s]", craftx + 6.35, crafty + 2.3, F(S("Trash:")))
			formspec[n+1] = ui.make_trash_slot(craftx + 6.25, crafty + 2.5)
			n=n + 2
		end

		if ui.is_creative(player_name) then
			formspec[n] = ui.single_slot(craftx - 2.5, crafty + 2.5)
			formspec[n+1] = string.format("label[%f,%f;%s]", craftx - 2.4, crafty + 2.3, F(S("Refill:")))
			formspec[n+2] = string.format("list[detached:%srefill;main;%f,%f;1,1;]",
				F(player_name), craftx - 2.5 + ui.list_img_offset, crafty + 2.5 + ui.list_img_offset)
		end
		return {formspec=table.concat(formspec)}
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
	local description = item:get_meta():get_string("description")
	local show_is_group = false
	local displayitem = item:to_string()
	local selectitem = name
	if name:sub(1, 6) == "group:" then
		local group_name = name:sub(7)
		local group_item = ui.get_group_item(group_name)
		show_is_group = not group_item.sole
		displayitem = group_item.item or "unknown"
		selectitem = group_item.sole and displayitem or name
	end
	local label = show_is_group and "G" or ""
	-- Unique id to prevent tooltip being overridden
	local id = string.format("%i%i_", x*10, y*10)
	local buttonname = F(id..buttonname_prefix..ui.mangle_for_formspec(selectitem))
	local button = string.format("item_image_button[%f,%f;%f,%f;%s;%s;%s]",
			x, y, w, h,
			F(displayitem), buttonname, label)
	if show_is_group then
		local groupstring, andcount = ui.extract_groupnames(name)
		local grouptip
		if andcount == 1 then
			grouptip = S("Any item belonging to the @1 group", groupstring)
		elseif andcount > 1 then
			grouptip = S("Any item belonging to the groups @1", groupstring)
		end
		grouptip = F(grouptip)
		if andcount >= 1 then
			button = button  .. string.format("tooltip[%s;%s]", buttonname, grouptip)
		end
	elseif description ~= "" then
		button = button  .. string.format("tooltip[%s;%s]", buttonname, F(description))
	end
	return button
end

-- The recipe text contains parameters, hence they can yet not be translated.
-- Instead, use a dummy translation call so that it can be picked up by the
-- static parsing of the translation string update script
local recipe_text = {
	recipe = NS("Recipe @1 of @2"),
	usage = NS("Usage @1 of @2"),
}
local no_recipe_text = {
	recipe = S("No recipes"),
	usage = S("No usages"),
}
local role_text = {
	recipe = S("Result"),
	usage = S("Ingredient"),
}
local next_alt_text = {
	recipe = S("Show next recipe"),
	usage = S("Show next usage"),
}
local prev_alt_text = {
	recipe = S("Show previous recipe"),
	usage = S("Show previous usage"),
}
local other_dir = {
	recipe = "usage",
	usage = "recipe",
}

ui.register_page("craftguide", {
	get_formspec = function(player, perplayer_formspec)

		local craftguidex =       perplayer_formspec.craft_guide_x
		local craftguidey =       perplayer_formspec.craft_guide_y
		local craftguidearrowx =  perplayer_formspec.craft_guide_arrow_x
		local craftguideresultx = perplayer_formspec.craft_guide_result_x
		local formheaderx =       perplayer_formspec.form_header_x
		local formheadery =       perplayer_formspec.form_header_y
		local give_x =            perplayer_formspec.give_btn_x

		local player_name = player:get_player_name()
		local player_privs = minetest.get_player_privs(player_name)

		local formspec = {
			perplayer_formspec.standard_inv_bg,
			"label["..formheaderx..","..formheadery..";" .. F(S("Crafting Guide")) .. "]",
			"listcolors[#00000000;#00000000]"
		}

		local item_name = ui.current_item[player_name]
		if not item_name then
			return { formspec = table.concat(formspec) }
		end

		local n = 4

		local item_name_shown
		if minetest.registered_items[item_name]
				and minetest.registered_items[item_name].description then
			item_name_shown = S("@1 (@2)",
				minetest.registered_items[item_name].description, item_name)
		else
			item_name_shown = item_name
		end

		local dir = ui.current_craft_direction[player_name]
		local rdir = dir == "recipe" and "usage" or "recipe"

		local crafts = ui.crafts_for[dir][item_name]
		local alternate = ui.alternate[player_name]
		local alternates, craft
		if crafts and #crafts > 0 then
			alternates = #crafts
			craft = crafts[alternate]
		end
		local has_give = player_privs.give or ui.is_creative(player_name)

		formspec[n] = string.format("image[%f,%f;%f,%f;ui_crafting_arrow.png]",
	                            craftguidearrowx, craftguidey, ui.imgscale, ui.imgscale)

		formspec[n+1] = string.format("textarea[%f,%f;10,1;;%s: %s;]",
				perplayer_formspec.craft_guide_resultstr_x, perplayer_formspec.craft_guide_resultstr_y,
				F(role_text[dir]), item_name_shown)
		n = n + 2

		local giveme_form = table.concat({
			"label[".. (give_x+0.1)..",".. (craftguidey + 2.7) .. ";" .. F(S("Give me:")) .. "]",
			"button["..(give_x)..","..     (craftguidey + 2.9) .. ";0.75,0.5;craftguide_giveme_1;1]",
			"button["..(give_x+0.8)..",".. (craftguidey + 2.9) .. ";0.75,0.5;craftguide_giveme_10;10]",
			"button["..(give_x+1.6)..",".. (craftguidey + 2.9) .. ";0.75,0.5;craftguide_giveme_99;99]"
		})

		if not craft then
			-- No craft recipes available for this item.
			formspec[n] = string.format("label[%f,%f;%s]", craftguidex+2.5, craftguidey+1.5, F(no_recipe_text[dir]))
			local no_pos = dir == "recipe" and (craftguidex+2.5) or craftguideresultx
			local item_pos = dir == "recipe" and craftguideresultx or (craftguidex+2.5)
			formspec[n+1] = "image["..no_pos..","..craftguidey..";1.2,1.2;ui_no.png]"
			formspec[n+2] = stack_image_button(item_pos, craftguidey, 1.2, 1.2,
				"item_button_" .. other_dir[dir] .. "_", ItemStack(item_name))
			if has_give then
				formspec[n+3] = giveme_form
			end
			return { formspec = table.concat(formspec) }
		else
			formspec[n] = stack_image_button(craftguideresultx, craftguidey, 1.2, 1.2,
					"item_button_" .. rdir .. "_", ItemStack(craft.output))
			n = n + 1
		end

		local craft_type = ui.registered_craft_types[craft.type] or
				ui.craft_type_defaults(craft.type, {})
		if craft_type.icon then
			formspec[n] = string.format("image[%f,%f;%f,%f;%s]",
					craftguidearrowx+0.35, craftguidey, 0.5, 0.5, craft_type.icon)
			n = n + 1
		end
		formspec[n] = string.format("label[%f,%f;%s]", craftguidearrowx + 0.15, craftguidey + 1.4, F(craft_type.description))
		n = n + 1

		local display_size = craft_type.dynamic_display_size
				and craft_type.dynamic_display_size(craft)
				or { width = craft_type.width, height = craft_type.height }
		local craft_width = craft_type.get_shaped_craft_width
				and craft_type.get_shaped_craft_width(craft)
				or display_size.width

		-- This keeps recipes aligned to the right,
		-- so that they're close to the arrow.
		local xoffset = craftguidex+3.75
		local bspc = 1.25
		-- Offset factor for crafting grids with side length > 4
		local of = (3/math.max(3, math.max(display_size.width, display_size.height)))
		local od = 0
		-- Minimum grid size at which size optimization measures kick in
		local mini_craft_size = 6
		if display_size.width >= mini_craft_size then
			od = math.max(1, display_size.width - 2)
			xoffset = xoffset - 0.1
		end
		-- Size modifier factor
		local sf = math.min(1, of * (1.05 + 0.05*od))
		-- Button size
		local bsize = 1.2 * sf

		if display_size.width >= mini_craft_size then  -- it's not a normal 3x3 grid
			bsize = 0.8 * sf
		end
		if (bsize > 0.35 and display_size.width) then
		for y = 1, display_size.height do
		for x = 1, display_size.width do
			local item
			if craft and x <= craft_width then
				item = craft.items[(y-1) * craft_width + x]
			end
			-- Flipped x, used to build formspec buttons from right to left
			local fx = display_size.width - (x-1)
			-- x offset, y offset
			local xof = ((fx-1) * of + of) * bspc
			local yof = ((y-1) * of + 1) * bspc
			if item then
				formspec[n] = stack_image_button(
						xoffset - xof, craftguidey - 1.25 + yof, bsize, bsize,
						"item_button_recipe_",
						ItemStack(item))
			else
				-- Fake buttons just to make grid
				formspec[n] = string.format("image_button[%f,%f;%f,%f;ui_blank_image.png;;]",
						xoffset - xof, craftguidey - 1.25 + yof, bsize, bsize)
			end
			n = n + 1
		end
		end
		else
			-- Error
			formspec[n] = string.format("label[2,%f;%s]",
				craftguidey, F(S("This recipe is too@nlarge to be displayed.")))
			n = n + 1
		end

		if craft_type.uses_crafting_grid and display_size.width <= 3 then
			formspec[n]   = "label["..(give_x+0.1)..","..    (craftguidey + 1.7) .. ";" .. F(S("To craft grid:")) .. "]"
			formspec[n+1] = "button["..  (give_x)..","..     (craftguidey + 1.9) .. ";0.75,0.5;craftguide_craft_1;1]"
			formspec[n+2] = "button["..  (give_x+0.8)..",".. (craftguidey + 1.9) .. ";0.75,0.5;craftguide_craft_10;10]"
			formspec[n+3] = "button["..  (give_x+1.6)..",".. (craftguidey + 1.9) .. ";0.75,0.5;craftguide_craft_max;" .. F(S("All")) .. "]"
			n = n + 4
		end

		if has_give then
			formspec[n] = giveme_form
			n = n + 1
		end

		if alternates and alternates > 1 then
			formspec[n] = string.format("label[%f,%f;%s]",
						craftguidex+4, craftguidey + 2.3, F(S(recipe_text[dir], alternate, alternates)))
			formspec[n+1] = string.format("image_button[%f,%f;1.1,1.1;ui_left_icon.png;alternate_prev;]",
						craftguidearrowx+0.2, craftguidey + 2.6)
			formspec[n+2] = string.format("image_button[%f,%f;1.1,1.1;ui_right_icon.png;alternate;]",
						craftguidearrowx+1.35, craftguidey + 2.6)
			formspec[n+3] = "tooltip[alternate_prev;" .. F(prev_alt_text[dir]) .. "]"
			formspec[n+4] = "tooltip[alternate;" .. F(next_alt_text[dir]) .. "]"
		end

		return { formspec = table.concat(formspec) }
	end,
})

local function craftguide_giveme(player, formname, fields)
	local player_name = player:get_player_name()
	local player_privs = minetest.get_player_privs(player_name)
	if not player_privs.give and
			not ui.is_creative(player_name) then
		minetest.log("action", "[unified_inventory] Denied give action to player " ..
			player_name)
		return
	end

	local amount
	for k, v in pairs(fields) do
		amount = k:match("craftguide_giveme_(.*)")
		if amount then break end
	end

	amount = tonumber(amount) or 0
	if amount == 0 then return end

	local output = ui.current_item[player_name]
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

	amount = tonumber(amount) or -1 -- fallback for "all"
	if amount == 0 or amount < -1 or amount > 99 then return end

	local player_name = player:get_player_name()

	local output = ui.current_item[player_name] or ""
	if output == "" then return end

	local crafts = ui.crafts_for[
		ui.current_craft_direction[player_name]][output] or {}
	if #crafts == 0 then return end

	local alternate = ui.alternate[player_name]

	local craft = crafts[alternate]
	if not craft.width then
		if not craft.output then
			minetest.log("warning", "[unified_inventory] Craft has no output.")
		else
			minetest.log("warning", ("[unified_inventory] Craft for '%s' has no width."):format(craft.output))
		end
		return
	end
	if craft.width > 3 then return end

	ui.craftguide_match_craft(player, "main", "craft", craft, amount)

	ui.set_inventory_formspec(player, "craft")
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "" then
		return
	end

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
