local function GetFactionCommand(event, player, command)
    if command == "getfaction" then
        local target = player:GetSelection()
        if target and target:IsPlayer() then
            player:SendBroadcastMessage("Selected player's faction is: " .. target:GetFaction())
        else
            player:SendBroadcastMessage("Your faction is: " .. player:GetFaction())
        end
        return false
    end
end

RegisterPlayerEvent(42, GetFactionCommand)