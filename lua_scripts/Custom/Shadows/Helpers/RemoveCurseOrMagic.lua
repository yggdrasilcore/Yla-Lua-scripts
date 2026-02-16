function RemoveCurseOrMagic(player, target)
    if player:GetDistance(target) > 40 then return end
    
    local class = player:GetClass()
    
    if class == 2 then
        player:CastSpell(target, 4987, true)
    elseif class == 8 then
        player:CastSpell(target, 475, true)
    elseif class == 11 then
        player:CastSpell(target, 2782, true)
    elseif class == 7 then
        player:CastSpell(target, 51886, true)
    elseif class == 5 then
        player:CastSpell(target, 988, true)
    end
end