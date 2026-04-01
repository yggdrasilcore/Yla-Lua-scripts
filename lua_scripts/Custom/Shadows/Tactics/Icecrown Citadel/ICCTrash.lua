function BotAttackInsects(player)
    local insects = player:GetCreaturesInRange(100, 37782)
    
    if #insects == 0 then return end
    
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
        if player:GetDistance(nearestInsect) > 5 then
            player:MoveTo(0, nearestInsect:GetX(), nearestInsect:GetY(), nearestInsect:GetZ())
        else
            player:DealDamage(nearestInsect, 5000)
        end
    end
end

function BotInsectLoop(eventId, delay, repeats, player)
    if player:GetMapId() ~= 631 then
        player:RemoveEventById(eventId)
        return
    end
    
    local px = player:GetX()
    local py = player:GetY()
    local pz = player:GetZ()
    
    if px >= 4336 and px <= 4374 and py >= 3080 and py <= 3155 and pz >= 355 and pz <= 395 then
        if not player:HasHealSpec() then
            BotAttackInsects(player)
        end
    end
end

function OnBotMapChange(event, player)
    if player:GetMapId() == 631 and player:IsBot() then
        player:RegisterEvent(BotInsectLoop, math.random(1500, 2200), 0)
    end
end

RegisterPlayerEvent(28, OnBotMapChange)
for _, player in ipairs(GetPlayersInWorld()) do OnBotMapChange(_, player) end