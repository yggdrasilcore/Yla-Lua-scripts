-- Multistate: Ruby Sanctum-only script (map 724).
if GetStateMapId() ~= 724 then return end

local function GeneralZarithrian(eventId, delay, repeats, zarithrian)
    if zarithrian:IsDead() or not zarithrian:IsInCombat() then        
        zarithrian:SetData("CachedMainTank", nil)
        zarithrian:SetData("CachedOffTank", nil)
        zarithrian:SetData("CombatStartTime", nil)
        zarithrian:SetData("LastSwapTime", nil)
        zarithrian:SetData("TankingAdds", nil)
        
        StopLuaEvent(zarithrian)
        return
    end
    
    local players = zarithrian:GetPlayersInRange(100)
    local validPlayers = {}
    
    for _, player in ipairs(players) do
        if player:IsAlive() and player:IsInCombat() and player:IsBot() then
            table.insert(validPlayers, player)
        end
    end
    
    if #validPlayers == 0 then StopLuaEvent(zarithrian) return end
    
    local map = zarithrian:GetMap()
    local mainTankPos = {x = 3051, y = 527, z = 89.14}
    local offTankPos = {x = 3039, y = 513, z = 89.11}
    local rangedCenter = {x = 3024, y = 527, z = 89}
    
    local combatStartTime = zarithrian:GetData("CombatStartTime")
    local lastSwapTime = zarithrian:GetData("LastSwapTime")
    
    if not combatStartTime then
        combatStartTime = os.time()
        zarithrian:SetData("CombatStartTime", combatStartTime)
        zarithrian:SetData("LastSwapTime", combatStartTime)
        lastSwapTime = combatStartTime
    end
    
    local combatTime = os.time() - combatStartTime
    
    local mainTank, offTank = IdentifyTanks(zarithrian)
    
    local tanks = {}
    for _, player in ipairs(validPlayers) do
        if IsTank(player) then
            table.insert(tanks, player)
        end
    end
    table.sort(tanks, function(a, b) return a:GetMaxHealth() > b:GetMaxHealth() end)
    
    for _, player in ipairs(validPlayers) do
        local victim = zarithrian:GetVictim()
        if victim and victim == player and IsTank(player) then
            player:AddAura(64556, player)
        end
    end
    
    local mainTankIsBot = mainTank and mainTank:IsBot() or false
    local offTankIsBot = offTank and offTank:IsBot() or false
    
    local useNormalTactics = (mainTank and offTank and mainTankIsBot and offTankIsBot)
    local hasRealPlayerTank = not mainTankIsBot or not offTankIsBot
    
    if not useNormalTactics or hasRealPlayerTank then
        if mainTank and mainTankIsBot then
            local adds = zarithrian:GetCreaturesInRange(100, 39814)
            local tankingAdds = zarithrian:GetData("TankingAdds") or false
            
            if combatTime > 0 and (combatTime - (lastSwapTime - combatStartTime)) >= 30 then
                tankingAdds = not tankingAdds
                zarithrian:SetData("TankingAdds", tankingAdds)
                zarithrian:SetData("LastSwapTime", os.time())
            end
            
            if tankingAdds then
                if not IsAtPos(mainTank, offTankPos.x, offTankPos.y, 2) then
                    mainTank:MoveTo(1, offTankPos.x, offTankPos.y, offTankPos.z, true)
                end
                
                for _, add in ipairs(adds) do
                    if add:IsAlive() and add:IsInCombat() then
                        mainTank:CastSpell(add, 70428, true)
                    end
                end
            else
                if not IsAtPos(mainTank, mainTankPos.x, mainTankPos.y, 2) then
                    mainTank:MoveTo(1, mainTankPos.x, mainTankPos.y, mainTankPos.z, true)
                end
                
                if IsAtPos(mainTank, mainTankPos.x, mainTankPos.y, 2) then
                    local bossX, bossY = zarithrian:GetX(), zarithrian:GetY()
                    local bossCenterX, bossCenterY, bossCenterZ = 3044, 525, 89.47
                    local distToCenter = math.sqrt((bossX - bossCenterX)^2 + (bossY - bossCenterY)^2)
                    
                    if distToCenter > 3 then
                        zarithrian:MoveTo(1, bossCenterX, bossCenterY, bossCenterZ, true)
                    end
                end
                
                mainTank:CastSpell(zarithrian, 70428, true)
            end
        end
        
        if offTank and offTankIsBot then
            local adds = zarithrian:GetCreaturesInRange(100, 39814)
            local tankingAdds = zarithrian:GetData("TankingAdds") or false
            
            if not tankingAdds then
                if not IsAtPos(offTank, offTankPos.x, offTankPos.y, 2) then
                    offTank:MoveTo(1, offTankPos.x, offTankPos.y, offTankPos.z, true)
                end
                
                for _, add in ipairs(adds) do
                    if add:IsAlive() and add:IsInCombat() then
                        offTank:CastSpell(add, 70428, true)
                    end
                end
            else
                if not IsAtPos(offTank, mainTankPos.x, mainTankPos.y, 2) then
                    offTank:MoveTo(1, mainTankPos.x, mainTankPos.y, mainTankPos.z, true)
                end
                
                if IsAtPos(offTank, mainTankPos.x, mainTankPos.y, 2) then
                    local bossX, bossY = zarithrian:GetX(), zarithrian:GetY()
                    local bossCenterX, bossCenterY, bossCenterZ = 3044, 525, 89.47
                    local distToCenter = math.sqrt((bossX - bossCenterX)^2 + (bossY - bossCenterY)^2)
                    
                    if distToCenter > 3 then
                        zarithrian:MoveTo(1, bossCenterX, bossCenterY, bossCenterZ, true)
                    end
                end
                
                offTank:CastSpell(zarithrian, 70428, true)
            end
        end
    else
        if combatTime > 0 and (combatTime - (lastSwapTime - combatStartTime)) >= 30 then
            local tempMainName = zarithrian:GetData("CachedMainTank")
            local tempOffName = zarithrian:GetData("CachedOffTank")
            zarithrian:SetData("CachedMainTank", tempOffName)
            zarithrian:SetData("CachedOffTank", tempMainName)
            zarithrian:SetData("LastSwapTime", os.time())
            
            mainTank, offTank = IdentifyTanks(zarithrian)
            mainTankIsBot = mainTank and mainTank:IsBot() or false
            offTankIsBot = offTank and offTank:IsBot() or false
        end
        
        if mainTank and mainTankIsBot then
            if not IsAtPos(mainTank, mainTankPos.x, mainTankPos.y, 2) then
                mainTank:MoveTo(1, mainTankPos.x, mainTankPos.y, mainTankPos.z, true)
            end
            
            if IsAtPos(mainTank, mainTankPos.x, mainTankPos.y, 2) then
                local bossX, bossY = zarithrian:GetX(), zarithrian:GetY()
                local bossCenterX, bossCenterY, bossCenterZ = 3044, 525, 89.47
                local distToCenter = math.sqrt((bossX - bossCenterX)^2 + (bossY - bossCenterY)^2)
                
                if distToCenter > 3 then
                    zarithrian:MoveTo(1, bossCenterX, bossCenterY, bossCenterZ, true)
                end
            end
            
            local mainTankThreat = zarithrian:GetThreat(mainTank)
            local hasHighestThreat = true
            
            for _, player in ipairs(validPlayers) do
                if zarithrian:GetThreat(player) > mainTankThreat then
                    hasHighestThreat = false
                    break
                end
            end
            
            if not hasHighestThreat then
                local highestThreat = 0
                for _, player in ipairs(validPlayers) do
                    local threat = zarithrian:GetThreat(player)
                    if threat > highestThreat then
                        highestThreat = threat
                    end
                end
                zarithrian:AddThreat(mainTank, highestThreat * 1.1 + 1000)
            end
            
            local mainTankHasAggro = (zarithrian:GetVictim() and zarithrian:GetVictim():GetGUID() == mainTank:GetGUID())
            if not mainTankHasAggro then
                mainTank:CastSpell(zarithrian, 37486, true)
            end
        end
        
        local adds = zarithrian:GetCreaturesInRange(100, 39814)
        
        if offTank and offTankIsBot then
            if not IsAtPos(offTank, offTankPos.x, offTankPos.y, 2) then
                offTank:MoveTo(1, offTankPos.x, offTankPos.y, offTankPos.z, true)
            end
            
            for _, add in ipairs(adds) do
                if add:IsAlive() and add:IsInCombat() then
                    local addThreat = add:GetThreat(offTank)
                    local hasHighestThreat = true
                    
                    for _, player in ipairs(validPlayers) do
                        if add:GetThreat(player) > addThreat then
                            hasHighestThreat = false
                            break
                        end
                    end
                    
                    if not hasHighestThreat then
                        local highestThreat = 0
                        for _, player in ipairs(validPlayers) do
                            local threat = add:GetThreat(player)
                            if threat > highestThreat then
                                highestThreat = threat
                            end
                        end
                        add:AddThreat(offTank, highestThreat * 1.1 + 1000)
                    end
                    
                    local offTankHasAggro = (add:GetVictim() and add:GetVictim():GetGUID() == offTank:GetGUID())
                    if not offTankHasAggro then
                        offTank:CastSpell(add, 37486, true)
                    end
                end
            end
        end
        
        for _, tank in ipairs(tanks) do
            if mainTank and offTank and tank:GetGUID() ~= mainTank:GetGUID() and tank:GetGUID() ~= offTank:GetGUID() then
                if tank:IsBot() then
                    if not IsAtPos(tank, offTankPos.x, offTankPos.y, 2) then
                        tank:MoveTo(1, offTankPos.x, offTankPos.y, offTankPos.z, true)
                    end
                end
            end
        end
    end
    
    local meleeDps = {}
    for _, player in ipairs(validPlayers) do
        local isTank = false
        for _, tank in ipairs(tanks) do
            if player:GetGUID() == tank:GetGUID() then
                isTank = true
                break
            end
        end
        
        if not isTank and player:HasMeleeSpec() then
            table.insert(meleeDps, player)
        end
    end
        
    if #meleeDps > 0 then
        local bx, by = zarithrian:GetX(), zarithrian:GetY()
        local bossO = zarithrian:GetO()
        
        local behindX = bx - math.cos(bossO) * 6
        local behindY = by - math.sin(bossO) * 6
        
        for _, player in ipairs(meleeDps) do
            local px, py = player:GetX(), player:GetY()
            local distToBehind = math.sqrt((px - behindX)^2 + (py - behindY)^2)
            
            if distToBehind > 14 then
                local behindZ = map:GetHeight(behindX, behindY)
                player:MoveTo(1, behindX, behindY, behindZ, true)
            end
        end
    end
    
    local rangedAndCasters = {}
    for _, player in ipairs(validPlayers) do
        local isTank = false
        for _, tank in ipairs(tanks) do
            if player:GetGUID() == tank:GetGUID() then
                isTank = true
                break
            end
        end
        
        if not isTank and (player:HasHealSpec() or player:HasCasterSpec()) then
            table.insert(rangedAndCasters, player)
        end
    end

    if #rangedAndCasters > 0 then
        for i, player in ipairs(rangedAndCasters) do
            local px, py = player:GetX(), player:GetY()
            
            if px < rangedCenter.x - 10 or px > rangedCenter.x + 10 or py < rangedCenter.y - 15 or py > rangedCenter.y + 15 then
                local lastMoved = player:GetData("LastMovedZarithrian") or 0
                local currentTime = os.time()
                
                if currentTime - lastMoved >= 5 then
                    local targetX = rangedCenter.x + math.random(-10, 10)
                    local targetY = rangedCenter.y + math.random(-15, 15)
                    local targetZ = map:GetHeight(targetX, targetY)
                    player:MoveTo(1, targetX, targetY, targetZ, true)
                    player:SetData("LastMovedZarithrian", currentTime)
                end
            end
        end
    end

    local currentTime = os.time()
    local adds = zarithrian:GetCreaturesInRange(100, 39814)
    for _, add in ipairs(adds) do
        local playersNearAdd = add:GetPlayersInRange(15)
        for _, player in pairs(playersNearAdd) do
            local name = player:GetName()
            if player:IsBot() then
                local lastDamageTime = player:GetData("LastFlamecallerDamage") or 0
                if currentTime - lastDamageTime >= 2 then
                    player:DealDamage(add, add:GetMaxHealth() * (math.random() * 0.01 + 0.015))
                    player:SetData("LastFlamecallerDamage", currentTime)
                end
            end
        end
    end

    zarithrian:RegisterEvent(GeneralZarithrian, 200, 1)
end

local function GeneralZarithianOnEnterCombat(event, player, creature)
    if creature and creature:GetEntry() == 39746 then
        StartLuaEvent(creature, GeneralZarithrian)
    end
end

RegisterPlayerEvent(33, GeneralZarithianOnEnterCombat)