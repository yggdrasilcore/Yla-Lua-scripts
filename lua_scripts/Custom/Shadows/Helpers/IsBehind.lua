function IsInRearHalf(boss, player)
    local bx, by, bz = boss:GetLocation()
    local px, py, pz = player:GetLocation()
    local orientation = boss:GetO()
    
    local dx = px - bx
    local dy = py - by
    local angleToPlayer = math.atan2(dy, dx)
    local relativeAngle = angleToPlayer - orientation
    
    while relativeAngle > math.pi do relativeAngle = relativeAngle - 2 * math.pi end
    while relativeAngle < -math.pi do relativeAngle = relativeAngle + 2 * math.pi end
    
    return math.abs(relativeAngle) > math.pi / 2
end

function IsBehind(boss, player)
    IsInRearHalf(boss, player)
end
