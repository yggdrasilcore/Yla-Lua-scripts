-- NPCs
local HALION_ENTRY          = 39863
local COMBUSTION_ENTRY      = 40001
local CONSUMPTION_ENTRY     = 40135
local METEOR_STRIKES_ENTRY  = {40029, 40041, 40042, 40043, 40044, 40055}

local HALION_INSIDE_ENTRY   = 40142
local CONSUMPTION_ENTRY     = 40135
local SHADOW_ORB            = 40083
local SHADOW_ORB_2          = 40100

local TWILIGHT_PORTAL       = {202794, 202795, 202796}

local COMBUSTION_AURA       = 74562
local CONSUMPTION_AURA      = 74792
local TWILIGHT_REALM        = 74807

local PULL_POS              = {3142.5, 534.3, 72.88}
local ORB_CENTER_POS        = {3153.75, 533.19, 72.88}

local AVERAGE_BOSS_DISTANCE        = 25
local AVERAGE_BOSS_DISTANCE_INSIDE = 20
local SPREAD_FACTOR                = 12.5
local SPREAD_FACTOR_INSIDE         = 5

local PORTAL_DISTANCE              = 8
local AOE_AVOIDANCE_DISTANCE       = 15

local TICK_FREQUENCY        = 200

local function GetAllBotsInInstance(instanceId)
    local bots = {}
    local allPlayers = GetPlayersInWorld()
    for _, player in ipairs(allPlayers) do
        if isPlayerBot[player:GetName()] then
            local bot = GetPlayerByName(player:GetName())
            if bot and bot:GetInstanceId() == instanceId and bot:IsInCombat() and bot:IsAlive() then
                table.insert(bots, bot)
            end
        end
    end
    return bots
end

local function GetRoleArraysFromBots(bots)
    local tanks = {}
    local healers = {}
    local melee = {}
    local casters = {}
    
    for _, player in ipairs(bots) do
        if IsTank(player) then
            table.insert(tanks, player)
        end
        if player:HasHealSpec() then
            table.insert(healers, player)
        end
        if player:HasMeleeSpec() then
            table.insert(melee, player)
        end
        if player:HasCasterSpec() then
            table.insert(casters, player)
        end
    end
    
    table.sort(tanks, function(a, b) return a:GetMaxHealth() > b:GetMaxHealth() end)
    table.sort(healers, function(a, b) return a:GetMaxPower(0) > b:GetMaxPower(0) end)
    
    return tanks, healers, melee, casters
end

