RegisterPlayerEvent(28, function(event, player)
    if player:GetMapId() == 724 and player:IsBot() then
        local master = GetPlayerByName(player:IsBot())
        if master then
            player:Whisper("Loaded Ruby Sanctum strategy.", 0, master)
        end
    end
end)