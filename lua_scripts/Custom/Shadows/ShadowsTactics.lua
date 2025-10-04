-- HOR TACTICS

function OnEnterHOR(event, player)
	if not player:GetMapId() == 668 then return end
	
	local LK = player:GetNearestCreature(4000, 36954)
	
	if LK then
		local group = player:GetGroup()
		
		if group then
			group:SetTargetIcon(4, LK:GetGUID(), player:GetGUID())
		end
	end
end

RegisterPlayerEvent(28, OnEnterHOR)


--- END HOR TACTICS

-- SINDY TOMB TWEAK

function CombatCheck(eventId, delay, repeats, sindragosa)
    if sindragosa:IsDead() or not sindragosa:IsInCombat() then
		sindragosa:SetData("SindyEventOn", nil)
        RemoveEventById(eventId)
        return
    end
   
   if sindragosa:GetZ() > 217 then
       local iceTargets = sindragosa:GetCreaturesInRange(1000, 36980)
       
       if #iceTargets > 0 then
           local player = sindragosa:GetNearestPlayer(1000, 0, 1)
           
           if player then
               local hasDebuff = player:HasAura(70084) or player:HasAura(71050) or 
                                 player:HasAura(71051) or player:HasAura(71052)
               
               local group = player:GetGroup()
               if group then
                   for i = 1, #iceTargets do
                       if not hasDebuff and iceTargets[i]:GetHealthPct() < 30 then
						   if iceTargets[i]:GetData("MoonSet") then return end
						   iceTargets[i]:SetData("MoonSet", true)
                           group:SetTargetIcon(4, iceTargets[i]:GetGUID(), player:GetGUID())
                       elseif hasDebuff then
						   if iceTargets[i]:GetData("SkullSet") then return end
						   iceTargets[i]:SetData("SkullSet", true)
                           group:SetTargetIcon(7, iceTargets[i]:GetGUID(), player:GetGUID())
                       end
                   end
               end
           end
       end
       return
   end
   
   if not (sindragosa:GetZ() < 217) then return end
   
   local target = sindragosa:GetVictim()
   if not target or not target:ToPlayer() then return end
   
   target:AddAura(64556, target)
end

function OnSindyCombat(event, player, enemy)
    if enemy and enemy:GetEntry() == 36853 then
		if not enemy:GetData("SindyEventOn") then
			enemy:SetData("SindyEventOn", true)
			enemy:RegisterEvent(CombatCheck, 1000, 0)
		end
    end
end

RegisterPlayerEvent(33, OnSindyCombat)

-- END SINDY TOMB TWEAK

-- START RAID ICONS SHADOW HANDLING

local function RemoveRaidIconsOnDeath(event, obj1, player)
	if event == 8 and not isPlayerBot[player:GetName()] then return end -- Ensures we don't process player death twice as this is in event 7 (packet) anyway
	
    local group = player:GetGroup()
    if not group then return end
    
    local members = group:GetMembers()
    for _, member in pairs(members) do
        if member:IsAlive() and member:IsInCombat() then
            local distance = player:GetDistance(member)
            if distance <= 100 then
                return
            end
        end
    end
    
	--[[
    local hasBots = false
    for _, member in pairs(members) do
        local memberName = member:GetName()
        if activeBots[memberName] then
            hasBots = true
            break
        end
    end
    
    if not hasBots then return end
    --]]
	
	group:SetTargetIcon(7, 0, player:GetGUID())
end

RegisterPacketEvent(0x269, 7, RemoveRaidIconsOnDeath) -- This captures all player deaths but packet events don't work on shadows, 
RegisterPlayerEvent(8, RemoveRaidIconsOnDeath) -- This works for all creature kills but not other death (shadows can only be killed by creatures, not gravity/drowning etc.)

-- END RAID ICONS SHADOW HANDLING