local function HalionInsideLoop(eventId, delay, repeats, player)
    if not player:HasAura(TWILIGHT_REALM) or not player:IsInCombat() then
        StopLuaEvent(player)
        return
    end
    
    local halionInside = player:GetNearestCreature(100, HALION_INSIDE_ENTRY)
    
    if not halionInside then
        player:RegisterEvent(HalionInsideLoop, TICK_FREQUENCY, 1)
        return
    end
    
    local instanceId = player:GetInstanceId()
    local bots = GetAllBotsInInstance(instanceId)
    local tanks, healers, melee, casters = GetRoleArraysFromBots(bots)
    local insideTank = tanks[1]
    
    if halionInside:IsCasting() and player == insideTank then
        UseDefensive(player)
    end
    
    if not player:HasAura(CONSUMPTION_AURA) then
        player:SetData("ConsumptionPos", nil)
    end
    
    if player == insideTank then
        local ocX, ocY, ocZ = ORB_CENTER_POS[1], ORB_CENTER_POS[2], ORB_CENTER_POS[3]
        local shadowOrbs = {}
        
        local orbs1 = player:GetCreaturesInRange(100, SHADOW_ORB)
        local orbs2 = player:GetCreaturesInRange(100, SHADOW_ORB_2)
        
        for _, orb in ipairs(orbs1) do
            table.insert(shadowOrbs, orb)
        end
        for _, orb in ipairs(orbs2) do
            table.insert(shadowOrbs, orb)
        end
        
        if #shadowOrbs >= 1 then
            local orb1X, orb1Y = shadowOrbs[1]:GetLocation()
            
            local angleToOrb = math.atan2(orb1Y - ocY, orb1X - ocX)
            local tankAngle = angleToOrb - math.rad(30)
            
            local targetX = ocX + (10 * math.cos(tankAngle))
            local targetY = ocY + (10 * math.sin(tankAngle))
            
            if not IsAtPos(player, targetX, targetY, 2) then
                print("Inside tank " .. player:GetName() .. " moving to orb position: (" .. targetX .. ", " .. targetY .. ", " .. ocZ .. ")")
                player:MoveTo(1, targetX, targetY, ocZ, true)
            end
            
            if IsAtPos(player, targetX, targetY, 2) then
                local hix, hiy = halionInside:GetLocation()
                local distToCenter = math.sqrt((hix - ocX)^2 + (hiy - ocY)^2)
                if distToCenter > 3 then
                    halionInside:MoveTo(1, ocX, ocY, ocZ, true)
                end
            end
        end
        
    elseif player:HasAura(CONSUMPTION_AURA) then
        local INSIDE_DANGER_NPCS = {CONSUMPTION_ENTRY}
        MoveForConsumption(player, halionInside, INSIDE_DANGER_NPCS)
    else
        if not player:HasAura(CONSUMPTION_AURA) then
            local INSIDE_DANGER_NPCS = {CONSUMPTION_ENTRY}
            
            local targetPos = player:GetData("HalionInsidePos")
            
            if targetPos then
                local px, py, pz = player:GetLocation()
                local currentPos = {x = px, y = py, z = pz}
                
                if halionInside and not IsPositionValidInSideArea(currentPos, halionInside, "left", AVERAGE_BOSS_DISTANCE_INSIDE, SPREAD_FACTOR_INSIDE, AOE_AVOIDANCE_DISTANCE, INSIDE_DANGER_NPCS) then
                    if IsPositionValidInSideArea(targetPos, halionInside, "left", AVERAGE_BOSS_DISTANCE_INSIDE, SPREAD_FACTOR_INSIDE, AOE_AVOIDANCE_DISTANCE, INSIDE_DANGER_NPCS) then
                        print("Inside player " .. player:GetName() .. " moving to saved position: (" .. targetPos.x .. ", " .. targetPos.y .. ", " .. targetPos.z .. ")")
                        player:MoveTo(1, targetPos.x, targetPos.y, targetPos.z, true)
                    else
                        FindAndMoveToInsidePosition(player, halionInside, INSIDE_DANGER_NPCS)
                    end
                end
            else
                FindAndMoveToInsidePosition(player, halionInside, INSIDE_DANGER_NPCS)
            end
        end
    end
    
    player:RegisterEvent(HalionInsideLoop, TICK_FREQUENCY, 1)
end

