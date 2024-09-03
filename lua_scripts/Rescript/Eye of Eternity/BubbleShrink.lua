local NPC_ID = 30282
local SPELL_ID = 18210
local function CastSpellPeriodically(eventId, delay, calls, creature)
    creature:CastSpell(creature, SPELL_ID, true)
end

local function OnSpawn(event, creature)
    creature:DespawnOrUnsummon(45000)
    creature:RegisterEvent(CastSpellPeriodically, 1400, 0)
	creature:SetFaction(35)
	creature:SetRooted()
end

RegisterCreatureEvent(NPC_ID, 5, OnSpawn)
WorldDBExecute("UPDATE creature_template SET scale = 5 WHERE entry = " .. NPC_ID)