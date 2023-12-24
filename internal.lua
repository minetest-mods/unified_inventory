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

-- Get the player-specific unified_inventory style
function ui.get_per_player_formspec(player_name)
	local draw_lite_mode = ui.lite_mode and not minetest.check_player_privs(player_name, {ui_full=true})

	local style = table.copy(draw_lite_mode and ui.style_lite or ui.style_full)
	style.is_lite_mode = draw_lite_mode
	return style
end

-- Creates an item image or regular image button with a tooltip
local function formspec_button(ui_peruser, name, image, offset, pos, scale, label)
	local element = 'image_button'
	if minetest.registered_items[image] then
		element = 'item_image_button'
	elseif image:find(":", 1, true) then
		image = "unknown_item.png"
	end
	local spc = (1-scale)*ui_peruser.btn_size/2
	local size = ui_peruser.btn_size*scale
	return string.format("%s[%f,%f;%f,%f;%s;%s;]", element,
		(offset.x or offset[1]) + ( ui_peruser.btn_spc * (pos.x or pos[1]) ) + spc,
		(offset.y or offset[2]) + ( ui_peruser.btn_spc * (pos.y or pos[2]) ) + spc,
		size, size, image, name) ..
		string.format("tooltip[%s;%s]", name, F(label or name))
end

