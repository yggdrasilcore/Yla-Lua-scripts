-- Multistate: login/logout/chat/command/packet handlers run globally, everything
-- else runs in map states. Cross-state coordination (summon handshake, referee
-- flag, referral sweep) uses shared player Data() and EMQ; progress itself
-- accumulates in account_raf via DB writes from every state.
local Multistate = require("Multistate")
local EMQ = require("EMQ")

-- Handlers defined below, assigned here so registration order is load-safe.
local HandleRAFWorld -- (player, data): runs in world, owns DB + commands
local HandleRAFView  -- (player, data): runs on map, pure render from payload
EMQ.RegisterQueue("RAFToWorld", function(player, data)
    if HandleRAFWorld and (Multistate.IsWorld() or Multistate.IsCompat()) then
        HandleRAFWorld(player, data)
    end
end)
EMQ.RegisterQueue("RAFToMap", function(player, data)
    if HandleRAFView and (Multistate.IsMap() or Multistate.IsCompat()) then
        HandleRAFView(player, data)
    end
end)

-- Welcome to Yggdrasil's RAF system, by mostly nick :)

-- START VARS
local RAFDuration 			= 60 * 24 * 60 * 60 -- RAF validity duration (60 * 24 * 60 * 60 = 60 days)
local ProgressCheckTimer 	= 5 				-- How often (in minutes) to check if RAF requirements are fulfilled, in minutes
local RAFRewardReq			= 7500				-- How many counts of "activity" to require to achieve RAF rewards (skill points earned, achievements earned, quests completed, area changes, creatures in level ranged killed, etc.)
local RewardTier1			= 5					-- How many referrals required to reach certain reward tiers
local RewardTier2			= 10
local RewardTier3			= 15
local RewardTier4			= 25
local RegisterRAFTimeLimit	= 1 				-- Time in hours to limit RAF linkage after starting to play
local summonCDLength		= 30				-- How many minutes the cooldown of the RAF summon is

-- AI-created pagination stuff
local ENTRIES_PER_PAGE 		= 10
local PAGINATION_INTID_START = 201
local SUMMON_PAGINATION_INTID_START = 701

-- Reward token settings
local TokenID 				= 19322
local TokenName 			= "Community Tokens"
local TokenReward 			= 5
-- END VARS
 
-- Map-side view cache: last payload delivered by world, per player name.
-- Menus render from here; clicks resolve rows here and forward via EMQ.
local rafViewCache        =   {}
local rafReqSeq           =   {}
local rafAckSeq           =   {}
local RAF_VIEW_TIMEOUT_MS =   6000
local playerProgress = {}

-- Create the account_raf table if it doesn't exist
AuthDBExecute([[
    CREATE TABLE IF NOT EXISTS acore_eluna.account_raf (
        account_id INT PRIMARY KEY,
        referer_id INT,
        status INT,
        progress INT DEFAULT 0,
        date INT,
        IP VARCHAR(15),
        IP_referer VARCHAR(15)
    )
]])

AuthDBExecute([[
    CREATE TABLE IF NOT EXISTS acore_eluna.account_raf_claimed (
        account_id INT,
        claimed INT,
		date INT
    )
]])

local function SendPurpleBroadcast(player, message)
    player:SendBroadcastMessage("|cFFEDFFC0" .. message .. "|r")
end

local function PlayerHasEnoughFreeSlots(player, requiredSlots)
	local freeSlots = 0

	for slot = 23, 38 do
		local item = player:GetItemByPos(255, slot)
		if not item then
			freeSlots = freeSlots + 1
		end
	end

	for bag = 19, 22 do
		local bagItem = player:GetItemByPos(255, bag)
		if bagItem then
			local bagSize = bagItem:GetBagSize()
			for slot = 0, bagSize - 1 do
				local item = player:GetItemByPos(bag, slot)
				if not item then
					freeSlots = freeSlots + 1
				end
			end
		end
	end

	print("Total free slots found: " .. freeSlots)
	return freeSlots >= requiredSlots
end

-- Pure map-side renders. World delivers every value in the view payload;
-- NOTHING here touches the DB or shared vars.
local function RAFTimeLeftText(date)
    local timeLeft = (date + RAFDuration) - os.time()
    if timeLeft <= 0 then
        return "Expired"
    end
    local daysLeft = math.floor(timeLeft / (24 * 60 * 60))
    local hoursLeft = math.floor((timeLeft % (24 * 60 * 60)) / 3600)
    if daysLeft > 0 then
        return string.format("%d days", daysLeft)
    elseif hoursLeft > 0 then
        return string.format("%d hours", hoursLeft)
    else
        return "less than 1 hour"
    end
end

local function ShowReferralInfoMenu(player, view)
    player:GossipClearMenu()
    local rows = (view and view.rows) or {}
    if #rows == 0 then
        player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_grouplooking:32:32:-22:0|tYou have no referrals.", 1, 2)
        player:GossipMenuAddItem(0, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 1, 998)
        player:GossipSendMenu(12, player, 1)
        return
    end
    local page = (view and view.page) or 1
    local totalPages = (view and view.totalPages) or 1
    for _, entry in ipairs(rows) do
        local statusText = (entry.status == 2) and "In progress" or "Completed"
        local progressText
        if not entry.progress or (entry.progress == 0 and statusText ~= "Completed") then
            progressText = 0
        elseif statusText == "Completed" then
            progressText = 100
        else
            progressText = string.format("%.2f", math.min(100, (entry.progress / RAFRewardReq * 100)))
        end
        player:GossipMenuAddItem(0, string.format("|TInterface/ICONS/inv_misc_groupneedmore:32:32:-22:0|tReferral ID: %d\n \nStatus: %s \nProgress: %d%% \nRAF active for: %s\n \n ",
            entry.refereeAccountId, statusText, progressText, RAFTimeLeftText(entry.date)), 1, 2)
    end
    if totalPages > 1 then
        if page > 1 then
            player:GossipMenuAddItem(0, "|TInterface/ICONS/Ability_Spy:32:32:-22:0|tPrevious Page", 1, PAGINATION_INTID_START + page - 1)
        end
        if page < totalPages then
            player:GossipMenuAddItem(0, "|TInterface/ICONS/Ability_Spy:32:32:-22:0|tNext Page", 1, PAGINATION_INTID_START + page + 1)
        end
        player:GossipMenuAddItem(0, string.format("|TInterface/ICONS/INV_Misc_Book_11:32:32:-22:0|tPage %d of %d", page, totalPages), 1, 2)
    end
    player:GossipMenuAddItem(0, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 1, 998)
    player:GossipSendMenu(12, player, 1)
end

local function ShowSummonFriendsMenu(player, view)
    player:GossipClearMenu()
    local cdSec = (view and view.cdSec) or 0
    local graceSec = (view and view.graceSec) or 0
    if graceSec > 0 then
        local minutesLeft = math.floor(cdSec / 60)
        local secondsLeft = cdSec % 60
        player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_pocketwatch_01:48:48:-26:0|tSummon grace timer!\n \nYou recently requested to summon someone. Time until you can send next request:\n\n"..minutesLeft.." minutes and "..secondsLeft.." seconds\n \nClick here to refresh cooldown.\n \n \n", 1, 7)
        player:GossipMenuAddItem(0, "|TInterface/ICONS/Trade_Engineering:48:48:-26:0|tBack", 1, 998)
        player:GossipSendMenu(12, player, 1)
    elseif cdSec > 0 then
        local minutesLeft = math.floor(cdSec / 60)
        local secondsLeft = cdSec % 60
        player:GossipMenuAddItem(0, "|TInterface/ICONS/spell_holy_borrowedtime:48:48:-26:0|tRAF summon cooldown:\n \n "..minutesLeft.." minutes and "..secondsLeft.." seconds\n \n", 1, 7)
        player:GossipMenuAddItem(0, "|TInterface/ICONS/Trade_Engineering:48:48:-26:0|tBack", 1, 998)
        player:GossipSendMenu(12, player, 1)
    else
        local rows = (view and view.friends) or {}
        local page = (view and view.page) or 1
        local totalPages = (view and view.totalPages) or 1
        if #rows == 0 then
            player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_grouplooking:48:48:-26:0|tYou have no friends to summon.", 1, 7)
            player:GossipMenuAddItem(0, "|TInterface/ICONS/Trade_Engineering:48:48:-26:0|tBack", 1, 998)
        else
            for _, friend in ipairs(rows) do
                player:GossipMenuAddItem(0, string.format("|TInterface/ICONS/spell_unused2:48:48:-26:0|tSummon %s", friend.name), 1, (friend.guid + 1000))
            end
            if totalPages > 1 then
                if page > 1 then
                    player:GossipMenuAddItem(0, "|TInterface/ICONS/Ability_Spy:48:48:-26:0|tPrevious Page", 1, SUMMON_PAGINATION_INTID_START + page - 1)
                end
                if page < totalPages then
                    player:GossipMenuAddItem(0, "|TInterface/ICONS/Ability_Spy:48:48:-26:0|tNext Page", 1, SUMMON_PAGINATION_INTID_START + page + 1)
                end
                player:GossipMenuAddItem(0, string.format("|TInterface/ICONS/INV_Misc_Book_11:32:32:-22:0|tPage %d of %d", page, totalPages), 1, 2)
            end
            player:GossipMenuAddItem(0, "|TInterface/ICONS/Trade_Engineering:48:48:-26:0|tBack", 1, 998)
        end
        player:GossipSendMenu(12, player, 1)
    end
