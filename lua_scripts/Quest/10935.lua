-- Multistate: map-only script (all hooks fire in map states).
if GetStateMapId() == -1 then return end

local count22507 = 0
local JulesEvent

local function Spawn22506(event, creature)
	creature:NearTeleport(creature:GetX(), creature:GetY(), 101.5914, creature:GetO())
end

local function Spawn22507(event, creature)
	if count22507 == 0 then
		creature:SetReactState(0)
		creature:NearTeleport(-710, 2745, 101.59147, creature:GetO())
		creature:MoveRandom(5)
		creature:SetScale(1.5)
		creature:AddAura(39303, creature)
		count22507 = count22507 + 1
		creature:SetSpeed(1, 0.45)
		creature:SetSpeed(0, 0.45)
		--print("1 summon!")
        
        anchorite = creature:GetNearestCreature(50, 22431)
        
        if anchorite then
            creature:SetInCombatWith(anchorite)
        end
        
		player = creature:GetNearestPlayer(20)
        if player then
            creature:SetInCombatWith(player)
        end
		
		creature:RegisterEvent(function(eventId, delay, repeats, creature)
			if creature then
				if not creature:HasAura(39303) then
					creature:AddAura(39303, creature)
				end
				creature:CastSpell(creature, 39320, true)
			else
				--print("22507 creature not found!")
			end
		end, 5000, 0)
		
		Jules = creature:GetNearestCreature(20, 22432)
        
		if Jules and not JulesEvent then
			--creature:SetRooted(false)
			--print("Unrooting and starting Jules event...")
			JulesEvent = true
			Jules:RegisterEvent(function(eventId, delay, repeats, creature)
				JulesEvent = nil
				--print("Disabling Jules fly")
				if creature then
                    creature:SetDisableGravity()
                    creature:SetHover(false)
					creature:MoveStop()
					creature:MoveClear()
					if creature:HasAura(39283) then
						creature:RemoveAura(39283)
					end
					creature:RegisterEvent(function(eventId, delay, repeats, creature)
                        creature:MoveStop()
                        creature:MoveClear()
                        creature:NearTeleport(creature:GetX(), creature:GetY(), 101.59, creature:GetO())
                        if creature:HasAura(39283) then
                            creature:RemoveAura(39283)
                        end
						--print("Landing Jules")  
					end, 300, 1)
					creature:RegisterEvent(function(eventId, delay, repeats, creature)
						creature:SetRooted()
                        if creature:HasAura(39283) then
                            creature:RemoveAura(39283)
                        end
                        --print("Rooting Jules!")
					end, 320, 1)
					creature:RegisterEvent(function(eventId, delay, repeats, creature)
						creature:SetRooted(false)
						creature:SetRespawnDelay(30)
						creature:DespawnOrUnsummon()
                        --print("Despawning Jules!")
					end, 40000, 1)
				end
			end, 147*1000, 1)
		end
		
	elseif count22507 == 1 then
		count22507 = count22507 + 1
		creature:DespawnOrUnsummon()
	elseif count22507 == 2 then
		count22507 = count22507 + 1
		creature:DespawnOrUnsummon()
	elseif count22507 == 3 then
		count22507 = count22507 + 1
		creature:DespawnOrUnsummon()
	elseif count22507 == 4 then
		count22507 = count22507 + 1
		creature:DespawnOrUnsummon()
	else
		count22507 = 0
		creature:DespawnOrUnsummon()
	end
    
    if not lightningtime or lightningtime < os.time() then
        lightningtime = os.time() + 150
        lightningbunny = creature:SpawnCreature(22508, -710, 2747, 113, 0, 1, 150000)
        lightningbunny:RegisterEvent(function(eventId, delay, repeats, lightningbunny)
            if lightningbunny then
                if not lightningbunny:HasAura(39380) then
                    lightningbunny:AddAura(39380, lightningbunny)
                end
                if not lightningbunny:HasAura(39308) then
                    lightningbunny:AddAura(39308, lightningbunny)
                end
                lightningbunny:CastSpell(lightningbunny, 39381, true)
            else
                RemoveEventById(eventId)
            end
        end, 10000, 15)   
    end
end

