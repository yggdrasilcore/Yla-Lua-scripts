-- Multistate: PLAYER_EVENT_ON_COMMAND (42) only fires in the global state. The
-- "cbstoptime" handshake is stored via shared Data() (see CombatLeave.lua) so
-- the map-state combat clearer can authorize this command.
local Multistate = require("Multistate")
if GetStateMapId() ~= -1 then return end

local Multistate = require("Multistate")

local function OnCommand(event, player, command)
    if command:lower() == "combatstop" then
        local gmRank = player:GetGMRank()
        -- Multistate: shared cross-state handshake, also written from map states.
        local cbstoptime = Multistate.GetData(player, "cbstoptime")
        local currentTime = os.time()
        if gmRank > 2 then
            if debugprint == 1 then
                print("Permitting combatstop command for "..player:GetName())
            end
            return true
        end
        if not (cbstoptime and math.abs(currentTime - cbstoptime) <= 2) then
            if debugprint == 1 then
                print("Denying combatstop command for "..player:GetName())
            end
            return false
        end
        if debugprint == 1 then
            print("Permitting combatstop command for "..player:GetName())
        end
        return true
    end
end

RegisterPlayerEvent(42, OnCommand)
