local logoutTimer = 1000
local voteTokenItemId = 377420 -- ID for Vote Tokens
local voteTokenCost = 50 -- Cost in Vote Tokens

local playersToUpdate = {}

-- Function to check if a value exists in a table
local function tableContains(table, value)
    for _, v in ipairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

-- Function to decode the taximask into a table of known nodes
local function decodeTaximask(taximask)
    local knownNodes = {}
    for i, value in ipairs(taximask) do
        for bit = 0, 31 do
            if bit32.band(value, bit32.lshift(1, bit)) ~= 0 then
                local nodeId = (i - 1) * 32 + bit + 1
                table.insert(knownNodes, nodeId)
            end
        end
    end
    return knownNodes
end

-- Function to check if player has at least a required number of taxi nodes for a region
local function hasAtLeastTaxiNodes(playerGuid, regionNodes, requiredCount)
    local query = CharDBQuery(string.format("SELECT taximask FROM characters WHERE guid = %u", playerGuid))
    
    if query then
        local taximaskStr = query:GetString(0)
        local taximask = {}
        
        for value in taximaskStr:gmatch("%d+") do
            table.insert(taximask, tonumber(value))
        end
        
        local knownNodes = decodeTaximask(taximask)
        local count = 0
        
        for _, nodeId in ipairs(regionNodes) do
            if tableContains(knownNodes, nodeId) then
                count = count + 1
            end
        end
        
        return count >= requiredCount
    else
        print(string.format("Error: Could not retrieve character data for GUID %u.", playerGuid))
        return false
    end
end

-- Function to encode a set of nodes into a taximask
local function encodeTaximask(nodes)
    local taximask = {}
    for i = 1, 16 do
        taximask[i] = 0
    end
    for _, nodeId in ipairs(nodes) do
        local index = math.floor((nodeId - 1) / 32) + 1
        local bit = (nodeId - 1) % 32
        taximask[index] = bit32.bor(taximask[index], bit32.lshift(1, bit))
    end
    return taximask
end

local function getTaxiNodes(player)
    local guid = player:GetGUIDLow()
    
    local query = CharDBQuery(string.format("SELECT taximask FROM characters WHERE guid = %u", guid))
    
    if query then
        local taximaskStr = query:GetString(0)
        local taximask = {}
        
        for value in taximaskStr:gmatch("%d+") do
            table.insert(taximask, tonumber(value))
        end
        
        local knownNodes = decodeTaximask(taximask)
        
        player:SendBroadcastMessage(string.format("Known taxi nodes for your character:"))
        for _, nodeId in ipairs(knownNodes) do
            player:SendBroadcastMessage(string.format("Node ID: %d", nodeId))
        end
    else
        player:SendBroadcastMessage("No taximask found for your character.")
    end
end

local function taxieasternkingdomsNodes(playerGuid)
    local query = CharDBQuery(string.format("SELECT taximask FROM characters WHERE guid = %u", playerGuid))
    
    if query then
        local taximaskStr = query:GetString(0)
        local taximask = {}
        
        for value in taximaskStr:gmatch("%d+") do
            table.insert(taximask, tonumber(value))
        end
        
        local knownNodes = decodeTaximask(taximask)
        
        local azerothNodes = {82, 83, 1,2,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,43,45,56,66,67,68,70,71,74,75,76,78,84,85,86,87,195,224,315,352,377,383,384}
        
        for _, nodeId in ipairs(azerothNodes) do
            if not tableContains(knownNodes, nodeId) then
                table.insert(knownNodes, nodeId)
            end
        end
        
        local newTaximask = encodeTaximask(knownNodes)
        local newTaximaskStr = table.concat(newTaximask, " ")
        
        CharDBExecute(string.format("UPDATE characters SET taximask = '%s' WHERE guid = %u", newTaximaskStr, playerGuid))
        
        print(string.format("Eastern Kingdoms taxi nodes have been added for player GUID %u.", playerGuid))
    else
        print(string.format("Error: Could not retrieve character data for GUID %u.", playerGuid))
    end
end