local function Died22507(event, creature, killer)
	creature:CastSpell(creature, 39307, true)
    --print("22507 died")
    anchorite = creature:GetNearestCreature(50, 22431, 0, 1)
    if anchorite then 
        anchorite:RegisterEvent(function(eventId, delay, repeats, anchorite)
            if not anchorite:HasAura(39278) then
                anchorite:NearTeleport(anchorite:GetX(), anchorite:GetY(), anchorite:GetZ(), 1.5264)
                anchorite:AddAura(39278, anchorite)
                --print("fixing anchorite position")
            end
        end, 25, 3)    
    end
	creature:RemoveEvents()
end

local function StartCombat22507(event, creature, target)
	creature:RegisterEvent(function(eventId, delay, repeats, creature)
		creature:AddAura(39303, creature)
	end, 10, 1)
    anchorite = creature:GetNearestCreature(50, 22431, 0, 1)
    if anchorite then 
        anchorite:RegisterEvent(function(eventId, delay, repeats, anchorite)
            if not anchorite:HasAura(39278) then
                anchorite:NearTeleport(anchorite:GetX(), anchorite:GetY(), anchorite:GetZ(), 1.5264)
                anchorite:CastSpell(anchorite, 39278, true)
            end
        end, 25, 3)  
    end  
	creature:SetSpeed(1, 0.45)
	creature:SetSpeed(0, 0.45)
end

local function LeaveCombat22507(event, creature)
	creature:RegisterEvent(function(eventId, delay, repeats, creature)
		creature:AddAura(39303, creature)
	end, 10, 1)
    anchorite = creature:GetNearestCreature(50, 22431, 0, 1)
    if anchorite then 
        anchorite:RegisterEvent(function(eventId, delay, repeats, anchorite)
            if not anchorite:HasAura(39278) then
                anchorite:NearTeleport(anchorite:GetX(), anchorite:GetY(), anchorite:GetZ(), 1.5264)
                anchorite:CastSpell(anchorite, 39278, true)
            end
        end, 25, 3)  
    end  
	creature:SetSpeed(1, 0.45)
	creature:SetSpeed(0, 0.45)
end

local function StartCombat22506(event, creature, target)
    anchorite = creature:GetNearestCreature(50, 22431, 0, 1)
    if anchorite then 
        anchorite:RegisterEvent(function(eventId, delay, repeats, anchorite)
            if not anchorite:HasAura(39278) then
                anchorite:NearTeleport(anchorite:GetX(), anchorite:GetY(), anchorite:GetZ(), 1.5264)
                anchorite:CastSpell(anchorite, 39278, true)
            end
        end, 25, 3)   
    end 
end

local function LeaveCombat22506(event, creature)
    anchorite = creature:GetNearestCreature(50, 22431, 0, 1)
    if anchorite then 
        anchorite:RegisterEvent(function(eventId, delay, repeats, anchorite)
            if not anchorite:HasAura(39278) then
                anchorite:NearTeleport(anchorite:GetX(), anchorite:GetY(), anchorite:GetZ(), 1.5264)
                anchorite:CastSpell(anchorite, 39278, true)
            end
        end, 25, 3)   
    end
end

local function Died22506(event, creature, killer)
    anchorite = creature:GetNearestCreature(50, 22431, 0, 1)
    if anchorite then 
        anchorite:RegisterEvent(function(eventId, delay, repeats, anchorite)
            if not anchorite:HasAura(39278) then
                anchorite:NearTeleport(anchorite:GetX(), anchorite:GetY(), anchorite:GetZ(), 1.5264)
                anchorite:CastSpell(anchorite, 39278, true)
            end
        end, 25, 3)    
    end
end

local function EnterHonorHold(event, player, newZone, newArea)
    if JulesEvent then return end
    if player then
        Jules = player:GetNearestCreature(500, 22432)
        if Jules and Jules:GetDistance(-710, 2754, 102) > 4 then
            Jules:RegisterEvent(function(eventId, delay, repeats, Jules)
                Jules:Respawn()
            end, 25, 1)    
            Jules:DespawnOrUnsummon()
        end
    end
end

RegisterCreatureEvent(22506, 1, StartCombat22506)
RegisterCreatureEvent(22506, 2, LeaveCombat22506)
RegisterCreatureEvent(22506, 4, Died22506)
RegisterCreatureEvent(22506, 5, Spawn22506)

RegisterCreatureEvent(22507, 1, StartCombat22507)
RegisterCreatureEvent(22507, 2, LeaveCombat22507)
RegisterCreatureEvent(22507, 4, Died22507)
RegisterCreatureEvent(22507, 5, Spawn22507)

RegisterPlayerEvent(27, EnterHonorHold)