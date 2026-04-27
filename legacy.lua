-- Inefficient pattern matching

local warned_funcs = {}
local function LOG_ONCE(funcname)
	if warned_funcs[funcname] then return end
	warned_funcs[funcname] = true
	core.log("error", "Call to undocumented, deprecated API '" .. funcname .. "'."
		.. " In a future version of Unified Inventory this will result in a real error.")
end

function unified_inventory.canonical_item_spec_matcher(spec)
	LOG_ONCE("canonical_item_spec_matcher")
	local specname = ItemStack(spec):get_name()
	if specname:sub(1, 6) ~= "group:" then
		return function (itemname)
			return itemname == specname
		end
	end

	local group_names = specname:sub(7):split(",")
	return function (itemname)
		local itemdef = core.registered_items[itemname]
		for _, group_name in ipairs(group_names) do
			if (itemdef.groups[group_name] or 0) == 0 then
				return false
			end
		end
		return true
	end
end

function unified_inventory.item_matches_spec(item, spec)
	LOG_ONCE("item_matches_spec")
	local itemname = ItemStack(item):get_name()
	return unified_inventory.canonical_item_spec_matcher(spec)(itemname)
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
	LOG_ONCE("register_group_item")
	unified_inventory.registered_group_items[groupname] = itemname
end

