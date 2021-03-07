local S = minetest.get_translator("unified_inventory")
local F = minetest.formspec_escape

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
	ui.formspec_x = unified_inventory.formspec_x
	ui.formspec_y = unified_inventory.formspec_y
	ui.pagecols = unified_inventory.pagecols
	ui.pagerows = unified_inventory.pagerows
	ui.page_x = unified_inventory.page_x
	ui.page_y = unified_inventory.page_y
	ui.craft_x = unified_inventory.craft_x
	ui.craft_y = unified_inventory.craft_y
	ui.resultstr_y = unified_inventory.resultstr_y
	ui.give_btn_x = unified_inventory.give_btn_x
	ui.main_button_x = unified_inventory.main_button_x
	ui.main_button_y = unified_inventory.main_button_y
	ui.page_buttons_x = unified_inventory.page_buttons_x
	ui.page_buttons_y = unified_inventory.page_buttons_y
	ui.searchwidth = unified_inventory.searchwidth
	ui.form_header_x = unified_inventory.form_header_x
	ui.form_header_y = unified_inventory.form_header_y
	ui.btn_spc = unified_inventory.btn_spc
	ui.btn_size = unified_inventory.btn_size
	ui.std_inv_x = unified_inventory.std_inv_x
	ui.std_inv_y = unified_inventory.std_inv_y
	ui.standard_inv = unified_inventory.standard_inv
	ui.standard_inv_bg = unified_inventory.standard_inv_bg

	if lite then

		ui.formspec_x =  0.6
		ui.formspec_y =  0.6
		ui.pagecols = 4
		ui.pagerows = 6
		ui.page_x = 10.5
		ui.page_y = 1.25
		ui.craft_x = 2.6
		ui.craft_y = 0.75
		ui.resultstr_y = 0.35
		ui.give_btn_x = 0.15
		ui.main_button_x = ui.page_x
		ui.main_button_y = 7.9
		ui.page_buttons_x = ui.page_x
		ui.page_buttons_y = 6.3
		ui.searchwidth = 1.6
		ui.form_header_x =  0.2
		ui.form_header_y =  0.2
		ui.btn_spc = 0.8
		ui.btn_size = 0.7
		ui.std_inv_x = 0.1
		ui.std_inv_y = 4.6

	end

	ui.items_per_page = ui.pagecols * ui.pagerows
	ui.standard_inv =     string.format("list[current_player;main;%f,%f;8,4;]",
                                     ui.std_inv_x+0.15, ui.std_inv_y+0.15)

	ui.standard_inv_bg =  string.format("image[%f,%f;%f,%f;ui_main_inventory.png]",
                                     ui.std_inv_x, ui.std_inv_y,
                                     unified_inventory.imgscale*8, unified_inventory.imgscale*4)
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

	if not pagedef then
		return "" -- Invalid page name
	end

	local formspec = {
		"formspec_version[4]size[17.75,12.25]",
		pagedef.formspec_prepend and "" or "no_prepend[]",
		unified_inventory.standard_background -- Background
	}
	local n = 4

	if draw_lite_mode then
		formspec[1] = "formspec_version[4]size[14,9.75]"
		formspec[3] = unified_inventory.standard_background
	end

	if unified_inventory.is_creative(player_name)
	and page == "craft" then -- add the "Refill" slot.
		formspec[n] = "image["..(ui_peruser.craft_x-2.5)..","..(ui_peruser.craft_y+2.5)..";"..unified_inventory.imgscale..","..unified_inventory.imgscale..";ui_single_slot.png]"
		n = n+1
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
				formspec[n+1] = ( ui_peruser.main_button_x + ui_peruser.btn_spc * (i - 1) - button_col * ui_peruser.btn_spc * 4)
				formspec[n+2] = ","..(ui_peruser.main_button_y + button_row * ui_peruser.btn_spc)..";"..ui_peruser.btn_size..","..ui_peruser.btn_size..";"
				formspec[n+3] = F(def.image)..";"
				formspec[n+4] = F(def.name)..";]"
				formspec[n+5] = "tooltip["..F(def.name)
				formspec[n+6] = ";"..(def.tooltip or "").."]"
				n = n+7
			else
				formspec[n] = "image["
				formspec[n+1] = ( ui_peruser.main_button_x + ui_peruser.btn_spc * (i - 1) - button_col * ui_peruser.btn_spc * 4)
				formspec[n+2] = ","..(ui_peruser.main_button_y + button_row * ui_peruser.btn_spc)..";"..ui_peruser.btn_size..","..ui_peruser.btn_size..";"
				formspec[n+3] = F(def.image).."^[colorize:#808080:alpha]"
				n = n+4

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

	formspec[n+1] = "field["..ui_peruser.page_buttons_x..","..
		ui_peruser.page_buttons_y..";"..
		(ui_peruser.searchwidth - 0.1)..","..
		ui_peruser.btn_size..";searchbox;;"..
		F(unified_inventory.current_searchbox[player_name]) .. "]"
	formspec[n+2] = "image_button["..(ui_peruser.page_buttons_x + ui_peruser.searchwidth)..","..
		ui_peruser.page_buttons_y..";"..
		ui_peruser.btn_size..","..ui_peruser.btn_size..
		";ui_search_icon.png;searchbutton;]"..
		"tooltip[searchbutton;" ..F(S("Search")) .. "]"
	formspec[n+3] = "image_button["..(ui_peruser.page_buttons_x + ui_peruser.searchwidth + ui_peruser.btn_spc)..","..
		ui_peruser.page_buttons_y..";"..
		ui_peruser.btn_size..","..ui_peruser.btn_size..
		";ui_reset_icon.png;searchresetbutton;]"..
		"tooltip[searchresetbutton;" ..F(S("Reset search and display everything")) .. "]"

	n = n + 4

	-- Controls to flip items pages

	local btnlist = {
		{ "ui_skip_backward_icon.png", "start_list", "First page" },
		{ "ui_doubleleft_icon.png",    "rewind3",    "Back three pages" },
		{ "ui_left_icon.png",          "rewind1",    "Back one page" },
		{ "ui_right_icon.png",         "forward1",   "Forward one page" },
		{ "ui_doubleright_icon.png",   "forward3",   "Forward three pages" },
		{ "ui_skip_forward_icon.png",  "end_list",   "Last page" },
	}

	if draw_lite_mode then
		btnlist[5] = nil
		btnlist[2] = nil
	end

	local bn = 0
	for _, b in pairs(btnlist) do
		formspec[n] =  "image_button["..
			(ui_peruser.page_buttons_x + ui_peruser.btn_spc*bn)..","..
			(ui_peruser.page_buttons_y + ui_peruser.btn_spc)..";"..
			ui_peruser.btn_size..","..
			ui_peruser.btn_size..";"..
			b[1]..";"..b[2]..";]"..
			"tooltip["..b[2]..";"..F(S(b[3])).."]"
		bn = bn + 1
		n = n + 1
	end

	local no_matches = S("No matching items")
	if draw_lite_mode then
		no_matches = S("No matches.")
	end

	-- Items list
	if #unified_inventory.filtered_items_list[player_name] == 0 then
		formspec[n] = "label["..ui_peruser.page_x..","..(ui_peruser.page_y+0.15)..";" .. F(no_matches) .. "]"
	else
		local dir = unified_inventory.active_search_direction[player_name]
		local list_index = unified_inventory.current_index[player_name]
		local page2 = math.floor(list_index / (ui_peruser.items_per_page) + 1)
		local pagemax = math.floor(
			(#unified_inventory.filtered_items_list[player_name] - 1)
				/ (ui_peruser.items_per_page) + 1)
		for y = 0, ui_peruser.pagerows - 1 do
			for x = 0, ui_peruser.pagecols - 1 do
				local name = unified_inventory.filtered_items_list[player_name][list_index]
				local item = minetest.registered_items[name]
				if item then
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

					local button_name = "item_button_" .. dir .. "_"
						.. unified_inventory.mangle_for_formspec(name)
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
		formspec[n] = "label["..ui_peruser.page_x..","..ui_peruser.form_header_y..";"..F(S("Page")) .. ": "
			.. S("@1 of @2",page2,pagemax).."]"
	end
	n= n+1

	if unified_inventory.activefilter[player_name] ~= "" then
		formspec[n] = "label["..ui_peruser.page_x..","..(ui_peruser.page_y - 0.65)..";" .. F(S("Filter")) .. ":]"
		formspec[n+1] = "label["..ui_peruser.page_x..","..(ui_peruser.page_y - 0.25)..";"..F(unified_inventory.activefilter[player_name]).."]"
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
	unified_inventory.filtered_items_list[player_name]={}
	for name, def in pairs(minetest.registered_items) do
		if (not def.groups.not_in_creative_inventory
			or def.groups.not_in_creative_inventory == 0)
		and def.description
		and def.description ~= ""
		and ffilter(name, def) then
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
