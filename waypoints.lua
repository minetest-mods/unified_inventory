local S = minetest.get_translator("unified_inventory")
local F = minetest.formspec_escape
local ui = unified_inventory
local COUNT = 5

local hud_colors = {
	{"#FFFFFF", 0xFFFFFF, S("White")},
	{"#DBBB00", 0xf1d32c, S("Yellow")},
	{"#DD0000", 0xDD0000, S("Red")},
	{"#2cf136", 0x2cf136, S("Green")},
	{"#2c4df1", 0x2c4df1, S("Blue")},
}

-- Storage compatibility code

--[[
Stores temporary player data (persists until player leaves)
	[player_name] = {
		[<waypoint index>] = {
			edit = <edit current waypoint?>,
			hud = <hud ID>,
		},
		[<waypoint index>] = { ... },
		...
	}
]]
local waypoints_temp = {}

--[[
Datastorage format (per-player):
	{
		selected = <waypoint index>,
		[<waypoint index>] = {
			name = <name or nil>
			world_pos = <coordinates vector>,
			color = <"hud_colors" index>,
			active = <hud show waypoint?>,
			display_pos = <hud display coorinates?>,
		},
		[<waypoint index>] = { ... },
		...
	}
Player metadata format:
	{
		selected = <selected number>,
		-- Cannot mix integer/string keys in JSON
		data = {
			[<waypoint index>] = { same as above },
			...
		}
	}
]]

local function set_waypoint_data(player, waypoints)
	local meta = player:get_meta()
	if not next(waypoints.data or {}) then
		-- Empty data. Do not save anything, or delete
		meta:set_string("ui_waypoints", "")
	else
		meta:set_string("ui_waypoints", minetest.write_json(waypoints))
	end
end

local function migrate_datastorage(player, waypoints)
	-- Copy values from old table
	local new_data = {
		selected = waypoints.selected,
		data = {}
	}
	for i = 1, COUNT do
		new_data.data[i] = waypoints[i]
	end

	set_waypoint_data(player, new_data)

	-- Delete values, but keep one entry so that it's saved by datastorage
	for k, _ in pairs(waypoints) do
		waypoints[k] = nil
	end
	waypoints[1] = 1
end

local have_datastorage = minetest.get_modpath("datastorage") ~= nil
local function get_waypoint_data(player)
	local player_name = player:get_player_name()

	-- Migration step
	if have_datastorage then
		local waypoints = datastorage.get(player_name, "waypoints")
		if waypoints.selected then
			migrate_datastorage(player, waypoints)
			minetest.log("action", "[unified_inventory] " ..
				"Migrated waypoints of player: " .. player_name)
		end
	end

	-- Get directly from metadata
	local waypoints = player:get_meta():get("ui_waypoints")
	waypoints = waypoints and minetest.parse_json(waypoints) or {}
	waypoints.data = waypoints.data or {}

	return waypoints
end

