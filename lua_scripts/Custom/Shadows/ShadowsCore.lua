
-- Shadows Configs Start

maxBotCount = 4
maxVIPCount = 9
minShadowsLevel = 15 -- Global var also referenced by Twiggy

local BOT_TELE_VISUAL   = 64446
local BotSummonCD       = 10 * 60 -- 10 minutes

isPlayerBot		        =   {} -- Global table referenced in VIP script as well
activeBots       		=   {}
local addCmdTimer       =   {}
local logoutEvent       =   {}
-- Last world payload per player. Map renders from here, never touches DB.
local mapViewCache      =   {}
local mapReqSeq         =   {} -- last request seq per player name
local mapAckSeq         =   {} -- last rendered view seq per player name
local VIEW_TIMEOUT_MS   =   6000
local mapPendingAction  =   {} -- deferred click action per player, run on next view

local botTeleTime       =   {}
local botMasters        =   {}
local botSummonTime     =   {}
local dontKickTime	    =   {}
local removalInProgress =   {}
local lastTeleTime      =   {}
local disallowedZones   =   {4298}--, 4197, 3628, 3666} -- Scarlet Enclave (DK start area), Wintergrasp, Halaa

-- Shadows Configs End

-- Multistate support (mod-ale multistate-shoehorn): the global state runs login,
-- logout, command, chat, group and packet handlers, while map states run gossip,
-- map-enter, zone-change and save handlers. Per-state Lua tables are therefore
-- NOT shared. Cross-state coordination uses:
--   * the `shadows_bots` CharDB table as the canonical bot -> master mapping
--     (synchronous reads work in every state),
--   * shared player Data() (see Multistate.lua) for per-player counters/flags,
--   * EMQ for shipping player commands from the global state to map states.
-- The accessor functions below are global so every Shadows script (and VIP,
-- TokensLogin, etc.) can use them in any state. Never access isPlayerBot /
-- activeBots Lua tables across files anymore; they are gone.
local Multistate = require("Multistate")
local EMQ = require("EMQ")

CharDBExecute("CREATE TABLE IF NOT EXISTS acore_eluna.shadows_bots (bot_name VARCHAR(12) NOT NULL PRIMARY KEY, master_name VARCHAR(12) NOT NULL)")

-- Returns the master name for a bot name, or nil. Works in every state.
function ShadowGetMaster(botName)
    if not botName then
        return nil
    end
    local query = CharDBQuery("SELECT master_name FROM acore_eluna.shadows_bots WHERE bot_name = '" .. botName .. "'")
    if query then
        return query:GetString(0)
    end
    return nil
end

-- Sets (or clears with nil) the bot -> master mapping. Visible in every state.
function ShadowSetMaster(botName, masterName)
    if not botName then
        return
    end
    if masterName then
        CharDBExecute("REPLACE INTO acore_eluna.shadows_bots (bot_name, master_name) VALUES ('" .. botName .. "', '" .. masterName .. "')")
    else
        CharDBExecute("DELETE FROM acore_eluna.shadows_bots WHERE bot_name = '" .. botName .. "'")
    end
end

-- Returns the list of bot names owned by a master. Works in every state.
function ShadowGetBots(masterName)
    local bots = {}
    if not masterName then
        return bots
    end
    local query = CharDBQuery("SELECT bot_name FROM acore_eluna.shadows_bots WHERE master_name = '" .. masterName .. "' ORDER BY bot_name")
    if query then
        repeat
            table.insert(bots, query:GetString(0))
        until not query:NextRow()
    end
    return bots
end

-- Returns the whole mapping as { [masterName] = { botNames } }. Works in every state.
function ShadowGetAllBots()
    local all = {}
    local query = CharDBQuery("SELECT bot_name, master_name FROM acore_eluna.shadows_bots")
    if query then
        repeat
            local botName = query:GetString(0)
            local masterName = query:GetString(1)
            if not all[masterName] then
                all[masterName] = {}
            end
            table.insert(all[masterName], botName)
        until not query:NextRow()
    end
    return all
end

-- Per-player shadows counters/flags in shared Data() (visible in every state).
function ShadowGetBotCount(player)
    return Multistate.GetData(player, "ShadowsBotCount") or 0
end

function ShadowSetBotCount(player, count)
    count = count or 0
    if count < 0 then
        count = 0
    end
    Multistate.SetData(player, "ShadowsBotCount", count)
end

function ShadowAddBotCount(player, delta)
    ShadowSetBotCount(player, ShadowGetBotCount(player) + (delta or 0))
end

function ShadowGetLoginTime(player)
    return Multistate.GetData(player, "ShadowsLoginTime")
end

function ShadowSetLoginTime(player, t)
    Multistate.SetData(player, "ShadowsLoginTime", t)
end

-- Shadow bar flag (written on login/global, read in gossip/map and AIO/global).
function ShadowGetBarData(player)
    return Multistate.GetData(player, "ShadowsBarData")
end

function ShadowSetBarData(player, value)
    Multistate.SetData(player, "ShadowsBarData", value)
end

-- Summon-protection timestamps, stored per master in shared Data().
function ShadowSetDontKick(masterPlayer, botName, time)
    if not masterPlayer or not botName then
        return
    end
    local t = Multistate.GetData(masterPlayer, "ShadowsDontKick") or {}
    t[botName] = time
    Multistate.SetData(masterPlayer, "ShadowsDontKick", t)
end

function ShadowDontKickActive(botPlayer)
    if not botPlayer then
        return false
    end
    local botName = botPlayer:GetName()
    local masterName = ShadowGetMaster(botName)
    if not masterName then
        return false
    end
    local master = Multistate.FindPlayerByName(masterName)
    if not master then
        return false
    end
    local t = Multistate.GetData(master, "ShadowsDontKick") or {}
    return t[botName] and t[botName] > os.time()
end

-- Bot summon throttle (written in gossip/map, read in command/global).
function ShadowGetBotSummonTime(player)
    return Multistate.GetData(player, "ShadowsBotSummonTime") or 0
end

function ShadowSetBotSummonTime(player, t)
    Multistate.SetData(player, "ShadowsBotSummonTime", t)
end

-- Follow-teleport throttle (Teleport() runs in both global packet handlers and
-- map enter handlers).
function ShadowGetLastTeleTime(player)
    return Multistate.GetData(player, "ShadowsLastTele") or 0
end

function ShadowSetLastTeleTime(player, t)
    Multistate.SetData(player, "ShadowsLastTele", t)
end

-- Handlers defined below, assigned here so registration order is load-safe.
local HandleWorldOp   -- (player, data): runs in world, owns DB + RunCommand
local HandleMapView   -- (player, data): runs on map, pure render from payload
EMQ.RegisterQueue("ShadowsToWorld", function(player, data)
    if HandleWorldOp and (GetStateMapId() == -1) then
        HandleWorldOp(player, data)
    end
end)
EMQ.RegisterQueue("ShadowsToMap", function(player, data)
    if HandleMapView and (GetStateMapId() ~= -1) then
        HandleMapView(player, data)
    end
end)

-- Shadows Script Start

function GetClassName(classId)
    local classNames = {
        [1] = "Warrior",
        [2] = "Paladin",
        [3] = "Hunter",
        [4] = "Rogue",
        [5] = "Priest",
        [6] = "Death Knight",
        [7] = "Shaman",
        [8] = "Mage",
        [9] = "Warlock",
        [11] = "Druid"
    }
    return classNames[classId] or "Unknown"
end

function GetRaceName(raceId)
    local raceNames = {
        [1] = "Human",
        [2] = "Orc",
        [3] = "Dwarf",
        [4] = "Night Elf",
        [5] = "Undead",
        [6] = "Tauren",
        [7] = "Gnome",
        [8] = "Troll",
        [10] = "Blood Elf",
        [11] = "Draenei"
    }
    return raceNames[raceId] or "Unknown"
end

function GetClassIconPath(classId)
    local classIcons = {
        [1] = "Ability_Warrior_SavageBlow",      -- Warrior
        [2] = "Spell_Holy_HolyBolt",             -- Paladin
        [3] = "INV_Weapon_Bow_07",               -- Hunter
        [4] = "Ability_Stealth",                 -- Rogue
        [5] = "Spell_Holy_PowerWordShield",      -- Priest
        [6] = "Spell_Deathknight_ClassIcon",     -- Death Knight
        [7] = "Spell_Nature_BloodLust",          -- Shaman
        [8] = "Spell_Holy_MagicalSentry",        -- Mage
        [9] = "Spell_Shadow_CurseOfTounges",     -- Warlock
        [11] = "Spell_Nature_Regeneration"       -- Druid
    }
    return classIcons[classId] or "INV_Misc_QuestionMark"
end

function GetRaceIconPath(raceId, gender)
    local raceIcons = {
        [1] = {
            [0] = "achievement_character_human_male",
            [1] = "achievement_character_human_female"
        },
        [2] = {
            [0] = "achievement_character_orc_male",
            [1] = "achievement_character_orc_female"
        },
        [3] = {
            [0] = "achievement_character_dwarf_male",
            [1] = "inv_misc_head_dwarf_02"
        },
        [4] = {
            [0] = "achievement_character_nightelf_male",
            [1] = "achievement_character_nightelf_female"
        },
        [5] = {
            [0] = "inv_misc_head_undead_01",
            [1] = "inv_misc_head_undead_02"
        },
        [6] = {
            [0] = "achievement_character_tauren_male",
            [1] = "achievement_character_tauren_female"
        },
        [7] = {
            [0] = "inv_misc_head_gnome_01",
            [1] = "inv_misc_head_gnome_02"
        },
        [8] = {
            [0] = "achievement_character_troll_male",
            [1] = "achievement_character_troll_female"
        },
        [10] = {
            [0] = "achievement_character_bloodelf_male",
            [1] = "achievement_character_bloodelf_female"
        },
        [11] = {
            [0] = "achievement_character_draenei_male",
            [1] = "achievement_character_draenei_female"
        }
    }
    
    if raceIcons[raceId] and raceIcons[raceId][gender] then
        return raceIcons[raceId][gender]
    end
    return "INV_Misc_QuestionMark"
