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

local function SetFactionCommand(event, player, command)
    -- Split the command into parts
    local args = {}
    for word in command:gmatch("%w+") do
        table.insert(args, word)
    end
    
    -- Check if command is "setfaction" and has a faction number
    if args[1] == "setfaction" and args[2] then
        -- Convert the second argument to a number
        local factionId = tonumber(args[2])
        
        if not factionId then
            player:SendBroadcastMessage("Please provide a valid faction number.")
            return false
        end
        
        -- Get target or use player if no target
        local target = player:GetSelection()
        if target and target:IsPlayer() then
            target:SetFaction(factionId)
            player:SendBroadcastMessage("Set selected player's faction to: " .. factionId)
        else
            player:SetFaction(factionId)
            player:SendBroadcastMessage("Set your faction to: " .. factionId)
        end
        return false
    end
end

RegisterPlayerEvent(42, SetFactionCommand)