local message1 = "|cff00ccff Welcome to Yggdrasil! Please join our Discord server to stay updated. https://discord.gg/PCcCWFBdTQ"
local message2 = "|cff00ccff Players can now purchase guilds at the Mall. Please visit the guild vendor in the northern mound to get started."
local message3 = "|cff00ccff Vote Tokens and Community Tokens are located in key ring and are account shared. Ask Twiggy to check your balance."
local message4 = "|cff00ccff We offer full account transfers until December 31st. If you haven't transferred your account yet, visit Discord to learn more."
local message5 = "|cff00ccff Please type \"/join world\" if you'd like to partake in the world chat."
local message6 = "|cff00ccff You may now hire your alts to assist you in parties! Reach level 15, do the Time-Lost Void quest and check with Twiggy to learn more."
local message7 = "|cff00ccff RAF and Community Tokens, which can be used for VIP, are now live! Visit our Discord server's announcements to learn more."
local interval = 500000 -- 10 minutes in milliseconds (change this to desired interval)

local messages = {message1, message2, message3, message4, message5, message6, message7}
local currentIndex = 1 -- Start with the first message

-- Function to send the message
local function SendServerMessage()
    SendWorldMessage(messages[currentIndex], 2) -- Send to chatbox (change to 1 for WideScreen)
    -- Switch to the next message
    currentIndex = currentIndex % #messages + 1
end

-- Register the repeating event
CreateLuaEvent(SendServerMessage, interval, 0) -- 0 means repeat indefinitely
