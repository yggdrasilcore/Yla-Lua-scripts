-- Multistate: PLAYER_EVENT_ON_LOGIN (3) only fires in the global state (the
-- Guild API used here is world-only as well).
if GetStateMapId() ~= -1 then return end

local EVENT_PLAYER_LOGIN = 3

-- Function to handle the event
local function OnLogin(event, player)
    -- Delay in milliseconds (1 ms = 0.001 seconds)
    local delay = 1

    -- Create a timed event to print the GMOTD
    player:RegisterEvent(function(eventId, delay, repeats, player)
        local guild = player:GetGuild()
        if guild then
            local gmotd = guild:GetMOTD()
            player:SendBroadcastMessage("|cff40ff40Guild Message of the Day: " .. gmotd .. "|r")
        end
    end, delay, 1)
end

-- Register the OnLogin event
RegisterPlayerEvent(EVENT_PLAYER_LOGIN, OnLogin)