end

local commandCategories = {
   movement = {
       name = "Movement",
       intid = 20,
       commands = {
           {cmd = "follow", name = "Follow", desc = "Your shadows will follow the player. Say 'follow' in group chat or whisper to instruct shadow."},
           {cmd = "flee", name = "Flee", desc = "Your shadows will try to move away from their target while in combat. Say 'flee' in group chat or whisper to instruct shadow."},
           {cmd = "runaway", name = "Run Away", desc = "Your shadows will try to kite their currently aggroed mobs by whispering or saying 'runaway' in group chat."},
           {cmd = "@tank flee", name = "Tank Flee", desc = "Your shadows will command the tank to flee from combat. Say '@tank flee' in group chat or whisper to instruct shadow."},
           {cmd = "@dps flee", name = "DPS Flee", desc = "Your shadows will command the DPS to flee from combat. Say '@dps flee' in group chat or whisper to instruct shadow."},
           {cmd = "@heal flee", name = "Healer Flee", desc = "Your shadows will command the healer to flee from combat. Say '@heal flee' in group chat or whisper to instruct shadow."},
           {cmd = "@melee flee", name = "Melee Flee", desc = "Your shadows will command melee players to flee from combat. Say '@melee flee' in group chat or whisper to instruct shadow."},
           {cmd = "@ranged flee", name = "Ranged Flee", desc = "Your shadows will command ranged players to flee from combat. Say '@ranged flee' in group chat or whisper to instruct shadow."},
           {cmd = "stay", name = "Stay", desc = "Your shadows will stay in its current position. Say 'stay' in group chat or whisper to instruct shadow."},
           {cmd = "reset botAI", name = "Reset botAI", desc = "Say 'reset botAI' (case sensitive) in group chat or whispers to a shadow to reset its current settings."},
       }
   },
   combat = {
       name = "Combat",
       intid = 21,
       commands = {
           {cmd = "attack", name = "Attack", desc = "Your shadows will engage and attack the target. Say 'attack' in group chat or whisper to instruct shadow."},
           {cmd = "@tank attack", name = "Tank Attack", desc = "Your shadows will command the tank to attack the target. Say '@tank attack' in group chat or whisper to instruct shadow."},
           {cmd = "@dps attack", name = "DPS Attack", desc = "Your shadows will command the DPS to attack the target. Say '@dps attack' in group chat or whisper to instruct shadow."},
           {cmd = "@heal attack", name = "Healer Attack", desc = "Your shadows will command the healer to attack the target. Say '@heal attack' in group chat or whisper to instruct shadow."},
           {cmd = "@melee attack", name = "Melee Attack", desc = "Your shadows will command melee players to attack the target. Say '@melee attack' in group chat or whisper to instruct shadow."},
           {cmd = "@ranged attack", name = "Ranged Attack", desc = "Your shadows will command ranged players to attack the target. Say '@ranged attack' in group chat or whisper to instruct shadow."},
           {cmd = "grind", name = "Grind", desc = "Make all shadows automatically attack nearby creatures that yield experience points. Say 'grind' in group chat to activate grind mode."},
           {cmd = "reset botAI", name = "Reset botAI", desc = "Say 'reset botAI' (case sensitive) in group chat or whispers to a shadow to reset its current settings."},
       }
   },
   formation = {
       name = "Formation",
       intid = 22,
       commands = {
           {cmd = "formation arrow", name = "Arrow Formation", desc = "Your shadows will arrange itself in an arrow formation. Say 'formation arrow' in group chat or whisper to instruct shadow."},
           {cmd = "formation queue", name = "Queue Formation", desc = "Your shadows will arrange itself in a queue formation. Say 'formation queue' in group chat or whisper to instruct shadow."},
           {cmd = "formation near", name = "Near Formation", desc = "Your shadows will arrange itself in a close formation. Say 'formation near' in group chat or whisper to instruct shadow."},
           {cmd = "formation melee", name = "Melee Formation", desc = "Your shadows will arrange itself in a melee formation. Say 'formation melee' in group chat or whisper to instruct shadow."},
           {cmd = "formation line", name = "Line Formation", desc = "Your shadows will arrange itself in a line formation. Say 'formation line' in group chat or whisper to instruct shadow."},
           {cmd = "formation circle", name = "Circle Formation", desc = "Your shadows will arrange itself in a circular formation. Say 'formation circle' in group chat or whisper to instruct shadow."},
           {cmd = "formation chaos", name = "Chaos Formation", desc = "Your shadows will arrange itself in a chaotic formation. Say 'formation chaos' in group chat or whisper to instruct shadow."},
           {cmd = "formation shield", name = "Shield Formation", desc = "Your shadows will arrange itself in a shield formation. Say 'formation shield' in group chat or whisper to instruct shadow."},
           {cmd = "formation", name = "Default Formation", desc = "Your shadows will revert to its default formation. Say 'formation' in group chat or whisper to instruct shadow."},
           {cmd = "reset botAI", name = "Reset botAI", desc = "Say 'reset botAI' (case sensitive) in group chat or whispers to a shadow to reset its settings."},
       }
   },
   worldinteraction = {
       name = "World Interaction", 
       intid = 23,
       commands = {
           {cmd = "repair", name = "Repair", desc = "Your shadows will repair at a nearby eligible vendor if you say 'repair' in group chat or whispers."},
           {cmd = "talk", name = "Talk", desc = "By saying 'talk' in group chat or whispers to a shadow, your shadows will talk to your current target. This can be used to hand in quests or learn flight paths, for example."},
           {cmd = "trainer learn", name = "Learn Skills", desc = "Your shadows will learn applicable skills from the trainer you are currently talking to. Say 'trainer learn' in group chat or whisper to instruct shadow."},
           {cmd = "release", name = "Release Spirit", desc = "Your shadows will release its spirit upon death. Say 'release' in group chat or whisper to instruct shadow."},
           {cmd = "quests", name = "View Quests", desc = "Your shadows will display available quests. Say 'quests' in group chat or whisper to instruct shadow."},
           {cmd = "stats", name = "View Stats", desc = "Your shadows will display current stats. Say 'stats' in group chat or whisper to instruct shadow."},
           {cmd = "reset botAI", name = "Reset botAI", desc = "Say 'reset botAI' (case sensitive) in group chat or whispers to a shadow to reset its settings."},
        }
   },
   spell = {
       name = "Spells", 
       intid = 24,
       commands = {
           {cmd = "cast <spell>", name = "cast <spell name>", desc = "You may instruct your shadows to cast specific spells in their spell book by saying 'cast <spell name>'.\n \nFor example, if you want your Death Knight shadow to change presence, say 'cast Blood Presence' in group chat or whisper.\n \nThis is also how one can assign paladin and other class buffs.\n \n"},
       }
   },
   playerinteraction = {
       name = "Player Interaction", 
       intid = 26,
       commands = {
           {cmd = "stats", name = "Stats", desc = "By saying 'stats' in group chat or whispers, your shadows will display their experience percentage, number of free bag slots, and money."},
           {cmd = "inv", name = "Inventory", desc = "By whispering 'inv' to a shadow, the shadow will whisper back its full inventory."},
           {cmd = "c", name = "Inventory", desc = "'c' can also be used to make a shadow show its inventory."},
           {cmd = "e", name = "Equip Inventory", desc = "By whispering 'e <item>' to a shadow, the shadow will equip a named or linked from its inventory."},
           {cmd = "s", name = "Sell Inventory", desc = "By whispering 's' to a shadow, a shadow can vendor specific items. Specify further with grey, vendor, item link, and more."},
           {cmd = "u", name = "Use Inventory", desc = "Whisper 'u' to a shadow to make it use any available item specified in the message. If no item specified, your shadow will say which items can be used."},
           {cmd = "destroy", name = "Destroy Inventory", desc = "By whispering 'destroy' to a shadow, you can select items to destroy from its inventory."},
           {cmd = "rep", name = "Reputation", desc = "By whispering 'rep' or 'reputation' to a shadow, the shadow will tell you its current reputation standing of the faction of whichever NPC you are currently targetting."},
           {cmd = "t", name = "Trade", desc = "You may trade your shadows to distribute loot, free up inventory, pass mats around, and so on. Whisper them 't' or trade them directly to get started. They will whisper you their inventory. To select items to trade, whisper them which item from their inventory you want traded. \n \nNote: Shadows cannot trade you soulbound items even if they have a valid trade timer."},
       }
   },
   talents = {
       name = "Talents", 
       intid = 27,
       commands = {
           {cmd = "talents", name = "Talents", desc = "Your shadows are capable of flexibly utilizing their talents. Whisper your shadow 'talents' to get started."},
           {cmd = "talents spec list", name = "Talents Spec List", desc = "Your shadows come with preset talents you can assign them. They can list applicable talent presets by whispering them 'talents spec list'."},
           {cmd = "talents switch", name = "Talents Switch", desc = "By whispering 'talents switch 1' or 'talents switch 2' to a shadow, the shadow will switch to its main specialization (1) or its secondary specialization (2)."},
           {cmd = "talents spec <specName>", name = "Talents Spec <specName>", desc = "By whispering 'talents spec' with a specialization as listed by 'talents spec list', your shadow will swap out its current set of talents for the chosen preset."},
           {cmd = "talents autopick", name = "Talents Autopick", desc = "Your shadows can automatically select their preferred talents by whispering them 'talents autopick', assuming they have free talent points."},
           {cmd = "note", name = "Note", desc = "Using flexible shadow talents will not influence your glyphs. The talents your shadows apply will remain after the shadow session ends. It is free for shadows to respec."},
       }
   },
   loot = {
       name = "Loot", 
       intid = 28,
       commands = {
		   {cmd = "ll", name = "Loot List Settings", desc = "Control how your shadows loot items with the following commands."},
		   {cmd = "ll normal", name = "Loot Normal Items", desc = "Instruct your shadows to roll greed on all items up to rare quality and loot items not claimed by other players by whispering 'll normal'."},
		   {cmd = "ll all", name = "Loot All Items", desc = "Instruct your shadows to loot all quality items by whispering 'll all'."},
		   {cmd = "ll quest", name = "Loot Quest Items", desc = "Instruct your shadows to loot quest-related items by whispering 'll quest'."},
		   {cmd = "ll disenchant", name = "Loot Disenchantable Items", desc = "Instruct your shadows to loot items suitable for disenchanting by whispering them 'll disenchant'."},
		   {cmd = "ll none", name = "Stop Looting", desc = "Instruct your shadows to stop looting by whispering 'll none'."}
         }
   },
}

