if GetStateMapId() ~= -1 then return end

local ALLOWED = {
    "^UnbindInstance[ %w]*$",
    "^%.character level[ %w\128-\255]*$",
    "^%.?character changeaccount [%w_\128-\255]+ [%w_%.@%-\128-\255]+$",
}

local function IsAllowed(command)
    if type(command) ~= "string" or #command > 100 then
        return false
    end
    if command:find("[%c;]") then
        return false
    end
    for _, pattern in ipairs(ALLOWED) do
        if command:match(pattern) then
            return true
        end
    end
    return false
end

local function ProcessCommandQueue()
    CharDBQueryAsync("SELECT command FROM ycore_yla.command_queue WHERE executed IS NULL", function(query)
        if query then
            local commands = {}
            repeat
                table.insert(commands, query:GetString(0))
            until not query:NextRow()

            for _, command in ipairs(commands) do
                if IsAllowed(command) then
                    RunCommand(command)
                else
                    print("command_queue rejected: " .. command)
                end
            end

            CharDBExecute(string.format(
                "UPDATE ycore_yla.command_queue SET executed = %d WHERE executed IS NULL",
                os.time()
            ))
        end
    end)
end

CreateLuaEvent(ProcessCommandQueue, 300000, 0)