function UnrootCreature(event, delay, repeats, creature)
    if creature then
        creature:SetRooted(false)
    end
end

function ArmyOfTheDeadSpawn(event, creature)
    creature:SetRooted(true)
    creature:PerformEmote(449)
    
    creature:RegisterEvent(UnrootCreature, 1500, 1)
end

RegisterCreatureEvent(24207, 5, ArmyOfTheDeadSpawn)