-- Add registered buttons (tabs)
local function formspec_tab_buttons(player, formspec, style)
	local n = #formspec + 1

	-- Main buttons

	local filtered_inv_buttons = {}

	for _, def in pairs(ui.buttons) do
		if not (style.is_lite_mode and def.hide_lite) then
			if def.condition == nil or def.condition(player) or not ui.hide_disabled_buttons then
				table.insert(filtered_inv_buttons, def)
			end
		end
	end

	local needs_scrollbar = #filtered_inv_buttons > style.main_button_cols * style.main_button_rows

	formspec[n] = ("scroll_container[%g,%g;%g,%g;tabbtnscroll;vertical]"):format(
		style.main_button_x, style.main_button_y, -- position
		style.main_button_cols * style.btn_spc, style.main_button_rows -- size
	)
	n = n + 1

	for i, def in pairs(filtered_inv_buttons) do
		local pos_x =           ((i - 1) % style.main_button_cols) * style.btn_spc
		local pos_y = math.floor((i - 1) / style.main_button_cols) * style.btn_spc

		if def.type == "image" then
			if (def.condition == nil or def.condition(player)) then
				formspec[n] = string.format("image_button[%g,%g;%g,%g;%s;%s;]",
					pos_x, pos_y, style.btn_size, style.btn_size,
					F(def.image),
					F(def.name))
				formspec[n+1] = "tooltip["..F(def.name)..";"..(def.tooltip or "").."]"
				n = n+2

			else
				formspec[n] = string.format("image[%g,%g;%g,%g;%s^[colorize:#808080:alpha]",
					pos_x, pos_y, style.btn_size, style.btn_size,
					def.image)
				n = n+1
			end
		end
	end
	formspec[n] = "scroll_container_end[]"
	if needs_scrollbar then
		local total_rows = math.ceil(#filtered_inv_buttons / style.main_button_cols)
		formspec[n+1] = ("scrollbaroptions[max=%i;arrows=hide]"):format(
			-- This calculation is not 100% accurate but "good enough"
			(total_rows - style.main_button_rows) * style.btn_spc * 10
		)
		formspec[n+2] = ("scrollbar[%g,%g;0.4,%g;vertical;tabbtnscroll;0]"):format(
			style.main_button_x + style.main_button_cols * style.btn_spc - 0.1, -- x pos
			style.main_button_y, -- y pos
			style.main_button_rows * style.btn_spc -- height
		)
		formspec[n+3] = "scrollbaroptions[max=1000;arrows=default]"
	end
end

-- Add category GUI elements (top right)
local function formspec_add_categories(player, formspec, ui_peruser)
	local player_name = player:get_player_name()
	local n = #formspec + 1

	local categories_pos = {
		ui_peruser.page_x,
		ui_peruser.page_y-ui_peruser.btn_spc-0.5
	}
	local categories_scroll_pos = {
		ui_peruser.page_x,
		ui_peruser.form_header_y - (ui_peruser.is_lite_mode and 0 or 0.2)
	}

	formspec[n] = string.format("background9[%f,%f;%f,%f;%s;false;16]",
		ui_peruser.page_x-0.15, categories_scroll_pos[2],
		(ui_peruser.btn_spc * ui_peruser.pagecols) + 0.2, 1.4 + (ui_peruser.is_lite_mode and 0 or 0.2),
		"ui_smallbg_9_sliced.png")
	n = n + 1

	formspec[n] = string.format("label[%f,%f;%s]",
		ui_peruser.page_x,
		ui_peruser.form_header_y + (ui_peruser.is_lite_mode and 0.3 or 0.2), F(S("Category:")))
	n = n + 1

	local scroll_offset = 0
	local category_count = #ui.category_list
	if category_count > ui_peruser.pagecols then
		scroll_offset = ui.current_category_scroll[player_name]
	end

	for index, category in ipairs(ui.category_list) do
		local column = index - scroll_offset
		if column > 0 and column <= ui_peruser.pagecols then
			local scale = 0.8
			if ui.current_category[player_name] == category.name then
				scale = 1
			end
			formspec[n] = formspec_button(ui_peruser, "category_"..category.name, category.symbol, categories_pos, {column-1, 0}, scale, category.label)
			n = n + 1
		end
	end
	if category_count > ui_peruser.pagecols and scroll_offset > 0 then
		-- prev
		formspec[n] = formspec_button(ui_peruser, "prev_category", "ui_left_icon.png", categories_scroll_pos, {ui_peruser.pagecols - 2, 0}, 0.8, S("Scroll categories left"))
		n = n + 1
	end
	if category_count > ui_peruser.pagecols and category_count - scroll_offset > ui_peruser.pagecols then
		-- next
		formspec[n] = formspec_button(ui_peruser, "next_category", "ui_right_icon.png", categories_scroll_pos, {ui_peruser.pagecols - 1, 0}, 0.8, S("Scroll categories right"))
	end
end

local function formspec_add_search_box(player, formspec, ui_peruser)
	local player_name = player:get_player_name()
	local n = #formspec + 1

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

	if ui.activefilter[player_name] ~= "" then
		formspec[n+6] = string.format("label[%f,%f;%s: %s]",
			ui_peruser.page_x, ui_peruser.page_y - 0.25,
			F(S("Filter")), F(ui.activefilter[player_name]))
	end
end

local function formspec_add_item_browser(player, formspec, ui_peruser)
	local player_name = player:get_player_name()
	local n = #formspec + 1

	-- Controls to flip items pages

	local btnlist = {
		{ "ui_skip_backward_icon.png", "start_list", S("First page") },
		{ "ui_doubleleft_icon.png",    "rewind3",    S("Back three pages") },
		{ "ui_left_icon.png",          "rewind1",    S("Back one page") },
		{ "ui_right_icon.png",         "forward1",   S("Forward one page") },
		{ "ui_doubleright_icon.png",   "forward3",   S("Forward three pages") },
		{ "ui_skip_forward_icon.png",  "end_list",   S("Last page") },
	}

	if ui_peruser.is_lite_mode then
		btnlist[2] = nil
		btnlist[5] = nil
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

	-- Items list
	if #ui.filtered_items_list[player_name] == 0 then
		local no_matches = S("No matching items")
		if ui_peruser.is_lite_mode then
			no_matches = S("No matches.")
		end

		formspec[n] = "label["..ui_peruser.page_x..","..(ui_peruser.page_y+0.15)..";" .. F(no_matches) .. "]"
		return
	end

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
				local tooltip = item.description
				if item.mod_origin then
					-- "mod_origin" may not be specified for items that were
					-- registered in a callback (during or before ServerEnv init)
					tooltip = tooltip .. " [" .. item.mod_origin .. "]"
				end
				formspec[n + 1] = ("tooltip[%s;%s]"):format(
					button_name, minetest.formspec_escape(tooltip)
				)
				n = n + 2
			end
			list_index = list_index + 1
		end
	end
	formspec[n] = "style[page_number;content_offset=0]"
	formspec[n + 1] = string.format("image_button[%f,%f;%f,0.4;;page_number;%s: %s;false;false;]",
		ui_peruser.page_buttons_x,
		ui_peruser.page_buttons_y + ui_peruser.btn_spc * 2 - 0.1,
		ui_peruser.btn_spc * (bn - 1) + ui_peruser.btn_size,
		F(S("Page")), S("@1 of @2",page2,pagemax))
end

function ui.get_formspec(player, page)

	if not player then
		return ""
	end

	local player_name = player:get_player_name()
	local ui_peruser = ui.get_per_player_formspec(player_name)

	ui.current_page[player_name] = page
	local pagedef = ui.pages[page]

	if not pagedef then
		return "" -- Invalid page name
	end

	local fs = {
		"formspec_version[4]",
		"size["..ui_peruser.formw..","..ui_peruser.formh.."]",
		pagedef.formspec_prepend and "" or "no_prepend[]",
		ui.standard_background
	}

	local perplayer_formspec = ui.get_per_player_formspec(player_name)
	local fsdata = pagedef.get_formspec(player, perplayer_formspec)

	fs[#fs + 1] = fsdata.formspec

	formspec_tab_buttons(player, fs, ui_peruser)

	if fsdata.draw_inventory ~= false then
		-- Player inventory
		fs[#fs + 1] = "listcolors[#00000000;#00000000]"
		fs[#fs + 1] = ui_peruser.standard_inv
	end

	if fsdata.draw_item_list == false then
		return table.concat(fs, "")
	end

	formspec_add_categories(player, fs, ui_peruser)
	formspec_add_search_box(player, fs, ui_peruser)
	formspec_add_item_browser(player, fs, ui_peruser)

	return table.concat(fs)
end

function ui.set_inventory_formspec(player, page)
	if player then
		player:set_inventory_formspec(ui.get_formspec(player, page))
	end
end

function ui.is_itemdef_listable(def)
	return (not def.groups.not_in_creative_inventory
			or def.groups.not_in_creative_inventory == 0)
		and def.description
		and def.description ~= ""
end

--apply filter to the inventory list (create filtered copy of full one)
function ui.apply_filter(player, filter, search_dir)
	if not player then
		return false
	end
	local player_name = player:get_player_name()

	-- Whether to show uncraftable items
	local fprefilter = function(_)
		return true
	end
	if ui.hide_uncraftable_items and not ui.is_creative(player_name) then
		fprefilter = function(name)
			return ui.get_recipe_list(name)
		end
	end

	local registered_items = minetest.registered_items
	local lfilter = string.lower(filter)
	local ffilter

	if lfilter:sub(1, 6) == "group:" then
		-- Group filter: all groups of the item must match
		local groups = lfilter:sub(7):split(",")
		ffilter = function(name)
			local def = registered_items[name]
			for _, group in ipairs(groups) do
				if not def.groups[group]
				or def.groups[group] <= 0 then
					return false
				end
			end
			return true
		end
	else
		-- Name filter: fuzzy match item names and descriptions
		local player_info = minetest.get_player_information(player_name)
		local lang = player_info and player_info.lang_code or ""

		ffilter = function(name)
			local def = registered_items[name]
			local lname = string.lower(name)
			local ldesc = string.lower(def.description)
			local llocaldesc = minetest.get_translated_string
				and string.lower(minetest.get_translated_string(lang, def.description))
			return string.find(lname, lfilter, 1, true) or string.find(ldesc, lfilter, 1, true)
				or llocaldesc and string.find(llocaldesc, lfilter, 1, true)
		end
	end

	local filtered_items = {}

	local category = ui.current_category[player_name] or 'all'
	if category == 'all' then
		for _, name in ipairs(ui.items_list) do
			if fprefilter(name) and ffilter(name) then
				table.insert(filtered_items, name)
			end
		end
	elseif category == 'uncategorized' then
		for _, name in ipairs(ui.items_list) do
			if not ui.find_category(name)
					and fprefilter(name)
					and ffilter(name) then
				table.insert(filtered_items, name)
			end
		end
	else
		-- Any other category is selected
		for name, exists in pairs(ui.registered_category_items[category]) do
			if exists
					and fprefilter(name)
					and ffilter(name) then
				table.insert(filtered_items, name)
			end
		end
	end
	table.sort(filtered_items)

	ui.filtered_items_list_size[player_name] = #filtered_items
	ui.filtered_items_list[player_name] = filtered_items
	ui.current_index[player_name] = 1
	ui.activefilter[player_name] = filter
	ui.active_search_direction[player_name] = search_dir
	ui.set_inventory_formspec(player, ui.current_page[player_name])
end

-- Inform players about potential visual issues
minetest.register_on_joinplayer(function(player)
	local player_name = player:get_player_name()
	local info = minetest.get_player_information(player_name)
	if info and (info.formspec_version or 0) < 4 then
		minetest.chat_send_player(player_name, S("Unified Inventory: Your game version is too old"
			.. " and does not support the GUI requirements. You might experience visual issues."))
	end
end)
