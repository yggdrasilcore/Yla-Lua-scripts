if GetStateMapId() ~= -1 then return end

local mutedAccounts = {}

-- Persistent chatter state, stored per character in character_custom_data type 97.
local CHATTER_DATA_TYPE = 97

local function ToBool(value)
    return value == true or value == "ENABLED"
end

local function SendChatterState(player)
    if ToBool(player:Data():Get("ShadowsChatterData")) then
        player:SendAddonMessage("ShadowsBar", "CHATTERON", 7, player)
    else
        player:SendAddonMessage("ShadowsBar", "CHATTEROFF", 7, player)
    end
end

local function SaveChatterState(player)
    local data = ToBool(player:Data():Get("ShadowsChatterData")) and 'ENABLED' or 'DISABLED'
    CharDBExecute("REPLACE INTO ycore_yla.character_custom_data (guid, type, time, data) VALUES ("..player:GetGUIDLow()..", "..CHATTER_DATA_TYPE..", "..os.time()..", '"..data.."')")
end

local function OnCommand(event, player, command)
    if command == "shadowschatteron" or command == "shadowschatteroff" then
        player:Data():Set("ShadowsChatterData", command == "shadowschatteron")
        SaveChatterState(player)
        SendChatterState(player)
        return false
    end

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

local function IsChatterDisabled(player)
    local shadow = player:ToShadow()
    local master = shadow and shadow:GetMaster()
    if not master then return false end
    return master:Data():Get("ShadowsChatterData") == false
end

local function OnChatMessage(event, player, message, _, _, _, _)
    if not player:IsBot() then return end
    local accountId = player:GetAccountId()
    if mutedAccounts[accountId] or IsChatterDisabled(player) then
        print("Shadow " .. player:GetName() .. " muted from saying " .. message)
        return false
    end
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

-- Loads the stored chatter state and sends it to the client. Called by the ".shadowsbarstatus"
-- handler in ShadowsCore, because the client announces its addon load there. Not keyed on login,
-- where the player may not be available (e.g. logging into an invalid map).
function LoadShadowsChatterState(player)
    local guid = player:GetGUIDLow()
    CharDBQueryAsync("SELECT data FROM ycore_yla.character_custom_data WHERE guid = "..guid.." AND type = "..CHATTER_DATA_TYPE, function(result)
        local target = GetPlayerByGUID(GetPlayerGUID(guid))
        if not target then return end
        if result then target:Data():Set("ShadowsChatterData", result:GetString(0) == "ENABLED") end
        SendChatterState(target)
    end)
end

RegisterPlayerEvent(42, OnCommand)
RegisterPlayerEvent(18, OnChatMessage)
RegisterPlayerEvent(20, OnChatMessage)
RegisterPlayerEvent(21, OnChatMessage)
RegisterPlayerEvent(22, OnChatMessage)
RegisterPlayerEvent(3, OnLogin)
RegisterPlayerEvent(4, OnLogin)