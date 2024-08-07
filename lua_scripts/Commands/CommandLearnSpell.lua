local MSG_LEARNSPELL = "#learnspell" -- Message to learn a spell by ID.

-- Function to learn a spell for the player.
local function LearnSpell(player, spellId)
    -- Learn the spell for the player.
    player:LearnSpell(spellId)
    -- Send a message to the player confirming the spell learning.
    player:SendBroadcastMessage("You have learned spell ID " .. spellId)
end

local function OnChat(event, player, message, _, _, _, _, _, _, _, _, _, guid)
    local gmRank = player:GetGMRank()
    -- Check if the player is a GM
    if gmRank >= 3 then
        local lowerMsg = message:lower()
        -- Check if the message starts with the command and has a spell ID.
        if string.sub(lowerMsg, 1, #MSG_LEARNSPELL) == MSG_LEARNSPELL then
            local spellId = tonumber(string.sub(lowerMsg, #MSG_LEARNSPELL + 1))
            if spellId then
                -- Learn the spell with the specified ID.
                LearnSpell(player, spellId)
            else
                -- Send a message if the spell ID is not valid.
                player:SendBroadcastMessage("Invalid spell ID.")
            end
            return false
        end
    end
end

-- Register the function to handle player chat events.
RegisterPlayerEvent(18, OnChat) -- Event 18 is the PLAYER_CHAT event
