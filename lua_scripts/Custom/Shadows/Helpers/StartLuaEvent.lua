local activeEvents = {}

local function EventKey(unit)
    return unit:GetGUIDLow() .. ":" .. unit:GetName()
end

function IsLuaEventActive(unit)
    return activeEvents[EventKey(unit)] ~= nil
end

function StartLuaEvent(unit, eventName, delay, repeats)
    local key = EventKey(unit)
    local previous = activeEvents[key]
    if previous then unit:RemoveEventById(previous) end
    unit:Data():Set("CombatTime", 0)
    unit:Data():Set("CombatStart", os.time())
    activeEvents[key] = unit:RegisterEvent(eventName, delay or 200, repeats or 1)
end

function StopLuaEvent(unit)
    unit:RemoveEvents()
    activeEvents[EventKey(unit)] = nil
    unit:Data():Set("CombatTime", nil)
end
