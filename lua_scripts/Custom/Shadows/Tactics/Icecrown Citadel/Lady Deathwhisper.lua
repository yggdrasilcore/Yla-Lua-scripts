local function LadyDeathwhisperLoop(eventId, delay, repeats, deathwhisper)
    if deathwhisper:IsDead() or not deathwhisper:IsInCombat() then
        StopLuaEvent(deathwhisper)
        return
    end
    
    local darnavan = deathwhisper:GetNearestCreature(1000, 38472, 0) or deathwhisper:GetNearestCreature(1000, 38485, 0)
    
    if darnavan then
        local nearestPlayer = darnavan:GetNearestPlayer(1000)
        if nearestPlayer then
            local group = nearestPlayer:GetGroup()
            if group then
                group:SetTargetIcon(4, darnavan:GetGUID(), nearestPlayer:GetGUID())
                StopLuaEvent(deathwhisper)
                return
            end
        end
    end
    
    deathwhisper:RegisterEvent(LadyDeathwhisperLoop, 1000, 30)
end

local function OnLadyDeathwhisperCombat(event, player, enemy)
    if enemy and enemy:GetEntry() == 36855 then
        StartLuaEvent(enemy, LadyDeathwhisperLoop)
    end
end

RegisterPlayerEvent(33, OnLadyDeathwhisperCombat)