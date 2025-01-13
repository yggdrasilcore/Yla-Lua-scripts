local function OnEnterCombat(event, player, enemy)
    if not enemy then 
        return 
    end
    
    -- Check if player is in specific area (Frozen Throne platform)
    if not (player:GetAreaId() == 4859) then 
        return 
    end
    
    -- Check for Lich King and his combat state
    local LK = player:GetNearestCreature(1000, 36597)
    if LK and not LK:IsInCombat() then
        print("Player " .. player:GetName() .. " just entered combat on LK platform, but LK not active! Enemy: " .. enemy:GetEntry())
        
        -- Get and despawn nearby creatures with specific IDs
        local creatureIds = {37698, 36633, 36701, 37799, 39190}
        for _, id in ipairs(creatureIds) do
            local creatures = player:GetCreaturesInRange(1000, id)
            if creatures then
                for _, creature in ipairs(creatures) do
                    creature:DespawnOrUnsummon(0)
                end
            end
        end
    end
end

RegisterPlayerEvent(33, OnEnterCombat)