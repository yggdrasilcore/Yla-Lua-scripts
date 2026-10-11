-- Multistate: Ruby Sanctum-only script (map 724).
if GetStateMapId() ~= 724 then return end

local function SavianaRagefireLoop(eventId, delay, repeats, saviana)
    if saviana:IsDead() or not saviana:IsInCombat() then StopLuaEvent(saviana) return  end
    
    local players = saviana:GetPlayersInRange(100)
    local validPlayers = {}
    
    for _, player in ipairs(players) do
        if player:IsAlive() and player:IsInCombat() and player:IsBot() then
            table.insert(validPlayers, player)
        end
    end
    
    if #validPlayers == 0 then StopLuaEvent(saviana) return end
    
    local bx, by, bz = saviana:GetLocation()
    local bossInFlightPhase = bz > 85
    
    local playersWithFlameBeacon = {}
    local playersWithConflagration = {}
    local otherPlayers = {}
    
    for _, player in ipairs(validPlayers) do
        if player:HasAura(74453) then
            table.insert(playersWithFlameBeacon, player)
        elseif player:HasAura(74455) then
            table.insert(playersWithConflagration, player)
        else
            table.insert(otherPlayers, player)
        end
    end
    
    local stackPos = {x = 3153, y = 627, z = 78.7}
    local spreadPos = {x = 3119, y = 616, z = 78.7}
    
    -- Gather mid during air phase
    if bossInFlightPhase and #playersWithConflagration == 0 then
        for _, player in ipairs(otherPlayers) do
            if not IsAtPos(player, stackPos.x, stackPos.y, 5) then
                local offsetX = math.random(-3, 3)
                local offsetY = math.random(-3, 3)
                player:MoveTo(1, stackPos.x + offsetX, stackPos.y + offsetY, stackPos.z, true)
            end
        end
    end
    
    -- Spread out Flame Beacons
    if bossInFlightPhase and #playersWithFlameBeacon > 0 then
        table.sort(playersWithFlameBeacon, function(a, b) return a:GetName() < b:GetName() end)
        
        local positions = CalculateSpreadPositions(stackPos, spreadPos, #playersWithFlameBeacon, 6, 15)
        
        for i, player in ipairs(playersWithFlameBeacon) do
            local map = player:GetMap()
            local groundZ = map:GetHeight(positions[i].x, positions[i].y)
            player:MoveTo(1, positions[i].x, positions[i].y, groundZ, true)
            UseRocketBoots(player)
            UseDefensive(player)
        end
    end
    
    -- Ground phase tactics
    if not bossInFlightPhase then
        local tanks = {}
        local dpsAndHealers = {}
        
        -- Find out who are the tanks
        for _, player in ipairs(validPlayers) do
            if not player:HasAura(74455) and IsTank(player) then    
                table.insert(tanks, player)
            else
                table.insert(dpsAndHealers, player)
            end
        end
        
        for _, tank in ipairs(tanks) do
            local victim = saviana:GetVictim()
            local victimIsTank
            if victim and victim:IsPlayer() and IsTank(victim) then victimIsTank = true end
            
            if not victimIsTank then
                -- Check if this tank has highest threat among all players
                local tankThreat = saviana:GetThreat(tank)
                local hasHighestThreat = true
                
                for _, player in ipairs(validPlayers) do
                    if saviana:GetThreat(player) > tankThreat then
                        hasHighestThreat = false
                        break
                    end
                end
                
                -- If no tank has highest threat, boost this tank's threat
                if not hasHighestThreat then
                    local highestThreat = 0
                    for _, player in ipairs(validPlayers) do
                        local threat = saviana:GetThreat(player)
                        if threat > highestThreat then
                            highestThreat = threat
                        end
                    end
                    local threatToAdd = 10000 + math.random(-500, 500)
                    saviana:AddThreat(tank, threatToAdd)
                end
            else
                if tank == victim and not IsAtPos(saviana, 3150, 643, 5) then
                    saviana:MoveTo(9999, 3150, 643, 79.4, true) -- Boss position failsafe
                end
            end
            
            if saviana:IsCasting() then -- Flame Breath
                UseDefensive(tank)
            end
            
            -- Move tanks in front of boss, by water
            if not IsAtPos(tank, 3149.7, 648.15, 1.5) then
			    UseRocketBoots(tank)
                tank:MoveTo(1, 3149.7, 648.15, 77.23, true)
            end
        end
        
        -- Position players behind boss
        for _, player in ipairs(dpsAndHealers) do
            if not IsInRearHalf(saviana, player) then
                local offsetX = math.random(-3, 3)
                local offsetY = math.random(-3, 3)
                if not IsAtPos(player, 3142 + offsetX, 631 + offsetY, 1.5) then
                    player:MoveTo(1, 3142 + offsetX, 631 + offsetY, 78.5, true)
                end
            end
        end
    end
    
    -- Hunters dispell Enrage
    for _, player in ipairs(validPlayers) do
        if player:GetClass() == 3 and saviana:HasAura(78722) and not player:HasAura(74455) then
            player:CastSpell(saviana, 19801, true)
        end
    end
    
    saviana:RegisterEvent(SavianaRagefireLoop, 200, 1)
end

local function SavianaRagefireOnEnterCombat(event, player, saviana)
    if saviana and saviana:GetEntry() == 39747 then
        StartLuaEvent(saviana, SavianaRagefireLoop)
    end
end

RegisterPlayerEvent(33, SavianaRagefireOnEnterCombat)