-- Multistate: Halls of Reflection-only script (map 668).
if not IsCompatibilityMode() and GetStateMapId() ~= 668 then return end

local function TargetPriorityTrash(event, player, _)
    if not (player:GetMapId() == 668) then return end
    
    player:RegisterEvent(function(e,d,r, player)
        local group = player:GetGroup() 
        if not group then return end
        
        local prioTarget
        
        local priorityIds = {38175, 38172, 38177, 38173, 38176}
        
        for i, creatureId in ipairs(priorityIds) do
            if not prioTarget then
                local creatures = player:GetCreaturesInRange(300, creatureId)
                
                for _, creature in ipairs(creatures) do
                    if creature:IsTargetableForAttack() then
                        prioTarget = creature
                        break
                    end
                end
            end
        end
        
        local general = player:GetNearestCreature(300, 36723)
        if general then
            if general:IsInCombat() then
                local reflections = general:GetCreaturesInRange(300, 37068)
                for _, reflection in ipairs(reflections) do
                    if reflection:IsTargetableForAttack() then
                        prioTarget = reflection
                        break
                    end
                end
            end
        else
            local reflections = player:GetCreaturesInRange(300, 37068)
            for _, reflection in ipairs(reflections) do
                if reflection:IsTargetableForAttack() then
                    prioTarget = reflection
                    break
                end
            end
        end
            
        if prioTarget then
            if prioTarget:GetData("SkullSet") then return end
            prioTarget:SetData("SkullSet", true)
            group:SetTargetIcon(7, prioTarget:GetGUID(), player:GetGUID())
        end
    end, 500, 1)
end

RegisterPlayerEvent(7, TargetPriorityTrash)     -- On kill creature
RegisterPlayerEvent(33, TargetPriorityTrash)     -- On enter combat
