local ui = unified_inventory

local settings = {
	lite = {
		conf_value = core.settings:get_bool("unified_inventory_lite", false),
		-- title
		-- desc
		-- (values)
	},
	hide_disabled_buttons = {
		conf_value = core.settings:get_bool("unified_inventory_hide_disabled_buttons", false),
	},
	hide_uncraftable_items = {
		conf_value = core.settings:get_bool("unified_inventory_hide_uncraftable_items", false),
	},
	hide_groups_ifempty = {
		conf_value = "stair",
		title = "Automatically hidden groups",
		desc = "Comma-separated list of groups to hide from the item browser " ..
			"when no filter is applied (i.e. empty search box).",
		values = "group1, group2, ...",
	},
}

-- Read the descriptions from "settingtypes.txt" if available
do
	local modpath = core.get_modpath(core.get_current_modname())
	local file = io.open(modpath .. "/settingtypes.txt", "r")
	local desc = {}
	for line in file:lines() do
		local comment = line:match("^# (.*)")
		if comment then
			table.insert(desc, comment)
		end

		local key, title = line:match("^unified_inventory_(%S*)%s+(%b()).*")
		if title then
			title = title:sub(2, -2)
			if settings[key] then
				settings[key].title = title
				settings[key].desc = table.concat(desc, "\n")
			end
			desc = {}
		end
	end
end


local playersettings

--- Retrieves either a player-specific or global setting, depending
--- on whether `player` is specified
function ui.get_setting(player, key)
	local player_name = core.is_player(player) and player:get_player_name() or player
	assert(player_name == nil or type(player_name) == "string")
	assert(type(key) == "string")

	local def = settings[key]
	local value

	if player_name then
		if playersettings then
			value = playersettings.get(player_name, "unified_inventory:" .. key)
		else
			-- Backwards compat
			if key == "lite" then
				value = def.conf_value and not core.check_player_privs(player_name, {ui_full=true})
			end
		end
	end

	if value == nil then
		value = def.conf_value
	end

	if value == nil then
		core.log("warning", ("[unified_inventory] Setting '%s' not found"):format(key))
	end
	return value
end

local function on_setting_changed(player_name, old, new)
	if old == new then
		return
	end
	local player = core.get_player_by_name(player_name)
	ui.apply_filter(player, ui.current_searchbox[player_name])
	ui.set_inventory_formspec(player, ui.current_page[player_name])
end

local function register_playersettings()
	playersettings = _G.playersettings

	for key, def in pairs(settings) do
		--print("register", key, dump(def))
		playersettings.register("unified_inventory:" .. key, {
			type = type(def.conf_value),
			shortdesc = "Unified Inventory: " .. def.title,
			longdesc  = def.desc,
			default   = def.conf_value,
			afterchange = on_setting_changed,
			values = def.values
		})
	end
end

if core.get_modpath("playersettings") then
	-- Note: playersettings depends on unified_inventory, hence it is necessary
	--       to delay registration after all mods have loaded.
	core.register_on_mods_loaded(register_playersettings)
end
