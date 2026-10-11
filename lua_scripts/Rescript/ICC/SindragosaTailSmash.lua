-- Multistate: Icecrown Citadel-only script (map 631).
if GetStateMapId() ~= 631 then return end

local function TailSmashFix(event, sindragosa, spell)
	sindragosa:RegisterEvent(function(e, d, r, sindragosa)
		sindragosa:StopSpellCast()
		sindragosa:CastSpell(sindragosa, 69286, true)
	end, 990 * 2)
end

RegisterSpellEvent(71077, 1, TailSmashFix)