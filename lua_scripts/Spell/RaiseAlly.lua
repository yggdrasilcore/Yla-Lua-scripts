-- RegisterPlayerEvent for spell cast
local function RaiseAllyCast(event, player, spell, skipCheck)
	local target = player:GetSelection()
	if target and target:IsPlayer() and (player:IsInSameGroupWith(target) or player:IsInSameRaidWith(target)) and target:IsDead() then
		target:CastSpell(target, 46619)
		target:RegisterEvent(function(eventId, delay, repeats, target)
			RaiseAllyGhoul = target:GetNearestCreature(10, 30230)
			if RaiseAllyGhoul then
				RaiseAllyGhoul:PerformEmote(449) -- Crawl animation
			end
		end, 50, 1)
	else
		player:RegisterEvent(function(eventId, delay, repeats, player)
			player:ResetSpellCooldown(61999)
			player:RemoveEventById(eventId)
		end, 500, 1)
	end
end

local function RaiseAllyRess(event, packet, player)
	if player:HasAura(46619) then
		player:RemoveAura(46619)
	end
end

local function RaiseAllyRelease(event, packet, player)
	if player:HasAura(46619) and player:HasAura(8326) then
		player:RemoveAura(46619)
	end
end

-- Register the event
RegisterSpellEvent(61999, 2, RaiseAllyCast)
RegisterPacketEvent(0x15C, 5, RaiseAllyRess)
RegisterPacketEvent(0x26A, 5, RaiseAllyRelease)