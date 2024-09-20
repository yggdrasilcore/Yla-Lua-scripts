local FROST_QUEENS_LAIR = 4889
local Sindragosa_ID = 36853
local KNOCKBACK_IMMUNITY = 64556
local ROOT_STUN_IMMUNITY = 41310
local COMBAT_START_EVENT_INTERVAL = 500 -- 500 milliseconds
local SEARCH_DISTANCE = 500 -- 50 yards
local SindyEvent = {}
local tankmessage = {}

local function CombatCheck(eventId, delay, repeats, player)
    local Sindragosa = player:GetNearestCreature(SEARCH_DISTANCE, Sindragosa_ID)
	
    if not (player:GetAreaId() == FROST_QUEENS_LAIR) then
		player:RemoveEvents()
		SindyEvent[player:GetName()] = nil
		if player:HasAura(KNOCKBACK_IMMUNITY) then
            player:RemoveAura(KNOCKBACK_IMMUNITY)
        end
	
	else
		if Sindragosa and Sindragosa:IsInCombat() then 
			if Sindragosa:GetVictim() == player then
				player:RemoveAura(KNOCKBACK_IMMUNITY)
				player:AddAura(KNOCKBACK_IMMUNITY, player)
				if not tankmessage[player:GetName()] then
					print("[Sindragosa]: Immunity added to tank "..player:GetName().."!")
					tankmessage[player:GetName()] = true
				end
			else
				tankmessage[player:GetName()] = nil
				if player:HasAura(KNOCKBACK_IMMUNITY) then
					player:RemoveAura(KNOCKBACK_IMMUNITY)
					print("[Sindragosa]: Lost aggro! Removing immunity from "..player:GetName().."!")
				end
				if (not Sindragosa or Sindragosa:IsDead()) and not player:IsInCombat() then
					if player:HasAura(KNOCKBACK_IMMUNITY) then
						player:RemoveAura(KNOCKBACK_IMMUNITY)
					end
					
					player:RemoveEvents()
					SindyEvent[player:GetName()] = nil
					
				end
			end
		end
	end
end

local function OnSindyCombat(event, player, enemy)
	if enemy and enemy:GetEntry() == Sindragosa_ID then
		if not SindyEvent[player:GetName()] then
			player:RegisterEvent(CombatCheck, COMBAT_START_EVENT_INTERVAL, 0)
			SindyEvent[player:GetName()] = true
		end
	end
end

RegisterPlayerEvent(33, OnSindyCombat)