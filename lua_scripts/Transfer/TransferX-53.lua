local function OnMapChange(event, player)
    if player:HasSpell(76154) then
        player:LearnSpell(75973)
        player:RemoveSpell(76154)
    end
end

RegisterPlayerEvent(28, OnMapChange)