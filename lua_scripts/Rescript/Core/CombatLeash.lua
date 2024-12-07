local function CombatLeash(event, player, enemy)
    if not 
    (
    player:GetMapId() == 0 or
    player:GetMapId() == 1 or
    player:GetMapId() == 530 or
    player:GetMapId() == 571
    )
    then
        return
    end
    
    local mobs = player:GetCreaturesInRange(50)
    local NPCsNearby = false
    for _, mob in pairs(mobs) do
        NPCsNearby = true
        -- Initialize HP tracking for each mob
        mob:SetData("LeashPct", mob:GetHealthPct())
        break
    end
    
    if not NPCsNearby then
        print("[Combat Leash Fix]: No NPCs nearby. Exiting combat leash.")
        return
    end
    
    local startPos = {
        x = player:GetX(),
        y = player:GetY(),
        z = player:GetZ()
    }
    print("[Combat Leash Fix]: Start position recorded:", startPos.x, startPos.y, startPos.z)
    
    player:RegisterEvent(function(eventId, delay, repeats, player)
        print("[Combat Leash Fix]: Registered event triggered. Checking conditions...")
        if not player:IsInCombat() then
            print("[Combat Leash Fix]: Player is not in combat.")
            player:RemoveEventById(eventId)
            return
        end
        
        if player:GetDistance(startPos.x, startPos.y, startPos.z) <= 80 then
            print("[Combat Leash Fix]: Player is within 50 units of start position. No action needed.")
            return
        end
        
        local mobs = player:GetCreaturesInRange(50)
        local NPCsNearby = false
        local anyDamageTaken = false
        local mobsToLeash = {}
        
        for _, mob in pairs(mobs) do
            NPCsNearby = true
            local currentHpPct = mob:GetHealthPct()
            local previousHpPct = mob:GetData("LeashPct") or currentHpPct
            
            if not (mob:IsInCombat() and mob:GetSelection() == player) then
                return
            end
            
            -- Check if mob took damage since last check
            if currentHpPct < previousHpPct then
                anyDamageTaken = true
            end
            
            -- Update stored HP percentage
            mob:SetData("LeashPct", currentHpPct)
            
            -- Track mobs that are too far from home
            local homeX, homeY, homeZ = mob:GetHomePosition()
            if mob:GetDistance(homeX, homeY, homeZ) > 100 then
                table.insert(mobsToLeash, mob)
            end
        end
        
        -- Only clear threat lists if no damage was taken and mobs are too far
        if not anyDamageTaken and #mobsToLeash > 0 then
            print("[Combat Leash Fix]: No damage taken, clearing threat lists for out-of-range mobs")
            for _, mob in pairs(mobsToLeash) do
                mob:ClearThreatList()
            end
        end
        
        if not NPCsNearby then
            print("[Combat Leash Fix]: No NPCs nearby. Removing event.")
            player:RemoveEventById(eventId)
        end
    end, 15000, 0)
end

RegisterPlayerEvent(33, CombatLeash)