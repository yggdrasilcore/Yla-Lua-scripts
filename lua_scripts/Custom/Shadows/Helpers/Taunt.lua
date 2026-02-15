function Taunt(player, target, CD_CHECK)
    local PALADIN = 2
    local DEATH_KNIGHT = 6
    local DRUID = 11
    local WARRIOR = 1
    
    local PALADIN_TAUNT = 62124
    local DK_TAUNT = 56222
    local DRUID_TAUNT = 6795
    local WARRIOR_TAUNT = 355
    
    local class = player:GetClass()
    local spellId
    
    if class == PALADIN then
        spellId = PALADIN_TAUNT
    elseif class == DEATH_KNIGHT then
        spellId = DK_TAUNT
    elseif class == DRUID then
        spellId = DRUID_TAUNT
    elseif class == WARRIOR then
        spellId = WARRIOR_TAUNT
    end
    
    if CD_CHECK and spellId and player:HasSpellCooldown(spellId) then
        return
    end
    
    if spellId then
        player:CastSpell(target, spellId, false)
    end
end