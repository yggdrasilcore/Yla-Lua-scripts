----------------------------------------------------------------------------------------------------
-- Conf
----------------------------------------------------------------------------------------------------

-- Global config
local EnableModule		= true		-- Enable == true, disable == false

-- Logger config
local EnableLogger		= true		-- Enable == true, disable == false
local LoggingInterval	= 15 		-- How often to write new log data to the database.
local EnableDebug		= true		-- Enables console debug prints

-- What events should we log?
local LogWorldUpdate	= true		-- Logs avg world update diff per logging interval, plus high world update diffs
local LogMapUpdate		= false		-- Logs high map update diffs. Currently causes crashes
local LogAuctionHouse	= true		-- Buy, sell, expire, remove auction
local LogMisc			= true		-- Weather, world triggers
local LogCMD			= true		-- Logs Eluna reloads, certain GM commands, and count of GM and player commands
local LogCharacter		= true		-- Logs character create/delete
local LogPlayerSave		= true		-- Counts how many players have been saved during the LoggingInterval
local LogAddon			= true		-- Logs count of addon chatter during the logging interval, and the most active sender
local LogDeleteWO		= true		-- Logs deletion of creatures and gameobjects
local LogLoginLogout	= true		-- Logs count of logins/logouts during logging interval

-- Specific logger configs
local HighDiffLimit		= 200		-- Diff, in ms, to trigger independent update time logging

-- Truncate config
local EnableTruncate	= true		-- Enable == true, disable == false
local TruncateOnStartup	= false		-- Enable == true, disable == false
local TruncateCutoff	= 48		-- How old the data should be to get truncated, in hours.
local DeleteInterval	= 60		-- How often to truncate old data, in hours. This leaves one entry per hour for all event types

----------------------------------------------------------------------------------------------------
-- End conf. Do not edit below unless you know what you're doing.
----------------------------------------------------------------------------------------------------

if not EnableLogger then return end
if LoggingInterval < 1 then error("[Eluna Server Logger]: Fatal error - Logger frequency cannot be lower than 1! Aborting.") end

CharDBExecute("CREATE TABLE IF NOT EXISTS statistics (event VARCHAR(32) NOT NULL, param1 INT UNSIGNED, param2 VARCHAR(32), param3 INT UNSIGNED);")

-- Cache tables

local event13Cache			= {}
local event24Cache			= {}
local event25Cache			= {}
local event26Cache			= {}
local event27Cache			= {}
local event28Cache			= {}
local event29Cache			= {}
local event30Cache			= {}
local event31Cache			= {}
local event32Cache			= {}
local CmdCache				= {}
local highWorldDiffCache	= {}
local highMapDiffCache		= {}
local playerSaveCache		= 0
local charCreate			= 0
local charDel				= 0
local charLogin				= 0
local charLogout			= 0
local GMCmd					= 0
local PCmd					= 0
local SessionID 			= os.time()
local DataPointCount		= 1

-- Helper functions

local function getMapId(object)
	return object:GetMap():GetMapId() or 0
end

