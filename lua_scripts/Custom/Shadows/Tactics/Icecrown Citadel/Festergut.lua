local function FestergutLoop(eventId, delay, repeats, festergut)
    if festergut:IsDead() or not festergut:IsInCombat() then
        StopLuaEvent(festergut)
        return
    end
    
    local players = festergut:GetPlayersInRange(100)
    local validPlayers = {}
    
    for _, player in ipairs(players) do
        if player:IsAlive() and player:IsInCombat() and isPlayerBot[player:GetName()] then
            table.insert(validPlayers, player)
        end
    end
    
    if #validPlayers == 0 then
        StopLuaEvent(festergut)
        return
    end
    
    local anySporeActive = false
    for _, player in ipairs(validPlayers) do
        if player:HasAura(69278) or player:HasAura(69279) or player:HasAura(71221) then
            anySporeActive = true
            break
        end
    end
    
    if anySporeActive then
        festergut:RegisterEvent(FestergutLoop, 200, 1)
        return
    end
    
    for _, player in ipairs(validPlayers) do
        if not IsTank(player) then
            if not IsInRearHalf(festergut, player) then
                local offsetX = math.random(-3, 3)
                local offsetY = math.random(-3, 3)
                local bx, by, bz = festergut:GetLocation()
                player:MoveTo(1, bx + offsetX, by + offsetY, bz, true)
            end
        end
    end
    
    festergut:RegisterEvent(FestergutLoop, 200, 1)
end

local function FestergutOnEnterCombat(event, player, festergut)
    if festergut and festergut:GetEntry() == 36626 then
        StartLuaEvent(festergut, FestergutLoop)
    end
end

RegisterPlayerEvent(33, FestergutOnEnterCombat)

function MalleableGooAvoidance(eventId, delay, repeats, festergut)
    local avoidDistance = 13
    local destX = festergut:GetData("GooX")
    local destY = festergut:GetData("GooY")
    local destZ = festergut:GetData("GooZ")
    
    if not destX or not destY or not destZ then
        festergut:RemoveEventById(eventId)
        return
    end
    
    local players = festergut:GetPlayersInRange(100)
    local gasSporePlayer = nil
    local gasSporeNearGoo = false
    
    for _, player in ipairs(players) do
        if player:IsAlive() and player:IsInCombat() then
            local hasGasSpore = player:HasAura(69278) or player:HasAura(69279) or player:HasAura(71221)
            
            if hasGasSpore then
                gasSporePlayer = player
                
                if isPlayerBot[player:GetName()] then
                    local px, py, pz = player:GetLocation()
                    local distance = math.sqrt((px - destX)^2 + (py - destY)^2 + (pz - destZ)^2)
                    
                    if distance < avoidDistance then
                        gasSporeNearGoo = true
                        local dx = px - destX
                        local dy = py - destY
                        local length = math.sqrt(dx^2 + dy^2)
                        
                        if length == 0 then
                            local angle = math.random() * 2 * math.pi
                            dx = math.cos(angle)
                            dy = math.sin(angle)
                        else
                            dx = dx / length
                            dy = dy / length
                        end
                        
                        local newX = destX + dx * 15
                        local newY = destY + dy * 15
                        
                        player:MoveTo(1, newX, newY, pz, true)
                    end
                end
                break
            end
        end
    end
    
    if gasSporePlayer and not gasSporeNearGoo then
        return
    end
    
    if gasSporePlayer and gasSporeNearGoo then
        local spx, spy, spz = gasSporePlayer:GetLocation()
        
        for _, player in ipairs(players) do
            if player:IsAlive() and player:IsInCombat() and isPlayerBot[player:GetName()] and player ~= gasSporePlayer then
                local px, py, pz = player:GetLocation()
                local distance = math.sqrt((px - destX)^2 + (py - destY)^2 + (pz - destZ)^2)
                
                if distance < avoidDistance then
                    player:MoveTo(1, spx, spy, spz, true)
                end
            end
        end
    else
        for _, player in ipairs(players) do
            if player:IsAlive() and player:IsInCombat() and isPlayerBot[player:GetName()] then
                local px, py, pz = player:GetLocation()
                local distance = math.sqrt((px - destX)^2 + (py - destY)^2 + (pz - destZ)^2)
                
                if distance < avoidDistance then
                    local dx = px - destX
                    local dy = py - destY
                    local length = math.sqrt(dx^2 + dy^2)
                    
                    if length == 0 then
                        local angle = math.random() * 2 * math.pi
                        dx = math.cos(angle)
                        dy = math.sin(angle)
                    else
                        dx = dx / length
                        dy = dy / length
                    end
                    
                    local newX = destX + dx * 15
                    local newY = destY + dy * 15
                    
                    player:MoveTo(1, newX, newY, pz, true)
                end
            end
        end
    end
end

function OnMalleableGooCast(event, caster, spell, skipCheck)
    local target = spell:GetTarget()
    local x, y, z = spell:GetTargetDest()
    
    if target then
        local festergut = target:GetNearestCreature(100, 36626, 0)
        
        if festergut then
            festergut:SetData("GooX", x)
            festergut:SetData("GooY", y)
            festergut:SetData("GooZ", z)
            festergut:RegisterEvent(MalleableGooAvoidance, 400, 20)
        end
    end
end

RegisterSpellEvent(72296, 2, OnMalleableGooCast)