-- Multistate: Drak'Tharon Keep-only script (map 600).
if not IsCompatibilityMode() and GetStateMapId() ~= 600 then return end

local MAP_ID       = 600
local TICK_TIMER   = 100 -- ms
local NUDGE_Z      = 1 -- yds

local function StartDrakTharonKeepTactics(event, d, r, player)
    if not (player:GetMapId() == MAP_ID) then player:RemoveEventById(event) end

    local px, py, pz, po = player:GetLocation()
    local floorZ = player:GetFloorZ()

    if floorZ and floorZ > 0 and (pz + (NUDGE_Z / 2) < floorZ) then
        player:NearTeleport(px, py, pz + NUDGE_Z, po)
    end
end

local function OnEnterDTK(event, player)
    if not player:IsBot() then return end
    if not (player:GetMapId() == MAP_ID) then
        return
    end

    player:RegisterEvent(StartDrakTharonKeepTactics, TICK_TIMER, 0)
end

RegisterPlayerEvent(28, OnEnterDTK)
require("Multistate").ForEachPlayer(function(player) OnEnterDTK(nil, player) end)