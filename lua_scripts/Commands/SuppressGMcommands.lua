-- Multistate: PLAYER_EVENT_ON_COMMAND (42) only fires in the global state.
if GetStateMapId() ~= -1 then return end

function GMcommands(event, player, command)
    if player and player:GetGMRank() == 0 and string.find(command, "gm") then
        player:SendBroadcastMessage("Command '" .. command .. "' does not exist.")
        return false
    end
end

RegisterPlayerEvent(42, GMcommands)
