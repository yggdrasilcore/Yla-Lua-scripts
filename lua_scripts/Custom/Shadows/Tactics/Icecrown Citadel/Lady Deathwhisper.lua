local function LadyDeathwhisperLoop(eventId, delay, repeats, deathwhisper)
    if deathwhisper:IsDead() or not deathwhisper:IsInCombat() then
        deathwhisper:RemoveEvents()
        deathwhisper:SetData("EventActive", nil)
        return
    end
    
    local darnavan = deathwhisper:GetNearestCreature(200, 38472, 0) or deathwhisper:GetNearestCreature(200, 38485, 0)
    
    if darnavan then
        local nearestPlayer = darnavan:GetNearestPlayer(200)
        if nearestPlayer then
            local group = nearestPlayer:GetGroup()
            if group then
                group:SetTargetIcon(4, darnavan:GetGUID(), nearestPlayer:GetGUID())
                deathwhisper:RemoveEvents()
                deathwhisper:SetData("EventActive", nil)
                return
            end
        end
    end
end

local function OnLadyDeathwhisperCombat(event, player, enemy)
    if enemy and enemy:GetEntry() == 36855 then
        if not enemy:GetData("EventActive") then
            enemy:SetData("EventActive", true)
            enemy:RegisterEvent(LadyDeathwhisperLoop, 1000, 600)
        end
    end
end

RegisterPlayerEvent(33, OnLadyDeathwhisperCombat)