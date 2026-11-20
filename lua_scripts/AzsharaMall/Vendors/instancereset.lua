-- Azshara Mall-only script (mall map 37).
-- UnbindInstance is world-state-only, so unbinds run through a world command.
local function OnInstanceResetCommand(event, player, command)
    local targetGuid, map, difficulty = command:lower():match("^[%.!]?instanceresetunbind%s+(%d+)%s+(%d+)%s+(%d+)$")
    if not targetGuid then return end
    if not player then return false end
    local windowEnd = player:Data():Get("InstanceResetWindow")
    local now = os.time()
    if not windowEnd then return false end
    if now > windowEnd then return false end
    local queueCommand = "UnbindInstance(" .. map .. ", " .. difficulty .. ")"
    local ok, target = pcall(GetPlayerByGUID, tonumber(targetGuid))
    if ok and target then
        target:UnbindInstance(tonumber(map), tonumber(difficulty))
        CharDBExecute("UPDATE ycore_yla.command_queue SET executed = 1 WHERE comment = " .. targetGuid .. " AND command = '" .. queueCommand .. "'")
    else
        CharDBExecute("INSERT INTO ycore_yla.command_queue (comment, command, inserted, executed) SELECT " .. targetGuid .. ", '" .. queueCommand .. "', " .. os.time() .. ", 0 FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM ycore_yla.command_queue WHERE comment = " .. targetGuid .. " AND command = '" .. queueCommand .. "' AND executed = 0)")
    end
    return false
end

local NPC_ID = 190090
local TOKEN_ITEM_ID = 20880
local MAX_MENU_ITEMS = 8
local model_ID = 27486
local FREE_RESETS   = 1
local VIP_RESETS    = 2
local freeReset = {}
local resetCount = {}
local accountLockoutCache = {} -- [accountId] = {lockoutMap, chars}

local instanceData = {
    [249] = {name = "Onyxia's Lair", size = 25},
    [269] = {name = "Opening of the Dark Portal", size = 5},
    [309] = {name = "Zul'Gurub", size = 20},
    [409] = {name = "Molten Core", size = 40},
    [469] = {name = "Blackwing Lair", size = 40},
    [509] = {name = "Ruins of Ahn'Qiraj", size = 20},
    [531] = {name = "Ahn'Qiraj Temple", size = 40},
    [532] = {name = "Karazhan", size = 10},
    [533] = {name = "Naxxramas", size = 25},
    [534] = {name = "The Battle for Mount Hyjal", size = 25},
    [540] = {name = "Hellfire Citadel: The Shattered Halls", size = 5},
    [542] = {name = "Hellfire Citadel: The Blood Furnace", size = 5},
    [543] = {name = "Hellfire Citadel: Ramparts", size = 5},
    [544] = {name = "Magtheridon's Lair", size = 25},
    [545] = {name = "Coilfang: The Steamvault", size = 5},
    [546] = {name = "Coilfang: The Underbog", size = 5},
    [547] = {name = "Coilfang: The Slave Pens", size = 5},
    [548] = {name = "Coilfang: Serpentshrine Cavern", size = 25},
    [550] = {name = "Tempest Keep", size = 25},
    [552] = {name = "Tempest Keep: The Arcatraz", size = 5},
    [553] = {name = "Tempest Keep: The Botanica", size = 5},
    [554] = {name = "Tempest Keep: The Mechanar", size = 5},
    [555] = {name = "Auchindoun: Shadow Labyrinth", size = 5},
    [556] = {name = "Auchindoun: Sethekk Halls", size = 5},
    [557] = {name = "Auchindoun: Mana-Tombs", size = 5},
    [558] = {name = "Auchindoun: Auchenai Crypts", size = 5},
    [560] = {name = "The Escape From Durnholde", size = 5},
    [564] = {name = "Black Temple", size = 25},
    [565] = {name = "Gruul's Lair", size = 25},
    [568] = {name = "Zul'Aman", size = 10},
    [574] = {name = "Utgarde Keep", size = 5},
    [575] = {name = "Utgarde Pinnacle", size = 5},
    [576] = {name = "The Nexus", size = 5},
    [578] = {name = "The Oculus", size = 5},
    [580] = {name = "The Sunwell", size = 25},
    [585] = {name = "Magister's Terrace", size = 5},
    [595] = {name = "The Culling of Stratholme", size = 5},
    [599] = {name = "Halls of Stone", size = 5},
    [600] = {name = "Drak'Tharon Keep", size = 5},
    [601] = {name = "Azjol-Nerub", size = 5},
    [602] = {name = "Halls of Lightning", size = 5},
    [603] = {name = "Ulduar", size = 25},
    [604] = {name = "Gundrak", size = 5},
    [608] = {name = "Violet Hold", size = 5},
    [615] = {name = "The Obsidian Sanctum", size = 25},
    [616] = {name = "The Eye of Eternity", size = 25},
    [624] = {name = "Vault of Archavon", size = 25},
    [631] = {name = "Icecrown Citadel", size = 25},
    [632] = {name = "The Forge of Souls", size = 5},
    [649] = {name = "Trial of the Crusader", size = 5},
    [650] = {name = "Trial of the Champion", size = 25},
    [658] = {name = "Pit of Saron", size = 5},
    [668] = {name = "Halls of Reflection", size = 5},
    [724] = {name = "The Ruby Sanctum", size = 25}
}