ui.register_page("waypoints", {
	get_formspec = function(player)
		local player_name = player:get_player_name()
		local wp_info_x = ui.style_full.form_header_x + 1.25
		local wp_info_y = ui.style_full.form_header_y + 0.5
		local wp_bottom_row = ui.style_full.std_inv_y - 1
		local wp_buttons_rj = ui.style_full.std_inv_x + 10.1 - ui.style_full.btn_spc
		local wp_edit_w = ui.style_full.btn_spc * 4 - 0.1

		local waypoints = get_waypoint_data(player)
		local sel = waypoints.selected or 1

		local formspec = {
			ui.style_full.standard_inv_bg,
			string.format("label[%f,%f;%s]",
				ui.style_full.form_header_x, ui.style_full.form_header_y, F(S("Waypoints"))),
			"image["..wp_info_x..","..wp_info_y..";1,1;ui_waypoints_icon.png]"
		}
		local n=4

		-- Tabs buttons:
		for i = 1, COUNT do
			local sw="select_waypoint"..i
			formspec[n] = string.format("image_button[%f,%f;%f,%f;%sui_%i_icon.png;%s;]",
				ui.style_full.main_button_x, wp_bottom_row - (5-i) * ui.style_full.btn_spc,
				ui.style_full.btn_size, ui.style_full.btn_size,
				(i == sel) and "ui_blue_icon_background.png^" or "",
				i, sw)
			formspec[n+1] = "tooltip["..sw..";"..S("Select Waypoint #@1", i).."]"
			n = n + 2
		end

		local waypoint = waypoints.data[sel] or {}
		local temp = waypoints_temp[player_name][sel] or {}
		local default_name = S("Waypoint @1", sel)

		-- Main buttons:
		local btnlist = {
			set_waypoint = {
				"ui_waypoint_set_icon.png",
				S("Set waypoint to current location")
			},
			toggle_waypoint = {
				waypoint.active and "ui_on_icon.png" or "ui_off_icon.png",
				waypoint.active and S("Hide waypoint") or S("Show waypoint")
			},
			toggle_display_pos = {
				waypoint.display_pos and "ui_green_icon_background.png^ui_xyz_icon.png" or "ui_red_icon_background.png^ui_xyz_icon.png^(ui_no.png^[transformR90)",
				waypoint.display_pos and S("Hide coordinates") or S("Show coordinates")
			},
			toggle_color = {
				"ui_circular_arrows_icon.png",
				S("Change color of waypoint display")
			},
			rename_waypoint = {
				"ui_pencil_icon.png",
				S("Edit waypoint name")
			}
		}

		local x = 4
		for name, def in pairs(btnlist) do
			formspec[n] = string.format("image_button[%f,%f;%f,%f;%s;%s%i;]",
				wp_buttons_rj - ui.style_full.btn_spc * x, wp_bottom_row,
				ui.style_full.btn_size, ui.style_full.btn_size,
				def[1], name, sel)
			formspec[n+1] = "tooltip["..name..sel..";"..F(def[2]).."]"
			x = x - 1
			n = n + 2
		end

		-- Waypoint's info:
		formspec[n] = ("label[%f,%f;%s]"):format(
			wp_info_x, wp_info_y + 1.1,
			F(waypoint.active and S("Waypoint active") or S("Waypoint inactive"))
		)
		n = n + 1

		if temp.edit then
			formspec[n] = string.format("field[%f,%f;%f,%f;rename_box%i;;%s]",
				wp_buttons_rj - wp_edit_w - 0.1, wp_bottom_row - ui.style_full.btn_spc,
				wp_edit_w, ui.style_full.btn_size, sel, (waypoint.name or default_name))
			formspec[n+1] = string.format("image_button[%f,%f;%f,%f;ui_ok_icon.png;confirm_rename%i;]",
				wp_buttons_rj, wp_bottom_row - ui.style_full.btn_spc,
				ui.style_full.btn_size, ui.style_full.btn_size, sel)
			formspec[n+2] = "tooltip[confirm_rename"..sel..";"..F(S("Finish editing")).."]"
			n = n + 3
		end

		formspec[n] = string.format("label[%f,%f;%s: %s]",
			wp_info_x, wp_info_y+1.6, F(S("World position")),
			minetest.pos_to_string(waypoint.world_pos or vector.new()))
		formspec[n+1] = string.format("label[%f,%f;%s: %s]",
			wp_info_x, wp_info_y+2.10, F(S("Name")), (waypoint.name or default_name))
		formspec[n+2] = string.format("label[%f,%f;%s: %s]",
			wp_info_x, wp_info_y+2.60, F(S("HUD text color")), hud_colors[waypoint.color or 1][3])

		return {formspec=table.concat(formspec)}
	end,
})

ui.register_button("waypoints", {
	type = "image",
	image = "ui_waypoints_icon.png",
	tooltip = S("Waypoints"),
	hide_lite=true
})

local function update_hud(player, waypoints, temp, i)
	local waypoint = waypoints.data[i]
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
		name = waypoint.name or S("Waypoint @1", i)
	end

	-- Perform HUD updates
	if temp.hud then
		player:hud_remove(temp.hud)
		temp.hud = nil
	end
	if waypoint.active then
		temp.hud = player:hud_add({
			hud_elem_type = "waypoint",
			number = hud_colors[waypoint.color or 1][2] ,
			name = name,
			text = "m",
			world_pos = pos
		})
	end
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "" then return end

	local player_name = player:get_player_name()
	local update_formspec = false
	local need_update_hud = false
	local hit = false

	local waypoints = get_waypoint_data(player)
	local temp = waypoints_temp[player_name]
	for i = 1, COUNT do
		local waypoint = waypoints.data[i] or {}

		if fields["select_waypoint"..i] then
			hit = true
			waypoints.selected = i
			update_formspec = true
		end

		if fields["toggle_waypoint"..i] then
			hit = true
			waypoint.active = not (waypoint.active)
			need_update_hud = true
			update_formspec = true
		end

		if fields["set_waypoint"..i] then
			hit = true
			local pos = vector.round(player:get_pos())
			waypoint.world_pos = pos
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
			waypoint.display_pos = not waypoint.display_pos
			need_update_hud = true
			update_formspec = true
		end

		if fields["toggle_color"..i] then
			hit = true
			local color = waypoint.color or 0
			color = color + 1
			if color > #hud_colors then
				color = 1
			end
			waypoint.color = color
			need_update_hud = true
			update_formspec = true
		end

		if fields["confirm_rename"..i] then
			hit = true
			temp[i] = temp[i] or {}
			temp[i].edit = false
			waypoint.name = fields["rename_box"..i]
			need_update_hud = true
			update_formspec = true
		end

		if hit then
			-- Save first
			waypoints.data[i] = waypoint
			set_waypoint_data(player, waypoints)
		end
		-- Update after
		if need_update_hud then
			update_hud(player, waypoints, temp, i)
		end
		if update_formspec then
			ui.set_inventory_formspec(player, "waypoints")
		end

		if hit then return end
	end
end)


minetest.register_on_joinplayer(function(player)
	local player_name = player:get_player_name()
	local waypoints = get_waypoint_data(player)

	waypoints_temp[player_name] = {}
	for i = 1, COUNT do
		update_hud(player, waypoints, waypoints_temp[player_name], i)
	end
end)

minetest.register_on_leaveplayer(function(player)
	waypoints_temp[player:get_player_name()] = nil
end)

