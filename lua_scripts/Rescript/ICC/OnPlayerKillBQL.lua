-- Multistate: PLAYER_EVENT_ON_KILL_CREATURE (7) fires in map states, but Group
-- member listing is world-only, so group-wide aura cleanup and quest credit are
-- forwarded to the global state via EMQ.
local MS = require("Multistate")
local EMQ = require("EMQ")

local AURAS = { 70877, 72151, 72649, 71949, 70867, 70879, 70923 }

-- Global executor (Group API is world-only).
EMQ.RegisterQueue("BQLKillReward", function(player, data)
    if not player then
        return
    end
    local group = player:GetGroup()
    if not group then
        return
    end
    for _, member in pairs(group:GetMembers()) do -- Clear residual vampire bite state
        for _, aura in ipairs(AURAS) do
            if member:HasAura(aura) then member:RemoveAura(aura) end
        end
    end

    if data and data.questId then
        for _, member in pairs(group:GetMembers()) do
            if member:HasQuest(data.questId) then
                member:CompleteQuest(data.questId)
            end
        end
    end
end)
-- Multistate: Icecrown Citadel-only script (map 631; the EMQ queue above must
-- still register in every state, hence the gate sits below it).
if not IsCompatibilityMode() and GetStateMapId() ~= 631 then return end


local function OnPlayerKillBQL(event, player, killed)
	if killed:GetEntry() == 37955 then

        -- Fix buggy minchar quest completion
		local minchar = killed:GetNearestCreature(200, 38558, 0, 1)

        local questId = nil
        if minchar then
            local difficulty = player:GetDifficulty()
            questId = 24874 -- 10-man quest

            if difficulty == 1 or difficulty == 3 then
                questId = 24879 -- 25-man quest
            end
        end

        local data = { questId = questId }
        if MS.IsCompat() or MS.IsWorld() then
            -- Compatibility/single-state: run inline.
            local group = player:GetGroup()
            if group then
                for _, member in pairs(group:GetMembers()) do
                    for _, aura in ipairs(AURAS) do
                        if member:HasAura(aura) then member:RemoveAura(aura) end
                    end
                end
                if questId then
                    for _, member in pairs(group:GetMembers()) do
                        if member:HasQuest(questId) then
                            member:CompleteQuest(questId)
                        end
                    end
                end
            end
        else
            player:SendEMQMessage("BQLKillReward", data)
        end
    end
end

RegisterPlayerEvent(7, OnPlayerKillBQL)
