for name, def in pairs(minetest.registered_items) do
	for _,v in pairs(unified_inventory.item_hide_list) do
	  	if v == name then
			minetest.registered_items[name].groups.not_in_creative_inventory = 1
		end
	end
	
end
function unified_inventory.get_formspec(player, page)
	if not player then
		return ""
	end
	local player_name = player:get_player_name()
	unified_inventory.current_page[player_name] = page
	local pagedef = unified_inventory.pages[page]

	local formspec = "size[14,10]"
	local fsdata = nil

	-- Background
	formspec = formspec .. "background[-0.19,-0.25;14.4,10.75;ui_form_bg.png]"
	-- Current page
	if unified_inventory.pages[page] then
		fsdata = pagedef.get_formspec(player)
		formspec = formspec .. fsdata.formspec
	else
		return "" -- Invalid page name
	end

	-- Main buttons
	for i, def in pairs(unified_inventory.buttons) do
		if def.type == "image" then
			formspec = formspec.."image_button["
					..(0.65 * (i - 1))..",9;0.8,0.8;"
					..minetest.formspec_escape(def.image)..";"
					..minetest.formspec_escape(def.name)..";]"
		end
	end

	if fsdata.draw_inventory ~= false then
		-- Player inventory
		formspec = formspec.."listcolors[#00000000;#00000000]"
		formspec = formspec .. "list[current_player;main;0,4.5;8,4;]"
	end

	if fsdata.draw_item_list == false then
		return formspec
	end

	-- Controls to flip items pages
	local start_x = 9.2
	formspec = formspec .. "image_button["..(start_x + 0.6 * 0)..",9;.8,.8;ui_skip_backward_icon.png;start_list;]"
	formspec = formspec .. "image_button["..(start_x + 0.6 * 1)..",9;.8,.8;ui_doubleleft_icon.png;rewind3;]"
	formspec = formspec .. "image_button["..(start_x + 0.6 * 2)..",9;.8,.8;ui_left_icon.png;rewind1;]"
	formspec = formspec .. "image_button["..(start_x + 0.6 * 3)..",9;.8,.8;ui_right_icon.png;forward1;]"
	formspec = formspec .. "image_button["..(start_x + 0.6 * 4)..",9;.8,.8;ui_doubleright_icon.png;forward3;]"
	formspec = formspec .. "image_button["..(start_x + 0.6 * 5)..",9;.8,.8;ui_skip_forward_icon.png;end_list;]"

	-- Search box
	formspec = formspec .. "field[9.5,8.325;3,1;searchbox;;"..minetest.formspec_escape(unified_inventory.current_searchbox[player_name]).."]"
	formspec = formspec .. "image_button[12.2,8.1;.8,.8;ui_search_icon.png;searchbutton;]"

	-- Items list
	if #unified_inventory.filtered_items_list[player_name] == 0 then
		formspec = formspec.."label[8.2,0;No matching items]"
	else
		local list_index = unified_inventory.current_index[player_name]
		local page = math.floor(list_index / (80) + 1)
		local pagemax = math.floor(
			(#unified_inventory.filtered_items_list[player_name] - 1)
				/ (80) + 1)
		local item = {}
		for y = 0, 9 do
		for x = 0, 7 do
			local name = unified_inventory.filtered_items_list[player_name][list_index]
			if minetest.registered_items[name] then
				formspec = formspec.."item_image_button["
						..(8.2 + x * 0.7)..","
						..(1   + y * 0.7)..";.81,.81;"
						..name..";item_button_"
						..name..";]"
				list_index = list_index + 1
			end
		end
		end
		formspec = formspec.."label[8.2,0;Page:]"
		formspec = formspec.."label[9,0;"..page.." of "..pagemax.."]"
	end
	if unified_inventory.activefilter[player_name] ~= "" then
		formspec = formspec.."label[8.2,0.4;Filter:]"
		formspec = formspec.."label[9,0.4;"..minetest.formspec_escape(unified_inventory.activefilter[player_name]).."]"
	end
	return formspec
end

function unified_inventory.set_inventory_formspec(player, page)
	if player then
		local formspec = unified_inventory.get_formspec(player, page)
		player:set_inventory_formspec(formspec)
	end
end

--apply filter to the inventory list (create filtered copy of full one)
function unified_inventory.apply_filter(player, filter)
	local player_name = player:get_player_name()
	local lfilter = string.lower(filter)
	if not pcall(function() ("technic:test"):find(lfilter) end) then
		-- Filter is invalid
		lfilter = ""
	end
	local ffilter
	if lfilter:sub(1, 6) == "group:" then
		local groups = lfilter:sub(7):split(",")
		ffilter = function(name, def)
			for _, group in ipairs(groups) do
				if not ((def.groups[group] or 0) > 0) then
					return false
				end
			end
			return true
		end
	else
		ffilter = function(name, def)
			local lname = string.lower(name)
			local ldesc = string.lower(def.description)
			return string.find(lname, lfilter) or string.find(ldesc, lfilter)
		end
	end
	unified_inventory.filtered_items_list[player_name]={}
	for name, def in pairs(minetest.registered_items) do
		if (def.groups.not_in_creative_inventory or 0) == 0 and (def.description or "") ~= "" and ffilter(name, def) then
			table.insert(unified_inventory.filtered_items_list[player_name], name)
		end
	end
	table.sort(unified_inventory.filtered_items_list[player_name])
	unified_inventory.filtered_items_list_size[player_name] = #unified_inventory.filtered_items_list[player_name]
	unified_inventory.current_index[player_name] = 1
	unified_inventory.activefilter[player_name] = filter
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
