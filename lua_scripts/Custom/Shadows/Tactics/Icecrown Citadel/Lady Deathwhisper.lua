local function LadyDeathwhisper10Loop(eventId, delay, repeats, deathwhisper)
    if deathwhisper:IsDead() or not deathwhisper:IsInCombat() then
        deathwhisper:RemoveEvents()
        deathwhisper:SetData("EventActive", nil)
        return
    end
    
    local darnavan = deathwhisper:GetNearestCreature(100, 38472, 0)
    
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

local function LadyDeathwhisper25Loop(eventId, delay, repeats, deathwhisper)
    if deathwhisper:IsDead() or not deathwhisper:IsInCombat() then
        deathwhisper:RemoveEvents()
        deathwhisper:SetData("EventActive", nil)
        return
    end
    
    local darnavan = deathwhisper:GetNearestCreature(100, 38485, 0)
    
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
            if player:GetDifficulty() == 0 or player:GetDifficulty() == 2 then
                enemy:RegisterEvent(LadyDeathwhisper10Loop, 2500, 20)
            elseif player:GetDifficulty() == 1 or player:GetDifficulty() == 3 then
                enemy:RegisterEvent(LadyDeathwhisper25Loop, 2500, 20)
            end
        end
    end
end

RegisterPlayerEvent(33, OnLadyDeathwhisperCombat)