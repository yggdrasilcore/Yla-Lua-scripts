-- Multistate: Icecrown Citadel-only script (map 631).
if GetStateMapId() ~= 631 then return end

local function BotAttackInsects(player)
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
            if player:GetClass() == 6 then -- DK
                player:CastSpell(_, 49941, true) -- Blood Boil
            elseif player:GetClass() == 1 then -- Warrior
                player:CastSpell(_, 47502, true) -- Thunder Clap
            elseif player:GetClass() == 2 then -- Paladin
                player:CastSpell(_, 48819, true) -- Consecration
            elseif player:GetClass() == 5 then -- Priest
                player:CastSpell(_, 48078, true) -- Holy Nova
            elseif player:GetClass() == 8 then -- Mage
                player:CastSpell(_, 42921, true) -- Rrcane Explosion
            else
                player:DealDamage(nearestInsect, 5000)
            end
        end
    end
end

local function BotInsectLoop(eventId, delay, repeats, player)
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

local function OnBotMapChange(event, player)
    if player:GetMapId() == 631 and player:IsBot() then
        player:RegisterEvent(BotInsectLoop, math.random(1500, 2200), 0)
    end
end

RegisterPlayerEvent(28, OnBotMapChange)
for _, player in ipairs(GetStateMap():GetPlayers()) do OnBotMapChange(nil, player) end