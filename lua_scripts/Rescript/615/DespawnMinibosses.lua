if GetStateMapId() ~= 615 then return end

local function OnKillSartharion(event, player, creature)
    if event == 7 and creature:GetEntry() ~= 28860 then return end
    
    local minibosses = creature:GetCreaturesInRange(400)
    
    for _, miniboss in pairs(minibosses) do
        local entry = miniboss:GetEntry()
        if entry == 30451 or entry == 30452 or entry == 30449 then
            miniboss:DespawnOrUnsummon() -- Despawn small dragons on kill Sartharion
        end
    end
end

RegisterPlayerEvent(7, OnKillSartharion)

local function OnKilledByCreatureOrMapEnter(event, player, creature)
    if not (player:GetMapId() == 615) then return end
    
    local instanceId = player:GetInstanceId()
    local anyoneInCombat = false
    
    local playersOnMap = player:GetMap():GetPlayers()-- Get all players in map
    
    for _, mapPlayer in ipairs(playersOnMap) do
        if mapPlayer:GetInstanceId() == instanceId and mapPlayer:IsInCombat() then
            anyoneInCombat = true
            break
        end
    end
    
    if anyoneInCombat then return end -- If anyone in instance in combat, do not despawn small dragons (not wiped)
    
    local minibosses = player:GetCreaturesInRange(400)
    
    for _, miniboss in pairs(minibosses) do
        local entry = miniboss:GetEntry()
        if entry == 30451 or entry == 30452 or entry == 30449 then
            if miniboss:GetZ() < 84 or not miniboss:IsStopped() then -- If small dragons not home, or on a walk, despawn
                if miniboss:GetNearestCreature(400, 28860) then -- Sartharion
                    miniboss:DespawnOrUnsummon()
                    miniboss:Respawn()
                end
            end
        end
    end
end

RegisterPlayerEvent(8, OnKilledByCreatureOrMapEnter)
RegisterPlayerEvent(28, OnKilledByCreatureOrMapEnter)