local function HalionLoop(eventId, delay, repeats, halion)
    if halion:IsDead() or not halion:IsInCombat() then
        halion:SetData("PortalTransitionPrinted", nil)
        StopLuaEvent(halion)
        return
    end
    
    local instanceId = halion:GetInstanceId()
    local bots = GetAllBotsInInstance(instanceId)
    
    if #bots == 0 then StopLuaEvent(halion) return end
    
    local tanks, healers, melee, casters = GetRoleArraysFromBots(bots)
    
    halion:SetData("CombatTime", (halion:GetData("CombatTime") or 0) + TICK_FREQUENCY)
    
    local victim = halion:GetVictim()
    
    local DANGER_NPCS = {COMBUSTION_ENTRY}
    for _, id in ipairs(METEOR_STRIKES_ENTRY) do
        table.insert(DANGER_NPCS, id)
    end
    
    if halion:IsCasting() then 
        for _, tank in ipairs(tanks) do
            if not tank:HasAura(TWILIGHT_REALM) then
                UseDefensive(tank)
            end
        end
    end

    if victim then
        if IsAtPos(victim, ORB_CENTER_POS[1], ORB_CENTER_POS[2], 13) then
            if not IsAtPos(halion, ORB_CENTER_POS[1], ORB_CENTER_POS[2], 3) then
                halion:MoveTo(1, ORB_CENTER_POS[1], ORB_CENTER_POS[2], ORB_CENTER_POS[3], true)
            end
        end
    end
    
    for _, player in ipairs(bots) do
        DisableDispels(player)
        
        if not player:HasAura(TWILIGHT_REALM) then
            if player:HasAura(COMBUSTION_AURA) then
                MoveForCombustion(player, halion, DANGER_NPCS)
            else
                if (player == victim or player == tanks[2]) and not player:HasAura(TWILIGHT_REALM) then
                    if halion:GetData("CombatTime") < 5000 then
                        player:MoveTo(1, PULL_POS[1], PULL_POS[2], PULL_POS[3], true)
                    
                    elseif halion:GetData("CombatTime") < 8000 then
                        local victim = halion:GetVictim()
                        if victim then
                            if IsAtPos(victim, ORB_CENTER_POS[1], ORB_CENTER_POS[2], 10) then
                                if not IsAtPos(halion, ORB_CENTER_POS[1], ORB_CENTER_POS[2], 3) then
                                    halion:MoveTo(1, ORB_CENTER_POS[1], ORB_CENTER_POS[2], ORB_CENTER_POS[3], true)
                                end
                            end
                        end
                    else
                        local cachedPos = player:GetData("TankSafePos")
                        local needsRecalc = false
                        
                        if cachedPos then
                            local dangerNpcs = {}
                            for _, entry in ipairs(DANGER_NPCS) do
                                local npcs = player:GetCreaturesInRange(100, entry)
                                for _, npc in ipairs(npcs) do
                                    table.insert(dangerNpcs, npc)
                                end
                            end
                            
                            for _, danger in ipairs(dangerNpcs) do
                                local dx, dy = danger:GetLocation()
                                local distToDanger = math.sqrt((cachedPos.x - dx)^2 + (cachedPos.y - dy)^2)
                                if distToDanger < AOE_AVOIDANCE_DISTANCE then
                                    needsRecalc = true
                                    break
                                end
                            end
                        else
                            needsRecalc = true
                        end
                        
                        if needsRecalc then
                            local dangerNpcs = {}
                            for _, entry in ipairs(DANGER_NPCS) do
                                local npcs = player:GetCreaturesInRange(100, entry)
                                for _, npc in ipairs(npcs) do
                                    table.insert(dangerNpcs, npc)
                                end
                            end
                            
                            local centerX, centerY, centerZ = ORB_CENTER_POS[1], ORB_CENTER_POS[2], ORB_CENTER_POS[3]
                            
                            local bestX, bestY, bestZ = PULL_POS[1], PULL_POS[2], PULL_POS[3]
                            local bestDist = 999999
                            
                            for angle = 0, 350, 10 do
                                local rad = math.rad(angle)
                                local testX = centerX + (10 * math.cos(rad))
                                local testY = centerY + (10 * math.sin(rad))
                                
                                local valid = true
                                for _, danger in ipairs(dangerNpcs) do
                                    local dx, dy = danger:GetLocation()
                                    if math.sqrt((testX - dx)^2 + (testY - dy)^2) < AOE_AVOIDANCE_DISTANCE then
                                        valid = false
                                        break
                                    end
                                end
                                
                                if valid then
                                    local dist = math.sqrt((testX - PULL_POS[1])^2 + (testY - PULL_POS[2])^2)
                                    if dist < bestDist then
                                        bestDist = dist
                                        bestX, bestY, bestZ = testX, testY, centerZ
                                    end
                                end
                            end
                            
                            player:SetData("TankSafePos", {x = bestX, y = bestY, z = bestZ})
                            cachedPos = {x = bestX, y = bestY, z = bestZ}
                        end
                        
                        if cachedPos and not IsAtPos(player, cachedPos.x, cachedPos.y, 3) then
                            player:MoveTo(1, cachedPos.x, cachedPos.y, cachedPos.z, true)
                        end
                    end
                end
            end
        end
    end

    if halion:GetHealthPct() >= 75 or halion:GetHealthPct() < 50 then
        local METEOR_NPCS = {}
        for _, id in ipairs(METEOR_STRIKES_ENTRY) do
            table.insert(METEOR_NPCS, id)
        end
        
        local POSITION_DANGER_NPCS = {COMBUSTION_ENTRY}
        for _, id in ipairs(METEOR_STRIKES_ENTRY) do
            table.insert(POSITION_DANGER_NPCS, id)
        end
        
        for _, player in ipairs(bots) do
            if not player:HasAura(TWILIGHT_REALM) then
                if player ~= victim and player ~= tanks[2]
                and not player:HasAura(COMBUSTION_AURA) and not player:HasAura(CONSUMPTION_AURA) then
                    local behindWaypoint = player:GetData("BehindWaypoint")
                    
                    if behindWaypoint then
                        if IsAtPos(player, behindWaypoint.x, behindWaypoint.y, 3) then
                            player:SetData("BehindWaypoint", nil)
                            local targetPos = player:GetData("HalionPos")
                            if targetPos then
                                print("Player " .. player:GetName() .. " reached behind waypoint, moving to final position: (" .. targetPos.x .. ", " .. targetPos.y .. ", " .. targetPos.z .. ")")
                                player:MoveTo(1, targetPos.x, targetPos.y, targetPos.z, true)
                            end
                        end
                    else
                        local targetPos = player:GetData("HalionPos")
                        local savedSide = player:GetData("HalionSide")
                        
                        if targetPos and savedSide then
                            local px, py, pz = player:GetLocation()
                            local currentPos = {x = px, y = py, z = pz}
                            
                            if halion and not IsPositionValidInSideArea(currentPos, halion, savedSide, AVERAGE_BOSS_DISTANCE, SPREAD_FACTOR, AOE_AVOIDANCE_DISTANCE, POSITION_DANGER_NPCS) then
                                local nearbyDangers = {}
                                for _, entry in ipairs(POSITION_DANGER_NPCS) do
                                    local npcs = player:GetCreaturesInRange(AOE_AVOIDANCE_DISTANCE + 5, entry)
                                    for _, npc in ipairs(npcs) do
                                        local nx, ny = npc:GetLocation()
                                        local dist = math.sqrt((px - nx)^2 + (py - ny)^2)
                                        table.insert(nearbyDangers, "NPC " .. entry .. " at distance " .. string.format("%.1f", dist))
                                    end
                                end
                                
                                local hx, hy = halion:GetLocation()
                                local dx = px - hx
                                local dy = py - hy
                                local posAngle = math.atan2(dy, dx)
                                local posDist = math.sqrt(dx*dx + dy*dy)
                                local relativeAngle = posAngle - halion:GetO()
                                while relativeAngle > math.pi do relativeAngle = relativeAngle - 2 * math.pi end
                                while relativeAngle < -math.pi do relativeAngle = relativeAngle + 2 * math.pi end
                                
                                local invalidReason = ""
                                if savedSide == "left" then
                                    if relativeAngle < math.pi / 4 or relativeAngle > 3 * math.pi / 4 then
                                        invalidReason = "wrong side (angle: " .. string.format("%.2f", relativeAngle) .. ", need π/4 to 3π/4)"
                                    end
                                elseif savedSide == "right" then
                                    if relativeAngle > -math.pi / 4 or relativeAngle < -3 * math.pi / 4 then
                                        invalidReason = "wrong side (angle: " .. string.format("%.2f", relativeAngle) .. ", need -3π/4 to -π/4)"
                                    end
                                end
                                
                                if posDist < AVERAGE_BOSS_DISTANCE - SPREAD_FACTOR or posDist > AVERAGE_BOSS_DISTANCE + SPREAD_FACTOR then
                                    if invalidReason ~= "" then invalidReason = invalidReason .. ", " end
                                    invalidReason = invalidReason .. "wrong distance (" .. string.format("%.1f", posDist) .. ", need " .. (AVERAGE_BOSS_DISTANCE - SPREAD_FACTOR) .. "-" .. (AVERAGE_BOSS_DISTANCE + SPREAD_FACTOR) .. ")"
                                end
                                
                                if #nearbyDangers > 0 then
                                    if invalidReason ~= "" then invalidReason = invalidReason .. ", " end
                                    invalidReason = invalidReason .. table.concat(nearbyDangers, ", ")
                                end
                                
                                print("Player " .. player:GetName() .. " position invalid due to: " .. invalidReason)
                                
                                if IsPositionValidInSideArea(targetPos, halion, savedSide, AVERAGE_BOSS_DISTANCE, SPREAD_FACTOR, AOE_AVOIDANCE_DISTANCE, POSITION_DANGER_NPCS) then
                                    print("Player " .. player:GetName() .. " moving to saved position: (" .. targetPos.x .. ", " .. targetPos.y .. ", " .. targetPos.z .. ")")
                                    player:MoveTo(1, targetPos.x, targetPos.y, targetPos.z, true)
                                else
                                    print("Player " .. player:GetName() .. " saved position also invalid, finding new position")
                                    FindAndMoveToPosition(player, halion, savedSide, METEOR_NPCS, POSITION_DANGER_NPCS)
                                end
                            end
                        else
                            FindAndMoveToPosition(player, halion, "left", METEOR_NPCS, POSITION_DANGER_NPCS)
                        end
                    end
                end
            end
        end
    end

    if halion:GetHealthPct() < 75 and halion:GetHealthPct() >= 50 then
        if not halion:GetData("PortalTransitionPrinted") then
            print("=== PORTAL TRANSITION (75%-50%) ===")
            print("Tank2: " .. (tanks[2] and tanks[2]:GetName() or "none"))
            print("Healer2: " .. (healers[2] and healers[2]:GetName() or "none"))
            halion:SetData("PortalTransitionPrinted", true)
        end
        
        local nearestPortal = GetNearestObject(halion, "GameObject", TWILIGHT_PORTAL, 100)
        
        if nearestPortal then
            local portalX, portalY, portalZ = nearestPortal:GetLocation()
            
            for _, player in ipairs(bots) do
                if player ~= tanks[2] and player ~= healers[2]
                and not player:HasAura(COMBUSTION_AURA) and not player:HasAura(CONSUMPTION_AURA) then
                    if not player:HasAura(TWILIGHT_REALM) then
                        print(player:GetName() .. " heading to portal")
                        if not IsAtPos(player, portalX, portalY, PORTAL_DISTANCE) then
                            player:MoveTo(1, portalX, portalY, portalZ, true)
                        else
                            StartLuaEvent(player, HalionInsideLoop)
                            player:AddAura(TWILIGHT_REALM, player)
                        end
                    end
                else
                    print(player:GetName() .. " staying outside (excluded or has debuff)")
                end
            end
        end
    end
    
    if halion:GetHealthPct() < 50 then
        HandlePhase3Transition(halion, bots, tanks, healers)
    end

    if halion:GetHealthPct() < 50 then
    end
    
    halion:RegisterEvent(HalionLoop, TICK_FREQUENCY, 1)
