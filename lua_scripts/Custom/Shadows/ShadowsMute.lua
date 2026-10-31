if GetStateMapId() ~= -1 then return end

local mutedAccounts = {}

local function OnCommand(event, player, command)
    if command == "muteshadows" or command == "unmuteshadows" then
        local muting = command == "muteshadows"
        local senderAccountId = player:GetAccountId()
        local affected = {}

        if muting then
            mutedAccounts[senderAccountId] = true
        else
            mutedAccounts[senderAccountId] = nil
        end

        for _, p in ipairs(GetPlayersInWorld()) do
            if p:GetAccountId() == senderAccountId and p:IsBot() then
                local name = p:GetName()
                table.insert(affected, name)
            end
        end

        if #affected > 0 then
            player:SendBroadcastMessage((muting and "Muted: " or "Unmuted: ") .. table.concat(affected, ", "))
        else
            player:SendBroadcastMessage((muting and "Mute saved. No shadows currently online." or "Unmuted. No shadows currently online."))
        end
        return false
    end
end

local function OnChatMessage(event, player, message, _, _, _, _)
    if not player:IsBot() then return end
    local accountId = player:GetAccountId()
    if not mutedAccounts[accountId] then return end
    print("Shadow " .. player:GetName() .. " muted from saying " .. message)
    return false
end

local function OnLogin(event, player)
    if player:IsBot() then
        local accountId = player:GetAccountId()
        if mutedAccounts[accountId] then
            print("Shadow " .. player:GetName() .. " muted on login (cached mute for account " .. accountId .. ")")
        end
    else
        local accountId = player:GetAccountId()
        if mutedAccounts[accountId] then
            mutedAccounts[accountId] = nil
            print("Cleared mute cache for account " .. accountId .. " on non-bot logout")
        end
    end
end

RegisterPlayerEvent(42, OnCommand)
RegisterPlayerEvent(18, OnChatMessage)
RegisterPlayerEvent(20, OnChatMessage)
RegisterPlayerEvent(21, OnChatMessage)
RegisterPlayerEvent(22, OnChatMessage)
RegisterPlayerEvent(3, OnLogin)
RegisterPlayerEvent(4, OnLogin)