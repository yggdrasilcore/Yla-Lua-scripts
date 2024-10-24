-- Eluna script to reset player's talents upon writing #resettalents
local function OnChat(event, player, msg, Type, lang)
    -- Check if the message is #resettalents
    if msg == "#resettalents" then
        -- Reset the player's talents
        player:ResetTalents()

        -- Send a confirmation message to the player
        player:SendBroadcastMessage("Your talents have been reset.")

        -- Return false to prevent the message from being sent to others
        return false
    end
end

-- Register the chat event
RegisterPlayerEvent(18, OnChat)
