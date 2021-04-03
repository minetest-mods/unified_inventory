local S = minetest.get_translator("unified_inventory")

unified_inventory.registered_categories = {}
unified_inventory.registered_category_items = {}
unified_inventory.category_list = {}

local function char_to_sort_index(char_code)
	if char_code <= 32 then
		-- Command codes, no thanks
		return 0
	end
	if char_code <= 64 then
		-- Sorts numbers, and some punctuation, after letters
		return char_code
	end
	if char_code >= 158 then
		-- Out of sortable range
		return 0
	end
	if char_code > 122 then
		-- Avoids overlap with {, |, } and ~
		return char_code - 58
	end
	if char_code > 96 then
		-- Normalises lowercase with uppercase
		return char_code - 96
	end
	return char_code - 64
end

local function string_to_sort_index(str)
	local max_chars = 5
	local power = 100
	local index = 0
	for i=1,math.min(#str, max_chars) do
		index = index + (char_to_sort_index(string.byte(str, i))/(power^i))
	end
	return index
end

function update_category_list()
	local category_list = {}
	table.insert(category_list, {
		name = "all",
		label = S("All Items"),
		symbol = "ui_category_all.png",
		index = -2,
	})
	table.insert(category_list, {
		name = "uncategorized",
		label = S("Misc. Items"),
		symbol = "ui_category_none.png",
		index = -1,
	})
	for category, def in pairs(unified_inventory.registered_categories) do
		table.insert(category_list, {
			name = category,
			label = def.label or category,
			symbol = def.symbol,
			index = def.index or                    -- sortby defined order
					string_to_sort_index(category)  -- or do a rudimentary alphabetical sort
		})
	end
	table.sort(category_list, function (a,b)
		return a.index < b.index
	end)
	unified_inventory.category_list = category_list
end

local function ensure_category_exists(category_name)
	if not unified_inventory.registered_categories[category_name] then
		unified_inventory.registered_categories[category_name] = {
			symbol = "default:stick",
			label = category_name
		}
	end
	if not unified_inventory.registered_category_items[category_name] then
		unified_inventory.registered_category_items[category_name] = {}
	end
end

function unified_inventory.register_category(category_name, config)
	ensure_category_exists(category_name)
	if config and config.symbol then
		unified_inventory.set_category_symbol(category_name, config.symbol)
	end
	if config and config.label then
		unified_inventory.set_category_label(category_name, config.label)
	end
	if config and config.index then
		unified_inventory.set_category_index(category_name, config.index)
	end
	if config and config.items then
		unified_inventory.add_category_items(category_name, config.items)
	end
	update_category_list()
end
function unified_inventory.set_category_symbol(category_name, symbol)
	ensure_category_exists(category_name)
	unified_inventory.registered_categories[category_name].symbol = symbol
	update_category_list()
end
function unified_inventory.set_category_label(category_name, label)
	ensure_category_exists(category_name)
	unified_inventory.registered_categories[category_name].label = label
	update_category_list()
end
function unified_inventory.set_category_index(category_name, index)
	ensure_category_exists(category_name)
	unified_inventory.registered_categories[category_name].index = index
	update_category_list()
end
function unified_inventory.add_category_item(category_name, item)
	ensure_category_exists(category_name)
	unified_inventory.registered_category_items[category_name][item] = true
end
function unified_inventory.add_category_items(category_name, items)
	for _,item in ipairs(items) do
		unified_inventory.add_category_item(category_name, item)
	end
end

function unified_inventory.remove_category_item(category_name, item)
	unified_inventory.registered_category_items[category_name][item] = nil
end
function unified_inventory.remove_category(category_name)
	unified_inventory.registered_categories[category_name] = nil
	unified_inventory.registered_category_items[category_name] = nil
	update_category_list()
end

function unified_inventory.find_category(item)
	-- Returns the first category the item exists in
	-- Best for checking if an item has any category at all
	for category, items in pairs(unified_inventory.registered_category_items) do
		if items[item] then return category end
	end
end
function unified_inventory.find_categories(item)
	-- Returns all the categories the item exists in
	-- Best for listing all categories
	local categories = {}
	for category, items in pairs(unified_inventory.registered_category_items) do
		if items[item] then
			table.insert(categories, category)
		end
	end
	return categories
end
