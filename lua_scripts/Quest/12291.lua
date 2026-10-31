if not (GetStateMapId() == 571) then return end

local function ReApplyBindingLifeAura(event, player, aura, mode)
    if not (mode == 1) then return end
    
    local remaining = aura:GetDuration()
    
    player:RegisterEvent(function(eventId, delay, repeats, player)
        if not (player:GetAreaId() == 4185) then return end
        
        local aura = player:AddAura(48809, player)
        if aura then aura:SetDuration(remaining) end
        
    end, 1, 1)
end

RegisterAuraEvent(48809, 2, ReApplyBindingLifeAura)