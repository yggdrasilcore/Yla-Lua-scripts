-- Multistate: Azshara Mall-only script (mall map 37).
if GetStateMapId() ~= 37 then return end

local logoutTimer = 1000
local voteTokenItemId = 20880 -- ID for Vote Tokens
local voteTokenCost = 50 -- Cost in Vote Tokens
local voteTokenName = "Vote Tokens"

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
        taximask[index] = bit_or(taximask[index], bit32.lshift(1, bit))
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
    local player = require("Multistate").FindPlayerByGUID(GetPlayerGUID(playerGuid))
    if not player then
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
    else
        CreateLuaEvent(function() taxieasternkingdomsNodes(playerGuid) end, logoutTimer, 1)
        print("Looping Eastern Kingdoms taxi event!")
    end
end

local function taxikalimdorNodes(playerGuid)
    local player = require("Multistate").FindPlayerByGUID(GetPlayerGUID(playerGuid))
    if not player then
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
    else
        CreateLuaEvent(function() taxikalimdorNodes(playerGuid) end, logoutTimer, 1)
        print("Looping Kalimdor taxi event!")
    end
end

local function taxioutlandNodes(playerGuid)
    local player = require("Multistate").FindPlayerByGUID(GetPlayerGUID(playerGuid))
    if not player then
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
    else
        CreateLuaEvent(function() taxioutlandNodes(playerGuid) end, logoutTimer, 1)
        print("Looping Outland taxi event!")
    end
end

local function taxieasternkingdoms()
    for i = #playersToUpdate, 1, -1 do
        local playerData = playersToUpdate[i]
        taxieasternkingdomsNodes(playerData.guid)
        table.remove(playersToUpdate, i)
    end
end

local function taxikalimdor()
    for i = #playersToUpdate, 1, -1 do
        local playerData = playersToUpdate[i]
        taxikalimdorNodes(playerData.guid)
        table.remove(playersToUpdate, i)
    end
end

local function taxioutland()
    for i = #playersToUpdate, 1, -1 do
        local playerData = playersToUpdate[i]
        taxioutlandNodes(playerData.guid)
        table.remove(playersToUpdate, i)
    end
end

local function OnGossipHello(event, player, creature)
    player:GossipClearMenu()
    player:GossipMenuAddItem(4, "|TInterface/ICONS/INV_Misc_QuestionMark:32:32:-22:0|tAbout flight paths vendor", 0, 4, false)
    player:GossipMenuAddItem(4, "|TInterface/ICONS/achievement_zone_kalimdor_01:32:32:-22:0|tKalimdor flight paths", 0, 1, false, "Are you sure you want to pay 50 Vote Tokens for all Kalimdor flight paths? This process will log you out as the flight paths load.")
    player:GossipMenuAddItem(4, "|TInterface/ICONS/achievement_zone_easternkingdoms_01:32:32:-22:0|tEastern Kingdoms flight paths", 0, 2, false, "Are you sure you want to pay 50 Vote Tokens for all Eastern Kingdoms flight paths? This process will log you out as the flight paths load.")
    player:GossipMenuAddItem(4, "|TInterface/ICONS/achievement_zone_outland_01:32:32:-22:0|tOutland flight paths", 0, 3, false, "Are you sure you want to pay 50 Vote Tokens for all Outland flight paths? This process will log you out as the flight paths load.")
    player:GossipSendMenu(12, creature, 62)
end