local pendingReset = {} -- [guid] = {map, difficulty, chars}

local function BuildLockoutCacheForAccount(accountId)
    accountLockoutCache[accountId] = {chars = {}, lockoutMap = {}, freeResets = {}}

    CharDBQueryAsync("SELECT guid, name FROM characters WHERE account = " .. accountId, function(charQuery)
        if not charQuery then return end

        local chars = {}
        local guidList = {}
        repeat
            local guid = charQuery:GetUInt32(0)
            local name = charQuery:GetString(1)
            table.insert(chars, {guid = guid, name = name})
            table.insert(guidList, guid)
        until not charQuery:NextRow()

        accountLockoutCache[accountId].chars = chars

        if #guidList == 0 then return end

        local guidIn = table.concat(guidList, ",")

        CharDBQueryAsync("SELECT guid, time, count FROM ycore_yla.character_instance_vendor_reset WHERE guid IN (" .. guidIn .. ")", function(resetQuery)
            local loaded = {}
            if resetQuery then
                repeat
                    local g = resetQuery:GetUInt32(0)
                    local t = resetQuery:GetUInt32(1)
                    local c = resetQuery:GetUInt32(2)
                    loaded[g] = {time = t, count = c}
                until not resetQuery:NextRow()
            else
            end

            for _, char in ipairs(chars) do
                if loaded[char.guid] then
                    accountLockoutCache[accountId].freeResets[char.guid] = loaded[char.guid].time
                    freeReset[char.guid] = loaded[char.guid].time
                    resetCount[char.guid] = loaded[char.guid].count
                else
                    accountLockoutCache[accountId].freeResets[char.guid] = 0
                    freeReset[char.guid] = 0
                    resetCount[char.guid] = 0
                end
            end
        end)

        CharDBQueryAsync("SELECT ci.guid, i.map, i.difficulty FROM character_instance ci JOIN instance i ON i.id = ci.instance WHERE ci.guid IN (" .. guidIn .. ")", function(instanceQuery)
            if not instanceQuery then return end

            local guidNameMap = {}
            for _, char in ipairs(chars) do
                guidNameMap[char.guid] = char.name
            end

            repeat
                local guid = instanceQuery:GetUInt32(0)
                local map = instanceQuery:GetUInt32(1)
                local difficulty = instanceQuery:GetUInt32(2)
                if instanceData[map] then
                    local key = map * 10 + difficulty
                    if not accountLockoutCache[accountId].lockoutMap[key] then
                        accountLockoutCache[accountId].lockoutMap[key] = {}
                    end
                    local already = false
                    for _, entry in ipairs(accountLockoutCache[accountId].lockoutMap[key]) do
                        if entry.guid == guid then already = true break end
                    end
                    if not already then
                        table.insert(accountLockoutCache[accountId].lockoutMap[key], {guid = guid, name = guidNameMap[guid]})
                    end
                end
            until not instanceQuery:NextRow()
        end)
    end)
end

local function OnPlayerMapChange(event, player)
    if player:IsBot() then return end

    local guid = player:GetGUIDLow()
    local accountId = player:GetAccountId()

    player:RegisterEvent(function(e, d, r, player)
        if player:GetMapId() == 37 then BuildLockoutCacheForAccount(accountId) end
    end, 1000)
    if player:Data():Get("InstanceResetLockChecked") then return end
    CharDBQueryAsync("SELECT command FROM ycore_yla.command_queue WHERE comment = " .. guid .. " AND executed = 0", function(q)
        local player = nil
        for _, p in ipairs(GetStateMap():GetPlayers()) do
            if p:GetGUIDLow() == guid then player = p break end
        end
        if not player then return end

        if q then
            repeat
                local command = q:GetString(0)
                local mapVal, diffVal = command:match("UnbindInstance%((%d+),%s*(%d+)%)")
                if mapVal and diffVal then
                    player:Data():Set("InstanceResetWindow", os.time() + 5)
                    player:RunCommand(".instanceresetunbind " .. guid .. " " .. mapVal .. " " .. diffVal)
                end
            until not q:NextRow()
        end

        player:Data():Set("InstanceResetLockChecked", 1)
    end)