local function taxikalimdorNodes(playerGuid)
    local query = CharDBQuery(string.format("SELECT taximask FROM characters WHERE guid = %u", playerGuid))
    
    if query then
        local taximaskStr = query:GetString(0)
        local taximask = {}
        
        for value in taximaskStr:gmatch("%d+") do
            table.insert(taximask, tonumber(value))
        end
        
        local knownNodes = decodeTaximask(taximask)
        
        local azerothNodes = {93, 94, 22,23,25,26,27,28,29,30,31,32,33,37,38,39,40,41,42,44,48,49,52,53,55,57,58,61,62,63,64,65,69,72,73,77,79,80,166,167,179}
        
        for _, nodeId in ipairs(azerothNodes) do
            if not tableContains(knownNodes, nodeId) then
                table.insert(knownNodes, nodeId)
            end
        end
        
        local newTaximask = encodeTaximask(knownNodes)
        local newTaximaskStr = table.concat(newTaximask, " ")
        
        CharDBExecute(string.format("UPDATE characters SET taximask = '%s' WHERE guid = %u", newTaximaskStr, playerGuid))
        
        print(string.format("Kalimdor taxi nodes have been added for player GUID %u.", playerGuid))
    else
        print(string.format("Error: Could not retrieve character data for GUID %u.", playerGuid))
    end
end

local function taxioutlandNodes(playerGuid)
    local query = CharDBQuery(string.format("SELECT taximask FROM characters WHERE guid = %u", playerGuid))
    
    if query then
        local taximaskStr = query:GetString(0)
        local taximask = {}
        
        for value in taximaskStr:gmatch("%d+") do
            table.insert(taximask, tonumber(value))
        end
        
        local knownNodes = decodeTaximask(taximask)
        
        local azerothNodes = {99, 100, 101, 102, 111, 112, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 139, 140, 141, 142, 147, 149, 150, 151, 156, 159, 160, 163, 164, 171, 172, 205, 213}
        
        for _, nodeId in ipairs(azerothNodes) do
            if not tableContains(knownNodes, nodeId) then
                table.insert(knownNodes, nodeId)
            end
        end
        
        local newTaximask = encodeTaximask(knownNodes)
        local newTaximaskStr = table.concat(newTaximask, " ")
        
        CharDBExecute(string.format("UPDATE characters SET taximask = '%s' WHERE guid = %u", newTaximaskStr, playerGuid))
        
        print(string.format("Outland taxi nodes have been added for player GUID %u.", playerGuid))
    else
        print(string.format("Error: Could not retrieve character data for GUID %u.", playerGuid))
    end
end

local function taxieasternkingdoms()
    local currentTime = os.time()
    for i = #playersToUpdate, 1, -1 do
        local playerData = playersToUpdate[i]
        if currentTime - playerData.logoutTime >= 3 then
            taxieasternkingdomsNodes(playerData.guid)
            table.remove(playersToUpdate, i)
        end
    end
end

local function taxikalimdor()
    local currentTime = os.time()
    for i = #playersToUpdate, 1, -1 do
        local playerData = playersToUpdate[i]
        if currentTime - playerData.logoutTime >= 3 then
            taxikalimdorNodes(playerData.guid)
            table.remove(playersToUpdate, i)
        end
    end
end

local function taxioutland()
    local currentTime = os.time()
    for i = #playersToUpdate, 1, -1 do
        local playerData = playersToUpdate[i]
        if currentTime - playerData.logoutTime >= 3 then
            taxioutlandNodes(playerData.guid)
            table.remove(playersToUpdate, i)
        end
    end
end