end

local function ShowRefereeInfo(player, view)
    player:GossipClearMenu()
    if view and view.found then
        local statusText = (view.status == 2) and "In progress" or "Completed"
        local progressText
        if view.progress == 0 and statusText ~= "Completed" then
            progressText = 0
        elseif statusText == "Completed" then
            progressText = 100
        else
            progressText = (view.progress / RAFRewardReq * 100)
        end
        if progressText > 100 then
            progressText = 100
        end
        player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_groupneedmore:32:32:-22:0|tReferral status: \n \nYou're registered with the following referral information:\n \nReferer ID: ".. view.refererAccountId ..". \n \nStatus: " .. statusText .." \n \nProgress towards rewards: " .. progressText .."%.\n \nReferral program time left: " .. RAFTimeLeftText(view.date)..".\n \n", 1, 3)
        player:GossipMenuAddItem(0, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 1, 998)
    else
        player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_grouplooking:32:32:-22:0|t Referral status:\n \nYou have not been registered as a referred player.\n \n", 1, 3)
        player:GossipMenuAddItem(0, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 1, 998)
    end
    player:GossipSendMenu(12, player, 1)
end

local function ShowRAFMenu(player)
    player:GossipClearMenu()
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_valentinescard02:32:32:-22:0|tRegister referal", 1, 1)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_groupneedmore:32:32:-22:0|tSee my referred friends", 1, 2)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_grouplooking:32:32:-22:0|tSee my referee status", 1, 3)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_box_02:32:32:-22:0|tClaim referral bonuses", 1, 4)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/spell_unused2:32:32:-22:0|tSummon my RAF friend", 1, 7)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tClose RAF menu", 1, 5)
    player:GossipSendMenu(12, player, 1)
end

local function ClaimBonuses(player, view)
    player:GossipClearMenu()
    local comp = (view and view.comp) or {"In progress", "In progress", "In progress", "In progress", "In progress"}
    local claim = (view and view.claim) or {".", ".", ".", ".", "."}
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_rune_07:32:32:-22:0|tFirst referral reward:\n \nStatus: "..comp[1]..""..claim[1].."\n \nContains: 5 Community Tokens\n \n ", 1, 40)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_box_01:32:32:-22:0|tReward box 1:\n \nRequirement: ".. RewardTier1 .." referrals.\nStatus: "..comp[2]..""..claim[2].."\n \nContains:\n- Rotface and Festergut's Acidic Blood\n- Unobtainable Vanilla mounts\n- Fishing Chair\n- 60 Emblems of Frost\n \n ", 1, 41)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_box_02:32:32:-22:0|tReward box 2:\n \nRequirement: ".. RewardTier2 .." referrals.\nStatus: "..comp[3]..""..claim[3].."\n \nContains:\n- X-53 Touring Rocket\n- Hard-to-get mounts\n- ToC trinkets and cloaks\n- 95 Emblems of Frost\n \n ", 1, 42)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_box_03:32:32:-22:0|tReward box 3:\n \nRequirement: ".. RewardTier3 .." referrals.\nStatus: "..comp[4]..""..claim[4].."\n \nContains:\n- ICC 25 heroic weapons\n- ICC 25 normal trinkets\n- Ashes of Al'ar\n- 95 Emblems of Frost and 1 Sanctification Mark\n \n ", 1, 43)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_box_04:32:32:-22:0|tReward box 4:\n \nRequirement: ".. RewardTier4 .." referrals.\nStatus: "..comp[5]..""..claim[5].."\n \nContains:\n- Sea Turtle mount\n- Unobtainable mounts\n- 50 Community Tokens\n \n ", 1, 44)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 1, 998)
    player:GossipSendMenu(12, player, 1)
end

local function ShowRAFLink(player, view)
    player:GossipClearMenu()
    local accountId = player:GetAccountId()
    if view and view.linked then
        player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_valentinescard02:32:32:-22:0|tI am a new player\n \nClick here to link up with the friend that refered you.\n \n", 1, 10, true, "You are already linked to a referer!\n\nAre you sure you want to change your link?\n\n Accepting will reset your progress towards your referal reward!")
    else
        player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_valentinescard02:32:32:-22:0|tI am a new player, link me to my referer", 1, 10, true, "Please enter the referral ID from your friend. Only enter numbers.")
    end
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_groupneedmore:32:32:-22:0|tHow to refer your friends: \n \nTo refer your friends, you must share your friend referral code with them. \n \nYour referral code is: ".. accountId ..".\n \nAfter they create their account, they must log in and speak to their Twiggy to enter this code at the new player button above.\n \n", 1, 1)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 1, 998)
    player:GossipSendMenu(12, player, 1)
end

local function ShowSummonRequest(player, view)
    local summonerName = (view and view.summoner) or ""
    local area = (view and view.area) or ""
    player:GossipClearMenu()
    player:GossipMenuAddItem(0, "|TInterface/ICONS/spell_unused2:48:48:-26:0|tIncoming summon request!\n \n" .. summonerName .. " wants to summon you to "..area.."! Do you accept?\n \n", 1, 500)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_groupneedmore:48:48:-26:0|tYes\n \n", 1, 501)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_grouplooking:48:48:-26:0|tNo\n \n", 1, 502)
    player:GossipSendMenu(12, player, 1)
end

local function Reward41(player)
    player:GossipClearMenu()
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_box_01:32:32:-22:0|tRewards box 1: ".. RewardTier1 .." friends\n ", 1, 41)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/spell_shadow_bloodboil:32:32:-22:0|tOption 1: Quest items\n \nRotface and Festergut's bloods\n \n", 1, 411)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/ability_mount_jungletiger:32:32:-22:0|tOption 2: Mount \n \nLeopard (60% speed)\n \n", 1, 412)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/ability_mount_jungletiger:32:32:-22:0|tOption 3: Mount \n \nBengal Tiger (60% speed)\n \n", 1, 413)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/ability_mount_drake_bronze:32:32:-22:0|tOption 4: Mount \n \nBrazen Taxi (flightless dragon with 100% speed and permanent Slow Fall)\n \n", 1, 414)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/ability_mount_undeadhorse:32:32:-22:0|tOption 5: Mount \n \nNaxxramas Deathcharger (100% speed)\n \n", 1, 416)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_fishingchair:32:32:-22:0|tOption 6: Toy \n \nFishing Chair\n \n", 1, 415)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_frostemblem_01:32:32:-22:0|tOption 7: Emblems\n \n60 Emblems of Frost\n \n", 1, 417)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 1, 4)
    player:GossipSendMenu(12, player, 1)