end

local function HalionOnEnterCombat(event, player, halion)
    if halion and halion:GetEntry() == HALION_ENTRY then
        player:SetData("HalionPos", nil)
        player:SetData("HalionSide", nil)
        player:SetData("HalionInsidePos", nil)
        player:SetData("HalionInsideSide", nil)
        player:SetData("CombustionPos", nil)
        player:SetData("ConsumptionPos", nil)
        player:SetData("TankSafePos", nil)
        player:SetData("OutsideGroup", nil)
        player:SetData("InsideGroup", nil)
        player:SetData("BehindWaypoint", nil)
        
        halion:SetData("CombatTime", 0)
        
        StartLuaEvent(halion, HalionLoop)
    end
end

RegisterPlayerEvent(33, HalionOnEnterCombat)

function FindAndMoveToPosition(player, halion, startSide, sideSelectionDangerNpcs, positionDangerNpcs)
    local meteorObjects = {}
    for _, entry in ipairs(METEOR_STRIKES_ENTRY) do
        local npcs = halion:GetCreaturesInRange(200, entry)
        for _, npc in ipairs(npcs) do
            table.insert(meteorObjects, npc)
        end
    end
    
    local chosenSide = "left"
    
    if #meteorObjects > 0 then
        local leftMeteors = 0
        local rightMeteors = 0
        
        for _, meteor in ipairs(meteorObjects) do
            local dx, dy = meteor:GetLocation()
            local hx, hy = halion:GetLocation()
            local angle = math.atan2(dy - hy, dx - hx)
            local facingAngle = halion:GetO()
            local relativeAngle = angle - facingAngle
            
            while relativeAngle > math.pi do relativeAngle = relativeAngle - 2 * math.pi end
            while relativeAngle < -math.pi do relativeAngle = relativeAngle + 2 * math.pi end
            
            if relativeAngle > math.pi / 4 and relativeAngle < 3 * math.pi / 4 then
                leftMeteors = leftMeteors + 1
            elseif relativeAngle < -math.pi / 4 and relativeAngle > -3 * math.pi / 4 then
                rightMeteors = rightMeteors + 1
            end
        end
        
        chosenSide = leftMeteors <= rightMeteors and "left" or "right"
    end
    
    local savedSide = player:GetData("HalionSide")
    local needsSideSwitch = savedSide and savedSide ~= chosenSide
    
    if needsSideSwitch then
        local hx, hy, hz = halion:GetLocation()
        local facing = halion:GetO()
        local behindAngle = facing + math.pi
        local behindDist = 5
        local behindX = hx + behindDist * math.cos(behindAngle)
        local behindY = hy + behindDist * math.sin(behindAngle)
        
        player:SetData("HalionSide", chosenSide)
        player:SetData("HalionPos", nil)
        player:SetData("BehindWaypoint", {x = behindX, y = behindY, z = behindZ})
        
        UseSpeedBuff(player)
        player:MoveTo(1, behindX, behindY, hz, true)
        return
    end
    
    local validPos = GetRandomValidPositionInSideArea(halion, chosenSide, AVERAGE_BOSS_DISTANCE, SPREAD_FACTOR, AOE_AVOIDANCE_DISTANCE, positionDangerNpcs)
    
    if validPos then
        local hx, hy, hz = halion:GetLocation()
        local facing = halion:GetO()
        local px, py, pz = player:GetLocation()
        
        local pathCrossesFront = false
        local numSamples = 10
        
        for i = 1, numSamples do
            local t = i / numSamples
            local sampleX = px + t * (validPos.x - px)
            local sampleY = py + t * (validPos.y - py)
            
            local angleToSample = math.atan2(sampleY - hy, sampleX - hx)
            local relativeSample = angleToSample - facing
            
            while relativeSample > math.pi do relativeSample = relativeSample - 2 * math.pi end
            while relativeSample < -math.pi do relativeSample = relativeSample + 2 * math.pi end
            
            if relativeSample >= -math.pi/4 and relativeSample <= math.pi/4 then
                pathCrossesFront = true
                break
            end
        end
        
        if pathCrossesFront then
            local behindAngle = facing + math.pi
            local behindDist = 5
            local behindX = hx + behindDist * math.cos(behindAngle)
            local behindY = hy + behindDist * math.sin(behindAngle)
            
            player:SetData("HalionSide", chosenSide)
            player:SetData("HalionPos", validPos)
            player:SetData("BehindWaypoint", {x = behindX, y = behindY, z = behindZ})
            
            UseSpeedBuff(player)
            player:MoveTo(1, behindX, behindY, hz, true)
            return
        end
        
        player:SetData("HalionSide", chosenSide)
        player:SetData("HalionPos", validPos)
        
        local dx = validPos.x - px
        local dy = validPos.y - py
        local distance = math.sqrt(dx*dx + dy*dy)
        
        if distance > 30 then
            UseSpeedBuff(player)
        end
        
        player:MoveTo(1, validPos.x, validPos.y, validPos.z, true)
    end
