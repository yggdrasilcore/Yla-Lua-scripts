function StopLuaEvent(creature)
    creature:RemoveEvents()
    creature:SetData("EventActive", nil)
end