local NPC_ID = 190090
local TOKEN_ITEM_ID = 20880
local MAX_MENU_ITEMS = 8
local model_ID = 27486
local freeReset = {}

local instanceData = {
    [249] = {name = "Onyxia's Lair", size = 25},
   -- [269] = {name = "Opening of the Dark Portal", size = 5},
    [309] = {name = "Zul'Gurub", size = 20},
    [409] = {name = "Molten Core", size = 40},
    [469] = {name = "Blackwing Lair", size = 40},
    [509] = {name = "Ruins of Ahn'Qiraj", size = 20},
    [531] = {name = "Ahn'Qiraj Temple", size = 40},
    [532] = {name = "Karazhan", size = 10},
    [533] = {name = "Naxxramas", size = 25},
    [534] = {name = "The Battle for Mount Hyjal", size = 25},
   -- [540] = {name = "Hellfire Citadel: The Shattered Halls", size = 5},
   -- [542] = {name = "Hellfire Citadel: The Blood Furnace", size = 5},
   -- [543] = {name = "Hellfire Citadel: Ramparts", size = 5},
    [544] = {name = "Magtheridon's Lair", size = 25},
   -- [545] = {name = "Coilfang: The Steamvault", size = 5},
   -- [546] = {name = "Coilfang: The Underbog", size = 5},
   -- [547] = {name = "Coilfang: The Slave Pens", size = 5},
    [548] = {name = "Coilfang: Serpentshrine Cavern", size = 25},
    [550] = {name = "Tempest Keep", size = 25},
   -- [552] = {name = "Tempest Keep: The Arcatraz", size = 5},
   -- [553] = {name = "Tempest Keep: The Botanica", size = 5},
   -- [554] = {name = "Tempest Keep: The Mechanar", size = 5},
   -- [555] = {name = "Auchindoun: Shadow Labyrinth", size = 5},
   -- [556] = {name = "Auchindoun: Sethekk Halls", size = 5},
  --  [557] = {name = "Auchindoun: Mana-Tombs", size = 5},
  --  [558] = {name = "Auchindoun: Auchenai Crypts", size = 5},
   -- [560] = {name = "The Escape From Durnholde", size = 5},
    [564] = {name = "Black Temple", size = 25},
    [565] = {name = "Gruul's Lair", size = 25},
    [568] = {name = "Zul'Aman", size = 10},
  --  [574] = {name = "Utgarde Keep", size = 5},
  --  [575] = {name = "Utgarde Pinnacle", size = 5},
  --  [576] = {name = "The Nexus", size = 5},
  --  [578] = {name = "The Oculus", size = 5},
    [580] = {name = "The Sunwell", size = 25},
  --  [585] = {name = "Magister's Terrace", size = 5},
  --  [595] = {name = "The Culling of Stratholme", size = 5},
  --  [599] = {name = "Halls of Stone", size = 5},
  --  [600] = {name = "Drak'Tharon Keep", size = 5},
  --  [601] = {name = "Azjol-Nerub", size = 5},
  --  [602] = {name = "Halls of Lightning", size = 5},
    [603] = {name = "Ulduar", size = 25},
  --  [604] = {name = "Gundrak", size = 5},
  --  [608] = {name = "Violet Hold", size = 5},
    [615] = {name = "The Obsidian Sanctum", size = 25},
    [616] = {name = "The Eye of Eternity", size = 25},
    [624] = {name = "Vault of Archavon", size = 25},
    [631] = {name = "Icecrown Citadel", size = 25},
  --  [632] = {name = "The Forge of Souls", size = 5},
  --  [649] = {name = "Trial of the Crusader", size = 5},
    [650] = {name = "Trial of the Champion", size = 25},
  --  [658] = {name = "Pit of Saron", size = 5},
  --  [668] = {name = "Halls of Reflection", size = 5},
    [724] = {name = "The Ruby Sanctum", size = 25}
}

local function GetSavedInstanceLockouts(player)
    local guid = player:GetGUIDLow()
    local query = CharDBQuery("SELECT instance FROM character_instance WHERE guid = " .. guid)
    if query then
        local instances = {}
        repeat
            local instanceId = query:GetUInt32(0)
            table.insert(instances, instanceId)
        until not query:NextRow()
        return instances
    end
    return nil
end

local function GetInstanceDetails(instanceId)
    local query = CharDBQuery("SELECT map, difficulty FROM instance WHERE id = " .. instanceId)
    if query then
        local map = query:GetUInt32(0)
        local difficulty = query:GetUInt32(1)
        return map, difficulty
    end
    return nil, nil
end

local function GetTokenCost(difficulty)
    if difficulty == 0 then return 50
    elseif difficulty == 1 then return 100
    elseif difficulty == 2 then return 200
    elseif difficulty == 3 then return 400
    else return 0
    end
end