end

local function GetTokenCost(difficulty, size)
    if size == 5 and difficulty > 0 then return 5
    elseif difficulty == 0 then return 50
    elseif difficulty == 1 then return 100
    elseif difficulty == 2 then return 200
    elseif difficulty == 3 then return 400
    else return 0
    end
end

local function ChargeTokens(player, tokenCost)
    local guid = player:GetGUIDLow()
    if tokenCost == 0 then return true end

    if not freeReset[guid] then
        freeReset[guid] = 0
        return true
    end

    if player:GetItemCount(TOKEN_ITEM_ID) >= tokenCost then
        player:RemoveItem(TOKEN_ITEM_ID, tokenCost)
        return true
    else
        player:SendBroadcastMessage("You don't have enough Vote Tokens.")
        return false
    end
end

local function GetDifficultyName(difficulty, size)
    if difficulty == 0 then
        if size == 5 then return "Normal"
        elseif size == 10 or size == 20 or size == 40 then return size .. " Normal"
        elseif size == 25 then return "10 Normal"
        end
    elseif difficulty == 1 then
        if size == 5 then return "Heroic"
        elseif size == 10 then return "Normal"
        elseif size == 25 then return "25 Normal"
        end
    elseif difficulty == 2 then
        return "10 Heroic"
    elseif difficulty == 3 then
        return "25 Heroic"
    end
    return ""
end

local function FormatTimeRemaining(seconds, maxResets)
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local suffix = (maxResets > 1) and ("until " .. maxResets .. " free resets") or "until free reset"
    if days > 0 then
        return days .. "d " .. hours .. "h " .. suffix
    elseif hours > 0 then
        return hours .. "h " .. minutes .. "m " .. suffix
    else
        return minutes .. "m " .. suffix
    end
end

local function GetFreeResetLabel(remaining, maxResets)
    if remaining <= 0 then
        return nil
    end
    if maxResets > 1 then
        return remaining .. " free resets available"
    else
        return "Free reset available"
    end
end

local function ShowCooldownList(player, creature)
    local accountId = player:GetAccountId()
    local cache = accountLockoutCache[accountId]

    player:GossipClearMenu()

    if not cache then
        player:SendBroadcastMessage("Your instance data is still loading, please try again in a moment.")
        player:GossipComplete()
        return
    end

    local maxResets = FREE_RESETS
    if IsVIP(player) then
        maxResets = VIP_RESETS
    end

    for _, char in ipairs(cache.chars) do
        local timerText

        if not freeReset[char.guid] or freeReset[char.guid] < os.time() then
            timerText = GetFreeResetLabel(maxResets, maxResets)
        else
            local remaining = maxResets - (resetCount[char.guid] or 0)
            timerText = GetFreeResetLabel(remaining, maxResets)
            if not timerText then
                timerText = FormatTimeRemaining(freeReset[char.guid] - os.time(), maxResets)
            end
        end

        local label = char.name .. " - " .. timerText
        player:GossipMenuAddItem(0, label, 0, 9998)
    end

    player:GossipMenuAddItem(4, "Back", 0, 7001)
    player:GossipSendMenu(1, creature)
end

