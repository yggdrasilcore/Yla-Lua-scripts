-- Multistate: PLAYER_EVENT_ON_LOGIN (3) only fires in the global state.
if GetStateMapId() ~= -1 then return end

RegisterPlayerEvent(3, function(event, player)
    local function ClearChat(player)
        for i = 1, 500 do
            player:SendBroadcastMessage(" ")
        end
        player:SendBroadcastMessage("Welcome to Yggdrasil! Branch out on a new adventure today.")
    end
    ClearChat(player)
end)