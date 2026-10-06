-- Multistate: map-only script (all hooks fire in map states).
if not IsCompatibilityMode() and GetStateMapId() == -1 then return end

local function POSCombatEnd(event, player)
    if player:GetAreaId() == 4905 and player:GetNearestCreature(150, 36658, 0, 2) then
		player:RegisterEvent(function(eventId, delay, repeats, player)
            local Tyrannus = player:GetNearestCreature(150, 36658, 0, 1)
            local Rimefang = player:GetNearestCreature(150, 36661)
            
            if Tyrannus and Rimefang and not Rimefang:HasAura(46598) then
                Tyrannus:CastSpell(Rimefang, 46598, true)
            end
		end, 5000, 1)
    end
end

local function EnterScourgelordsCommand(event, player, oldArea, newArea)
    if newArea == 4905 then
		local Tyrannus = player:GetNearestCreature(150, 36658, 0, 1)
		local Rimefang = player:GetNearestCreature(150, 36661)
		
		if Tyrannus and Rimefang and not Rimefang:HasAura(46598) and not Tyrannus:IsInCombat() then
			Tyrannus:CastSpell(Rimefang, 46598, true)
		end
    end
end
        
local function POSCombat(event, player, enemy)
	if enemy and enemy:GetEntry() == 36877 then -- Wrathbone skeletons in cave
		local Tyrannus = player:GetNearestCreature(1000, 36658, 0, 1)
		local Rimefang = player:GetNearestCreature(1000, 36661)
		
		if Tyrannus and Rimefang and not Rimefang:HasAura(46598) then
			Tyrannus:CastSpell(Rimefang, 46598, true)
		end
	end
	if enemy and (enemy:GetEntry() == 36658) then -- Tyrannus        
		player:RegisterEvent(function(eventId, delay, repeats, player)
					
			local slaveGroups = {
			player:GetCreaturesInRange(500, 37572),
			player:GetCreaturesInRange(500, 37575),
			player:GetCreaturesInRange(500, 37576)
			}

			for _, group in ipairs(slaveGroups) do
				for _, slave in ipairs(group) do
					slave:SetFaction(1) 
				end
			end
			
		end, 7000, 1)
	end
end

RegisterPlayerEvent(33, POSCombat)
RegisterPlayerEvent(34, POSCombatEnd)
RegisterPlayerEvent(47, EnterScourgelordsCommand)