RegisterPlayerEvent(28, function(event, player)
    if player:GetMapId() == 724 and isPlayerBot[player:GetName()] then
        local master = GetPlayerByName(isPlayerBot[player:GetName()])
        if master then
            player:Whisper("Loaded Ruby Sanctum strategy.", 0, master)
        end
    end
end)