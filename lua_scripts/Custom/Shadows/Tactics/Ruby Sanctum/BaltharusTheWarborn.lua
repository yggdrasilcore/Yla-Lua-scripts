if GetStateMapId() ~= 724 then return end

local function CalculateCirclePosition(map, centerX, centerY, radius, angleRadians)
    local x = centerX + radius * math.cos(angleRadians)
    local y = centerY + radius * math.sin(angleRadians)
    local z = map:GetHeight(x, y)
    
    return {
        x = x,
        y = y,
        z = z
    }
end

local function BaltharusLoop(eventId, delay, repeats, baltharus)
    if baltharus:IsDead() or not baltharus:IsInCombat() then
        local players = baltharus:GetPlayersInRange(100)
        for _, player in ipairs(players) do
            if player:IsBot() and player:IsInGroup() then
                SetTargetIconDeferred(player, 7, nil)
                break
            end
        end
        
        baltharus:Data():Set("CachedMainTank", nil)
        baltharus:Data():Set("CachedOffTank", nil)
        baltharus:Data():Set("CombatStartTime", nil)
        baltharus:Data():Set("MovedToWaitSpot", nil)
        baltharus:Data():Set("SkullSet", nil)
        baltharus:Data():Set("MovedThisCast", nil)
        baltharus:Data():Set("MovedForOrientation", nil)
        baltharus:Data():Set("TempestTargetX", nil)
        baltharus:Data():Set("TempestTargetY", nil)
        baltharus:Data():Set("TempestTargetZ", nil)
        baltharus:Data():Set("LastMainTankTargetX", nil)
        baltharus:Data():Set("LastMainTankTargetY", nil)
        baltharus:Data():Set("MainTankLastX", nil)
        baltharus:Data():Set("MainTankLastY", nil)
        baltharus:Data():Set("OffTankLastX", nil)
        baltharus:Data():Set("OffTankLastY", nil)
        
        StopLuaEvent(baltharus) 
        return 
    end
    
    local players = baltharus:GetPlayersInRange(100)
    local validPlayers = {}
    local botPlayers = {}
    
    for _, player in ipairs(players) do
        if player:IsAlive() and player:IsInCombat() then
            table.insert(validPlayers, player)
            if player:IsBot() then
                table.insert(botPlayers, player)
            end
        end
    end
    
    if #botPlayers == 0 then StopLuaEvent(baltharus) return end
    
    local setter = nil
    for _, player in ipairs(botPlayers) do
        if player:IsInGroup() then setter = player break end
    end

    if setter and not baltharus:Data():Get("SkullSet") then
        SetTargetIconDeferred(setter, 7, baltharus)
        baltharus:Data():Set("SkullSet", true)
    end
    
    local map = baltharus:GetMap()
    local stackPos = {x = 3153, y = 533, z = 72.97}
    local pullSpot = {x = 3152, y = 495, z = 72.25}
    local waitSpot = {x = 3169, y = 502, z = 72.03}
    
    local combatStartTime = baltharus:Data():Get("CombatStartTime")
    
    if not combatStartTime then
        combatStartTime = os.time()
        baltharus:Data():Set("CombatStartTime", combatStartTime)
    end
    
    local combatTime = os.time() - combatStartTime
    
    local mainTank, offTank = IdentifyTanks(baltharus)
    
    local tanks = {}
    for _, player in ipairs(validPlayers) do
        if IsTank(player) then
            table.insert(tanks, player)
        end
    end
    table.sort(tanks, function(a, b) return a:GetMaxHealth() > b:GetMaxHealth() end)
    
    if mainTank and mainTank:IsBot() and combatTime == 0 then
        mainTank:AddAura(33206, mainTank)
        local aura = mainTank:GetAura(33206)
        if aura then
            aura:SetDuration(15000)
        end
        UseDefensive(mainTank)
    end

    local bossTargets = {baltharus}
    local clones = baltharus:GetCreaturesInRange(100, 39899)
    for _, clone in ipairs(clones) do
        if clone:IsAlive() and clone:IsInCombat() then
            table.insert(bossTargets, clone)
            
            if not clone:Data():Get("UsedSpawnDefensive") and mainTank and offTank then
                if mainTank:IsBot() then
                    UseDefensive(mainTank)
                end
                if offTank:IsBot() then
                    UseDefensive(offTank)
                end
                clone:Data():Set("UsedSpawnDefensive", true)
            end
        end
    end

    if mainTank and mainTank:IsBot() then
        local mainTankThreat = baltharus:GetThreat(mainTank)
        local hasHighestThreat = true
        
        for _, player in ipairs(validPlayers) do
            if baltharus:GetThreat(player) > mainTankThreat then
                hasHighestThreat = false
                break
            end
        end
        
        if not hasHighestThreat then
            local highestThreat = 0
            for _, player in ipairs(validPlayers) do
                local threat = baltharus:GetThreat(player)
                if threat > highestThreat then
                    highestThreat = threat
                end
            end
            baltharus:AddThreat(mainTank, highestThreat * 1.1 + 1000)
        end
        
        local mainTankHasAggro = (baltharus:GetVictim() and baltharus:GetVictim():GetGUID() == mainTank:GetGUID())
        if not mainTankHasAggro then
            mainTank:CastSpell(baltharus, 37486, true)
        end
    end
    
    if offTank and offTank:IsBot() then
        local hasClone = false
        for _, clone in ipairs(bossTargets) do
            if clone ~= baltharus then
                hasClone = true
                local offTankThreat = clone:GetThreat(offTank)
                local hasHighestThreat = true
                
                for _, player in ipairs(validPlayers) do
                    if clone:GetThreat(player) > offTankThreat then
                        hasHighestThreat = false
                        break
                    end
                end
                
                if not hasHighestThreat then
                    local highestThreat = 0
                    for _, player in ipairs(validPlayers) do
                        local threat = clone:GetThreat(player)
                        if threat > highestThreat then
                            highestThreat = threat
                        end
                    end
                    clone:AddThreat(offTank, highestThreat * 1.1 + 1000)
                end
                
                local offTankHasAggro = (clone:GetVictim() and clone:GetVictim():GetGUID() == offTank:GetGUID())
                if not offTankHasAggro then
                    offTank:CastSpell(clone, 37486, true)
                end
            end
        end
    end
    
    if combatTime <= 8 then
        if mainTank and mainTank:IsBot() and not IsAtPos(mainTank, pullSpot.x, pullSpot.y, 2) then
            mainTank:MoveTo(1, pullSpot.x, pullSpot.y, pullSpot.z, true)
            mainTank:AddAura(54861, mainTank)
        end
    else
        local hasMovedToWaitSpot = baltharus:Data():Get("MovedToWaitSpot")
        if not hasMovedToWaitSpot then
            if mainTank and mainTank:IsBot() and not IsAtPos(mainTank, waitSpot.x, waitSpot.y, 2) then
                mainTank:MoveTo(1, waitSpot.x, waitSpot.y, waitSpot.z, true)
            elseif (mainTank and mainTank:IsBot() and IsAtPos(mainTank, waitSpot.x, waitSpot.y, 2)) or 
               (mainTank and not mainTank:IsBot() and combatTime > 15) then
                baltharus:Data():Set("MovedToWaitSpot", true)
            end
        else
            local castingBosses = {}
            for _, boss in ipairs(bossTargets) do
                if boss:HasAura(75125) or boss:HasAura(75126) then
                    table.insert(castingBosses, boss)
                    local victim = boss:GetVictim()
                    if victim and victim:IsBot() then
                        UseDefensive(victim)
                        if not victim:HasAura(33206) then
                            local aura = victim:AddAura(33206, victim)
                            if aura then
                                aura:SetDuration(5000)
                            end
                        end
                    end
                end
            end
            
            local bossNotFacingCounterClockwise = false
            for _, boss in ipairs(bossTargets) do
                local bx, by = boss:GetX(), boss:GetY()
                local bossAngleOnCircle = math.atan2(by - stackPos.y, bx - stackPos.x)
                local counterclockwiseTangent = bossAngleOnCircle + (math.pi / 2)
                local bossO = boss:GetO()
                local angleDiff = math.abs(bossO - counterclockwiseTangent)
                
                if angleDiff > math.pi then
                    angleDiff = 2 * math.pi - angleDiff
                end
                
                if angleDiff > (math.pi / 6) then
                    bossNotFacingCounterClockwise = true
                    break
                end
            end
            
            if #castingBosses > 0 or bossNotFacingCounterClockwise then
                if mainTank and mainTank:IsBot() and mainTank:HasAura(35340) then 
                    mainTank:RemoveAura(35340) 
                end
                if offTank and offTank:IsBot() and offTank:HasAura(35340) then 
                    offTank:RemoveAura(35340) 
                end

                local movedThisCast = baltharus:Data():Get("MovedThisCast") or {}
                local needsNewPosition = false
                
                if bossNotFacingCounterClockwise then
                    local lastOrientationMove = baltharus:Data():Get("MovedForOrientation") or 0
                    if os.time() >= lastOrientationMove + 5 then
                        needsNewPosition = true
                        baltharus:Data():Set("MovedForOrientation", os.time())
                    end
                elseif #castingBosses > 0 then
                    for _, boss in ipairs(castingBosses) do
                        if not movedThisCast[tostring(boss:GetGUID())] then
                            needsNewPosition = true
                            movedThisCast[tostring(boss:GetGUID())] = true
                        end
                    end
                end
                
                if needsNewPosition and mainTank then
                    local angleIncrement = (2 * math.pi) / 14
                    
                    local tx, ty = mainTank:GetX(), mainTank:GetY()
                    local currentAngle = math.atan2(ty - stackPos.y, tx - stackPos.x)
                    local newAngle = currentAngle + angleIncrement
                    local finalPos = CalculateCirclePosition(map, stackPos.x, stackPos.y, 35, newAngle)
                    
                    local lastX = baltharus:Data():Get("LastMainTankTargetX")
                    local lastY = baltharus:Data():Get("LastMainTankTargetY")
                    
                    if not lastX or math.abs(finalPos.x - lastX) > 1 or math.abs(finalPos.y - lastY) > 1 then
                        --print("NEW POSITION - Main tank at: " .. tx .. ", " .. ty .. ", " .. mainTank:GetZ())
                        --print("NEW POSITION - Moving to: " .. finalPos.x .. ", " .. finalPos.y .. ", " .. finalPos.z)
                        --print("NEW POSITION - Current angle: " .. currentAngle .. ", New angle: " .. newAngle)
                    end
                    
                    baltharus:Data():Set("TempestTargetX", finalPos.x)
                    baltharus:Data():Set("TempestTargetY", finalPos.y)
                    baltharus:Data():Set("TempestTargetZ", finalPos.z)
                    baltharus:Data():Set("LastMainTankTargetX", finalPos.x)
                    baltharus:Data():Set("LastMainTankTargetY", finalPos.y)
                    
                    if mainTank:IsBot() then
                        baltharus:Data():Set("MainTankLastX", nil)
                        baltharus:Data():Set("MainTankLastY", nil)
                        
                        mainTank:MoveStop()
                    end
                end
                
                baltharus:Data():Set("MovedThisCast", movedThisCast)
                
                if mainTank and mainTank:IsBot() then
                    local targetX = baltharus:Data():Get("TempestTargetX")
                    local targetY = baltharus:Data():Get("TempestTargetY")
                    local targetZ = baltharus:Data():Get("TempestTargetZ")
                    
                    if targetX then
                        local currentX, currentY = mainTank:GetX(), mainTank:GetY()
                        local lastX = baltharus:Data():Get("MainTankLastX")
                        local lastY = baltharus:Data():Get("MainTankLastY")
                        
                        local needsTeleport = false
                        if lastX and lastY then
                            local distanceMoved = math.sqrt((currentX - lastX)^2 + (currentY - lastY)^2)
                            if distanceMoved < 2 then
                                needsTeleport = true
                            end
                        end
                        
                        if needsTeleport then
                            local dirX = targetX - currentX
                            local dirY = targetY - currentY
                            local dirLen = math.sqrt(dirX^2 + dirY^2)
                            
                            if dirLen > 0 then
                                dirX = dirX / dirLen
                                dirY = dirY / dirLen
                                
                                local teleportDistance = math.min(2, dirLen)
                                local newX = currentX + dirX * teleportDistance
                                local newY = currentY + dirY * teleportDistance
                                local newZ = map:GetHeight(newX, newY)
                                
                                mainTank:NearTeleport(newX, newY, newZ, mainTank:GetO())
                                --print("TELEPORT - Main tank teleported to: " .. newX .. ", " .. newY .. ", " .. newZ)
                                
                                baltharus:Data():Set("MainTankLastX", newX)
                                baltharus:Data():Set("MainTankLastY", newY)
                            end
                        else
                            baltharus:Data():Set("MainTankLastX", currentX)
                            baltharus:Data():Set("MainTankLastY", currentY)
                        end
                        
                        mainTank:MoveTo(1, targetX, targetY, targetZ, true)
                        if not mainTank:HasAura(54861) then mainTank:AddAura(54861, mainTank) end
                        
                        if IsAtPos(mainTank, targetX, targetY, 2) and #castingBosses > 0 then
                            local aura = mainTank:AddAura(35340, mainTank)
                            if aura then aura:SetDuration(5000) end
                        end
                    end
                end
            else
                baltharus:Data():Set("MovedThisCast", nil)
                baltharus:Data():Set("MainTankLastX", nil)
                baltharus:Data():Set("MainTankLastY", nil)
                baltharus:Data():Set("OffTankLastX", nil)
                baltharus:Data():Set("OffTankLastY", nil)
                if mainTank and mainTank:IsBot() and mainTank:HasAura(35340) then 
                    mainTank:RemoveAura(35340) 
                end
                if offTank and offTank:IsBot() and offTank:HasAura(35340) then 
                    offTank:RemoveAura(35340) 
                end
            end
            
            if offTank and offTank:IsBot() and mainTank then
                local mtx, mty = mainTank:GetX(), mainTank:GetY()
                local mtAngle = math.atan2(mty - stackPos.y, mtx - stackPos.x)
                local oppositeAngle = mtAngle + math.pi
                local otPos = CalculateCirclePosition(map, stackPos.x, stackPos.y, 35, oppositeAngle)
                
                local otx, oty = offTank:GetX(), offTank:GetY()
                local otCurrentAngle = math.atan2(oty - stackPos.y, otx - stackPos.x)
                
                local nearbyThreats = {}
                for _, boss in ipairs(bossTargets) do
                    if boss:GetVictim() and boss:GetVictim():GetGUID() == offTank:GetGUID() then
                        if boss:HasAura(75125) or boss:HasAura(75126) then
                            local bx, by = boss:GetX(), boss:GetY()
                            local dist = math.sqrt((otx - bx)^2 + (oty - by)^2)
                            if dist < 15 then
                                table.insert(nearbyThreats, boss)
                            end
                        end
                    end
                end
                
                if #nearbyThreats > 0 then
                    local angleIncrement = (2 * math.pi) / 14
                    local safeAngle = otCurrentAngle + angleIncrement
                    otPos = CalculateCirclePosition(map, stackPos.x, stackPos.y, 35, safeAngle)
                    
                    local currentX, currentY = offTank:GetX(), offTank:GetY()
                    local lastX = baltharus:Data():Get("OffTankLastX")
                    local lastY = baltharus:Data():Get("OffTankLastY")
                    
                    local needsTeleport = false
                    if lastX and lastY then
                        local distanceMoved = math.sqrt((currentX - lastX)^2 + (currentY - lastY)^2)
                        if distanceMoved < 2 then
                            needsTeleport = true
                        end
                    end
                    
                    if needsTeleport then
                        local dirX = otPos.x - currentX
                        local dirY = otPos.y - currentY
                        local dirLen = math.sqrt(dirX^2 + dirY^2)
                        
                        if dirLen > 0 then
                            dirX = dirX / dirLen
                            dirY = dirY / dirLen
                            
                            local teleportDistance = math.min(2, dirLen)
                            local newX = currentX + dirX * teleportDistance
                            local newY = currentY + dirY * teleportDistance
                            local newZ = map:GetHeight(newX, newY)
                            
                            offTank:NearTeleport(newX, newY, newZ, offTank:GetO())
                            --print("TELEPORT - Off tank teleported to: " .. newX .. ", " .. newY .. ", " .. newZ)
                            
                            baltharus:Data():Set("OffTankLastX", newX)
                            baltharus:Data():Set("OffTankLastY", newY)
                        end
                    else
                        baltharus:Data():Set("OffTankLastX", currentX)
                        baltharus:Data():Set("OffTankLastY", currentY)
                    end
                    
                    offTank:AddAura(54861, offTank)
                elseif #castingBosses > 0 then
                    local currentX, currentY = offTank:GetX(), offTank:GetY()
                    local lastX = baltharus:Data():Get("OffTankLastX")
                    local lastY = baltharus:Data():Get("OffTankLastY")
                    
                    local needsTeleport = false
                    if lastX and lastY then
                        local distanceMoved = math.sqrt((currentX - lastX)^2 + (currentY - lastY)^2)
                        if distanceMoved < 2 then
                            needsTeleport = true
                        end
                    end
                    
                    if needsTeleport then
                        local dirX = otPos.x - currentX
                        local dirY = otPos.y - currentY
                        local dirLen = math.sqrt(dirX^2 + dirY^2)
                        
                        if dirLen > 0 then
                            dirX = dirX / dirLen
                            dirY = dirY / dirLen
                            
                            local teleportDistance = math.min(2, dirLen)
                            local newX = currentX + dirX * teleportDistance
                            local newY = currentY + dirY * teleportDistance
                            local newZ = map:GetHeight(newX, newY)
                            
                            offTank:NearTeleport(newX, newY, newZ, offTank:GetO())
                            --print("TELEPORT - Off tank teleported to: " .. newX .. ", " .. newY .. ", " .. newZ)
                            
                            baltharus:Data():Set("OffTankLastX", newX)
                            baltharus:Data():Set("OffTankLastY", newY)
                        end
                    else
                        baltharus:Data():Set("OffTankLastX", currentX)
                        baltharus:Data():Set("OffTankLastY", currentY)
                    end
                    
                    offTank:AddAura(54861, offTank)
                end
                
                if not IsAtPos(offTank, otPos.x, otPos.y, 2) then
                    offTank:MoveTo(1, otPos.x, otPos.y, otPos.z, true)
                end
            end
        end
    end
    
    local healersAndCasters = {}
    for _, player in ipairs(botPlayers) do
        local isTank = false
        for _, tank in ipairs(tanks) do
            if player:GetGUID() == tank:GetGUID() then
                isTank = true
                break
            end
        end
        
        if not isTank and (player:HasHealSpec() or player:HasCasterSpec()) then
            table.insert(healersAndCasters, player)
        end
    end
    
    if #healersAndCasters > 0 then
        local bx, by = baltharus:GetX(), baltharus:GetY()
        
        for i, player in ipairs(healersAndCasters) do
            local px, py = player:GetX(), player:GetY()
            local distToStack = math.sqrt((px - stackPos.x)^2 + (py - stackPos.y)^2)
            local distToBoss = math.sqrt((px - bx)^2 + (py - by)^2)
            
            if distToStack > 15 or distToBoss < 30 or distToBoss > 45 then
                local dirX = stackPos.x - bx
                local dirY = stackPos.y - by
                local dirLen = math.sqrt(dirX^2 + dirY^2)
                
                if dirLen > 0 then
                    dirX = dirX / dirLen
                    dirY = dirY / dirLen
                end
                
                local targetDist = math.random(30, 45)
                local baseX = bx + dirX * targetDist
                local baseY = by + dirY * targetDist
                
                local angle = (i - 1) * (2 * math.pi / #healersAndCasters)
                local spreadRadius = math.random(0, 5)
                local targetX = baseX + spreadRadius * math.cos(angle)
                local targetY = baseY + spreadRadius * math.sin(angle)
                local targetZ = map:GetHeight(targetX, targetY)
                
                player:MoveTo(1, targetX, targetY, targetZ, true)
                if combatTime <= 8 and not player:HasAura(54861) then
                    player:AddAura(54861, player)
                end
            end
        end
    end
    
    local meleeDps = {}
    for _, player in ipairs(botPlayers) do
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
        local bx, by = baltharus:GetX(), baltharus:GetY()
        for _, player in ipairs(meleeDps) do
            if not IsInRearHalf(baltharus, player) then
                local offsetX = math.random(-2, 2)
                local offsetY = math.random(-2, 2)
                local behindX = bx - 3 + offsetX
                local behindY = by + offsetY
                local behindZ = map:GetHeight(behindX, behindY)
                player:MoveTo(1, behindX, behindY, behindZ, true)
                if combatTime <= 8 and not player:HasAura(54861) then
                    player:AddAura(54861, player)
                end
            end
        end
    end
    
    baltharus:RegisterEvent(BaltharusLoop, 200, 1)
end

local function BaltharusOnEnterCombat(event, creature, target)
    if not creature or creature:GetEntry() ~= 39751 then return end
    if IsLuaEventActive(creature) then return end
    StartLuaEvent(creature, BaltharusLoop)
end

RegisterCreatureEvent(39751, 1, BaltharusOnEnterCombat)