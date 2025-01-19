local evadeRange = 70 -- range for creatures to evade
local debugprint = 0

local function CombatLeash(event, player, enemy)
    if not (
        player:GetMapId() == 0 or
        player:GetMapId() == 1 or
        player:GetMapId() == 530 or
        player:GetMapId() == 571
    ) then
        return
    end

    local mobs = player:GetCreaturesInRange(evadeRange)
    local NPCsNearby = false
    for _, mob in pairs(mobs) do
        NPCsNearby = true
        -- Initialize HP tracking for each mob
        mob:SetData("LeashPct", mob:GetHealthPct())
        break
    end

    if not NPCsNearby then
        if debugprint == 1 then
            print("[Combat Leash Fix]: No NPCs nearby. Exiting combat leash.")
        end
        return
    end

    local startPos = {
        x = player:GetX(),
        y = player:GetY(),
        z = player:GetZ()
    }
    if debugprint == 1 then
        print("[Combat Leash Fix]: Start position recorded:", startPos.x, startPos.y, startPos.z)
    end

    player:RegisterEvent(function(eventId, delay, repeats, player)
        if debugprint == 1 then
            print("[Combat Leash Fix]: Registered event triggered. Checking conditions...")
        end
        if not player:IsInCombat() then
            if debugprint == 1 then
                print("[Combat Leash Fix]: Player is not in combat.")
            end
            player:RemoveEventById(eventId)
            return
        end

        if debugprint == 1 then
            print("[Combat Leash Fix]: Player is in combat. Checking distance from start position...")
        end
        if player:GetDistance(startPos.x, startPos.y, startPos.z) <= evadeRange then
            if debugprint == 1 then
                print("[Combat Leash Fix]: Player "..player:GetName().." is within 50 units of start position. No action needed.")
            end
            return
        end

        if debugprint == 1 then
            print("[Combat Leash Fix]: Player is outside the evade range. Checking nearby mobs...")
        end
        local mobs = player:GetCreaturesInRange(evadeRange)
        local NPCsNearby = false
        local anyDamageTaken = false
        local mobsToLeash = {}

        for _, mob in pairs(mobs) do
            if debugprint == 1 then
                print("[Combat Leash Fix]: Checking mob "..mob:GetName().."...")
            end
            if not mob:GetAITarget(1, true) == player then
                if debugprint == 1 then
                    print("Taking no action as mob isn't targeting player")
                end
                return
            end
            NPCsNearby = true

            local currentHpPct = mob:GetHealthPct()
            local previousHpPct = mob:GetData("LeashPct") or currentHpPct

            if not mob:IsInCombat() then
                if debugprint == 1 then
                    print("Mob "..mob:GetName().." isn't in combat, returning")
                end
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
            if mob:GetDistance(homeX, homeY, homeZ) > evadeRange then
                table.insert(mobsToLeash, mob)
            end
        end

        -- Only clear threat lists if no damage was taken and mobs are too far
        if not anyDamageTaken and #mobsToLeash > 0 then
            if debugprint == 1 then
                print("[Combat Leash Fix]: No damage taken, clearing threat lists for out-of-range mobs")
            end
            for _, mob in pairs(mobsToLeash) do
                mob:ClearThreatList()
            end
        end

        if not NPCsNearby and player:IsInCombat() then
            if debugprint == 1 then
                print("[Combat Leash Fix]: No NPCs nearby. Removing event.")
            end
            player:SetData("cbstoptime", os.time())
            player:RunCommand("combatstop")
            player:RemoveEventById(eventId)
        end
    end, 15000, 0)

end

RegisterPlayerEvent(33, CombatLeash)

local function OnCommand(event, player, command)
    if command:lower() == "combatstop" then
        local gmRank = player:GetGMRank()
        local cbstoptime = player:GetData("cbstoptime")
        local currentTime = os.time()
        if gmRank > 2 then
            if debugprint == 1 then
                print("Permitting combatstop command for "..player:GetName())
            end
            return true
        end
        if not (cbstoptime and math.abs(currentTime - cbstoptime) <= 2) then
            if debugprint == 1 then
                print("Denying combatstop command for "..player:GetName())
            end
            return false
        end
        if debugprint == 1 then
            print("Permitting combatstop command for "..player:GetName())
        end
        return true
    end
end

RegisterPlayerEvent(42, OnCommand)
