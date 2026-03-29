function GetRole(player)
    if not player or not player:IsAlive() or not player:IsInCombat() or not player:IsBot() then
        return nil
    end
    
    if IsTank(player) then
        return "tank"
    elseif player:HasHealSpec() then
        return "healer"
    elseif player:HasMeleeSpec() then
        return "melee"
    elseif player:HasCasterSpec() then
        return "caster"
    end
    
    return nil
end