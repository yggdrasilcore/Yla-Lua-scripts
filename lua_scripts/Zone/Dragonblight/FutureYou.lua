function OnSpawn(event, creature)
    creature:SetReactState(0)
    creature:RegisterEvent(CheckForEnemies, 1000, 0)
end

function CheckForEnemies(eventId, delay, repeats, creature)
    local nearestEnemy = creature:GetNearestCreature(50, 27896)
    if nearestEnemy then
        creature:AttackStart(nearestEnemy)
        return
    end
    local nearestEnemy = creature:GetNearestCreature(50, 27897)
    if nearestEnemy then
        creature:AttackStart(nearestEnemy)
        return
    end
    local nearestEnemy = creature:GetNearestCreature(50, 27898)
    if nearestEnemy then
        creature:AttackStart(nearestEnemy)
        return
    end
    local nearestEnemy = creature:GetNearestCreature(50, 27890)
    if nearestEnemy then
        creature:AttackStart(nearestEnemy)
        return
    end
end

RegisterCreatureEvent(27899, 5, OnSpawn)