local blockedWords = {
    "[.]com", "[.]br", "[.]ml", "bit[.]ly",
    "[.] com", "[.] br", "[.] ml", "bit[.] ly", "bit [.]ly", 
    "c o m", "[.] b r", "[.]b r", "[.] m l", "[.]m l", "b i t",
    "account%s?%w*%s?for%s?%w*%s?sale", -- Selling accounts
}

local function antiPublishing(event, player, msg)
    -- Convert message to lowercase for case insensitive matching
    msg = string.lower(msg)

    if string.find(msg, "discord") then
        return true  -- Allow the message since it contains "discord.com"
    end
    
    if string.find(msg, "yggdrasilwow%.com") then
        return true  -- Allow the message since it contains "discord.com"
    end


    -- Check against other blocked patterns
    for _, v in ipairs(blockedWords) do 
        if string.find(msg, v) then 
            player:SendBroadcastMessage("I hope you're not intending to spam or market other servers here? :)")
            return false
        end 
    end

    -- If none of the blocked patterns are found, allow the message
    return true
end

-- Register the antiPublishing function for relevant player events
RegisterPlayerEvent(18, antiPublishing)
RegisterPlayerEvent(19, antiPublishing)
RegisterPlayerEvent(20, antiPublishing)
RegisterPlayerEvent(21, antiPublishing)
RegisterPlayerEvent(22, antiPublishing)