end
local function Reward42(player)
    player:GossipClearMenu()
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_box_02:32:32:-22:0|tReward box 2: ".. RewardTier2 .." friends\n ", 1, 42)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/ability_mount_rocketmount2:32:32:-22:0|tOption 1: Mount\n \nX-53 Touring Rocket (adaptable speed)\n \n", 1, 421)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv-mount_raven_54:32:32:-22:0|tOption 2: Mount\n \nReins of the Raven Lord (100% speed)\n \n", 1, 422)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/ability_mount_raptor:32:32:-22:0|tOption 3: Mount\n \nSwift Razzashi Raptor (100% speed)\n \n", 1, 423)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/ability_mount_jungletiger:32:32:-22:0|tOption 4: Mount\n \nSwift Zulian Tiger\n \n", 1, 424)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/ability_druid_challangingroar:32:32:-22:0|tOption 5: Mount\n \nBig Battle Bear\n \n", 1, 425) -- Amani War bear? Replaced with unobtainable bear
    player:GossipMenuAddItem(0, "|TInterface/ICONS/ability_mount_mammoth_brown:32:32:-22:0|tOption 6: Mount\n \nTraveler's Tundra Mammoth\n \n", 1, 426)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/achievement_dungeon_ulduar77_25man:32:32:-22:0|tOption 7: Item\n \nAlliance: Solace of the Fallen (Normal)\nHorde: Solace of the Defeated (Normal)\n \n", 1, 427)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_cape_16:32:32:-22:0|tOption 8: Item\n \nAlliance: Cloak of the Silver Covenant (Normal)\nHorde: Cloak of Serrated Blades (Normal)\n \n", 1, 428)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_scarab_crystal:32:32:-22:0|tOption 9: Item\n \nAlliance: Satrina's Impeding Scarab (Normal)\nHorde: Juggernaut's Vitality (Normal)\n \n", 1, 429)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_bone_skull_02:32:32:-22:0|tOption 10: Item\n \nAlliance: Death's Verdict (Normal)\nHorde: Death's Choice (Normal)\n \n", 1, 460)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/spell_holy_summonlightwell:32:32:-22:0|tOption 11: Item\n \nFlare of the Heavens (Normal)\n \n", 1, 461)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_frostemblem_01:32:32:-22:0|tOption 12: Emblems\n \n95 Emblems of Frost\n \n", 1, 462)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 1, 4)
    player:GossipSendMenu(12, player, 1)
end
local function Reward43(player)
    player:GossipClearMenu()
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_box_03:32:32:-22:0|tReward box 3: ".. RewardTier3 .." friends\n \n", 1, 43)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_staff_109:32:32:-22:0|tOption 1: Item\n \nNibelung (Heroic)\n \n", 1, 431)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_axe_120:32:32:-22:0|tOption 2: Item\n \n Bryntroll, the Bone Arbiter (Heroic)\n \n", 1, 432) 
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_weapon_bow_55:32:32:-22:0|tOption 3: Item\n \n Zod's Repeating Longbow (Heroic)\n \n", 1, 433)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_weapon_shortblade_103:32:32:-22:0|tOption 4: Item\n \n Heartpierce (Heroic)\n \n", 1, 434)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_weapon_hand_33:32:32:-22:0|tOption 5: Item\n \n Black Bruise (Heroic)\n \n", 1, 435)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_staff_107:32:32:-22:0|tOption 6: Item\n \n Distant Land (Heroic)\n \n", 1, 436)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_staff_106:32:32:-22:0|tOption 7: Item\n \n Dying Light (Heroic)\n \n", 1, 437)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_jewelry_trinket_04:32:32:-22:0|tOption 8: Item\n \n Deathbringer's Will (Normal)\n \n", 1, 439)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_jewelry_trinket_02:32:32:-22:0|tOption 9: Item\n \n Althor's Abacus (Normal)\n \n", 1, 470)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_jewelry_trinket_01:32:32:-22:0|tOption 10: Item\n \n Dislodged Foreign Object (Normal)\n \n", 1, 471)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_jewelry_trinket_06:32:32:-22:0|tOption 11: Item\n \n Sindragosa's Flawless Fang (Normal)\n \n", 1, 472)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_summerfest_brazierorange:32:32:-22:0|tOption 12: Mount\n \nAshes of Al'ar", 1, 438)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_frostemblem_01:32:32:-22:0|tOption 13: Emblems and Mark\n \n95 Emblems of Frost and 1x Mark of Sanctification", 1, 473)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 1, 4)
    player:GossipSendMenu(12, player, 1)
end
local function Reward44(player)
    player:GossipClearMenu()
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_box_04:32:32:-22:0|tReward box 4: ".. RewardTier4 .." referrals:\n.", 1, 44)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_fish_turtle_02:32:32:-22:0|tOption 1: Mount\n \n Sea Turtle (slow on land, fast in water)\n \n", 1, 441)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/ability_mount_drake_proto:32:32:-22:0|tOption 2: Mount\n \nBlack Proto Drake mount\n \n", 1, 442)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/ability_mount_rocketmount:32:32:-22:0|tOption 3: Mount\n \nX-51 Nether-Rocket X-TREME\n \n", 1, 443)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/ability_mount_netherdrakeelite:32:32:-22:0|tOption 4: Mount\n \nSwift Nether Drake\n \n", 1, 444)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/ability_mount_netherdrakeelite:32:32:-22:0|tOption 5: Mount\n \nVengeful Nether Drake mount\n \n", 1, 445) 
    player:GossipMenuAddItem(0, "|TInterface/ICONS/ability_mount_netherdrakeelite:32:32:-22:0|tOption 6: Mount\n \nMerciless Nether Drake mount\n \n", 1, 446)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_rune_07:32:32:-22:0|tOption 7: Tokens\n \n50 Community Tokens\n \n", 1, 447)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 1, 4)
    player:GossipSendMenu(12, player, 1)
end
-- Option intid -> item for tiers with plain item grants.
local function RAFClaimItem(tier, option)
    local tables = {
        [2] = { [421] = 54860, [422] = 32768, [423] = 19872, [424] = 19902,
                [425] = 49282, [426] = 44234, [427] = 47271, [428] = 48668,
                [429] = 47290, [460] = 47303, [461] = 45518 },
        [3] = { [431] = 50725, [432] = 50709, [433] = 50638, [434] = 50641,
                [435] = 50692, [436] = 50695, [437] = 50725, [438] = 32458,
                [439] = 50362, [470] = 50366, [471] = 50353, [472] = 50364 },
        [4] = { [441] = 46109, [442] = 44164, [443] = 35226, [444] = 30609,
                [445] = 37676, [446] = 34092 },
    }
    return tables[tier] and tables[tier][option] or nil
end

-- Grants the approved claim on the map (entity APIs only). World verified
-- eligibility and recorded the claim before approving.
local function GrantRAFReward(player, tier, option)
    if tier == 0 then
        player:AddItem(19322, 5)
        SendPurpleBroadcast(player, "Twiggy: You've been rewarded "..TokenReward.." "..TokenName.."!")
    elseif tier == 1 then
        player:AddItem(19322, 5)
        if option == 411 then
            player:AddItem(50226, 1)
            player:AddItem(50231, 1)
            SendPurpleBroadcast(player, "Twiggy: You've been rewarded "..TokenReward.." "..TokenName..", Rotface's Acidic Blood and Festergut's Acidic Blood!")
        elseif option == 412 then
            player:LearnSpell(10788)
            SendPurpleBroadcast(player, "Twiggy: You've been rewarded "..TokenReward.." "..TokenName.." and " .. GetItemLink(8633) .. "!")
        elseif option == 413 then
            player:LearnSpell(10790)
            SendPurpleBroadcast(player, "Twiggy: You've been rewarded "..TokenReward.." "..TokenName.." and " .. GetItemLink(8630) .. "!")
        elseif option == 417 then
            player:AddItem(49426, 60)
            SendPurpleBroadcast(player, "Twiggy: You've been rewarded "..TokenReward.." "..TokenName.." and 60 " .. GetItemLink(49426) .. "!")
        else
            local items = { [414] = 20221, [415] = 33223, [416] = 23193 }
            local itemId = items[option]
            if itemId then
                player:AddItem(itemId, 1)
                SendPurpleBroadcast(player, "Twiggy: You've been rewarded "..TokenReward.." "..TokenName.." and " .. GetItemLink(itemId) .. "!")
            end
        end
    elseif tier == 2 then
        local race = player:GetRace()
        player:AddItem(19322, 5)
        if option == 428 and (race == 1 or race == 3 or race == 4 or race == 7 or race == 11) then
            player:AddItem(48673, 1)
        elseif option == 429 and (race == 1 or race == 3 or race == 4 or race == 7 or race == 11) then
            player:AddItem(47080, 1)
        elseif option == 460 and (race == 1 or race == 3 or race == 4 or race == 7 or race == 11) then
            player:AddItem(47115, 1)
        elseif option == 461 and (race == 1 or race == 3 or race == 4 or race == 7 or race == 11) then
            player:AddItem(47041, 1)
        elseif option == 462 then
            player:AddItem(49426, 95)
        elseif option ~= nil then
            player:AddItem(RAFClaimItem(option), 1)
        end
        local itemLink = GetItemLink(RAFClaimItem(option))
        if option == 462 then
            SendPurpleBroadcast(player, "Twiggy: You've been rewarded "..TokenReward.." "..TokenName.." and 95 " .. itemLink .. "!")
        else
            SendPurpleBroadcast(player, "Twiggy: You've been rewarded "..TokenReward.." "..TokenName.." and " .. itemLink .. "!")
        end
    elseif tier == 3 then
        local class = player:GetClass()
        player:AddItem(19322, 5)
        if option == 473 then
            player:AddItem(49426, 95)
            if class == 4 or class == 6 or class == 8 or class == 11 then
                player:AddItem(52025, 1)
            elseif class == 1 or class == 3 or class == 7 then
                player:AddItem(52026, 1)
            else
                player:AddItem(49426, 1)
            end
            SendPurpleBroadcast(player, "Twiggy: You've been rewarded "..TokenReward.." "..TokenName..", 95 Emblems of Frost, and 1x Mark of Sanctification!")
        else
            player:AddItem(RAFClaimItem(option), 1)
            SendPurpleBroadcast(player, "Twiggy: You've been rewarded "..TokenReward.." "..TokenName.." and " .. GetItemLink(RAFClaimItem(option)) .. "!")
        end
    elseif tier == 4 then
        if option == 447 then
            player:AddItem(19322, 50)
            SendPurpleBroadcast(player, "Twiggy: You've been rewarded 50 "..TokenName.."!")
        else
            player:AddItem(RAFClaimItem(option), 1)
            player:AddItem(19322, 5)
            SendPurpleBroadcast(player, "Twiggy: You've been rewarded "..TokenReward.." "..TokenName.." and " .. GetItemLink(RAFClaimItem(option)) .. "!")
        end
    end