end

function MoveForCombustion(player, halion, dangerNpcEntries)
    local dangerNpcs = {}
    for _, entry in ipairs(dangerNpcEntries) do
        local npcs = player:GetCreaturesInRange(100, entry)
        for _, npc in ipairs(npcs) do
            table.insert(dangerNpcs, npc)
        end
    end
    
    local ocX, ocY, ocZ = ORB_CENTER_POS[1], ORB_CENTER_POS[2], ORB_CENTER_POS[3]
    
    local savedPos = player:GetData("CombustionPos")
    
    if savedPos then
        local stillSafe = true
        for _, danger in ipairs(dangerNpcs) do
            local dx, dy = danger:GetLocation()
            local distToDanger = math.sqrt((savedPos.x - dx)^2 + (savedPos.y - dy)^2)
            if distToDanger < AOE_AVOIDANCE_DISTANCE then
                stillSafe = false
                break
            end
        end
        
        if stillSafe then
            if IsAtPos(player, savedPos.x, savedPos.y, 2) then
                player:CastSpell(player, 4987, true)
                player:SetData("CombustionPos", nil)
            else
                player:MoveTo(1, savedPos.x, savedPos.y, savedPos.z, true)
            end
            return
        end
    end
    
    local bestX, bestY, bestZ = nil, nil, nil
    local bestDist = 999999
    
    for angle = 0, 350, 10 do
        local rad = math.rad(angle)
        local testX = ocX + (45 * math.cos(rad))
        local testY = ocY + (45 * math.sin(rad))
        
        local valid = true
        for _, danger in ipairs(dangerNpcs) do
            local dx, dy = danger:GetLocation()
            local distToDanger = math.sqrt((testX - dx)^2 + (testY - dy)^2)
            if distToDanger < AOE_AVOIDANCE_DISTANCE then
                valid = false
                break
            end
        end
        
        if valid then
            local px, py = player:GetLocation()
            local dist = math.sqrt((testX - px)^2 + (testY - py)^2)
            if dist < bestDist then
                bestDist = dist
                bestX, bestY, bestZ = testX, testY, ocZ
            end
        end
    end
    
    if bestX then
        player:SetData("CombustionPos", {x = bestX, y = bestY, z = bestZ})
        UseSpeedBuff(player)
        DisableSpellCast(player, 2)
        player:MoveTo(1, bestX, bestY, bestZ, true)
    end
