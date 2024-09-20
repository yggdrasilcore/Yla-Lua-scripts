local function SendAnniversary(event, player, command)
    -- Split the command into parts
    local args = {}
    for word in command:gmatch("%w+") do
        table.insert(args, word)
    end

    -- Check if the command is sendanniversary
    if args[1] ~= "sendanniversary" then
        return
    end

    -- Check if a player name was provided
    if not args[2] then
        player:SendBroadcastMessage("Usage: .sendanniversary <playername>")
        return false
    end

    local playername = args[2]
    local targetPlayer = GetPlayerByName(playername)

    if not targetPlayer then
        player:SendBroadcastMessage("Error: Player not found.")
        return false
    end

    local receiverGUIDLow = targetPlayer:GetGUIDLow()
    local targetName = targetPlayer:GetName()

    local subject = "Half Year Anniversary gift from staff"
    local body = string.format([[Greetings, %s!

This month, the server turns 6 months, and we would like to include you in the half-year anniversary. Thank you for all the hard work you are doing by being an active player and member of our community. You are an integral part of our journey and we hope that you will take part in our continued growth as well.

Stay tuned on Discord for more anniversary information!

Best regards,
The Yggdrasil staff.]], targetName)

    SendMail(subject, body, receiverGUIDLow, 3, 61, 0, 10000000, 0, 43516, 1, 49426, 40)
    player:SendBroadcastMessage("Anniversary mail sent to " .. targetName .. ".")
    return false
end

RegisterPlayerEvent(42, SendAnniversary)