-- Pure map-side renders from world payloads. No DB or shared vars.

local function CacheView(playerName, view)
    local c = mapViewCache[playerName] or {}
    if view.view == "hello" then
        c.hello = view
    elseif view.view == "add" then
        c.available = view.available or {}
        c.hello = { view = "hello", seq = view.seq, count = view.count, max = view.max, barReady = view.barReady }
    elseif view.view == "remove" then
        c.bots = view.bots or {}
        c.hello = { view = "hello", seq = view.seq, count = view.count, max = view.max, barReady = view.barReady }
    end
    mapViewCache[playerName] = c
    mapAckSeq[playerName] = view.seq
end

local function ShowAvailableShadows(player, view)
    local rows = (view and view.available) or (mapViewCache[player:GetName()] or {}).available or {}
    local cc = mapViewCache[player:GetName()]
    if cc then cc.lastMenu = "add" end
    player:GossipClearMenu()
    player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_groupneedmore:40:40:-24:0|tAvailable shadows:\n \n ", 0, 10)

    local found = false
    for index, charInfo in ipairs(rows) do
        local className = GetClassName(charInfo.class)
        local raceName = GetRaceName(charInfo.race)

        local raceIcon = GetRaceIconPath(charInfo.race, charInfo.gender)
        local classIcon = GetClassIconPath(charInfo.class)

        if charInfo.tier == 1 then
            player:GossipMenuAddItem(4, "|TINTERFACE/ICONS/" .. raceIcon .. ":40:40:-24:0|t |TINTERFACE/ICONS/" .. classIcon .. ":40:40:-24:0|t |TINTERFACE/ICONS/achievement_level_" .. (math.floor(charInfo.level / 10) * 10) .. ":40:40:-24:0|t \n \n \n \nName:  " .. charInfo.name .. "\n \nLevel:  " .. charInfo.level .. "\n \nRace:  " .. raceName .. "\n \nClass:  " .. className .. "\n ", 0, 100 + index)
            found = true
        elseif charInfo.tier == 2 then
            player:GossipMenuAddItem(4, "|TINTERFACE/ICONS/" .. raceIcon .. ":40:40:-24:0|t |TInterface/ICONS/" .. classIcon .. ":40:40:-24:0|t |TInterface/ICONS/inv_misc_desecrated_clothchest:40:40:-24:0|t\n \n \n \nName:  " .. charInfo.name .. "\n \nLevel:  " .. charInfo.level .. "\n \nRace:  " .. raceName .. "\n \nClass:  " .. className .. "\n ", 0, 100 + index)
            found = true
        end
    end
    if not found then
        player:GossipMenuAddItem(4, "|TINTERFACE/ICONS/ability_rogue_shadowstep:40:40:-24:0|tNo available shadows \n \nThere are no shadows available in the range you can mind control. Your shadows must be within ten levels of you and at least level 15.\n \n", 0, 10)
    end

    player:GossipMenuAddItem(4, "|TInterface/ICONS/Trade_Engineering:40:40:-24:0|tBack", 0, 999)

    player:GossipSendMenu(12, player, 200)
end

local function ShadowsHello(player, view)
    local hello = view or (mapViewCache[player:GetName()] or {}).hello or {}
    local cc = mapViewCache[player:GetName()]
    if cc then cc.lastMenu = "hello" end
    local count = hello.count or 0
    local maxBotsForPlayer = hello.max or maxBotCount

    player:GossipClearMenu()

    player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_gizmo_02:40:40:-24:0|tHow to use shadows", 0, 2)

    player:GossipMenuAddItem(4, "|TInterface/ICONS/inv_misc_groupneedmore:40:40:-24:0|tAdd shadow (" .. count .. "/"..maxBotsForPlayer..")", 0, 10)
    if count > 0 then
        player:GossipMenuAddItem(4, "|TINTERFACE/ICONS/spell_unused2:40:40:-24:0|tSummon shadows", 0, 5, false, "Are you sure you want to summon your shadow(s) here?\n \nThis will induce a "..(BotSummonCD/60).."-minute summon cooldown.")
        player:GossipMenuAddItem(4, "|TInterface/PaperDollInfoFrame/UI-GearManager-Undo:40:40:-24:0|tRemove shadow", 0, 6)
    end
    player:GossipMenuAddItem(4, "|TINTERFACE/ICONS/spell_shadow_darksummoning:40:40:-24:0|tShadow bar settings", 0, 7)
    player:GossipMenuAddItem(4, "|TINTERFACE/ICONS/Trade_Engineering:40:40:-24:0|tExit", 0, 1000)
    player:GossipSendMenu(12, player, 200)
end

local function ListActiveShadows(player, view)
    local bots = (view and view.bots) or (mapViewCache[player:GetName()] or {}).bots or {}
    local cc = mapViewCache[player:GetName()]
    if cc then cc.lastMenu = "remove" end
    player:GossipClearMenu()

    local activeHeader = "Active shadows:"
    if #bots == 0 then
        activeHeader = "You have no active shadows."
    end
    player:GossipMenuAddItem(0, "|TInterface/PaperDollInfoFrame/UI-GearManager-Undo:40:40:-24:0|t" .. activeHeader .. "\n \n ", 0, 6)

    for index, botName in ipairs(bots) do
        local menuText = string.format(
            "|TInterface/ICONS/ability_vehicle_loadselfcatapult:40:40:-24:0|t%s\n \n ",
            botName
        )

        player:GossipMenuAddItem(0, menuText, 0, 200 + index)
    end

    player:GossipMenuAddItem(0, "|TInterface/ICONS/Trade_Engineering:40:40:-24:0|tBack", 0, 999)
    player:GossipSendMenu(12, player, 200)
end

-- Loading placeholder. Intid 11 is a dedicated no-op.
local function ShowLoadingMenu(player, text)
    text = text or "Loading, one moment..."
    player:GossipClearMenu()
    player:GossipMenuAddItem(4, "|TINTERFACE/ICONS/inv_misc_groupneedmore:40:40:-24:0|t" .. text .. "\n \n", 0, 11)
    player:GossipMenuAddItem(4, "|TINTERFACE/ICONS/Trade_Engineering:40:40:-24:0|tBack", 0, 999)
    player:GossipSendMenu(12, player, 200)
end

local function DoSummon(player, accountId, botNames)
    if not botNames or #botNames == 0 then
        player:SendAreaTriggerMessage("You have no active shadows.")
        return
    end
    for _, botName in ipairs(botNames or {}) do
        local bot = Multistate.FindPlayerByName(botName)
        if bot then
            bot:Teleport(player:GetMapId(), player:GetX() + math.random(-3, 3), player:GetY() + math.random(-3, 3), player:GetZ() + math.random(0, 0.1), player:GetO() + math.random(-6, 6))
            player:CastSpell(bot, BOT_TELE_VISUAL, true)
            bot:RegisterEvent(function(eventId, delay, repeats, b)
                if b then b:CastSpell(b, BOT_TELE_VISUAL, true) end
            end, 500, 1)
        end
    end
    botTeleTime[accountId] = os.time() + (BotSummonCD)
end

-- Map -> world request. Only the matching answer renders.
local function MapSendToWorld(player, op, params)
    local name = player:GetName()
    local seq = (mapReqSeq[name] or 0) + 1
    mapReqSeq[name] = seq
    local data = { op = op, seq = seq, playerName = name }
    if params then
        for k, v in pairs(params) do
            data[k] = v
        end
    end
    player:SendEMQMessage("ShadowsToWorld", data)
    player:RegisterEvent(function(eventId, delay, repeats, pl)
        if pl and mapAckSeq[pl:GetName()] ~= seq and mapReqSeq[pl:GetName()] == seq then
            mapPendingAction[pl:GetName()] = nil
            pl:SendAreaTriggerMessage("Shadows service timed out, please reopen the menu.")
            local c = mapViewCache[pl:GetName()]
            if c and c.hello then
                ShadowsHello(pl, c.hello)
            else
                pl:GossipComplete()
            end
        end
    end, VIEW_TIMEOUT_MS, 1)
end

-- Map-side view dispatcher. Stale answers are dropped.
HandleMapView = function(player, data)
    if not player or not data then
        return
    end
    local name = data.playerName or player:GetName()
    -- Unsolicited views (nil seq) always render.
    if data.seq ~= nil and data.seq ~= mapReqSeq[name] then
        return
    end
    CacheView(name, data)
    mapAckSeq[name] = mapReqSeq[name]
    if data.view == "hello" then
        ShadowsHello(player, data)
    elseif data.view == "add" then
        ShowAvailableShadows(player, data)
    elseif data.view == "remove" then
        if mapPendingAction[name] == "summon" then
            mapPendingAction[name] = nil
            DoSummon(player, player:GetAccountId(), data.bots)
            local c = mapViewCache[name]
            if c and c.hello then ShadowsHello(player, c.hello) end
        else
            ListActiveShadows(player, data)
        end
    elseif data.view == "follow" then
        for _, botName in ipairs(data.bots or {}) do
            local bot = Multistate.FindPlayerByName(botName)
            if bot and bot:GetMapId() == player:GetMapId() then
                if not bot:IsWithinLoS(player) and
                (((bot:GetZ() < player:GetZ() - 20) or (bot:GetZ() > player:GetZ() + 20) or (player:GetDistance(bot) > 100))
                or not ((bot:GetMapId() == player:GetMapId())))
                or
                (player:GetDistance(bot) > 400)
                then
                    bot:Teleport(player:GetMapId(), player:GetX() + math.random(-1, 1), player:GetY() + math.random(-1, 1), player:GetZ(), player:GetO() + math.random(-6, 6))
                end
            end
        end
    end
