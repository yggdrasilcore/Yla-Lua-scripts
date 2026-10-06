-- Multistate: Icecrown Citadel-only script (map 631).
if not IsCompatibilityMode() and GetStateMapId() ~= 631 then return end

local function OnEnterCombat(event, player, enemy)
    if not enemy then  return  end
    
    if not (player:GetAreaId() == 4859) then return end -- Frozen Throne
    
    local LK = player:GetNearestCreature(1000, 36597)
    if LK and not LK:IsInCombat() then
    
        local creatureIds = {37698, 36633, 36701, 37799, 39190} -- ICC trash mobs
        for _, id in ipairs(creatureIds) do
            local creatures = player:GetCreaturesInRange(1000, id)
            if creatures then
                for _, creature in ipairs(creatures) do
                    creature:DespawnOrUnsummon(0)
                end
            end
        end
    end
end

RegisterPlayerEvent(33, OnEnterCombat)