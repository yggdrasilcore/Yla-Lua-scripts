local function ReloadConfig()
    RunCommand("reload conf")
    RunCommand("ahbotoptions ahexpire 2")
    RunCommand("ahbotoptions ahexpire 6")
    RunCommand("ahbotoptions ahexpire 7")
end

CreateLuaEvent(ReloadConfig, 36*60*60*1000, 0)