if not (GetStateMapId() == 571) then return end

local function ReApplyBindingLifeAura(event, player, aura, mode)
    if not (mode == 1) then return end
    
    local remaining = aura:GetDuration()
    
    player:RegisterEvent(function(eventId, delay, repeats, player)
        if not (player:GetAreaId() == 4185) then return end
        
        player:AddAura(SPELL_BINDING_LIFE, player)
        local reapplied = player:GetAura(SPELL_BINDING_LIFE)
        
        if reapplied then reapplied:SetDuration(remaining) end
        
    end, 1, 1)
end

RegisterAuraEvent(48809, 2, ReApplyBindingLifeAura)