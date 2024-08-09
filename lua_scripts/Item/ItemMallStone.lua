local ITEM_ID = 37430
local COOLDOWN = 3600 -- 1 hour cooldown in seconds
local MAP_ID = 573
local X = 250.504822
local Y = 504.449799
local Z = 24.741276
local ORIENTATION = 5.461457

local function CreateCooldownTable()
    CharDBExecute([[
        CREATE TABLE IF NOT EXISTS `character_cooldowns` (
            `guid` INT UNSIGNED NOT NULL,
            `item_id` INT UNSIGNED NOT NULL,
            `cooldown_end` INT UNSIGNED NOT NULL,
            PRIMARY KEY (`guid`, `item_id`)
        )
    ]])
end

local function LoadCooldown(player)
    local guid = player:GetGUIDLow()
    local query = CharDBQuery("SELECT cooldown_end FROM character_cooldowns WHERE guid = " .. guid .. " AND item_id = " .. ITEM_ID)
    if query then
        return query:GetUInt32(0)
    end
    return 0
end

local function SaveCooldown(player, cooldownEnd)
    local guid = player:GetGUIDLow()
    CharDBExecute("REPLACE INTO character_cooldowns (guid, item_id, cooldown_end) VALUES (" .. guid .. ", " .. ITEM_ID .. ", " .. cooldownEnd .. ")")
end

function OnUse(event, player, item, target)
    if player:IsInCombat() then
        player:SendAreaTriggerMessage("You cannot use this item in combat.")
        return false
    end

    if player:GetBattlegroundId() ~= 0 then
        player:SendAreaTriggerMessage("You cannot use this item in a battleground.")
        return false
    end

    local currentTime = os.time()
    local cooldownEnd = LoadCooldown(player)
    local remainingCooldown = cooldownEnd - currentTime

    if remainingCooldown > 0 then
        local hours = math.floor(remainingCooldown / 3600)
        local minutes = math.floor((remainingCooldown % 3600) / 60)
        local seconds = math.floor(remainingCooldown % 60)
        player:SendAreaTriggerMessage("This item is on cooldown for " .. hours .. " hours, " .. minutes .. " minutes, and " .. seconds .. " seconds.")
        return false
    end

    cooldownEnd = currentTime + COOLDOWN
    SaveCooldown(player, cooldownEnd) -- Save the new cooldown end time to the database
    player:Teleport(MAP_ID, X, Y, Z, ORIENTATION)
    return true
end

function OnLogin(event, player)
    -- Load the cooldown when the player logs in
    LoadCooldown(player)
end

function OnItemCast(event, player, item, spell)
    if item:GetEntry() == ITEM_ID then
        player:CastSpell(player, 5553, true) -- Cast a generic casting delay spell with a 1-second delay. Replace 5553 with the correct spell ID if necessary.
    end
end

CreateCooldownTable() -- Ensure the cooldown table exists before doing anything else

RegisterItemEvent(ITEM_ID, 2, OnUse)
RegisterPlayerEvent(3, OnLogin) -- 3 is the event ID for player login
RegisterPlayerEvent(5, OnItemCast) -- 5 is the event ID for spell cast start

print("[Item]: Mall Stone Teleport Stone loaded!")
