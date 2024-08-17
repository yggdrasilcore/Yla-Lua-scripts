local NPC_ID = 190089
local CURRENCY_ID = 37742
local CURRENCY_NAME = "Transmog Token"
local ItemCache = {} 
local itemsPerPage = 10
local currentSearchTerm = " " 

local slotTypes = {
	[10000] = {name = "Head", inventoryType = 1},
	[11000] = {name = "Shoulder", inventoryType = 3},
	[12000] = {name = "Shirt", inventoryType = 4},
	[13000] = {name = "Waist", inventoryType = 6},
	[14000] = {name = "Legs", inventoryType = 7},
	[15000] = {name = "Feet", inventoryType = 8},
	[16000] = {name = "Wrists", inventoryType = 9},
	[18000] = {name = "Hands", inventoryType = 10},
	[19000] = {name = "Back", inventoryType = 16},
	[20000] = {name = "Weapon", inventoryType = {13, 17, 21, 22, 26}},
	[21000] = {name = "Off-hand", inventoryType = {22, 23}},
	[22000] = {name = "Shield", inventoryType = 14},
	[23000] = {name = "Ranged", inventoryType = {15, 26}}
}

function ItemCache.LoadCache()
	ItemCache["Cache"] = {}
	local i = 1
	local Query
	
	Query = WorldDBQuery("SELECT entry, class, name, subclass, InventoryType, RequiredLevel, Quality, maxcount FROM item_template WHERE ((InventoryType>0 AND InventoryType NOT IN (28, 27, 24, 18, 19, 12) AND ItemLevel < 200) OR (Name LIKE '%frostmourne%' AND ItemLevel < 201)) AND name NOT LIKE '%deprecated%' AND Quality != 7 AND name NOT LIKE '%Sword2H, Corrupted%' AND name NOT LIKE '%Tigole%' ORDER BY Name ASC;")
	if Query then
		repeat
			local name = Query:GetString(2)
			local inventoryType = Query:GetUInt32(4)
			local quality = Query:GetUInt32(6)
			local maxcount = Query:GetUInt32(7)
			if not (name:find("%(") or name:find("%)") or 
					name:find("%[") or name:find("%]") or 
					name:lower():find("unused") or name:lower():find("test")) then
				ItemCache["Cache"][i] = {
					entry = Query:GetUInt32(0),
					class = Query:GetUInt32(1),
					name = name,
					subclass = Query:GetUInt32(3),
					InventoryType = inventoryType,
					level = Query:GetUInt32(5),
					quality = quality,
					maxcount = maxcount
				}
				i = i + 1
			end
		until not Query:NextRow()
		table.sort(ItemCache["Cache"], function(a, b)
			return a.name < b.name
		end)
		print("[Eluna Item Vendor]: Item name cache initialized. Loaded ".. (i-1) .." items.")
	end
end

local function GetItemsByClassAndSubclass(class, subclass)
	local items = {}
	for _, item in pairs(ItemCache["Cache"]) do
		if item.class == class and item.subclass == subclass then
			table.insert(items, item)
		end
	end
	return items
end

local function PlayerHasEnoughFreeSlots(player, requiredSlots)
	local freeSlots = 0

	for slot = 23, 38 do
		local item = player:GetItemByPos(255, slot)
		if not item then
			freeSlots = freeSlots + 1
		end
	end

	for bag = 19, 22 do
		local bagItem = player:GetItemByPos(255, bag)
		if bagItem then
			local bagSize = bagItem:GetBagSize()
			for slot = 0, bagSize - 1 do
				local item = player:GetItemByPos(bag, slot)
				if not item then
					freeSlots = freeSlots + 1
				end
			end
		end
	end

	print("Total free slots found: " .. freeSlots)
	return freeSlots >= requiredSlots
end

local function PlayerHasEnoughCurrency(player, cost)
	local playerCurrency = player:GetItemCount(CURRENCY_ID)
	return playerCurrency >= cost
end

