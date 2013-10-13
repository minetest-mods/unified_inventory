
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
})

unified_inventory.register_button("craftguide", {
	type = "image",
	image = "ui_craftguide_icon.png",
})

unified_inventory.register_button("home_gui_set", {
	type = "image",
	image = "ui_sethome_icon.png",
	action = function(player)
		local player_name = player:get_player_name()
		unified_inventory.set_home(player, player:getpos())
		local home = unified_inventory.home_pos[player_name]
		if home ~= nil then
			minetest.sound_play("dingdong",
					{to_player=player_name, gain = 1.0})
			minetest.chat_send_player(player_name,
					"Home position set to: "
					..minetest.pos_to_string(home))
		end
	end,
})

unified_inventory.register_button("home_gui_go", {
	type = "image",
	image = "ui_gohome_icon.png",
	action = function(player)
		minetest.sound_play("teleport",
				{to_player=player:get_player_name(), gain = 1.0})
		unified_inventory.go_home(player)
	end,
})
	
unified_inventory.register_button("mine_gui_set", {
	type = "image",
	image = "ui_setmine.png",
	action = function(player)
		local player_name = player:get_player_name()
		unified_inventory.set_mine(player, player:getpos())
		local mine = unified_inventory.minepos[player_name]
		if mine ~= nil then
			minetest.sound_play("dingdong",
					{to_player=player_name, gain = 1.0})
			minetest.chat_send_player(player_name,
					"Mine position set to: "
					..minetest.pos_to_string(mine))
		end
	end,
})

unified_inventory.register_button("mine_gui_go", {
	type = "image",
	image = "ui_gomine.png",
	action = function(player)
		minetest.sound_play("teleport",
				{to_player=player:get_player_name(), gain = 1.0})
		unified_inventory.go_mine(player)
	end,
})

unified_inventory.register_button("misc_set_day", {
	type = "image",
	image = "ui_sun_icon.png",
	action = function(player)
		local player_name = player:get_player_name()
		if minetest.check_player_privs(player_name, {settime=true}) then 
			minetest.sound_play("birds",
					{to_player=player_name, gain = 1.0})
			minetest.set_timeofday((6000 % 24000) / 24000)
			minetest.chat_send_player(player_name,
					"Time of day set to 6am")
		else
			minetest.chat_send_player(player_name,
					"You don't have the"
					.." settime priviledge!")
		end
	end,
})

unified_inventory.register_button("misc_set_night", {
	type = "image",
	image = "ui_moon_icon.png",
	action = function(player)
		local player_name = player:get_player_name()
		if minetest.check_player_privs(player_name, {settime=true}) then
			minetest.sound_play("owl",
					{to_player=player_name, gain = 1.0})
			minetest.set_timeofday((21000 % 24000) / 24000)
			minetest.chat_send_player(player_name,
					"Time of day set to 9pm")
		else
			minetest.chat_send_player(player_name,
					"You don't have the"
					.." settime priviledge!")	
		end
	end,
})

unified_inventory.register_button("clear_inv", {
	type = "image",
	image = "ui_trash_icon.png",
	action = function(player)
		local player_name = player:get_player_name()
		if not unified_inventory.is_creative(player_name) then
			minetest.chat_send_player(player_name,
					"This button has been disabled outside"
					.." of creative mode to prevent"
					.." accidental inventory trashing."
					.." Use the trash slot instead.")
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
		formspec = formspec.."list[current_player;craftpreview;6,1;1,1;]"
		formspec = formspec.."list[current_player;craft;2,1;3,3;]"
		formspec = formspec.."label[7,2.5;Trash:]"
		formspec = formspec.."list[detached:trash;main;7,3;1,1;]"
		if unified_inventory.is_creative(player_name) then
			formspec = formspec.."label[0,2.5;Refill:]"
			formspec = formspec.."list[detached:"..player_name.."refill;main;0,3;1,1;]"
		end
		return {formspec=formspec}
	end,
})

unified_inventory.register_page("craftguide", {
	get_formspec = function(player)
		local player_name = player:get_player_name()
		local formspec = "background[0,1;8,3;ui_craftguide_form.png]"
		formspec = formspec.."background[0,4.5;8,4;ui_main_inventory.png]"
		formspec = formspec.."label[0,0;Crafting Guide]"
		formspec = formspec.."list[detached:"..player_name.."craftrecipe;output;6,1;1,1;]"
		formspec = formspec.."label[6,2.6;Method:]"
		local item_name = unified_inventory.current_item[player_name]
		local craft = nil
		if item_name then
			formspec = formspec.."textarea[0.3,0.6;10,1;;Result: "..item_name..";]"
			local alternates = 0
			local alternate = unified_inventory.alternate[player_name]
			local crafts = unified_inventory.crafts_table[item_name]
			if crafts ~= nil and #crafts > 0 then
				alternates = #crafts
				craft = crafts[alternate]
				local method = craft.type
				if craft.type == "normal" then
					method = "crafting"
				elseif craft.type == "shapeless" then
					method = "shapeless crafting"
				elseif craft.type == "alloy" then
					method = "alloy cooking"
				end
				formspec = formspec.."label[6,3;"..method.."]"
			end
			if alternates > 1 then
				formspec = formspec.."label[0,2.6;Recipe "
						..tostring(alternate).." of "
						..tostring(alternates).."]"
				formspec = formspec.."button[0,3.15;2,1;alternate;Alternate]"
			end
		end

		local craftinv = minetest.get_inventory({
			type = "detached",
			name = player_name.."craftrecipe"
		})

		-- fake buttons just to make 3x3 grid
		for y = 1, 3 do
		for x = 1, 3 do
			formspec = formspec.."image_button["
				..(1.0 + x)..","..(0.0 + y)..";1.1,1.1;ui_blank_image.png;;]"
		end
		end

		if not craft then
			craftinv:set_stack("output", 1, nil)
			return {formspec=formspec}
		end

		craftinv:set_stack("output", 1, craft.output)

		local width = craft.width
		if width == 0 then
			-- Shapeless recipe
			width = 3
		end

		local i = 1
		for y = 1, 3 do
		for x = 1, width do
			local item = craft.items[i]
			if item then
				if string.sub(item, 1, 6) == "group:" then
					local group = string.sub(item, 7)
					formspec = formspec.."image_button["
						..(1.0 + x)..","..(0.0 + y)..";1.1,1.1;"
						.."ui_group.png;;"
						..minetest.formspec_escape(group).."]"
				else
					formspec = formspec.."item_image_button["
						..(1.0 + x)..","..(0.0 + y)..";1.1,1.1;"
						..minetest.formspec_escape(item)..";"
						.."item_button_"
						..minetest.formspec_escape(item)..";]"
				end
			end
			i = i + 1
		end
		end
		return {formspec=formspec}
	end,
})

