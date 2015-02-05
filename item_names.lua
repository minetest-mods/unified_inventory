-- code based on 4itemnames mod by 4aiman

local wield = {}
local huds = {}
local dtimes = {}
local dlimit = 3  -- hud will be hidden after this much seconds
local airhudmod = minetest.get_modpath("4air")
local hudmod = minetest.get_modpath("hud")

local function get_desc(item)
    if minetest.registered_nodes[item] then return minetest.registered_nodes[item]["description"] end
    if minetest.registered_items[item] then return minetest.registered_items[item]["description"] end
    if minetest.registered_craftitems[item] then return minetest.registered_craftitems[item]["description"] end
    if minetest.registered_tools[item] then return minetest.registered_tools[item]["description"] end
    return ""
end

minetest.register_on_joinplayer(function(player)
	minetest.after(0.0, function()
	local player_name = player:get_player_name() 
	local off = {x=0, y=-70}
	if airhudmod or hudmod then 
		off.y=off.y-20
	end
	huds[player_name] = player:hud_add({
		hud_elem_type = "text",
		position = {x=0.5, y=1},
		offset = off,
		alignment = {x=0, y=0},
		number = 0xFFFFFF ,
		text = "",
	})
	--print(dump("item hud id: "..huds[player_name]))
	end)
end)

minetest.register_globalstep(function(dtime)
	local players = minetest.get_connected_players()
	for i,player in ipairs(players) do
		local player_name = player:get_player_name()
		local wstack = player:get_wielded_item():get_name()

		if dtimes[player_name] and dtimes[player_name] < dlimit then
			dtimes[player_name] = dtimes[player_name] + dtime
			if dtimes[player_name] > dlimit and huds[player_name] then
				player:hud_change(huds[player_name], 'text', "")
			end
		end

		if wstack ~= wield[player_name] then
			wield[player_name] = wstack
			local desc = get_desc(wstack)
			dtimes[player_name] = 0
			if huds[player_name] then 
				player:hud_change(huds[player_name], 'text', desc)
			end
		end
	end
end)
