local S = minetest.get_translator("unified_inventory")
local ui = unified_inventory

function unified_inventory.extract_groupnames(groupname)
	local specname = ItemStack(groupname):get_name()
	if specname:sub(1, 6) ~= "group:" then
		return nil, 0
	end
	local group_names = specname:sub(7):split(",")
	return table.concat(group_names, S(" and ")), #group_names
end


--- @brief See documentation of `unified_inventory.get_group_item`
---        Used in the craft guide to show a group item
local function compute_group_item(group_name_list)
	local candidate_items = ui.get_matching_items("group:" .. group_name_list)

	local is_group = {}
	for _, group_name in ipairs(group_name_list:split(",")) do
		is_group[group_name] = true
	end

	local count = 0
	local bestitem
	local bestpref = 0
	for item, _ in pairs(candidate_items) do
		count = count + 1

		local pref
		if string.sub(item, 1, 8) == "default:" and is_group[string.sub(item, 9)] then
			-- TODO: Rank according to the mod load order but as of 5.15.0 there is no such API.
			pref = 3
		elseif is_group[item:gsub("^[^:]*:", "")] then
			-- The item name happens to match the group name
			pref = 2
		else
			pref = 1
		end
		if pref > bestpref or (pref == bestpref and item < bestitem) then
			bestitem = item
			bestpref = pref
		end
	end

	return {
		item = bestitem, -- may be nil
		sole = (count <= 1)
	}
end


local group_item_cache = {}

--- @brief Finds "the best matching" item that has all of the specified groups.
---        Use-case: get an image for recipe ingredients that are a group.
--- @param group_name string, e.g. "tree,flammable"
--- @return A table: `{ item = "mymod:best_fit", sole = boolean }`
---         When `sole == true` --> no "G" (group) button text
function unified_inventory.get_group_item(group_name)
	if not group_item_cache[group_name] then
		group_item_cache[group_name] = compute_group_item(group_name)
	end
	return group_item_cache[group_name]
end


-- { group1 = { ["item:name1"] = true, ... }, group2 =  .... }
local group_to_item_list = {}
local group_LUT_initialized = false

--[[
This is for filtering known items by groups
e.g. find all items that match "group:flower,yellow" (flower AND yellow groups)
]]
function unified_inventory.init_matching_cache()
	for _, name in ipairs(ui.items_list) do
		-- we only need to care about groups, exact items are handled separately
		for group, value in pairs(minetest.registered_items[name].groups) do
			if value and value ~= 0 then
				if not group_to_item_list[group] then
					group_to_item_list[group] = {}
				end
				group_to_item_list[group][name] = true
			end
		end
	end
	group_LUT_initialized = true
end

--[[
Retrieves all matching items

Arguments:
	specname (string): Item name or group(s) to filter

Output:
	{
		matchingitem1 = true,
		...
	}
]]
function unified_inventory.get_matching_items(specname)
	assert(group_LUT_initialized) -- Function must not be called too early.

	if specname:sub(1,6) ~= "group:" then
		return { [specname] = true }
	end

	local accepted = {}
	for i, group in ipairs(specname:sub(7):split(",")) do
		local item_list = group_to_item_list[group]
		if i == 1 then
			-- First step: Copy all possible item names in this group
			for name, _ in pairs(item_list or {}) do
				accepted[name] = true
			end
		else
			-- Perform filtering
			if item_list then
				for name, _ in pairs(accepted) do
					-- Is set to `nil` if the group is missing
					accepted[name] = item_list[name]
				end
			else
				-- No matching items
				return {}
			end
		end
	end
	return accepted
end
