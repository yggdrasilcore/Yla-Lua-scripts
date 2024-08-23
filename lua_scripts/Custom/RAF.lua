-- Welcome to Yggdrasil's RAF system, by mostly nick :)

-- START VARS
local RAFDuration 			= 45 * 24 * 60 * 60 -- RAF validity duration (45 * 24 * 60 * 60 = 45 days)
local ProgressCheckTimer 	= 5 				-- How often (in minutes) to check if RAF requirements are fulfilled, in minutes
local RAFRewardReq			= 750				-- How many counts of "activity" to require to achieve RAF rewards (skill points earned, achievements earned, quests completed, area changes, creatures in level ranged killed, etc.)
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
 
-- CACHE TABLES
local RAFreferee = {}
local ClaimStatus0 = {}
local ClaimStatus1 = {}
local ClaimStatus2 = {}
local ClaimStatus3 = {}
local ClaimStatus4 = {}
local CompletionStatus0 = {}
local CompletionStatus1 = {}
local CompletionStatus2 = {}
local CompletionStatus3 = {}
local CompletionStatus4 = {}
local referraltable = {}
local eligibleSummon = {}
local summonCD = {}
local requestsender = {}
local requesttime = {}
local summonerGraceTimer = {}
local summonrequest = ""

-- Create the account_raf table if it doesn't exist
AuthDBExecute([[
    CREATE TABLE IF NOT EXISTS account_raf (
        account_id INT PRIMARY KEY,
        referer_id INT,
        status INT,
        progress INT DEFAULT 0,
        date INT,
        IP VARCHAR(15)
    )
]])

