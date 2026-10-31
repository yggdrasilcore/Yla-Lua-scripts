if GetStateMapId() ~= 631 then return end

local function LichKingLoop(eventId, delay, repeats, lk)
    if lk:IsDead() or not lk:IsInCombat() then
        StopLuaEvent(lk)
        return
    end
    
    local mainTank, offTank = IdentifyTanks(lk)
    
	-- Dispell on p1 -> p2 transition
    local hp = lk:GetHealthPct()
    local players = lk:GetPlayersInRange(100)
    local necroticAuras = {70337, 70338, 73785, 73786, 73787, 73912, 73913, 73914}
    
    if hp >= 65 and hp <= 70 then
        for _, player in pairs(players) do
            local name = player:GetName()
            if player:IsBot() then
                for _, auraId in ipairs(necroticAuras) do
                    if player:HasAura(auraId) then
                        player:CastSpell(player, 66116, true) -- Dispell necrotics from bots on phase transition
                        break
                    end
                end
            end
        end
    end
	
	-- Help orb damage on transitions
	if lk:IsCasting() and ((hp <= 70 and hp >= 55) or (hp <= 40 and hp >= 25)) then
		local currentTime = os.time()
		
		for _, player in pairs(players) do
			local name = player:GetName()
			if player:IsBot() then
				local ragingSpirit = player:GetNearestCreature(30, 36633)
				
				if ragingSpirit and not ragingSpirit:IsDead() then
					local lastAttackTime = player:GetData("LastSpiritAttack") or 0
					
					if currentTime - lastAttackTime >= 1 then
                        player:DealDamage(ragingSpirit, ragingSpirit:GetMaxHealth() * (math.random() * 0.01 + 0.005))
						player:SetData("LastSpiritAttack", currentTime)
					end
				end
			end
		end
	end
    
	-- P2: Handle Val'kyrs damage and tank positioning better
    if hp <= 70 and hp >= 42 then
        local valkyrs = lk:GetCreaturesInRange(100, 36609)
        local valkyrInAir = false
        local currentTime = os.time()
        
		for _, valkyr in pairs(valkyrs) do
			local vx, vy = valkyr:GetX(), valkyr:GetY()
            
            if valkyr:GetDistance2d(504, -2123) <= 43 then
                if valkyr:GetZ() > 846 then
                    valkyrInAir = true
                    
                    for _, player in pairs(players) do
                        if player:GetMap() and player:GetMap():IsHeroic() then
                            if player == offTank then -- Heroic, off tank taunts Val'kyrs
                                if not valkyr:HasAura(70428) then 
                                    player:AddAura(70428, valkyr)
                                elseif valkyr:HasAura(70428) then
                                    local tauntAura = valkyr:GetAura(70428)
                                    if tauntAura and tauntAura:GetDuration() < 200 then
                                        player:AddAura(70428, valkyr)
                                    end
                                end
                            end
                        end
                    end
                    
                else
                    for _, player in pairs(players) do
                        local name = player:GetName()
                        if player:IsBot() and not player:HasAura(68985) then      
                        
                            --[[
                        if player:HasMeleeSpec() then
                            print(name .. " has melee spec, distance: " .. player:GetDistance(valkyr))
                            if player:GetDistance(valkyr) > 5 then
                                print(name .. " moving to valkyr")
                                player:MoveTo(1, vx, vy, valkyr:GetZ(), true)
                            end
                        end
                        ]]

                            local lastAttackTime = player:GetData("LastValkyrAttack") or 0

                            if currentTime - lastAttackTime >= 1 then
                                local DMGtoDeal = (valkyr:GetMaxHealth() * (math.random() * 0.01 + 0.005)) / 2
                                player:DealDamage(valkyr, DMGtoDeal)
                                player:SetData("LastValkyrAttack", currentTime)
                                -- print("DPlayer "..player:GetName().." is damaging birdie for: "..DMGtoDeal.." HP!")
                            end
                        end
                    end
                end
            end
		end
        
        if valkyrInAir then
            local victim = lk:GetVictim()
            local lx, ly, lz = lk:GetLocation()
            
            for _, player in pairs(players) do
                local name = player:GetName()
                if player:IsBot() and player ~= victim then
                    local defileMoveTime = player:GetData("DefileMove") or 0
                    
                    if currentTime - defileMoveTime > 2.3 then
                        if not IsInRearHalf(lk, player) or player:GetDistance(lk) > 1 then
                            player:MoveTo(1, lx, ly, lz, true)
                        end
                    end
                end
            end
        end
        
        local victim = lk:GetVictim()
        
        if victim and victim:IsPlayer() then
            local tank = victim:ToPlayer()
            local name = tank:GetName()
            
            if victim:IsBot() and IsTank(tank) then
                if not IsAtPos(tank, 500, -2125, 5) then
                    local defiles = lk:GetCreaturesInRange(100, 38757)
                    local canMove = true
                    
                    if #defiles > 0 then
                        for _, defile in pairs(defiles) do
                            local distance = math.sqrt((500 - defile:GetX())^2 + (-2125 - defile:GetY())^2)
                            local stacks = 0
                            
                            if defile:HasAura(72756) then
                                local aura = defile:GetAura(72756)
                                if aura then
                                    stacks = aura:GetStackAmount()
                                end
                            end
                            
                            local minDistance = 10 + stacks
                            
                            if distance < minDistance then
                                canMove = false
                                break
                            end
                        end
                    end
                    
                    if canMove then
                        tank:MoveTo(1, 500, -2125, tank:GetZ(), true)
                    end
                end
            end
        end
    end
	
	-- P3: Help with Vile Spirit damage
	if hp < 40 and hp > 10 then
		local currentTime = os.time()
		
		for _, player in pairs(players) do
			local name = player:GetName()
			if player:IsBot() then
				local vileSpirit = player:GetNearestCreature(30, 37799)
				
				if vileSpirit and not vileSpirit:IsDead() then
					local lastAttackTime = player:GetData("LastVileSpiritAttack") or 0
					
					if currentTime - lastAttackTime >= 1 then
						player:DealDamage(vileSpirit, vileSpirit:GetMaxHealth() * (math.random() * 0.01 + 0.005))
						player:SetData("LastVileSpiritAttack", currentTime)
					end
				end
			end
		end
	end
    
    lk:RegisterEvent(LichKingLoop, 200, 1)
