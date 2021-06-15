local S = minetest.get_translator("unified_inventory")
local ui = unified_inventory

local function clear_inventory(player)
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
end

local clear_inv_button = {
	type = "image",
	image = "ui_trash_icon.png",
	tooltip = S("Clear inventory"),
	condition = function(player)
		return ui.is_creative(player:get_player_name())
	end,
}

print("bool :", minetest.settings:get_bool("unified_inventory_clear_inventory_confirm"))

if minetest.settings:get_bool("unified_inventory_clear_inventory_confirm") then
	ui.register_page("clear_inv", {
		get_formspec = function(player, perplayer_formspec)
			return {
				formspec = perplayer_formspec.standard_inv_bg ..
				"label[1,1;" .. S("Clear inventory") .. " ?]" ..
				"image_button[4,2;1.5,1.5;ui_ok_icon.png;clear_inv_confirm;]" ..
				"image_button[6,2;1.5,1.5;ui_no.png;clear_inv_cancel;]"
				,
			}
		end,
	})

	minetest.register_on_player_receive_fields(function(player, formname, fields)
		if formname ~= "" then
			return
		end

		for k, v in pairs(fields) do
			if k:match("clear_inv_confirm") then
				clear_inventory(player)
				ui.set_inventory_formspec(player, "craft")
				return
			end
			if k:match("clear_inv_cancel") then
				ui.set_inventory_formspec(player, "craft")
				return
			end
		end
	end)
else
	clear_inv_button.action = clear_inventory
end

ui.register_button("clear_inv", clear_inv_button)