end


local function ShadowsGossipSelect(event, player, object, sender, intid, code, menu_id)
    -- Map side: no DB or shared vars. Clicks resolve names from the
    -- cached view and forward via EMQ.
    local name = player:GetName()
    local cache = mapViewCache[name] or {}

    if intid == 11 then -- loading-header no-op
        return
    end

    if intid == 2 then -- Settings main menu
       player:GossipClearMenu()
       player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_gizmo_02:40:40:-24:0|tHow to use shadows\n \nBy reaching through the Twisting Nether, you are able to summon shadows of the other characters on your account.\n \nTo control and summon a shadow, it must be within ten levels of you.\n \nYour active shadows adjust to your faction.\n \nYou may control up to "..maxBotCount.." shadows at a time, or "..maxVIPCount.." shadows at a time if you have VIP.\n \nThe shadow bar offers quick access to most shadows features. See below for in-depth information on how to control your shadows.\n \n", 0, 2)

       -- Add main category options
       for _, category in pairs(commandCategories) do
           player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_gizmo_02:40:40:-24:0|t"..category.name, 0, category.intid)
       end

       player:GossipMenuAddItem(0, "|TInterface/ICONS/Trade_Engineering:40:40:-24:0|tBack", 0, 999)
       player:GossipSendMenu(12, player, 200)

    elseif intid >= 20 and intid <= 29 then -- Category submenus
       player:GossipClearMenu()

       -- Find the selected category
       local selectedCategory
       for _, category in pairs(commandCategories) do
           if category.intid == intid then
               selectedCategory = category
               break
           end
       end

        function GetCategoryIcon(categoryName)
           local icons = {
               ["Movement"] = "ability_hunter_improvedtracking",
               ["Combat"] = "ability_warrior_battleshout",
               ["Formation"] = "achievement_arena_5v5_3",
               ["World Interaction"] = "achievement_zone_northrend_01",
               ["Spells"] = "ability_mage_frostfirebolt",
               ["Trade"] = "inv_misc_coin_06",
               ["Player Interaction"] = "inv_misc_bag_07_red",
               ["Talents"] = "ability_dualwieldspecialization",
               ["Loot"] = "inv_box_03",
           }
           return icons[categoryName] or "inv_misc_questionmark"
        end

       if selectedCategory then
           -- Header with gizmo icon
           player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_gizmo_02:40:40:-24:0|t"..selectedCategory.name.." Commands:\n \n ", 0, selectedCategory.intid)

           -- Get the appropriate icon for this category
           local categoryIcon = GetCategoryIcon(selectedCategory.name)

           for _, command in ipairs(selectedCategory.commands) do
               local menuText = string.format(
                   "|TInterface/ICONS/%s:40:40:-24:0|t%s\n \n%s\n \n ",
                   categoryIcon,
                   command.name,
                   command.desc
               )
               player:GossipMenuAddItem(0, menuText, 0, selectedCategory.intid)
           end
       end

       player:GossipMenuAddItem(0, "|TInterface/ICONS/Trade_Engineering:40:40:-24:0|tBack", 0, 2)
       player:GossipSendMenu(12, player, 200)

    elseif intid == 3 then -- Follow (cached bots, map-safe only)
        for _, botName in ipairs(cache.bots or {}) do
            local bot = Multistate.FindPlayerByName(botName)
            if bot then
                bot:MoveFollow(player, math.random(-6, 6), math.random(-6, 6))
                if bot:IsInCombat() and bot:GetSelection() then
                    bot:GetSelection():ClearInCombat()
                end
                bot:ClearInCombat()
            end
        end
        player:SendAreaTriggerMessage("Your shadows are now following you.")
        if cache.hello then ShadowsHello(player, cache.hello) end
    elseif intid == 4 then -- Attack (cached bots, map-safe only)
        for _, botName in ipairs(cache.bots or {}) do
            if Multistate.FindPlayerByName(botName) then
                player:Say("/p attack", 0)
                break
            end
        end
        if cache.hello then ShadowsHello(player, cache.hello) end
    elseif intid == 5 then -- Summon from the active list, fetching it first if empty
        local accountId = player:GetAccountId()
        if not botTeleTime[accountId] then botTeleTime[accountId] = 0 end

        if botTeleTime[accountId] >= os.time() then
            player:SendAreaTriggerMessage("Your shadows summon is on cooldown for " .. math.floor((botTeleTime[accountId] - os.time()) / 60) .. " minutes and " .. ((botTeleTime[accountId] - os.time()) % 60) .. " seconds.")
            if cache.hello then ShadowsHello(player, cache.hello) end
        elseif cache.bots and #cache.bots > 0 then
            DoSummon(player, accountId, cache.bots)
            if cache.hello then ShadowsHello(player, cache.hello) end
        else
            mapPendingAction[name] = "summon"
            ShowLoadingMenu(player, "Loading your active shadows, one moment...")
            MapSendToWorld(player, "removemenu")
        end
    elseif intid == 6 then  -- Remove list: placeholder, world repopulates
        ShowLoadingMenu(player, "Loading your active shadows, one moment...")
        MapSendToWorld(player, "removemenu")
    elseif intid == 7 then -- Bar settings via cached flag
        if cache.hello and cache.hello.barReady then
            player:SendAddonMessage("ShadowsBar", "SETTINGS", 7, player)
        else
            player:SendAreaTriggerMessage("Your shadow bar settings are loading, please try again in a few seconds.")
            player:SendBroadcastMessage("Your shadow bar settings are loading, please try again in a few seconds.")
        end
        if cache.hello then ShadowsHello(player, cache.hello) end
    elseif intid >= 200 and intid < 299 then  -- Bot removal: name from cache, world commits
        local botName = (cache.bots or {})[intid - 200]
        if botName then
            ShowLoadingMenu(player, "Removing shadow, one moment...")
            MapSendToWorld(player, "remove", { botName = botName })
        end
    elseif intid == 10 then  -- Add entry: fresh fetch from hello, instant re-render inside the list
        if cache.lastMenu == "add" and cache.available then
            ShowAvailableShadows(player)
        else
            ShowLoadingMenu(player, "Loading available shadows...")
            MapSendToWorld(player, "addmenu")
        end
    elseif intid >= 100 and intid < 199 then  -- Bot add: name from cache, world commits
        local row = (cache.available or {})[intid - 100]
        if not row then
            return
        end
        local leave = false
        for _, zone in pairs(disallowedZones) do
            if player:GetZoneId() == zone or player:GetAreaId() == zone then
                player:GossipComplete()
                player:SendAreaTriggerMessage("You cannot use shadows in "..GetAreaName(player:GetAreaId())..".")
                leave = true
                break
            end
        end
        if leave then return end
        if (player:GetMapId() == 571) and (player:GetZoneId() == 4197) and IsWintergraspWarTime() then
            player:GossipComplete()
            player:SendAreaTriggerMessage("You cannot use shadows during active Wintergasp battles.")
            return
        end
        if player:GetLevel() < minShadowsLevel then
            player:SendAreaTriggerMessage("You need to be at least level ".. minShadowsLevel .. " to use shadows!")
            if cache.hello then ShadowsHello(player, cache.hello) end
            return
        end
        ShowLoadingMenu(player, "Adding shadow, one moment...")
        MapSendToWorld(player, "add", { botName = row.name, reqTime = os.time() })
    elseif intid == 999 then  -- "Back" option: cached hello only, never an op
        if cache.hello then
            player:GossipClearMenu()
            ShadowsHello(player, cache.hello)
        else
            player:GossipComplete()
        end
    elseif intid == 1000 then  -- "Exit" option
        player:GossipComplete()
    end
end


function SetActiveVars()
    local playersByAccount = {}
    local allGuids = {}

    -- Group players visible in this state by account ID and collect all GUIDs.
    -- Multistate: the global state sees everyone; map states see their own map.
    -- The shadows_bots table converges because all writes are REPLACE/DELETE.
    Multistate.ForEachPlayer(function(player)
        if player then
            Multistate.SetData(player, "ShadowBarStatusChecked", true)
            local accountId = player:GetAccountId()
            if not playersByAccount[accountId] then
                playersByAccount[accountId] = {}
            end
            local name = player:GetName()
            local guid = player:GetGUIDLow()
            local playerData = {
                name = name,
                guid = guid
            }
            table.insert(playersByAccount[accountId], playerData)
            table.insert(allGuids, playerData.guid)
            ShadowSetBotCount(player, 0)
        end
    end)

    -- Multistate: only the global state prunes stale mappings. This mirrors the
    -- original full table reset: any link involving an offline player is dropped,
    -- then co-online same-account links are re-detected below.
    if GetStateMapId() == -1 then
        CharDBExecute("DELETE FROM acore_eluna.shadows_bots WHERE bot_name NOT IN (SELECT name FROM characters WHERE online = 1) OR master_name NOT IN (SELECT name FROM characters WHERE online = 1)")
    end

    if #allGuids > 0 then
        local guidString = table.concat(allGuids, ",")
			
	    CharDBQueryAsync(
		    string.format("SELECT guid, data FROM acore_eluna.character_custom_data WHERE guid IN (%s) AND type = 98", guidString),
		    function(result)
				if result then
					repeat
						local guid = result:GetUInt32(0)
						local data = result:GetString(1)
						if data == "ENABLED" then
                            -- Multistate: state-aware lookup (callback runs in this state).
				 		    local player = Multistate.FindPlayerByGUID(GetPlayerGUID(guid))
				 		    if player then
								ShadowSetBarData(player, true)
		  		 			end
		 		 	    end
		 		    until not result:NextRow()
		 	    end
		    end
	    )
		
			
        CharDBQueryAsync(string.format(
            "SELECT guid, cooldown_end FROM acore_eluna.character_cooldowns WHERE guid IN (%s) AND item_id = 0",
            guidString
        ),
        function(query)
            local cooldowns = {}
            
            if query then
                repeat
                    local guid = query:GetUInt32(0)
                    local cooldownEnd = query:GetUInt32(1)
                    cooldowns[guid] = cooldownEnd
                until not query:NextRow()
            end

            -- Process each account
            for accountId, players in pairs(playersByAccount) do
                if #players > 1 then
                    local lowestCooldown = nil
                    local mainPlayer = nil

                    -- Find player with lowest cooldown in this account
                    for _, playerData in pairs(players) do
                        local cooldown = cooldowns[playerData.guid] or 0
                        if not lowestCooldown or cooldown < lowestCooldown then
                            lowestCooldown = cooldown
                            mainPlayer = playerData
                        end
                    end

                    -- Set up activeBots for the main player
                    if mainPlayer then
						local player = Multistate.FindPlayerByName(mainPlayer.name)
                        activeBots[mainPlayer.name] = {}
                        player:SetData("BotCount", 0)

                        -- Add other characters as bots
                        for _, playerData in pairs(players) do
                            if playerData.guid ~= mainPlayer.guid then
                                table.insert(activeBots[mainPlayer.name], playerData.name)
                                player:SetData("BotCount", (player:GetData("BotCount") or 0) + 1)
                                isPlayerBot[playerData.name] = mainPlayer.name
                            end
                        end
                    end
                end
            end
        end)
    end
