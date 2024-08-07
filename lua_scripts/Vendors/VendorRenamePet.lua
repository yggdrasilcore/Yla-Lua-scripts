local cost = 25
local currencyName = "Vote Tokens"
local petNameCache = {}
local sortedPetNameCache = {}
local PAGE_SIZE = 13
local currentEntry = 0
local currentHalf = 0
local currentPage = 1
local firstHalfSelection = ""
local secondHalfSelection = ""
local pendingRenames = {}
local petTypes = {
    [416] = "Imp",
    [417] = "Felhunter",
    [1860] = "Voidwalker",
    [1863] = "Succubus",
    [17252] = "Felguard",
    [26125] = "Raise Dead pet"  -- For Death Knight
}

-- Function to load pet names from the database and sort them
local function LoadPetNames()
    local query = WorldDBQuery("SELECT id, word, entry, half FROM pet_name_generation")
    if query then
        repeat
            local id = query:GetUInt32(0)
            local word = query:GetString(1)
            local entry = query:GetUInt32(2)
            local half = query:GetUInt32(3)
            petNameCache[id] = { word = word, entry = entry, half = half }
        until not query:NextRow()
    end

    -- Sort pet names alphabetically
    sortedPetNameCache = {}
    for id, data in pairs(petNameCache) do
        table.insert(sortedPetNameCache, { id = id, word = data.word, entry = data.entry, half = data.half })
    end
    table.sort(sortedPetNameCache, function(a, b) return a.word < b.word end)
end

-- Load pet names into cache on script load
LoadPetNames()

-- Command handler
local function OnPlayerCommand(event, player, command)
    if command == "petname" then
        player:GossipClearMenu()
        player:GossipMenuAddItem(4, "How does this work?", 0, 1)
        
        if player:GetClass() == 9 then -- Warlock
            player:GossipMenuAddItem(0, "Imp", 0, 416)
            player:GossipMenuAddItem(0, "Felhunter", 0, 417)
            player:GossipMenuAddItem(0, "Voidwalker", 0, 1860)
            player:GossipMenuAddItem(0, "Succubus", 0, 1863)
            player:GossipMenuAddItem(0, "Felguard", 0, 17252)
        elseif player:GetClass() == 6 then -- Death Knight
            player:GossipMenuAddItem(0, "What do you want to rename your undead pet to?", 0, 6)
        end
        
        player:GossipMenuAddItem(4, "Nevermind", 0, 2)
        player:GossipSendMenu(1, player, 60)
    end
end

local function OnGossipHello(event, player, creature)
	if player:GetClass() == 9 or player:GetClass() == 6 then
		player:GossipClearMenu()
		player:GossipMenuAddItem(4, "How does this work?", 0, 1)
		
		if player:GetClass() == 9 then -- Warlock
			player:GossipMenuAddItem(0, "Imp", 0, 416)
			player:GossipMenuAddItem(0, "Felhunter", 0, 417)
			player:GossipMenuAddItem(0, "Voidwalker", 0, 1860)
			player:GossipMenuAddItem(0, "Succubus", 0, 1863)
			player:GossipMenuAddItem(0, "Felguard", 0, 17252)
		elseif player:GetClass() == 6 then -- Death Knight
			player:GossipMenuAddItem(0, "What do you want to rename your undead pet to?", 0, 6)
		end
		
		player:GossipMenuAddItem(4, "Nevermind", 0, 2)
		player:GossipSendMenu(1, player, 60)
	else
		player:SendBroadcastMessage("I only cater to Warlocks and Death Knights.")
	end
end

local function ShowPage(player, entry, half, page)
    currentEntry = entry
    currentHalf = half
    currentPage = page

    local startIdx = (page - 1) * PAGE_SIZE + 1
    local endIdx = page * PAGE_SIZE
    local totalItems = 0

    -- Count total items
    for _, data in pairs(sortedPetNameCache) do
        if data.entry == entry and data.half == half then
            totalItems = totalItems + 1
        end
    end

    player:GossipClearMenu()

    -- Add the indicator for which half of the name is being selected
    player:GossipMenuAddItem(4, half == 0 and "Selecting first half of name" or "Selecting second half of name", 0, 0)

    -- Show items for the current page
    local itemsShown = 0
    for _, data in pairs(sortedPetNameCache) do
        if data.entry == entry and data.half == half then
            if itemsShown >= startIdx - 1 and itemsShown < endIdx then
                player:GossipMenuAddItem(0, data.word, 0, data.id)
            end
            itemsShown = itemsShown + 1
            if itemsShown >= endIdx then
                break
            end
        end
    end

    -- Add previous page button if not on the first page
    if page > 1 then
        player:GossipMenuAddItem(4, "Previous Page", 0, 10001)
    end

    -- Add next page button if there are more items
    if totalItems > endIdx then
        player:GossipMenuAddItem(4, "Next Page", 0, 10002)
    end

    player:GossipSendMenu(1, player, 60)
end