end

-- Loading placeholder. Intid 11 is a dedicated no-op.
local function RAFShowLoading(player, text)
    text = text or "Loading, one moment..."
    player:GossipClearMenu()
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_groupneedmore:32:32:-22:0|t" .. text .. "\n \n", 1, 11)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 1, 998)
    player:GossipSendMenu(12, player, 1)
end

local function RAFCacheView(playerName, view)
    local c = rafViewCache[playerName] or {}
    if view.view == "referralinfo" then
        c.referral = view
    elseif view.view == "summonfriends" then
        c.summon = view
    elseif view.view == "refereeinfo" then
        c.referee = view
    elseif view.view == "raflink" then
        c.link = view
    elseif view.view == "bonuses" or view.view == "claimapproved" then
        c.bonuses = view
    elseif view.view == "summonrequest" then
        c.request = view
    end
    rafViewCache[playerName] = c
    rafAckSeq[playerName] = view.seq
end

-- Map -> world request. Only the matching answer renders.
local function MapSendRAF(player, op, params)
    local name = player:GetName()
    local seq = (rafReqSeq[name] or 0) + 1
    rafReqSeq[name] = seq
    local data = { op = op, seq = seq, playerName = name }
    if params then
        for k, v in pairs(params) do
            data[k] = v
        end
    end
    player:SendEMQMessage("RAFToWorld", data)
    player:RegisterEvent(function(eventId, delay, repeats, pl)
        if pl and rafAckSeq[pl:GetName()] ~= seq and rafReqSeq[pl:GetName()] == seq then
            pl:SendAreaTriggerMessage("RAF service timed out, please reopen the menu.")
            ShowRAFMenu(pl)
        end
    end, RAF_VIEW_TIMEOUT_MS, 1)
end

-- Map-side view dispatcher. Stale answers are dropped.
HandleRAFView = function(player, data)
    if not player or not data then
        return
    end
    local name = data.playerName or player:GetName()
    if data.seq ~= nil and data.seq ~= rafReqSeq[name] then
        return
    end
    RAFCacheView(name, data)
    rafAckSeq[name] = rafReqSeq[name]
    if data.view == "hub" then
        ShowRAFMenu(player)
    elseif data.view == "referralinfo" then
        ShowReferralInfoMenu(player, data)
    elseif data.view == "summonfriends" then
        ShowSummonFriendsMenu(player, data)
    elseif data.view == "refereeinfo" then
        ShowRefereeInfo(player, data)
    elseif data.view == "raflink" then
        ShowRAFLink(player, data)
    elseif data.view == "bonuses" then
        ClaimBonuses(player, data)
    elseif data.view == "claimapproved" then
        GrantRAFReward(player, data.tier, data.option)
        ClaimBonuses(player, data)
    elseif data.view == "summonrequest" then
        ShowSummonRequest(player, data)
    elseif data.view == "teleport" then
        player:Teleport(data.map, data.x, data.y, data.z, data.o)
        player:GossipComplete()
    end
end


-- Claim option intid -> reward tier. Unknown intids claim nothing.
local RAFClaimTiers = {}
for _, i in ipairs({411,412,413,414,415,416,417}) do RAFClaimTiers[i] = 1 end
for _, i in ipairs({421,422,423,424,425,426,427,428,429,460,461,462}) do RAFClaimTiers[i] = 2 end
for _, i in ipairs({431,432,433,434,435,436,437,438,439,470,471,472,473}) do RAFClaimTiers[i] = 3 end
for _, i in ipairs({441,442,443,444,445,446,447}) do RAFClaimTiers[i] = 4 end
local function RAFClaimIntid(intid)
    return RAFClaimTiers[intid]
end

local function OnGossipSelect(event, player, object, sender, intid, code, menu_id)
    -- Map side: no DB or shared vars. Static navigation renders directly;
    -- everything else resolves rows from the cached view and forwards via EMQ.
    local name = player:GetName()
    local cache = rafViewCache[name] or {}

    if intid == 11 then -- loading-header no-op
        return
    end

    if intid > 1000 then -- summon friend: guid -> name from cache
        local friendGUIDLow = intid - 1000
        local target
        for _, f in ipairs(((cache.summon or {}).friends) or {}) do
            if f.guid == friendGUIDLow then target = f break end
        end
        if not target then
            RAFShowLoading(player, "Loading, one moment...")
            MapSendRAF(player, "open-summon", { page = 1 })
            return
        end
        if player:IsFlying() or player:IsOnVehicle()
        or player:IsFalling() or player:IsInCombat()
        or player:IsDead() or player:InArena()
        or player:InBattleground() then
            player:SendAreaTriggerMessage("You can't summon your friend right now!")
            return
        end
        RAFShowLoading(player, "Sending summon request, one moment...")
        MapSendRAF(player, "summon", { guid = friendGUIDLow })
    elseif intid >= PAGINATION_INTID_START and intid < PAGINATION_INTID_START + 99 then
        RAFShowLoading(player, "Loading, one moment...")
        MapSendRAF(player, "open-info", { page = intid - PAGINATION_INTID_START })
    elseif intid >= SUMMON_PAGINATION_INTID_START and intid < SUMMON_PAGINATION_INTID_START + 99 then
        RAFShowLoading(player, "Loading, one moment...")
        MapSendRAF(player, "open-summon", { page = intid - SUMMON_PAGINATION_INTID_START })
    elseif intid == 500 then
        if cache.request then
            ShowSummonRequest(player, cache.request)
        else
            player:GossipComplete()
        end
    elseif intid == 501 then
        RAFShowLoading(player, "Accepting summon, one moment...")
        MapSendRAF(player, "accept", {})
    elseif intid == 502 then
        player:GossipComplete()
        player:SendEMQMessage("RAFToWorld", { op = "decline", playerName = name })
    elseif intid == 1 then
        RAFShowLoading(player, "Loading, one moment...")
        MapSendRAF(player, "open-link", {})
    elseif intid == 10 then
        RAFShowLoading(player, "Linking, one moment...")
        MapSendRAF(player, "register", { code = code })
    elseif intid == 2 then
        RAFShowLoading(player, "Loading, one moment...")
        MapSendRAF(player, "open-info", { page = 1 })
    elseif intid == 3 then
        RAFShowLoading(player, "Loading, one moment...")
        MapSendRAF(player, "open-referee", {})
    elseif intid == 4 then
        RAFShowLoading(player, "Loading, one moment...")
        MapSendRAF(player, "open-bonuses", {})
    elseif intid == 5 then
        player:GossipComplete()
    elseif intid == 6 then
        player:GossipComplete()
    elseif intid == 7 then
        RAFShowLoading(player, "Loading, one moment...")
        MapSendRAF(player, "open-summon", { page = 1 })
    elseif intid == 40 then
        if player:HasItem(19322, 1) or PlayerHasEnoughFreeSlots(player, 1) then
            RAFShowLoading(player, "Claiming, one moment...")
            MapSendRAF(player, "claim", { tier = 0 })
        end
    elseif intid == 41 then
        Reward41(player)
    elseif intid == 42 then
        Reward42(player)
    elseif intid == 43 then
        Reward43(player)
    elseif intid == 44 then
        Reward44(player)
    elseif RAFClaimIntid(intid) then
        local tier = RAFClaimIntid(intid)
        if PlayerHasEnoughFreeSlots(player, 3) then
            RAFShowLoading(player, "Claiming, one moment...")
            MapSendRAF(player, "claim", { tier = tier, option = intid })
        else
            player:SendBroadcastMessage("You need at least 3 free bag slots to receive your reward.")
            if cache.bonuses then
                ClaimBonuses(player, cache.bonuses)
            else
                ShowRAFMenu(player)
            end
        end
    elseif intid == 998 then
        ShowRAFMenu(player)
    end
