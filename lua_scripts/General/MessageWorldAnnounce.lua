local message1 = "|cff00ccff Welcome to Yggdrasil! Please join our Discord server to stay updated. https://discord.gg/PCcCWFBdTQ"
local message2 = "|cff00ccff Remember to clear your client's cache folder regularly in order to use custom items like the Mall Stone."
local message3 = "|cff00ccff Please type \"/join world\" if you'd like to partake in the world chat."
local interval = 400000 -- 10 minutes in milliseconds (change this to desired interval)

local messages = {message1, message2, message3}
local currentIndex = 1 -- Start with the first message

-- Function to send the message
local function SendServerMessage()
    SendWorldMessage(messages[currentIndex], 2) -- Send to chatbox (change to 1 for WideScreen)
    -- Switch to the next message
    currentIndex = currentIndex % #messages + 1
end

-- Register the repeating event
CreateLuaEvent(SendServerMessage, interval, 0) -- 0 means repeat indefinitely