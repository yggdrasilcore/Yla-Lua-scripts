local SwiftnessPotion = {}
local DrumsOfSpeed = {}
local Blink = {}

function UseSpeedBuff(player)
    local guid = player:GetGUIDLow()
    local now = os.time()
    
    if player:HasSpell(55016) then
        player:CastSpell(player, 54861, true)
    elseif player:GetClass() == 4 then
        player:CastSpell(player, 11305, true)
    elseif player:GetClass() == 11 and player:HasAura(768) then
        player:CastSpell(player, 1850, true)
    elseif player:HasSpell(1953) then
        if not Blink[guid] or (now - Blink[guid]) >= 20 then
            player:CastSpell(player, 1953, true)
            Blink[guid] = now
        end
    else
        if not SwiftnessPotion[guid] or (now - SwiftnessPotion[guid]) >= 120 then
            player:CastSpell(player, 2379, true)
            SwiftnessPotion[guid] = now
        end
    end
    
    if player:HasSpell(51302) then
        if not DrumsOfSpeed[guid] or (now - DrumsOfSpeed[guid]) >= 120 then
            player:CastSpell(player, 35477, true)
            DrumsOfSpeed[guid] = now
        end
    end
end