-- EMQ.lua — Eve's Message Queue: inter-state communicator for multistate ALE.
-- Upstream: https://github.com/Foereaper/EMQ (adapted for mod-ale multistate-shoehorn).
--
-- Usage (in any script that needs cross-state messaging):
--   local EMQ = require("EMQ")
--
-- How it works: every player gets a 1s timer in BOTH the global state and their
-- map state. Messages are stored in the player's shared Data() cache (visible
-- from every state), written under the sender's context ("world" or "map") and
-- picked up by the timer running in the opposite context, which dispatches them
-- to the queue handler registered in that state.
--
--   -- global side (e.g. a .command handler, which always runs in world state):
--   EMQ.RegisterQueue("MyQueue", function(player, data) ... end)  -- runs in map state
--   player:SendEMQMessage("MyQueue", { ... })                     -- queued for map state
--
--   -- map side answering back to world state works symmetrically.
--
-- Notes:
--   * `data` must be marshallable (numbers, strings, booleans, plain tables).
--     Pass player/creature/item NAMES or GUIDs, never the objects themselves.
--   * `handler(player, data)` receives the player whose timer picked up the
--     message (the same player the message was queued on).
--   * ALE differences from upstream EMQ: player enumeration is state-aware
--     because GetPlayersInWorld()/GetPlayersOnMap() are world/map-only
--     respectively here (GetStateMap():GetPlayers() is used on maps).
--     GetStateMapId() exists in every state (-1 in world), so context
--     detection calls it directly.
--   * In compatibility (single-state) mode everything runs in the one world
--     state and messages are processed by the same state's timers.

local EMQ = {
    config = {
        frequency = 500, -- message processing delay timer in ms
    },
    queues = {}
}

local function getContext()
    if GetStateMapId() == -1 then
        return "world"
    end
    return "map"
end

function EMQ.RegisterMessageProcessor(event, player)
    if not player then
        return
    end
    player:RegisterEvent(EMQ.ProcessMessages, EMQ.config.frequency, 0)
end

function EMQ.ProcessMessages(_, _, _, player)
    if not player then
        return
    end
    local currentContext = getContext()
    local oppositeContext = (currentContext == "world") and "map" or "world"

    if (IsCompatibilityMode()) then
        oppositeContext = "world"
    end

    local dataCache = player:Data():AsTable()
    local allMessages = dataCache["EMQ_Messages"] or { world = {}, map = {} }
    local messagesToProcess = allMessages[oppositeContext] or {}

    if (#messagesToProcess > 0) then
        allMessages[oppositeContext] = {}
        player:Data():Set("EMQ_Messages", allMessages)

        for _, msg in pairs(messagesToProcess) do
            local handler = EMQ.queues[msg.queue]
            if handler then
                handler(player, msg.data)
            else
                print("No registered handler for queue '" .. msg.queue .. "'. Discarding message.")
            end
        end
    end
end

function EMQ.RegisterQueue(queue, handlerFunction)
    if type(handlerFunction) ~= "function" then
        error("Handler for queue '" .. queue .. "' must be a function.")
    end

    if EMQ.queues[queue] then
        error("Queue '" .. queue .. "' is already registered.")
    end

    EMQ.queues[queue] = handlerFunction
end

function Player:SendEMQMessage(queue, data, sendToCurrentContextAsWell)
    local originContext = getContext()
    local oppositeContext = (originContext == "world") and "map" or "world"

    local dataCache = self:Data():AsTable()
    local allMessages = dataCache["EMQ_Messages"] or { world = {}, map = {} }

    local message = { queue = queue, data = data }

    allMessages[originContext] = allMessages[originContext] or {}
    table.insert(allMessages[originContext], message)

    if sendToCurrentContextAsWell then
        allMessages[oppositeContext] = allMessages[oppositeContext] or {}
        table.insert(allMessages[oppositeContext], message)
    end

    self:Data():Set("EMQ_Messages", allMessages)
end

local function OnLoad()
    local context = getContext()
    local eventId = (context == "world") and 3 or 28
    RegisterPlayerEvent(eventId, EMQ.RegisterMessageProcessor)

    if context == "world" then
        for _, player in pairs(GetPlayersInWorld()) do
            EMQ.RegisterMessageProcessor(eventId, player)
        end
        -- Pumps registered during the reload storm never tick, so register
        -- again once the storm has passed. Global timers tick reliably here.
        CreateLuaEvent(function()
            for _, player in pairs(GetPlayersInWorld()) do
                EMQ.RegisterMessageProcessor(3, player)
            end
        end, 15000, 1)
    else
        local map = GetStateMap()
        if map then
            for _, player in pairs(map:GetPlayers()) do
                EMQ.RegisterMessageProcessor(eventId, player)
            end
        end
        -- Same reload-storm problem as world side: registrations made
        -- during reload never tick, so register again once the storm
        -- has passed.
        CreateLuaEvent(function()
            local stormMap = GetStateMap()
            if stormMap then
                for _, player in pairs(stormMap:GetPlayers()) do
                    EMQ.RegisterMessageProcessor(eventId, player)
                end
            end
        end, 15000, 1)
    end
end

RegisterServerEvent(33, OnLoad)

return EMQ
