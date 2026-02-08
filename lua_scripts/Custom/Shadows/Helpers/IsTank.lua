function IsTank(player)
    local class = player:GetClass()
    
    if class == 1 or class == 2 or class == 6 or class == 11 then
        if player:HasTankSpec() or (player:HasAura(5487) or player:HasAura(9634) or player:HasAura(16931)) then
            return true
        end
    end
    return false
end