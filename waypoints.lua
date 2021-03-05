local S = minetest.get_translator("unified_inventory")
local F = minetest.formspec_escape

local hud_colors = {
	{"#FFFFFF", 0xFFFFFF, S("White")},
	{"#DBBB00", 0xf1d32c, S("Yellow")},
	{"#DD0000", 0xDD0000, S("Red")},
	{"#2cf136", 0x2cf136, S("Green")},
	{"#2c4df1", 0x2c4df1, S("Blue")},
}

local hud_colors_max = #hud_colors

-- Stores temporary player data (persists until player leaves)
local waypoints_temp = {}

unified_inventory.register_page("waypoints", {
	get_formspec = function(player)
		local player_name = player:get_player_name()
		local wp_info_x = unified_inventory.form_header_x + 1.25
		local wp_info_y = unified_inventory.form_header_y + 0.5
		local wp_bottom_row = unified_inventory.std_inv_y - 1
		local wp_buttons_rj = unified_inventory.std_inv_x + 10.1 - unified_inventory.btn_spc
		local wp_edit_w = unified_inventory.btn_spc * 4 - 0.1

		-- build a "fake" temp entry if the server took too long
		-- during sign-on and returned an empty entry
		if not waypoints_temp[player_name] then waypoints_temp[player_name] = {hud = 1} end

		local waypoints = datastorage.get(player_name, "waypoints")
		local formspec = unified_inventory.standard_inv_bg..
			"label["..unified_inventory.form_header_x..","..unified_inventory.form_header_y..";" .. F(S("Waypoints")) .. "]"..
			"image["..wp_info_x..","..wp_info_y..";1,1;ui_waypoints_icon.png]"

		-- Tabs buttons:
		for i = 1, 5 do
			formspec = formspec ..
				"image_button["..unified_inventory.main_button_x..","..
				(wp_bottom_row - (5-i) * unified_inventory.btn_spc)..";"..
				unified_inventory.btn_size..","..unified_inventory.btn_size..";" ..
				(i == waypoints.selected and "ui_blue_icon_background.png^" or "") ..
				"ui_" .. i .. "_icon.png;" ..
				"select_waypoint" .. i .. ";]" ..
				"tooltip[select_waypoint" .. i .. ";"
					.. S("Select Waypoint #@1", i).."]"
		end

		local i = waypoints.selected or 1
		local waypoint = waypoints[i] or {}
		local temp = waypoints_temp[player_name][i] or {}
		local default_name = S("Waypoint @1", i)

		-- Main buttons:
		-- note:  the @1's in the set, arrow, and pencil tooltips are dummies.
		local btnlist = {
			{ "ui_waypoint_set_icon.png", "set_waypoint", "Set waypoint to current location@1" },
			{ waypoint.active and "ui_on_icon.png" or "ui_off_icon.png", "toggle_waypoint", "Make waypoint @1", waypoint.active and "invisible" or "visible" },
			{ waypoint.display_pos and "ui_green_icon_background.png" or "ui_red_icon_background.png", "toggle_display_pos", "@1 display of waypoint coordinates", waypoint.display_pos and "Disable" or "Enable" },
			{ "ui_circular_arrows_icon.png", "toggle_color", "Change color of waypoint display@1" },
			{ "ui_pencil_icon.png", "rename_waypoint", "Edit waypoint name@1" }
		}

		local x = 4
		for _, b in pairs(btnlist) do
			formspec = formspec ..
				"image_button["..(wp_buttons_rj - unified_inventory.btn_spc * x)..","..
				wp_bottom_row..";"..
				unified_inventory.btn_size..","..unified_inventory.btn_size..";"..
				b[1]..";"..
				b[2]..i..";]"..
				"tooltip["..b[2]..i..";"..F(S(b[3], b[4] or "")).."]"
			x = x - 1
		end

		-- Waypoint's info:
		formspec = formspec.."label["..wp_info_x..","..(wp_info_y+1.1)..";"
		if waypoint.active then
			formspec = formspec ..F(S("Waypoint active")).."]"
		else
			formspec = formspec ..F(S("Waypoint inactive")).."]"
		end

		if temp.edit then
			formspec = formspec ..
				"field["..(wp_buttons_rj - wp_edit_w - 0.1)..","..(wp_bottom_row - unified_inventory.btn_spc)..";"..
				wp_edit_w..","..unified_inventory.btn_size..";rename_box" .. i .. ";;"..
				(waypoint.name or default_name).."]" ..
				"image_button["..wp_buttons_rj..","..(wp_bottom_row - unified_inventory.btn_spc)..";"..
				unified_inventory.btn_size..","..unified_inventory.btn_size..";"..
				"ui_ok_icon.png;"..
				"confirm_rename"..i.. ";]"..
				"tooltip[confirm_rename" .. i .. ";"
					.. F(S("Finish editing")).."]"
		end

		formspec = formspec .. "label["..wp_info_x..","..(wp_info_y+1.6)..";"..F(S("World position"))..": " ..
			minetest.pos_to_string(waypoint.world_pos or vector.new()) .. "]" ..
			"label["..wp_info_x..","..(wp_info_y+2.10)..";"..F(S("Name"))..": ".. (waypoint.name or default_name) .. "]" ..
			"label["..wp_info_x..","..(wp_info_y+2.60)..";"..F(S("HUD text color"))..": " ..
			hud_colors[waypoint.color or 1][3] .. "]"

		return {formspec=formspec}
	end,
})