AuthDBExecute([[
    CREATE TABLE IF NOT EXISTS account_raf_claimed (
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

local function ShowReferralInfoMenu(player, page)
    page = page or 1
    local accountId = player:GetAccountId()
    player:GossipClearMenu()
    local query = AuthDBQuery(string.format([[
            SELECT account_id, status, date, progress FROM account_raf WHERE referer_id = %d
        ]], accountId))
    
    if query then
        local entries = {}
        repeat
            local refereeAccountId = query:GetUInt32(0)
            local status = query:GetUInt32(1)
            local date = query:GetUInt32(2)
            local progress = query:GetUInt32(3)
            table.insert(entries, {refereeAccountId = refereeAccountId, status = status, date = date, progress = progress})
        until not query:NextRow()
        
        local totalPages = math.ceil(#entries / ENTRIES_PER_PAGE)
        local startIndex = (page - 1) * ENTRIES_PER_PAGE + 1
        local endIndex = math.min(startIndex + ENTRIES_PER_PAGE - 1, #entries)
        
        for i = startIndex, endIndex do
            local entry = entries[i]
            local statusText = (entry.status == 2) and "In progress" or "Completed"
            local currentTime = os.time()
            local timeLeft = (entry.date + RAFDuration) - currentTime
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
            local progressText
            if not entry.progress or (entry.progress == 0 and statusText ~= "Completed") then
                progressText = 0
            elseif statusText == "Completed" then
                progressText = 100
            else
				progressText = string.format("%.2f", math.min(100, (entry.progress / RAFRewardReq * 100)))
            end
            player:GossipMenuAddItem(0, string.format("|TInterface/ICONS/inv_misc_groupneedmore:32:32:-22:0|tReferral ID: %d\n \nStatus: %s \nProgress: %d%% \nRAF active for: %s\n \n ", 
                entry.refereeAccountId, statusText, progressText, timeLeftText), 1, 2)
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
    else
        player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_grouplooking:32:32:-22:0|tYou have no referrals.", 1, 2)
        player:GossipMenuAddItem(0, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 1, 998)
    end
    player:GossipSendMenu(1, player, 1)
end

local function ShowSummonFriendsMenu(player, page)
    page = page or 1
    local playerName = player:GetName()
    local accountId = player:GetAccountId()
    player:GossipClearMenu()

    if summonerGraceTimer[accountId] and summonerGraceTimer[accountId] > os.time() then
        local timeLeft = summonCD[accountId] - os.time()
        local minutesLeft = math.floor(timeLeft / 60)
        local secondsLeft = timeLeft % 60
        player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_pocketwatch_01:48:48:-26:0|tSummon grace timer!\n \nYou recently requested to summon someone. Time until you can send next request:\n\n"..minutesLeft.." minutes and "..secondsLeft.." seconds\n \nClick here to refresh cooldown.\n \n \n", 1, 7)
        player:GossipMenuAddItem(0, "|TInterface/ICONS/Trade_Engineering:48:48:-26:0|tBack", 1, 998)
        player:GossipSendMenu(1, player, 1)
    elseif summonCD[accountId] and summonCD[accountId] > os.time() then
        local timeLeft = summonCD[accountId] - os.time()
        local minutesLeft = math.floor(timeLeft / 60)
        local secondsLeft = timeLeft % 60
        player:GossipMenuAddItem(0, "|TInterface/ICONS/spell_holy_borrowedtime:48:48:-26:0|tRAF summon cooldown:\n \n "..minutesLeft.." minutes and "..secondsLeft.." seconds\n \n", 1, 7)
        player:GossipMenuAddItem(0, "|TInterface/ICONS/Trade_Engineering:48:48:-26:0|tBack", 1, 998)
        player:GossipSendMenu(1, player, 1)
    else
	    local MaxRAFDuration = os.time() - RAFDuration
		
		local query = AuthDBQuery(string.format([[
			SELECT account_id, referer_id
			FROM account_raf
			WHERE (referer_id = %d AND date > %d) OR (account_id = %d AND date > %d)
		]], accountId, MaxRAFDuration, accountId, MaxRAFDuration))
		
        local friendsToSummon = {}
        local playerList = GetPlayersInWorld()
        
        if query then
            repeat
                local friendAccountId = query:GetUInt32(0)
                local referrerAccountId = query:GetUInt32(1)
                for _, friend in ipairs(playerList) do
                    if (friend:GetAccountId() == friendAccountId and friend:GetName() ~= playerName)
                    or (friend:GetAccountId() == referrerAccountId and friend:GetName() ~= playerName) 
                    then
                        table.insert(friendsToSummon, {name = friend:GetName(), guid = friend:GetGUIDLow()})
                    end
                end
            until not query:NextRow()
        end

        local totalPages = math.ceil(#friendsToSummon / ENTRIES_PER_PAGE)
        local startIndex = (page - 1) * ENTRIES_PER_PAGE + 1
        local endIndex = math.min(startIndex + ENTRIES_PER_PAGE - 1, #friendsToSummon)

        for i = startIndex, endIndex do
            local friend = friendsToSummon[i]
            eligibleSummon[player:GetName()] = friend.name
            player:GossipMenuAddItem(0, string.format("|TInterface/ICONS/spell_unused2:48:48:-26:0|tSummon %s", friend.name), 1, (friend.guid + 1000))
        end

        if #friendsToSummon > 0 then
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
        else
            player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_grouplooking:48:48:-26:0|tYou have no friends to summon.", 1, 7)
            player:GossipMenuAddItem(0, "|TInterface/ICONS/Trade_Engineering:48:48:-26:0|tBack", 1, 998)
        end
        player:GossipSendMenu(1, player, 1)
    end
end

local function ShowRefereeInfo(player)
    local accountId = player:GetAccountId()
    local query = AuthDBQuery(string.format([[
        SELECT referer_id, status, date, progress FROM account_raf WHERE account_id = %d
    ]], accountId))
    
    player:GossipClearMenu()
    
    if query then
		local refererAccountId = query:GetUInt32(0)
		local status = query:GetUInt32(1)
		local date = query:GetUInt32(2)
		local progress = query:GetUInt32(3)
		
		local statusText = (status == 2) and "In progress" or "Completed"
		local progressText
		
		if progress == 0 and statusText ~= "Completed" then
			progressText = 0
		elseif statusText == "Completed" then
			progressText = 100
		else
			progressText = string.format("%.2f", (progress / RAFRewardReq * 100))
		end
		
		if progressText > 100 then
			progressText = 100
		end
		
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
		
		player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_groupneedmore:32:32:-22:0|tReferral status: \n \nYou're registered with the following referral information:\n \nReferer ID: ".. refererAccountId ..". \n \nStatus: " .. statusText .." \n \nProgress towards rewards: " .. progressText .."%.\n \nReferral program time left: " .. timeLeftText..".\n \n", 1, 3)
		
		player:GossipMenuAddItem(0, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 1, 998)
    else
        player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_grouplooking:32:32:-22:0|t Referral status:\n \nYou have not been registered as a referred player.\n \n", 1, 3)
		player:GossipMenuAddItem(0, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 1, 998)
    end
    
    player:GossipSendMenu(1, player, 1)
end

local function ShowRAFMenu(player)
    player:GossipClearMenu()
    --player:GossipMenuAddItem(0, "|TInterface/ICONS/INV_Misc_QuestionMark:32:32:-22:0|tHow does RAF work?", 1, 6)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_valentinescard02:32:32:-22:0|tRegister referal", 1, 1)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_groupneedmore:32:32:-22:0|tSee my referred friends", 1, 2)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_grouplooking:32:32:-22:0|tSee my referee status", 1, 3)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_box_02:32:32:-22:0|tClaim referral bonuses", 1, 4)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/spell_unused2:32:32:-22:0|tSummon my RAF friend", 1, 7)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tClose RAF menu", 1, 5)
    player:GossipSendMenu(1, player, 1)
end

local function ClaimBonuses(player)
    player:GossipClearMenu()
	local GUIDLow = player:GetGUIDLow()
	local accountId = player:GetAccountId()
	local ClaimStatus
	local CompletionStatus
	
	if not ClaimStatus0[GUIDLow] then 
		ClaimStatus0[GUIDLow] = "."
		ClaimStatus1[GUIDLow] = "."
		ClaimStatus2[GUIDLow] = "."
		ClaimStatus3[GUIDLow] = "."
		ClaimStatus4[GUIDLow] = "."
		CompletionStatus0[GUIDLow] = "In progress"
		CompletionStatus1[GUIDLow] = "In progress"
		CompletionStatus2[GUIDLow] = "In progress"
		CompletionStatus3[GUIDLow] = "In progress"
		CompletionStatus4[GUIDLow] = "In progress"
		
		local claimquery = AuthDBQuery(string.format([[
			SELECT claimed FROM account_raf_claimed WHERE account_id = %d
		]], accountId))
		
		if claimquery then
			-- Iterate over all the results
			repeat
				local claimed = claimquery:GetUInt32(0)
				
				-- Assign statuses based on the claimed value
				if claimed == 1 then
					ClaimStatus0[GUIDLow] = ", claimed."
				elseif claimed == 5 then
					ClaimStatus1[GUIDLow] = ", claimed."
				elseif claimed == 10 then
					ClaimStatus2[GUIDLow] = ", claimed."
				elseif claimed == 15 then
					ClaimStatus3[GUIDLow] = ", claimed."
				elseif claimed == 25 then
					ClaimStatus4[GUIDLow] = ", claimed."
				end
			until not claimquery:NextRow()
		end
				
		local completionquery = AuthDBQuery(string.format([[
			SELECT COUNT(*) FROM account_raf 
			WHERE referer_id = %d AND status = 4
		]], accountId))
		
		local completioncount = 0
		if completionquery then
			completioncount = completionquery:GetUInt32(0)
		end
		
		if completioncount > 0 then
			CompletionStatus0[GUIDLow] = "Completed"
			if not (ClaimStatus0[GUIDLow] == ", claimed.") then
				ClaimStatus0[GUIDLow] = ", claim now!" 
			end
		end
		if completioncount > 4 then
			CompletionStatus1[GUIDLow] = "Completed"
			if not (ClaimStatus1[GUIDLow] == ", claimed.") then
				ClaimStatus1[GUIDLow] = ", claim now!" 
			end
		end
		if completioncount > 9 then
			CompletionStatus2[GUIDLow] = "Completed"
			if not (ClaimStatus2[GUIDLow] == ", claimed.") then
				ClaimStatus2[GUIDLow] = ", claim now!" 
			end
		end
		if completioncount > 14 then
			CompletionStatus3[GUIDLow] = "Completed"
			if not (ClaimStatus3[GUIDLow] == ", claimed.") then
				ClaimStatus3[GUIDLow] = ", claim now!" 
			end
		end
		if completioncount > 24 then
			CompletionStatus4[GUIDLow] = "Completed"
			if not (ClaimStatus4[GUIDLow] == ", claimed.") then
				ClaimStatus4[GUIDLow] = ", claim now!" 
			end
		end
	end
	player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_rune_07:32:32:-22:0|tFirst referral reward:\n \nStatus: "..CompletionStatus0[GUIDLow]..""..ClaimStatus0[GUIDLow].."\n \nContains: 5 Community Tokens\n \n ", 1, 40) -- This is tier 0
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_box_01:32:32:-22:0|tReward box 1:\n \nRequirement: ".. RewardTier1 .." referrals.\nStatus: "..CompletionStatus1[GUIDLow]..""..ClaimStatus1[GUIDLow].."\n \nContains:\n- 5 Rotface and Festergut's Acidic Blood\n- Unobtainable Vanilla mounts\n- Fishing Chair\n- 60 Emblems of Frost\n \n ", 1, 41)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_box_02:32:32:-22:0|tReward box 2:\n \nRequirement: ".. RewardTier2 .." referrals.\nStatus: "..CompletionStatus2[GUIDLow]..""..ClaimStatus2[GUIDLow].."\n \nContains:\n- X-53 Touring Rocket\n- Hard-to-get mounts\n- ToC trinkets and cloaks\n- 95 Emblems of Frost\n \n ", 1, 42)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_box_03:32:32:-22:0|tReward box 3:\n \nRequirement: ".. RewardTier3 .." referrals.\nStatus: "..CompletionStatus3[GUIDLow]..""..ClaimStatus3[GUIDLow].."\n \nContains:\n- ICC 25 heroic weapons\n- ICC 25 normal trinkets\n- Ashes of Al'ar\n- 95 Emblems of Frost and 1 Sanctification Mark\n \n ", 1, 43)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_box_04:32:32:-22:0|tReward box 4:\n \nRequirement: ".. RewardTier4 .." referrals.\nStatus: "..CompletionStatus4[GUIDLow]..""..ClaimStatus4[GUIDLow].."\n \nContains:\n- Sea Turtle mount\n- Unobtainable mounts\n- 50 Community Tokens\n \n ", 1, 44)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 1, 998)
    player:GossipSendMenu(1, player, 1)
end

local function Reward40(player)
    player:GossipClearMenu()
	local GUIDLow = player:GetGUIDLow()
	local accountId = player:GetAccountId()
	
	if CompletionStatus0[GUIDLow] ~= "Completed" then
		message = "Twiggy: You can't claim this reward yet!"
		SendPurpleBroadcast(player, message)
		ClaimBonuses(player)
	elseif CompletionStatus0[GUIDLow] == "Completed" then
		if ClaimStatus0[GUIDLow] == ", claimed." then
			message = "Twiggy: You've already claimed this reward!"
			SendPurpleBroadcast(player, message)
			ClaimBonuses(player)
		else
			if player:HasItem(19322, 1) or PlayerHasEnoughFreeSlots(player, 1) then
				player:AddItem(19322, 5)
				
				message = "Twiggy: You've been rewarded "..TokenReward.." "..TokenName.."!"
				SendPurpleBroadcast(player, message)
				
				AuthDBExecute(string.format([[
					INSERT INTO account_raf_claimed (account_id, claimed, date)
					VALUES (%d, %d, %d)
				]], accountId, 1, os.time()))
				
				ClaimStatus0[GUIDLow] = ", claimed."
				ClaimBonuses(player)
			end
		end
	end
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
    player:GossipSendMenu(1, player, 1)
end

local function RewardBase41(player, itemId, itemName)
    player:GossipClearMenu()
    local GUIDLow = player:GetGUIDLow()
    local accountId = player:GetAccountId()
    
    if CompletionStatus1[GUIDLow] == "Completed" then
        if ClaimStatus1[GUIDLow] ~= ", claimed." then
			if player:PlayerHasEnoughFreeSlots(player, 3) then
				player:AddItem(19322, 5)
				if itemId == 50231 then
					player:AddItem(50226, 1)
					player:AddItem(50231, 1)
				elseif itemId == 49426 then
					player:AddItem(itemId, 60)
				elseif itemId == 8633 then
					player:LearnSpell(10788)
				elseif itemId == 8630 then
					player:LearnSpell(10790)
				else
					player:AddItem(itemId, 1)
				end
				
				itemLink = GetItemLink(itemId)
				
				if itemId == 50231 then
					message = "Twiggy: You've been rewarded "..TokenReward.." "..TokenName..", Rotface's Acidic Blood and Festergut's Acidic Blood!"
				elseif itemId == 49426 then
					message = "Twiggy: You've been rewarded "..TokenReward.." "..TokenName.." and 60 " .. itemLink .. "!"
				else 
					message = "Twiggy: You've been rewarded "..TokenReward.." "..TokenName.." and " .. itemLink .. "!"
				end
				
				SendPurpleBroadcast(player, message)
				
				AuthDBExecute(string.format([[
					INSERT INTO account_raf_claimed (account_id, claimed, date)
					VALUES (%d, %d, %d)
				]], accountId, 5, os.time()))
				
				ClaimStatus1[GUIDLow] = ", claimed."
				ClaimBonuses(player)
			else
				player:SendBroadcastMessage("You need at least 3 free bag slots to receive your reward.")
				ClaimBonuses(player)
			end
        end
    end
end

local function Reward411(player) -- Rotface and Festergut's bloods
    RewardBase41(player, 50231, "Rotface blood")
end

local function Reward412(player) -- Leopard mount
    RewardBase41(player, 8633, "Leopard mount")
end

local function Reward413(player) -- Bengal Tiger mount
    RewardBase41(player, 8630, "Bengal Tiger mount")
end

local function Reward414(player) -- Brazen Taxi mount
    RewardBase41(player, 20221, "Brazen Taxi mount")
end

local function Reward415(player) -- Fishing Chair
    RewardBase41(player, 33223, "Fishing Chair")
end

local function Reward416(player) -- Naxxramas Deathcharger mount
    RewardBase41(player, 23193, "Naxxramas Deathcharger mount")
end

local function Reward417(player) -- 60 Emblems of Frost
    RewardBase41(player, 49426, "60 Emblems of Frost")
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
    player:GossipSendMenu(1, player, 1)
end

local function RewardBase42(player, itemId)
    player:GossipClearMenu()
    local GUIDLow = player:GetGUIDLow()
    local accountId = player:GetAccountId()
	local race = player:GetRace()
    
    if CompletionStatus2[GUIDLow] == "Completed" then
        if ClaimStatus2[GUIDLow] ~= ", claimed." then
			if PlayerHasEnoughFreeSlots(player, 3) then
				player:AddItem(19322, 5)
				if itemId == 48668 and (race == 1  or race == 3 or race == 4 or race == 7 or race == 11) then
					player:AddItem(48673, 1)
				elseif itemId == 47290 and (race == 1  or race == 3 or race == 4 or race == 7 or race == 11) then
					player:AddItem(47080, 1)
				elseif itemId == 47303 and (race == 1  or race == 3 or race == 4 or race == 7 or race == 11) then
					player:AddItem(47115, 1)
				elseif itemId == 47271 and (race == 1  or race == 3 or race == 4 or race == 7 or race == 11) then
					player:AddItem(47041, 1)
				elseif itemId == 49426 then
					player:AddItem(itemId, 95)
				else
					player:AddItem(itemId, 1)
				end
				
				itemLink = GetItemLink(itemId)
				
				if itemId == 49426 then
					message = "Twiggy: You've been rewarded "..TokenReward.." "..TokenName.." and 95 " .. itemLink .. "!"
				else 
					message = "Twiggy: You've been rewarded "..TokenReward.." "..TokenName.." and " .. itemLink .. "!"
				end
				
				SendPurpleBroadcast(player, message)
				
				AuthDBExecute(string.format([[
					INSERT INTO account_raf_claimed (account_id, claimed, date)
					VALUES (%d, %d, %d)
				]], accountId, 10, os.time()))
				
				ClaimStatus2[GUIDLow] = ", claimed."
				ClaimBonuses(player)
			else
				player:SendBroadcastMessage("You need at least 3 free bag slots to receive your reward.")
				ClaimBonuses(player)
			end
        end
    end
end

local function Reward421(player)
    RewardBase42(player, 54860)
end

local function Reward422(player)
    RewardBase42(player, 32768)
end

local function Reward423(player)
    RewardBase42(player, 19872)
end

local function Reward424(player)
    RewardBase42(player, 19902)
end

local function Reward425(player)
    RewardBase42(player, 49282)
end

local function Reward426(player)
    RewardBase42(player, 44234)
end

local function Reward427(player)
    RewardBase42(player, 47271)
end

local function Reward428(player)
    RewardBase42(player, 48668)
end

local function Reward429(player)
    RewardBase42(player, 47290)
end

local function Reward460(player)
    RewardBase42(player, 47303)
end

local function Reward461(player)
    RewardBase42(player, 45518)
end

local function Reward462(player)
    RewardBase42(player, 49426)
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
    player:GossipSendMenu(1, player, 1)
end

local function RewardBase43(player, itemId)
    player:GossipClearMenu()
    local GUIDLow = player:GetGUIDLow()
    local accountId = player:GetAccountId()
    local race = player:GetRace()
	local class = player:GetClass()
    
    if CompletionStatus3[GUIDLow] == "Completed" then
        if ClaimStatus3[GUIDLow] ~= ", claimed." then
			if PlayerHasEnoughFreeSlots(player, 3) then
				player:AddItem(19322, 5)
				if itemId == 49426 then
					player:AddItem(itemId, 95)
					if class == 4 or class == 6 or class == 8 or class == 11 then
						player:AddItem(52025, 1) -- Mark of Sanctification
					elseif class == 1 or class == 3 or class == 7 then
						player:AddItem(52026, 1) -- Mark of Sanctification
					else
						player:AddItem(itemId, 1)
					end
				else
					player:AddItem(itemId, 1)
				end
				
				itemLink = GetItemLink(itemId)
				
				if itemId == 49426 then
					message = "Twiggy: You've been rewarded "..TokenReward.." "..TokenName..", 95 " .. itemLink .. ", and 1x Mark of Sanctification!"
				else 
					message = "Twiggy: You've been rewarded "..TokenReward.." "..TokenName.." and " .. itemLink .. "!"
				end
				
				SendPurpleBroadcast(player, message)
				
				AuthDBExecute(string.format([[
					INSERT INTO account_raf_claimed (account_id, claimed, date)
					VALUES (%d, %d, %d)
				]], accountId, 15, os.time()))
				
				ClaimStatus3[GUIDLow] = ", claimed."
				ClaimBonuses(player)
			else
				player:SendBroadcastMessage("You need at least 3 free bag slots to receive your reward.")
				ClaimBonuses(player)
			end
        end
    end
end

local function Reward431(player)
    RewardBase43(player, 50725)
end

local function Reward432(player)
    RewardBase43(player, 50709)
end

local function Reward433(player)
    RewardBase43(player, 50638)
end

local function Reward434(player)
    RewardBase43(player, 50641)
end

local function Reward435(player)
    RewardBase43(player, 50692)
end

local function Reward436(player)
    RewardBase43(player, 50695)
end

local function Reward437(player)
    RewardBase43(player, 50725)
end

local function Reward438(player)
    RewardBase43(player, 32458)
end

local function Reward439(player)
    RewardBase43(player, 50362)
end

local function Reward470(player)
    RewardBase43(player, 50366)
end

local function Reward471(player)
    RewardBase43(player, 50353)
end

local function Reward472(player)
    RewardBase43(player, 50364)
end

local function Reward473(player)
    RewardBase43(player, 49426)
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
    player:GossipSendMenu(1, player, 1)
end

local function RewardBase44(player, itemId)
    player:GossipClearMenu()
    local GUIDLow = player:GetGUIDLow()
    local accountId = player:GetAccountId()
    local race = player:GetRace()
    
    if CompletionStatus4[GUIDLow] == "Completed" then
        if ClaimStatus4[GUIDLow] ~= ", claimed." then
			if PlayerHasEnoughFreeSlots(player, 3) then
				if itemId == 19322 then
					player:AddItem(19322, 50)
				else
					player:AddItem(itemId, 1)
					player:AddItem(19322, 5)
				end
				
				itemLink = GetItemLink(itemId)
				
				if itemId == 49426 then
					message = "Twiggy: You've been rewarded "..TokenReward.." "..TokenName..", 95 " .. itemLink .. ", and 2x Mark of Sanctification!"
				else 
					message = "Twiggy: You've been rewarded "..TokenReward.." "..TokenName.." and " .. itemLink .. "!"
				end
				
				SendPurpleBroadcast(player, message)
				
				AuthDBExecute(string.format([[
					INSERT INTO account_raf_claimed (account_id, claimed, date)
					VALUES (%d, %d, %d)
				]], accountId, 25, os.time()))
				
				ClaimStatus4[GUIDLow] = ", claimed."
				ClaimBonuses(player)
			else
				player:SendBroadcastMessage("You need at least 3 free bag slots to receive your reward.")
				ClaimBonuses(player)
			end
        end
    end
end

local function Reward441(player)
    RewardBase44(player, 46109)
end

local function Reward442(player)
    RewardBase44(player, 44164)
end

local function Reward443(player)
    RewardBase44(player, 35226)
end

local function Reward444(player)
    RewardBase44(player, 30609) 
end

local function Reward445(player)
    RewardBase44(player, 37676) 
end

local function Reward446(player)
    RewardBase44(player, 34092) 
end

local function Reward447(player)
    RewardBase44(player, 19322)
end

local function ShowRAFLink(player)
    player:GossipClearMenu()
    local accountId = player:GetAccountId()
	
	local result = string.format([[
		SELECT account_id FROM account_raf WHERE account_id = %d
	]], accountId)
	
	if result and #result > 0 then
		player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_valentinescard02:32:32:-22:0|tI am a new player\n \nClick here to link up with the friend that refered you.\n \n", 1, 10, true, "You are already linked to a referer!\n\nAre you sure you want to change your link?\n\n Accepting will reset your progress towards your referal reward!")		
	else
		player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_valentinescard02:32:32:-22:0|tI am a new player, link me to my referer", 1, 10, true, "Please enter the referral ID from your friend. Only enter numbers.")
	end
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_groupneedmore:32:32:-22:0|tHow to refer your friends: \n \nTo refer your friends, you must share your friend referral code with them. \n \nYour referral code is: ".. player:GetAccountId() ..".\n \nAfter they create their account, they must log in and speak to their Twiggy to enter this code at the new player button above.\n \n", 1, 1)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/Trade_Engineering:32:32:-22:0|tBack", 1, 998)
    player:GossipSendMenu(1, player, 1)
end

local function ShowSummonRequest(friend)
	friend:GossipClearMenu()
	
	requesttime[friend:GetAccountId()] = os.time() + 120
	
	if not requestsender[friend:GetAccountId()] then
		requestsender[friend:GetAccountId()] = summonrequest
	end
	summonerName = requestsender[friend:GetAccountId()]
	summoner = GetPlayerByName(summonerName)
	friend:GossipMenuAddItem(0, "|TInterface/ICONS/spell_unused2:48:48:-26:0|tIncoming summon request!\n \n" .. summonerName .. " wants to summon you to "..GetAreaName(summoner:GetAreaId()).."! Do you accept?\n \n", 1, 500)
	friend:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_groupneedmore:48:48:-26:0|tYes\n \n", 1, 501)
	friend:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_grouplooking:48:48:-26:0|tNo\n \n", 1, 502)
	friend:GossipSendMenu(1, friend, 1)
end

local function OnGossipSelect(event, player, object, sender, intid, code, menu_id)
    local GUIDLow = player:GetGUIDLow()
	local accountId = player:GetAccountId()
	if intid > 1000 then
		local friendGUIDLow = intid - 1000
		if player:IsFlying() or player:IsOnVehicle()
		or player:IsFalling()or player:IsInCombat()
		or player:IsDead() or player:InArena()
		or player:InBattleground() then -- Simple sanity check
			player:SendAreaTriggerMessage("You can't summon your friend right now!")
		elseif summonCD[accountId] and summonCD[accountId] > os.time() then
			local timeLeft = summonCD[accountId] - os.time()
			local minutesLeft = math.floor(timeLeft / 60)
			local secondsLeft = timeLeft % 60
			player:SendAreaTriggerMessage(string.format("Your RAF summon is on cooldown for %d minutes and %d seconds.", minutesLeft, secondsLeft))
		else
			player:RunCommand(string.format("rafsummonfriend %s", friendGUIDLow))
		end
		ShowSummonFriendsMenu(player)
	elseif intid >= PAGINATION_INTID_START and intid < PAGINATION_INTID_START + 99 then
        local page = intid - PAGINATION_INTID_START
        ShowReferralInfoMenu(player, page)
	elseif intid == 500 then
		ShowSummonRequest(player)
	elseif intid == 501 then
		if os.time() >= requesttime[player:GetAccountId()] + 120 then
			player:SendAreaTriggerMessage("You have not accepted the summon in time!")
			player:GossipComplete()
		else
			summonerName = requestsender[player:GetAccountId()]
			summoner = GetPlayerByName(summonerName)
			if summoner:IsFlying() or summoner:IsOnVehicle()
			or summoner:IsFalling() or summoner:IsInCombat()
			or summoner:IsDead() or summoner:InArena()
			or summoner:InBattleground() then -- Simple sanity check on acceptance
				summoner:SendAreaTriggerMessage("You can't summon your friend right now!")
				player:SendAreaTriggerMessage("Your friend isn't available to summon you anymore.")
				summoner:GossipComplete()
				player:GossipComplete()
			else
				player:Teleport(summoner:GetMapId(), summoner:GetX(), summoner:GetY(), summoner:GetZ(), summoner:GetO())
				requesttime[player:GetAccountId()] = requesttime[player:GetAccountId()] + 120
				summoner:SendAreaTriggerMessage(player:GetName().." has accepted your summon request.")
				summonerGraceTimer[summoner:GetAccountId()] = nil
				summonCD[summoner:GetAccountId()] = os.time() + summonCDLength * 60
				summoner:GossipComplete()
				player:GossipComplete()
			end
		end
	elseif intid == 502 then
		summonerName = requestsender[player:GetAccountId()]
		summoner = GetPlayerByName(summonerName)
		summoner:SendAreaTriggerMessage(player:GetName().." has denied your summon request.")
        player:GossipComplete()
    elseif intid == 1 then
        ShowRAFLink(player)
    elseif intid == 10 then
        local accountId = player:GetAccountId()
        local query = AuthDBQuery(string.format([[
            SELECT totaltime FROM account WHERE id = %d
        ]], accountId))
        local timeplayed = query:GetUInt32(0)

        if timeplayed < 3600 * RegisterRAFTimeLimit then
            -- Ensure the code is a number
            local referer_id = tonumber(code)
            if not referer_id then
                player:SendAreaTriggerMessage("Please enter a valid number for the referral ID.")
                ShowRAFLink(player)
                return
            end

            -- Verify that the referer ID exists in the account table
            local refererQuery = AuthDBQuery(string.format([[
                SELECT id FROM account WHERE id = %d
            ]], referer_id))

            if not refererQuery then
                player:SendAreaTriggerMessage("The entered referral ID does not exist. Please check and try again.")
                ShowRAFLink(player)
                return
            end

			if accountId == referer_id then
				player:SendBroadcastMessage("You can't refer yourself!")
                ShowRAFLink(player)
				return
			end
			
			local currentTime = os.time()
			local playerIP = player:GetPlayerIP()
			
			AuthDBExecute(string.format([[
				INSERT INTO account_raf (account_id, referer_id, status, progress, date, IP)
				VALUES (%d, %d, 2, 0, %d, '%s')
				ON DUPLICATE KEY UPDATE referer_id = %d, status = 2, progress = 0, date = %d, IP = '%s'
			]], accountId, referer_id, currentTime, playerIP, referer_id, currentTime, playerIP))
			
			AuthDBExecute(string.format([[
				UPDATE account
				SET recruiter = %d
				WHERE id = %d
			]], accountId, GUIDlow))
			
			RAFreferee[accountId] = true
			player:SendAreaTriggerMessage(string.format("Successfully linked to referrer with ID: %d. Remember to relog to use the summon function.", referer_id))
        else 
			local message = "|cFFFF0000You can't register or change your referral link if you have played for more than one hour.|r"
            player:SendAreaTriggerMessage(message)
            player:SendBroadcastMessage(message)
        end
        ShowRAFLink(player)
    elseif intid == 2 then
        ShowReferralInfoMenu(player)
    elseif intid == 3 then
        ShowRefereeInfo(player)
    elseif intid == 4 then
		ClaimBonuses(player)
    elseif intid == 5 then
        player:GossipComplete()
    elseif intid == 6 then -- Learn about RAF
        player:GossipComplete()
    elseif intid == 7 then -- Summon friend
        ShowSummonFriendsMenu(player)
	elseif intid >= SUMMON_PAGINATION_INTID_START and intid < SUMMON_PAGINATION_INTID_START + 99 then
        local page = intid - SUMMON_PAGINATION_INTID_START
        ShowSummonFriendsMenu(player, page)
    elseif intid == 40 then
        Reward40(player)
    elseif intid == 41 then
	    if CompletionStatus1[GUIDLow] ~= "Completed" then
			message = "Twiggy: You can't claim this reward yet!"
			SendPurpleBroadcast(player, message)
			ClaimBonuses(player)
		elseif CompletionStatus1[GUIDLow] == "Completed" then
			if ClaimStatus1[GUIDLow] == ", claimed." then
				message = "Twiggy: You've already claimed this reward!"
				SendPurpleBroadcast(player, message)
				ClaimBonuses(player)
			else
				Reward41(player)
			end
		end		
    elseif intid == 411 then
        Reward411(player)
    elseif intid == 412 then
        Reward412(player)
    elseif intid == 413 then
        Reward413(player)
    elseif intid == 414 then
        Reward414(player)
    elseif intid == 415 then
        Reward415(player)
    elseif intid == 416 then
        Reward416(player)
    elseif intid == 417 then
        Reward417(player)
    elseif intid == 42 then
		if CompletionStatus2[GUIDLow] ~= "Completed" then
			message = "Twiggy: You can't claim this reward yet!"
			SendPurpleBroadcast(player, message)
			ClaimBonuses(player)
		elseif CompletionStatus2[GUIDLow] == "Completed" then
			if ClaimStatus2[GUIDLow] == ", claimed." then
				message = "Twiggy: You've already claimed this reward!"
				SendPurpleBroadcast(player, message)
				ClaimBonuses(player)
			else
				Reward42(player)
			end
		end	
    elseif intid == 421 then
        Reward421(player)
    elseif intid == 422 then
        Reward422(player)
    elseif intid == 423 then
        Reward423(player)
    elseif intid == 424 then
        Reward424(player)
    elseif intid == 425 then
        Reward425(player)
    elseif intid == 426 then
        Reward426(player)
    elseif intid == 427 then
        Reward427(player)
    elseif intid == 428 then
        Reward428(player)
    elseif intid == 429 then
        Reward429(player)
    elseif intid == 460 then
        Reward460(player)
    elseif intid == 461 then
        Reward461(player)
    elseif intid == 462 then
        Reward462(player)
    elseif intid == 43 then
		if CompletionStatus3[GUIDLow] ~= "Completed" then
			message = "Twiggy: You can't claim this reward yet!"
			SendPurpleBroadcast(player, message)
			ClaimBonuses(player)
		elseif CompletionStatus3[GUIDLow] == "Completed" then
			if ClaimStatus3[GUIDLow] == ", claimed." then
				message = "Twiggy: You've already claimed this reward!"
				SendPurpleBroadcast(player, message)
				ClaimBonuses(player)
			else
				Reward43(player)
			end
		end	
    elseif intid == 431 then
        Reward431(player)
    elseif intid == 432 then
        Reward432(player)
    elseif intid == 433 then
        Reward433(player)
    elseif intid == 434 then
        Reward434(player)
    elseif intid == 435 then
        Reward435(player)
    elseif intid == 436 then
        Reward436(player)
    elseif intid == 437 then
        Reward437(player)
    elseif intid == 438 then
        Reward438(player)
    elseif intid == 439 then
        Reward439(player)
    elseif intid == 470 then
        Reward470(player)
    elseif intid == 471 then
        Reward471(player)
    elseif intid == 472 then
        Reward472(player)
    elseif intid == 473 then
        Reward473(player)
    elseif intid == 44 then
		if CompletionStatus4[GUIDLow] ~= "Completed" then
			message = "Twiggy: You can't claim this reward yet!"
			SendPurpleBroadcast(player, message)
			ClaimBonuses(player)
		elseif CompletionStatus4[GUIDLow] == "Completed" then
			if ClaimStatus4[GUIDLow] == ", claimed." then
				message = "Twiggy: You've already claimed this reward!"
				SendPurpleBroadcast(player, message)
				ClaimBonuses(player)
			else
				Reward44(player)
			end
		end	
	elseif intid == 441 then
        Reward441(player)
    elseif intid == 442 then
        Reward442(player)
    elseif intid == 443 then
        Reward443(player)
    elseif intid == 444 then
        Reward444(player)
    elseif intid == 445 then
        Reward445(player)
    elseif intid == 446 then
        Reward446(player)
    elseif intid == 447 then
        Reward447(player)
    elseif intid == 998 then
        ShowRAFMenu(player)
    end
end

local function RAFCommands(event, player, command) -- .summonfriend, .rafreferee, .rafdelete, .rafmenu
    local cmd, param = string.match(command:lower(), "^(%S+)%s*(%d*)$")
    local accountId = player:GetAccountId()
	
    if cmd == "rafsummonfriend" then
        if not param or param == "" then
            return false
        end
		
        local friendGUIDLow = tonumber(param)
        if eligibleSummon[player:GetName()] then
            if type(eligibleSummon[player:GetName()]) == "table" then  -- table in case there's multiple people in summon queue
                for friendName, friendGUID in pairs(eligibleSummon[player:GetName()]) do
                    if friendGUID == friendGUIDLow then
                        local friend = GetPlayerByGUID(friendName)
                        if friend and friend:IsAlive() and not friend:IsInCombat()
						and not friend:IsOnVehicle() and not friend:IsFalling()
						and not friend:InArena() and not friend:InBattleground() then -- simple sanity check
							eligibleSummon[player:GetName()] = nil
							summonrequest = player:GetName()
							ShowSummonRequest(friend)
							summonCD[accountId] = os.time() + 2 * 60 -- 2 min cd between summons
							summonerGraceTimer[accountId] = os.time() + 2 * 60 -- Probably a duplicate but I'm tired so who cares
                        else
                            player:SendBroadcastMessage(friend:GetName().." isn't able to receive summon requests right now.")
                        end	
					end
                end
            else
                local friendName = eligibleSummon[player:GetName()] -- in case there's only one person in summon queue we don't need the table
                local friend = GetPlayerByName(friendName)
				if friend and friend:IsAlive() and not friend:IsInCombat()
				and not friend:IsOnVehicle() and not friend:IsFalling()
				and not friend:InArena() and not friend:InBattleground() then -- simple sanity check
					eligibleSummon[player:GetName()] = nil
					summonrequest = player:GetName()
					ShowSummonRequest(friend)
					summonCD[accountId] = os.time() + 2 * 60 -- 2 min cd between summons
					summonerGraceTimer[accountId] = os.time() + 2 * 60 -- Probably a duplicate but I'm tired so who cares
				else
                    player:SendBroadcastMessage(friend:GetName().." isn't able to receive summon requests right now.")
				end	
            end
		end
        return false
    end
	
    if command:lower() == "rafmenu" or command:lower() == "referalmenu" then
        ShowRAFMenu(player)
        return false -- Prevent further command processing
    end

    if command:lower() == "referalinfo" or command:lower() == "rafinfo" then
        local accountId = player:GetAccountId()
        local query = AuthDBQuery(string.format([[
            SELECT account_id, status, date FROM account_raf WHERE referer_id = %d
        ]], accountId))

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
        return false
    end

    if (cmd == "rafreferee" and param) or (cmd == "rafrefer" and param) or (cmd == "refer" and param) then
		if player:GetGMRank() > 0 then
			local referer_id = tonumber(param)
			
			if accountId == referer_id then
				player:SendBroadcastMessage("You can't refer yourself!")
				return false
			end

			local currentTime = os.time()
			local playerIP = player:GetPlayerIP()

			AuthDBExecute(string.format([[
				INSERT INTO account_raf (account_id, referer_id, status, progress, date, IP)
				VALUES (%d, %d, 2, 0, %d, '%s')
				ON DUPLICATE KEY UPDATE referer_id = %d, status = 2, progress = 0, date = %d, IP = '%s'
			]], accountId, referer_id, currentTime, playerIP, referer_id, currentTime, playerIP))

			RAFreferee[accountId] = true
			player:SendBroadcastMessage(string.format("You have been registered as a referee with referer ID: %d", referer_id))
		end
        return false
    elseif cmd == "rafdelete" and param then
        if player:GetGMRank() > 0 then
            local account_to_delete = tonumber(param)
            AuthDBExecute(string.format([[
                DELETE FROM account_raf WHERE account_id = %d
            ]], account_to_delete))

            if RAFreferee[account_to_delete] == true then
                RAFreferee[account_to_delete] = nil
            end

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
local function CheckRefereeStatus(player)
    local accountId = player:GetAccountId()
    local MaxRAFDuration = os.time() - RAFDuration
    local playerIP = player:GetPlayerIP()

    local query = AuthDBQuery(string.format([[
        SELECT 1 FROM account_raf
        WHERE account_id = %d AND status = 2 AND date > %d
    ]], accountId, MaxRAFDuration))

    if query then
        AuthDBExecute(string.format([[
            UPDATE account_raf SET IP = '%s' WHERE account_id = %d
        ]], playerIP, accountId))
        RAFreferee[accountId] = true
    else
        RAFreferee[accountId] = nil
    end
end

local function ClearRefereeStatus(event, player)
    local accountId = player:GetAccountId()
    if RAFreferee[accountId] == true then
        RAFreferee[accountId] = nil
    end
end

-- Check referee status on player login and server load
local function OnPlayerLogin(event, player)
    CheckRefereeStatus(player)
end

local function ReloadEluna(event)
    local players = GetPlayersInWorld()
    for _, player in ipairs(players) do
        CheckRefereeStatus(player)
    end
end

-- Update progress on creature kill and area change
local function UpdateProgress(player)
    local accountId = player:GetAccountId()
    if RAFreferee[accountId] then
        AuthDBExecute(string.format([[
            UPDATE account_raf SET progress = progress + 1 WHERE account_id = %d
        ]], accountId))
    end
end

local function OnSave(event, player)
    UpdateProgress(player)
end

local function OnAchievementComplete(event, player, achievementId)
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
    for refereeAccountId, _ in pairs(RAFreferee) do
        local query = AuthDBQuery(string.format([[
            SELECT progress, referer_id FROM account_raf WHERE account_id = %d AND status = 2
        ]], refereeAccountId))
        
        if query then
            local progress = query:GetUInt32(0)
            local refererId = query:GetUInt32(1)
            
            if progress >= RAFRewardReq then
                AuthDBExecute(string.format([[
                    UPDATE account_raf SET status = 3 WHERE account_id = %d
                ]], refereeAccountId))
                
                local players = GetPlayersInWorld()
                
                -- Send message to the referred player (referee) if they're online
                for _, player in ipairs(players) do
                    if player:GetAccountId() == refereeAccountId then
						message = "Twiggy: Congratulations, you've qualified for your referee reward! You have earned ".. TokenReward .." ".. TokenName.. " and a special reward, speak to me to claim it."
						SendPurpleBroadcast(player, message)
						player:AddItem(TokenID, TokenReward)
                        RAFreferee[refereeAccountId] = nil
                        break
                    end
                end
                
                -- Check referer's status 1 second after changing entry in DB, to allow for time to update
				CreateLuaEvent(function()
					local players = GetPlayersInWorld()
					local query2 = AuthDBQuery(string.format([[
						SELECT COUNT(*) as count FROM account_raf WHERE referer_id = %d AND status > 2
					]], refererId))
					
					if query2 then
						AuthDBExecute(string.format([[
							UPDATE account_raf SET status = 4 WHERE account_id = %d
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
						for _, player in ipairs(players) do
							if player:GetAccountId() == refererId then
								SendPurpleBroadcast(player, message)
								refererOnline = true
								break
							end
						end
						if not refererOnline then
							local charactersQuery = CharDBQuery(string.format([[
								SELECT guid, name FROM characters WHERE account = %d
							]], refererId))
							if charactersQuery then
								repeat
									local charGUIDLow = charactersQuery:GetUInt32(0)
									local charName = charactersQuery:GetString(1)
									-- Create and send mail to each character
									local subject = "Refer a Friend Reward"
									if referralCount == 0 then
										body = "Dear ".. charName .."! I bear happy news!\n\nYour first referral with ID ".. refereeAccountId .." has qualified for Refer a Friend rewards! You first special reward is ".. TokenReward .." ".. TokenName.. ", speak with me to claim it.\n\nYour personal branch of Yggdrasil,\nTwiggy"
									elseif referralCount == RewardTier1 or referralCount == RewardTier2 or referralCount == RewardTier3 or referralCount == RewardTier4 then
										body = "Dear ".. charName .."! I bear happy news!\n\nYour referee with ID ".. refereeAccountId .." has fulfilled the the requirements to earn you another special Refer a Friend reward of your choice! You have earned ".. TokenReward .." ".. TokenName.. " and a special reward, speak with me to claim it.\n\nYour personal branch of Yggdrasil,\nTwiggy"
									else
										body = "Dear ".. charName .."! I bear happy news!\n\nCongratulations! Your referee with ID ".. refereeAccountId .." has qualified for Refer a Friend rewards! You have earned ".. TokenReward .." ".. TokenName.. ". Check in with me any time to see how your referrals are going.\n\nYour personal branch of Yggdrasil,\nTwiggy"
									end
									-- Send mail to the character
									SendMail(subject, body, charGUIDLow, 0, 61)
								until not charactersQuery:NextRow()
							end
						end
					end
				end, 1000, 1)  -- 1000 milliseconds = 1 second
            end
        end
    end
end

CreateLuaEvent(CheckCompletedReferrals, ProgressCheckTimer * 60 * 1000, 0)
RegisterPlayerEvent(3, OnPlayerLogin)
RegisterPlayerEvent(4, ClearRefereeStatus)
RegisterPlayerEvent(7, OnCreatureKill)
RegisterPlayerEvent(25, OnSave)
RegisterPlayerEvent(27, OnAreaTrigger)
RegisterServerEvent(33, ReloadEluna)
RegisterPlayerEvent(42, RAFCommands)
RegisterPlayerEvent(45, OnAchievementComplete)
RegisterPlayerEvent(54, OnCompleteQuest)

RegisterPlayerGossipEvent(1, 2, OnGossipSelect) -- Register gossip selection event
print("[RAF]: Nick's friend referral module loaded!")