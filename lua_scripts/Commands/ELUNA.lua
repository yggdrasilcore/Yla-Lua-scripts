local function CommandHandler(event, player, command)
    local cmd = string.lower(command)
	
	if not player then return end
    
    if player:GetGMRank() > 0 and (cmd == "list events" or cmd == "list event") then
        local activeEvents = GetActiveGameEvents()
        
        if #activeEvents > 0 then
            player:SendBroadcastMessage("Currently active game events:")
            for _, eventId in ipairs(activeEvents) do
                player:SendBroadcastMessage("- Event ID: " .. eventId)
            end
        else
            player:SendBroadcastMessage("No active game events found.")
        end
        
        return false
    elseif player:GetGMRank() > 0 and cmd == "eluna" then
        player:SendBroadcastMessage("Available ELUNA commands:")
        player:SendBroadcastMessage(".reload eluna - Recompiles and reloads all ELUNA events and states")
        player:SendBroadcastMessage(".list events - Show number of active ELUNA events")
        player:SendBroadcastMessage(".clear globalevents - Removes global active timed ELUNA events")
        player:SendBroadcastMessage(".clear allevents - Removes all active timed ELUNA events")
        player:SendBroadcastMessage(".clear playerevents - Removes all active ELUNA hook events from player")
        player:SendBroadcastMessage(".clear creatureevents <creature_id> - Removes all active ELUNA hook events from all instances of creature ID")
        player:SendBroadcastMessage(".clear eventid <event_id> - Removes event by specific ID")
        return false
    elseif player:GetGMRank() > 0 and cmd == "clear playerevents" then
        ClearPlayerEvents()
        player:SendBroadcastMessage("All active ELUNA events have been cleared from the player.")
        return false
    elseif player:GetGMRank() > 0 and cmd == "clear globalevents" then
        RemoveEvents(false)
        player:SendBroadcastMessage("All global timed ELUNA events have been cleared.")
        return false
    elseif player:GetGMRank() > 0 and cmd == "clear allevents" then
        RemoveEvents(true)
        player:SendBroadcastMessage("All active timed ELUNA events have been cleared.")
        return false
    elseif player:GetGMRank() > 0 and cmd:find("^clear creatureevents%s+(%d+)$") then
        local creature_id = tonumber(cmd:match("^clear creatureevents%s+(%d+)$"))
        if creature_id then
            ClearCreatureEvents(creature_id)
            player:SendBroadcastMessage("All active ELUNA events have been cleared from creatures with ID " .. creature_id .. " if creature exists.")
        else
            player:SendBroadcastMessage("Invalid creature ID. Usage: .clear creatureevents <creature_id>")
        end
    elseif player:GetGMRank() > 0 and cmd:find("^clear eventid%s+(%d+)$") then
        local event_id = tonumber(cmd:match("^clear eventid%s+(%d+)$"))
        if event_id then
			if IsGameEventActive(event_id) then
				RemoveEventById(event_id)
				player:SendBroadcastMessage("ELUNA event ID "..event_id.." has been cleared.")
			else
				player:SendBroadcastMessage("Invalid event ID. Event must be active to be cleared.")
			end
        end
        return false
    end
end

RegisterPlayerEvent(42, CommandHandler) -- Register the command handler