end

function MoveForConsumption(player, halionInside, dangerNpcEntries)
    local dangerNpcs = {}
    for _, entry in ipairs(dangerNpcEntries) do
        local npcs = player:GetCreaturesInRange(100, entry)
        for _, npc in ipairs(npcs) do
            table.insert(dangerNpcs, npc)
        end
    end
    
    local ocX, ocY, ocZ = ORB_CENTER_POS[1], ORB_CENTER_POS[2], ORB_CENTER_POS[3]
    
    local savedPos = player:GetData("ConsumptionPos")
    
    if savedPos then
        local stillSafe = true
        for _, danger in ipairs(dangerNpcs) do
            local dx, dy = danger:GetLocation()
            local distToDanger = math.sqrt((savedPos.x - dx)^2 + (savedPos.y - dy)^2)
            if distToDanger < AOE_AVOIDANCE_DISTANCE then
                stillSafe = false
                break
            end
        end
        
        if stillSafe then
            if IsAtPos(player, savedPos.x, savedPos.y, 2) then
                player:CastSpell(player, 4987, true)
                player:SetData("ConsumptionPos", nil)
            else
                DisableSpellCast(player, 2)
                player:MoveTo(1, savedPos.x, savedPos.y, savedPos.z, true)
            end
            return
        end
    end
    
    local bestX, bestY, bestZ = nil, nil, nil
    local bestDist = 999999

    local facingAngle = halionInside:GetO()
    local px, py, pz = player:GetLocation()

    for distance = 30, 50, 2 do
        local testX = px + (distance * math.cos(facingAngle))
        local testY = py + (distance * math.sin(facingAngle))
        
        local valid = true
        for _, danger in ipairs(dangerNpcs) do
            local dx, dy = danger:GetLocation()
            local distToDanger = math.sqrt((testX - dx)^2 + (testY - dy)^2)
            if distToDanger < AOE_AVOIDANCE_DISTANCE then
                valid = false
                break
            end
        end
        
        if valid then
            local dist = math.sqrt((testX - px)^2 + (testY - py)^2)
            if dist < bestDist then
                bestDist = dist
                bestX, bestY, bestZ = testX, testY, pz
            end
        end
    end
    
    if bestX then
        print("Consumption triggered for " .. player:GetName() .. " - Boss facing: " .. facingAngle .. " - Player location: (" .. px .. ", " .. py .. ", " .. pz .. ") - New location: (" .. bestX .. ", " .. bestY .. ", " .. bestZ .. ")")
        player:SetData("ConsumptionPos", {x = bestX, y = bestY, z = bestZ})
        UseSpeedBuff(player)
        DisableSpellCast(player, 2)
        player:MoveTo(1, bestX, bestY, bestZ, true)
    else
        print("No valid consumption position found for " .. player:GetName())
    end
