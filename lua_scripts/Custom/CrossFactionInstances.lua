-- This ELUNA module sets the faction of all players in an instance to the same as the first player to enter it.
-- Written by mostly nick :) for Yggdrasil WoW

local cachedFaction = {}

local function OnPlayerMapChange(event, player)
    local instanceId = player:GetInstanceId()
    local mapId = player:GetMapId()
	
	if mapId == 631 or mapId == 658 
	or mapId == 632 or mapId == 668
	or mapId == 649 or mapId == 650
	
	then
		if instanceId and instanceId > 0 then
            if mapId == 631 then
                player:RegisterEvent(function(eventId, delay, repeats, player)
                    if player:GetNearestCreature(250, 37190) then -- Sets ICC to ally if ally NPCs present
                        cachedFaction[instanceId] = 1
                        player:SetFaction(cachedFaction[instanceId])
                        print("ICC, instance ID "..instanceId..": Ally ICC detected!")
                    elseif player:GetNearestCreature(250, 37189) then
                        cachedFaction[instanceId] = 2
                        player:SetFaction(cachedFaction[instanceId])
                        print("ICC, instance ID "..instanceId..": Horde ICC detected!")
                    else
                        print("ICC, instance ID "..instanceId..": No ICC faction detected - checking preexisting players...")
                        if not cachedFaction[instanceId] then
                            for _, otherPlayer in pairs(GetPlayersInWorld()) do
                                if otherPlayer:GetInstanceId() == instanceId and player:GetGUIDLow() ~= otherPlayer:GetGUIDLow() then -- Builds cache if there is none, in the event of an ELUNA reload
                                    cachedFaction[instanceId] = otherPlayer:GetFaction()
                                    if player:GetFaction() ~= cachedFaction[instanceId] then
                                        print("ICC, instance ID "..instanceId..": Cached faction found, setting player faction to "..cachedFaction[instanceId])
                                        player:SetFaction(cachedFaction[instanceId])
                                    end
                                    break
                                end
                            end
                            
                            if not cachedFaction[instanceId] then
                                print("ICC, instance ID "..instanceId..": No preexisting players detected, setting ICC faction to current player's faction")
                                cachedFaction[instanceId] = player:GetFaction()
                            end
                        else
                            if player:GetFaction() ~= cachedFaction[instanceId] then
                                player:SetFaction(cachedFaction[instanceId])
                            end
                        end
                    end
                    player:RemoveEventById(eventId)
                end, 500, 1)
            else
                if not cachedFaction[instanceId] then
                    for _, otherPlayer in pairs(GetPlayersInWorld()) do
                        if otherPlayer:GetInstanceId() == instanceId and player:GetGUIDLow() ~= otherPlayer:GetGUIDLow() then -- Builds cache if there is none, in the event of an ELUNA reload
                            cachedFaction[instanceId] = otherPlayer:GetFaction()
                            if player:GetFaction() ~= cachedFaction[instanceId] then
                                player:SetFaction(cachedFaction[instanceId])
                            end
                            break
                        end
                    end
                    
                    if not cachedFaction[instanceId] then
                        cachedFaction[instanceId] = player:GetFaction()
                    end
                else
                    if player:GetFaction() ~= cachedFaction[instanceId] then
                        player:SetFaction(cachedFaction[instanceId])
                    end
                end
            end
		end

    else
        if player and not (
        (player:GetRace() == 1 and player:GetFaction() == 1) or -- Human
        (player:GetRace() == 2 and player:GetFaction() == 2) or -- Orc
        (player:GetRace() == 3 and player:GetFaction() == 3) or -- Dwarf
        (player:GetRace() == 4 and player:GetFaction() == 4) or -- Night Elf
        (player:GetRace() == 5 and player:GetFaction() == 5) or -- Undead
        (player:GetRace() == 6 and player:GetFaction() == 6) or -- Tauren
        (player:GetRace() == 7 and player:GetFaction() == 115) or -- Gnome
        (player:GetRace() == 8 and player:GetFaction() == 116) or -- Troll
        (player:GetRace() == 10 and player:GetFaction() == 1610) or -- Blood elf
        (player:GetRace() == 11 and player:GetFaction() == 1629)) -- Draenei
        then
            print("Faction discrepancy detected, resetting player "..player:GetName().."! Current faction: "..player:GetFaction())
            player:SetFactionForRace(player:GetRace())
            print("Faction discrepancy detected, resetting player "..player:GetName().."! New faction: "..player:GetFaction())
        end
    end
end

RegisterPlayerEvent(28, OnPlayerMapChange)