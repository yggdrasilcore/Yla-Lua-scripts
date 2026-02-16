function IdentifyTanks(creature)
    local map = creature:GetMap()
    local instanceId = creature:GetInstanceId()
    local allPlayers = map:GetPlayers()
    
    local players = {}
    for _, player in ipairs(allPlayers) do
        if player:GetInstanceId() == instanceId and player:IsAlive() and player:IsInCombat() then
            table.insert(players, player)
        end
    end
    
    local group = nil
    for _, player in ipairs(players) do
        group = player:GetGroup()
        if group then break end
    end
    
    local realMainTank = nil
    local realOffTank = nil
    
    if group then
        for _, player in ipairs(players) do
            if IsMainTank(group, player) then
                realMainTank = player
            elseif IsOffTank(group, player) then
                realOffTank = player
            end
        end
    end
    
    local mainTank, offTank = nil, nil
    
    if realMainTank and realOffTank then
        mainTank, offTank = realMainTank, realOffTank
    else
        local function getCachedTank(dataKey)
            local tankName = creature:GetData(dataKey)
            if tankName then
                for _, player in ipairs(players) do
                    if player:GetName() == tankName and player:IsAlive() and player:IsInCombat() then
                        return player
                    end
                end
                creature:SetData(dataKey, nil)
            end
            return nil
        end
        
        local function findBestBotTank(exclude1, exclude2)
            local botTanks = {}
            for _, player in ipairs(players) do
                if isPlayerBot[player:GetName()] and IsTank(player) then
                    if (not exclude1 or player:GetGUID() ~= exclude1:GetGUID()) and (not exclude2 or player:GetGUID() ~= exclude2:GetGUID()) then
                        table.insert(botTanks, player)
                    end
                end
            end
            
            if #botTanks > 0 then
                table.sort(botTanks, function(a, b) return a:GetMaxHealth() > b:GetMaxHealth() end)
                return botTanks[1]
            end
            return nil
        end
        
        if realMainTank and not realOffTank then
            local cachedOffTank = getCachedTank("CachedOffTank")
            if cachedOffTank then
                mainTank, offTank = realMainTank, cachedOffTank
            else
                local botOffTank = findBestBotTank(realMainTank)
                if botOffTank then
                    if creature:GetData("CachedMainTank") == botOffTank:GetName() then
                        creature:SetData("CachedMainTank", nil)
                    end
                    creature:SetData("CachedOffTank", botOffTank:GetName())
                    mainTank, offTank = realMainTank, botOffTank
                else
                    mainTank, offTank = realMainTank, nil
                end
            end
        elseif realOffTank and not realMainTank then
            local cachedMainTank = getCachedTank("CachedMainTank")
            if cachedMainTank then
                mainTank, offTank = cachedMainTank, realOffTank
            else
                local botMainTank = findBestBotTank(realOffTank)
                if botMainTank then
                    if creature:GetData("CachedOffTank") == botMainTank:GetName() then
                        creature:SetData("CachedOffTank", nil)
                    end
                    creature:SetData("CachedMainTank", botMainTank:GetName())
                    mainTank, offTank = botMainTank, realOffTank
                else
                    mainTank, offTank = nil, realOffTank
                end
            end
        else
            local cachedMainTank = getCachedTank("CachedMainTank")
            local cachedOffTank = getCachedTank("CachedOffTank")
            
            if cachedMainTank and cachedOffTank then
                mainTank, offTank = cachedMainTank, cachedOffTank
            else
                local botTanks = {}
                for _, player in ipairs(players) do
                    if isPlayerBot[player:GetName()] and IsTank(player) then
                        table.insert(botTanks, player)
                    end
                end
                
                if #botTanks >= 2 then
                    table.sort(botTanks, function(a, b) return a:GetMaxHealth() > b:GetMaxHealth() end)
                    if creature:GetData("CachedOffTank") == botTanks[1]:GetName() then
                        creature:SetData("CachedOffTank", nil)
                    end
                    creature:SetData("CachedMainTank", botTanks[1]:GetName())
                    if creature:GetData("CachedMainTank") == botTanks[2]:GetName() then
                        creature:SetData("CachedMainTank", nil)
                    end
                    creature:SetData("CachedOffTank", botTanks[2]:GetName())
                    mainTank, offTank = botTanks[1], botTanks[2]
                elseif #botTanks == 1 then
                    if creature:GetData("CachedOffTank") == botTanks[1]:GetName() then
                        creature:SetData("CachedOffTank", nil)
                    end
                    creature:SetData("CachedMainTank", botTanks[1]:GetName())
                    mainTank, offTank = botTanks[1], nil
                end
            end
        end
    end
    
    if mainTank and offTank and mainTank:GetGUID() == offTank:GetGUID() then
        offTank = nil
        creature:SetData("CachedOffTank", nil)
    end
    
    local lastMain = creature:GetData("LastAssignedMain")
    local lastOff = creature:GetData("LastAssignedOff")
    local currentMain = mainTank and mainTank:GetName() or nil
    local currentOff = offTank and offTank:GetName() or nil
    
    if currentMain ~= lastMain or currentOff ~= lastOff then
        print(string.format("[IdentifyTanks] Tanks assigned - Main: %s, Off: %s", currentMain or "none", currentOff or "none"))
        creature:SetData("LastAssignedMain", currentMain)
        creature:SetData("LastAssignedOff", currentOff)
    end
    
    return mainTank, offTank
end