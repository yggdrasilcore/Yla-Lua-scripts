function GetPlayersInInstance(creature)
    local players = {}
    local instanceId = creature:GetInstanceId()
    local map = creature:GetMap()
    local mapPlayers = map:GetPlayers()
    
    for _, player in ipairs(mapPlayers) do
        if player:GetInstanceId() == instanceId and player:IsInCombat() and player:IsAlive() then
            table.insert(players, player)
        end
    end
    
    return players
end