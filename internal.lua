local S = unified_inventory.gettext
local F = unified_inventory.fgettext

-- This pair of encoding functions is used where variable text must go in
-- button names, where the text might contain formspec metacharacters.
-- We can escape button names for the formspec, to avoid screwing up
-- form structure overall, but they then don't get de-escaped, and so
-- the input we get back from the button contains the formspec escaping.
-- This is a game engine bug, and in the anticipation that it might be
-- fixed some day we don't want to rely on it.  So for safety we apply
-- an encoding that avoids all formspec metacharacters.
function unified_inventory.mangle_for_formspec(str)
	return string.gsub(str, "([^A-Za-z0-9])", function (c) return string.format("_%d_", string.byte(c)) end)
end
function unified_inventory.demangle_for_formspec(str)
	return string.gsub(str, "_([0-9]+)_", function (v) return string.char(v) end)
end

function unified_inventory.get_per_player_formspec(player_name)
	local lite = unified_inventory.lite_mode and not minetest.check_player_privs(player_name, {ui_full=true})

	local ui = {}
	ui.pagecols = unified_inventory.pagecols
	ui.pagerows = unified_inventory.pagerows
	ui.page_y = unified_inventory.page_y
	ui.formspec_y = unified_inventory.formspec_y
	ui.main_button_x = unified_inventory.main_button_x
	ui.main_button_y = unified_inventory.main_button_y
	ui.craft_result_x = unified_inventory.craft_result_x
	ui.craft_result_y = unified_inventory.craft_result_y
	ui.form_header_y = unified_inventory.form_header_y

	if lite then
		ui.pagecols = 4
		ui.pagerows = 6
		ui.page_y = 0.25
		ui.formspec_y = 0.47
		ui.main_button_x = 8.2
		ui.main_button_y = 6.5
		ui.craft_result_x = 2.8
		ui.craft_result_y = 3.4
		ui.form_header_y = -0.1
	end

	ui.items_per_page = ui.pagecols * ui.pagerows
	return ui, lite
end

