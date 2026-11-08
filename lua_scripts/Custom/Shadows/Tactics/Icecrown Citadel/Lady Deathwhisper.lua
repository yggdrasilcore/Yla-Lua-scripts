if GetStateMapId() ~= 631 then return end

local LADY_DEATHWHISPER_ENTRY = 36855

local function LadyDeathwhisper10Loop(eventId, delay, repeats, deathwhisper)
    if deathwhisper:IsDead() or not deathwhisper:IsInCombat() then
        deathwhisper:RemoveEvents()
        deathwhisper:Data():Set("EventActive", nil)
        return
    end
    
    local darnavan = deathwhisper:GetNearestCreature(100, 38472, 0)
    
    if darnavan then
        local nearestPlayer = darnavan:GetNearestPlayer(200)
        if nearestPlayer then
            SetTargetIconDeferred(nearestPlayer, 4, darnavan)
            deathwhisper:RemoveEvents()
            deathwhisper:Data():Set("EventActive", nil)
            return
        end
    end
end

local function LadyDeathwhisper25Loop(eventId, delay, repeats, deathwhisper)
    if deathwhisper:IsDead() or not deathwhisper:IsInCombat() then
        deathwhisper:RemoveEvents()
        deathwhisper:Data():Set("EventActive", nil)
        return
    end
    
    local darnavan = deathwhisper:GetNearestCreature(100, 38485, 0)
    
    if darnavan then
        local nearestPlayer = darnavan:GetNearestPlayer(200)
        if nearestPlayer then
            SetTargetIconDeferred(nearestPlayer, 4, darnavan)
            deathwhisper:RemoveEvents()
            deathwhisper:Data():Set("EventActive", nil)
            return
        end
    end
end

local function OnLadyDeathwhisperCombat(event, player, enemy)
    if enemy and enemy:GetEntry() == LADY_DEATHWHISPER_ENTRY then
        if not enemy:Data():Get("EventActive") then    
            enemy:Data():Set("EventActive", true)
            if player:GetDifficulty() == 0 or player:GetDifficulty() == 2 then
                enemy:RegisterEvent(LadyDeathwhisper10Loop, 2500, 20)
            elseif player:GetDifficulty() == 1 or player:GetDifficulty() == 3 then
                enemy:RegisterEvent(LadyDeathwhisper25Loop, 2500, 20)
            end
        end
    end
end

RegisterPlayerEvent(33, OnLadyDeathwhisperCombat)


-- Move stuck bots after killing LDW adds and not LOS to LDW
local function LadyDeathwhisperLosLoop(eventId, delay, repeats, player)
    if player:GetMapId() ~= 631 then player:RemoveEventById(eventId) return end
    if player:GetZ() > 130 then player:RemoveEventById(eventId) return end

    local ldw = player:GetSelection()
    if ldw and ldw:GetEntry() == LADY_DEATHWHISPER_ENTRY then
        if player:IsInCombat() and ldw:IsInCombat() then
            local hpPct = ldw:GetHealthPct()
            if hpPct > 99 then
                if not player:IsWithinLoS(ldw) then
                    if not player:IsMoving() then
                        UseRocketBoots(player)
                        MoveImmediately(player, -606, 2211.60, 49.5)
                    end
                end
            end
        end
    end
end

local function OnEnterMap631(event, player)
    if player:GetMapId() == 631 and player:IsBot() then
        player:RegisterEvent(LadyDeathwhisperLosLoop, 2000, 0, player)
    end
end

RegisterPlayerEvent(28, OnEnterMap631)
if GetStateMap() then for _, player in ipairs(GetStateMap():GetPlayers()) do OnEnterMap631(nil, player) end end
