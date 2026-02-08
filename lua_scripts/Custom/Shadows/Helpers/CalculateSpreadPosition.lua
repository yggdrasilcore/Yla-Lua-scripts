function CalculateSpreadPositions(stackPos, spreadPos, numPlayers, spacing)
    local positions = {}
    
    local dirX = spreadPos.x - stackPos.x
    local dirY = spreadPos.y - stackPos.y
    local dist = math.sqrt(dirX^2 + dirY^2)
    dirX = dirX / dist
    dirY = dirY / dist
    
    local perpX = -dirY
    local perpY = dirX
    
    local objectWidth = 2.2 -- Roughly the width of a player
    local totalWidth = (numPlayers - 1) * spacing * objectWidth
    local minDistance = totalWidth / 2 + spacing
    
    for i = 1, numPlayers do
        local spreadOffset = ((i - 1) - (numPlayers - 1) / 2) * spacing * objectWidth
        
        positions[i] = {
            x = stackPos.x + dirX * minDistance + perpX * spreadOffset,
            y = stackPos.y + dirY * minDistance + perpY * spreadOffset,
            z = stackPos.z
        }
    end
    
    return positions
end