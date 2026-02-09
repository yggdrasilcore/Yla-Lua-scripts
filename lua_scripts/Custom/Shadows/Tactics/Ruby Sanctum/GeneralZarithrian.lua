local function GeneralZarithrian(eventId, delay, repeats, zarithrian)
    if zarithrian:IsDead() or not zarithrian:IsInCombat() then        
        zarithrian:SetData("MainTankName", nil)
        zarithrian:SetData("OffTankName", nil)
        zarithrian:SetData("CombatStartTime", nil)
        zarithrian:SetData("LastSwapTime", nil)
        
        StopLuaEvent(zarithrian)
        return
    end
    
    -- Player Tracking
    local players = zarithrian:GetPlayersInRange(100)
    local validPlayers = {}
    
    for _, player in ipairs(players) do
        if player:IsAlive() and player:IsInCombat() and isPlayerBot[player:GetName()] then
            table.insert(validPlayers, player)
        end
    end
    
    if #validPlayers == 0 then StopLuaEvent(zarithrian) return end
    
    local map = zarithrian:GetMap()
    local mainTankPos = {x = 3051, y = 527, z = 89.14}
    local offTankPos = {x = 3039, y = 513, z = 89.11}
    local rangedCenter = {x = 3024, y = 527, z = 89}
    
    -- Tank Setup
    local mainTankName = zarithrian:GetData("MainTankName")
    local offTankName = zarithrian:GetData("OffTankName")
    local combatStartTime = zarithrian:GetData("CombatStartTime")
    local lastSwapTime = zarithrian:GetData("LastSwapTime")
    
    if not mainTankName then
        local tanks = {}
        for _, player in ipairs(validPlayers) do
            if IsTank(player) then
                table.insert(tanks, player)
            end
        end
        
        table.sort(tanks, function(a, b) return a:GetMaxHealth() > b:GetMaxHealth() end)
        
        if #tanks > 0 then
            mainTankName = tanks[1]:GetName()
            zarithrian:SetData("MainTankName", mainTankName)
            
            if #tanks > 1 then
                offTankName = tanks[2]:GetName()
                zarithrian:SetData("OffTankName", offTankName)
            end
        end
        
        combatStartTime = os.time()
        zarithrian:SetData("CombatStartTime", combatStartTime)
        zarithrian:SetData("LastSwapTime", combatStartTime)
    end
    
    local combatTime = os.time() - combatStartTime
    
    -- Identify current tanks
    local tanks = {}
    for _, player in ipairs(validPlayers) do
        if IsTank(player) then
            table.insert(tanks, player)
        end
    end
    table.sort(tanks, function(a, b) return a:GetMaxHealth() > b:GetMaxHealth() end)
    
    local mainTank = nil
    local offTank = nil
    
    for _, player in ipairs(validPlayers) do
        if player:GetName() == mainTankName then
            mainTank = player
        elseif player:GetName() == offTankName then
            offTank = player
        end
    end
    
    -- Tank role inheritance if tanks die
    if not mainTank and offTank then
        -- Off tank becomes main tank
        mainTankName = offTankName
        zarithrian:SetData("MainTankName", mainTankName)
        mainTank = offTank
        
        -- Find new off tank from remaining tanks
        offTankName = nil
        offTank = nil
        for _, tank in ipairs(tanks) do
            if tank:GetName() ~= mainTankName then
                offTankName = tank:GetName()
                zarithrian:SetData("OffTankName", offTankName)
                offTank = tank
                break
            end
        end
    elseif not offTank and mainTank then
        -- Find new off tank
        for _, tank in ipairs(tanks) do
            if tank:GetName() ~= mainTankName then
                offTankName = tank:GetName()
                zarithrian:SetData("OffTankName", offTankName)
                offTank = tank
                break
            end
        end
    end
    
    -- Tank position swapping every 30 seconds
    if combatTime > 0 and (combatTime - (lastSwapTime - combatStartTime)) >= 30 then
        local temp = mainTankName
        mainTankName = offTankName
        offTankName = temp
        zarithrian:SetData("MainTankName", mainTankName)
        zarithrian:SetData("OffTankName", offTankName)
        zarithrian:SetData("LastSwapTime", os.time())
        
        -- Re-identify after swap
        mainTank = nil
        offTank = nil
        for _, player in ipairs(validPlayers) do
            if player:GetName() == mainTankName then
                mainTank = player
            elseif player:GetName() == offTankName then
                offTank = player
            end
        end
    end
    
    -- Main tank threat and positioning
    if mainTank then
        -- Position main tank
        if not IsAtPos(mainTank, mainTankPos.x, mainTankPos.y, 2) then
            mainTank:MoveTo(1, mainTankPos.x, mainTankPos.y, mainTankPos.z, true)
        end
        
        -- Move Zarithrian to center if main tank is positioned but boss isn't
        if IsAtPos(mainTank, mainTankPos.x, mainTankPos.y, 2) then
            local bossX, bossY = zarithrian:GetX(), zarithrian:GetY()
            local bossCenterX, bossCenterY, bossCenterZ = 3044, 525, 89.47
            local distToCenter = math.sqrt((bossX - bossCenterX)^2 + (bossY - bossCenterY)^2)
            
            if distToCenter > 3 then
                zarithrian:MoveTo(1, bossCenterX, bossCenterY, bossCenterZ, true)
            end
        end
        
        -- Maintain threat on boss
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
    
    -- Off tank and other tanks handle adds
    local adds = zarithrian:GetCreaturesInRange(100, 39814)
    
    if offTank then
        -- Position off tank
        if not IsAtPos(offTank, offTankPos.x, offTankPos.y, 2) then
            offTank:MoveTo(1, offTankPos.x, offTankPos.y, offTankPos.z, true)
        end
        
        -- Off tank picks up adds
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
    
    -- Other tanks also position at off tank spot and help with adds
    for _, tank in ipairs(tanks) do
        if mainTank and offTank and tank:GetGUID() ~= mainTank:GetGUID() and tank:GetGUID() ~= offTank:GetGUID() then
            if not IsAtPos(tank, offTankPos.x, offTankPos.y, 2) then
                tank:MoveTo(1, offTankPos.x, offTankPos.y, offTankPos.z, true)
            end
        end
    end
    
    -- Melee DPS positioning
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
        
    -- Melee DPS positioning
    if #meleeDps > 0 then
        local bx, by = zarithrian:GetX(), zarithrian:GetY()
        local bossO = zarithrian:GetO()  -- Boss facing angle
        
        -- Behind = opposite of facing direction, 5 yards back
        local behindX = bx - math.cos(bossO) * 6
        local behindY = by - math.sin(bossO) * 6
        
        for _, player in ipairs(meleeDps) do
            local px, py = player:GetX(), player:GetY()
            local distToBehind = math.sqrt((px - behindX)^2 + (py - behindY)^2)
            
            -- Only move if far from behind position
            if distToBehind > 14 then
                local behindZ = map:GetHeight(behindX, behindY)
                player:MoveTo(1, behindX, behindY, behindZ, true)
            end
        end
    end
    
    -- Ranged and Casters positioning
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
            
            -- Check if outside the free movement area (centerX ±10, centerY ±15)
            if px < rangedCenter.x - 10 or px > rangedCenter.x + 10 or py < rangedCenter.y - 15 or py > rangedCenter.y + 15 then
                local lastMoved = player:GetData("LastMovedZarithrian") or 0
                local currentTime = os.time()
                
                -- Only move if 5 seconds have passed since last move
                if currentTime - lastMoved >= 5 then
                    -- Assign new random position within range
                    local targetX = rangedCenter.x + math.random(-10, 10)
                    local targetY = rangedCenter.y + math.random(-15, 15)
                    local targetZ = map:GetHeight(targetX, targetY)
                    player:MoveTo(1, targetX, targetY, targetZ, true)
                    player:SetData("LastMovedZarithrian", currentTime)
                end
            end
        end
    end

    -- Hack to force damage on Onyx Flamecallers
    local currentTime = os.time()
    for _, add in ipairs(adds) do
        local playersNearAdd = add:GetPlayersInRange(15)
        for _, player in pairs(playersNearAdd) do
            local name = player:GetName()
            if isPlayerBot[name] then
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