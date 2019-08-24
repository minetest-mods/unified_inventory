local function extract_group_name(name)
	return name:match("^group:(.+)")
end

local function count_compare(item1, item2)
	return item1.index.total_count > item2.index.total_count
end

local function lex_compare(group1, group2)
	local items1 = group1.items
	local items2 = group2.items

	local len1 = #items1
	local len2 = #items2
	local min_len = math.min(len1, len2)

	for i = 1, min_len do
		local count1 = items1[i].index.total_count
		local count2 = items2[i].index.total_count

		if count1 ~= count2 then
			return count1 < count2
		end
	end

	return len1 < len2
end

function unified_inventory.add_craft_item(t, item_name, craft_pos)
	local item = t[item_name]

	if item == nil then
		t[item_name] = {
			craft_positions = {craft_pos},
			found = false
		}
	else
		table.insert(item.craft_positions, craft_pos)
	end
end

function unified_inventory.add_craft_group(t, group_name, craft_pos)
	local group = t[group_name]

	if group == nil then
		t[group_name] = {
			craft_positions = {craft_pos},
			found = false,
			found_items = {}
		}
	else
		table.insert(group.craft_positions, craft_pos)
	end
end

function unified_inventory.create_craft_index(craft)
	local craft_index = {
		items = {},
		groups = {}
	}

	local MAX_HEIGHT = 3
	local MAX_WIDTH = 3

	local craft_items = craft.items
	local craft_width = craft.width

	if craft_width == 0 then
		craft_width = MAX_WIDTH
	end

	local pos = 1

	for y = 1, MAX_HEIGHT do
		for x = 1, craft_width do
			local craft_pos = (y - 1) * MAX_WIDTH + x
			local item = craft_items[pos]

			if item ~= nil then
				local group = extract_group_name(item)

				if group == nil then
					unified_inventory.add_craft_item(craft_index.items, item, craft_pos)
				else
					unified_inventory.add_craft_group(craft_index.groups, group, craft_pos)
				end
			end

			pos = pos + 1
		end
	end

	return craft_index
end

function unified_inventory.find_craft_item(item_name, craft_index)
	local found = false
	local item = craft_index.items[item_name]
	local get_item_group = minetest.get_item_group

	if item ~= nil then
		item.found = true
		found = true
	end

	for group_name, group in pairs(craft_index.groups) do
		if get_item_group(item_name, group_name) > 0 then
			group.found = true
			found = true

			table.insert(group.found_items, item_name)
		end
	end

	return found
end

function unified_inventory.all_items_found(craft_index)
	for _, item in pairs(craft_index.items) do
		if not item.found then
			return false
		end
	end

	for _, group in pairs(craft_index.groups) do
		if not group.found then
			return false
		end
	end

	return true
end

function unified_inventory.create_item_index(inv_list, craft_index)
	local item_index = {}
	local not_found = {}

	for _, stack in ipairs(inv_list) do
		if not stack:is_empty() then
			local item_name = stack:get_name()
			local item_count = stack:get_count()
			local item = item_index[item_name]

			if item == nil then
				if not_found[item_name] == nil then
					local item_found = unified_inventory.find_craft_item(item_name, craft_index)

					if item_found then
						item_index[item_name] = {
							total_count = item_count,
							times_matched = 0
						}
					else
						not_found[item_name] = true
					end
				end
			else
				item.total_count = item.total_count + item_count
			end
		end
	end

	return item_index
end

function unified_inventory.get_group_items(group_name, craft_index, item_index)
	local items = {}
	local group = craft_index.groups[group_name]

	for _, item_name in ipairs(group.found_items) do
		local item = item_index[item_name]

		table.insert(items, {
			name = item_name,
			index = item
		})
	end

	return items
end

