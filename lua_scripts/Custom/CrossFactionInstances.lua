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
                print("ICC, faction adjustment script triggered!")
                player:RegisterEvent(function(eventId, delay, repeats, player)
                    if not cachedFaction[instanceId] then    
                        print("ICC, player "..player:GetName().." just entered! No faction cached for instance ID "..instanceId)
                        if player:HasAura(73822) then -- horde icc
                            player:SetFaction(1801) -- horde faction adjustment
                            cachedFaction[instanceId] = 1801
                            print("ICC, instance ID "..instanceId..": Horde ICC detected! Setting player faction to "..cachedFaction[instanceId])
                        elseif player:HasAura(73828) then -- ally icc
                            player:SetFaction(1802) -- ally  faction adjustment
                            cachedFaction[instanceId] = 1802
                            print("ICC, instance ID "..instanceId..": Ally ICC detected! Setting player faction to "..cachedFaction[instanceId])
                        end
                    else
                        print("ICC, player "..player:GetName().." just entered! Faction cached for instance ID "..instanceId..": "..cachedFaction[instanceId])
                        for _, playersInInstances in pairs(GetPlayersInWorld()) do
                            if playersInInstances:GetInstanceId() == instanceId then
                                print("ICC, instance ID "..instanceId..": Cached faction found, setting player faction to "..cachedFaction[instanceId])
                                player:SetFaction(35)
                                player:SetFaction(cachedFaction[instanceId])
                            end
                        end
                    end
                end, 500, 1)
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