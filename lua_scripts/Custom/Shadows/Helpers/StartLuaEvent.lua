function StartLuaEvent(unit, eventName, delay, repeats)
    local previous = unit:Data():Get("EventActive")
    if previous then unit:RemoveEventById(previous) end
    unit:Data():Set("CombatTime", 0)
    unit:Data():Set("CombatStart", os.time())
    unit:Data():Set("EventActive", unit:RegisterEvent(eventName, delay or 200, repeats or 1))
end
