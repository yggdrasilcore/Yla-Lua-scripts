-- Multistate: PLAYER_EVENT_ON_LOGIN (3) only fires in the global state (the
-- Guild API used here is world-only as well).
if GetStateMapId() ~= -1 then return end

local function OnLogin(event, player)
    local delay = 1

    player:RegisterEvent(function(eventId, delay, repeats, player)
        local guild = player:GetGuild()
        if guild then
            local gmotd = guild:GetMOTD()
            player:SendBroadcastMessage("|cff40ff40Guild Message of the Day: " .. gmotd .. "|r")
        end
    end, delay, 1)
end

RegisterPlayerEvent(3, OnLogin)