end

local function ShadowsLogin(event, player) -- Lazy persistent storage solution. Could probably just use characters table directly. Initially wanted cache-persistent value attached to world but not possible in standard AC ELUNA
    -- Multistate: this handler only fires in the global state (event 3).
    local guid = player:GetGUIDLow()
    local name = player:GetName()

	CharDBExecute("REPLACE INTO acore_eluna.character_cooldowns (guid, item_id, cooldown_end) VALUES (" .. guid .. ", 0, " .. os.time() .. ")");

    if ShadowGetMaster(name) then

		if player:HasAura(32113) then player:RemoveAura(32113) end

		if (player:GetClass() == 11) and not player:HasAura(57857) then player:AddAura(57857, player) end -- Fixes Druid shadows stuck on Rebirth without mats

        if not player:IsInGroup() then return end

        local group = player:GetGroup()

        local masterName = ShadowGetMaster(name)
        local master
        if masterName then master = Multistate.FindPlayerByName(masterName) end

        if not master then return end

		if ShadowGetBarData(master) then
			master:SendAddonMessage("ShadowsBar", "ENABLED", 7, master)
		else
			master:SendAddonMessage("ShadowsBar", "DISABLED", 7, master)
		end

        if not group:IsLeader(player:GetGUID()) then return end

        if player:IsInSameGroupWith(master) or player:IsInSameRaidWith(master) then
            group:SetLeader(master:GetGUID())
        end
    end

    if ShadowGetMaster(name) then return end

    if ShadowGetBotCount(player) < 0 then ShadowSetBotCount(player, 0) end

	ShadowSetLoginTime(player, os.time())

	CharDBQueryAsync("SELECT data FROM acore_eluna.character_custom_data WHERE guid = "..guid.." AND type = 98", function(result)
		if result then
			local data = result:GetString(0)
			local player = Multistate.FindPlayerByGUID(GetPlayerGUID(guid))
			if not player then return end
			if data == "ENABLED" then
				ShadowSetBarData(player, true)
			else
				ShadowSetBarData(player, false)
			end
		end
	end)
end

