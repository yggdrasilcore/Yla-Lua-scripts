-- Multistate: map-only script (all hooks fire in map states).
if not IsCompatibilityMode() and GetStateMapId() == -1 then return end

local function TreeFormWatchdogLoop(eventId, delay, repeats, player)
    if not player:IsBot() then player:RemoveEventById(eventId) return end
    if not player:IsInCombat() then return end
    if player:HasSpell(33891) and not player:HasAura(33891) then
        player:CastSpell(player, 33891, true)
    end
end

local function OnPlayerMapChange(event, player)
    if player:IsBot() and player:GetClass() == 11 then
        player:RegisterEvent(TreeFormWatchdogLoop, 3000, 0)
    end
end

RegisterPlayerEvent(28, OnPlayerMapChange)
require("Multistate").ForEachPlayer(function(player) OnPlayerMapChange(nil, player) end)