local EMOTE_DURATION = 3 -- Duration of the emote in seconds

function ArmyOfTheDeadSpawn(event, creature)
    creature:SetRooted(true)
    creature:PerformEmote(449)
    
    creature:RegisterEvent(UnrootCreature, EMOTE_DURATION * 1000, 1, creature)
end

function UnrootCreature(event, delay, repeats, creature)
    if creature and creature:IsInWorld() then
        creature:SetRooted(false)
    end
end

RegisterCreatureEvent(24207, 5, ArmyOfTheDeadSpawn)