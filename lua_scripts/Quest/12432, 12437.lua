-- Multistate: map-only script (all hooks fire in map states).
if GetStateMapId() == -1 then return end

local function OnSpawn(event, creature)
    local player = creature:GetNearestPlayer(15)
    if player then
        if creature:GetNearestCreature(10, 27702) then
            player:CompleteQuest(12437) -- Horde lumership quest
        elseif creature:GetNearestCreature(10, 27688) then
            player:CompleteQuest(12432) -- Ally lumbership quest
        end
    end
end

RegisterCreatureEvent(27663, 5, OnSpawn) -- 27663 is rocket explosion dummy