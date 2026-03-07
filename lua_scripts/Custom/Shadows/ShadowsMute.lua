local mutedShadows = {}

local function OnCommand(event, player, command)
    if command == "muteshadows" or command == "unmuteshadows" then
        local muting = command == "muteshadows"
        local senderAccountId = player:GetAccountId()
        local senderName = player:GetName()
        local affected = {}

        for _, p in ipairs(GetPlayersInWorld()) do
            if p:GetAccountId() == senderAccountId and p:GetName() ~= senderName then
                local name = p:GetName()
                mutedShadows[name] = muting or nil
                table.insert(affected, name)
            end
        end

        if #affected > 0 then
            player:SendBroadcastMessage((muting and "Muted: " or "Unmuted: ") .. table.concat(affected, ", "))
        else
            player:SendBroadcastMessage("No shadows found.")
        end
        return false
    end
end

local function OnChatMessage(event, player, message, _, _, _, _)
    local name = player:GetName()
    if not mutedShadows[name] then return end
    if player:IsBot() then
        print("Shadow " .. name .. " muted from saying " .. message)
        return false
    end
end

RegisterPlayerEvent(42, OnCommand)
RegisterPlayerEvent(18, OnChatMessage)
RegisterPlayerEvent(20, OnChatMessage)
RegisterPlayerEvent(21, OnChatMessage)
RegisterPlayerEvent(22, OnChatMessage)