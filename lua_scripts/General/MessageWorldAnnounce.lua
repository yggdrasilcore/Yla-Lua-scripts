if GetStateMapId() ~= -1 then return end

local message1 = "|cff00ccff Welcome to Yggdrasil! Please join our Discord server to stay updated. https://discord.gg/PCcCWFBdTQ"
local message2 = "|cff00ccff Remember to ask Twiggy if you have questions about Yggdrasil and the server's features."
local message3 = "|cff00ccff We reward social media, streaming and other content about Yggdrasil with Community Tokens, exchangable for VIP and vanity items! Check in with Twiggy or Discord to learn more."
local message4 = "|cff00ccff Please type \"/join world\" if you'd like to partake in the world chat."
local interval = 500000 -- 10 minutes in milliseconds (change this to desired interval)

local messages = {message1, message2, message3, message4}
local currentIndex = 1 -- Start with the first message

-- Function to send the message
local function SendServerMessage()
    SendWorldMessage(messages[currentIndex], 2) -- Send to chatbox (change to 1 for WideScreen)
    -- Switch to the next message
    currentIndex = currentIndex % #messages + 1
end

-- Register the repeating event
CreateLuaEvent(SendServerMessage, interval, 0) -- 0 means repeat indefinitely
