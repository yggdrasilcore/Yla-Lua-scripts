if GetStateMapId() ~= -1 then return end

local function UpdateClientCacheCommand(event, player, command)
    if command == "update cache" or command == "update client cache" then
        if player and player:GetGMRank() < 2 then return end
        UpdateClientCache()
        if not player then return end
		player:SendBroadcastMessage("Invalidating caches.")
    end
end

RegisterPlayerEvent(42, UpdateClientCacheCommand)