if GetStateMapId() ~= 595 then return end

local ARTHAS_ENTRY = 26499
local ZOMBIE_ENTRY = 27737

local function KillZombiesLoop(eventId, delay, repeats, player)
    if player:GetMapId() ~= 595 then
        player:RemoveEventById(eventId)
        return
    end

    local arthas = player:GetNearestCreature(100, ARTHAS_ENTRY)
    if not arthas then return end

    local dist = arthas:GetDistance2d(2400, 1207)
    if dist >= 20 then return end

    local zombies = player:GetCreaturesInRange(750, ZOMBIE_ENTRY, 0, 1)
    for _, zombie in ipairs(zombies) do
        if zombie:IsInCombat() or (zombie:GetX() < 2400 and not (zombie:GetX() > 2250 and zombie:GetY() > 1235)) then
            zombie:Kill(zombie)
        end
    end
end

local function OnPlayerMapChange(event, player)
    if player:GetMapId() == 595 then
        player:RegisterEvent(KillZombiesLoop, 15000, 0)
    end
end

RegisterPlayerEvent(28, OnPlayerMapChange)

if GetStateMap() then
    for _, player in ipairs(GetStateMap():GetPlayers()) do
        player:RegisterEvent(OnPlayerMapChange, 5000, 0)
    end
end