function unified_inventory.get_formspec(player, page)

	if not player then
		return ""
	end

	local player_name = player:get_player_name()
	local ui_peruser,draw_lite_mode = unified_inventory.get_per_player_formspec(player_name)

	unified_inventory.current_page[player_name] = page
	local pagedef = unified_inventory.pages[page]

	local formspec = {
		"size[14,10]",
		"background[-0.19,-0.25;14.4,10.75;ui_form_bg.png]" -- Background
	}
	local n = 3

	if draw_lite_mode then
		formspec[1] = "size[11,7.7]"
		formspec[2] = "background[-0.19,-0.2;11.4,8.4;ui_form_bg.png]"
	end

	if unified_inventory.is_creative(player_name)
	and page == "craft" then
		formspec[n] = "background[0,"..(ui_peruser.formspec_y + 2)..";1,1;ui_single_slot.png]"
		n = n+1
	end

	-- Current page
	if not unified_inventory.pages[page] then
		return "" -- Invalid page name
	end

	local perplayer_formspec = unified_inventory.get_per_player_formspec(player_name)
	local fsdata = pagedef.get_formspec(player, perplayer_formspec)

	formspec[n] = fsdata.formspec
	n = n+1

	local button_row = 0
	local button_col = 0

	-- Main buttons

	local filtered_inv_buttons = {}

	for i, def in pairs(unified_inventory.buttons) do
		if not (draw_lite_mode and def.hide_lite) then 
			table.insert(filtered_inv_buttons, def)
		end
	end

	for i, def in pairs(filtered_inv_buttons) do

		if draw_lite_mode and i > 4 then
			button_row = 1
			button_col = 1
		end

		if def.type == "image" then
			if (def.condition == nil or def.condition(player) == true) then
				formspec[n] = "image_button["
				formspec[n+1] = ( ui_peruser.main_button_x + 0.65 * (i - 1) - button_col * 0.65 * 4)
				formspec[n+2] = ","..(ui_peruser.main_button_y + button_row * 0.7)..";0.8,0.8;"
				formspec[n+3] = minetest.formspec_escape(def.image)..";"
				formspec[n+4] = minetest.formspec_escape(def.name)..";]"
				formspec[n+5] = "tooltip["..minetest.formspec_escape(def.name)
				formspec[n+6] = ";"..(def.tooltip or "").."]"
				n = n+7
			else
				formspec[n] = "image["
				formspec[n+1] = ( ui_peruser.main_button_x + 0.65 * (i - 1) - button_col * 0.65 * 4)
				formspec[n+2] = ","..(ui_peruser.main_button_y + button_row * 0.7)..";0.8,0.8;"
				formspec[n+3] = minetest.formspec_escape(def.image).."^[colorize:#808080:alpha]"
				n = n+4

			end
		end
	end

	if fsdata.draw_inventory ~= false then
		-- Player inventory
		formspec[n] = "listcolors[#00000000;#00000000]"
		formspec[n+1] = "list[current_player;main;0,"..(ui_peruser.formspec_y + 3.5)..";8,4;]"
		n = n+2
	end

	if fsdata.draw_item_list == false then
		return table.concat(formspec, "")
	end

	-- Controls to flip items pages
	local start_x = 9.2

	if not draw_lite_mode then
		formspec[n] =
			"image_button[" .. (start_x + 0.6 * 0)
				.. ",9;.8,.8;ui_skip_backward_icon.png;start_list;]"
			.. "tooltip[start_list;" .. F("First page") .. "]"

			.. "image_button[" .. (start_x + 0.6 * 1)
				.. ",9;.8,.8;ui_doubleleft_icon.png;rewind3;]"
			.. "tooltip[rewind3;" .. F("Back three pages") .. "]"
			.. "image_button[" .. (start_x + 0.6 * 2)
				.. ",9;.8,.8;ui_left_icon.png;rewind1;]"
			.. "tooltip[rewind1;" .. F("Back one page") .. "]"

			.. "image_button[" .. (start_x + 0.6 * 3)
				.. ",9;.8,.8;ui_right_icon.png;forward1;]"
			.. "tooltip[forward1;" .. F("Forward one page") .. "]"
			.. "image_button[" .. (start_x + 0.6 * 4)
				.. ",9;.8,.8;ui_doubleright_icon.png;forward3;]"
			.. "tooltip[forward3;" .. F("Forward three pages") .. "]"

			.. "image_button[" .. (start_x + 0.6 * 5)
				.. ",9;.8,.8;ui_skip_forward_icon.png;end_list;]"
			.. "tooltip[end_list;" .. F("Last page") .. "]"
	else
		formspec[n] =
			"image_button[" .. (8.2 + 0.65 * 0)
				.. ",5.8;.8,.8;ui_skip_backward_icon.png;start_list;]"
			.. "tooltip[start_list;" .. F("First page") .. "]"
			.. "image_button[" .. (8.2 + 0.65 * 1)
				.. ",5.8;.8,.8;ui_left_icon.png;rewind1;]"
			.. "tooltip[rewind1;" .. F("Back one page") .. "]"
			.. "image_button[" .. (8.2 + 0.65 * 2)
				.. ",5.8;.8,.8;ui_right_icon.png;forward1;]"
			.. "tooltip[forward1;" .. F("Forward one page") .. "]"
			.. "image_button[" .. (8.2 + 0.65 * 3)
				.. ",5.8;.8,.8;ui_skip_forward_icon.png;end_list;]"
			.. "tooltip[end_list;" .. F("Last page") .. "]"
	end
	n = n+1

	-- Search box
	formspec[n] = "field_close_on_enter[searchbox;false]"
	n = n+1

	if not draw_lite_mode then
		formspec[n] = "field[9.5,8.325;3,1;searchbox;;"
			.. minetest.formspec_escape(unified_inventory.current_searchbox[player_name]) .. "]"
		formspec[n+1] = "image_button[12.2,8.1;.8,.8;ui_search_icon.png;searchbutton;]"
			.. "tooltip[searchbutton;" ..F("Search") .. "]"
		formspec[n+2] = "image_button[12.9,8.1;.8,.8;ui_reset_icon.png;searchresetbutton;]"
			.. "tooltip[searchbutton;" ..F("Search") .. "]"
			.. "tooltip[searchresetbutton;" ..F("Reset search and display everything") .. "]"
	else
		formspec[n] = "field[8.5,5.225;2.2,1;searchbox;;"
			.. minetest.formspec_escape(unified_inventory.current_searchbox[player_name]) .. "]"
		formspec[n+1] = "image_button[10.3,5;.8,.8;ui_search_icon.png;searchbutton;]"
			.. "tooltip[searchbutton;" ..F("Search") .. "]"
		formspec[n+2] = "image_button[11,5;.8,.8;ui_reset_icon.png;searchresetbutton;]"
			.. "tooltip[searchbutton;" ..F("Search") .. "]"
			.. "tooltip[searchresetbutton;" ..F("Reset search and display everything") .. "]"
	end
	n = n+3

	local no_matches = "No matching items"
	if draw_lite_mode then
		no_matches = "No matches."
	end

	-- Items list
	if #unified_inventory.filtered_items_list[player_name] == 0 then
		formspec[n] = "label[8.2,"..ui_peruser.form_header_y..";" .. F(no_matches) .. "]"
	else
		local dir = unified_inventory.active_search_direction[player_name]
		local list_index = unified_inventory.current_index[player_name]
		local page = math.floor(list_index / (ui_peruser.items_per_page) + 1)
		local pagemax = math.floor(
			(#unified_inventory.filtered_items_list[player_name] - 1)
				/ (ui_peruser.items_per_page) + 1)
		local item = {}
		for y = 0, ui_peruser.pagerows - 1 do
			for x = 0, ui_peruser.pagecols - 1 do
				local name = unified_inventory.filtered_items_list[player_name][list_index]
				if minetest.registered_items[name] then
					-- Clicked on current item: Flip crafting direction
					if name == unified_inventory.current_item[player_name] then
						local cdir = unified_inventory.current_craft_direction[player_name]
						if cdir == "recipe" then
							dir = "usage"
						elseif cdir == "usage" then
							dir = "recipe"
						end
					else
					-- Default: use active search direction by default
						dir = unified_inventory.active_search_direction[player_name]
					end
					formspec[n] = "item_image_button["
						..(8.2 + x * 0.7)..","
						..(ui_peruser.formspec_y + ui_peruser.page_y + y * 0.7)..";.81,.81;"
						..name..";item_button_"..dir.."_"
						..unified_inventory.mangle_for_formspec(name)..";]"
					n = n+1
					list_index = list_index + 1
				end
			end
		end
		formspec[n] = "label[8.2,"..ui_peruser.form_header_y..";"..F("Page") .. ": "
			.. S("%s of %s"):format(page,pagemax).."]"
	end
	n= n+1

	if unified_inventory.activefilter[player_name] ~= "" then
		formspec[n] = "label[8.2,"..(ui_peruser.form_header_y + 0.4)..";" .. F("Filter") .. ":]"
		formspec[n+1] = "label[9.1,"..(ui_peruser.form_header_y + 0.4)..";"..minetest.formspec_escape(unified_inventory.activefilter[player_name]).."]"
	end
	return table.concat(formspec, "")
end

function unified_inventory.set_inventory_formspec(player, page)
	if player then
		player:set_inventory_formspec(unified_inventory.get_formspec(player, page))
	end
end

--apply filter to the inventory list (create filtered copy of full one)
function unified_inventory.apply_filter(player, filter, search_dir)
	if not player then
		return false
	end
	local player_name = player:get_player_name()
	local lfilter = string.lower(filter)
	local ffilter
	if lfilter:sub(1, 6) == "group:" then
		local groups = lfilter:sub(7):split(",")
		ffilter = function(name, def)
			for _, group in ipairs(groups) do
				if not def.groups[group]
				or def.groups[group] <= 0 then
					return false
				end
			end
			return true
		end
	else
		ffilter = function(name, def)
			local lname = string.lower(name)
			local ldesc = string.lower(def.description)
			return string.find(lname, lfilter, 1, true) or string.find(ldesc, lfilter, 1, true)
		end
	end
	local is_creative = unified_inventory.is_creative(player_name)
	unified_inventory.filtered_items_list[player_name]={}
	for name, def in pairs(minetest.registered_items) do
		if (not def.groups.not_in_creative_inventory
			or def.groups.not_in_creative_inventory == 0)
		and def.description
		and def.description ~= ""
		and ffilter(name, def)
		and (is_creative or unified_inventory.crafts_for.recipe[def.name]) then
			table.insert(unified_inventory.filtered_items_list[player_name], name)
		end
	end
	table.sort(unified_inventory.filtered_items_list[player_name])
	unified_inventory.filtered_items_list_size[player_name] = #unified_inventory.filtered_items_list[player_name]
	unified_inventory.current_index[player_name] = 1
	unified_inventory.activefilter[player_name] = filter
	unified_inventory.active_search_direction[player_name] = search_dir
	unified_inventory.set_inventory_formspec(player,
	unified_inventory.current_page[player_name])
end

function unified_inventory.items_in_group(groups)
	local items = {}
	for name, item in pairs(minetest.registered_items) do
		for _, group in pairs(groups:split(',')) do
			if item.groups[group] then
				table.insert(items, name)
			end
		end
	end
	return items
end

function unified_inventory.sort_inventory(inv)
	local inlist = inv:get_list("main")
	local typecnt = {}
	local typekeys = {}
	for _, st in ipairs(inlist) do
		if not st:is_empty() then
			local n = st:get_name()
			local w = st:get_wear()
			local m = st:get_metadata()
			local k = string.format("%s %05d %s", n, w, m)
			if not typecnt[k] then
				typecnt[k] = {
					name = n,
					wear = w,
					metadata = m,
					stack_max = st:get_stack_max(),
					count = 0,
				}
				table.insert(typekeys, k)
			end
			typecnt[k].count = typecnt[k].count + st:get_count()
		end
	end
	table.sort(typekeys)
	local outlist = {}
	for _, k in ipairs(typekeys) do
		local tc = typecnt[k]
		while tc.count > 0 do
			local c = math.min(tc.count, tc.stack_max)
			table.insert(outlist, ItemStack({
				name = tc.name,
				wear = tc.wear,
				metadata = tc.metadata,
				count = c,
			}))
			tc.count = tc.count - c
		end
	end
	if #outlist > #inlist then return end
	while #outlist < #inlist do
		table.insert(outlist, ItemStack(nil))
	end
	inv:set_list("main", outlist)
end
