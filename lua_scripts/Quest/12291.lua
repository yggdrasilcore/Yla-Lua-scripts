local MAP_NORTHREND = 571
local FORGOTTENSHORE = 4185
local SPELL_BINDING_LIFE = 48809
local MODE_DEFAULT = 1

RegisterAuraEvent(SPELL_BINDING_LIFE, 2, function(event, unit, aura, mode)
    if mode ~= MODE_DEFAULT then
        return
    end
    if unit:GetMapId() ~= MAP_NORTHREND or unit:GetAreaId() ~= FORGOTTENSHORE then
        return
    end
    local remaining = aura:GetDuration()
    unit:RegisterEvent(function(eventId, delay, repeats, target)
        if target:GetMapId() ~= MAP_NORTHREND or target:GetAreaId() ~= FORGOTTENSHORE then
            return
        end
        target:AddAura(SPELL_BINDING_LIFE, target)
        local reapplied = target:GetAura(SPELL_BINDING_LIFE)
        if reapplied then
            reapplied:SetDuration(remaining)
        end
    end, 1, 1)
end)
