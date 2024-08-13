local coveredMaps = 631 -- 631 is ICC

local playerCombat = {}

local function CheckCombatStatus(eventId, delay, repeats, player)
    local guid = player:GetGUIDLow()
    if playerCombat[guid] and player:IsInCombat() and player:GetMapId() == coveredMaps then
        if playerCombat[guid] <= os.time() then
            local allFullHealth = true
            
            if player:GetHealthPct() < 100 then
                allFullHealth = false
				print("Player does NOT have full HP!")
			end
            
            local group = player:GetGroup()
            if group then
                for _, member in pairs(group:GetMembers()) do
                    if member:GetHealthPct() < 100 then
                        allFullHealth = false
                        break
                    end
                end
            end
            
            if allFullHealth then
				print("Resetting combat!")
				local creatures = player:GetCreaturesInRange(200)
				for _, creature in pairs(creatures) do
					if creature:IsInCombat() then
						oldDelay = creature:GetRespawnDelay()
						creature:SetRespawnDelay(1)
						creature:DespawnOrUnsummon()
						creature:SetRespawnDelay(oldDelay)
					end
				end
				
				player:ClearInCombat()
                playerCombat[guid] = nil
            end
        end
    elseif not player:IsInCombat() or not player:GetMapId() == coveredMaps then
        playerCombat[guid] = nil
		player:RemoveEvents()
    end
end

local function OnEnterCombat(event, player, enemy)
    local guid = player:GetGUIDLow()
    playerCombat[guid] = os.time() + 5 * 60
    player:RegisterEvent(CheckCombatStatus, 5000, 60)
	print("Calling anti combat bug function!")
end

--RegisterPlayerEvent(33, OnEnterCombat)
