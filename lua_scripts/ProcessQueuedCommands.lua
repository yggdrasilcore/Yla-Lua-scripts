local function ProcessCommandQueue()
    CharDBQueryAsync("SELECT command FROM acore_eluna.command_queue WHERE executed IS NULL", function(query)
        if query then
            repeat
                local command = query:GetString(0)
                RunCommand(command)
                CharDBExecute(string.format("UPDATE acore_eluna.command_queue SET executed = %d WHERE command = '%s' AND executed IS NULL LIMIT 1", os.time(), command:gsub("'", "\\'")))
            until not query:NextRow()
        end
    end)
end

CreateLuaEvent(ProcessCommandQueue, 30000, 0)