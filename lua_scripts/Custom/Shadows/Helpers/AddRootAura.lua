function AddRootAura(player, duration)
    local aura = player:AddAura(35340, player)
    if aura then aura:SetDuration(duration) end
end

function RemoveRootAura(player)
    player:RemoveAura(35340)
end