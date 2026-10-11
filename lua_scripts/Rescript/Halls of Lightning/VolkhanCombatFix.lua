-- Multistate: Halls of Lightning-only script (map 602).
if GetStateMapId() ~= 602 then return end

local function OnKillVolkhan(event, player, killed)
    if killed:GetEntry() == 28587 then
        player:RegisterEvent(function(e, d, r, player)
            local brittle = player:GetNearObjects(100, 8, 28681)
            local molten = player:GetNearObjects(100, 8, 28695)
            if #brittle == 0 and #molten == 0 then
                player:RemoveEventById(e)
                return
            end
            for _, creature in pairs(brittle) do
                creature:DespawnOrUnsummon()
            end
        end, 2000, 30) -- Loop in case molten golems still alive and killed later
    end
end
RegisterPlayerEvent(7, OnKillVolkhan)