-- Core function
local function CacheDataPoints()
	if EnableDebug then print("[Eluna Server Logger]: Storing data point ".. DataPointCount .. " for session ".. SessionID .." to database...") end
	local values = {}
	
	table.insert(values, "('pCount', " .. #GetPlayersInWorld() .. ", NULL, " .. os.time() .. ")")

	local totalDiff = 0
	for _, diff in ipairs(event13Cache) do
		totalDiff = totalDiff + diff
	end

	if #event13Cache > 0 then
		local avgDiff = totalDiff / #event13Cache
		table.insert(values, "('13av', " .. math.floor(avgDiff) .. ", NULL, " .. os.time() .. ")")
	end

	for timestamp, highDiff in pairs(highWorldDiffCache) do
		table.insert(values, "('13hi', " .. highDiff .. ", NULL, " .. timestamp .. ")")
	end

	for map, diffs in pairs(highMapDiffCache) do
		for timestamp, highDiff in pairs(diffs) do
			table.insert(values, "('23hi', " .. map .. ", " .. highDiff .. ", " .. timestamp .. ")")
		end
	end

	for trigger, count in pairs(event24Cache) do
		table.insert(values, "('24', " .. trigger .. ", " .. count .. ", " .. os.time() .. ")")
	end

	for zoneId, count in pairs(event25Cache) do
		table.insert(values, "('25', " .. zoneId .. ", " .. count .. ", " .. os.time() .. ")")
	end

	for owner, count in pairs(event26Cache) do
		table.insert(values, "('26', " .. count .. ", " ..  tostring(owner) .. ", " .. os.time() .. ")")
	end

	for owner, count in pairs(event27Cache) do
		table.insert(values, "('27', " .. count .. ", " ..  tostring(owner) .. ", " .. os.time() .. ")")
	end

	for bidder, count in pairs(event28Cache) do
		table.insert(values, "('28', " .. count .. ", " ..  tostring(bidder) .. ", " .. os.time() .. ")")
	end

	for owner, count in pairs(event29Cache) do
		table.insert(values, "('29', " .. count .. ", " ..  tostring(owner) .. ", " .. os.time() .. ")")
	end

	local total, maxSender, maxCount = 0, nil, 0
	for sender, count in pairs(event30Cache) do total, maxCount, maxSender = total + count, math.max(maxCount, count), count > maxCount and sender or maxSender end
	if maxCount > 0 then
		table.insert(values, string.format("('30', %s, %d, %d)", maxSender or "null", maxCount, os.time()))
	end
	
	for mapId, count in pairs(event31Cache) do
		table.insert(values, "('31', " .. mapId .. ", " .. count .. ", " .. os.time() .. ")")
	end

	for mapId, count in pairs(event32Cache) do
		table.insert(values, "('32', " .. mapId .. ", " .. count .. ", " .. os.time() .. ")")
	end

	for t, cmdData in pairs(CmdCache) do
		for cmd, guid in pairs(cmdData) do
			table.insert(values, "('GMcmd', " .. guid .. ", '" .. cmd .. "', " .. t .. ")")
		end
	end
	
	if playerSaveCache > 0 then
		table.insert(values, "('pSave', " .. playerSaveCache .. ", NULL, " .. os.time() .. ")")
	end
	
	if charCreate > 0 then
		table.insert(values, "('charCreate', " .. charCreate .. ", NULL, " .. os.time() .. ")")
	end
	
	if charDel > 0 then
		table.insert(values, "('charDel', " .. charDel .. ", NULL, " .. os.time() .. ")")
	end
	
	if charLogin > 0 then
		table.insert(values, "('charLogin', " .. charLogin .. ", NULL, " .. os.time() .. ")")
	end
	
	if charLogout > 0 then
		table.insert(values, "('charLogout', " .. charLogout .. ", NULL, " .. os.time() .. ")")
	end
	
	if GMCmd > 0 then
		table.insert(values, "('GMcmd', " .. GMCmd .. ", NULL, " .. os.time() .. ")")
	end
	
	if PCmd > 0 then
		table.insert(values, "('Pcmd', " .. PCmd .. ", NULL, " .. os.time() .. ")")
	end
	
	if #values > 0 then
		local query = "INSERT INTO statistics (event, param1, param2, param3) VALUES " .. table.concat(values, ",") .. ";"
		if EnableDebug then print("[Eluna Server Logger]: Inserting query - "..query) end
		CharDBExecute(query)
	end

	event13Cache		= {}
	event24Cache		= {}
	event25Cache		= {}
	event26Cache		= {}
	event27Cache		= {}
	event28Cache		= {}
	event29Cache		= {}
	event30Cache		= {}
	event31Cache		= {}
	event32Cache		= {}
	CmdCache			= {}
	highWorldDiffCache	= {}
	highMapDiffCache	= {}
	playerSaveCache		= 0
	charCreate			= 0
	charDel				= 0
	charLogin			= 0
	charLogout			= 0
	GMCmd				= 0
	PCmd				= 0
	DataPointCount		= DataPointCount + 1
end

local function CleanOldData()
    local truncateTime = os.time() - (TruncateCutoff * 60 * 60)
    local oneHourAgo = os.time() - (DeleteInterval * 60)
    local query = string.format([[
    DELETE FROM statistics
    WHERE param3 < %d
    AND param3 NOT IN (
        SELECT max_param3
        FROM (
            SELECT MAX(param3) AS max_param3
            FROM statistics
            WHERE param3 >= %d
            GROUP BY event, DATE_FORMAT(FROM_UNIXTIME(param3), '%%Y-%%m-%%d %%H')
        ) AS temp_max_param3
    );
    ]], truncateTime, oneHourAgo)
    CharDBExecute(query)
end

-- Functions to handle registration data input

local function OnWorldUpdate(event, diff)
	table.insert(event13Cache, diff)
	
	if diff > HighDiffLimit then highWorldDiffCache[os.time()] = diff end
end

local mapThrottle = 0

local function OnMapUpdate(event, map, diff)
	if diff > HighDiffLimit then 
		if mapThrottle >= os.time() then print("throttled") return end
		if highWorldDiffCache[os.time()] or highWorldDiffCache[os.time() - 1] then return end
		print("High map update diff detected!")
		highMapDiffCache[map:GetMapId()] = highMapDiffCache[map:GetMapId()] or {};
		highMapDiffCache[map:GetMapId()][os.time()] = diff
		mapThrottle = os.time() + 1
	end
end

local function OnTriggerEvent(event, player, triggerId)
	event24Cache[triggerId] = (event24Cache[triggerId] or 0) + 1
end

local function OnWeatherEvent(event, zoneId, state, grade)
	event25Cache[zoneId] = (event25Cache[zoneId] or 0) + 1
end

local function OnAuctionAdd(event, auctionId, owner, item, expireTime, buyout, startBid, currentBid, bidderGUIDLow)
	local ownerGuid = owner:GetGUIDLow()
	event26Cache[ownerGuid] = (event26Cache[ownerGuid] or 0) + 1
end

local function OnAuctionRemove(event, auctionId, owner, item, expireTime, buyout, startBid, currentBid, bidderGUIDLow)
	local ownerGuid = owner:GetGUIDLow()
	event27Cache[ownerGuid] = (event27Cache[ownerGuid] or 0) + 1
end

local function OnAuctionSuccessful(event, auctionId, owner, item, expireTime, buyout, startBid, currentBid, bidderGUIDLow)
	event28Cache[bidderGUIDLow] = (event28Cache[bidderGUIDLow] or 0) + 1
end

local function OnAuctionExpire(event, auctionId, owner, item, expireTime, buyout, startBid, currentBid, bidderGUIDLow)
	local ownerGuid = owner:GetGUIDLow()
	event29Cache[ownerGuid] = (event29Cache[ownerGuid] or 0) + 1
end

local function OnAddonEvent(event, sender, type, prefix, msg, target)
	local senderGuid = sender:GetGUIDLow()
	event30Cache[senderGuid] = (event30Cache[senderGuid] or 0) + 1
end

local function OnDeleteCreature(event, creature)
	local mapId = getMapId(creature)
	event31Cache[mapId] = (event31Cache[mapId] or 0) + 1
end

local function OnDeleteGameObject(event, gameobject)
	local mapId = getMapId(gameobject)
	event32Cache[mapId] = (event32Cache[mapId] or 0) + 1
end

local function OnCmd(event, player, command)
	local currentTime = os.time()
	
	if event == 33 then
		CmdCache[currentTime] = CmdCache[currentTime] or {}
		CmdCache[currentTime]["reload Eluna"] = 0
		return
	end
	
	if not player then return end
	
	if player:GetGMRank() > 0 then
		GMCmd = GMCmd + 1
		local firstWord = command:match("^(%S+)")
		if not firstWord then return end
		firstWord = firstWord:lower()
		
		if firstWord == "reload" or firstWord == "list" or firstWord == "lookup" then
			CmdCache[currentTime] = CmdCache[currentTime] or {}
			CmdCache[currentTime][command:sub(1, 32)] = player:GetGUIDLow()
			return
		end
	else
		PCmd = PCmd + 1
	end
end

local function CharacterEvent(event, player)
	if event == 1 then
		charCreate = charCreate + 1
	elseif event == 2 then
		charDel = charDel + 1
	elseif event == 3 then
		charLogin = charLogin + 1
	elseif event == 4 then
		charLogout = charLogout + 1
	elseif event == 25 then
		playerSaveCache = playerSaveCache + 1
	end
end

-- Event registrations

if EnableLogger then
	local EnabledLoggers = 0
	if LogWorldUpdate then
		RegisterServerEvent(13, OnWorldUpdate)
		EnabledLoggers = EnabledLoggers + 1
	end
	if LogMapUpdate then
		RegisterServerEvent(23, OnMapUpdate)
		EnabledLoggers = EnabledLoggers + 1
	end
	if LogMisc then
		RegisterServerEvent(24, OnTriggerEvent)
		RegisterServerEvent(25, OnWeatherEvent)
		EnabledLoggers = EnabledLoggers + 1
	end
	if LogAuctionHouse then
		RegisterServerEvent(26, OnAuctionAdd)
		RegisterServerEvent(27, OnAuctionRemove)
		RegisterServerEvent(28, OnAuctionSuccessful)
		RegisterServerEvent(29, OnAuctionExpire)
		EnabledLoggers = EnabledLoggers + 1
	end
	if LogAddon then
		RegisterServerEvent(30, OnAddonEvent)
		EnabledLoggers = EnabledLoggers + 1
	end
	if LogDeleteWO then
		RegisterServerEvent(31, OnDeleteCreature)
		RegisterServerEvent(32, OnDeleteGameObject)
		EnabledLoggers = EnabledLoggers + 1
	end
	if LogPlayerSave then
		RegisterPlayerEvent(25, CharacterEvent)
		EnabledLoggers = EnabledLoggers + 1
	end
	if LogCMD then
		RegisterServerEvent(33, OnCmd)
		RegisterPlayerEvent(42, OnCmd)
		EnabledLoggers = EnabledLoggers + 1
	end
	if LogCharacter then
		RegisterPlayerEvent(1, CharacterEvent)
		RegisterPlayerEvent(2, CharacterEvent)
		EnabledLoggers = EnabledLoggers + 1
	end
	if LogLoginLogout then
		RegisterPlayerEvent(3, CharacterEvent)
		RegisterPlayerEvent(4, CharacterEvent)
		EnabledLoggers = EnabledLoggers + 1
	end
	if EnabledLoggers == 0 then
		error("[Eluna Server Logger]: Fatal error - Logging is enabled but all loggers are disabled. Aborting.")
	end
	CreateLuaEvent(CacheDataPoints, LoggingInterval * 60 * 1000, 0)
if EnableDebug then print("[Eluna Server Logger]: Server logger loaded with session ID "..SessionID..". Storing data every "..LoggingInterval.." minutes. Truncating enabled: "..tostring(EnableTruncate)) end
end

if EnableTruncate then
	if TruncateOnStartup then
		CleanOldData()
	end
	if not EnableLogger then
		print("[Eluna Server Logger]: Warning - Truncate is enabled but nothing is being logged.")
	end
	CreateLuaEvent(CleanOldData, DeleteInterval * 60 * 1000, 0)
end
