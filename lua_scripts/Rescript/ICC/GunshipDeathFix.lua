local function GunshipRemoved(event, packet, player)
    if player:GetMapId() == 631 then
        -- Get player position
        local x = player:GetX()
        local y = player:GetY()
        local z = player:GetZ()
        
        -- Define both target locations
        local location1 = {x = -108, y = 2601, z = 451}
        local location2 = {x = -55, y = 1992, z = 619}
        
        -- Calculate distances to both points
        local distance1 = math.sqrt(
            (x - location1.x) * (x - location1.x) +
            (y - location1.y) * (y - location1.y) +
            (z - location1.z) * (z - location1.z)
        )
        
        local distance2 = math.sqrt(
            (x - location2.x) * (x - location2.x) +
            (y - location2.y) * (y - location2.y) +
            (z - location2.z) * (z - location2.z)
        )
        
        -- Check if within 50 yards of either location
        if distance1 <= 50 or distance2 <= 50 then
            player:CastSpell(player, 7, true)
        end
    end
    
    return false
end

RegisterPacketEvent(0x38D, 5, GunshipRemoved)