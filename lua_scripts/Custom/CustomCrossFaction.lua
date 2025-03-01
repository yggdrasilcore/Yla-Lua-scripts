-------------------------------------------------------------------------------------------------------------------
-- This ELUNA module sets the faction of all players in an instance to the same as the first player to enter it.
-- Written by mostly nick :) for Yggdrasil WoW
-------------------------------------------------------------------------------------------------------------------

local cachedFaction = {}

local function OnPlayerMapChange(event, map, player)
    local instanceId = player:GetInstanceId()
    local mapId = player:GetMapId()
    local name = player:GetName()
	
	if (mapId == 631 or mapId == 658 -- ICC and the Frozen Halls maps
	or mapId == 632 or mapId == 668) -- The Frozen Halls maps
	then
        if instanceId and instanceId > 0 then
            player:RegisterEvent(function(eventId, delay, repeats, player)
                if not cachedFaction[instanceId] then
                    -- local map = player:GetMap()
                    -- if map then map:SaveInstanceData() end
                    -- First check if faction exists in DB using async query
                    CharDBQueryAsync(string.format("SELECT faction FROM instance WHERE id = %d", instanceId), function(result)
						local player = GetPlayerByName(name)
						if result and (result:GetUInt32(0) > 0) then
							-- Faction found in DB, use it
							cachedFaction[instanceId] = result:GetUInt32(0)
							print("ICC, instance ID "..instanceId..": Loaded faction "..cachedFaction[instanceId].." from DB")
						else
							-- Determine faction from creatures/auras as before
							if (mapId == 631 and (player:GetNearestCreature(1000, 39372) or player:GetNearestCreature(20000, 37187)))
							or (mapId == 632 and player:GetNearestCreature(1000, 37596))
							or (mapId == 658 and player:GetNearestCreature(1000, 36990))
							or (mapId == 668 and player:GetNearestCreature(1000, 37223))
							or (mapId == 631 and player:HasAura(73822))
							then -- horde instance
								cachedFaction[instanceId] = 1801
								-- Store in DB
								CharDBExecute("UPDATE instance SET faction = "..cachedFaction[instanceId].." WHERE id = "..instanceId)
								print("ICC, instance ID "..instanceId..": Horde instance detected! Setting player faction to horde.")
								if player:IsAlliance() then
									player:SetFaction(1801)
								end
							elseif (mapId == 631 and (player:GetNearestCreature(1000, 39372) or player:GetNearestCreature(20000, 37200)))
							or (mapId == 632 and player:GetNearestCreature(1000, 37597))
							or (mapId == 658 and player:GetNearestCreature(1000, 36993))
							or (mapId == 668 and player:GetNearestCreature(1000, 37221))
							or (mapId == 631 and player:HasAura(73828))
							then -- ally instance
								cachedFaction[instanceId] = 1802
								-- Store in DB
								CharDBExecute("UPDATE instance SET faction = "..cachedFaction[instanceId].." WHERE id = "..instanceId)
								print("ICC, instance ID "..instanceId..": Ally instance detected! Setting player faction to alliance.")
								if not player:IsAlliance() then
									player:SetFaction(1802)
								end
							end
						end

						-- Move the faction handling code inside the callback since we need the faction to be determined
						print("ICC Xfac - player "..player:GetName().." just entered map ID "..mapId.."! Instance faction: "..instanceId..": "..cachedFaction[instanceId])
						for _, playersInInstances in pairs(GetPlayersInWorld()) do
							if playersInInstances:GetInstanceId() == instanceId then
								if cachedFaction[instanceId] == 1801 and playersInInstances:IsAlliance() then
									playersInInstances:SetFaction(35)
									playersInInstances:SetFaction(1801)
									print("Player name: "..playersInInstances:GetName().." is ally, setting to horde faction 1801.")
								elseif cachedFaction[instanceId] == 1802 and not playersInInstances:IsAlliance() then
									playersInInstances:SetFaction(35)
									playersInInstances:SetFaction(1802)
									print("Player name: "..playersInInstances:GetName().." is horde, setting to alliance faction 1802.")
								else
									playersInInstances:SetFaction(35)
									playersInInstances:SetFactionForRace(playersInInstances:GetRace())
								end
							end
						end
					end)
                else
                    -- If faction is already cached, handle faction changes immediately
                    print("ICC Xfac - player "..player:GetName().." just entered map ID "..mapId.."! Instance faction: "..instanceId..": "..cachedFaction[instanceId])
                    for _, playersInInstances in pairs(GetPlayersInWorld()) do
                        if playersInInstances:GetInstanceId() == instanceId then
                            if cachedFaction[instanceId] == 1801 and playersInInstances:IsAlliance() then
                                playersInInstances:SetFaction(35)
                                playersInInstances:SetFaction(1801)
                                print("Player name: "..playersInInstances:GetName().." is ally, setting to horde faction 1801.")
                            elseif cachedFaction[instanceId] == 1802 and not playersInInstances:IsAlliance() then
                                playersInInstances:SetFaction(35)
                                playersInInstances:SetFaction(1802)
                                print("Player name: "..playersInInstances:GetName().." is horde, setting to alliance faction 1802.")
                            else
                                playersInInstances:SetFaction(35)
                                playersInInstances:SetFactionForRace(playersInInstances:GetRace())
                            end
                        end
                    end
                end
            end, 500, 1)
        end
    elseif isPlayerBot[player:GetName()]
    and not map:IsBattleground()
    and not map:IsArena()
    then -- Faction adjustment for bots on xfac bot 
        master = GetPlayerByName(isPlayerBot[player:GetName()])
        if not master then -- Don't adjust if player isn't accessible; assume bot's faction was already adjusted on initial spawn
            return
        end
        if (master:GetRace() == 1
        or master:GetRace() == 3 or master:GetRace() == 4
        or master:GetRace() == 7 or master:GetRace() == 11)
        then -- Alliance master
            if (player:GetRace() == 1 or player:GetRace() == 3
            or player:GetRace() == 4 or player:GetRace() == 7
            or player:GetRace() == 11) 
            then
                return -- Bot is already alliance, do nothing
            else
                player:SetFaction(1802)
            end
        else -- Horde master
            if (player:GetRace() == 2 or player:GetRace() == 5
            or player:GetRace() == 6 or player:GetRace() == 8
            or player:GetRace() == 10)
            then
                return -- Bot is already horde, do nothing
            else
                player:SetFaction(1801)
            end
        end
    else
		if not (player:GetFaction() == 1801 or player:GetFaction() == 1802) then return end
        if not (
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

function CacheCurrentInstances()
    local validMaps = {631, 632, 658, 668}
    local allianceFactions = {1, 3, 4, 115, 1629, 1802}
    
    local function isValidMap(mapId)
        for _, validMap in pairs(validMaps) do
            if mapId == validMap then
                return true
            end
        end
        return false
    end
    
    local function isAllianceFaction(factionId)
        for _, allianceFaction in pairs(allianceFactions) do
            if factionId == allianceFaction then
                return true
            end
        end
        return false
    end
    
    for _, player in pairs(GetPlayersInWorld()) do
        local instanceId = player:GetInstanceId()
        local mapId = player:GetMapId()
        
        if instanceId > 0 and isValidMap(mapId) then
            if not cachedFaction[instanceId] then
                for _, instancePlayer in pairs(GetPlayersInWorld()) do
                    if instancePlayer:GetInstanceId() == instanceId then
                        local faction = instancePlayer:GetFaction()
                        
                        if isAllianceFaction(faction) then
                            cachedFaction[instanceId] = 1802 -- Alliance
                            print("Instance ID "..instanceId..": Cached as Alliance (1802)")
                            break
                        else
                            cachedFaction[instanceId] = 1801 -- Horde
                            print("Instance ID "..instanceId..": Cached as Horde (1801)")
                            break
                        end
                    end
                end
            end
        end
    end
end


-------------------------------------------------------------------------------------------------------------------
-- End custom Xfac
-------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------
-- Faction adjustment event registrations
------------------------------------------------------------------------------------------------

CacheCurrentInstances()
RegisterServerEvent(21, OnPlayerMapChange)

------------------------------------------------------------------------------------------------
-- End faction adjustment event registrations
------------------------------------------------------------------------------------------------
