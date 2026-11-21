if GetStateMapId() ~= -1 then return end

local ALLOWED = {
    "^%.cache refresh ",
    "^%.send items ",
}

local function IsAllowed(command)
    if type(command) ~= "string" then
        return false
    end
    if command:find("[%c;]") then
        return false
    end
    for _, pattern in ipairs(ALLOWED) do
        if command:find(pattern) then
            return true
        end
    end
    return false
end

local function OnFirstLogin(event, player)
    if player:GetMapId() == 571 then
        local guid = player:GetGUIDLow()
        local name = player:GetName()
        
        CreateLuaEvent(function()
            RunCommand(".cache refresh "..name)
            RunCommand(".character customize "..name)
        end, 1000, 1)
        
        CreateLuaEvent(function()
            CharDBQueryAsync("SELECT command FROM ycore_yla.legacy_transfer_queue WHERE guid = "..guid, function(query)
                if query then
                    local commands = {}
                    repeat
                        table.insert(commands, query:GetString(0))
                    until not query:NextRow()
                    for _, command in ipairs(commands) do
                        if IsAllowed(command) then
                            RunCommand(command)
                        else
                            print("legacy_transfer_queue rejected: " .. command)
                        end
                    end
                    CharDBExecute("DELETE FROM ycore_yla.legacy_transfer_queue WHERE guid = "..guid)
                end
            end)
        end, 10000, 1)
        
        player:RegisterEvent(function(_,_,_,player)
            if not player:HasItem(6948) then player:AddItem(6948) end
            player:SendBroadcastMessage("|cFFA64DFFWelcome to Yggdrasil, "..name.."!\nPlease check your mail to retrieve your items. As a part of your arrival, you will be able to customize your character from next logout.|t")
        end, 10000, 1)
        
    end
end

RegisterPlayerEvent(30, OnFirstLogin)