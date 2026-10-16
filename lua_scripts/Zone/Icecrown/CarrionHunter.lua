-- Multistate: Northrend-only script (map 571).
if GetStateMapId() ~= 571 then return end

function OnEnterCombat(event, creature, target)
   local auraOwner = creature:GetNearestCreature(20, 31262)
   if not auraOwner then
       return
   end
   if auraOwner:HasAura(46598) then
       auraOwner:RemoveAura(46598)
   end
end

function OnLeaveCombat(event, creature)
   local auraOwner = creature:GetNearestCreature(20, 31262)
   if not auraOwner then
       return
   end
   if not auraOwner:HasAura(46598) then
       creature:CastSpell(auraOwner, 46598)
   end
end

RegisterCreatureEvent(31263, 1, OnEnterCombat)
RegisterCreatureEvent(31263, 2, OnLeaveCombat)