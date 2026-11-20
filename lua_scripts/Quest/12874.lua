-- Storm Peaks-only script (map 571): quest 12874 Fervor of the Frostborn (Hyldsmeet).
if GetStateMapId() ~= 571 then return end

local function OnEnterArea(event, player, oldArea, newArea)
    if newArea == 4428 then
        player:RegisterEvent(function(eventId, delay, repeats, player)
			local creature = player:GetNearestCreature(15, 29736)
			
			if player:GetAreaId() == 4428 then 
				if creature and player:HasQuest(12874) then
					player:CastSpell(creature, 46598)
					
					player:RegisterEvent(function(eventId, delay, repeats, player)
						local creature = player:GetNearestCreature(15, 29736)
						creature:SetHover(false)
						creature:SetDisableGravity(true)
						if not creature:HasAura(55971) then
							creature:AddAura(55971, creature)
						end
						player:RemoveEvents()
					end, 200, 1)
				end
			end		
		end, 1940, 0)
    end
	if oldArea == 4428 then
		player:RemoveEvents()
	end
end

RegisterPlayerEvent(47, OnEnterArea)