local function ChargeTokens(player, difficulty)
    local guid = player:GetGUIDLow()
    local tokenCost = GetTokenCost(difficulty)
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

local function ResetInstanceLockout(player, map, difficulty)
    if ChargeTokens(player, difficulty) then
        local guid = player:GetGUIDLow()
        if (not freeReset[guid] or (freeReset[guid] < os.time())) then 
            freeReset[guid] = os.time() + 7 * 24 * 60 * 60
            CharDBExecute("REPLACE INTO character_instance_vendor_reset (guid, time) VALUES (" .. guid .. ", " .. freeReset[guid] .. ");")
        end
        player:UnbindInstance(map, difficulty)
        local instanceName = instanceData[map] and instanceData[map].name
        local difficultyName = GetDifficultyName(difficulty, instanceData[map] and instanceData[map].size or 0)
        if instanceName then
            player:SendBroadcastMessage("Your instance lockout for " .. instanceName .. " (" .. difficultyName .. ") has been reset.")
        else
            player:SendBroadcastMessage("Your chosen instance lockout has been reset.")
        end
    end
end

local function SortInstancesByMapID(instances)
    if not instances or #instances == 0 then
        return {}  -- Return an empty table if instances are empty or nil
    end

    local sortedInstances = {}
    for _, instanceId in ipairs(instances) do
        local map, difficulty = GetInstanceDetails(instanceId)
        if map and difficulty and instanceData[map] then
            table.insert(sortedInstances, {
                instanceId = instanceId,
                map = map,
                difficulty = difficulty
            })
        end
    end
    table.sort(sortedInstances, function(a, b) return a.map > b.map end)
    return sortedInstances
end
local function GenerateMenu(page, player, creature)
    local guid = player:GetGUIDLow()
    player:GossipClearMenu()
    
    local instances = GetSavedInstanceLockouts(player)

    local sortedInstances = SortInstancesByMapID(instances)

    local startIndex = (page - 1) * MAX_MENU_ITEMS + 1
    local endIndex = math.min(page * MAX_MENU_ITEMS, #sortedInstances)

    local hasValidOptions = false

    for i = startIndex, endIndex do
        local instance = sortedInstances[i]
        local map, difficulty = instance.map, instance.difficulty
        
        -- Check if the map is supported by instanceData
        if instanceData[map] then
            local instanceName = instanceData[map].name
            local difficultyName = GetDifficultyName(difficulty, instanceData[map].size)
            local tokenCost = GetTokenCost(difficulty)
            
            if (not freeReset[guid] or (freeReset[guid] < os.time())) then tokenCost = 0 end
            
            local gossipText = "Reset " .. instanceName .. " " .. difficultyName .. "                 (Cost: " .. tokenCost .. " Vote Tokens)"
            player:GossipMenuAddItem(2, gossipText, 0, map * 10 + difficulty, false, "Are you sure you want to reset " .. instanceName .. " " .. difficultyName .. " for " .. tokenCost .. " vote tokens?")
            
            hasValidOptions = true
        end
    end

    if not hasValidOptions then
        player:SendBroadcastMessage("You don't have any raid locks to reset.")
        player:GossipComplete()
        return
    end

    -- Add navigation buttons
    if page > 1 then
        player:GossipMenuAddItem(4, "Previous page", 0, 1000 + page - 1)
    end
    if endIndex < #sortedInstances then
        player:GossipMenuAddItem(4, "Next page", 0, 1000 + page + 1)
    end

    player:GossipMenuAddItem(0, "Nevermind", 0, 9999) -- Option to cancel
    player:GossipSendMenu(1, creature)
end

local function OnGossipHello(event, player, creature)
    local guid = player:GetGUIDLow()
    if not freeReset[guid] then
        local result = CharDBQuery("SELECT time FROM character_instance_vendor_reset WHERE guid = " .. guid)
        if result then
            freeReset[guid] = result:GetUInt32(0)
        else
            freeReset[guid] = 0
        end
    end
    player:GossipClearMenu()
    GenerateMenu(1, player, creature)
end

local function OnGossipSelect(event, player, creature, sender, intid, code, menu_id)
    if intid >= 1000 and intid <= 1050 then
        -- Navigation option selected
        local newPage = intid - 1000
        GenerateMenu(newPage, player, creature)
        return
    else
        local map = math.floor(intid / 10)
        local difficulty = intid % 10
        if map ~= 999 and difficulty >= 0 and difficulty <= 5 then
            ResetInstanceLockout(player, map, difficulty)
        end
    end
    player:GossipComplete()
end

RegisterCreatureGossipEvent(NPC_ID, 1, OnGossipHello)
RegisterCreatureGossipEvent(NPC_ID, 2, OnGossipSelect)
CharDBExecute("CREATE TABLE IF NOT EXISTS character_instance_vendor_reset (guid INT NOT NULL, time INT NOT NULL, PRIMARY KEY (guid));")