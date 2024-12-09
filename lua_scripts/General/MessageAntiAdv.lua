local blockedWords = {
    -- Existing entries
    "[.]com", "[.]br", "[.]ml", "bit[.]ly",
    "[.] com", "[.] br", "[.] ml", "bit[.] ly", "bit [.]ly", 
    "c o m", "[.] b r", "[.]b r", "[.] m l", "[.]m l", "b i t",
    "account%s?%w*%s?for%s?%w*%s?sale", -- Selling accounts
    
    -- Generic TLDs
    "[.]org", "[.]net", "[.]info", "[.]biz", "[.]xyz", 
    "[.]online", "[.]site", "[.]tech", "[.]shop", "[.]store",
    
    -- Country Code TLDs
    "[.]us", "[.]uk", "[.]ca", "[.]au", "[.]de", "[.]fr", 
    "[.]jp", "[.]ru", "[.]cn", "[.]in", "[.]es", "[.]it", 
    "[.]nl", "[.]ch", "[.]se", "[.]no", "[.]kr", "[.]mx",
    
    -- New server and game server advertising blocks
    "battle%s*wow%s*new",
    "new%s*blizzlike%s*(?:and)?%s*pvp%s*server",
    "new%s*server",
    
    -- Eastern European and Middle Eastern TLDs
    "[.]ua", "[.]by", "[.]md", "[.]rs", "[.]bg", "[.]hr", 
    "[.]cz", "[.]sk", "[.]si", "[.]pl", "[.]ro", "[.]hu", "[.]ee", 
    "[.]lv", "[.]lt", "[.]ba", "[.]mk", "[.]me", "[.]al", "[.]xn%-%-p1ai", -- Russia in Cyrillic
    
    -- Middle Eastern TLDs
    "[.]ae", "[.]sa", "[.]il", "[.]iq", "[.]ir", "[.]jo", "[.]lb", 
    "[.]ps", "[.]sy", "[.]ye", "[.]om", "[.]bh", "[.]kw", "[.]qa", 
    "[.]xn%-%-wgv71a119e", -- Saudi Arabia in Arabic
    "[.]xn%-%-mgb9awbf", -- Egypt in Arabic
    
    -- Additional Common TLDs
    "[.]io", "[.]co", "[.]ai", "[.]app", "[.]dev", "[.]club", 
    "[.]blog", "[.]email", "[.]news", "[.]media", "[.]live",
    
    -- Variations similar to existing pattern
    "[.] org", "[.] net", "[.] info", "o r g", "n e t", "i n f o"
}

local function antiPublishing(event, player, msg)
    -- Convert message to lowercase for case insensitive matching
    msg = string.lower(msg)

    -- Check if the message contains "discord.com"
    if string.find(msg, "discord%.com") then
        return true  -- Allow the message since it contains "discord.com"
    end
    -- Check if the message contains "discord.com"
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

print("Anti Advertising script loaded!") --for console debugging
