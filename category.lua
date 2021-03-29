
unified_inventory.registered_categories = {}
unified_inventory.registered_category_items = {}
unified_inventory.category_list = {}

function update_category_list()
	local category_list = {}
	table.insert(category_list, {
		name = "all",
		label = "All",
		symbol = "ui_reset_icon.png",
		index = -2,
	})
	table.insert(category_list, {
		name = "uncategorised",
		label = "Misc.",
		symbol = "ui_no.png",
		index = -1,
	})
	for category, def in pairs(unified_inventory.registered_categories) do
		local b1,b2 = string.byte(string.upper(category), 1, 2)
		table.insert(category_list, {
			name = category,
			label = def.label or category,
			symbol = def.symbol,
			index =
				def.index or                    -- sortby defined order
				((b1-64)*0.01)+((b2-64)*0.0001) -- or do a rhudimentary alphabetical sort
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
