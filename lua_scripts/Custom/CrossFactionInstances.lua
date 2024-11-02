-- This ELUNA module sets the faction of all players in an instance to the same as the first player to enter it.
-- Written by mostly nick :) for Yggdrasil WoW

local cachedFaction = {}

local function OnPlayerMapChange(event, player)
    local instanceId = player:GetInstanceId()
    local mapId = player:GetMapId()
	
	if mapId == 631 or mapId == 658 
	or mapId == 632 or mapId == 668
	--or mapId == 649 or mapId == 650 -- TOC and TOGC; not supported under current implementation
	
	then
		if instanceId and instanceId > 0 then
            print("Faction adjustment script triggered!")
            player:RegisterEvent(function(eventId, delay, repeats, player)
                if not cachedFaction[instanceId] then    
                    print("Player "..player:GetName().." just entered map ID "..mapId.."! No faction cached for instance ID "..instanceId)
                    
                    if (mapId == 631 and player:HasAura(73822))
                    or (mapId == 632 and player:GetNearestCreature(1000, 37596))
                    or (mapId == 658 and player:GetNearestCreature(1000, 36990))
                    or (mapId == 668 and player:GetNearestCreature(1000, 37223))
                    then -- ally instance. 73822 is horde icc buff. maps 632, 658, and 668 are Sylvanas Windrunner
                        player:SetFaction(1801) -- horde faction adjustment
                        cachedFaction[instanceId] = 1801
                        print("ICC, instance ID "..instanceId..": Horde instance detected! Setting player faction to "..cachedFaction[instanceId])
                    elseif (mapId == 631 and player:HasAura(73828))
                    or (mapId == 632 and player:GetNearestCreature(1000, 37597))
                    or (mapId == 658 and player:GetNearestCreature(1000, 36993))
                    or (mapId == 668 and player:GetNearestCreature(1000, 37221))
                    then -- ally instance. 73828 is ally icc buff. maps 632, 658, and 668 are Lady Jaina Proudmoore
                        player:SetFaction(1802) -- ally  faction adjustment
                        cachedFaction[instanceId] = 1802
                        print("ICC, instance ID "..instanceId..": Ally instance detected! Setting player faction to "..cachedFaction[instanceId])
                    end
                    
                else
                    print("ICC, player "..player:GetName().." just entered map ID "..mapId.."! Faction cached for instance ID "..instanceId..": "..cachedFaction[instanceId])
                    for _, playersInInstances in pairs(GetPlayersInWorld()) do
                        if playersInInstances:GetInstanceId() == instanceId then
                            print("ICC, instance ID "..instanceId..": Cached faction found, setting player faction to "..cachedFaction[instanceId])
                            playersInInstances:SetFaction(35)
                            playersInInstances:SetFaction(cachedFaction[instanceId])
                        end
                    end
                end
            end, 500, 1)
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