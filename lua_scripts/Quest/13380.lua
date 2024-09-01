local playersInArea = {}
local checkEventId = nil

local function ScanAndDespawn()
    local playerCount = 0
    for name, _ in pairs(playersInArea) do
        local player = GetPlayerByName(name)
        if player and player:IsInWorld() then
            local nearGargoyles = player:GetCreaturesInRange(150, 32769) -- Gargoyle Ambusher npc ID
            for _, gargoyle in ipairs(nearGargoyles) do
                gargoyle:MoveChase(player)
            end
            playerCount = playerCount + 1
        else
            playersInArea[name] = nil
        end
    end
    
    if playerCount == 0 then
        if checkEventId then
            RemoveEventById(checkEventId)
            checkEventId = nil
        end
    end
end

local function OnAreaTrigger(event, player, newZone, newArea)
    if newArea == 4509 then -- The bombardment
        local allyPlane = player:GetNearestCreature(25, 31406) -- ally NPC
        local hordePlane = player:GetNearestCreature(25, 31838) -- horde NPC
        
        if allyPlane or hordePlane then
            playersInArea[player:GetName()] = true
            
            if not checkEventId then
                checkEventId = CreateLuaEvent(ScanAndDespawn, 5000, 0) -- Run every 5 seconds indefinitely
				print("Event ID ".. checkEventId .." launched to check quest ID 13380 for player "..player:GetName())
            end
        end
    else
        playersInArea[player:GetName()] = nil
    end
end

RegisterPlayerEvent(27, OnAreaTrigger)