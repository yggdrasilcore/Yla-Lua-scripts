-- Multistate: map-only script (all hooks fire in map states).
if not IsCompatibilityMode() and GetStateMapId() == -1 then return end

-- Multistate: PLAYER_EVENT_ON_UPDATE_ZONE (27) fires in map states, but
-- enumerating online GMs (GetPlayersInWorld) is world-only, so GM
-- notifications are forwarded to the global state via EMQ.
local MS = require("Multistate")
local EMQ = require("EMQ")

-- Global executor: notifies all online GMs (world-only enumeration).
EMQ.RegisterQueue("AntiCheatNotifyGMs", function(player, data)
    if not data or not data.message then
        return
    end
    for _, gm in pairs(GetPlayersInWorld()) do
        if gm:GetGMRank() > 0 then
            gm:SendAreaTriggerMessage(data.message)
        end
    end
end)

local function antiGMIslandCheat(event, player, newZone, newArea)
    if newZone == 876 and player:GetGMRank() == 0 then
        player:Teleport(13, 0, 0, 0, 0)
        player:SendAreaTriggerMessage("You have been detected in an area you're not supposed to be in!")
        local message = "[Anticheat] Player " .. player:GetName() .. " has been detected on GM island with too low GM rank!"
        if MS.IsCompat() or MS.IsWorld() then
            for _, gm in pairs(GetPlayersInWorld()) do
                if gm:GetGMRank() > 0 then
                    gm:SendAreaTriggerMessage(message)
                end
            end
        else
            player:SendEMQMessage("AntiCheatNotifyGMs", { message = message })
        end
    end
end

RegisterPlayerEvent(27, antiGMIslandCheat)
