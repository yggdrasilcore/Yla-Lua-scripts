-- Multistate: Azshara Mall-only script (mall map 37).
if GetStateMapId() ~= 37 then return end

local NPC_ID = 190092 -- Replace with your NPC's ID
local VOTE_TOKEN = 20880
local VOTE_TOKEN_NAME = "Vote Tokens"
local PRICE = 50
local CHARGE_DELAY_SEC = 2 -- delayed pay-on-success check fires this long after the command

-- One outstanding op per player, stored in the cross-state player:Data() cache.
-- Entry shape: {op, old, expected, ts, seq}. Values must stay marshallable (no userdata).
local PENDING_KEY = "GuildVendorOp"
local opSeq = 0

local function GetPending(player)
    local v = player:Data():Get(PENDING_KEY)
    if v == nil then
        return nil
    end
    if type(v) == "table" and v.AsTable then
        return v:AsTable()
    end
    return v
end

local function IsPending(player)
    local entry = GetPending(player)
    if entry == nil then
        return false
    end
    if os.time() - (entry.ts or 0) > 1 then
        player:Data():Set(PENDING_KEY, nil) -- stale, timer never fired; next op may proceed
        return false
    end
    return true
end

local function IsValidGuildName(guildName)
    if #guildName < 5 or #guildName > 23 then
        return false
    end
    for i = 1, #guildName do
        local char = guildName:sub(i, i)
        local isValid = (char >= 'a' and char <= 'z') or (char >= 'A' and char <= 'Z') or char == ' '
        if not isValid then
            return false
        end
    end
    return true
end

-- Pay-on-success: each op records its own old + expected name; the 2s check
-- only clears/charges its own op, so concurrent ops can't bleed into each other.
local function ScheduleChargeOnGuildChange(player, op, oldGuildName, expectedGuildName)
    opSeq = opSeq + 1
    local mySeq = opSeq
    player:Data():Set(PENDING_KEY, {op = op, old = oldGuildName, expected = expectedGuildName, ts = os.time(), seq = mySeq})
    player:RegisterEvent(function(_, _, _, p)
        if p == nil then
            return
        end
        local entry = GetPending(p)
        if entry == nil or entry.seq ~= mySeq then
            return -- superseded by a newer op, or data wiped on logout
        end
        p:Data():Set(PENDING_KEY, nil)
        local newGuildName = p:IsInGuild() and p:GetGuildName() or nil
        local success = (newGuildName ~= nil and newGuildName == expectedGuildName and newGuildName ~= oldGuildName)
        if success then
            if p:HasItem(VOTE_TOKEN, PRICE, true) then
                p:RemoveItem(VOTE_TOKEN, PRICE)
                if op == "rename" then
                    p:SendBroadcastMessage("Your guild '" .. tostring(oldGuildName) .. "' has been renamed to '" .. newGuildName .. "'. You have been charged " .. PRICE .. " " .. VOTE_TOKEN_NAME .. ". The change will be visible after next server restart.")
                else
                    p:SendBroadcastMessage("Guild '" .. newGuildName .. "' created! You have been charged " .. PRICE .. " " .. VOTE_TOKEN_NAME .. ".")
                end
            else
                p:SendBroadcastMessage("Your guild was changed to '" .. newGuildName .. "' but you don't have enough " .. VOTE_TOKEN_NAME .. " to pay (" .. PRICE .. "). Please acquire them as soon as possible.")
            end
            print("Guild Vendor [" .. op .. "] - Guild changed from '" .. tostring(oldGuildName) .. "' to '" .. newGuildName .. "' for " .. p:GetName() .. ", charged " .. PRICE)
        else
            p:SendBroadcastMessage("Guild change failed, you were not charged.")
            print("Guild Vendor [" .. op .. "] - No guild change for " .. p:GetName() .. " (old: '" .. tostring(oldGuildName) .. "', new: '" .. tostring(newGuildName) .. "', expected: '" .. tostring(expectedGuildName) .. "'), not charged.")
        end
    end, CHARGE_DELAY_SEC * 1000, 1)
end

