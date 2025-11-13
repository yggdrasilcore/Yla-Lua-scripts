local mutedShadows = {}
local function OnCommand(event, player, command)
    local args = {}
    for arg in command:gmatch("%S+") do
        table.insert(args, arg)
    end
    
    if args[1] == "muteshadow" then
        for i = 2, #args do
            mutedShadows[args[i]] = true
            print("Muted shadow: " .. args[i])
        end
        return false
    elseif args[1] == "unmuteshadow" then
        for i = 2, #args do
            mutedShadows[args[i]] = nil
            print("Unmuted shadow: " .. args[i])
        end
        return false
    end
end
local function OnChatMessage(event, player, message, _, _, _, _)
    local name = player:GetName()
    
    local mutedList = {}
    for shadowName, _ in pairs(mutedShadows) do
        table.insert(mutedList, shadowName)
    end
    
    if not mutedShadows[name] then return end
    if isPlayerBot[name] then
        return false
    end
end
RegisterPlayerEvent(42, OnCommand)
RegisterPlayerEvent(18, OnChatMessage)
RegisterPlayerEvent(20, OnChatMessage)
RegisterPlayerEvent(21, OnChatMessage)
RegisterPlayerEvent(22, OnChatMessage)