end

local function OnLKCombat(event, player, enemy)
    if enemy and enemy:GetEntry() == 36597 then
        StartLuaEvent(enemy, LichKingLoop)
    end
end

function OnSoulReaperCast(event, caster, spell, skipCheck)
    local target = spell:GetTarget()
    
    if target and target:IsPlayer() then
        local player = target:ToPlayer()
        if player:IsBot() and IsTank(player) then
            UseDefensive(player)
            player:AddAura(71638, player)
        end
    end
end

function OnDefilePrepare(event, caster, spell)
    local target = spell:GetTarget()
	if not target then return end
	if not target:IsPlayer() then return end
    target:SetData("DefileMove", os.time())
	if target:IsBot() then UseRocketBoots(target) end
end

local function OnReload(player)
    if player:GetMapId() == 631 then
        if player:GetZ() > 835 then
            local LK = player:GetNearestCreature(100, 36597)
            if not LK then return end
            if LK:IsInCombat() then
                OnLKCombat(_, player, LK)
            end
        end
    end
end

if GetStateMap() then for _, player in ipairs(GetStateMap():GetPlayers()) do OnReload(player) end end
RegisterPlayerEvent(33, OnLKCombat)
RegisterSpellEvent(69409, 2, OnSoulReaperCast)
RegisterSpellEvent(72762, 1, OnDefilePrepare)