local function onCommand(event, player, command)
    if command == "taxinodes" then
        getTaxiNodes(player)
        return false
    elseif command == "taxieasternkingdoms" then
        local playerGuid = player:GetGUIDLow()
        local azerothNodes = {82, 83, 1,2,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,43,45,56,66,67,68,70,71,74,75,76,78,84,85,86,87,195,224,315,352,377,383,384}
        local requiredCount = 35
        
        if hasAtLeastTaxiNodes(playerGuid, azerothNodes, requiredCount) then
            player:SendBroadcastMessage("You already have all Eastern Kingdoms flight paths.")
			player:GossipComplete()
        else
            table.insert(playersToUpdate, {guid = playerGuid, logoutTime = os.time()})
            player:SendBroadcastMessage("You have purchased all Eastern Kingdoms flight paths. This process will log you out.")
            player:SaveToDB() -- Save any pending changes
            player:LogoutPlayer() -- Logout the player immediately
            CreateLuaEvent(taxieasternkingdoms, logoutTimer, 0)
        end
        return false
    elseif command == "taxikalimdor" then
        local playerGuid = player:GetGUIDLow()
        local azerothNodes = {93, 94, 22,23,25,26,27,28,29,30,31,32,33,37,38,39,40,41,42,44,48,49,52,53,55,57,58,61,62,63,64,65,69,72,73,77,79,80,166,167,179}
        local requiredCount = 31
        
        if hasAtLeastTaxiNodes(playerGuid, azerothNodes, requiredCount) then
            player:SendBroadcastMessage("You already have at least 35 Kalimdor flight paths.")
			player:GossipComplete()
        else
            table.insert(playersToUpdate, {guid = playerGuid, logoutTime = os.time()})
            player:SendBroadcastMessage("You have purchased all Kalimdor flight paths. This process will log you out.")
            player:SaveToDB() -- Save any pending changes
            player:LogoutPlayer() -- Logout the player immediately
            CreateLuaEvent(taxikalimdor, logoutTimer, 0)
        end
        return false
    elseif command == "taxioutland" then
        local playerGuid = player:GetGUIDLow()
        local azerothNodes = {99, 100, 101, 102, 111, 112, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 139, 140, 141, 142, 147, 149, 150, 151, 156, 159, 160, 163, 164, 171, 172, 205, 213}
        local requiredCount = 17
        
        if hasAtLeastTaxiNodes(playerGuid, azerothNodes, requiredCount) then
            player:SendBroadcastMessage("You already have at least 27 Outland flight paths.")
			player:GossipComplete()
        else
            table.insert(playersToUpdate, {guid = playerGuid, logoutTime = os.time()})
            player:SendBroadcastMessage("You have purchased all Outland flight paths. This process will log you out.")
            player:SaveToDB() -- Save any pending changes
            player:LogoutPlayer() -- Logout the player immediately
            CreateLuaEvent(taxioutland, logoutTimer, 0)
        end
        return false
    end
end

local function OnGossipHello(event, player, creature)
    player:GossipMenuAddItem(0, "Flight path sets cost 50 Vote Tokens each", 0, 4, false)
    player:GossipMenuAddItem(3, "Kalimdor flight paths", 0, 1, false, "Are you sure you want to pay 50 Vote Tokens for all Kalimdor flight paths? This process will log you out as the flight paths load.")
    player:GossipMenuAddItem(3, "Eastern Kingdoms flight paths", 0, 2, false, "Are you sure you want to pay 50 Vote Tokens for all Eastern Kingdoms flight paths? This process will log you out as the flight paths load.")
    player:GossipMenuAddItem(3, "Outland flight paths", 0, 3, false, "Are you sure you want to pay 50 Vote Tokens for all Outland flight paths? This process will log you out as the flight paths load.")
    player:GossipSendMenu(1, creature)
end


local function hasSufficientVoteTokens(player, amount)
    return player:GetItemCount(voteTokenItemId) >= amount
end

local function removeVoteTokens(player, amount)
    player:RemoveItem(voteTokenItemId, amount)
end

