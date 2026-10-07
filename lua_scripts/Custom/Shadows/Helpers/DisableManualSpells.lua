local MANUAL_SPELLS = {
-- Dispells
370,475,527,528,552,988,1152,2782,2893,3137,4526,4975,4977,4978,4983,4987,6528,8012,8170,8171,8172,8946,8947,10872,14129,14134,14253,15090,15729,16072,16908,17012,17201,18461,19476,19658,19801,20426,20427,20428,21076,23258,23859,24022,25756,26677,27495,27496,27609,27626,27847,28133,28787,28788,29200,29380,30281,30415,30416,30449,31825,31826,32375,32400,32592,32633,33625,36461,38082,38306,39078,39302,39897,43241,43577,43813,45149,47795,48205,48367,48706,49087,50068,50146,51886,52025,55598,55625,55677,55691,56131,56163,56170,56364,56536,56601,56988,57183,57190,57767,61255,62416,62422,63499,65546,66056,66057,66116,67518,68621,68622,68623,68624,68625,68626,68627,68628,68629,70477,70548,71693,71694,72734,
56222, 355, 26281, 28140, 29060, 230525, 37017, 37486, 37548, 49613, 51774, 51775, 52154, 53477, 53798, 53799, 54794, 70428,


-- Hand of Reckoning
62124,
67485,

-- Righteous Defense
31789,
31790,

-- Growl
1853,
2649,
6795,
14916,
14917,
14918,
14919,
14920,
14921,
14922,
14923,
14924,
14925,
14926,
14927,
27047,
27344,
31334,
39270,
58855,
61676,

-- Mocking Blow
694,
7400,
7402,
20559,
20560,
21008,
25266,
47504,

-- Challenging Shout
1161,

-- Death Grip
49560,
49575,
49576,
51399,
53276,
55719,
57602,
57603,
57604,
61094,
64429,
64430,
64431,
66017,
68753,
68754,
68755,
70564,

-- Challenging Roar
5209,

-- Blink
1953,
6139,
14514,
21655,
28391,
28401,
29208,
29209,
29210,
29211,
29883,
29884,
29966,
29967,
29968,
31439,
31465,
32937,
33546,
33548,
33549,
33550,
34165,
34605,
34844,
36097,
36109,
36718,
36994,
38194,
38203,
38642,
38643,
38932,
38981,
45862,
46571,
46573,
50648,
57869,
62578,
64662,
65793,
69904,

-- Disengage
781,
56446,
57635,
57636,
60932,
60934,
61507,
61508,
65869,
65870,
68339,
68340,

-- Killing Spree
51690,

-- Shadowstep
36554,

}

local RemovedPlayerSpells = {}

