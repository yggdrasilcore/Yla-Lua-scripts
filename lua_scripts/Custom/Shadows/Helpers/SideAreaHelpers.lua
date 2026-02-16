function IsInSideArea(creature, player, side)
    local cx, cy, cz = creature:GetLocation()
    local o = creature:GetO()
    
    local px, py, pz = player:GetLocation()
    
    local dx = px - cx
    local dy = py - cy
    
    local angleToPlayer = math.atan2(dy, dx)
    local relativeAngle = angleToPlayer - o
    
    while relativeAngle > math.pi do relativeAngle = relativeAngle - 2 * math.pi end
    while relativeAngle < -math.pi do relativeAngle = relativeAngle + 2 * math.pi end
    
    if side == "left" then
        return relativeAngle > math.pi / 4 and relativeAngle < 3 * math.pi / 4
    elseif side == "right" then
        return relativeAngle < -math.pi / 4 and relativeAngle > -3 * math.pi / 4
    end
    
    return false
end

function GetRandomValidPositionInSideArea(creature, side, distance, offset, minAvoidance, dangerNpcIds)
    local cx, cy, cz = creature:GetLocation()
    local o = creature:GetO()
    
    for attempt = 1, 20 do
        local angle
        if side == "left" then
            angle = o + math.pi / 4 + math.random() * math.pi / 2
        elseif side == "right" then
            angle = o - 3 * math.pi / 4 + math.random() * math.pi / 2
        end
        
        local dist = distance + math.random(-offset, offset)
        local x = cx + dist * math.cos(angle)
        local y = cy + dist * math.sin(angle)
        
        local isSafe = true
        for _, npcId in ipairs(dangerNpcIds) do
            if not IsSafePosition(x, y, creature, npcId, minAvoidance, 100) then
                isSafe = false
                break
            end
        end
        
        if isSafe then
            local z = creature:GetMap():GetHeight(x, y) or cz
            return {x = x, y = y, z = z}
        end
    end
    
    return nil
end

function IsPositionValidInSideArea(pos, creature, side, distance, offset, minAvoidance, dangerNpcIds)
    local cx, cy, cz = creature:GetLocation()
    local o = creature:GetO()
    
    local px, py = pos.x, pos.y
    local dx = px - cx
    local dy = py - cy
    local posAngle = math.atan2(dy, dx)
    local posDist = math.sqrt(dx*dx + dy*dy)
    
    local relativeAngle = posAngle - o
    while relativeAngle > math.pi do relativeAngle = relativeAngle - 2 * math.pi end
    while relativeAngle < -math.pi do relativeAngle = relativeAngle + 2 * math.pi end
    
    if side == "left" then
        if relativeAngle < math.pi / 4 or relativeAngle > 3 * math.pi / 4 then
            return false
        end
    elseif side == "right" then
        if relativeAngle > -math.pi / 4 or relativeAngle < -3 * math.pi / 4 then
            return false
        end
    end
    
    if posDist < distance - offset or posDist > distance + offset then
        return false
    end
    
    for _, npcId in ipairs(dangerNpcIds) do
        if not IsSafePosition(px, py, creature, npcId, minAvoidance, 100) then
            return false
        end
    end
    
    return true
end

function IsSafePosition(x, y, creature, npcId, minDistance, maxDistance)
    if type(npcId) == "number" then
        local npcs = creature:GetCreaturesInRange(maxDistance or 100, npcId)
        for _, npc in ipairs(npcs) do
            local npcX, npcY, npcZ = npc:GetLocation()
            local dx = x - npcX
            local dy = y - npcY
            local distance = math.sqrt(dx * dx + dy * dy)
            if distance < minDistance then
                return false
            end
        end
    else
        local npcX, npcY, npcZ = npcId:GetLocation()
        local dx = x - npcX
        local dy = y - npcY
        local distance = math.sqrt(dx * dx + dy * dy)
        if distance < minDistance then
            return false
        end
    end
    
    return true
end

function GoToSideArea(creature, player, side, distance, offset)
    local cx, cy, cz = creature:GetLocation()
    local o = creature:GetO()
    
    local angle
    if side == "left" then
        angle = o + math.pi / 2 + math.random() * math.pi / 2 - math.pi / 4
    elseif side == "right" then
        angle = o - math.pi / 2 - math.random() * math.pi / 2 + math.pi / 4
    end
    
    local dist = distance + math.random(-offset, offset)
    local x = cx + dist * math.cos(angle)
    local y = cy + dist * math.sin(angle)
    local z = creature:GetMap():GetHeight(x, y) or cz
    
    if not z then z = cz end
    
    player:MoveTo(1, x, y, z, true)
end