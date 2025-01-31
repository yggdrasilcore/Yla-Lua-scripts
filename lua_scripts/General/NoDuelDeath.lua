local function OnDuelEnd(event, winner, loser, type)
    local aura = loser:AddAura(29230, loser)
    if aura then
        aura:SetDuration(5000)
    end
end

RegisterPlayerEvent(11, OnDuelEnd)