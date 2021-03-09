local S = minetest.get_translator("unified_inventory")
local F = minetest.formspec_escape
local ui = unified_inventory

-- This pair of encoding functions is used where variable text must go in
-- button names, where the text might contain formspec metacharacters.
-- We can escape button names for the formspec, to avoid screwing up
-- form structure overall, but they then don't get de-escaped, and so
-- the input we get back from the button contains the formspec escaping.
-- This is a game engine bug, and in the anticipation that it might be
-- fixed some day we don't want to rely on it.  So for safety we apply
-- an encoding that avoids all formspec metacharacters.

function ui.mangle_for_formspec(str)
	return string.gsub(str, "([^A-Za-z0-9])", function (c) return string.format("_%d_", string.byte(c)) end)
end
function ui.demangle_for_formspec(str)
	return string.gsub(str, "_([0-9]+)_", function (v) return string.char(v) end)
end


function ui.get_per_player_formspec(player_name)
	local draw_lite_mode = ui.lite_mode and not minetest.check_player_privs(player_name, {ui_full=true})

	return table.copy(draw_lite_mode and ui.style_lite or ui.style_full), draw_lite_mode
end

function ui.get_formspec(player, page)

	if not player then
		return ""
	end

	local player_name = player:get_player_name()
	local ui_peruser,draw_lite_mode = ui.get_per_player_formspec(player_name)

	ui.current_page[player_name] = page
	local pagedef = ui.pages[page]

	if not pagedef then
		return "" -- Invalid page name
	end

	local formspec = {
		"formspec_version[4]size[17.75,12.25]",
		pagedef.formspec_prepend and "" or "no_prepend[]",
		ui.standard_background -- Background
	}
	local n = 4

	if draw_lite_mode then
		formspec[1] = "formspec_version[4]size[14,9.75]"
		formspec[3] = ui.standard_background
	end

	local perplayer_formspec = ui.get_per_player_formspec(player_name)
	local fsdata = pagedef.get_formspec(player, perplayer_formspec)

	formspec[n] = fsdata.formspec
	n = n+1

	local button_row = 0
	local button_col = 0

	-- Main buttons

	local filtered_inv_buttons = {}

	for i, def in pairs(ui.buttons) do
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
				formspec[n] = string.format("image_button[%f,%f;%f,%f;%s;%s;]",
					ui_peruser.main_button_x + ui_peruser.btn_spc * (i - 1) - button_col * ui_peruser.btn_spc * 4,
					ui_peruser.main_button_y + button_row * ui_peruser.btn_spc,
					ui_peruser.btn_size,ui_peruser.btn_size,
					F(def.image),
					F(def.name))
				formspec[n+1] = "tooltip["..F(def.name)..";"..(def.tooltip or "").."]"
				n = n+2
			else
				formspec[n] = string.format("image[%f,%f;%f,%f;%s^[colorize:#808080:alpha]",
				ui_peruser.main_button_x + ui_peruser.btn_spc * (i - 1) - button_col * ui_peruser.btn_spc * 4,
				ui_peruser.main_button_y + button_row * ui_peruser.btn_spc,
				ui_peruser.btn_size,ui_peruser.btn_size,def.image)
				n = n+1
			end
		end
	end

	if fsdata.draw_inventory ~= false then
		-- Player inventory
		formspec[n] = "listcolors[#00000000;#00000000]"
		formspec[n+1] = ui_peruser.standard_inv
		n = n+2
	end

	if fsdata.draw_item_list == false then
		return table.concat(formspec, "")
	end

	-- Search box
	formspec[n] = "field_close_on_enter[searchbox;false]"

	formspec[n+1] = string.format("field[%f,%f;%f,%f;searchbox;;%s]",
		ui_peruser.page_buttons_x, ui_peruser.page_buttons_y,
		ui_peruser.searchwidth - 0.1, ui_peruser.btn_size,
		F(ui.current_searchbox[player_name]))
	formspec[n+2] = string.format("image_button[%f,%f;%f,%f;ui_search_icon.png;searchbutton;]",
		ui_peruser.page_buttons_x + ui_peruser.searchwidth, ui_peruser.page_buttons_y,
		ui_peruser.btn_size,ui_peruser.btn_size)
	formspec[n+3] = "tooltip[searchbutton;" ..F(S("Search")) .. "]"
	formspec[n+4] = string.format("image_button[%f,%f;%f,%f;ui_reset_icon.png;searchresetbutton;]",
		ui_peruser.page_buttons_x + ui_peruser.searchwidth + ui_peruser.btn_spc,
		ui_peruser.page_buttons_y,
		ui_peruser.btn_size, ui_peruser.btn_size)
	formspec[n+5] = "tooltip[searchresetbutton;"..F(S("Reset search and display everything")).."]"

	n = n + 6

	-- Controls to flip items pages

	local btnlist = {
		{ "ui_skip_backward_icon.png", "start_list", S("First page") },
		{ "ui_doubleleft_icon.png",    "rewind3",    S("Back three pages") },
		{ "ui_left_icon.png",          "rewind1",    S("Back one page") },
		{ "ui_right_icon.png",         "forward1",   S("Forward one page") },
		{ "ui_doubleright_icon.png",   "forward3",   S("Forward three pages") },
		{ "ui_skip_forward_icon.png",  "end_list",   S("Last page") },
	}

	if draw_lite_mode then
		btnlist[5] = nil
		btnlist[2] = nil
	end

	local bn = 0
	for _, b in pairs(btnlist) do
		formspec[n] =  string.format("image_button[%f,%f;%f,%f;%s;%s;]",
			ui_peruser.page_buttons_x + ui_peruser.btn_spc*bn,
			ui_peruser.page_buttons_y + ui_peruser.btn_spc,
			ui_peruser.btn_size, ui_peruser.btn_size,
			b[1],b[2])
		formspec[n+1] = "tooltip["..b[2]..";"..F(b[3]).."]"
		bn = bn + 1
		n = n + 2
	end

	local no_matches = S("No matching items")
	if draw_lite_mode then
		no_matches = S("No matches.")
	end

	-- Items list
	if #ui.filtered_items_list[player_name] == 0 then
		formspec[n] = "label["..ui_peruser.page_x..","..(ui_peruser.page_y+0.15)..";" .. F(no_matches) .. "]"
	else
		local dir = ui.active_search_direction[player_name]
		local list_index = ui.current_index[player_name]
		local page2 = math.floor(list_index / (ui_peruser.items_per_page) + 1)
		local pagemax = math.floor(
			(#ui.filtered_items_list[player_name] - 1)
				/ (ui_peruser.items_per_page) + 1)
		for y = 0, ui_peruser.pagerows - 1 do
			for x = 0, ui_peruser.pagecols - 1 do
				local name = ui.filtered_items_list[player_name][list_index]
				local item = minetest.registered_items[name]
				if item then
					-- Clicked on current item: Flip crafting direction
					if name == ui.current_item[player_name] then
						local cdir = ui.current_craft_direction[player_name]
						if cdir == "recipe" then
							dir = "usage"
						elseif cdir == "usage" then
							dir = "recipe"
						end
					else
					-- Default: use active search direction by default
						dir = ui.active_search_direction[player_name]
					end

					local button_name = "item_button_" .. dir .. "_"
						.. ui.mangle_for_formspec(name)
					formspec[n] = ("item_image_button[%f,%f;%f,%f;%s;%s;]"):format(
						ui_peruser.page_x + x * ui_peruser.btn_spc,
						ui_peruser.page_y + y * ui_peruser.btn_spc,
						ui_peruser.btn_size, ui_peruser.btn_size,
						name, button_name
					)
					formspec[n + 1] = ("tooltip[%s;%s \\[%s\\]]"):format(
						button_name, minetest.formspec_escape(item.description),
						item.mod_origin or "??"
					)
					n = n + 2
					list_index = list_index + 1
				end
			end
		end
		formspec[n] = string.format("label[%f,%f;%s: %s]",
			ui_peruser.page_x, ui_peruser.form_header_y,
			F(S("Page")), S("@1 of @2",page2,pagemax))
	end
	n= n+1

	if ui.activefilter[player_name] ~= "" then
		formspec[n] = string.format("label[%f,%f;%s:]",
			ui_peruser.page_x, ui_peruser.page_y - 0.65, F(S("Filter")))
		formspec[n+1] = string.format("label[%f,%f;%s]",
			ui_peruser.page_x, ui_peruser.page_y - 0.25, F(ui.activefilter[player_name]))
	end
	return table.concat(formspec, "")
end

function ui.set_inventory_formspec(player, page)
	if player then
		player:set_inventory_formspec(ui.get_formspec(player, page))
	end
end

--apply filter to the inventory list (create filtered copy of full one)
function ui.apply_filter(player, filter, search_dir)
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
		local lang = minetest.get_player_information(player_name).lang_code
		ffilter = function(name, def)
			local lname = string.lower(name)
			local ldesc = string.lower(def.description)
			local llocaldesc = minetest.get_translated_string
				and string.lower(minetest.get_translated_string(lang, def.description))
			return string.find(lname, lfilter, 1, true) or string.find(ldesc, lfilter, 1, true)
				or llocaldesc and string.find(llocaldesc, lfilter, 1, true)
		end
	end
	ui.filtered_items_list[player_name]={}
	for name, def in pairs(minetest.registered_items) do
		if (not def.groups.not_in_creative_inventory
			or def.groups.not_in_creative_inventory == 0)
		and def.description
		and def.description ~= ""
		and ffilter(name, def) then
			table.insert(ui.filtered_items_list[player_name], name)
		end
	end
	table.sort(ui.filtered_items_list[player_name])
	ui.filtered_items_list_size[player_name] = #ui.filtered_items_list[player_name]
	ui.current_index[player_name] = 1
	ui.activefilter[player_name] = filter
	ui.active_search_direction[player_name] = search_dir
	ui.set_inventory_formspec(player,
	ui.current_page[player_name])
end

function ui.items_in_group(groups)
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

function ui.sort_inventory(inv)
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
