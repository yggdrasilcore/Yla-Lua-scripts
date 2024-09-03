local function CastSpellPeriodically(eventId, delay, calls, creature)
    creature:CastSpell(creature, 18210, true)	
end

local function OnSpawn(event, creature)
    creature:DespawnOrUnsummon(45000)
    creature:RegisterEvent(CastSpellPeriodically, 1400, 0)
end

local function OnCombat(event, creature, target)
    creature:SetRooted()
end

RegisterCreatureEvent(30282, 5, OnSpawn)
RegisterCreatureEvent(30282, 5, OnCombat)
WorldDBExecute("UPDATE creature_template SET scale = 5, BaseAttackTime = 9999999, unit_flags = 33685510, unit_flags2 = 34816 WHERE entry = 30282")
