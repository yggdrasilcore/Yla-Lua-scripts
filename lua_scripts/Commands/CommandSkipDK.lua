----------------------------------------------
---------------- Constants -------------------

local TELE_TO_GM_MODE   = 1
local ITEM_HEARTHSTONE  = 6948

-- Class
local CLASS_DEATHKNIGHT = 6

-- Races
local RACE_HUMAN        = 1
local RACE_ORC          = 2
local RACE_DWARF        = 3
local RACE_NIGHT_ELF    = 4
local RACE_UNDEAD       = 5
local RACE_TAUREN       = 6
local RACE_GNOME        = 7
local RACE_TROLL        = 8
local RACE_BLOOD_ELF    = 10
local RACE_DRAENEI      = 11

----------------------------------------------
------------------ Config --------------------

-- Shared quests for all races
local SHARED_QUESTS = {
    12800,12801,12738,12679,12680,12619,12751,12754,12755,12756,
    12757,12697,12698,12700,12701,12641,12706,12778,12714,12715,
    12779,13165,13166,12719,12720,12593,12722,12723,12724,12725,
    12657,12727,12842,12687,12636,12850,12848,12733,12670,12678,
}

-- Race-specific quests
local RACE_QUESTS = {
    [RACE_HUMAN]     = {12742,13188},
    [RACE_ORC]       = {12748,13189},
    [RACE_DWARF]     = {12744,13188},
    [RACE_NIGHT_ELF] = {12743,13188},
    [RACE_UNDEAD]    = {12750,13189},
    [RACE_TAUREN]    = {12739,13189},
    [RACE_GNOME]     = {12745,13188},
    [RACE_TROLL]     = {12749,13189},
    [RACE_BLOOD_ELF] = {12747,13189},
    [RACE_DRAENEI]   = {12746,13188},
}

----------------------------------------------
------------------- Code ---------------------
-- Multistate: PLAYER_EVENT_ON_CHAT (18) fires in the global state, but the
-- skip sequence mutates the player on its map, so it is forwarded via EMQ.
local MS = require("Multistate")
local EMQ = require("EMQ")

-- Map-state executor (via EMQ, or directly in compatibility mode).
local function DoSkipDK(player)
    if not player then
        return
    end
    -- Add Hearthstone
    player:AddItem(ITEM_HEARTHSTONE)

    -- Complete quests
    AutoCompleteQuests(player, SHARED_QUESTS)
    AutoCompleteQuests(player, RACE_QUESTS[player:GetRace()])

    --Set correct level
    if player:GetLevel() < 58 then
        player:SetLevel(58)
    end

    -- Teleport to Dalaran
    player:Teleport(571, 5849.55, 637, 647.52, 2.38338, TELE_TO_GM_MODE)

    player:SendBroadcastMessage("You have skipped the Death Knight starter zone and been teleported to Dalaran.")
end

EMQ.RegisterQueue("CmdSkipDK", function(player, data) DoSkipDK(player) end)

if GetStateMapId() ~= -1 then return end

local function AutoCompleteQuests(player, quests)
    if not player or not quests then
        return
    end
    for _, questId in pairs(quests) do
        player:AddQuest(questId)
        player:CompleteQuest(questId)
        player:RewardQuest(questId)
    end
end

local function DeathKnightSkipStarterZone(event, player, message, Type, lang)
    if message:lower() == "#ti3j5kfo0s" or message:lower() == "#skipdk" then

        if player:GetClass() ~= CLASS_DEATHKNIGHT then
            player:SendBroadcastMessage("This command is only available for Death Knights.")
            return
        end

        if MS.IsCompat() then
            DoSkipDK(player)
        else
            player:SendEMQMessage("CmdSkipDK", {})
        end

        return false
    end
end

RegisterPlayerEvent(18, DeathKnightSkipStarterZone) -- PLAYER_EVENT_ON_CHAT