end


-- World side: owns ALL DB and shared vars. Answers map requests with views.
local worldRAFClaimed = {}

local RAFTiers = {
    [0] = { need = 0, claimed = 1 },
    [1] = { need = 4, claimed = 5 },
    [2] = { need = 9, claimed = 10 },
    [3] = { need = 14, claimed = 15 },
    [4] = { need = 24, claimed = 25 },
}

local function WorldRAFView(player, seq, view)
    if not player or not view then return end
    view.seq = seq
    view.playerName = view.playerName or player:GetName()
    player:SendEMQMessage("RAFToMap", view)
end

local function RAFBonusStrings(claimed, n)
    local needs = {0, 4, 9, 14, 24}
    local vals = {1, 5, 10, 15, 25}
    local comp, claim = {}, {}
    for i = 1, 5 do
        if n > needs[i] then
            comp[i] = "Completed"
            claim[i] = claimed[vals[i]] and ", claimed." or ", claim now!"
        else
            comp[i] = "In progress"
            claim[i] = claimed[vals[i]] and ", claimed." or "."
        end
    end
    return comp, claim
end

local function WorldRAFBonuses(player, seq, extra)
    local accountId = player:GetAccountId()
    local name = player:GetName()
    AuthDBQueryAsync(string.format("SELECT claimed FROM acore_eluna.account_raf_claimed WHERE account_id = %d", accountId), function(claimquery)
        local claimed = {}
        if claimquery then
            repeat claimed[claimquery:GetUInt32(0)] = true until not claimquery:NextRow()
        end
        AuthDBQueryAsync(string.format("SELECT COUNT(*) FROM acore_eluna.account_raf WHERE referer_id = %d AND status = 4", accountId), function(cq)
            local p = GetPlayerByName(name)
            if not p then return end
            local n = 0
            if cq then n = cq:GetUInt32(0) end
            local comp, claim = RAFBonusStrings(claimed, n)
            local v = { view = "bonuses", comp = comp, claim = claim }
            if extra then for k, vv in pairs(extra) do v[k] = vv end end
            WorldRAFView(p, seq, v)
        end)
    end)
end

-- Single committer for claims. Serial in world; memory guard plus async DB
-- recheck means rapid double-clicks grant exactly once.
local function WorldRAFClaim(player, tier, option, seq)
    local accountId = player:GetAccountId()
    local name = player:GetName()
    local t = RAFTiers[tier]
    local function deny(msg)
        local p = GetPlayerByName(name)
        if not p then return end
        if msg then SendPurpleBroadcast(p, msg) end
        WorldRAFBonuses(p, seq, nil)
    end
    if not t then
        WorldRAFBonuses(player, seq, nil)
        return
    end
    if worldRAFClaimed[accountId .. ":" .. tier] then
        deny("Twiggy: You've already claimed this reward!")
        return
    end
    AuthDBQueryAsync(string.format("SELECT claimed FROM acore_eluna.account_raf_claimed WHERE account_id = %d", accountId), function(claimquery)
        local already = false
        if claimquery then
            repeat if claimquery:GetUInt32(0) == t.claimed then already = true end until not claimquery:NextRow()
        end
        if already then
            deny("Twiggy: You've already claimed this reward!")
            return
        end
        AuthDBQueryAsync(string.format("SELECT COUNT(*) FROM acore_eluna.account_raf WHERE referer_id = %d AND status = 4", accountId), function(cq)
            local p = GetPlayerByName(name)
            if not p then return end
            local n = 0
            if cq then n = cq:GetUInt32(0) end
            if n <= t.need then
                deny("Twiggy: You can't claim this reward yet!")
                return
            end
            AuthDBExecute(string.format("INSERT INTO acore_eluna.account_raf_claimed (account_id, claimed, date) VALUES (%d, %d, %d)", accountId, t.claimed, os.time()))
            worldRAFClaimed[accountId .. ":" .. tier] = true
            local claimed = {}
            claimed[t.claimed] = true
            local comp, claim = RAFBonusStrings(claimed, n)
            WorldRAFView(p, seq, { view = "claimapproved", tier = tier, option = option, comp = comp, claim = claim })
        end)
    end)
end

