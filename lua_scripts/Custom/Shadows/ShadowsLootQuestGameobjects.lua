-- World queries the index once and publishes it as serialized world data;
-- map states adopt the shared copy and never query.
local Multistate = require("Multistate")

local questItemGoCache = {}
local cachedQuests = {}
local cachedItems = {}
local cachedGOs = {}

local function AdoptQuestItemGO()
    local shared = GetWorldData("QuestItemGO")
    if type(shared) == "table" and shared.AsTable then
        shared = shared:AsTable()
    end
    if type(shared) ~= "table" or type(shared.cache) ~= "table" then
        return false
    end
    questItemGoCache = shared.cache
    cachedQuests = type(shared.quests) == "table" and shared.quests or {}
    cachedItems = type(shared.items) == "table" and shared.items or {}
    cachedGOs = type(shared.gos) == "table" and shared.gos or {}
    return true
end

local function PublishQuestItemGO()
    SetWorldData("QuestItemGO", {
        cache = questItemGoCache,
        quests = cachedQuests,
        items = cachedItems,
        gos = cachedGOs,
    })
end

if Multistate.IsWorld() then
WorldDBQueryAsync([[
    SELECT gqi.GameObjectEntry, qt.ID AS QuestID, gqi.ItemId,
        CASE
            WHEN gqi.ItemId = qt.RequiredItemId1 THEN qt.RequiredItemCount1
            WHEN gqi.ItemId = qt.RequiredItemId2 THEN qt.RequiredItemCount2
            WHEN gqi.ItemId = qt.RequiredItemId3 THEN qt.RequiredItemCount3
            WHEN gqi.ItemId = qt.RequiredItemId4 THEN qt.RequiredItemCount4
            WHEN gqi.ItemId = qt.RequiredItemId5 THEN qt.RequiredItemCount5
            WHEN gqi.ItemId = qt.RequiredItemId6 THEN qt.RequiredItemCount6
        END AS RequiredCount,
        got.Data3
    FROM quest_template qt
    INNER JOIN gameobject_questitem gqi
        ON gqi.ItemId IN (
            qt.RequiredItemId1, qt.RequiredItemId2, qt.RequiredItemId3,
            qt.RequiredItemId4, qt.RequiredItemId5, qt.RequiredItemId6
        )
    INNER JOIN gameobject_template got
        ON got.entry = gqi.GameObjectEntry
        AND got.type = 3
    WHERE
        qt.RequiredItemId1 > 0 OR qt.RequiredItemId2 > 0 OR qt.RequiredItemId3 > 0 OR
        qt.RequiredItemId4 > 0 OR qt.RequiredItemId5 > 0 OR qt.RequiredItemId6 > 0
    ORDER BY qt.ID
]], function(results)
    if not results then return end

    repeat
        local goEntry   = results:GetUInt32(0)
        local questId   = results:GetUInt32(1)
        local itemId    = results:GetUInt32(2)
        local itemCount = results:GetUInt32(3)
        local data3     = results:GetUInt32(4)

        if not questItemGoCache[questId] then
            questItemGoCache[questId] = {}
            cachedQuests[questId] = true
        end

        table.insert(questItemGoCache[questId], {
            goEntry   = goEntry,
            itemId    = itemId,
            itemCount = itemCount,
            data3     = data3,
        })

        cachedItems[itemId] = true
        cachedGOs[goEntry]  = true
    until not results:NextRow()

    local numQuests = 0
    local numItems  = 0
    local numGOs    = 0
    for _ in pairs(cachedQuests) do numQuests = numQuests + 1 end
    for _ in pairs(cachedItems)  do numItems  = numItems  + 1 end
    for _ in pairs(cachedGOs)    do numGOs    = numGOs    + 1 end

    print("[QuestItemGO] Indexed " .. numQuests .. " quests, " .. numItems .. " items, " .. numGOs .. " gameobjects.")
    PublishQuestItemGO()
end)
else
    CreateLuaEvent(function(eventId)
        if AdoptQuestItemGO() then
            RemoveEventById(eventId)
        end
    end, 5000, 0)
end

print("[QuestItemGO] questItemGoCache = {")
for questId, entries in pairs(questItemGoCache) do
    print("    [" .. questId .. "] = {")
    for _, e in ipairs(entries) do
        print("        { goEntry=" .. e.goEntry .. ", itemId=" .. e.itemId .. ", itemCount=" .. e.itemCount .. ", data3=" .. e.data3 .. " },")
    end
    print("    },")
end
print("}")

local function GetItemName(itemId)
    local template = GetItemTemplate(itemId)
    return template and template:GetName() or tostring(itemId)
end

