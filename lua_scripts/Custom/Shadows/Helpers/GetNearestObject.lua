function GetNearestObject(worldObject, objectType, entries, range)
    local nearest = nil
    local minDistance = math.huge
    
    for _, entry in ipairs(entries) do
        local obj
        if objectType == "GameObject" then
            obj = worldObject:GetNearestGameObject(range, entry)
        elseif objectType == "Creature" then
            obj = worldObject:GetNearestCreature(range, entry)
        elseif objectType == "Player" then
            obj = worldObject:GetNearestPlayer(range)
        end
        
        if obj then
            local distance = worldObject:GetDistance(obj)
            if distance < minDistance then
                minDistance = distance
                nearest = obj
            end
        end
    end
    
    return nearest
end