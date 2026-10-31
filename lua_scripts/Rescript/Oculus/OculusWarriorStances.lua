if GetStateMapId() ~= 578 then return end

local function OnUseDragonEssence(event, player, item, target)
    if player:GetClass() ~= 1 then
        return
    end

    local aura1 = player:HasAura(2457)  -- BAttle Stance
    local aura2 = player:HasAura(71)    -- Defensive Stance
    local aura3 = player:HasAura(2458)  -- Berserker Stance

    if aura1 or aura2 or aura3 then
        local cachedAura
        if aura1 then
            cachedAura = 2457
        elseif aura2 then
            cachedAura = 71
        elseif aura3 then
            cachedAura = 2458
        end
        
        player:RegisterEvent(function(eventid, delay, repeats, player)
            if player and not (player:HasAura(2457) or player:HasAura(71) or player:HasAura(2458)) then
                player:AddAura(cachedAura, player)  -- Reapply the cached aura
            end
        end, 5000, 1)
    end
end

RegisterItemEvent(37859, 2, OnUseDragonEssence)
RegisterItemEvent(37860, 2, OnUseDragonEssence)
RegisterItemEvent(37815, 2, OnUseDragonEssence)
