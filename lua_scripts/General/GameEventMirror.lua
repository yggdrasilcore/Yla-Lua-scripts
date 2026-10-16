-- GameEventMirror.lua
-- World-state mirror of core game events into WorldData for map states.
--
-- Engine already fires server events 34 (GAME_EVENT_START) and 35
-- (GAME_EVENT_STOP) in the world state via YLA_GameEventScript, and exposes
-- world-only GetActiveGameEvents / IsGameEventActive. Map states cannot call
-- those, so this script publishes the active set once at load plus on every
-- start/stop, and map handlers read it via GetWorldData("GameEvents").
--
-- World-state only: every state loads every script, but snapshot + hooks run
-- once in the world state.
if GetStateMapId() ~= -1 then return end

local function Publish(active)
    SetWorldData("GameEvents", {active = active})
end

local function Snapshot()
    local active = {}
    for _, id in ipairs(GetActiveGameEvents()) do
        active[id] = true
    end
    Publish(active)
end

local function OnGameEventStart(event, gameeventid)
    local cur = GetWorldData("GameEvents")
    local active = {}
    if cur then
        if cur.AsTable then cur = cur:AsTable() end
        if cur.active then
            if cur.active.AsTable then
                active = cur.active:AsTable()
            else
                active = cur.active
            end
        end
    end
    active[gameeventid] = true
    Publish(active)
end

local function OnGameEventStop(event, gameeventid)
    local cur = GetWorldData("GameEvents")
    local active = {}
    if cur then
        if cur.AsTable then cur = cur:AsTable() end
        if cur.active then
            if cur.active.AsTable then
                active = cur.active:AsTable()
            else
                active = cur.active
            end
        end
    end
    active[gameeventid] = nil
    Publish(active)
end

Snapshot()
RegisterServerEvent(34, OnGameEventStart)
RegisterServerEvent(35, OnGameEventStop)
