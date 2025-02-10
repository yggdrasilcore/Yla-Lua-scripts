local function OnDuelEnd(event, winner, loser, type)
    local aura = loser:AddAura(29230, loser)
    if aura then
        aura:SetDuration(5000)
    end
	
    local aura2 = winner:AddAura(29230, winner)
    if aura2 then
        aura2:SetDuration(5000)
    end
end

RegisterPlayerEvent(11, OnDuelEnd)