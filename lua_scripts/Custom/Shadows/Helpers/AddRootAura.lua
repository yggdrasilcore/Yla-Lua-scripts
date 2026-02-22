function AddRootAura(player, duration)
    local aura = player:AddAura(35340, player)
    if aura then aura:SetDuration(duration) end
end