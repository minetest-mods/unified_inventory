local ui = unified_inventory

local function drop(pos, itemstack)
	local obj = minetest.add_item(pos, itemstack:take_item(itemstack:get_count()))
	if obj then
		obj:set_velocity({
			x = math.random(-10, 10) / 9,
			y = 5,
			z = math.random(-10, 10) / 9,
		})
	end
end

local function add_to_bones(bones_inv,stk,pos)
	if bones_inv and bones_inv:room_for_item("main", stk) then
		bones_inv:add_item("main", stk)
	else
		drop(pos, stk)
	end
end

minetest.register_on_dieplayer(function(player)
	local bones_mode = minetest.settings:get("bones_mode")
	if bones_mode ~= "bones" and bones_mode ~= "drop" and bones_mode ~= "keep" then
		bones_mode = "bones"
	end
	local player_name=player:get_player_name()

	if bones_mode == "keep" or minetest.is_creative_enabled(player_name) then
		return
	end

	local pos = player:get_pos()

	minetest.after(1, function()
		local bones_meta = nil
		local player_meta = player:get_meta()
		local maxp = vector.add(pos, 16)
		local minp = vector.subtract(pos, 16)
		local bones = minetest.find_nodes_in_area(minp, maxp, {"bones:bones"})
		local name = player_name

		for _, p in pairs(bones) do
			local m = minetest.get_meta(p)
			if m:get_string("owner") == name then
				bones_meta = m
				break
			end
		end
		local bones_inv = nil
		if bones_meta then
			bones_inv = bones_meta:get_inventory()
		end
		local player_inv = player:get_inventory()
		for i = 1, 4 do
			local x = minetest.get_inventory({
					type = "detached",
					name = player:get_player_name() .. "_bags"
				}):get_stack("bag" .. i, 1)
			add_to_bones(bones_inv,x,pos)
			local def = x:get_definition()
			if(def.groups.bagslots)then
				local list_name = "bag" .. i .. "contents"
				local size = player_inv:get_size(list_name)
				for si = 1, size do
					local stk = player_inv:get_stack(list_name, si)
					player_inv:set_stack(list_name, 0, nil)
					add_to_bones(bones_inv,stk,pos)
				end
				minetest.get_inventory({
						type = "detached",
						name = player:get_player_name() .. "_bags"
					}):set_stack("bag" .. i, 1, nil)
				player_meta:set_string("unified_inventory:bags", nil)
				player_inv:set_size(list_name, 0)
			end
		end
	end)
end)
