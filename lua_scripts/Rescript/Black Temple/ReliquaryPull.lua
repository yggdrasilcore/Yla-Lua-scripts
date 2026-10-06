-- Multistate: Black Temple-only script (map 564).
if not IsCompatibilityMode() and GetStateMapId() ~= 564 then return end

local ids = {22856, 23418, 23419, 23420}

local function CheckReliquaryPullLoop(eventId, delay, repeats, player)
    if player:GetMapId() ~= 564 then player:RemoveEventById(eventId) return end
    
    if player:GetZ() <= 145 then return end
    
    for _, id in ipairs(ids) do
        local npc = player:GetNearestCreature(100, id)
        if npc then
            npc:SetRespawnDelay(30)
            npc:DespawnOrUnsummon()
        end
    end
end

local function CheckReliquaryPull(event, player)
    if player:GetMapId() ~= 564 then return end
    player:RegisterEvent(CheckReliquaryPullLoop, 3500, 0)
end

RegisterPlayerEvent(28, CheckReliquaryPull)
require("Multistate").ForEachPlayer(function(player) CheckReliquaryPull(nil, player) end)