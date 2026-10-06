-- Multistate.lua — shared helpers for ALE multistate mode (mod-ale multistate-shoehorn).
--
-- Background: with ALE.CompatibilityMode = false the engine runs one Lua state
-- for the global ("world") context plus one Lua state per map+instance. Hooks are
-- split between them:
--   WORLD (global state only): server events 5,7-16,25-30,33-35, player events
--     1-4,18-22,30,42, packet events, group/guild/gameevent/weather/auction/
--     addon/ticket/world events, login/logout/chat/commands.
--   MAP (map states only): server events 17,18,21-24,31,32, player events 5-17,
--     23-29,31+, creature/gameobject/item/gossip/map/instance/spell/BG events.
-- Each state loads every script, but registrations only fire in their own state,
-- Lua locals/globals are NOT shared between states, and several APIs only exist
-- in one context (WORLD-only: GetPlayersInWorld, GetPlayerByGUID, GetPlayerByName,
-- GetMapById, Group/Guild methods; MAP-only: GetStateMap). GetStateMapId() and
-- GetStateInstanceId() exist in every state (-1 / 0 in the world state), so state
-- gates use them directly with no probing. Use the helpers below to write
-- context-safe code.
--
-- Usable via: local MS = require("Multistate")
-- (Keep this file dependency-free: it must load in every state, first or last.)

local Multistate = {}

-- True when the engine runs a single global state (legacy behaviour).
function Multistate.IsCompat()
    return IsCompatibilityMode()
end

-- True when this code executes in the global ("world") state.
-- GetStateMapId() returns -1 there (and in compatibility mode, which is a
-- single world state).
function Multistate.IsWorld()
    return GetStateMapId() == -1
end

-- True when this code executes in a map state (never true in compat mode).
function Multistate.IsMap()
    return GetStateMapId() ~= -1
end

-- File-scope guards. Idiom (placed before registrations/logic, after definitions
-- that other files may rely on):
--   local MS = require("Multistate")
--   if MS.SkipMap() then return end    -- global-only script (world events/timers/APIs)
--   if MS.SkipWorld() then return end  -- map-only script (map events/APIs)
function Multistate.SkipMap()
    return Multistate.IsMap()
end

function Multistate.SkipWorld()
    return (not Multistate.IsCompat()) and Multistate.IsWorld()
end

-- Iterate all players visible from the current state: every online player in the
-- global state (or compat mode), otherwise the players on this state's map.
function Multistate.ForEachPlayer(fn)
    if GetStateMapId() == -1 then
        for _, p in ipairs(GetPlayersInWorld()) do
            if p then fn(p) end
        end
    else
        local map = GetStateMap()
        if map then
            for _, p in ipairs(map:GetPlayers()) do
                if p then fn(p) end
            end
        end
    end
end

-- State-aware replacement for GetPlayerByName (WORLD-only; errors in map states).
-- In map states only players on the same map can be resolved; returns nil
-- otherwise. In the global state (and compat mode) this is a direct passthrough.
function Multistate.FindPlayerByName(name)
    if not name then
        return nil
    end
    if Multistate.IsWorld() then
        return GetPlayerByName(name)
    end
    local found = nil
    Multistate.ForEachPlayer(function(p)
        if not found and p:GetName() == name then
            found = p
        end
    end)
    return found
end

-- State-aware replacement for GetPlayerByGUID (WORLD-only; errors in map states).
-- Accepts an ObjectGuid userdata or a guid-low number. In map states only players
-- on the same map can be resolved; returns nil otherwise.
function Multistate.FindPlayerByGUID(guid)
    if guid == nil then
        return nil
    end
    if Multistate.IsWorld() then
        return GetPlayerByGUID(guid)
    end
    local low = nil
    if type(guid) == "number" then
        low = guid
    else
        low = GetGUIDLow(guid)
    end
    if not low then
        return nil
    end
    local found = nil
    Multistate.ForEachPlayer(function(p)
        if not found and p:GetGUIDLow() == low then
            found = p
        end
    end)
    return found
end

-- Count players visible from the current state (replacement for
-- #GetPlayersInWorld(), which errors in map states).
function Multistate.CountPlayers()
    local n = 0
    Multistate.ForEachPlayer(function() n = n + 1 end)
    return n
end

-- Shared cross-state storage on a player object. Unlike the ObjectVariables
-- extension (obj:SetData/GetData, per Lua state), obj:Data() is backed by a
-- process-wide cache shared by every state, so values written in the global
-- state are visible in map states and vice versa. Values must be marshallable
-- (numbers, strings, booleans, plain tables); userdata (players, creatures,
-- items, ...) can NOT be stored — store names/guids instead.
function Multistate.GetShared(player, key)
    if not player or not key then
        return nil
    end
    local v = player:Data():Get(key)
    if v == nil then
        return nil
    end
    if type(v) == "table" and v.AsTable then
        return v:AsTable()
    end
    return v
end

function Multistate.SetShared(player, key, value)
    if not player or not key then
        return
    end
    player:Data():Set(key, value)
end

function Multistate.ClearShared(player, key)
    if not player or not key then
        return
    end
    player:Data():Set(key, nil)
end

return Multistate