end


function FindAndMoveToInsidePosition(player, halionInside, dangerNpcs)
    local validPos = GetRandomValidPositionInSideArea(halionInside, "left", AVERAGE_BOSS_DISTANCE_INSIDE, SPREAD_FACTOR_INSIDE, AOE_AVOIDANCE_DISTANCE, dangerNpcs)
    
    if validPos then
        player:SetData("HalionInsideSide", "left")
        player:SetData("HalionInsidePos", validPos)
        
        local px, py, pz = player:GetLocation()
        local dx = validPos.x - px
        local dy = validPos.y - py
        local distance = math.sqrt(dx*dx + dy*dy)
        
        if distance > 30 then
            UseSpeedBuff(player)
        end
        
        print("Inside player " .. player:GetName() .. " moving to new position: (" .. validPos.x .. ", " .. validPos.y .. ", " .. validPos.z .. ")")
        player:MoveTo(1, validPos.x, validPos.y, validPos.z, true)
    end
end

function HandlePhase3Transition(halion, bots, tanks, healers)
    local nonTankHealers = {}
    for _, player in ipairs(bots) do
        if player:IsAlive() and player ~= tanks[1] and player ~= tanks[2]
        and player ~= healers[1] and player ~= healers[2] then
            table.insert(nonTankHealers, player)
        end
    end
    
    table.sort(nonTankHealers, function(a, b)
        return a:GetMaxHealth() > b:GetMaxHealth()
    end)
    
    local outsideHP = 0
    local insideHP = 0
    
    if tanks[1] then
        if tanks[1]:HasAura(TWILIGHT_REALM) then
            insideHP = insideHP + tanks[1]:GetMaxHealth()
            tanks[1]:SetData("InsideGroup", true)
            tanks[1]:SetData("OutsideGroup", false)
            print("Tank1 " .. tanks[1]:GetName() .. " assigned to INSIDE group")
        else
            outsideHP = outsideHP + tanks[1]:GetMaxHealth()
            tanks[1]:SetData("OutsideGroup", true)
            tanks[1]:SetData("InsideGroup", false)
            print("Tank1 " .. tanks[1]:GetName() .. " assigned to OUTSIDE group")
        end
    end
    
    if tanks[2] then
        if tanks[2]:HasAura(TWILIGHT_REALM) then
            insideHP = insideHP + tanks[2]:GetMaxHealth()
            tanks[2]:SetData("InsideGroup", true)
            tanks[2]:SetData("OutsideGroup", false)
            print("Tank2 " .. tanks[2]:GetName() .. " assigned to INSIDE group")
        else
            outsideHP = outsideHP + tanks[2]:GetMaxHealth()
            tanks[2]:SetData("OutsideGroup", true)
            tanks[2]:SetData("InsideGroup", false)
            print("Tank2 " .. tanks[2]:GetName() .. " assigned to OUTSIDE group")
        end
    end
    
    for _, player in ipairs(nonTankHealers) do
        local hp = player:GetMaxHealth()
        if outsideHP <= insideHP then
            player:SetData("OutsideGroup", true)
            player:SetData("InsideGroup", false)
            outsideHP = outsideHP + hp
            print(player:GetName() .. " assigned to OUTSIDE group")
        else
            player:SetData("InsideGroup", true)
            player:SetData("OutsideGroup", false)
            insideHP = insideHP + hp
            print(player:GetName() .. " assigned to INSIDE group")
        end
    end
    
    local nearestPortal = GetNearestObject(halion, "GameObject", TWILIGHT_PORTAL, 100)
    if nearestPortal then
        local portalX, portalY, portalZ = nearestPortal:GetLocation()
        for _, player in ipairs(bots) do
            if not player:HasAura(COMBUSTION_AURA) and not player:HasAura(CONSUMPTION_AURA) then
                if player:GetData("OutsideGroup") and player:HasAura(TWILIGHT_REALM) then
                    print(player:GetName() .. " needs to exit portal (assigned OUTSIDE, currently INSIDE)")
                    if not IsAtPos(player, portalX, portalY, PORTAL_DISTANCE) then
                        player:AddAura(71638)
                        player:MoveTo(1, portalX, portalY, portalZ, true)
                    else
                        player:RemoveAura(TWILIGHT_REALM)
                        StopLuaEvent(player)
                        player:SetData("HalionInsideLoopStarted", false)
                    end
                end
                if player:GetData("InsideGroup") and not player:HasAura(TWILIGHT_REALM) then
                    print(player:GetName() .. " needs to enter portal (assigned INSIDE, currently OUTSIDE)")
                    if not IsAtPos(player, portalX, portalY, PORTAL_DISTANCE) then
                        player:AddAura(71638)
                        player:MoveTo(1, portalX, portalY, portalZ, true)
                    else
                        player:AddAura(TWILIGHT_REALM, player)
                        StartLuaEvent(player, HalionInsideLoop)
                    end
                end
            end
        end
    end
end