local function ResetInstanceLockout(player, map, difficulty, targetGuid, targetName)
    local guid = player:GetGUIDLow()
    local accountId = player:GetAccountId()
    local size = instanceData[map] and instanceData[map].size or 0
    local tokenCost = GetTokenCost(difficulty, size)
    local instanceName = instanceData[map] and instanceData[map].name
    local difficultyName = GetDifficultyName(difficulty, size)

    local maxResets = FREE_RESETS
    if IsVIP(player) then
        maxResets = VIP_RESETS
    end

    if not freeReset[targetGuid] or freeReset[targetGuid] < os.time() then
        freeReset[targetGuid] = os.time() + 7 * 24 * 60 * 60
        resetCount[targetGuid] = 0
    end

    if resetCount[targetGuid] < maxResets then
        tokenCost = 0
        resetCount[targetGuid] = resetCount[targetGuid] + 1

        CharDBExecute("REPLACE INTO ycore_yla.character_instance_vendor_reset (guid, time, count) VALUES (" .. targetGuid .. ", " .. freeReset[targetGuid] .. ", " .. resetCount[targetGuid] .. ")")
    end

    if not ChargeTokens(player, tokenCost) then return end

    player:Data():Set("InstanceResetWindow", os.time() + 5)
    player:RunCommand(".instanceresetunbind " .. targetGuid .. " " .. map .. " " .. difficulty)
    CharDBExecute("DELETE FROM character_instance WHERE guid = " .. targetGuid .. " AND instance IN (SELECT id FROM instance WHERE map = " .. map .. " AND difficulty = " .. difficulty .. ")")

    local key = map * 10 + difficulty
    if accountLockoutCache[accountId] then
        local lockedChars = accountLockoutCache[accountId].lockoutMap[key]
        if lockedChars then
            for i = #lockedChars, 1, -1 do
                if lockedChars[i].guid == targetGuid then
                    table.remove(lockedChars, i)
                    break
                end
            end
            if #lockedChars == 0 then
                accountLockoutCache[accountId].lockoutMap[key] = nil
            end
        end
    else
    end

    if instanceName then
        player:SendBroadcastMessage("Instance lockout for " .. instanceName .. " (" .. difficultyName .. ") has been reset for " .. targetName .. ".")
    else
        player:SendBroadcastMessage("Instance lockout has been reset for " .. targetName .. ".")
    end
end

local function SortInstancesByMapID(lockoutMap)
    local sortedInstances = {}
    for key, chars in pairs(lockoutMap) do
        local map = math.floor(key / 10)
        local difficulty = key % 10
        if instanceData[map] then
            table.insert(sortedInstances, {
                map = map,
                difficulty = difficulty,
                chars = chars,
            })
        end
    end
    table.sort(sortedInstances, function(a, b) return a.map > b.map end)
    return sortedInstances
end

local function ShowCharacterList(player, creature, map, difficulty)
    local guid = player:GetGUIDLow()
    local accountId = player:GetAccountId()
    local cache = accountLockoutCache[accountId]
    local key = map * 10 + difficulty
    local lockedChars = (cache and cache.lockoutMap[key]) or {}
    local size = instanceData[map] and instanceData[map].size or 0
    local instanceName = instanceData[map] and instanceData[map].name or "Unknown"
    local difficultyName = GetDifficultyName(difficulty, size)

    player:GossipClearMenu()

    if #lockedChars == 0 then
        player:SendBroadcastMessage("No characters are locked to this instance.")
        player:GossipComplete()
        return
    end

    for i, char in ipairs(lockedChars) do
        local charTokenCost = GetTokenCost(difficulty, size)

        local maxResets = 1
        if IsVIP(player) then
            maxResets = 2
        end
        if not freeReset[char.guid] or freeReset[char.guid] < os.time() then
            resetCount[char.guid] = 0
            charTokenCost = 0
            elseif resetCount[char.guid] and resetCount[char.guid] < maxResets then
            charTokenCost = 0
        end

        local label = char.name .. " (Cost: " .. charTokenCost .. " Vote Tokens)"
        local confirmText = "Are you sure you want to reset " .. instanceName .. " " .. difficultyName .. " for character " .. char.name .. "? This will cost " .. charTokenCost .. " Vote Tokens."
        player:GossipMenuAddItem(2, label, 0, 50000 + key * 100 + i, false, confirmText)
    end

    pendingReset[guid] = {map = map, difficulty = difficulty, chars = lockedChars}

    player:GossipMenuAddItem(4, "Back", 0, 8000)
    player:GossipMenuAddItem(0, "Nevermind", 0, 9999)
    player:GossipSendMenu(1, creature)
end

