if GetStateMapId() ~= 631 then return end

local sindyEventOn = false

function CombatCheck(eventId, delay, repeats, sindragosa)
    if sindragosa:IsDead() or not sindragosa:IsInCombat() then
        sindyEventOn = false
        RemoveEventById(eventId)
        return
    end
    
    local target = sindragosa:GetVictim()
    if target and target:ToPlayer() then
        local player = target:ToPlayer()
        local name = player:GetName()
        if player:IsBot() and IsTank(player) then
            local px, py = player:GetX(), player:GetY()
            local sx, sy = sindragosa:GetX(), sindragosa:GetY()
            
            if px >= 4403 and px <= 4412 and py >= 2481 and py <= 2510 then
                if not (sx >= 4403 and sx <= 4412 and sy >= 2481 and sy <= 2510) then
                    sindragosa:MoveTo(0, 4408, 2484, 203.37) -- Corrects Sindy's position if mispositioned by tank
                end
            end
        end
        
        target:AddAura(64556, target) -- Prevents tank from being knocked back by erroneous tail swipe pathing
    end
    
    if sindragosa:GetX() > 4475 then -- Spaces out tombs in case shadows stack them
        local playersInRange = sindragosa:GetPlayersInRange(100)
        local botsWithAura = {}
        
		for _, player in pairs(playersInRange) do
			local name = player:GetName()
			if player:IsBot() then
				local hasMarked = player:HasAura(70126)
				local hasIced = player:HasAura(70157)
				local aura = player:GetAura(70126)
				local duration = aura and aura:GetDuration() or 0
				
				print("Bot: " .. name .. " | Marked: " .. tostring(hasMarked) .. " | Iced: " .. tostring(hasIced) .. " | Duration: " .. duration)
        
				if hasMarked and not hasIced and aura and duration < 2000 then
					table.insert(botsWithAura, player)
				end
			end
		end
        
		for i = 1, #botsWithAura do
			local bot1 = botsWithAura[i]
			for j = i + 1, #botsWithAura do
				local bot2 = botsWithAura[j]
				local distance = bot1:GetDistance(bot2)
				
				if distance <= 7 then
					local name1 = bot1:GetName()
					local name2 = bot2:GetName()
					local playerToMove = name1 < name2 and bot1 or bot2
					
					print("Distance between " .. name1 .. " and " .. name2 .. ": " .. distance)
					print("Moving: " .. playerToMove:GetName() .. " to X: " .. (playerToMove:GetX() - 10) .. " Y: " .. playerToMove:GetY() .. " Z: " .. playerToMove:GetZ())
					
					UseSpeedBuff(playerToMove)
					playerToMove:MoveTo(0, playerToMove:GetX() - 10, playerToMove:GetY(), playerToMove:GetZ())
					return
				end
			end
		end
    end
    
	if sindragosa:GetX() < 4475 then -- Helps damage Frost Tombs
		local iceTargets = sindragosa:GetCreaturesInRange(1000, 36980)
		local currentTime = os.time()
		local raidDifficulty = sindragosa:GetMap():GetDifficulty()
		local healthPct = sindragosa:GetHealthPct()
		
		for i = 1, #iceTargets do
			local tomb = iceTargets[i]
			local shouldDamage = false
			
			if healthPct > 35 then
				shouldDamage = true
			else
				if not tomb:Data():Get("TombTime") then
					tomb:Data():Set("TombTime", currentTime)
				end
				
				local tombAge = currentTime - tomb:Data():Get("TombTime")
				if tombAge > 9 then
					shouldDamage = true
				end
			end
			
			if shouldDamage then
				local playersNearTomb = tomb:GetPlayersInRange(10)
				
				for _, player in pairs(playersNearTomb) do
					if player:IsBot() then
						local lastDamageTime = player:Data():Get("LastTombDamage") or 0
						
						if currentTime - lastDamageTime >= 1.5 then
							local nearestTomb = player:GetNearestCreature(10, 36980, 0)
							
							if nearestTomb then
								local baseDamage = nearestTomb:GetMaxHealth() * (math.random() * 0.01 + 0.015)
								
								if raidDifficulty == 0 or raidDifficulty == 2 then -- 10-man raid
									player:DealDamage(nearestTomb, baseDamage)
								else -- 25-man raid
									player:DealDamage(nearestTomb, baseDamage * 1.5)
								end
								
								player:Data():Set("LastTombDamage", currentTime)
							end
						end
					end
				end
			end
		end
	end
end

function OnSindyCombat(event, player, enemy)
    if enemy and enemy:GetEntry() == 36853 then
        if not sindyEventOn then
            sindyEventOn = true
            enemy:RegisterEvent(CombatCheck, 300, 0)
        end
    end
end

RegisterPlayerEvent(33, OnSindyCombat)