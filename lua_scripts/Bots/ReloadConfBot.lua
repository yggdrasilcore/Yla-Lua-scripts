local function ReloadConfig()
    RunCommand("reload conf")
    RunCommand("ahbotoptions ahexpire 2")
    RunCommand("ahbotoptions ahexpire 6")
    RunCommand("ahbotoptions ahexpire 7")
end

CreateLuaEvent(ReloadConfig, 24*60*60*1000, 0)