local function LogoutOrSave(event, player)
    -- Event 4 (logout) is global. Event 25 (map save) forwards to world.
    if event == 25 then
        player:SendEMQMessage("ShadowsToWorld", { op = "savebar", playerName = player:GetName() })
        return
    end
    local guid = player:GetGUIDLow()
    local name = player:GetName()

	if ShadowGetBarData(player) then
		CharDBExecute("REPLACE INTO acore_eluna.character_custom_data (guid, type, time, data) VALUES ("..guid..", 98, "..os.time()..", 'ENABLED')")
	else
		CharDBExecute("REPLACE INTO acore_eluna.character_custom_data (guid, type, time, data) VALUES ("..guid..", 98, "..os.time()..", 'DISABLED')")
	end

    -- Check if the player was anyone's bot and unlink them.
    local botMaster = ShadowGetMaster(name)
    ShadowSetMaster(name, nil)
    -- The departing player can no longer master anyone: unlink their bots.
    for _, botName in ipairs(ShadowGetBots(name)) do
        ShadowSetMaster(botName, nil)
    end

    if botMaster then
        local master = Multistate.FindPlayerByName(botMaster)
        if master then
            ShadowSetBotCount(master, #(ShadowGetBots(botMaster)))
        end

        if (master and master:GetInstanceId()) or player:GetInstanceId() then
            return -- Don't boot players' bots from group if in RHC as it can bug out the instance group
        end
        player:RemoveFromGroup()
    end
end

function CheckActiveBots(eventid, delay, repeats, uninvitedPlayer)
    local uninvitedPlayerName = uninvitedPlayer:GetName()
    if ShadowGetMaster(uninvitedPlayerName) then
        local player = Multistate.FindPlayerByName(ShadowGetMaster(uninvitedPlayerName))
        local bot = Multistate.FindPlayerByName(uninvitedPlayerName)
        if player and bot then
            player:RegisterEvent(function(_, _, _, player)
                player:RunCommand(".shadows bot remove " .. uninvitedPlayerName)
                print("Bot removed: " ..uninvitedPlayerName.. ".")
                print("Leader: " ..player:GetName())
            end, 100, 1)
        end
        logoutEvent[uninvitedPlayerName] = nil
    end
end

function UninviteGroupGUID(event, packet, player)
    local guid = packet:ReadGUID()
    local reason = packet:ReadString()
    local uninvitedPlayer = Multistate.FindPlayerByGUID(guid)
    if uninvitedPlayer then
        if not logoutEvent[uninvitedPlayer:GetName()] then
			if ShadowDontKickActive(uninvitedPlayer) then return end
			--print("shadows debug - uninvited GUID")
            logoutEvent[uninvitedPlayer:GetName()] = uninvitedPlayer:RegisterEvent(CheckActiveBots, 100, 1)
        end
    end
end

function UninviteGroup(event, packet, player)
    local uninvitedPlayerName = packet:ReadString()
    local uninvitedPlayer = Multistate.FindPlayerByName(uninvitedPlayerName)
    if uninvitedPlayer then
        if not logoutEvent[uninvitedPlayer:GetName()] then
			if ShadowDontKickActive(uninvitedPlayer) then return end
			--print("shadows debug - uninvited group")
            logoutEvent[uninvitedPlayer:GetName()] = uninvitedPlayer:RegisterEvent(CheckActiveBots, 100, 1)
        end
    end
end

local function LeaveGroup(event, group, guid, method, kicker, reason)
    local uninvitedPlayer = Multistate.FindPlayerByGUID(guid)
    if uninvitedPlayer then
        if not logoutEvent[uninvitedPlayer:GetName()] then
			if ShadowDontKickActive(uninvitedPlayer) then return end
			--print("shadows debug - leaving group")
            logoutEvent[uninvitedPlayer:GetName()] = uninvitedPlayer:RegisterEvent(CheckActiveBots, 100, 1)
        end
    end
end

local function DisbandGroup(event, group)
    for _, member in ipairs (group:GetMembers()) do
        if ShadowGetMaster(member:GetName()) then
            local botName = member:GetName()
            local player = Multistate.FindPlayerByName(ShadowGetMaster(botName))
            if player and not logoutEvent[botName] then
                logoutEvent[botName] = player:RegisterEvent(function(_, _, _, player)
					if ShadowDontKickActive(Multistate.FindPlayerByName(botName)) then return end
                    player:RunCommand(".shadows bot remove " .. botName)
                    print("Removing "..botName.." from disbanded group")
                    logoutEvent[botName] = nil
                end, 100, 1)
            end
        end
    end
end

function Teleport(player, sameMap)
    -- Multistate: called from global packet handlers and map enter handlers.
    local name = player:GetName()
    if ShadowGetMaster(name) then return end
    if ShadowGetBotCount(player) == 0 then
        return
    end
    if os.time() <= ShadowGetLastTeleTime(player) then
        return
    end
    if not player:IsInGroup() then
        return -- Should probably add a sanity check here to disconnect bots not in your party in case party affiliation fails somehow
    end
    if player:IsDead() then
        return
    end
    if ((player:GetMapId() == 0 or player:GetMapId() == 1 -- Kalimdor, Eastern Kingdoms
    or player:GetMapId() == 530 or player:GetMapId() == 571) -- Outlands, Northrend
    and (sameMap == "yes"))
    or (player:InArena() or player:InBattleground()) -- PVP exclusions from teleport
    then
        return
    end
    for i, botName in ipairs(ShadowGetBots(name)) do
        local bot = Multistate.FindPlayerByName(botName)
        if bot and not player:IsInCombat() then
			if (bot:GetHealth() == 0) and not bot:HasAura(8326) then -- Stops unreleased ghost corpses from being teleported
				return
			end 
            if bot:GetMapId() ~= player:GetMapId() and sameMap == "yes" then
                return
            end
            if not bot:IsWithinLoS(player) and
			(((bot:GetZ() < player:GetZ() - 20) or (bot:GetZ() > player:GetZ() + 20) or (player:GetDistance(bot) > 100))
			or not ((bot:GetMapId() == player:GetMapId())))
			or
			(player:GetDistance(bot) > 400)
			then
				if bot:HasAura(8326) then RunCommand("revive "..bot:GetName()) end -- handle auto revive of bots on enter instance/raid
                bot:Teleport(player:GetMapId(), player:GetX() + math.random(-1, 1), player:GetY() + math.random(-1, 1), player:GetZ(), player:GetO() + math.random(-6, 6))
                print("Teleporting bot "..botName.." to "..name)
            end
        end
    end
    ShadowSetLastTeleTime(player, os.time() + 1)
end

local function PacketTeleDelay(_, _, player)
    local name = player:GetName()
    if ShadowGetMaster(name) then return end
    local sameMap = "openWorld"
    player:RegisterEvent(function(_, _, _, player)
        Teleport(player, sameMap)
    end, 1000, 1)
end

local function PacketMoveDelay(_, _, player)
    local name = player:GetName()
    if ShadowGetMaster(name) then return end
    local sameMap = "yes"
    player:RegisterEvent(function(_, _, _, player)
        Teleport(player, sameMap)
    end, 1000, 1)
end

local function buildCommandList()
    local commands = {}
    for _, category in pairs(commandCategories) do
        for _, cmd in ipairs(category.commands) do
            local cleanCmd = cmd.cmd:gsub("%s*<.+>%s*$", ""):lower()
            commands[cleanCmd] = true
        end
    end
    return commands
end

local validCommands = buildCommandList()

local function OnGroup(event, player, msg, Type, lang, group)
    if msg == "repair" then
        local group = player:GetGroup()

        local groupPlayers = group:GetMembers()
        for _, groupMember in ipairs(groupPlayers) do
            local groupMemberName = groupMember:GetName()

            for _, botName in ipairs(ShadowGetBots(groupMemberName)) do
                local bot = GetPlayerByName(botName)
                if bot and player:GetAccountId() == bot:GetAccountId() then
                    bot:SendUnitWhisper("Repairing!", 0, player)
                end
            end
        end
    end
end

local botWhisperResponses = {
    {
        keywords = {"hello", "hi", "hey", "greetings", "good morning", "good afternoon", "good evening", "howdy", "hiya", "what's up", "yo", "sup", "how are you", "how's it going", "nice to see you", "welcome", "salutations", "good day", "ahoy", "aloha", "bonjour", "hola", "ciao", "o/", "o7"},
        replies = {"Hey! :)", "Hiya!", "What's up?", "Greetings, traveler!", "Hello there!", "Hi!", "Howdy partner!", "Good to see you!", "Hey, how are you?", "Good day!", "Hey there!", "Hello friend!", "Yo!", "Sup!", "How's it going?", "Nice to see you too!", "Welcome!", "Ahoy matey!", "Aloha!", "Bonjour!", "Hola!", "Ciao!", "o/!", "o7!"}
    },
    {
        keywords = {"joke", "funny", "laugh", "haha", "hehe", "lol", "rofl", "lmao", "kek", "heh"},
        replies = {
            "Why don't scientists trust atoms? Because they make up everything!",
            "Parallel lines have so much in common. It's a shame they'll never meet.",
            "Why did the scarecrow win an award? Because he was outstanding in his field!",
            "I told my wife she was drawing her eyebrows too high. She looked surprised.",
            "Why did the bicycle fall over? Because it was two tired!",
            "Want to hear a joke about paper? Never mind, it's tearable.",
            "I'm reading a book on anti-gravity. It's impossible to put down!",
            "Why did the golfer wear two pairs of pants? In case he got a hole-in-one.",
            "What do you call a fish with no eyes? Fsh!",
            "What do you call a fake noodle? An impasta.",
            "Why don't eggs tell jokes? They'd crack each other up.",
            "How do you make an octopus laugh? With ten-tickles!",
            "Why did the math book look sad? Because it had too many problems.",
            "What do you call a bear with no teeth? A gummy bear.",
            "Why don't skeletons fight each other? They don't have the guts.",
            "What do you get if you drop a piano down a mineshaft? A flat miner.",
            "Why did the can crusher quit his job? Because it was soda pressing.",
            "Want to hear a construction joke? I'm still working on it."
        }
    },
    {
        keywords = {"quest", "mission", "task", "objective", "adventure", "journey", "challenge"},
        replies = {"Ready for another adventure!", "Let's embark on a new quest!", "What mission are you on today?", "Got a challenging task ahead?", "Time to set some new goals!", "Excited for the journey ahead!", "Let's tackle that dungeon!", "What's your next objective?"}
    },
    {
        keywords = {"boss", "kill", "defeat", "victory", "triumph", "conquer"},
        replies = {"Congratulations on the boss kill!", "Great job defeating the boss!", "Victory is ours!", "We've triumphed!", "Another boss conquered!", "Well done on overcoming the challenge!", "You're a true champion!", "Epic victory!"}
    },
    {
        keywords = {"lore", "story", "history", "legend", "myth", "tale", "saga"},
        replies = {"Interested in the lore of Azeroth?", "The legends of this world are vast and intriguing.", "The stories of Azeroth are endless.", "What tale would you like to hear?", "The history of this land is fascinating."}
    },
    {
        keywords = {"gear", "equipment", "armor", "weapon", "upgrade", "loot", "enchant", "gem"},
        replies = {"Need some advice on your gear?", "Let's talk about your equipment!", "Looking to upgrade?", "What weapon are you using?", "Got any new loot to show off?", "Need help with enchants or gems?"}
    },
    {
        keywords = {"class", "spec", "talent", "ability", "rotation", "build", "playstyle"},
        replies = {"Need tips for your class?", "Let's discuss your spec!", "What talents are you using?", "What's your rotation like?", "Need help with your build?", "What's your playstyle?"}
    },
    {
        keywords = {"pvp", "arena", "battleground", "duel", "honor"},
        replies = {"Ready for some PvP action?", "Let's discuss arena strategies!", "What's your battleground of choice?", "Need tips for dueling?", "What's your PvP rating?"}
    },
    {
        keywords = {"dungeon", "raid", "instance", "heroic"},
        replies = {"I've heard tales of that place!", "A challenging endeavor awaits!", "I've explored many such places.", "Many adventurers have met their end in there.", "Do you think we can conquer it?", "I wonder what awaits us inside."}
    },
    {
        keywords = {"mount", "ride", "flying"},
        replies = {"Need help with your mount collection?", "What's your favorite ride?", "What mounts are you missing?", "I've heard of some rare ones around here."}
    },
    {
        keywords = {"guild", "leader", "officer", "recruitment"},
        replies = {"Need help with guild management?", "Let's talk about your guild!", "What's your role in the guild?", "Need tips for recruitment?"}
    },
    {
        keywords = {"profession", "crafting", "gathering", "recipe"},
        replies = {"Need help with your professions?", "Let's talk about crafting!", "What gathering skills are you using?", "What's your profession leveling strategy?"}
    },
    {
        keywords = {"weather", "raining", "sunny", "cloudy", "snowing"},
        replies = {"Looks like typical Azeroth weather to me!", "I've seen worse in Northrend.", "At least it's not raining elementals.", "Could be worse, could be a Forsaken winter.", "I prefer the weather in Nagrand myself."}
    },
    {
        keywords = {"i told you", "you should know", "obviously", "clearly", "everyone knows", "it's common sense", "for the last time", "how many times"},
        replies = {"Oh, I must have missed the memo.", "Thanks for the condescension. Very helpful.", "My crystal ball was in the shop that day.", "Sorry my telepathy wasn't working.", "Couldn't hear you from that high horse.", "Please continue telling me what I should know.", "I'll check my omniscience settings."}
    },
    {
        keywords = {"shit", "ass", "fuck", "bitch", "bastard", "cunt", "dick", "prick", "moron", "idiot", "stupid", "dumb", "jerk", "twat", "cock", "wanker", "slut", "douchebag", "asshole", "fucker", "crap", "tosser", "scumbag"},
        replies = {"I wish you would treat me better!", "Is this how you treat yourself?", "Please refrain from using such language.", "That's not very nice.", "I'd appreciate it if you'd be more respectful.", "Let's keep the conversation civil.", "I don't deserve to be spoken to like that."}
    },
}

local function OnWhisper(event, player, msg, Type, lang, receiver)
    if not player:IsBot() then return end
    
    local receiverName = receiver:GetName()
    local playerName = player:GetName()

    if not ShadowGetMaster(receiverName) then return end

    local masterName = ShadowGetMaster(receiverName)

    if not masterName then return end

    if playerName ~= masterName then
        local masterResponses = {
            "I am a shadow! Please whisper my master, " .. masterName .. "!",
            "I cannot respond directly. Please contact my master, " .. masterName .. ".",
            "My responses are limited. Whisper " .. masterName .. " for assistance.",
            "I am unable to process your request. Please whisper " .. masterName .. ".",
            "For further information, please whisper my master, " .. masterName .. ".",
            "I am here only to please " .. masterName .. "! Contact them instead.",
            "Direct your inquiries to my master, " .. masterName .. ".",
            "I am programmed to relay messages. Whisper " .. masterName .. ". Beep boop.",
            "Please whisper my master, " .. masterName .. ", for assistance.",
            "I am somebody else's helper! Please whisper " .. masterName .. " for help.",
            "I am not a player, though I might seem like one! Please whisper my master " .. masterName,
            "I am a bot, please whisper the player " .. masterName,
            "Please direct all questions to " .. masterName .. ", I live under a strict regime of no fraternization.",
            "I am just a shadow, please whisper the player controlling me instead, " .. masterName,
        }
        receiver:SendUnitWhisper(masterResponses[math.random(#masterResponses)], 0, player)
        return
    end

    local msgLower = msg:lower()

    for cmd, _ in pairs(validCommands) do
        if msgLower:match("^" .. cmd:lower() .. "%s*$") or msgLower:match("^" .. cmd:lower() .. "%s+") then
            return
        end
    end

    if msg == "repair" then
        receiver:SendUnitWhisper("Repairing!", 0, player)
        return
    end

    if msgLower:match("co%s+.+") or msgLower:match("nc%s+.+") or msgLower:match("do%s+.+") then
        return
    end

    local bot = receiver

    for _, category in ipairs(botWhisperResponses) do
        for _, keyword in ipairs(category.keywords) do
            if msgLower:find(keyword, 1, true) then
                bot:SendUnitWhisper(category.replies[math.random(#category.replies)], 0, player)
                return
            end
        end
    end

    local fallback = {
        "That command is unfamiliar to me. Perhaps Twiggy can assist you.",
        "I'm not sure what you're asking. Consult Twiggy for a list of valid commands.",
        "My programming doesn't include that command. Please ask Twiggy for guidance.",
        "I'm afraid I don't recognize that. Twiggy has the commands I understand.",
        "I can't process that. For a list of commands, talk to Twiggy.",
        "That doesn't compute. Check Twiggy for a command reference.",
        "I don't understand. Twiggy knows what I can do.",
        "I'm unable to perform that action. Twiggy can tell you what I'm capable of.",
    }
    bot:SendUnitWhisper(fallback[math.random(#fallback)], 0, player)
end

-- World side: owns ALL DB and shared vars. Answers carry a fresh view.

local function WorldMaxBots(player)
    if Multistate.GetData(player, "VIPTime") and Multistate.GetData(player, "VIPTime") > os.time() then
        return maxVIPCount
    end
    return maxBotCount
end

local function WorldHelloView(player, seq)
    local name = player:GetName()
    return {
        view = "hello", seq = seq, playerName = name,
        count = #ShadowGetBots(name),
        max = WorldMaxBots(player),
        barReady = Multistate.GetData(player, "ShadowBarStatusChecked") and true or false,
        bots = ShadowGetBots(name),
    }
end

local function WorldSendView(player, payload)
    if player and payload then
        player:SendEMQMessage("ShadowsToMap", payload)
    end
end

-- Folds the add/remove intent into the response: the queued write may
-- not have applied when the re-read runs.
local function WorldIntentHello(player, seq, addedName, removedName)
    local name = player:GetName()
    local bots = {}
    for _, b in ipairs(ShadowGetBots(name)) do
        if b ~= removedName then
            table.insert(bots, b)
        end
    end
    if addedName then
        local seen = false
        for _, b in ipairs(bots) do
            if b == addedName then seen = true break end
        end
        if not seen then table.insert(bots, addedName) end
    end
    table.sort(bots)
    ShadowSetBotCount(player, #bots)
    return {
        view = "hello", seq = seq, playerName = name,
        count = #bots,
        max = WorldMaxBots(player),
        barReady = Multistate.GetData(player, "ShadowBarStatusChecked") and true or false,
        bots = bots,
    }
end

-- Single committer for bot adds. Derives the count from truth; duplicate
-- rapid EMQs hit the exists check and become recount-only no-ops.
local function WorldAddBot(player, botName, seq, viaMenu, reqTime)
    local name = player:GetName()
    local function answer()
        if seq then WorldSendView(player, WorldHelloView(player, seq)) end
    end
    if not botName or botName == "" or botName == name then
        answer()
        return false
    end
    if viaMenu then
        if not reqTime or (os.time() - reqTime > 30) then
            player:SendAreaTriggerMessage("That shadows request expired, please try again.")
            answer()
            return false
        end
    elseif not (ShadowGetBotSummonTime(player) ~= 0 and (os.time() - ShadowGetBotSummonTime(player) < 5)) then
        return false
    end
    local lastAdd = Multistate.GetData(player, "ShadowsAddCmd")
    if lastAdd and not (GetCurrTime() - lastAdd > 300) then
        player:SendAreaTriggerMessage("You can't add shadows that fast!")
        answer()
        return false
    end
    local exists = false
    for _, char in ipairs(ShadowGetBots(name)) do
        if char == botName then exists = true break end
    end
    if exists then
        ShadowSetBotCount(player, #ShadowGetBots(name))
        answer()
        return true
    end
    if #ShadowGetBots(name) >= WorldMaxBots(player) then
        player:SendAreaTriggerMessage("You can't summon more shadows until you remove one.")
        ShadowSetBotCount(player, #ShadowGetBots(name))
        answer()
        return false
    end
    ShadowSetMaster(botName, name)
    ShadowSetBotSummonTime(player, os.time())
    ShadowSetDontKick(player, botName, os.time() + 3)
    Multistate.SetData(player, "ShadowsAddCmd", GetCurrTime())
    if ShadowGetBotCount(player) > 4 then
        local shadowsGroup = player:GetGroup()
        if shadowsGroup then shadowsGroup:ConvertToRaid() end
    end
    -- Engine command; the wrapper below swallows the re-entrant event via marker.
    Multistate.SetData(player, "ShadowsInternalCmd", botName)
    player:RunCommand(".shadows bot add " .. botName)
    player:RegisterEvent(function(e, d, r, pl)
        if not pl then return end
        local bot = Multistate.FindPlayerByName(botName)
        if not bot then return end
        local botGroup = bot:GetGroup()
        local playerGroup = pl:GetGroup()
        if botGroup and playerGroup and botGroup ~= playerGroup then
            bot:RemoveFromGroup()
            pl:GroupInvite(bot)
        elseif botGroup and not playerGroup then
            bot:RemoveFromGroup()
            pl:GroupInvite(bot)
        end
    end, 200, 1)
    -- Intent-aware answer: count/bots include the just-added name even if
    -- the queued REPLACE has not applied yet, so the (n/max) never lags.
    if seq then WorldSendView(player, WorldIntentHello(player, seq, botName, nil)) end
    return true
end

-- Single committer for bot removes. Idempotent; intent-aware.
local function WorldRemoveBot(player, botName, seq)
    local name = player:GetName()
    if botName and botName ~= "" then
        local target = Multistate.FindPlayerByName(botName)
        if target then target:RemoveEvents() end
        ShadowSetMaster(botName, nil)
        Multistate.SetData(player, "ShadowsInternalCmd", botName)
        player:RunCommand(".shadows bot remove " .. botName)
    end
    if seq then
        local v = WorldIntentHello(player, seq, nil, botName)
        v.view = "remove"
        WorldSendView(player, v)
    else
        ShadowSetBotCount(player, #ShadowGetBots(name))
    end
    return true
end

-- World op dispatcher (HandleWorldOp assignment). All DB and shared-var
-- work happens here, in the world state. Mutating ops answer with views.
HandleWorldOp = function(player, data)
    if not player or not data or not data.op then return end
    local op = data.op
    local name = player:GetName()

    if op == "open" then
        WorldSendView(player, WorldHelloView(player, data.seq))
    elseif op == "removemenu" then
        WorldSendView(player, {
            view = "remove", seq = data.seq, playerName = name,
            count = #ShadowGetBots(name),
            max = WorldMaxBots(player),
            barReady = Multistate.GetData(player, "ShadowBarStatusChecked") and true or false,
            bots = ShadowGetBots(name),
        })
    elseif op == "addmenu" then
        local accountId = player:GetAccountId()
        local seq = data.seq
        local guidLow = player:GetGUIDLow()
        CharDBQueryAsync("SELECT name, race, class, gender, level FROM characters WHERE account = " .. accountId .. " ORDER BY level DESC, name ASC", function(query)
            local p = GetPlayerByName(name)
            if not p then return end
            local owned = {}
            local ownedQuery = CharDBQuery("SELECT bot_name FROM acore_eluna.shadows_bots WHERE master_name = '" .. name .. "'")
            if ownedQuery then
                repeat owned[ownedQuery:GetString(0)] = true until not ownedQuery:NextRow()
            end
            local grouped = {}
            local grp = p:GetGroup()
            if grp then
                for _, m in ipairs(grp:GetMembers()) do grouped[m:GetName()] = true end
            end
            local pLevel = p:GetLevel()
            local rows = {}
            if query then
                repeat
                    local cName = query:GetString(0)
                    local cLevel = query:GetUInt8(4)
                    if cName ~= name and not owned[cName] and not grouped[cName] then
                        local tier = 0
                        if cLevel >= minShadowsLevel and cLevel > 9 and math.abs(pLevel - cLevel) <= 10 then
                            tier = 1
                        elseif cLevel >= minShadowsLevel and math.abs(pLevel - cLevel) <= 10 then
                            tier = 2
                        end
                        if tier > 0 then
                            table.insert(rows, {
                                name = cName,
                                race = query:GetUInt8(1),
                                class = query:GetUInt8(2),
                                gender = query:GetUInt8(3),
                                level = cLevel,
                                tier = tier,
                            })
                        end
                    end
                until not query:NextRow()
            end
            local hv = WorldHelloView(p, seq)
            hv.view = "add"
            hv.available = rows
            WorldSendView(p, hv)
        end)
    elseif op == "add" then
        WorldAddBot(player, data.botName, data.seq, true, data.reqTime)
    elseif op == "remove" then
        WorldRemoveBot(player, data.botName, data.seq)
    elseif op == "mapenter" then
        if ShadowGetMaster(name) then return end
        local bots = ShadowGetBots(name)
        if #bots == 0 then return end
        if player:IsDead() then return end
        if not player:IsInGroup() then return end
        if player:InArena() or player:InBattleground() then return end
        if os.time() <= (ShadowGetLastTeleTime(player) or 0) then return end
        ShadowSetLastTeleTime(player, os.time() + 1)
        WorldSendView(player, { view = "follow", seq = data.seq, playerName = name, bots = bots })
    elseif op == "zonecheck" then
        if ShadowGetMaster(name) then return end
        if ShadowGetBotCount(player) <= 0 then return end
        for _, zone in pairs(disallowedZones) do
            if data.zone == zone or data.area == zone then
                local doRemove = false
                for _, botName in ipairs(ShadowGetBots(name)) do
                    local bot = Multistate.FindPlayerByName(botName)
                    if bot then bot:RemoveFromGroup() end
                    ShadowSetMaster(botName, nil)
                    doRemove = true
                end
                ShadowSetBotCount(player, 0)
                if doRemove then
                    player:RegisterEvent(function(eventId, delay, repeats, pl)
                        if pl then
                            pl:SendAreaTriggerMessage("You cannot use shadows in "..GetAreaName(pl:GetAreaId())..".")
                        end
                    end, 100, 1)
                end
            end
        end
    elseif op == "savebar" then
        local guid = player:GetGUIDLow()
        if ShadowGetBarData(player) then
            CharDBExecute("REPLACE INTO acore_eluna.character_custom_data (guid, type, time, data) VALUES ("..guid..", 98, "..os.time()..", 'ENABLED')")
        else
            CharDBExecute("REPLACE INTO acore_eluna.character_custom_data (guid, type, time, data) VALUES ("..guid..", 98, "..os.time()..", 'DISABLED')")
        end
    elseif op == "wgcheck" then
        local war = IsWintergraspWarTime()
        if war and not _wgWasWarWorld then
            ProcessWintergraspWorldstate(3801, 0)
        end
        _wgWasWarWorld = war
    end
end

local function OnBotCommand(event, player, command)
    if command == "shadowsmenu" then
        WorldSendView(player, WorldHelloView(player, nil))
        return false
    end
    if string.find(command, "^playerb") then
        if string.find(command, "^shadows bot add ") then
            local botName = string.match(command, "^shadows bot add (.+)$")
            if botName and Multistate.GetData(player, "ShadowsInternalCmd") == botName then
                Multistate.ClearData(player, "ShadowsInternalCmd")
                return true
            end
            return WorldAddBot(player, botName, nil, false, nil)
        end

        if string.find(command, "^shadows bot remove ") then
            local botName = string.match(command, "^shadows bot remove (.+)$")
            if botName and Multistate.GetData(player, "ShadowsInternalCmd") == botName then
                Multistate.ClearData(player, "ShadowsInternalCmd")
                return true
            end
            return WorldRemoveBot(player, botName, nil)
        end
        return false
    end

	if command == "shadowslogin" then
		if ShadowGetLoginTime(player) and (ShadowGetLoginTime(player) < os.time() + 5) then
			local accountId = player:GetAccountId()
			local name = player:GetName()
			
			CharDBQueryAsync("SELECT name FROM characters WHERE account = " .. accountId .. " AND name != '" .. name .. "'", function(query)
				if query then
					local characters = {}
					repeat
						local characterName = query:GetString(0)
						table.insert(characters, characterName)
					until not query:NextRow()
					
					local bots = table.concat(characters, ", ")
					local player = GetPlayerByName(name)
					if player then
						player:SendAddonMessage("Shadows", bots, 7, player)
					end
				end
			end)
		end
		return false
	end
	
	if command == "shadowsbaron" then
		ShadowSetBarData(player, true)
		player:SendBroadcastMessage("Automatic shadows bar enabled.")
		return false
	elseif command == "shadowsbaroff" then
		ShadowSetBarData(player, false)
		player:SendBroadcastMessage("Automatic shadows bar disabled.")
		return false
	elseif command == "shadowsbarstatus" then
		Multistate.SetData(player, "ShadowBarStatusChecked", true)
		if not player:IsInGroup() then
			if ShadowGetBarData(player) then
				player:SendAddonMessage("ShadowsBar", "OPEN", 7, player)
			else
				player:SendAddonMessage("ShadowsBar", "CLOSED", 7, player)
			end
		else
			local group = player:GetGroup()
			local groupPlayers = group:GetMembers()
			local foundBot = false
			for _, groupMember in ipairs(groupPlayers) do
				local name = groupMember:GetName()
				if ShadowGetMaster(name) == player:GetName() and ShadowGetBarData(player) then
					player:SendAddonMessage("ShadowsBar", "ENABLED", 7, player)
					foundBot = true
					break
				end
			end
			if not foundBot then
				if ShadowGetBarData(player) then
					player:SendAddonMessage("ShadowsBar", "OPEN", 7, player)
				else
					player:SendAddonMessage("ShadowsBar", "CLOSED", 7, player)
				end
			end
		end
		return false
	end

	if string.find(command, "attemptaddbot ") then

	    local bots = string.match(command, "attemptaddbot (.+)$")
	    local botNames = {}
		local maxBotsForPlayer = maxBotCount
	   
	    for botName in string.gmatch(bots, "([^,]+)") do
		    botName = string.gsub(botName, "^%s*(.-)%s*$", "%1")
			table.insert(botNames, botName)
	    end
		
	   
	   if player:IsInGroup() then
		   
		   if Multistate.GetData(player, "VIPTime") and Multistate.GetData(player, "VIPTime") > os.time() then
				maxBotsForPlayer = maxVIPCount
		   end
		   
		   if #botNames > maxBotsForPlayer then
			   player:SendBroadcastMessage("We could not log in your shadows as the total shadows in your group exceeds your limit of "..maxBotCount..".")
			   return false
		   end
		   
		   local playerGuid = player:GetGUIDLow()
		   
		   for _, botName in ipairs(botNames) do
		 	   WorldAddBot(player, botName, nil, false, nil)
		    end
	    end
	    return false
	end

end

local function OnPlayerMapEnter(event, map, player)
    -- Multistate: server event 21 fires in map states. No DB here; world
    -- answers with a follow view naming the bots to pull.
    player:SendEMQMessage("ShadowsToWorld", { op = "mapenter", playerName = player:GetName() })
end

local function OnDisallowedZones(event, player, newZone, newArea)
    -- Multistate: player event 27 fires in map states. No DB here; world
    -- owns the bulk remove and messages the player directly.
    if player:IsDead() then
        return
    end
    player:SendEMQMessage("ShadowsToWorld", { op = "zonecheck", playerName = player:GetName(), zone = newZone, area = newArea })
end

local function OnGroupChangeLeader(event, packet, player)
    if not player:IsInGroup() then return end
    
    local group = player:GetGroup()
    
    for _, player in ipairs (group:GetMembers()) do
        local name = player:GetName()

        if ShadowGetMaster(name) then

            local masterName = ShadowGetMaster(name)
            local master

            if masterName then master = Multistate.FindPlayerByName(masterName) end

            if not master then return end
            if group:IsLeader(player:GetGUID()) then
                if player:IsInSameGroupWith(master) or player:IsInSameRaidWith(master) then

                    -- Multistate: the packet handler runs world-side, but
                    -- player:RegisterEvent timers can tick in map states where
                    -- the Group API is unavailable. Defer on a world (global)
                    -- timer and re-resolve everything by name.
                    local playerName = player:GetName()
                    CreateLuaEvent(function()
                        local player = GetPlayerByName(playerName)
                        if not player then return end
                        local group = player:GetGroup()
                        if not group then return end

                        local name = player:GetName()

                        local masterName = ShadowGetMaster(name)
                        local master

                        if masterName then master = Multistate.FindPlayerByName(masterName) end
            
                        group:SetLeader(master:GetGUID())

                    end, 1000)
                    
                    break
                end
            end
        end
    end
end

function ProcessWintergraspWorldstate(variableID, value) -- Called on init and update worldstate 3801
    if value == 0 then
        Multistate.ForEachPlayer(function(player)
            if (player:GetMapId() == 571) and (player:GetZoneId() == 4197) then
                local playerName = player:GetName()

                if not ShadowGetMaster(playerName) then
                    local master = player

                    if master and ShadowGetBotCount(master) > 0 then

                        local botsToRemove = {}
                        for i, botName in ipairs(ShadowGetBots(master:GetName())) do
                            table.insert(botsToRemove, botName)
                        end

                        if #botsToRemove > 0 then
                            for _, botName in ipairs(botsToRemove) do
                                local bot = Multistate.FindPlayerByName(botName)
                                if bot then
                                    bot:RemoveFromGroup()
                                end
                                master:RunCommand(".shadows bot remove " .. botName)
                                ShadowSetMaster(botName, nil)
                            end
                            ShadowSetBotCount(master, #ShadowGetBots(master:GetName()))
                            master:SendBroadcastMessage("Shadows are not permitted during active Wintergrasp battles. Your shadows have logged off.")
                            master:SendAreaTriggerMessage("Shadows are not permitted during active Wintergrasp battles. Your shadows have logged off.")
                        end
                    end
                end
            end
        end)
    end
end

-- Dismiss shadows on battle start. Northrend state only.
local _wgWasWar = false
local _wgWasWarWorld = false -- world-state edge flag for the EMQ-driven check
local function WGShadowWatch()
    if GetStateMapId() ~= 571 then return end
    local war = IsWintergraspWarTime()
    if war and not _wgWasWar then
        -- World executes; map only triggers (no DB here).
        local map = GetStateMap()
        if map then
            for _, p in ipairs(map:GetPlayers()) do
                if p then
                    p:SendEMQMessage("ShadowsToWorld", { op = "wgcheck", playerName = p:GetName() })
                    break
                end
            end
        end
    end
    _wgWasWar = war
end
if GetStateMapId() == 571 then
    CreateLuaEvent(WGShadowWatch, 15000, 0)
end

SetActiveVars()
RegisterPlayerEvent(3, ShadowsLogin)
RegisterPlayerEvent(4, LogoutOrSave)
RegisterPlayerEvent(25, LogoutOrSave)
RegisterPlayerEvent(19, OnWhisper)
RegisterPlayerEvent(20, OnGroup)
RegisterServerEvent(21, OnPlayerMapEnter)
RegisterPlayerEvent(27, OnDisallowedZones)
RegisterPlayerEvent(42, OnBotCommand)
RegisterPlayerGossipEvent(200, 2, ShadowsGossipSelect)
RegisterGroupEvent(3, LeaveGroup)
RegisterGroupEvent(5, DisbandGroup)
RegisterPacketEvent(0x075, 5, UninviteGroup)
RegisterPacketEvent(0x076, 5, UninviteGroupGUID)
RegisterPacketEvent(0x0C7, 5, PacketTeleDelay)
RegisterPacketEvent(0x0C9, 5, PacketMoveDelay)
RegisterPacketEvent(0x0CA, 5, PacketMoveDelay)
RegisterPacketEvent(0x0CB, 5, PacketMoveDelay)
RegisterPacketEvent(0x079, 7, OnGroupChangeLeader)