local function ReloadConfig()
    RunCommand("ahbotoptions ahexpire 2")
    RunCommand("ahbotoptions ahexpire 6")
    RunCommand("ahbotoptions ahexpire 7")
    RunCommand("reload conf")
end

CreateLuaEvent(ReloadConfig, 36*60*60*1000, 0)