local function UpdatePetName(playerGUID)
    local renameInfo = pendingRenames[playerGUID]
    if renameInfo then
        local query = string.format("UPDATE character_pet SET name = '%s' WHERE owner = %d AND entry = %d",
            renameInfo.petName, playerGUID, renameInfo.petEntry)
        CharDBExecute(query)
        print(string.format("Updated pet name in database for player GUID %d to %s", playerGUID, renameInfo.petName))
        pendingRenames[playerGUID] = nil
    end
end

local function OnGossipSelect(event, player, object, sender, intid, code)
    if intid == 416 or intid == 417 or intid == 1860 or intid == 1863 or intid == 17252 then
        firstHalfSelection = ""
        secondHalfSelection = ""
        currentEntry = intid
        currentHalf = 0
        player:GossipClearMenu()
        ShowPage(player, intid, 0, 1)
    elseif intid == 6 then
        firstHalfSelection = ""
        secondHalfSelection = ""
        currentEntry = 26125
        currentHalf = 0
        player:GossipClearMenu()
        ShowPage(player, 26125, 0, 1)
    elseif intid == 1 then
        player:GossipClearMenu()
        player:GossipMenuAddItem(0, "I possess the ability to permanently rename your pets through manipulating the threads in the Twisting Nether. Simply choose what kind of pet you want to rename and select the name. I charge "..cost.." "..currencyName.." for my services. To complete the process, I will log you out. When you return, your pet will be renamed.", 0, intid)
        player:GossipMenuAddItem(4, "Back", 0, 20001)
        player:GossipSendMenu(1, player, 60)
    elseif intid == 2 then
        player:GossipComplete()
    elseif intid == 10001 then
        player:GossipClearMenu()
        ShowPage(player, currentEntry, currentHalf, currentPage - 1)
    elseif intid == 10002 then
        player:GossipClearMenu()
        ShowPage(player, currentEntry, currentHalf, currentPage + 1)
    elseif petNameCache[intid] then
        local selectedName = petNameCache[intid]
        if selectedName then
            if currentHalf == 0 then
                firstHalfSelection = selectedName.word
                currentHalf = 1
                player:GossipClearMenu()
                ShowPage(player, selectedName.entry, 1, 1)
            else
                secondHalfSelection = selectedName.word
                local fullPetName = firstHalfSelection .. secondHalfSelection
                local petType = petTypes[currentEntry] or "Pet"
                
                player:GossipClearMenu()
                player:GossipMenuAddItem(4, string.format("Rename %s to %s?", petType, fullPetName), 0, 20000, false, string.format("Are you sure you want to rename your %s to '%s'? This process costs "..cost.." "..currencyName.." and will log you out to save the change.", petType, fullPetName))
                player:GossipMenuAddItem(0, "Cancel", 0, 20001)
                player:GossipSendMenu(1, player, 60)
            end
        end
    elseif intid == 20000 then
        local petType = petTypes[currentEntry] or "Pet"
        local fullPetName = firstHalfSelection .. secondHalfSelection
        local playerGUID = player:GetGUIDLow()
        
        -- Check if the player has enough vote tokens
        if player:GetItemCount(20880) >= cost then
            player:RemoveItem(20880, cost)
            player:SaveToDB()
            
            pendingRenames[playerGUID] = {
                petName = fullPetName,
                petEntry = currentEntry
            }
            
            print(string.format("Player %s will rename their %s to: %s", player:GetName(), petType, fullPetName))
            player:GossipComplete()
            
            -- Schedule the database update
            CreateLuaEvent(function() UpdatePetName(playerGUID) end, 1000, 1)
            
            -- Log out the player
            player:LogoutPlayer(false)
        else
            player:SendBroadcastMessage("You don't have enough "..currencyName..". "..cost.." "..currencyName.." are required to rename your pet.")
            player:GossipComplete()
        end
    elseif intid == 20001 then
        firstHalfSelection = ""
        secondHalfSelection = ""
        currentHalf = 0
        player:GossipClearMenu()
        player:GossipClearMenu()
        player:GossipMenuAddItem(4, "How does this work?", 0, 1)
        
        if player:GetClass() == 9 then -- Warlock
            player:GossipMenuAddItem(0, "Imp", 0, 416)
            player:GossipMenuAddItem(0, "Felhunter", 0, 417)
            player:GossipMenuAddItem(0, "Voidwalker", 0, 1860)
            player:GossipMenuAddItem(0, "Succubus", 0, 1863)
            player:GossipMenuAddItem(0, "Felguard", 0, 17252)
        elseif player:GetClass() == 6 then -- Death Knight
            player:GossipMenuAddItem(0, "What do you want to rename your undead pet to?", 0, 6)
        end
        player:GossipMenuAddItem(4, "Nevermind", 0, 2)
        
        player:GossipSendMenu(1, player, 60)
    end
end

-- Register player command event
RegisterPlayerEvent(42, OnPlayerCommand)

-- Register gossip event for player interactions (ID 60) and NPC (ID 190086)
RegisterPlayerGossipEvent(60, 2, OnGossipSelect)
RegisterCreatureGossipEvent(190086, 1, OnGossipHello)
RegisterCreatureGossipEvent(190086, 2, OnGossipSelect)