local function OnGossipSelect(event, player, creature, sender, intid, code)
    if intid == 4 then
        player:GossipClearMenu()
        player:GossipMenuAddItem(4, "|TInterface/ICONS/INV_Misc_QuestionMark:32:32:-22:0|tAbout flight paths vendor\n \nI have travelled between the warmer continents for decades now, and after a life full of travels, I'm ready to offer my teachings of the world to you, "..player:GetName().."\n \nI can offer to teach you all flight paths of Outlands, Eastern Kingdoms and Kalimdor for "..voteTokenCost.." "..voteTokenName..".\n \nMy services are non-refundable.\n \n ", 0, 4, false)
        player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 0, 5, false)
        player:GossipSendMenu(12, creature, 62)
    elseif intid == 5 then
        OnGossipHello(event, player, creature)
    elseif intid == 1 then -- Kalimdor
        local playerGuid = player:GetGUIDLow()
        local azerothNodes = {93, 94, 22,23,25,26,27,28,29,30,31,32,33,37,38,39,40,41,42,44,48,49,52,53,55,57,58,61,62,63,64,65,69,72,73,77,79,80,166,167,179}
        local requiredCount = 35

        if hasAtLeastTaxiNodes(playerGuid, azerothNodes, requiredCount) then
            player:SendBroadcastMessage("You already have all Kalimdor flight paths.")
            player:GossipComplete()
        elseif player:HasItem(voteTokenItemId, voteTokenCost) then
            player:RemoveItem(voteTokenItemId, voteTokenCost)
            table.insert(playersToUpdate, {guid = playerGuid, logoutTime = os.time()})
            player:SendBroadcastMessage("You have purchased all Kalimdor flight paths. This process will log you out.")
            player:SaveToDB()
            player:LogoutPlayer()
            CreateLuaEvent(taxikalimdor, logoutTimer, 1)
            player:GossipComplete()
        else
            player:SendBroadcastMessage("You do not have enough Vote Tokens.")
            player:GossipComplete()
        end
    elseif intid == 2 then -- Eastern Kingdoms
        local playerGuid = player:GetGUIDLow()
        local azerothNodes = {82, 83, 1,2,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,43,45,56,66,67,68,70,71,74,75,76,78,84,85,86,87,195,224,315,352,377,383,384}
        local requiredCount = 31

        if hasAtLeastTaxiNodes(playerGuid, azerothNodes, requiredCount) then
            player:SendBroadcastMessage("You already have all Eastern Kingdoms flight paths.")
            player:GossipComplete()
        elseif player:HasItem(voteTokenItemId, voteTokenCost) then
            player:RemoveItem(voteTokenItemId, voteTokenCost)
            table.insert(playersToUpdate, {guid = playerGuid, logoutTime = os.time()})
            player:SendBroadcastMessage("You have purchased all Eastern Kingdoms flight paths. This process will log you out.")
            player:SaveToDB()
            player:LogoutPlayer()
            CreateLuaEvent(taxieasternkingdoms, logoutTimer, 1)
            player:GossipComplete()
        else
            player:SendBroadcastMessage("You do not have enough Vote Tokens.")
            player:GossipComplete()
        end
    elseif intid == 3 then -- Outland
        local playerGuid = player:GetGUIDLow()
        local azerothNodes = {99, 100, 101, 102, 111, 112, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 139, 140, 141, 142, 147, 149, 150, 151, 156, 159, 160, 163, 164, 171, 172, 205, 213}
        local requiredCount = 17

        if hasAtLeastTaxiNodes(playerGuid, azerothNodes, requiredCount) then
            player:SendBroadcastMessage("You already have all Outland flight paths.")
            player:GossipComplete()
        elseif player:HasItem(voteTokenItemId, voteTokenCost) then
            player:RemoveItem(voteTokenItemId, voteTokenCost)
            table.insert(playersToUpdate, {guid = playerGuid, logoutTime = os.time()})
            player:SendBroadcastMessage("You have purchased all Outland flight paths. This process will log you out.")
            player:SaveToDB()
            player:LogoutPlayer()
            CreateLuaEvent(taxioutland, logoutTimer, 1)
            player:GossipComplete()
        else
            player:SendBroadcastMessage("You do not have enough Vote Tokens.")
            player:GossipComplete()
        end
    end
end

RegisterCreatureGossipEvent(190095, 1, OnGossipHello)
RegisterCreatureGossipEvent(190095, 2, OnGossipSelect)