local function OnGossipHello(event, player, creature)
    if IsPending(player) then
        creature:SendUnitWhisper("You already have a guild operation in progress, please wait a few seconds.", 0, player)
        player:GossipComplete()
    else
        player:GossipMenuAddItem(4, "|TInterface/ICONS/INV_Misc_QuestionMark:32:32:-26:0|t Greetings, what can I do for you?",  0, 1)
        player:GossipMenuAddItem(0, "|TInterface/ICONS/INV_Shirt_GuildTabard_01:32:32:-26:0|t Buy a guild for "..PRICE.." "..VOTE_TOKEN_NAME, 0, 2, true, "What would you like to name your new guild?\n \nAfter its name,\nremember to click 'accept' to continue.\n ")
        player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_scroll_02:32:32:-26:0|t Rename guild for "..PRICE.." "..VOTE_TOKEN_NAME, 0, 3, true, "What would you like to rename your guild to?\n \nAfter entering the new name,\nremember to click 'accept' to continue.\n \nNote: Guild renames reflect after a server restart. Restarts are done weekly.\n ")
        player:GossipMenuAddItem(0, "|TInterface/ICONS/Trade_Engineering:32:32:-26:0|t Nevermind", 0, 9)
        player:GossipSendMenu(12, creature, 60)
    end
end

local function OnGossipSelect(event, player, creature, sender, intid, code, menu_id)
    if intid == 1 then
        OnGossipHello(event, player, creature)
    elseif intid == 2 then
        if IsPending(player) then
            creature:SendUnitWhisper("You already have a guild operation in progress, please wait a few seconds.", 0, player)
            player:GossipComplete()
            return false
        end
        if player:IsInGuild() then
            creature:SendUnitWhisper("You can't buy a guild if you're already in a guild!", 0, player)
            player:GossipComplete()
            return false
        end
        if code and code ~= "" then
            -- Strip quotes so RunCommand stays well-formed, then validate length/charset.
            local guildName = code:gsub('"', '')
            if not IsValidGuildName(guildName) then
                creature:SendUnitWhisper("Invalid guild name. Use only letters and spaces, between 5 and 23 characters.", 0, player)
                OnGossipHello(event, player, creature)
                return false
            end
            if not player:HasItem(VOTE_TOKEN, PRICE, true) then
                creature:SendUnitWhisper("You don't have enough "..VOTE_TOKEN_NAME.."!", 0, player)
                OnGossipHello(event, player, creature)
                return false
            end
            print("Guild Create - Requested name: '" .. guildName .. "' by " .. player:GetName())
            RunCommand('.guild create ' .. player:GetName() .. ' "' .. guildName .. '"')
            print('.guild create ' .. player:GetName() .. ' "' .. guildName .. '"')
            creature:SendUnitWhisper("Creating guild '" .. guildName .. "'...", 0, player)
            player:GossipComplete()
            ScheduleChargeOnGuildChange(player, "create", nil, guildName)
        else
            OnGossipHello(event, player, creature)
        end
    elseif intid == 3 then
        if IsPending(player) then
            creature:SendUnitWhisper("You already have a guild operation in progress, please wait a few seconds.", 0, player)
            player:GossipComplete()
            return false
        end
        if not (player:GetGuildRank() == 0) then
            creature:SendUnitWhisper("Only Guild Masters can rename a guild!", 0, player)
            player:GossipComplete()
            return false
        end
        if code and code ~= "" then
            -- Strip quotes so RunCommand stays well-formed, then validate length/charset.
            local guildName = code:gsub('"', '')
            if not IsValidGuildName(guildName) then
                creature:SendUnitWhisper("Invalid guild name. Use only letters and spaces, between 5 and 23 characters.", 0, player)
                OnGossipHello(event, player, creature)
                return false
            end
            if not player:HasItem(VOTE_TOKEN, PRICE, true) then
                creature:SendUnitWhisper("You don't have enough "..VOTE_TOKEN_NAME.."!", 0, player)
                OnGossipHello(event, player, creature)
                return false
            end
            local oldGuildName = player:GetGuildName()
            print("Guild Rename - Requested name: '" .. guildName .. "' by " .. player:GetName() .. " (old: '" .. tostring(oldGuildName) .. "')")
            RunCommand('.guild rename "' .. tostring(oldGuildName) .. '" "' .. guildName .. '"')
            print('.guild rename "' .. tostring(oldGuildName) .. '" "' .. guildName .. '"')
            creature:SendUnitWhisper("Renaming guild '" .. tostring(oldGuildName) .. "' to '" .. guildName .. "'...", 0, player)
            player:GossipComplete()
            ScheduleChargeOnGuildChange(player, "rename", oldGuildName, guildName)
        else
            OnGossipHello(event, player, creature)
        end
    elseif intid == 9 then
        player:GossipComplete()
    end
end

RegisterCreatureGossipEvent(NPC_ID, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_ID, 2, OnGossipSelect)