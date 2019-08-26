local function extract_group_name(name)
	return name:match("^group:(.+)")
end

local function count_compare(item1, item2)
	return item1.index.total_count > item2.index.total_count
end

local function lex_compare(group1, group2)
	local items1 = group1.items
	local items2 = group2.items

	local len1 = group1.items_count
	local len2 = group2.items_count
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
			times_used = 1,
			craft_positions = {craft_pos},
			found = false
		}
	else
		local times_used = item.times_used + 1

		item.craft_positions[times_used] = craft_pos
		item.times_used = times_used
	end
end

function unified_inventory.add_craft_group(t, group_name, craft_pos)
	local group = t[group_name]

	if group == nil then
		t[group_name] = {
			times_used = 1,
			craft_positions = {craft_pos},
			found = false,
			items_count = 0,
			found_items = {}
		}
	else
		local times_used = group.times_used + 1

		group.craft_positions[times_used] = craft_pos
		group.times_used = times_used
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

			local items_count = group.items_count + 1

			group.found_items[items_count] = item_name
			group.items_count = items_count
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

function unified_inventory.create_item_index(craft_index)
	local item_index = {
		craft_index = craft_index,
		stack_max = nil,
		used_items = {},
		unused_items = {}
	}

	return item_index
end

function unified_inventory.add_list_items(item_index, inv_list)
	local craft_index = item_index.craft_index
	local index_used = item_index.used_items
	local index_unused = item_index.unused_items

	local list_count = #inv_list

	for i = 1, list_count do
		local stack = inv_list[i]

		if not stack:is_empty() then
			local item_name = stack:get_name()
			local item_count = stack:get_count()
			local item = index_used[item_name]

			if item == nil then
				if index_unused[item_name] == nil then
					local item_found = unified_inventory.find_craft_item(item_name, craft_index)

					if item_found then
						index_used[item_name] = {
							total_count = item_count,
							times_matched = 0
						}

						local stack_max = stack:get_stack_max()
						local index_stack_max = item_index.stack_max

						if index_stack_max == nil or stack_max < index_stack_max then
							item_index.stack_max = stack_max
						end
					else
						index_unused[item_name] = true
					end
				end
			else
				item.total_count = item.total_count + item_count
			end
		end
	end
end

function unified_inventory.get_group_items(group, item_index)
	local items = {}
	local items_names = group.found_items
	local items_count = group.items_count

	local index_used = item_index.used_items

	for i = 1, items_count do
		local item_name = items_names[i]
		local item = index_used[item_name]

		items[i] = {
			name = item_name,
			index = item
		}
	end

	return items
end

function unified_inventory.ordered_groups(craft_index, item_index)
	local groups = {}
	local groups_count = 0

	for group_name, group in pairs(craft_index.groups) do
		local group_items = unified_inventory.get_group_items(group, item_index)
		table.sort(group_items, count_compare)

		groups_count = groups_count + 1

		groups[groups_count] = {
			name = group_name,
			items_count = group.items_count,
			items = group_items
		}
	end

	table.sort(groups, lex_compare)

	local i = 0

	return function()
		i = i + 1

		if i <= groups_count then
			local group = groups[i]
			return craft_index.groups[group.name], group.items
		end
	end
end

function unified_inventory.match_items(m, craft_index, item_index)
	local index_used = item_index.used_items

	for item_name, item in pairs(craft_index.items) do
		local index = index_used[item_name]
		local times_used = item.times_used
		local cell_count = math.floor(index.total_count / times_used)

		if cell_count == 0 then
			m.count = 0
			return
		end

		index.times_matched = times_used
		m.count = math.min(m.count, cell_count)

		local positions = item.craft_positions

		for i = 1, times_used do
			local craft_pos = positions[i]
			m.items[craft_pos] = item_name
		end
	end
end

function unified_inventory.match_groups(m, craft_index, item_index)
	for group, group_items in unified_inventory.ordered_groups(craft_index, item_index) do
		local times_used = group.times_used
		local positions = group.craft_positions
		local items_count = group.items_count

		for i = 1, times_used do
			local craft_pos = positions[i]

			local cell_count = 0
			local matched_item = nil

			for j = 1, items_count do
				local item = group_items[j]
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
	local match_table = {
		count = item_index.stack_max,
		items = {}
	}

	unified_inventory.match_items(match_table, craft_index, item_index)
	unified_inventory.match_groups(match_table, craft_index, item_index)

	if match_table.count == 0 then
		return
	end

	return match_table
end

function unified_inventory.find_best_match(src_list, dst_list, craft)
	local craft_index = unified_inventory.create_craft_index(craft)

	local item_index = unified_inventory.create_item_index(craft_index)
	unified_inventory.add_list_items(item_index, src_list)
	unified_inventory.add_list_items(item_index, dst_list)

	if not unified_inventory.all_items_found(craft_index) then
		return
	end

	return unified_inventory.get_match_table(craft_index, item_index)
end

function unified_inventory.craftguide_match_craft(inv, src_list_name, dst_list_name, craft, amount)
	local src_list = inv:get_list(src_list_name)
	local dst_list = inv:get_list(dst_list_name)

	local craft_match = unified_inventory.find_best_match(src_list, dst_list, craft)

	if craft_match == nil then
		return
	end

	local matched_items = craft_match.items
	local matched_count = craft_match.count

	if amount == -1 then
		amount = matched_count
	elseif amount > matched_count then
		return
	end

	-- Clear crafting grid (if possible)
	for i = 1, 9 do
		local dst_stack = inv:get_stack(dst_list_name, i)
		local leftover = inv:add_item(src_list_name, dst_stack)

		inv:set_stack(dst_list_name, i, leftover)
	end

	local fixed = {}

	for match_pos, item_name in pairs(matched_items) do
		local matched_stack = ItemStack(item_name)
		matched_stack:set_count(amount)

		local src_take = inv:remove_item(src_list_name, matched_stack)
		local src_take_count = src_take:get_count()
		local diff = amount - src_take_count

		if diff > 0 then
			matched_stack:set_count(diff)
			src_take:add_item(matched_stack)

			-- Because we take from dst_list we need to exclude already matched positions
			for i = 1, 9 do
				if fixed[i] == nil then
					local dst_take_stack = inv:get_stack(dst_list_name, i)
					local dst_name = dst_take_stack:get_name()

					if item_name == dst_name then
						local dst_count = dst_take_stack:get_count()

						if diff > dst_count then
							diff = diff - dst_count
							inv:set_stack(dst_list_name, i, nil)
						else
							dst_take_stack:set_count(dst_count - diff)
							inv:set_stack(dst_list_name, i, dst_take_stack)
							break
						end
					end
				end
			end
		end

		local dst_stack = inv:get_stack(dst_list_name, match_pos)
		inv:set_stack(dst_list_name, match_pos, src_take)

		local src_leftover = inv:add_item(src_list_name, dst_stack)

		if not src_leftover:is_empty() then
			local dst_leftover = inv:add_item(dst_list_name, src_leftover)

			if not dst_leftover:is_empty() then
				matched_stack:set_count(amount)

				inv:set_stack(dst_list_name, match_pos, dst_leftover)

				local src_reverse = inv:add_item(src_list_name, matched_stack)

				if not src_reverse:is_empty() then
					local dst_reserse = inv:add_item(dst_list_name, src_reverse)
				end
			end
		end

		fixed[match_pos] = true
	end
end
