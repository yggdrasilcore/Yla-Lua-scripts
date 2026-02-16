function GetAllBotsInInstance(creature)
    local bots = {}
    local instanceId = creature:GetInstanceId()
    local map = creature:GetMap()
    local mapPlayers = map:GetPlayers()
    
    for _, player in ipairs(mapPlayers) do
        if isPlayerBot[player:GetName()] and player:GetInstanceId() == instanceId and player:IsInCombat() and player:IsAlive() then
            table.insert(bots, player)
        end
    end
    
    return bots
end