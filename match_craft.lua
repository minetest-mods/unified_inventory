-- match_craft.lua
-- Find and automatically move inventory items to the crafting grid
-- according to the recipe.

--[[
Retrieve items from inventory lists and calculate their total count.
Return a table of "item name" - "total count" pairs.

Arguments:
	inv: minetest inventory reference
	lists: names of inventory lists to use

Example usage:
	-- Count items in "main" and "craft" lists of player inventory
	unified_inventory.count_items(player_inv_ref, {"main", "craft"})

Example output:
	{
		["default:pine_wood"] = 2,
		["default:acacia_wood"] = 4,
		["default:chest"] = 3,
		["default:axe_diamond"] = 2, -- unstackable item are counted too
		["wool:white"] = 6
	}
]]--
function unified_inventory.count_items(inv, lists)
	local counts = {}

	for i = 1, #lists do
		local name = lists[i]
		local size = inv:get_size(name)
		local list = inv:get_list(name)

		for j = 1, size do
			local stack = list[j]

			if not stack:is_empty() then
				local item = stack:get_name()
				local count = stack:get_count()

				counts[item] = (counts[item] or 0) + count
			end
		end
	end

	return counts
end

--[[
Retrieve craft recipe items and their positions in the crafting grid.
Return a table of "craft item name" - "set of positions" pairs.

Note that if craft width is not 3 then positions are recalculated as
if items were placed on a 3x3 grid. Also note that craft can contain
groups of items with "group:" prefix.

Arguments:
	craft: minetest craft recipe

Example output:
	-- Bed recipe
	{
		["wool:white"] = {[1] = true, [2] = true, [3] = true}
		["group:wood"] = {[4] = true, [5] = true, [6] = true}
	}
--]]
function unified_inventory.count_craft_positions(craft)
	local positions = {}
	local craft_items = craft.items
	local craft_type = unified_inventory.registered_craft_types[craft.type]
	                   or unified_inventory.craft_type_defaults(craft.type, {})
	local display_width = craft_type.dynamic_display_size
	                      and craft_type.dynamic_display_size(craft).width
	                      or craft_type.width
	local craft_width = craft_type.get_shaped_craft_width
	                    and craft_type.get_shaped_craft_width(craft)
	                    or display_width
	local i = 0

	for y = 1, 3 do
		for x = 1, craft_width do
			i = i + 1
			local item = craft_items[i]

			if item ~= nil then
				local pos = 3 * (y - 1) + x
				local set = positions[item]

				if set ~= nil then
					set[pos] = true
				else
					positions[item] = {[pos] = true}
				end
			end
		end
	end

	return positions
end

--[[
For every craft item find all matching inventory items.
- If craft item is a group then find all inventory items that matches
  this group.
- If craft item is not a group (regular item) then find only this item.

If inventory doesn't contain needed item then found set is empty for
this item.

Return a table of "craft item name" - "set of matching inventory items"
pairs.

Arguments:
	inv_items: table with items names as keys
	craft_items: table with items names or groups as keys

Example output:
	{
		["group:wood"] = {
			["default:pine_wood"] = true,
			["default:acacia_wood"] = true
		},
		["wool:white"] = {
			["wool:white"] = true
		}
	}
--]]
function unified_inventory.find_usable_items(inv_items, craft_items)
	local get_group = minetest.get_item_group
	local result = {}

	for craft_item in pairs(craft_items) do
		local group = craft_item:match("^group:(.+)")
		local found = {}

		if group ~= nil then
			for inv_item in pairs(inv_items) do
				if get_group(inv_item, group) > 0 then
					found[inv_item] = true
				end
			end
		else
			if inv_items[craft_item] ~= nil then
				found[craft_item] = true
			end
		end

		result[craft_item] = found
	end

	return result
end

--[[
Match inventory items with craft grid positions.
For every position select the matching inventory item with maximum
(total_count / (times_matched + 1)) value.

If for some position matching item cannot be found or match count is 0
then return nil.

Return a table of "matched item name" - "set of craft positions" pairs
and overall match count.

Arguments:
	inv_counts: table of inventory items counts from "count_items"
	craft_positions: table of craft positions from "count_craft_positions"

Example output:
	match_table = {
		["wool:white"] = {[1] = true, [2] = true, [3] = true}
		["default:acacia_wood"] = {[4] = true, [6] = true}
		["default:pine_wood"] = {[5] = true}
	}
	match_count = 2
--]]
function unified_inventory.match_items(inv_counts, craft_positions)
	local usable = unified_inventory.find_usable_items(inv_counts, craft_positions)
	local match_table = {}
	local match_count
	local matches = {}

	for craft_item, pos_set in pairs(craft_positions) do
		local use_set = usable[craft_item]

		for pos in pairs(pos_set) do
			local pos_item
			local pos_count

			for use_item in pairs(use_set) do
				local count = inv_counts[use_item]
				local times_matched = matches[use_item] or 0
				local new_pos_count = math.floor(count / (times_matched + 1))

				if pos_count == nil or pos_count < new_pos_count then
					pos_item = use_item
					pos_count = new_pos_count
				end
			end

			if pos_item == nil or pos_count == 0 then
				return nil
			end

			local set = match_table[pos_item]

			if set ~= nil then
				set[pos] = true
			else
				match_table[pos_item] = {[pos] = true}
			end

			matches[pos_item] = (matches[pos_item] or 0) + 1
		end
	end

	for match_item, times_matched in pairs(matches) do
		local count = inv_counts[match_item]
		local item_count = math.floor(count / times_matched)

		if match_count == nil or item_count < match_count then
			match_count = item_count
		end
	end

	return match_table, match_count
