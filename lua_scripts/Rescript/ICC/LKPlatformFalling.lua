local function IsOnLKPlatform(x, y)
    local polygon = {
        {457, -2104},
        {478, -2083},
        {508, -2076},
        {537, -2089},
        {552, -2127},
        {536, -2163},
        {515, -2172},
        {482, -2168},
        {452, -2147},
        {457, -2104}
    }
    
    local inside = false
    local j = #polygon
    for i = 1, #polygon do
        local xi, yi = polygon[i][1], polygon[i][2]
        local xj, yj = polygon[j][1], polygon[j][2]
        
        if ((yi > y) ~= (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi) then
            inside = not inside
        end
        j = i
    end
    return inside
end

local function CheckPositions(eventid, delay, repeats, player)
    if not player:IsInCombat() or player:GetAreaId() ~= 4859 then
        player:SetData("PositionCheckActive", nil)
        RemoveEventById(eventid)
        return
    end
    
    local creatures = player:GetUnfriendlyUnitsInRange(1000)
    for _, creature in pairs(creatures) do
        if creature:GetAreaId() == 4859 then
            local z = creature:GetZ()
            if z < 838 then
                local x, y, o = creature:GetX(), creature:GetY(), creature:GetO()
                creature:NearTeleport(x, y, 840, o)
            end
        end
    end
    
    local px, py = player:GetX(), player:GetY()
    local name = player:GetName()
    if isPlayerBot[name] and IsOnLKPlatform(px, py) then
        local z = player:GetZ()
        if z < 838 then
            local x, y, o = player:GetX(), player:GetY(), player:GetO()
            player:Teleport(player:GetMapId(), x, y, 840, o)
        end
    end
end

local function OnEnterCombat(event, player, enemy)
    if not enemy then return end
    
    if not (player:GetAreaId() == 4859) then return end
    
    if not player:GetData("PositionCheckActive") then
        player:SetData("PositionCheckActive", true)
        player:RegisterEvent(CheckPositions, 1000, 1500)
    end
end

RegisterPlayerEvent(33, OnEnterCombat)