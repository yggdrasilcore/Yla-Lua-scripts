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
        for _, mob in pairs(mobs) do
            NPCsNearby = true
            local homeX, homeY, homeZ = mob:GetHomePosition()
            if mob:IsInCombat() and mob:GetDistance(homeX, homeY, homeZ) > 100 then
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
