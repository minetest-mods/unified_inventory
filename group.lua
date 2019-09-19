local S = minetest.get_translator("unified_inventory")

function unified_inventory.canonical_item_spec_matcher(spec)
	local specname = ItemStack(spec):get_name()
	if specname:sub(1, 6) ~= "group:" then
		return function (itemname)
			return itemname == specname
		end
	end

	local group_names = specname:sub(7):split(",")
	return function (itemname)
		local itemdef = minetest.registered_items[itemname]
		for _, group_name in ipairs(group_names) do
			if (itemdef.groups[group_name] or 0) == 0 then
				return false
			end
		end
		return true
	end
end

function unified_inventory.item_matches_spec(item, spec)
	local itemname = ItemStack(item):get_name()
	return unified_inventory.canonical_item_spec_matcher(spec)(itemname)
end

function unified_inventory.extract_groupnames(groupname)
	local specname = ItemStack(groupname):get_name()
	if specname:sub(1, 6) ~= "group:" then
		return nil, 0
	end
	local group_names = specname:sub(7):split(",")
	return table.concat(group_names, S(" and ")), #group_names
end

unified_inventory.registered_group_items = {
	mesecon_conductor_craftable = "mesecons:wire_00000000_off",
	stone = "default:cobble",
	wood = "default:wood",
	book = "default:book",
	sand = "default:sand",
	leaves = "default:leaves",
	tree = "default:tree",
	vessel = "vessels:glass_bottle",
	wool = "wool:white",
}

function unified_inventory.register_group_item(groupname, itemname)
	unified_inventory.registered_group_items[groupname] = itemname
end


-- This is used when displaying craft recipes, where an ingredient is
-- specified by group rather than as a specific item.  A single-item group
-- is represented by that item, with the single-item status signalled
-- in the "sole" field.  If the group contains no items at all, the item
-- field will be nil.
--
-- Within a multiple-item group, we prefer to use an item that has the
-- same specific name as the group, and if there are more than one of
-- those items we prefer the one registered for the group by a mod.
-- Among equally-preferred items, we just pick the one with the
-- lexicographically earliest name.
--
-- The parameter to this function isn't just a single group name.
-- It may be a comma-separated list of group names.  This is really a
-- "group:..." ingredient specification, minus the "group:" prefix.

local function compute_group_item(group_name_list)
	local group_names = group_name_list:split(",")
	local candidate_items = {}
	for itemname, itemdef in pairs(minetest.registered_items) do
		if (itemdef.groups.not_in_creative_inventory or 0) == 0 then
			local all = true
			for _, group_name in ipairs(group_names) do
				if (itemdef.groups[group_name] or 0) == 0 then
					all = false
				end
			end
			if all then table.insert(candidate_items, itemname) end
		end
	end
	local num_candidates = #candidate_items
	if num_candidates == 0 then
		return {sole = true}
	elseif num_candidates == 1 then
		return {item = candidate_items[1], sole = true}
	end
	local is_group = {}
	local registered_rep = {}
	for _, group_name in ipairs(group_names) do
		is_group[group_name] = true
		local rep = unified_inventory.registered_group_items[group_name]
		if rep then registered_rep[rep] = true end
	end
	local bestitem = ""
	local bestpref = 0
	for _, item in ipairs(candidate_items) do
		local pref
		if registered_rep[item] then
			pref = 4
		elseif string.sub(item, 1, 8) == "default:" and is_group[string.sub(item, 9)] then
			pref = 3
		elseif is_group[item:gsub("^[^:]*:", "")] then
			pref = 2
		else
			pref = 1
		end
		if pref > bestpref or (pref == bestpref and item < bestitem) then
			bestitem = item
			bestpref = pref
		end
	end
	return {item = bestitem, sole = false}
end


local group_item_cache = {}

function unified_inventory.get_group_item(group_name)
	if not group_item_cache[group_name] then
		group_item_cache[group_name] = compute_group_item(group_name)
	end
	return group_item_cache[group_name]
end

