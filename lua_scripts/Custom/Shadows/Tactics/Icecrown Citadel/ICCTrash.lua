function BotAttackInsects(eventId, delay, repeats, player)
    local insects = player:GetCreaturesInRange(100, 37782)
    local currentTime = os.time()
    
    if #insects == 0 then
        player:SetData("InsectEventActive", nil)
        player:RemoveEventById(eventId)
        return
    end
    
    local py = player:GetY()
    if py < 3153 and py > 3075 then
        local nearestInsect = nil
        local nearestDistance = 999999
        
        for _, insect in pairs(insects) do
            if not insect:IsDead() then
                local distance = player:GetDistance(insect)
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestInsect = insect
                end
            end
        end
        
        if nearestInsect then
            local distance = player:GetDistance(nearestInsect)
            
            if distance > 5 then
                player:MoveTo(0, nearestInsect:GetX(), nearestInsect:GetY(), nearestInsect:GetZ())
            else
                local lastAttackTime = player:GetData("InsectAttackTime") or 0
                if currentTime - lastAttackTime >= 1 then
                    player:DealDamage(nearestInsect, 3000)
                    player:SetData("InsectAttackTime", currentTime)
                end
            end
        end
    else
        player:SetData("InsectEventActive", nil)
        player:RemoveEventById(eventId)
    end
end

function OnPlagueInsectCombat(event, player, enemy)
    if enemy and enemy:GetEntry() == 37782 then
        local playersInRange = player:GetPlayersInRange(100)
        
        for _, p in pairs(playersInRange) do
            local py = p:GetY()
            local name = p:GetName()
            
            if py < 3153 and py > 3075 and isPlayerBot[name] then
                if not p:GetData("InsectEventActive") then
                    p:SetData("InsectEventActive", true)
                    p:RegisterEvent(BotAttackInsects, 1000, 300)
                end
            end
        end
    end
end

RegisterPlayerEvent(33, OnPlagueInsectCombat)