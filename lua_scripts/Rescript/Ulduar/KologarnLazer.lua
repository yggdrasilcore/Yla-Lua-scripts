local function LazerSpawn(event, creature)
	
	if creature:GetEntry() == 33802 then
		creature:NearTeleport(1767, -23, 448.80, 0)
		creature:SetHomePosition(1767, -23, 448.80, 0)
	else
		creature:NearTeleport(1770, -28, 448.80, 0)
		creature:SetHomePosition(1770, -28, 448.80, 0)
	end
	
    -- Find the nearest creature with entry ID 32930 (Kologarn)
    local kologarn = creature:GetNearestCreature(60, 32930)

    -- Get all players in range of Kologarn
    local playersInRange = kologarn:GetPlayersInRange(54, 1, 1)
    
    -- Initialize a variable to store the player farthest from Kologarn
    local maxrangeplayer = nil
    local maxDistance = 0
    
    -- Loop through all players in range to find the farthest one
    for _, player in pairs(playersInRange) do
        local distance = player:GetDistance(kologarn)
        if distance > maxDistance then
            maxDistance = distance
            maxrangeplayer = player
		end
    end
    
    -- If a player is found, make the creature follow the farthest player
    if maxrangeplayer then
		creature:SetInCombatWith(maxrangeplayer)
		creature:SetSpeed(0, 0.7)
		creature:SetSpeed(1, 0.7)
		
		if creature:GetEntry() == 33802 then
			creature:MoveFollow(maxrangeplayer, 1, 0.3)
		else
			creature:MoveFollow(maxrangeplayer, 1, 2.1)
		end
		
		creature:RegisterEvent(function(eventId, delay, repeats, creature)
		
		player = creature:GetNearestPlayer(20)
			if player:GetDifficulty() == 1 then
				creature:AddAura(63977, creature) -- 25-man eye aoe
			else
				creature:AddAura(63347, creature) -- 10-man eye aoe
			end
			
			if creature:GetEntry() == 33802 then
				creature:CastSpell(creature, 63702, true) -- Right beam
			else
				creature:CastSpell(creature, 63676, true) -- Left bea,
			end
		end, 1000, 1)
			
    end
end

-- Register the event for creatures with entry IDs 33802 and 33632
RegisterCreatureEvent(33802, 5, LazerSpawn)
RegisterCreatureEvent(33632, 5, LazerSpawn)
