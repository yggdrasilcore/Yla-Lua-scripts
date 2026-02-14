local function LichKingLoop(eventId, delay, repeats, lk)
    if lk:IsDead() or not lk:IsInCombat() then
        StopLuaEvent(lk)
        return
    end
    
	-- Dispell on p1 -> p2 transition
    local hp = lk:GetHealthPct()
    local players = lk:GetPlayersInRange(100)
    local necroticAuras = {70337, 70338, 73785, 73786, 73787, 73912, 73913, 73914}
    
    if hp >= 65 and hp <= 70 then
        for _, player in pairs(players) do
            local name = player:GetName()
            if isPlayerBot[name] then
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
			if isPlayerBot[name] then
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
    if hp <= 65 and hp >= 42 then
        local valkyrs = lk:GetCreaturesInRange(100, 36609)
        local valkyrInAir = false
        local currentTime = os.time()
        
		for _, valkyr in pairs(valkyrs) do
			local vx, vy = valkyr:GetX(), valkyr:GetY()
			local distance2D = math.sqrt((vx - 504)^2 + (vy - 840)^2)
			
			if distance2D <= 43 then
				if valkyr:HasAura(68985) then
					valkyrInAir = true
				else
					for _, player in pairs(players) do
						local name = player:GetName()
						if isPlayerBot[name] then
							if player:HasMeleeSpec() then
								if player:GetDistance(valkyr) > 5 then
									player:MoveTo(1, vx, vy, valkyr:GetZ(), true)
								end
							end
							
							local lastAttackTime = player:GetData("LastValkyrAttack") or 0
							
							if currentTime - lastAttackTime >= 1 then
								player:DealDamage(valkyr, valkyr:GetMaxHealth() * (math.random() * 0.01 + 0.005))
								player:SetData("LastValkyrAttack", currentTime)
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
                if isPlayerBot[name] and player ~= victim then
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
            
            if isPlayerBot[name] and IsTank(tank) then
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
			if isPlayerBot[name] then
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
        if isPlayerBot[player:GetName()] and IsTank(player) then
            UseDefensive(player)
            player:AddAura(71638)
        end
    end
end

function OnDefilePrepare(event, caster, spell)
    local target = spell:GetTarget()
	if not target then return end
	if not target:IsPlayer() then return end
    target:SetData("DefileMove", os.time())
	if isPlayerBot[target:GetName()] then UseRocketBoots(target) end
end

RegisterPlayerEvent(33, OnLKCombat)
RegisterSpellEvent(69409, 2, OnSoulReaperCast)
RegisterSpellEvent(72762, 1, OnDefilePrepare)