-- Summon menu payload. Online resolved authoritatively in world.
local function WorldRAFSummonMenu(player, seq, page)
    page = page or 1
    local accountId = player:GetAccountId()
    local name = player:GetName()
    local cdSec = math.max(0, (Multistate.GetData(player, "RAFSummonCD") or 0) - os.time())
    local graceSec = math.max(0, (Multistate.GetData(player, "RAFSummonGrace") or 0) - os.time())
    local MaxRAFDuration = os.time() - RAFDuration
    AuthDBQueryAsync(string.format([[
        SELECT account_id, referer_id FROM acore_eluna.account_raf
        WHERE (referer_id = %d AND date > %d) OR (account_id = %d AND date > %d)
    ]], accountId, MaxRAFDuration, accountId, MaxRAFDuration), function(query)
        local p = GetPlayerByName(name)
        if not p then return end
        local linked = {}
        if query then
            repeat
                linked[query:GetUInt32(0)] = true
                linked[query:GetUInt32(1)] = true
            until not query:NextRow()
        end
        local friends = {}
        for _, pl in ipairs(GetPlayersInWorld()) do
            if pl and linked[pl:GetAccountId()] and pl:GetName() ~= name then
                table.insert(friends, { name = pl:GetName(), guid = pl:GetGUIDLow() })
            end
        end
        table.sort(friends, function(a, b) return a.name < b.name end)
        local totalPages = math.max(1, math.ceil(#friends / ENTRIES_PER_PAGE))
        if page > totalPages then page = totalPages end
        local rows = {}
        for i = (page - 1) * ENTRIES_PER_PAGE + 1, math.min(page * ENTRIES_PER_PAGE, #friends) do
            table.insert(rows, friends[i])
        end
        WorldRAFView(p, seq, { view = "summonfriends", friends = rows, page = page, totalPages = totalPages, cdSec = cdSec, graceSec = graceSec })
    end)
end

-- Shared summon execution for the EMQ op and the chat command.
local function WorldRAFSummon(requester, friend, seq)
    local reqName = requester:GetName()
    local function ackMenu()
        if seq then WorldRAFSummonMenu(requester, seq, 1) end
    end
    if not friend then
        requester:SendBroadcastMessage("Your friend isn't online right now.")
        ackMenu()
        return
    end
    if (Multistate.GetData(requester, "RAFSummonCD") or 0) > os.time() then
        ackMenu()
        return
    end
    if friend and friend:IsAlive() and not friend:IsInCombat()
    and not friend:IsOnVehicle() and not friend:IsFalling()
    and not friend:InArena() and not friend:InBattleground() then
        Multistate.SetData(friend, "RAFSummonRequest", reqName)
        Multistate.SetData(friend, "RAFSummonTime", os.time() + 120)
        Multistate.SetData(requester, "RAFSummonCD", os.time() + 2 * 60)
        Multistate.SetData(requester, "RAFSummonGrace", os.time() + 2 * 60)
        WorldRAFView(friend, nil, { view = "summonrequest", summoner = reqName, area = GetAreaName(requester:GetAreaId()) })
        ackMenu()
    elseif friend then
        requester:SendBroadcastMessage(friend:GetName().." isn't able to receive summon requests right now.")
        ackMenu()
    else
        requester:SendBroadcastMessage("Your friend isn't online right now.")
        ackMenu()
    end
end

local function WorldRAFAccept(target, seq)
    local name = target:GetName()
    if os.time() >= (Multistate.GetData(target, "RAFSummonTime") or 0) + 120 then
        target:SendAreaTriggerMessage("You have not accepted the summon in time!")
        if seq then WorldRAFView(target, seq, { view = "hub" }) end
        return
    end
    local summonerName = Multistate.GetData(target, "RAFSummonRequest")
    local summoner = summonerName and GetPlayerByName(summonerName) or nil
    if not summoner then
        target:SendAreaTriggerMessage("Your friend isn't available to summon you anymore.")
        if seq then WorldRAFView(target, seq, { view = "hub" }) end
        return
    end
    if summoner:IsFlying() or summoner:IsOnVehicle()
    or summoner:IsFalling() or summoner:IsInCombat()
    or summoner:IsDead() or summoner:InArena()
    or summoner:InBattleground() then
        summoner:SendAreaTriggerMessage("You can't summon your friend right now!")
        target:SendAreaTriggerMessage("Your friend isn't available to summon you anymore.")
        if seq then WorldRAFView(target, seq, { view = "hub" }) end
        return
    end
    Multistate.SetData(target, "RAFSummonTime", os.time() + 120)
    Multistate.ClearData(target, "RAFSummonRequest")
    summoner:SendAreaTriggerMessage(target:GetName().." has accepted your summon request.")
    Multistate.ClearData(summoner, "RAFSummonGrace")
    Multistate.SetData(summoner, "RAFSummonCD", os.time() + summonCDLength * 60)
    WorldRAFView(target, seq, { view = "teleport", map = summoner:GetMapId(), x = summoner:GetX(), y = summoner:GetY(), z = summoner:GetZ(), o = summoner:GetO() })
end

local function WorldRAFDecline(target)
    local summonerName = Multistate.GetData(target, "RAFSummonRequest")
    local summoner = summonerName and GetPlayerByName(summonerName) or nil
    if summoner then
        summoner:SendAreaTriggerMessage(target:GetName().." has denied your summon request.")
    end
    Multistate.ClearData(target, "RAFSummonRequest")
end

local function WorldRAFLinkView(player, seq)
    local accountId = player:GetAccountId()
    local name = player:GetName()
    AuthDBQueryAsync(string.format("SELECT account_id FROM acore_eluna.account_raf WHERE account_id = %d", accountId), function(query)
        local p = GetPlayerByName(name)
        if not p then return end
        WorldRAFView(p, seq, { view = "raflink", linked = query ~= nil })
    end)
end

local function WorldRAFRegister(player, code, seq)
    local accountId = player:GetAccountId()
    local name = player:GetName()
    local function linkview()
        WorldRAFLinkView(player, seq)
    end
    AuthDBQueryAsync(string.format("SELECT totaltime FROM account WHERE id = %d", accountId), function(tq)
        local p = GetPlayerByName(name)
        if not p or not tq then
            if p then linkview() end
            return
        end
        if tq:GetUInt32(0) >= 3600 * RegisterRAFTimeLimit then
            local message = "|cFFFF0000You can't register or change your referral link if you have played for more than one hour.|r"
            p:SendAreaTriggerMessage(message)
            p:SendBroadcastMessage(message)
            WorldRAFLinkView(p, seq)
            return
        end
        local referer_id = tonumber(code)
        if not referer_id then
            p:SendAreaTriggerMessage("Please enter a valid number for the referral ID.")
            WorldRAFLinkView(p, seq)
            return
        end
        AuthDBQueryAsync(string.format("SELECT id FROM account WHERE id = %d", referer_id), function(rq)
            local p2 = GetPlayerByName(name)
            if not p2 or not rq or not rq:GetUInt32(0) then
                if p2 then
                    p2:SendAreaTriggerMessage("The entered referral ID does not exist. Please check and try again.")
                    WorldRAFLinkView(p2, seq)
                end
                return
            end
            if accountId == referer_id then
                p2:SendBroadcastMessage("You can't refer yourself!")
                WorldRAFLinkView(p2, seq)
                return
            end
            local currentTime = os.time()
            local playerIP = p2:GetPlayerIP()
            AuthDBQueryAsync(string.format("SELECT last_ip FROM account WHERE id = %d", referer_id), function(ipq)
                local p3 = GetPlayerByName(name)
                if not p3 or not ipq then
                    if p3 then WorldRAFLinkView(p3, seq) end
                    return
                end
                local refererIP = ipq:GetString(0)
                AuthDBExecute(string.format([[
                    INSERT INTO acore_eluna.account_raf (account_id, referer_id, status, progress, date, IP, IP_referer)
                    VALUES (%d, %d, 2, 0, %d, '%s', '%s')
                    ON DUPLICATE KEY UPDATE referer_id = %d, status = 2, progress = 0, date = %d, IP = '%s', IP_referer = '%s'
                ]], accountId, referer_id, currentTime, playerIP, refererIP, referer_id, currentTime, playerIP, refererIP))
                Multistate.SetData(p3, "RAFreferee", true)
                p3:SendAreaTriggerMessage(string.format("Successfully linked to referrer with ID: %d. Remember to relog to use the summon function.", referer_id))
                WorldRAFLinkView(p3, seq)
            end)
        end)
    end)
end

local function WorldRAFInfo(player, seq, page)
    page = page or 1
    local accountId = player:GetAccountId()
    local name = player:GetName()
    AuthDBQueryAsync(string.format("SELECT account_id, status, date, progress FROM acore_eluna.account_raf WHERE referer_id = %d", accountId), function(query)
        local p = GetPlayerByName(name)
        if not p then return end
        local rows = {}
        if query then
            repeat
                table.insert(rows, {
                    refereeAccountId = query:GetUInt32(0),
                    status = query:GetUInt32(1),
                    date = query:GetUInt32(2),
                    progress = query:GetUInt32(3),
                })
            until not query:NextRow()
        end
        local totalPages = math.max(1, math.ceil(#rows / ENTRIES_PER_PAGE))
        if page > totalPages then page = totalPages end
        local slice = {}
        for i = (page - 1) * ENTRIES_PER_PAGE + 1, math.min(page * ENTRIES_PER_PAGE, #rows) do
            table.insert(slice, rows[i])
        end
        WorldRAFView(p, seq, { view = "referralinfo", rows = slice, page = page, totalPages = totalPages })
    end)
end

local function WorldRAFReferee(player, seq)
    local accountId = player:GetAccountId()
    local name = player:GetName()
    AuthDBQueryAsync(string.format("SELECT referer_id, status, date, progress FROM acore_eluna.account_raf WHERE account_id = %d", accountId), function(query)
        local p = GetPlayerByName(name)
        if not p then return end
        if query then
            WorldRAFView(p, seq, { view = "refereeinfo", found = true,
                refererAccountId = query:GetUInt32(0), status = query:GetUInt32(1),
                date = query:GetUInt32(2), progress = query:GetUInt32(3) })
        else
            WorldRAFView(p, seq, { view = "refereeinfo", found = false })
        end
    end)
end

HandleRAFWorld = function(player, data)
    if not player or not data or not data.op then return end
    if data.op == "open-info" then
        WorldRAFInfo(player, data.seq, data.page)
    elseif data.op == "open-summon" then
        WorldRAFSummonMenu(player, data.seq, data.page)
    elseif data.op == "open-referee" then
        WorldRAFReferee(player, data.seq)
    elseif data.op == "open-link" then
        WorldRAFLinkView(player, data.seq)
    elseif data.op == "open-bonuses" then
        WorldRAFBonuses(player, data.seq, nil)
    elseif data.op == "register" then
        WorldRAFRegister(player, data.code, data.seq)
    elseif data.op == "claim" then
        WorldRAFClaim(player, data.tier, data.option, data.seq)
    elseif data.op == "summon" then
        local friend
        for _, pl in ipairs(GetPlayersInWorld()) do
            if pl and pl:GetGUIDLow() == data.guid then friend = pl break end
        end
        WorldRAFSummon(player, friend, data.seq)
    elseif data.op == "accept" then
        WorldRAFAccept(player, data.seq)
    elseif data.op == "decline" then
        WorldRAFDecline(player)
    end
end

local function RAFCommands(event, player, command) -- .summonfriend, .rafreferee, .rafdelete, .rafmenu
	if not player then return end
    local cmd, param = string.match(command:lower(), "^(%S+)%s*(%d*)$")
    local accountId = player:GetAccountId()
	
	if player:GetGMRank() > 0 and command:lower():find("^rafconnect") then
		local _, _, accountId, refererId = command:find("^rafconnect%s+(%d+)%s+(%d+)$")
		
		if not accountId or not refererId then
			player:SendBroadcastMessage("Usage: .rafconnect <account_id> <referer_id>")
			return false
		end
		
		local gmName = player:GetName()
		AuthDBQueryAsync("SELECT 1 FROM account WHERE id IN (" .. accountId .. ", " .. refererId .. ")", function(accountCheck)
			local gm = GetPlayerByName(gmName)
			if not gm then return end
			if not accountCheck or accountCheck:GetRowCount() < 2 then
				gm:SendBroadcastMessage("Error: One or both account IDs are invalid.")
				return
			end
			AuthDBQueryAsync(string.format("SELECT 1 FROM acore_eluna.account_raf WHERE (account_id = %s AND referer_id = %s) OR (account_id = %s AND referer_id = %s)", accountId, refererId, refererId, accountId), function(linkCheck)
				local gm2 = GetPlayerByName(gmName)
				if not gm2 then return end
				if linkCheck and linkCheck:GetRowCount() > 0 then
					gm2:SendBroadcastMessage("Error: These accounts are already linked in RAF.")
					return
				end
				AuthDBExecute(string.format("INSERT INTO acore_eluna.account_raf (account_id, referer_id, status, progress, date) VALUES (%s, %s, 2, 0, %d)", accountId, refererId, os.time()))
				gm2:SendBroadcastMessage("RAF: Friend " .. accountId .. " successfully linked to referer " .. refererId .. ".")
			end)
		end)

		return false
	end
	
    if cmd == "rafsummonfriend" then
        if not param or param == "" then
            return false
        end
        local friendGUIDLow = tonumber(param)
        if friendGUIDLow then
            local friend
            for _, pl in ipairs(GetPlayersInWorld()) do
                if pl and pl:GetGUIDLow() == friendGUIDLow then friend = pl break end
            end
            WorldRAFSummon(player, friend, nil)
        end
        return false
    end

    if command:lower() == "rafmenu" or command:lower() == "referalmenu" then
        WorldRAFView(player, nil, { view = "hub" })
        return false -- Prevent further command processing
    end

	if command:lower() == "referalinfo" or command:lower() == "rafinfo" then
		local targetPlayer = player:GetSelection() -- Get the player's current target
		local accountId
		local name = player:GetName()

		-- Check if the player has a target and the target is a player
		if targetPlayer and targetPlayer:IsPlayer() then
			accountId = targetPlayer:GetAccountId()
		else
			accountId = player:GetAccountId() -- Fallback to the player's account ID if no target or target is not a player
		end

		AuthDBQueryAsync(string.format([[
			SELECT account_id, status, date FROM acore_eluna.account_raf WHERE referer_id = %d
		]], accountId), function(query)
			player = Multistate.FindPlayerByName(name)
			if query then
				local count = 0
				repeat
					count = count + 1
					local refereeAccountId = query:GetUInt32(0)
					local status = query:GetUInt32(1)
					local date = query:GetUInt32(2)

					local statusText = (status == 2) and "In progress" or "Completed"
					local currentTime = os.time()
					local timeLeft = (date + RAFDuration) - currentTime
					local daysLeft = math.floor(timeLeft / (24 * 60 * 60))
					local hoursLeft = math.floor((timeLeft % (24 * 60 * 60)) / 3600)

					local timeLeftText
					if daysLeft > 0 then
						timeLeftText = string.format("%d days", daysLeft)
					elseif hoursLeft > 0 then
						timeLeftText = string.format("%d hours", hoursLeft)
					else
						timeLeftText = "less than 1 hour"
					end

					player:SendBroadcastMessage(string.format("Referral found with account ID %d, status: %s, RAF active for: %s",
						refereeAccountId, statusText, timeLeftText))
				until not query:NextRow()

				if count == 0 then
					player:SendBroadcastMessage("You have no referrals.")
				end
			else
				player:SendBroadcastMessage("You have no referrals.")
			end
		end)
		return false
	end

    if (cmd == "rafreferee" and param) or (cmd == "rafrefer" and param) or (cmd == "refer" and param) then
		if player:GetGMRank() > 0 then
			local referer_id
			local target = player:GetSelection()
			
			if target and target:IsPlayer() then
				referer_id = target:GetAccountId()
			else
				referer_id = tonumber(param)
			end
			
			if accountId == referer_id then
				player:SendBroadcastMessage("You can't refer yourself!")
				return false
			end
			
			if not referer_id then
            player:SendBroadcastMessage("Usage: .refer <referer_id> or target")
			elseif referer_id > 0 then

				local currentTime = os.time()
				local playerIP = player:GetPlayerIP()

				AuthDBExecute(string.format([[
					INSERT INTO acore_eluna.account_raf (account_id, referer_id, status, progress, date, IP)
					VALUES (%d, %d, 2, 0, %d, '%s')
					ON DUPLICATE KEY UPDATE referer_id = %d, status = 2, progress = 0, date = %d, IP = '%s'
				]], accountId, referer_id, currentTime, playerIP, referer_id, currentTime, playerIP))

				Multistate.SetData(player, "RAFreferee", true)
				player:SendBroadcastMessage(string.format("You have been registered as a referee with referer ID: %d", referer_id))
			end
		end
        return false
    elseif cmd == "rafdelete" and param then
        if player:GetGMRank() > 0 then
            local account_to_delete = tonumber(param)
            AuthDBExecute(string.format([[
                DELETE FROM acore_eluna.account_raf WHERE account_id = %d
            ]], account_to_delete))

            Multistate.ForEachPlayer(function(p)
                if p:GetAccountId() == account_to_delete then
                    Multistate.ClearData(p, "RAFreferee")
                end
            end)

            player:SendBroadcastMessage(string.format("RAF entry for account ID %d has been deleted.", account_to_delete))
        else
            player:SendBroadcastMessage("You do not have permission to use this command.")
        end
        return false
    elseif player:GetGMRank() > 0 and (cmd == "rafreferee" or cmd == "rafrefer" or cmd == "rafdelete" or cmd == "refer") then
        if cmd == "rafreferee" or cmd == "rafrefer" then
            player:SendBroadcastMessage("Usage: .refer <referer_id> or .rafrefer <referer_id>")
        else
            player:SendBroadcastMessage("Usage: .rafdelete <account_id>")
        end
        return false
    end
end

-- Function to check and update referee status
-- Re-resolves inside: event objects expire after their dispatch, so the callback must not touch the captured one.
local function CheckRefereeStatus(player)
    local playerName = player:GetName()
    local accountId = player:GetAccountId()
    local MaxRAFDuration = os.time() - RAFDuration
    local playerIP = player:GetPlayerIP()

    AuthDBQueryAsync(string.format([[
        SELECT 1 FROM acore_eluna.account_raf
        WHERE account_id = %d AND status = 2 AND date > %d
    ]], accountId, MaxRAFDuration), function(query)

		local player = playerName and Multistate.FindPlayerByName(playerName) or nil
		if not player then return end
		if query then
			AuthDBExecute(string.format([[
				UPDATE acore_eluna.account_raf SET IP = '%s' WHERE account_id = %d
			]], playerIP, accountId))
			-- Multistate: visible in every state (progress handlers run on maps).
			Multistate.SetData(player, "RAFreferee", true)
		else
			Multistate.ClearData(player, "RAFreferee")
		end
	end)
end

local function ClearRefereeStatus(event, player)
    Multistate.ClearData(player, "RAFreferee")
end

-- Check referee status on player login and server load
local function OnPlayerLogin(event, player)
    CheckRefereeStatus(player)
end

local function ReloadEluna(event)
    -- Multistate: state-aware sweep (each state covers its visible players).
    Multistate.ForEachPlayer(function(player)
        CheckRefereeStatus(player)
    end)
end

local function UpdateProgress(player)
    local accountId = player:GetAccountId()
    if Multistate.GetData(player, "RAFreferee") then
        if not playerProgress[accountId] then
            playerProgress[accountId] = 0
            
            player:RegisterEvent(function(eventId, delay, repeats, player)
                if playerProgress[accountId] and playerProgress[accountId] > 0 then
                    AuthDBExecute(string.format([[
                        UPDATE acore_eluna.account_raf SET progress = progress + %d WHERE account_id = %d
                    ]], playerProgress[accountId], accountId))
                    playerProgress[accountId] = nil
                end
            end, 900000, 1) -- Update RAF progress every 15 minutes
        end
        
        playerProgress[accountId] = playerProgress[accountId] + 1
    end
end

local function OnSave(event, player)
    UpdateProgress(player)
end

local function OnAchievementComplete(event, player, achievementId)
    UpdateProgress(player)
end

local function OnEquip(event, player, item, bag, slot)
    UpdateProgress(player)
end

local function EnterCombat(event, player, enemy)
    UpdateProgress(player)
end

local function LeaveCombat(event, player)
    UpdateProgress(player)
end

local function OnXP(event, player, amount, victim, source)
    UpdateProgress(player)
end

local function OnRep(event, player, factionId, standing, incremental)
    UpdateProgress(player)
end

local function OnCreatureKill(event, killer, killed)
	if killed:GetLevel() + 8 >= killer:GetLevel() then
		UpdateProgress(killer)
	end
end

local function OnAreaTrigger(event, player, newZone, newArea)
    UpdateProgress(player)
end

local function OnCompleteQuest(event, player, quest)
    UpdateProgress(player)
end

local function CheckCompletedReferrals()
    -- Multistate: driven by the DB (pending referrals) instead of the per-state
    -- RAFreferee table, so every pending referral is checked exactly once from
    -- the global sweep. The status flip to 3 inside makes this idempotent.
    AuthDBQueryAsync("SELECT account_id FROM acore_eluna.account_raf WHERE status = 2", function(pending)
    if not pending then
        return
    end
    repeat
        local refereeAccountId = pending:GetUInt32(0)
        AuthDBQueryAsync(string.format([[
            SELECT progress, referer_id FROM acore_eluna.account_raf WHERE account_id = %d AND status = 2
        ]], refereeAccountId), function(query)
        
			if query then
				local progress = query:GetUInt32(0)
				local refererId = query:GetUInt32(1)
				
				if progress >= RAFRewardReq then
					AuthDBExecute(string.format([[
						UPDATE acore_eluna.account_raf SET status = 3 WHERE account_id = %d
					]], refereeAccountId))
					
					local players = GetPlayersInWorld()
					
					-- Send message to the referred player (referee) if they're online
					for _, player in ipairs(players) do
						if player:GetAccountId() == refereeAccountId then
							message = "Twiggy: Congratulations, you've qualified for your referee reward! You have earned ".. TokenReward .." ".. TokenName.. " and a special reward, speak to me to claim it."
							SendPurpleBroadcast(player, message)
							player:AddItem(TokenID, TokenReward)
							Multistate.ClearData(player, "RAFreferee")
							break
						end
					end
					
					-- Check referer's status 1 second after changing entry in DB, to allow for time to update
					CreateLuaEvent(function()
						local players = GetPlayersInWorld()
						AuthDBQueryAsync(string.format([[
							SELECT COUNT(*) as count FROM acore_eluna.account_raf WHERE referer_id = %d AND status > 2
						]], refererId), function(query2)
						
							if query2 then
								AuthDBExecute(string.format([[
									UPDATE acore_eluna.account_raf SET status = 4 WHERE account_id = %d
								]], refereeAccountId))
								local referralCount = query2:GetUInt32(0)
								print("referral count is "..referralCount)
								local message = ""
								
								if referralCount == 1 then
									message = "Twiggy: Congratulations! Your first referral with ID ".. refereeAccountId .." has qualified for Refer a Friend rewards! Your first special reward is ".. TokenReward .." ".. TokenName.. ", speak with me to claim it."
								elseif referralCount == RewardTier1 or referralCount == RewardTier2 or referralCount == RewardTier3 or referralCount == RewardTier4 then
									message = "Twiggy: Your referee with ID ".. refereeAccountId .." has fulfilled the the requirements to earn you another special Refer a Friend reward of your choice! You have earned ".. TokenReward .." ".. TokenName.. " and a special reward, speak with me to claim it."
								else
									message = "Twiggy: Congratulations! Your referee with ID ".. refereeAccountId .." has qualified for Refer a Friend rewards! You have earned ".. TokenReward .." ".. TokenName.. ". Check in with me any time to see how your referrals are going."
								end
								
								-- Send message to the referer if they're online
								local refererOnline = false
								for _, player in ipairs(players) do
									if player:GetAccountId() == refererId then
										SendPurpleBroadcast(player, message)
										refererOnline = true
										break
									end
								end
								if not refererOnline then
									CharDBQueryAsync(string.format([[SELECT guid, name FROM characters WHERE account = %d]], refererId), function(charactersQuery)
										if charactersQuery then
											repeat
												local charGUIDLow = charactersQuery:GetUInt32(0)
												local charName = charactersQuery:GetString(1)
												-- Create and send mail to each character
												local subject = "Refer a Friend Reward"
												if referralCount == 0 then
													local body = "Dear ".. charName .."! I bear happy news!\n\nYour first referral with ID ".. refereeAccountId .." has qualified for Refer a Friend rewards! You first special reward is ".. TokenReward .." ".. TokenName.. ", speak with me to claim it.\n\nYour personal branch of Yggdrasil,\nTwiggy"
												elseif referralCount == RewardTier1 or referralCount == RewardTier2 or referralCount == RewardTier3 or referralCount == RewardTier4 then
													local body = "Dear ".. charName .."! I bear happy news!\n\nYour referee with ID ".. refereeAccountId .." has fulfilled the the requirements to earn you another special Refer a Friend reward of your choice! You have earned ".. TokenReward .." ".. TokenName.. " and a special reward, speak with me to claim it.\n\nYour personal branch of Yggdrasil,\nTwiggy"
												else
													local body = "Dear ".. charName .."! I bear happy news!\n\nCongratulations! Your referee with ID ".. refereeAccountId .." has qualified for Refer a Friend rewards! You have earned ".. TokenReward .." ".. TokenName.. ". Check in with me any time to see how your referrals are going.\n\nYour personal branch of Yggdrasil,\nTwiggy"
												end
												-- Send mail to the character
												SendMail(subject, body, charGUIDLow, 0, 61)
											until not charactersQuery:NextRow()
										end
									end)
								end
							end
						end)
					end, 1000, 1)  -- 1000 milliseconds = 1 second
				end
			end
		end)
    until not pending:NextRow()
    end)
end

-- Multistate: the referral sweep touches every account and enumerates the world;
-- it runs exactly once server-wide in the global state (DB status flips make it
-- idempotent anyway).
if Multistate.IsCompat() or Multistate.IsWorld() then
    CreateLuaEvent(CheckCompletedReferrals, ProgressCheckTimer * 60 * 1000, 0)
end
RegisterPlayerEvent(3, OnPlayerLogin)
RegisterPlayerEvent(4, ClearRefereeStatus)
RegisterPlayerEvent(7, OnCreatureKill)
RegisterPlayerEvent(12, OnXP)
RegisterPlayerEvent(15, OnRep)
RegisterPlayerEvent(25, OnSave)
RegisterPlayerEvent(27, OnAreaTrigger)
RegisterPlayerEvent(29, OnEquip)
RegisterPlayerEvent(33, EnterCombat)
RegisterPlayerEvent(34, LeaveCombat)
RegisterPlayerEvent(42, RAFCommands)
RegisterPlayerEvent(45, OnAchievementComplete)
RegisterPlayerEvent(54, OnCompleteQuest)
RegisterServerEvent(33, ReloadEluna)

RegisterPlayerGossipEvent(1, 2, OnGossipSelect) -- Register gossip selection event