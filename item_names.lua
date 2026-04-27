-- Based on 4itemnames mod by 4aiman

local item_names = {} -- [player_name] = { hud, dtime, itemname }
local dlimit = 3  -- HUD element will be hidden after this many seconds
local hudbars_mod = core.get_modpath("hudbars")
local only_names = core.settings:get_bool("unified_inventory_only_names", true)
local max_length = tonumber(core.settings:get("unified_inventory_max_item_name_length")) or 80

local function set_hud(player)
	local player_name = player:get_player_name()
	local off = {x=0, y=-65}
	if hudbars_mod then
		-- Assume no alignment (2 per line)
		off.y = off.y - math.ceil(hb.hudbars_count / 2) * 25
	else
		off.y = off.y - 25
	end

	item_names[player_name] = {
		hud = player:hud_add({
			-- TODO: remove compatibility code when 5.8.0 is no longer used
			[core.features.hud_def_type_field and "type" or "hud_elem_type"] = "text",
			position = {x=0.5, y=1},
			offset = off,
			alignment = {x=0, y=-1},
			number = 0xFFFFFF,
			text = "",
		}),
		dtime = dlimit,
		index = 1,
		itemname = ""
	}
end

core.register_on_joinplayer(function(player)
	core.after(0, set_hud, player)
end)

core.register_on_leaveplayer(function(player)
	item_names[player:get_player_name()] = nil
end)

core.register_globalstep(function(dtime)
	for _, player in pairs(core.get_connected_players()) do
		local data = item_names[player:get_player_name()]
		if not data or not data.hud then
			data = {} -- Update on next step
			set_hud(player)
		end

		local index = player:get_wield_index()
		local stack = player:get_wielded_item()
		local itemname = stack:get_name()

		if data.hud and data.dtime < dlimit then
			data.dtime = data.dtime + dtime
			if data.dtime > dlimit then
				player:hud_change(data.hud, 'text', "")
			end
		end

		if data.hud and (itemname ~= data.itemname or index ~= data.index) then
			data.itemname = itemname
			data.index = index
			data.dtime = 0
			local lang_code = core.get_player_information(player:get_player_name()).lang_code

			local desc = stack.get_meta
				and stack:get_meta():get_string("description")

			if not desc or desc == "" then
				-- Try to use default description when none is set in the meta
				local def = core.registered_items[itemname]
				desc = def and def.description or ""
			end
			if only_names and desc and string.find(desc, "\n") then
				desc = string.match(desc, "([^\n]*)")
			end
			desc = core.get_translated_string(lang_code, desc)
			desc = core.strip_colors(desc)
			if string.len(desc) > max_length and max_length > 0 then
				desc = string.sub(desc, 1, max_length) .. " [...]"
			end
			player:hud_change(data.hud, 'text', desc)
		end
	end
end)