local function PlayerHasEnoughFreeSlots(player, requiredSlots)
    local freeSlots = 0
    for slot = 23, 38 do
        if not player:GetItemByPos(255, slot) then freeSlots = freeSlots + 1 end
    end
    for bag = 19, 22 do
        local bagItem = player:GetItemByPos(255, bag)
        if bagItem then
            local bagSize = bagItem:GetBagSize()
            for slot = 0, bagSize - 1 do
                if not player:GetItemByPos(bag, slot) then freeSlots = freeSlots + 1 end
            end
        end
    end
    return freeSlots >= requiredSlots
end

local function CanLootItem(player, data)
    local currentCount = player:GetItemCount(data.itemId)
    if data.itemCount > 1 then
        -- has at least 1 already (stackable) or has a free slot
        return currentCount > 0 or PlayerHasEnoughFreeSlots(player, 1)
    else
        return PlayerHasEnoughFreeSlots(player, 1)
    end
end

local function WhisperBagsFull(player, data)
    local throttleKey = "BagsFullWhisper_" .. data.itemId
    local lastWhisper = player:GetData(throttleKey)
    if lastWhisper and os.time() - lastWhisper < 120 then return end
    player:SetData(throttleKey, os.time())

    local masterName = player:IsBot()
    local master = require("Multistate").FindPlayerByName(masterName)
    if not master then return end

    local itemName = GetItemName(data.itemId)
    player:Whisper("I need to loot " .. itemName .. " from a nearby object, but my bags are full. Could you help me empty them or trade some items from me?", 0, master)
end

local function LootObject(eventId, delay, repeats, player, data)
    local go = player:GetNearestGameObject(20, data.goEntry)
    if not go then return end

    local dist = player:GetDistance(go)
    if dist > 4 then
        local gx, gy, gz = go:GetLocation()
        player:MoveTo(0, gx, gy, gz, true)
        return
    end

    player:RemoveEventById(eventId)

    local countBefore = player:GetItemCount(data.itemId)
    if player:IsMounted() then player:Dismount() end

    player:AddAura(68442, player)
    local aura = player:GetAura(68442)
    if aura then aura:SetDuration(2500) end

    player:RegisterEvent(function(eId, d, r, player)
        player:AddItem(data.itemId, 1)
        local countAfter = player:GetItemCount(data.itemId)

        if countAfter > countBefore then
            if data.data3 == 1 then
                local freshGO = player:GetNearestGameObject(20, data.goEntry)
                if freshGO then freshGO:Despawn() end
            end
        else
            local masterName = player:IsBot()
            local master = require("Multistate").FindPlayerByName(masterName)
            if master then
                local itemName = GetItemName(data.itemId)
                if not PlayerHasEnoughFreeSlots(player, 1) then
                    player:Whisper("My bags are full, so I can't loot " .. itemName .. "!", 0, master)
                else
                    player:Whisper("I'm having issues looting gameobject quest item " .. itemName .. " right now. Could you please help me?", 0, master)
                end
            end
        end
    end, 2500, 1)
end

local function ValidateAndApproachGO(player, data)
    if player:IsDead() or player:IsInCombat() then return end

    local go = player:GetNearestGameObject(20, data.goEntry)
    if not go then return end
    if not go:IsSpawned() or go:GetGoState() ~= 1 then return end

    if not CanLootItem(player, data) then
        WhisperBagsFull(player, data)
        return
    end

    local gx, gy, gz = go:GetLocation()
    local zdiff = math.abs(gz - player:GetZ())
    local los = player:IsWithinLoS(gx, gy, gz)

    if zdiff <= 5 and los then
        player:MoveTo(0, gx, gy, gz, true)

        player:RegisterEvent(function(eventId, delay, repeats, player)
            LootObject(eventId, delay, repeats, player, data)
        end, 250, 12)
    end
end

local function CheckForQuestGOs(eventId, delay, repeats, player)
    if not player:IsBot() then player:RemoveEventById(eventId) return end

    for questId, entries in pairs(questItemGoCache) do
        if player:HasQuest(questId) then
            for _, data in ipairs(entries) do
                if player:GetItemCount(data.itemId) < data.itemCount then
                    ValidateAndApproachGO(player, data)
                end
            end
        end
    end
end

local function OnMapChange(event, player)
    if not player then return end
    if not player:IsBot() then return end
    if player:GetData("BotQuestLoopActive") then return end
    player:SetData("BotQuestLoopActive", true)
    player:RegisterEvent(CheckForQuestGOs, {20000, 30000}, 0)
end

RegisterPlayerEvent(28, OnMapChange)

require("Multistate").ForEachPlayer(function(player)
    if player:GetData("BotQuestLoopActive") then return end
    player:SetData("BotQuestLoopActive", true)
    player:RegisterEvent(CheckForQuestGOs, {20000, 30000}, 0)
end)