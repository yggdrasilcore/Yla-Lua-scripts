-- SUBMERGE
local function OnCastSubmerge(event, caster, spell)
	caster:SetReactState(0) -- Set passive to not have AI Interrupt emotes
	
	immunity = caster:AddAura(29230, caster)
	if immunity then immunity:SetDuration(15000) end -- Ensure players can't channel dmg spells while submeringg
	
	caster:RemoveAura(53421) -- Reset submerge state to perform new emote
	
	caster:RegisterEvent(function(e, d, r, caster)
		caster:PerformEmote(374) -- Submerge emote
	end, 250)
	
	caster:RegisterEvent(function(e, d, r, caster)
		caster:AddAura(53421, caster) -- Re-add submerge state
	end, 1700)
	
	caster:RegisterEvent(function(e, d, r, caster) -- Ensures mob doesn't get stuck in passive on evade/wipe
		if caster:IsInCombat() then return end
		caster:SetReactState(2)
	end, 500, 200)
end

RegisterSpellEvent(53421, 2, OnCastSubmerge) -- Submerge



-- EMERGE
local function OnCastEmerge(event, caster, spell)
    if caster:HasAura(29230) then caster:RemoveAura(29230) end -- Reset immunity timer
	
	immunity = caster:AddAura(42716, caster)
	if immunity then immunity:SetDuration(1000) end -- New immunity timer
	
	aura = caster:AddAura(42716, caster) -- Root
	if aura then aura:SetDuration(1500) end -- Don't interrupt emote while performing it
	
	caster:CastSpell(caster, 68848, true) -- Interrupt self
    
    if caster:HasAura(53456) then caster:RemoveAura(53456) end -- Remove impale aura
	
	caster:RegisterEvent(function(e, d, r, caster)
		caster:PerformEmote(449) -- Emerge emote, hammering to ensure it triggers (won't overlap client-side)
	end, 50, 10)
	
	caster:RegisterEvent(function(e, d, r, caster)
		caster:SetReactState(2) -- Emerge eote probably done by now
	end, 1500)
end

RegisterSpellEvent(53500, 2, OnCastEmerge) -- Emerge

print("[Instance]: Azjol-Nerub: Anub'Arak instance fix loaded!")
