core.log("error", "[unified_inventory] Unittests are enabled!")

local ui = unified_inventory

core.register_craftitem(":uitest:leaves", {
	description = "UITEST Leaves",
	inventory_image = "default_leaves.png",
})

core.register_craftitem(":uitest:apple", {
	description = "UITEST Apple",
	inventory_image = "default_apple.png",
})

core.register_craftitem(":uitest:stick", {
	description = "UITEST Stick",
	inventory_image = "default_stick.png",
})

do
	ui.register_craft({
		type = "digging_chance",
		items = {"uitest:leaves"},
		output = ItemStack("uitest:apple 2"),
		width = 0,
	})
	ui.register_craft({
		type = "digging_chance",
		items = {"uitest:leaves"},
		output = { ItemStack("uitest:apple 1"), "uitest:stick 3" },
		width = 0,
	})
end

local function find_recipe_output(recipes, output)
	for _, recipe in ipairs(recipes) do
		if type(recipe.output) == "table" then
			-- get_recipe_list2(..)
			for _, itemstack in ipairs(recipe.output) do
				if itemstack:to_string() == output then
					return recipe
				end
			end
		else
			-- get_recipe_list(..)
			if recipe.output == output then
				return recipe
			end
		end
	end
	return nil
end

local function run_tests()
	local list, match

	list = ui.get_recipe_list2("uitest:apple")
	assert(#list == 2)
	match = assert(find_recipe_output(list, "uitest:stick 3"))
	assert(match.items[1] == "uitest:leaves")

	-- Backwards compat
	list = ui.get_recipe_list("uitest:apple")
	assert(#list == 1)
	match = assert(find_recipe_output(list, "uitest:apple 2"))
	assert(match.items[1] == "uitest:leaves")

	-- Done
	error("Tests passed!")
end

core.after(1, run_tests)
