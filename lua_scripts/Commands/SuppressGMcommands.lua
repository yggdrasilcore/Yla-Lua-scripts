function GMcommands(event, player, command)
    if player:GetGMRank() == 0 and string.find(command, "gm") then
        player:SendBroadcastMessage("Command '" .. command .. "' does not exist.")
        return false
    end
end

RegisterPlayerEvent(42, GMcommands)
