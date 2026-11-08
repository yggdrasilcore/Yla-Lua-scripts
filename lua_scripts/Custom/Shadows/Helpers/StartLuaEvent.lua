function StartLuaEvent(unit, eventName)
    if not unit:Data():Get("EventActive") then
        unit:Data():Set("EventActive", 1)
        unit:Data():Set("CombatTime", 0)
        unit:Data():Set("CombatStart", os.time())
        unit:RegisterEvent(eventName, 200, 1)
    end
end