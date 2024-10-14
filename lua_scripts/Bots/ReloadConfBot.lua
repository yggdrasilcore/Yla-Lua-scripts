local function ReloadConfig()
    RunCommand("reload conf")
end

CreateLuaEvent(ReloadConfig, 24*60*60*1000, 0)