end

--[[
Remove item from inventory lists.
Return stack of actually removed items.

This function replicates the inv:remove_item function but can accept
multiple lists.

Arguments:
	inv: minetest inventory reference
	lists: names of inventory lists
	stack: minetest item stack
--]]
function unified_inventory.remove_item(inv, lists, stack)
	local removed = ItemStack(nil)
	local leftover = ItemStack(stack)

	for i = 1, #lists do
		if leftover:is_empty() then
			break
		end

		local cur_removed = inv:remove_item(lists[i], leftover)
		removed:add_item(cur_removed)
		leftover:take_item(cur_removed:get_count())
	end

	return removed
end

--[[
Add item to inventory lists.
Return leftover stack.

This function replicates the inv:add_item function but can accept
multiple lists.

Arguments:
	inv: minetest inventory reference
	lists: names of inventory lists
	stack: minetest item stack
--]]
function unified_inventory.add_item(inv, lists, stack)
	local leftover = ItemStack(stack)

	for i = 1, #lists do
		if leftover:is_empty() then
			break
		end

		leftover = inv:add_item(lists[i], leftover)
	end

	return leftover
end

--[[
Move items from source list to destination list if possible.
Skip positions specified in exclude set.

Arguments:
	inv: minetest inventory reference
	src_list: name of source list
	dst_list: name of destination list
	exclude: set of positions to skip
--]]
function unified_inventory.swap_items(inv, src_list, dst_list, exclude)
	local size = inv:get_size(src_list)
	local empty = ItemStack(nil)

	for i = 1, size do
		if exclude == nil or exclude[i] == nil then
			local stack = inv:get_stack(src_list, i)

			if not stack:is_empty() then
				inv:set_stack(src_list, i, empty)
				local leftover = inv:add_item(dst_list, stack)

				if not leftover:is_empty() then
					inv:set_stack(src_list, i, leftover)
				end
			end
		end
	end
end

--[[
Move matched items to the destination list.

If destination list position is already occupied with some other item
then function tries to (in that order):
1. Move it to the source list
2. Move it to some other unused position in destination list itself
3. Drop it to the ground if nothing else is possible.

Arguments:
	player: minetest player object
	src_list: name of source list
	dst_list: name of destination list
	match_table: table of matched items
	amount: amount of items per every position
--]]
function unified_inventory.move_match(player, src_list, dst_list, match_table, amount)
	local inv = player:get_inventory()
	local item_drop = minetest.item_drop
	local src_dst_list = {src_list, dst_list}
	local dst_src_list = {dst_list, src_list}

	local needed = {}
	local moved = {}

	-- Remove stacks needed for craft
	for item, pos_set in pairs(match_table) do
		local stack = ItemStack(item)
		local stack_max = stack:get_stack_max()
		local bounded_amount = math.min(stack_max, amount)
		stack:set_count(bounded_amount)

		for pos in pairs(pos_set) do
			needed[pos] = unified_inventory.remove_item(inv, dst_src_list, stack)
		end
	end

	-- Add already removed stacks
	for pos, stack in pairs(needed) do
		local occupied = inv:get_stack(dst_list, pos)
		inv:set_stack(dst_list, pos, stack)

		if not occupied:is_empty() then
			local leftover = unified_inventory.add_item(inv, src_dst_list, occupied)

			if not leftover:is_empty() then
				inv:set_stack(dst_list, pos, leftover)
				local oversize = unified_inventory.add_item(inv, src_dst_list, stack)

				if not oversize:is_empty() then
					item_drop(oversize, player, player:get_pos())
				end
			end
		end

		moved[pos] = true
	end

	-- Swap items from unused positions to src (moved positions excluded)
	unified_inventory.swap_items(inv, dst_list, src_list, moved)
end

--[[
Find craft match and move matched items to the destination list.

If match cannot be found or match count is smaller than the desired
amount then do nothing.

If amount passed is -1 then amount is defined by match count itself.
This is used to indicate "craft All" case.

Arguments:
	player: minetest player object
	src_list: name of source list
	dst_list: name of destination list
	craft: minetest craft recipe
	amount: desired amount of output items
--]]
function unified_inventory.craftguide_match_craft(player, src_list, dst_list, craft, amount)
	local inv = player:get_inventory()
	local src_dst_list = {src_list, dst_list}

	local counts = unified_inventory.count_items(inv, src_dst_list)
	local positions = unified_inventory.count_craft_positions(craft)
	local match_table, match_count = unified_inventory.match_items(counts, positions)

	if match_table == nil or match_count < amount then
		return
	end

	if amount == -1 then
		amount = match_count
	end

	unified_inventory.move_match(player, src_list, dst_list, match_table, amount)
end
