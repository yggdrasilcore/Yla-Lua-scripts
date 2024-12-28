local function OnPlayerLogin(event, player)
    if player:HasAchieved(416) then
        player:SetKnownTitle(46)
    end
end

RegisterPlayerEvent(3, OnPlayerLogin)