local function GenerateMenu(page, player, creature)
    local guid = player:GetGUIDLow()
    local accountId = player:GetAccountId()
    player:GossipClearMenu()

    local cache = accountLockoutCache[accountId]
    if not cache then
        player:SendBroadcastMessage("Your instance data is still loading, please try again in a moment.")
        player:GossipComplete()
        return
    end

    local sortedInstances = SortInstancesByMapID(cache.lockoutMap)

    player:GossipMenuAddItem(0, "Check free reset cooldown", 0, 7000)

    local startIndex = (page - 1) * MAX_MENU_ITEMS + 1
    local endIndex = math.min(page * MAX_MENU_ITEMS, #sortedInstances)
    local shown = 0

    for i = startIndex, endIndex do
        local instance = sortedInstances[i]
        local map, difficulty = instance.map, instance.difficulty
        local size = instanceData[map].size

        if not (size == 5 and difficulty == 0) then
            local instanceName = instanceData[map].name
            local difficultyName = GetDifficultyName(difficulty, size)
            local gossipText = instanceName .. " " .. difficultyName
            player:GossipMenuAddItem(2, gossipText, 0, 10000 + map * 10 + difficulty)
            shown = shown + 1
        end
    end

    if shown == 0 then
        player:GossipMenuAddItem(0, "You don't have any instance locks to reset.", 0, 7001)
        player:GossipSendMenu(1, creature)
        return
    end

    if page > 1 then
        player:GossipMenuAddItem(4, "Previous page", 0, 1000 + page - 1)
    end
    if endIndex < #sortedInstances then
        player:GossipMenuAddItem(4, "Next page", 0, 1000 + page + 1)
    end

    player:GossipMenuAddItem(0, "Nevermind", 0, 9999)
    player:GossipSendMenu(1, creature)
end

local function ReaddLiveLockouts(player)
    local accountId = player:GetAccountId()
    local cache = accountLockoutCache[accountId]
    if not cache then return end
    for _, char in ipairs(cache.chars) do
        local okLive, live = pcall(GetPlayerByGUID, char.guid)
        if okLive and live then
            for map, data in pairs(instanceData) do
                for difficulty = 0, 3 do
                    local okBind, bind = pcall(function() return live:GetBoundInstance(map, difficulty) end)
                    if okBind and bind then
                        local key = map * 10 + difficulty
                        if not cache.lockoutMap[key] then
                            cache.lockoutMap[key] = {}
                        end
                        local already = false
                        for _, entry in ipairs(cache.lockoutMap[key]) do
                            if entry.guid == char.guid then already = true break end
                        end
                        if not already then
                            table.insert(cache.lockoutMap[key], {guid = char.guid, name = char.name})
                        end
                    end
                end
            end
        end
    end
end

local function OnGossipHello(event, player, creature)
    player:GossipClearMenu()
    ReaddLiveLockouts(player)
    GenerateMenu(1, player, creature)
end

local function OnGossipSelect(event, player, creature, sender, intid, code, menu_id)
    local guid = player:GetGUIDLow()
    local accountId = player:GetAccountId()

    if intid == 7000 then
        ShowCooldownList(player, creature)
        return
    end

    if intid == 7001 then
        OnGossipHello(nil, player, creature)
        return
    end

    if intid == 9998 then
        ShowCooldownList(player, creature)
        return
    end

    if intid >= 1000 and intid <= 1050 then
        local newPage = intid - 1000
        GenerateMenu(newPage, player, creature)
        return
    end

    if intid == 9999 then
        player:GossipComplete()
        return
    end

    if intid == 8000 then
        GenerateMenu(1, player, creature)
        return
    end

    if intid >= 50000 then
        local remainder = intid - 50000
        local key = math.floor(remainder / 100)
        local charIndex = remainder % 100
        local pending = pendingReset[guid]
        if pending and pending.chars[charIndex] then
            local char = pending.chars[charIndex]
            ResetInstanceLockout(player, pending.map, pending.difficulty, char.guid, char.name)
        else
        end

        local map = math.floor(key / 10)
        local difficulty = key % 10
        local cache = accountLockoutCache[accountId]
        local lockedChars = cache and cache.lockoutMap[key]
        if lockedChars and #lockedChars > 0 then
            ShowCharacterList(player, creature, map, difficulty)
        else
            GenerateMenu(1, player, creature)
        end
        return
    end
    if intid >= 10000 then
        local key = intid - 10000
        local map = math.floor(key / 10)
        local difficulty = key % 10
        ShowCharacterList(player, creature, map, difficulty)
        return
    end

    player:GossipComplete()
end

-- State-aware catch-up for already-online players (server start or
-- reload). GetPlayersInWorld() only exists in the global state.

if GetStateMapId() == -1 then
    for _, player in ipairs(GetPlayersInWorld()) do
        OnPlayerMapChange(nil, player)
    end
elseif GetStateMap() then
    for _, player in ipairs(GetStateMap():GetPlayers()) do
        OnPlayerMapChange(nil, player)
    end
end

RegisterPlayerEvent(28, OnPlayerMapChange)
RegisterPlayerEvent(42, OnInstanceResetCommand)
RegisterCreatureGossipEvent(NPC_ID, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_ID, 2, OnGossipSelect)
CharDBExecute("CREATE TABLE IF NOT EXISTS ycore_yla.character_instance_vendor_reset (guid INT NOT NULL, time INT NOT NULL, count INT DEFAULT 0, PRIMARY KEY (guid));")
