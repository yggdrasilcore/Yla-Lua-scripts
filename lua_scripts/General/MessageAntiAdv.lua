-- Multistate: chat events (18-22) only fire in the global state.
if GetStateMapId() ~= -1 then return end

local blockedWords = {
   -- Existing entries
   "[.]com%f[%s]", "[.]br%f[%s]", "[.]ml%f[%s]", "bit[.]ly%f[%s]",
   "[.] com%f[%s]", "[.] br%f[%s]", "[.] ml%f[%s]", "bit[.] ly%f[%s]", "bit [.]ly%f[%s]", 
   "c o m", "[.] b r", "[.]b r", "[.] m l", "[.]m l", "b i t",
   "account%s?%w*%s?for%s?%w*%s?sale",
   
   -- Generic TLDs
   "[.]org%f[%s]", "[.]net%f[%s]", "[.]info%f[%s]", "[.]biz%f[%s]", "[.]xyz%f[%s]", 
   "[.]online%f[%s]", "[.]site%f[%s]", "[.]tech%f[%s]", "[.]shop%f[%s]", "[.]store%f[%s]",
   
   -- Country Code TLDs
   "[.]us%f[%s]", "[.]uk%f[%s]", "[.]ca%f[%s]", "[.]au%f[%s]", "[.]de%f[%s]", "[.]fr%f[%s]", 
   "[.]jp%f[%s]", "[.]ru%f[%s]", "[.]cn%f[%s]", "[.]in%f[%s]", "[.]es%f[%s]", "[.]it%f[%s]", 
   "[.]nl%f[%s]", "[.]ch%f[%s]", "[.]se%f[%s]", "[.]no%f[%s]", "[.]kr%f[%s]", "[.]mx%f[%s]",
   
   -- Server blocks
   "battle%s*wow%s*new",
   "new%s*blizzlike%s*(?:and)?%s*pvp%s*server",
   "new%s*server",
   
   -- Eastern European TLDs
   "[.]ua%f[%s]", "[.]by%f[%s]", "[.]md%f[%s]", "[.]rs%f[%s]", "[.]bg%f[%s]", "[.]hr%f[%s]", 
   "[.]cz%f[%s]", "[.]sk%f[%s]", "[.]si%f[%s]", "[.]pl%f[%s]", "[.]ro%f[%s]", "[.]hu%f[%s]", "[.]ee%f[%s]", 
   "[.]lv%f[%s]", "[.]lt%f[%s]", "[.]ba%f[%s]", "[.]mk%f[%s]", "[.]me%f[%s]", "[.]al%f[%s]", "[.]xn%-%-p1ai%f[%s]",
   
   -- Middle Eastern TLDs
   "[.]ae%f[%s]", "[.]sa%f[%s]", "[.]il%f[%s]", "[.]iq%f[%s]", "[.]ir%f[%s]", "[.]jo%f[%s]", "[.]lb%f[%s]", 
   "[.]ps%f[%s]", "[.]sy%f[%s]", "[.]ye%f[%s]", "[.]om%f[%s]", "[.]bh%f[%s]", "[.]kw%f[%s]", "[.]qa%f[%s]", 
   "[.]xn%-%-wgv71a119e%f[%s]",
   "[.]xn%-%-mgb9awbf%f[%s]",
   
   -- Additional TLDs
   "[.]io%f[%s]", "[.]co%f[%s]", "[.]ai%f[%s]", "[.]app%f[%s]", "[.]dev%f[%s]", "[.]club%f[%s]", 
   "[.]blog%f[%s]", "[.]email%f[%s]", "[.]news%f[%s]", "[.]media%f[%s]", "[.]live%f[%s]",
   
   -- Variations
   "[.] org%f[%s]", "[.] net%f[%s]", "[.] info%f[%s]", "o r g", "n e t", "i n f o"
}

local function antiPublishing(event, player, msg)
    -- Convert message to lowercase for case insensitive matching
    msg = string.lower(msg)

    -- Check if the message contains "discord.com"
    if string.find(msg, "discord%.com") then
        return true  -- Allow the message since it contains "discord.com"
    end
    
    if string.find(msg, "%.%.") then
        return true
    end

    -- Check if the message contains "discord.com"
    if string.find(msg, "yggdrasilwow%.com") then
        return true  -- Allow the message since it contains "discord.com"
    end


    -- Check against other blocked patterns
    for _, v in ipairs(blockedWords) do 
        if string.find(msg, v) then
            print(player:GetName().." just said blocked msg: "..msg)
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
