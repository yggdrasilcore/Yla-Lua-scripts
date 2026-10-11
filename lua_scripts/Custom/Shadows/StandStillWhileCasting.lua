-- Multistate: map-only script (all hooks fire in map states).
if GetStateMapId() == -1 then return end

local function StandStillWhiteCasting(event, player, spell, _)
	local name = player:GetName()
	if not player:IsBot() then return end
	if event == 1 then
		player:AddAura(32113, player)
	else
		player:RemoveAura(32113)
	end
end

RegisterSpellEvent(698, 1, StandStillWhiteCasting)
RegisterSpellEvent(18540, 1, StandStillWhiteCasting)
RegisterSpellEvent(20700, 1, StandStillWhiteCasting)
RegisterSpellEvent(29893, 1, StandStillWhiteCasting)
RegisterSpellEvent(58887, 1, StandStillWhiteCasting)
RegisterSpellEvent(58659, 1, StandStillWhiteCasting)
RegisterSpellEvent(43987, 1, StandStillWhiteCasting)
RegisterSpellEvent(698, 2, StandStillWhiteCasting)
RegisterSpellEvent(18540, 2, StandStillWhiteCasting)
RegisterSpellEvent(20700, 2, StandStillWhiteCasting)
RegisterSpellEvent(29893, 2, StandStillWhiteCasting)
RegisterSpellEvent(58887, 2, StandStillWhiteCasting)
RegisterSpellEvent(58659, 2, StandStillWhiteCasting)
RegisterSpellEvent(43987, 2, StandStillWhiteCasting)
RegisterSpellEvent(698, 3, StandStillWhiteCasting)
RegisterSpellEvent(18540, 3, StandStillWhiteCasting)
RegisterSpellEvent(20700, 3, StandStillWhiteCasting)
RegisterSpellEvent(29893, 3, StandStillWhiteCasting)
RegisterSpellEvent(58887, 3, StandStillWhiteCasting)
RegisterSpellEvent(58659, 3, StandStillWhiteCasting)
RegisterSpellEvent(43987, 3, StandStillWhiteCasting)