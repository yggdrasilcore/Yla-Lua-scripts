RegisterPlayerEvent(3, function(event, player)
    local function ClearChat(player)
        for i = 1, 500 do
            player:SendBroadcastMessage(" ")
        end
        player:SendBroadcastMessage("Welcome to Yggdrasil! Branch out on a new adventure today.")
    end
    ClearChat(player)
end)