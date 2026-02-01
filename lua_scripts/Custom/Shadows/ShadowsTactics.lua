-- HOR TACTICS

function DoNotTargetLK(event, player)
    if not (player:GetMapId() == 668) then return end
    
    local LK = player:GetNearestCreature(4000, 36954)
    
    if LK then
        local group = player:GetGroup()
        
        if group then
            group:SetTargetIcon(4, LK:GetGUID(), player:GetGUID())
        end
    end
end

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
RegisterPlayerEvent(28, DoNotTargetLK)             -- On change map
RegisterPlayerEvent(33, TargetPriorityTrash)     -- On enter combat

--- END HOR TACTICS

-- SINDY TOMB TWEAK

function CombatCheck(eventId, delay, repeats, sindragosa)
    if sindragosa:IsDead() or not sindragosa:IsInCombat() then
        sindragosa:SetData("SindyEventOn", nil)
        RemoveEventById(eventId)
        return
    end
    
    if sindragosa:GetHealthPct() < 35 then -- Forces shadows to damage p2 tombs if they've been up more than 9 sec
        local iceTargets = sindragosa:GetCreaturesInRange(1000, 36980)
        local currentTime = os.time()
        
        for i = 1, #iceTargets do
            local tomb = iceTargets[i]
            if not tomb:GetData("TombTime") then
                tomb:SetData("TombTime", currentTime)
            else
                local tombAge = currentTime - tomb:GetData("TombTime")
                if tombAge > 9 then
                    local playersNearTomb = tomb:GetPlayersInRange(5)
                    for _, player in pairs(playersNearTomb) do
                        local name = player:GetName()
                        if isPlayerBot[name] then
                            local lastDamageTime = player:GetData("LastTombDamage") or 0
                            if currentTime - lastDamageTime >= 1.5 then
                                local nearestTomb = player:GetNearestCreature(5, 36980, 0)
                                if nearestTomb then
                                    player:DealDamage(nearestTomb, nearestTomb:GetMaxHealth() * 0.02)
                                    player:SetData("LastTombDamage", currentTime)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
   
    local target = sindragosa:GetVictim()
    if not target or not target:ToPlayer() then return end
   
    target:AddAura(64556, target) -- Prevents tank from being knocked back by erroneous tail swipe pathing
end

function OnSindyCombat(event, player, enemy)
    if enemy and enemy:GetEntry() == 36853 then
        if not enemy:GetData("SindyEventOn") then
            enemy:SetData("SindyEventOn", true)
            enemy:RegisterEvent(CombatCheck, 500, 0)
        end
    end
end

RegisterPlayerEvent(33, OnSindyCombat)

-- END SINDY TOMB TWEAK

-- START RAID ICONS SHADOW HANDLING
 
local function RemoveRaidIconsOnDeath(event, obj1, player)
    if event == 8 and not isPlayerBot[player:GetName()] then return end -- Ensures we don't process player death twice as this is in event 7 (packet) anyway
    
    local group = player:GetGroup()
    if not group then return end
    
    local members = group:GetMembers()
    for _, member in pairs(members) do
        if member:IsAlive() and member:IsInCombat() then
            local distance = player:GetDistance(member)
            if distance <= 100 then
                return
            end
        end
    end
    
    --[[
    local hasBots = false
    for _, member in pairs(members) do
        local memberName = member:GetName()
        if activeBots[memberName] then
            hasBots = true
            break
        end
    end
    
    if not hasBots then return end
    --]]
    
    group:SetTargetIcon(7, 0, player:GetGUID())
end

RegisterPacketEvent(0x269, 7, RemoveRaidIconsOnDeath) -- This captures all player deaths but packet events don't work on shadows, 
RegisterPlayerEvent(8, RemoveRaidIconsOnDeath) -- This works for all creature kills but not other death (shadows can only be killed by creatures, not gravity/drowning etc.)

-- END RAID ICONS SHADOW HANDLING

-- POS TACTIC HACKS

local function AddShadowsGarfrostFrostProtection(event, player, enemy)
    if enemy then
        if enemy:GetEntry() == 36494 then -- 36494 is Garfrost
            if isPlayerBot[player:GetName()] then
                player:AddAura(2705400, player)
            end
        else
            if player:HasAura(2705400) then
                player:RemoveAura(2705400)
            end
        end
    else
        if player:HasAura(2705400) then
            player:RemoveAura(2705400)
        end
    end
end  

local function RemoveShadowsGarfrostFrostProtection(event, player)
    if player:HasAura(2705400) then
        player:RemoveAura(2705400)
    end
end

RegisterPlayerEvent(33, AddShadowsGarfrostFrostProtection) -- Enter combat

RegisterPlayerEvent(3, RemoveShadowsGarfrostFrostProtection) -- On login, if stale aura
RegisterPlayerEvent(34, RemoveShadowsGarfrostFrostProtection) -- Leave combat

-- END POS TACTICS HACKS

-- LK TACTICS

local function CheckNecroticPlague(eventid, delay, repeats, lk) -- Make shadows dispell plague on p1->p2 transition
    local hp = lk:GetHealthPct()
    if lk:IsDead() or not lk:IsInCombat() or hp < 65 then
        lk:SetData("NecroticCheckActive", nil)
        RemoveEventById(eventid)
        return
    end
    
    
    if hp >= 65 and hp <= 70 then
        local players = lk:GetPlayersInRange(100)
        local necroticAuras = {70337, 70338, 73785, 73786, 73787, 73912, 73913, 73914}
        
        for _, player in pairs(players) do
            local name = player:GetName()
            if isPlayerBot[name] then
                for _, auraId in ipairs(necroticAuras) do
                    if player:HasAura(auraId) then
                        player:CastSpell(player, 66116, true)
                        break
                    end
                end
            end
        end
    end
end

local function OnLKCombat(event, player, enemy)
    if enemy and enemy:GetEntry() == 36597 then
        if not enemy:GetData("NecroticCheckActive") then
            enemy:SetData("NecroticCheckActive", true)
            enemy:RegisterEvent(CheckNecroticPlague, 1000, 0)
        end
    end
end

RegisterPlayerEvent(33, OnLKCombat)