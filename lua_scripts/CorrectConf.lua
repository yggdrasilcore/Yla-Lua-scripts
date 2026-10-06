-- Multistate: the reload-conf timer must run exactly once server-wide in the global state.
if GetStateMapId() ~= -1 then return end

CreateLuaEvent(function()
    RunCommand("reload conf")
    print("Reloading conf...")
end, 10000)