local function OnGossipSelect(event, player, creature, sender, intid, code)
    if intid == 4 then -- Recreate gossip menu
		player:GossipClearMenu()
		player:GossipMenuAddItem(0, "Flight path sets cost 50 Vote Tokens each", 0, 4, false)
		player:GossipMenuAddItem(3, "Kalimdor flight paths", 0, 1, false, "Are you sure you want to pay 50 Vote Tokens for all Kalimdor flight paths? This process will log you out as the flight paths load.")
		player:GossipMenuAddItem(3, "Eastern Kingdoms flight paths", 0, 2, false, "Are you sure you want to pay 50 Vote Tokens for all Eastern Kingdoms flight paths? This process will log you out as the flight paths load.")
		player:GossipMenuAddItem(3, "Outland flight paths", 0, 3, false, "Are you sure you want to pay 50 Vote Tokens for all Outland flight paths? This process will log you out as the flight paths load.")
		player:GossipSendMenu(1, creature)
    elseif intid == 1 then -- Kalimdor
        if hasSufficientVoteTokens(player, voteTokenCost) then
            removeVoteTokens(player, voteTokenCost)
            local playerGuid = player:GetGUIDLow()
            local azerothNodes = {93, 94, 22,23,25,26,27,28,29,30,31,32,33,37,38,39,40,41,42,44,48,49,52,53,55,57,58,61,62,63,64,65,69,72,73,77,79,80,166,167,179}
            local requiredCount = 35
            
            if hasAtLeastTaxiNodes(playerGuid, azerothNodes, requiredCount) then
                player:SendBroadcastMessage("You already have all Kalimdor flight paths.")
				player:GossipComplete()
            else
                table.insert(playersToUpdate, {guid = playerGuid, logoutTime = os.time()})
                player:SendBroadcastMessage("You have purchased all Kalimdor flight paths. This process will log you out.")
                player:SaveToDB()
                player:LogoutPlayer()
                CreateLuaEvent(taxikalimdor, logoutTimer, 0)
            end
        else
            player:SendBroadcastMessage("You do not have enough Vote Tokens.")
        end
        player:GossipComplete()
    elseif intid == 2 then -- Eastern Kingdoms
        if hasSufficientVoteTokens(player, voteTokenCost) then
            removeVoteTokens(player, voteTokenCost)
            local playerGuid = player:GetGUIDLow()
            local azerothNodes = {82, 83, 1,2,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,43,45,56,66,67,68,70,71,74,75,76,78,84,85,86,87,195,224,315,352,377,383,384}
            local requiredCount = 31
            
            if hasAtLeastTaxiNodes(playerGuid, azerothNodes, requiredCount) then
                player:SendBroadcastMessage("You already have all Eastern Kingdoms flight paths.")
				player:GossipComplete()
            else
                table.insert(playersToUpdate, {guid = playerGuid, logoutTime = os.time()})
                player:SendBroadcastMessage("You have purchased all Eastern Kingdoms flight paths. This process will log you out.")
                player:SaveToDB()
                player:LogoutPlayer()
                CreateLuaEvent(taxieasternkingdoms, logoutTimer, 0)
            end
        else
            player:SendBroadcastMessage("You do not have enough Vote Tokens.")
        end
        player:GossipComplete()
    elseif intid == 3 then -- Outland
        if hasSufficientVoteTokens(player, voteTokenCost) then
            removeVoteTokens(player, voteTokenCost)
            local playerGuid = player:GetGUIDLow()
            local azerothNodes = {99, 100, 101, 102, 111, 112, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 139, 140, 141, 142, 147, 149, 150, 151, 156, 159, 160, 163, 164, 171, 172, 205, 213}
            local requiredCount = 17
            
            if hasAtLeastTaxiNodes(playerGuid, azerothNodes, requiredCount) then
                player:SendBroadcastMessage("You already have all Outland flight paths.")
				player:GossipComplete()
            else
                table.insert(playersToUpdate, {guid = playerGuid, logoutTime = os.time()})
                player:SendBroadcastMessage("You have purchased all Outland flight paths. This process will log you out.")
                player:SaveToDB()
                player:LogoutPlayer()
                CreateLuaEvent(taxioutland, logoutTimer, 0)
            end
        else
            player:SendBroadcastMessage("You do not have enough Vote Tokens.")
        end
        player:GossipComplete()
    end
end

RegisterCreatureGossipEvent(190095, 1, OnGossipHello)
RegisterCreatureGossipEvent(190095, 2, OnGossipSelect)
RegisterPlayerEvent(42, onCommand)