function unified_inventory.ordered_groups(craft_index, item_index)
	local groups = {}

	for group_name in pairs(craft_index.groups) do
		local group_items = unified_inventory.get_group_items(group_name, craft_index, item_index)
		table.sort(group_items, count_compare)

		table.insert(groups, {
			name = group_name,
			items = group_items
		})
	end

	table.sort(groups, lex_compare)

	local i = 0
	local n = #groups

	return function()
		i = i + 1

		if i <= n then
			local group = groups[i]
			return craft_index.groups[group.name], group.items
		end
	end
end

function unified_inventory.match_items(m, craft_index, item_index)
	for item_name, item in pairs(craft_index.items) do
		local index = item_index[item_name]
		local times_used = #item.craft_positions
		local cell_count = math.floor(index.total_count / times_used)

		if cell_count == 0 then
			m.count = 0
			return
		end

		index.times_matched = times_used
		m.count = math.min(m.count, cell_count)

		for _, craft_pos in ipairs(item.craft_positions) do
			m.items[craft_pos] = item_name
		end
	end
end

function unified_inventory.match_groups(m, craft_index, item_index)
	for group, group_items in unified_inventory.ordered_groups(craft_index, item_index) do
		for _, craft_pos in ipairs(group.craft_positions) do
			local cell_count = 0
			local matched_item = nil

			for _, item in ipairs(group_items) do
				local index = item.index

				local item_count = index.total_count
				local times_matched = index.times_matched
				local match_count = math.floor(item_count / (times_matched + 1))

				if match_count > cell_count then
					cell_count = match_count
					matched_item = item
				end
			end

			if cell_count == 0 then
				m.count = 0
				return
			end

			m.count = math.min(m.count, cell_count)
			m.items[craft_pos] = matched_item.name

			local matched_index = matched_item.index
			matched_index.times_matched = matched_index.times_matched + 1
		end
	end
end

function unified_inventory.get_match_table(craft_index, item_index)
	local MAX_COUNT = 99

	local match_table = {
		count = MAX_COUNT,
		items = {}
	}

	unified_inventory.match_items(match_table, craft_index, item_index)
	unified_inventory.match_groups(match_table, craft_index, item_index)

	if match_table.count == 0 then
		return
	end

	return match_table
end

function unified_inventory.find_best_match(inv_list, craft)
	local craft_index = unified_inventory.create_craft_index(craft)
	local item_index = unified_inventory.create_item_index(inv_list, craft_index)

	if not unified_inventory.all_items_found(craft_index) then
		return
	end

	return unified_inventory.get_match_table(craft_index, item_index)
end

function unified_inventory.can_move(match_items, inv_list)
	for match_pos, match_name in pairs(match_items) do
		local inv_item = inv_list[match_pos]

		if not inv_item:is_empty() then
			local inv_item_name = inv_item:get_name()

			if match_name ~= inv_item_name then
				return false
			end
		end
	end

	return true
end

function unified_inventory.craftguide_match_craft(inv, src_list_name, dst_list_name, craft, amount)
	local src_list = inv:get_list(src_list_name)
	local dst_list = inv:get_list(dst_list_name)

	local craft_match = unified_inventory.find_best_match(src_list, craft)

	if craft_match == nil then
		return
	end

	local matched_items = craft_match.items
	local matched_count = craft_match.count

	if not unified_inventory.can_move(matched_items, dst_list) then
		return
	end

	if amount == -1 then
		amount = matched_count
	elseif amount > matched_count then
		return
	end

	for match_pos, item_name in pairs(matched_items) do
		local dst_stack = dst_list[match_pos]
		local dst_count = dst_stack:get_count()

		local matched_stack = ItemStack(item_name)
		local match_max = matched_stack:get_stack_max()

		local take_count = math.min(match_max - dst_count, amount)

		if take_count > 0 then
			matched_stack:set_count(take_count)

			local taken_stack = inv:remove_item(src_list_name, matched_stack)
			local leftover = taken_stack:add_item(dst_stack)

			if not leftover:is_empty() then
				inv:add_item(src_list_name, leftover)
			end

			dst_list[match_pos] = taken_stack
		end
	end

	inv:set_list(dst_list_name, dst_list)
end