function ItemCache.GenerateSearchMenu(player, object, currentPage)
	local searchTerm = currentSearchTerm or " "
	
	local results = {}
	for _, item in ipairs(ItemCache["Cache"]) do
		if item.name:lower():find(searchTerm) then
			table.insert(results, item)
		end
	end
	
	local low = (itemsPerPage * (currentPage - 1)) + 1
	local high = math.min(itemsPerPage * currentPage, #results)
	
	player:GossipClearMenu()
	player:GossipMenuAddItem(4, "Back to main menu", 0, 0)
	for i = low, high do
		local item = results[i]
		if item then
			player:GossipMenuAddItem(1, item.name, 0, 2000000 + item.entry)
		end
	end
	
	if currentPage > 1 then
		player:GossipMenuAddItem(4, "Previous page", 9000000 + currentPage, 9000000 + currentPage - 1)
	end
	
	if high < #results then
		player:GossipMenuAddItem(4, "Next page", 9000000 + currentPage, 9000000 + currentPage + 1)
	end
	
   player:GossipMenuAddItem(0, "Current search: " .. currentSearchTerm, 0, 9000000 + currentPage)
	player:GossipSendMenu(1, object)
end

local function ArmorTypeFilter(class, subclass)
	local filteredItems = {}
	for _, item in pairs(ItemCache["Cache"]) do
		if item.class == class and item.subclass == subclass then
			table.insert(filteredItems, item)
		end
	end
	return filteredItems
end

local function SlotTypeFilter(inventoryType)
	local filteredItems = {}
	local itemCount = 0
	local matchingItems = 0

	for _, item in pairs(ItemCache["Cache"]) do
		itemCount = itemCount + 1
		 if type(inventoryType) == "table" then
			for _, invType in ipairs(inventoryType) do
				if item.InventoryType == invType then
					table.insert(filteredItems, item)
					matchingItems = matchingItems + 1
					break
				end
			end
		elseif item.InventoryType == inventoryType then
			table.insert(filteredItems, item)
			matchingItems = matchingItems + 1
		end
	end
	
	if itemCount == 0 then
		print("Warning: ItemCache['Cache'] is empty!")
	elseif matchingItems == 0 then
		print("Warning: No items match the specified inventoryType: " .. tostring(inventoryType))
	end

	return filteredItems
end

function DisplayArmorItems(player, object, items, currentIntid)
	local itemsPerPage = 10
	local baseIntid = math.floor(currentIntid / 100) * 100
	local page = (currentIntid - baseIntid) + 1
	
	if items and #items > 0 then
		local totalPages = math.ceil(#items / itemsPerPage)
		player:GossipClearMenu()
		local startIndex = (page - 1) * itemsPerPage + 1
		local endIndex = math.min(page * itemsPerPage, #items)
		for i = startIndex, endIndex do
			local item = items[i]
			if item and item.name and item.entry then
				player:GossipMenuAddItem(1, item.name, 0, 2000000 + item.entry)
			end
		end
		-- Add pagination options
		if page > 1 then
			player:GossipMenuAddItem(7, "Previous Page", 0, baseIntid + page - 2)
		end
		if page < totalPages then
			player:GossipMenuAddItem(7, "Next Page", 0, baseIntid + page)
		end
		player:GossipMenuAddItem(4, "Back", 0, 200)
		player:GossipSendMenu(1, object)
	else
		player:GossipClearMenu()
		player:GossipMenuAddItem(0, "No items found.", 0, 0)
		player:GossipMenuAddItem(4, "Back", 0, 200)
		player:GossipSendMenu(1, object)
	end
end

function DisplaySlotItems(player, object, items, currentIntid)
	local itemsPerPage = 10
	local baseIntid = math.floor(currentIntid / 100) * 100
	local page = (currentIntid - baseIntid) + 1
	
	if items and #items > 0 then
		local totalPages = math.ceil(#items / itemsPerPage)
		player:GossipClearMenu()
		local startIndex = (page - 1) * itemsPerPage + 1
		local endIndex = math.min(page * itemsPerPage, #items)
		for i = startIndex, endIndex do
			local item = items[i]
			if item and item.name and item.entry then
				player:GossipMenuAddItem(1, item.name, 0, 2000000 + item.entry)
			end
		end
		if page > 1 then
			player:GossipMenuAddItem(7, "Previous Page", 0, baseIntid + page - 2)
		end
		if page < totalPages then
			player:GossipMenuAddItem(7, "Next Page", 0, baseIntid + page)
		end
		player:GossipMenuAddItem(4, "Back", 0, 300)
		player:GossipSendMenu(1, object)
	else
		player:GossipClearMenu()
		player:GossipMenuAddItem(0, "No items found.", 0, 0)
		player:GossipMenuAddItem(4, "Back", 0, 300)
		player:GossipSendMenu(1, object)
	end
end

local function OnGossipHello(event, player, object)
	player:GossipClearMenu()
	player:GossipMenuAddItem(0, "How does this work?", 0, 5000001)
	player:GossipMenuAddItem(1, "Search by item name", 0, 6000000, true, "")
	player:GossipMenuAddItem(1, "Search by armor type", 0, 200)
	player:GossipMenuAddItem(1, "Search by item slot", 0, 300)
	player:GossipSendMenu(1, object)
end

local function OnGossipSelect(event, player, object, sender, intid, code)
	if intid == 0 then
		return OnGossipHello(event, player, object)
	
	elseif intid > 9000000 then
		local searchTerm = currentSearchTerm or ""
		
		local results = {}
		for _, item in ipairs(ItemCache["Cache"]) do
			if item.name:lower():find(searchTerm) then
				table.insert(results, item)
			end
		end
		
		local page = intid - 9000000
		local startIndex = (page - 1) * itemsPerPage + 1
		local endIndex = math.min(startIndex + itemsPerPage - 1, #results)
	   
		player:GossipClearMenu()
		player:GossipMenuAddItem(4, "Back to main menu", 0, 0)
		
		for i = startIndex, endIndex do
			local item = results[i]
			if item then
				player:GossipMenuAddItem(1, item.name, 0, 2000000 + item.entry)
			end
		end
		
		if page > 1 then
			player:GossipMenuAddItem(4, "Previous page", 9000000 + page, 9000000 + page - 1)
		end
		
		if endIndex < #results then
			player:GossipMenuAddItem(4, "Next page", 9000000 + page, 9000000 + page + 1)
		end
		
		player:GossipMenuAddItem(0, "Current search: " .. currentSearchTerm, 0, 9000000 + page)
		player:GossipSendMenu(1, object)
		
	elseif intid == 5000001 then
		player:GossipClearMenu()
		player:GossipMenuAddItem(0, "I am the Ethereal Itemizer. I come from a realm with an unlimited supply of worldly and otherworldy goods, and I possess the ability to peer into the abyss to conjure items long forgotten. My skills are channeled into offering on-demand items for transmogrification. Any item can be inspected by requesting an inspection link before purchasing.", 0, 5000001)
		player:GossipMenuAddItem(4, "Back to main menu", 0, 0)
		player:GossipSendMenu(1, object)
		
	elseif intid == 5000003 then
		player:GossipMenuAddItem(1, "Search by item name", 0, 6000000, true, "")
		player:GossipMenuAddItem(1, "Search by armor type", 0, 200)
		player:GossipMenuAddItem(1, "Search by item slot", 0, 300)
		player:GossipMenuAddItem(4, "Back to main menu", 0, 0)
		player:GossipSendMenu(1, object)
		
	elseif intid == 200 then
		-- Main menu
		player:GossipClearMenu()
		player:GossipMenuAddItem(1, "Cloth", 0, 8900000)
		player:GossipMenuAddItem(1, "Leather", 0, 8800000)
		player:GossipMenuAddItem(1, "Mail", 0, 8700000)
		player:GossipMenuAddItem(1, "Plate", 0, 8600000)
		player:GossipMenuAddItem(4, "Back", 0, 5000003)
		player:GossipSendMenu(1, object)
	elseif intid >= 8900000 and intid < 9000000 then
		DisplayArmorItems(player, object, ArmorTypeFilter(4, 1), intid)
	elseif intid >= 8800000 and intid < 8900000 then
		DisplayArmorItems(player, object, ArmorTypeFilter(4, 2), intid)
	elseif intid >= 8700000 and intid < 8800000 then
		DisplayArmorItems(player, object, ArmorTypeFilter(4, 3), intid)
	elseif intid >= 8600000 and intid < 8700000 then
		DisplayArmorItems(player, object, ArmorTypeFilter(4, 4), intid)
	  
	elseif intid == 300 then
		player:GossipClearMenu()
		player:GossipMenuAddItem(1, "Browse head", 0, 10000)
		player:GossipMenuAddItem(1, "Browse shoulder", 0, 11000)
		player:GossipMenuAddItem(1, "Browse shirt", 0, 12000)
		player:GossipMenuAddItem(1, "Browse waist", 0, 13000)
		player:GossipMenuAddItem(1, "Browse legs", 0, 14000)
		player:GossipMenuAddItem(1, "Browse feet", 0, 15000)
		player:GossipMenuAddItem(1, "Browse wrists", 0, 16000)
		player:GossipMenuAddItem(1, "Browse hands", 0, 18000)
		player:GossipMenuAddItem(1, "Browse back", 0, 19000)
		player:GossipMenuAddItem(1, "Browse weapon", 0, 20000)
		player:GossipMenuAddItem(1, "Browse off-hand", 0, 21000)
		player:GossipMenuAddItem(1, "Browse shield", 0, 22000)
		player:GossipMenuAddItem(1, "Browse ranged", 0, 23000)
		player:GossipMenuAddItem(4, "Back", 0, 5000003)
		player:GossipSendMenu(1, object)

	elseif intid >= 10000 and intid < 11000 then
		local items = SlotTypeFilter(1)  -- Head
		DisplaySlotItems(player, object, items, intid, 10000)
	elseif intid >= 11000 and intid < 12000 then
		local items = SlotTypeFilter(3)  -- Shoulder
		DisplaySlotItems(player, object, items, intid, 11000)
	elseif intid >= 12000 and intid < 13000 then
		local items = SlotTypeFilter(4)  -- Shirt
		DisplaySlotItems(player, object, items, intid, 12000)
	elseif intid >= 13000 and intid < 14000 then
		local items = SlotTypeFilter(6)  -- Waist
		DisplaySlotItems(player, object, items, intid, 13000)
	elseif intid >= 14000 and intid < 15000 then
		local items = SlotTypeFilter(7)  -- Legs
		DisplaySlotItems(player, object, items, intid, 14000)
	elseif intid >= 15000 and intid < 16000 then
		local items = SlotTypeFilter(8)  -- Feet
		DisplaySlotItems(player, object, items, intid, 15000)
	elseif intid >= 16000 and intid < 17000 then
		local items = SlotTypeFilter(9)  -- Wrists
		DisplaySlotItems(player, object, items, intid, 16000)
	elseif intid >= 18000 and intid < 19000 then
		local items = SlotTypeFilter(10)  -- Hands
		DisplaySlotItems(player, object, items, intid, 18000)
	elseif intid >= 19000 and intid < 20000 then
		local items = SlotTypeFilter(16)  -- Back
		DisplaySlotItems(player, object, items, intid, 19000)
	elseif intid >= 20000 and intid < 21000 then
		local items = SlotTypeFilter({13, 17, 21, 22, 26})  -- Weapon
		DisplaySlotItems(player, object, items, intid, 20000)
	elseif intid >= 21000 and intid < 22000 then
		local items = SlotTypeFilter({22, 23})  -- Off-hand
		DisplaySlotItems(player, object, items, intid, 21000)
	elseif intid >= 22000 and intid < 23000 then
		local items = SlotTypeFilter(14)  -- Shield
		DisplaySlotItems(player, object, items, intid, 22000)
	elseif intid >= 23000 and intid < 24000 then
		local items = SlotTypeFilter({15, 26})  -- Ranged
		DisplaySlotItems(player, object, items, intid, 23000)

	elseif intid == 6000000 then
		print("Search input received. Code: " .. (code or "nil"))
		if code then
			if code ~= "" then
				currentSearchTerm = code:lower()
				print("Search term set to: " .. currentSearchTerm)
				ItemCache.GenerateSearchMenu(player, object, 1)
			else
				print("Empty search term received")
				player:GossipMenuAddItem(0, "Please enter a valid search term", 0, 5000003)
				player:GossipSendMenu(1, object)
			end
		else
			print("Search was canceled")
			OnGossipHello(event, player, object)
		end
	elseif intid > 8000000 and intid < 8100000 then
        local itemId = intid - 8000000
        local baseItemCost = math.ceil(itemId / 1000)

        -- Find the item in the ItemCache
        local itemData
        for _, item in ipairs(ItemCache["Cache"]) do
            if item.entry == itemId then
                itemData = item
                break
            end
        end

        if itemData then
            local quality = itemData.quality
            local maxcount = itemData.maxcount
			if maxcount == 0 then
				maxcount = 99
			end
            local itemCost = math.floor(baseItemCost / 3 * 2 + (baseItemCost / 4 * quality^1.4))

            if quality >= 5 then
                itemCost = math.max(itemCost, 100)
            end

            if PlayerHasEnoughCurrency(player, itemCost) then
                if PlayerHasEnoughFreeSlots(player, 1) then
                    if player:GetItemCount(itemId) < maxcount then
                        player:AddItem(itemId, 1)
                        player:RemoveItem(CURRENCY_ID, itemCost)
                        player:SendBroadcastMessage("You have purchased " .. GetItemLink(itemId) .. " for " .. itemCost .. " " .. CURRENCY_NAME .. ".")
                        print("Player "..player:GetName().." has purchased " .. GetItemLink(itemId) .. " for " .. itemCost .. " " .. CURRENCY_NAME .. ".")
                    else
                        player:SendBroadcastMessage("You cannot have more than " .. maxcount .. " of " .. GetItemLink(itemId) .. ".")
                    end
                    player:GossipComplete()
                else
                    player:SendAreaTriggerMessage("Your bags are full!")
                    player:SendBroadcastMessage("You don't have enough bag space to buy " .. GetItemLink(itemId))
                end
            else
                player:SendBroadcastMessage("You don't have enough " .. CURRENCY_NAME .. " to buy " .. GetItemLink(itemId) .. ". (Cost: " .. itemCost .. " " .. CURRENCY_NAME .. ")")
            end
		end
		
	elseif intid > 7000000 and intid < 7200000 then -- Send inspection link
		local itemId = intid - 7000000
		local itemLink = GetItemLink(itemId)
		player:SendBroadcastMessage("Inspection link for: " .. itemLink)
		
		player:GossipClearMenu()
		local baseItemCost = math.ceil(itemId / 1000)
		
		-- Find the item in the ItemCache
		local itemData
		for _, item in ipairs(ItemCache["Cache"]) do
			if item.entry == itemId then
				itemData = item
				break
			end
		end
		
		local quality = itemData and itemData.quality or 0
		local itemCost = math.floor((itemId / 1000)/3*2 + (baseItemCost / 4 * quality^1.4))
		if quality >= 5 then
			itemCost = math.max(itemCost, 100)
		end
		
		player:GossipMenuAddItem(0, "Do you want to receive an inspection link to " .. itemLink .. "?", 0, 7000000 + itemId)

		if PlayerHasEnoughCurrency(player, itemCost) then
			if PlayerHasEnoughFreeSlots(player, 1) then
				player:GossipMenuAddItem(0, "Do you want to buy " .. itemLink .. " for " .. itemCost .. " "..CURRENCY_NAME.."?", 0, 8000000 + itemId)
			else
				player:SendAreaTriggerMessage("Your bags are full!")
				player:GossipMenuAddItem(0, "You don't have enough bag space to buy " .. itemLink, 0, 0)
			end
		else
			player:GossipMenuAddItem(0, "You don't have enough "..CURRENCY_NAME.." to buy " .. itemLink .. " (Cost: " .. itemCost .. " "..CURRENCY_NAME..")", 0, 0)
		end
		
		player:GossipMenuAddItem(4, "Go back", 0, 0)
		player:GossipSendMenu(1, object)
	elseif intid > 4000000 then
		local page = intid - 4000000
		ItemCache.GenerateSearchMenu(player, object, page)
		
	elseif intid > 2000000 then -- Buy individual item
		local itemId = intid - 2000000
		local itemLink = GetItemLink(itemId)
		local baseItemCost = math.ceil(itemId / 1000)
		
		-- Find the item in the ItemCache
		local itemData
		for _, item in ipairs(ItemCache["Cache"]) do
			if item.entry == itemId then
				itemData = item
				break
			end
		end
		
		local quality = itemData and itemData.quality or 0
		local itemCost = math.floor(baseItemCost/3*2 + (baseItemCost / 4 * quality^1.4))
		
		if quality >= 5 then
			itemCost = math.max(itemCost, 100)
		end
		player:GossipClearMenu()
		player:GossipMenuAddItem(0, "Do you want to receive an inspection link to " .. itemLink .. "?", 0, 7000000 + itemId)
		
		if PlayerHasEnoughCurrency(player, itemCost) then
			if PlayerHasEnoughFreeSlots(player, 1) then
				player:GossipMenuAddItem(0, "Do you want to buy " .. itemLink .. " for " .. itemCost .. " "..CURRENCY_NAME.."?", 0, 8000000 + itemId)
			else
				player:GossipMenuAddItem(0, "You don't have enough bag space to buy " .. itemLink, 0, 0)
				player:SendAreaTriggerMessage("Your bags are full!")
			end
		else
			player:GossipMenuAddItem(0, "You don't have enough "..CURRENCY_NAME.." to buy " .. itemLink .. " (Cost: " .. itemCost .. " "..CURRENCY_NAME..")", 0, 0)
		end
		
		player:GossipMenuAddItem(4, "Go back", 0, 0)
		player:GossipSendMenu(1, object)
	end
end

ItemCache.LoadCache()

-- Register gossip events
RegisterCreatureGossipEvent(NPC_ID, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_ID, 2, OnGossipSelect)

print("[NPC]: Legacy Item Set vendor loaded!")