function DisableManualSpells(player)
    if not player then return end
    
    if not player:IsBot() then return end
    
    if player:GetData("RemovedManualSpells") then return end
    
    local guidLow = player:GetGUIDLow()
    local playerName = player:GetName():gsub("'", "''")
    
    local playerSpellsToRemove = {}
    table.sort(MANUAL_SPELLS)
    
    for _, spellId in ipairs(MANUAL_SPELLS) do
        if player:HasSpell(spellId) then
            table.insert(playerSpellsToRemove, spellId)
        end
    end
    
    if #playerSpellsToRemove > 0 then
        PrintInfo("[DisableManualSpells] Removing " .. #playerSpellsToRemove .. " spells from " .. playerName)
        local values = {}
        for _, spellId in ipairs(playerSpellsToRemove) do
            table.insert(values, string.format("(%d, %d)", guidLow, spellId))
            player:RemoveSpell(spellId)
        end
        player:SaveToDB()
        
        CharDBExecute("REPLACE INTO acore_eluna.disable_shadows_spells (guid, spell_id) VALUES " .. table.concat(values, ", "))
        RemovedPlayerSpells[guidLow] = playerSpellsToRemove
        player:SetData("RemovedManualSpells", true)
        PrintInfo("[DisableManualSpells] Cached and saved " .. #playerSpellsToRemove .. " spells for " .. playerName)
    end
end

local function OnMapChange(event, player)
    if not player then return end
    
    if not player:IsBot() then return end
    
    player:SetData("RemovedManualSpells", false)
    
    local guidLow = player:GetGUIDLow()
    local cachedSpells = RemovedPlayerSpells[guidLow]
    
    if cachedSpells then
        PrintInfo("[OnMapChange] Re-learning " .. #cachedSpells .. " spells from cache for " .. player:GetName())
        for _, spellId in ipairs(cachedSpells) do
            if not player:HasSpell(spellId) then
                player:LearnSpell(spellId)
            end
        end
    else
        PrintInfo("[OnMapChange] No cache found, querying DB for " .. player:GetName())
        local guid = player:GetGUID()
        CharDBQueryAsync(
            string.format("SELECT spell_id FROM acore_eluna.disable_shadows_spells WHERE guid = %d", guidLow),
            function(query)
                local player = require("Multistate").FindPlayerByGUID(guid)
                if not player then return end
                
                if query then
                    local spellsToLearn = {}
                    repeat
                        local spellId = query:GetUInt32(0)
                        table.insert(spellsToLearn, spellId)
                    until not query:NextRow()
                    
                    RemovedPlayerSpells[guidLow] = spellsToLearn
                    PrintInfo("[OnMapChange] Found " .. #spellsToLearn .. " spells in DB for " .. player:GetName())
                    
                    for _, spellId in ipairs(spellsToLearn) do
                        if not player:HasSpell(spellId) then
                            player:LearnSpell(spellId)
                        end
                    end
                    player:SaveToDB()
                end
            end
        )
    end
end

local function OnLeaveCombat(event, player)
    if not player then return end
    
    if not player:IsBot() then return end
    
    local guidLow = player:GetGUIDLow()
    local cachedSpells = RemovedPlayerSpells[guidLow]
    
    if cachedSpells then
        PrintInfo("[OnLeaveCombat] Re-learning " .. #cachedSpells .. " spells from cache for " .. player:GetName())
        for _, spellId in ipairs(cachedSpells) do
            if not player:HasSpell(spellId) then
                player:LearnSpell(spellId)
            end
        end
        player:SaveToDB()
        player:SetData("RemovedManualSpells", false)
    end
end

local function OnSave(event, player)
    if not player then return end
    
    if not player:IsBot() then return end
    
    local guidLow = player:GetGUIDLow()
    local guid = player:GetGUID()
    
    CharDBQueryAsync(
        string.format("SELECT spell_id FROM acore_eluna.disable_shadows_spells WHERE guid = %d", guidLow),
        function(query)
            local player = require("Multistate").FindPlayerByGUID(guid)
            if not player then return end
            
            if query then
                local allKnown = true
                local spellCount = 0
                repeat
                    spellCount = spellCount + 1
                    local spellId = query:GetUInt32(0)
                    if not player:HasSpell(spellId) then
                        allKnown = false
                        PrintInfo("[OnSave] Player " .. player:GetName() .. " missing spell " .. spellId)
                        break
                    end
                until not query:NextRow()
                
                if allKnown then
                    PrintInfo("[OnSave] All " .. spellCount .. " spells verified, clearing DB for " .. player:GetName())
                    CharDBExecute(string.format(
                        "DELETE FROM acore_eluna.disable_shadows_spells WHERE guid = %d",
                        guidLow
                    ))
                    RemovedPlayerSpells[guidLow] = nil
                else
                    PrintInfo("[OnSave] Not all spells verified, keeping DB entries for " .. player:GetName())
                end
            end
        end
    )
end

RegisterPlayerEvent(28, OnMapChange)
RegisterPlayerEvent(34, OnLeaveCombat)
RegisterPlayerEvent(25, OnSave)
CharDBExecute("CREATE TABLE IF NOT EXISTS acore_eluna.disable_shadows_spells (`guid` INT UNSIGNED NOT NULL, `spell_id` INT UNSIGNED NOT NULL, PRIMARY KEY (`guid`, `spell_id`))")

-- Multistate: the disablespells command fires globally but spell removal must
-- run on the target's map state.
local Multistate = require("Multistate")
local EMQ = require("EMQ")

EMQ.RegisterQueue("DisableSpellsCmd", function(player, data)
    if not player or not data then
        return
    end
    local target = nil
    local sel = player:GetSelection()
    if sel and data.targetGuidLow and sel:GetGUIDLow() == data.targetGuidLow then
        target = sel:ToPlayer()
    elseif data.targetName then
        target = Multistate.FindPlayerByName(data.targetName)
    end
    if target then
        DisableManualSpells(target)
        player:SendBroadcastMessage("DisableManualSpells executed on " .. target:GetName())
    else
        player:SendBroadcastMessage("DisableManualSpells target not found on this map.")
    end
end)

-- (Queue registered above in every state; the command below only fires globally.)
local function OnDisableSpellsCommand(event, player, command)
    if command == "disablespells" and player:GetGMRank() > 0 then
		
        local target = player:GetSelection()
        
        if not target then
            player:SendBroadcastMessage("No target selected")
            return false
        end
        
        if target:ToPlayer() == nil then
            player:SendBroadcastMessage("Target must be a player")
            return false
        end
        
        local targetPlayer = target:ToPlayer()

        local data = { targetGuidLow = target:GetGUIDLow(), targetName = targetPlayer:GetName() }
        if Multistate.IsCompat() then
            DisableManualSpells(targetPlayer)
            player:SendBroadcastMessage("DisableManualSpells executed on " .. targetPlayer:GetName())
        else
            player:SendEMQMessage("DisableSpellsCmd", data)
        end

        return false
    end
end

if GetStateMapId() == -1 then
    RegisterPlayerEvent(42, OnDisableSpellsCommand)
end