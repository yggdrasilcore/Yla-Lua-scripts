if GetStateMapId() ~= -1 then return end

local function ProcessCommandQueue()
    CharDBQueryAsync("SELECT command FROM ycore_yla.command_queue WHERE executed IS NULL", function(query)
        if query then
            local commands = {}
            repeat
                table.insert(commands, query:GetString(0))
            until not query:NextRow()

            for _, command in ipairs(commands) do
                RunCommand(command)
            end

            CharDBExecute(string.format(
                "UPDATE ycore_yla.command_queue SET executed = %d WHERE executed IS NULL",
                os.time()
            ))
        end
    end)
end

CreateLuaEvent(ProcessCommandQueue, 300000, 0)