function ManageInsect(eventId, delay, repeats, player)
    local insectGUID = player:GetData("AssignedInsectGUID")
    
    if not insectGUID then
        player:RemoveEventById(eventId)
        return
    end
    
    local insect = nil
    local insects = player:GetCreaturesInRange(100, 37782)
    for _, npc in pairs(insects) do
        if npc:GetGUIDLow() == insectGUID then
            insect = npc
            break
        end
    end
    
    if not insect or insect:IsDead() or player:IsDead() then
        player:SetData("AssignedInsectGUID", nil)
        player:RemoveEventById(eventId)
        return
    end
    
    local currentTime = os.time()
    local py = player:GetY()
	
    local go1 = player:GetNearestGameObject(100, 201372) -- Upper gate
    local go2 = player:GetNearestGameObject(100, 201612) -- Lower collision?
    local go3 = player:GetNearestGameObject(100, 201613) -- Green tube
    local go4 = player:GetNearestGameObject(100, 201614) -- Orange tube

    local KillNpc = false

    if (go1 and go1:GetGoState() == 0) or (go2 and go2:GetGoState() == 0) or 
       (go3 and go3:GetGoState() == 2) or (go4 and go4:GetGoState() == 2) then
        KillNpc = true
    end
	
	if KillNpc then insect:Kill(insect) return end
    
    if py < 3153 and py > 3075 then
        insect:SetFacingToObject(player)
		
		insect:MoveClear(true)
        local distance = insect:GetDistance(player)
        
        if distance > 1 then
            insect:SetDisableGravity(true)
            insect:MoveTo(0, player:GetX(), player:GetY(), player:GetZ(), false)
        end
        
        local lastAttackTime = insect:GetData("LastAttackTime") or 0
        if currentTime - lastAttackTime >= 2 then
            insect:DealDamage(player, math.random(50, 250))
            insect:SetData("LastAttackTime", currentTime)
        end
    else
        player:SetData("AssignedInsectGUID", nil)
        player:RemoveEventById(eventId)
    end
end

function AssignInsects(eventId, delay, repeats, player)
    local insects = player:GetCreaturesInRange(100, 37782)
    
    for _, insect in pairs(insects) do
        if not insect:IsDead() then
            local playersInRange = insect:GetPlayersInRange(100)
            local validPlayer = nil
            local nearestDistance = 999999
            
            for _, p in pairs(playersInRange) do
                local py = p:GetY()
                
                if py < 3153 and py > 3075 and not p:GetData("AssignedInsectGUID") then
                    local distance = insect:GetDistance(p)
                    if distance < nearestDistance then
                        nearestDistance = distance
                        validPlayer = p
                    end
                end
            end
            
            if validPlayer then
                validPlayer:SetData("AssignedInsectGUID", insect:GetGUIDLow())
                validPlayer:RegisterEvent(ManageInsect, 300, 1000)
            end
        end
    end
end

function OnPlagueInsectCombat(event, player, enemy)
    if enemy and enemy:GetEntry() == 37782 then
        player:RegisterEvent(AssignInsects, 300, 1)
    end
end

RegisterPlayerEvent(33, OnPlagueInsectCombat)