unified_inventory.register_button("waypoints", {
	type = "image",
	image = "ui_waypoints_icon.png",
	tooltip = S("Waypoints"),
	hide_lite=true
})

local function update_hud(player, waypoints, temp, i)
	local waypoint = waypoints[i]
	if not waypoint then return end
	temp[i] = temp[i] or {}
	temp = temp[i]
	local pos = waypoint.world_pos or vector.new()
	local name
	if waypoint.display_pos then
		name = minetest.pos_to_string(pos)
		if waypoint.name then
			name = name..", "..waypoint.name
		end
	else
		name = waypoint.name or "Waypoint "..i
	end
	if temp.hud then
		player:hud_remove(temp.hud)
	end
	if waypoint.active then
		temp.hud = player:hud_add({
			hud_elem_type = "waypoint",
			number = hud_colors[waypoint.color or 1][2] ,
			name = name,
			text = "m",
			world_pos = pos
		})
	else
		temp.hud = nil
	end
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "" then return end

	local player_name = player:get_player_name()
	local update_formspec = false
	local need_update_hud = false
	local hit = false

	local waypoints = datastorage.get(player_name, "waypoints")
	local temp = waypoints_temp[player_name]
	for i = 1, 5, 1 do
		if fields["select_waypoint"..i] then
			hit = true
			waypoints.selected = i
			update_formspec = true
		end

		if fields["toggle_waypoint"..i] then
			hit = true
			waypoints[i] = waypoints[i] or {}
			waypoints[i].active = not (waypoints[i].active)
			need_update_hud = true
			update_formspec = true
		end

		if fields["set_waypoint"..i] then
			hit = true
			local pos = player:get_pos()
			pos.x = math.floor(pos.x)
			pos.y = math.floor(pos.y)
			pos.z = math.floor(pos.z)
			waypoints[i] = waypoints[i] or {}
			waypoints[i].world_pos = pos
			need_update_hud = true
			update_formspec = true
		end

		if fields["rename_waypoint"..i] then
			hit = true
			temp[i] = temp[i] or {}
			temp[i].edit = true
			update_formspec = true
		end

		if fields["toggle_display_pos"..i] then
			hit = true
			waypoints[i] = waypoints[i] or {}
			waypoints[i].display_pos = not waypoints[i].display_pos
			need_update_hud = true
			update_formspec = true
		end

		if fields["toggle_color"..i] then
			hit = true
			waypoints[i] = waypoints[i] or {}
			local color = waypoints[i].color or 1
			color = color + 1
			if color > hud_colors_max then
				color = 1
			end
			waypoints[i].color = color
			need_update_hud = true
			update_formspec = true
		end

		if fields["confirm_rename"..i] then
			hit = true
			waypoints[i] = waypoints[i] or {}
			temp[i].edit = false
			waypoints[i].name = fields["rename_box"..i]
			need_update_hud = true
			update_formspec = true
		end
		if need_update_hud then
			update_hud(player, waypoints, temp, i)
		end
		if update_formspec then
			unified_inventory.set_inventory_formspec(player, "waypoints")
		end
		if hit then return end
	end
end)


minetest.register_on_joinplayer(function(player)
	local player_name = player:get_player_name()
	local waypoints = datastorage.get(player_name, "waypoints")
	local temp = {}
	waypoints_temp[player_name] = temp
	for i = 1, 5 do
		update_hud(player, waypoints, temp, i)
	end
end)

minetest.register_on_leaveplayer(function(player)
	waypoints_temp[player:get_player_name()] = nil
end)

