-- BUFF IDS
local SWIFT_FLIGHT_FORM_AURA = 40120 -- TO-DO, merge with below BUFF_IDS
local SLOW_FLIGHT_FORM_AURA = 33943 -- TO-DO, merge with below BUFF_IDS
local BUFF_IDS = {33943, 40120} -- Used as simplification in certain functions
local CHANNEL_SPELL_ID = 32783  -- Spell visual
local PARACHUTE_SPELL_ID = 44795

-- ITEM IDS-- ITEM IDS
local ITEM_IDS = {39163, 28326, 20739, 208800} -- Items used to trigger initial cast

-- TIMERS - CHANGE IF HIGH SERVER LOAD FROM FLYING
local PROBLEMZONEDELAY = 5 -- Increase if lag. Flight form is applied thrice on break as many zone/area changes are jagged and break your form multiple times. This is the delay between applications in ms. Extend to 2-20 if lag.
local REPETITIONS_ON_REAPPLY = 2 -- Reduce if lag. Makes normal reapplication happen twice as sanity checks are sometimes delayed.
local REAPPLICATION_ON_BREAK_CHECK_INTERVAL = 2 -- Increase if lag. Checks if flight form breaks unintendedly every X ms and repaplies if it does. 1 is seamless. 10 virtually seamless. 50 not so seamless. At 100, character is sometimes visible. Incrase if lag. 
local FALLING_CHECK_INTERVAL = 20 -- Increase if lag. Sanity check if gravity takes control of bird
local FLIGHTFORM_SANITY_CHECK_INTERVAL = 100 -- Increase if lag. Sanity check timer if flight form drops unintendedly but other checks fail, in ms
local UPDATE_INTERVAL = 100 -- Increase if lag. Used to store XYZ and flight status on map change, to reapply after leaving RDF
local PARACHUTE_CHECK_INTERVAL = 20 -- Increase if lag. Applies parachute if player was flying within the last FLIGHT_CHECK_INTERVAL and suddenly is not flying anymore
local FLIGHT_CHECK_INTERVAL = 500 -- X ms of parachute "immunity", prevents parachute from spawning from other flying events than Feathers of Azeroth

-- VARIABLES
local AREA_CACHE = 50 -- Reduce if lag. Cache of area snapshots, used as a failsafe to see if player is falling around an area change. This cache is built on every parachute check re PARACHUTE_CHECK_INTERVAL
local OBSTACLE_CHECK_DISTANCE = 5 -- Yards. Increase if parachute activates too close to ground. 
local TELEPORT_Z_OFFSET = 0.2 -- Adjusts height of player if hit Z cap, prevents them getting stuck flying upwards. Most areas don't use this. 
local checkHeight = 25  -- Adjust this value based on typical indoor ceiling heights. 25 works reasonably well, conisder higher values. 
local checkSWHeight = 12  -- SW is really jank in most districts so elevation cap set specifically.

-- ELEVATION BARRIERS
local MAX_Z = 1000 -- Max Z in Kalimdor and Eastern Kingdoms unless zone/area exception
local SILVERMOON_MAX_Z = 50
local ISLEOFQD_MAX_Z = 81
local ORGRIMMAR_MAX_Z = 62.5
local UNDERCITY_MAX_Z = 80
local RUINSOFLORADERON_MAX_Z = 78
local SWHARBOR_ZONE_MAX_Z = 110 -- Used with polygon
local SW_MAGE_TOWER_Z = 133 -- Used with polygon
local SW_ENTRANCE_Z = 106 -- Used with polygon
local SW_FP_Z = 120 -- Used with polygon
local SW_MAGE_DISTRICT_Z = 125 -- Used with polygon
local SW_Z = 115 -- Areas of SW not covered by above polygon Zs

-- CONSTANTS
local FlightAfterInstance = false
local lastUpdateTime = 0 -- Don't change this
local isReapplyingFlyAura = false -- Makes sure that player:Data():Get("isflying") check's reapplication and area change reapplication don't interfere with each othere
local CarryMessage = false -- Tracks if player has received message that Feathers of Azeroth carry them, to prevent repeat use to spam player

-- DATA TABLES (DO NOT CHANGE)
local LAST_WARNING_TIME = {}  -- Table to store the last warning time for each player, to not flood chat box
local flyingPlayers = {} -- Tracks all players in world 
local playerData = {}
local timerMap = {} 
local playerQuestStatus = {} -- Quest status changes break flight form, so we're storing active quests in a table to check against changes every X MS
local positionData = {} -- Used to reapply flight form on leaving RDF/instance

local QUEST_STATUS = {-- Re playerQuestStatus
    NONE = 0,
    COMPLETE = 1,
    UNAVAILABLE = 2,
    INCOMPLETE = 3,
    AVAILABLE = 4,
    FAILED = 5
}

-- MAPS
local EASTERN_KINGDOMS = 0
local KALIMDOR = 1
local OUTLAND_MAP = 530
local MAP_CHANGE_TO_REAPPLY_FLIGHT_FORM = {0, 1, 530} -- Used to track players leaving instances

-- ZONES
local TELDRASSIL = 141
local DARNASSUS = 1657
local ORGRIMMAR = 1637
local WINTERSPRING = 493
local UNDERCITY = 1497
local RUINSOFLORDAERON = 153
local SHININGSTRAND = 927
local ASHENVALE = 331
local SILVERMOON = 3487
local ISLEOFQD = 4080
local GHOSTLANDS = 3433
local EVERSONG = 3430
local FELWOOD = 361
local HYJAL = 616
local STORMWIND = 1519
local SWHARBOR = 4411
-- local PROBLEM_AREAS = {2273, 2274, 3433, 3496, 3513, 3914} -- Deprecated, keeping in case these come in handy later

local SW_PARK = {
    {x = -8756, y = 918},
    {x = -8663, y = 978},
    {x = -8688, y = 1165},
    {x = -8793, y = 1207},
    {x = -8826, y = 1101},
    {x = -8794, y = 993},
    {x = -8756, y = 918}
}

-- Mage District polygon matrix
local SW_MAGE_DISTRICT = {
  {x = -8867, y = 930}, 
  {x = -8885, y = 973}, 
  {x = -8924, y = 1014}, 
  {x = -8969, y = 990}, 
  {x = -8995, y = 993}, 
  {x = -9022, y = 959}, 
  {x = -9044, y = 906}, 
  {x = -9065, y = 856}, 
  {x = -9022, y = 789}, 
  {x = -8974, y = 811}, 
  {x = -8934, y = 835}, 
  {x = -8933, y = 888}, 
  {x = -8918, y = 903}, 
  {x = -8871, y = 898}, 
  {x = -8846, y = 913}, 
  {x = -8867, y = 930}
}

-- Inside part of mage tower, to prevent people from flying inside
local INSIDE_SW_MAGE_TOWER = {
  {x = -8997, y = 868}, 
  {x = -9007, y = 861}, 
  {x = -9014, y = 865}, 
  {x = -9016, y = 871}, 
  {x = -9015, y = 877}, 
  {x = -9009, y = 880}, 
  {x = -9003, y = 880}, 
  {x = -8998, y = 875}, 
  {x = -8997, y = 868}
}

-- Outer mage tower polygon matrix
local SW_MAGE_TOWER = {
    {x = -8963, y = 870},
    {x = -8980, y = 905},
    {x = -9023, y = 896},
    {x = -9033, y = 860},
    {x = -9007, y = 832}
}

local SW_STOCKADES = {
    {x = -8810, y = 809},
    {x = -8752, y = 801},
    {x = -8750, y = 859},
    {x = -8810, y = 809}
}

-- Grass ramp on left side of passageway from the canals has low collission barrier and needs exception
local MAGE_DISTRICT_EXCEPTION = {
    {x = -8953, y = 788},
    {x = -8984, y = 813},
    {x = -9005, y = 808},
    {x = -8990, y = 772},
    {x = -8949, y = 751},
    {x = -8953, y = 788}
}

local SW_CASTLE = {
    {x = -8606, y = 410},
    {x = -8407, y = 247},
    {x = -8261, y = 354},
    {x = -8298, y = 544},
    {x = -8298, y = 544},
    {x = -8412, y = 535},
    {x = -8606, y = 410}
}

local SW_OLD_TOWN = {
    {x = -8700, y = 363},
    {x = -8588, y = 439},
    {x = -8660, y = 534},
    {x = -8769, y = 447},
    {x = -8750, y = 407},
    {x = -8769, y = 393},
    {x = -8723, y = 384},
    {x = -8700, y = 363}
}

local SW_DWARVEN_DISTRICT = {
    {x = -8407, y = 686},
    {x = -8290, y = 616},
    {x = -8506, y = 509},
    {x = -8570, y = 582},
    {x = -8407, y = 686}
}

local SW_CHURCH = {
    {x = -8593, y = 814},
    {x = -8573, y = 787},
    {x = -8547, y = 783},
    {x = -8506, y = 737},
    {x = -8366, y = 826},
    {x = -8466, y = 934},
    {x = -8526, y = 910},
    {x = -8571, y = 936},
    {x = -8606, y = 891},
    {x = -8567, y = 834},
    {x = -8593, y = 814}
}

local SW_DWARVEN_DISTRICT_EXCEPTION = {
    {x = -8400, y = 654},
    {x = -8410, y = 668},
    {x = -8453, y = 634},
    {x = -8446, y = 582},
    {x = -8420, y = 638},
    {x = -8399, y = 657},
    {x = -8400, y = 654}
}

local SW_CANALS = {
    {x = -8785, y = 452},
    {x = -8822, y = 500},
    {x = -8877, y = 538},
    {x = -8705, y = 625},
    {x = -8738, y = 694},
    {x = -8780, y = 740},
    {x = -8902, y = 689},
    {x = -8926, y = 721},
    {x = -8830, y = 811},
    {x = -8857, y = 845},
    {x = -8834, y = 886},
    {x = -8876, y = 959},
    {x = -8831, y = 988},
    {x = -8750, y = 895},
    {x = -8643, y = 963},
    {x = -8617, y = 930},
    {x = -8722, y = 827},
    {x = -8711, y = 792},
    {x = -8724, y = 757},
    {x = -8636, y = 659},
    {x = -8492, y = 730},
    {x = -8458, y = 697},
    {x = -8578, y = 566},
    {x = -8533, y = 494},
    {x = -8565, y = 461},
    {x = -8662, y = 549},
    {x = -8783, y = 451},
    {x = -8785, y = 452}
}

-- SW Entrance polygon matrix
local SW_ENTRANCE = {
    {x = -8786, y = 437},
    {x = -8816, y = 434},
    {x = -8878, y = 509},
    {x = -8923, y = 510},
    {x = -8956, y = 550},
    {x = -8947, y = 594},
    {x = -9021, y = 698},
    {x = -8946, y = 735},
    {x = -8882, y = 618},
    {x = -8863, y = 551}
}

local SW_FP = {
    {x = -8853, y = 554},
    {x = -8887, y = 524},
    {x = -8847, y = 490},
    {x = -8844, y = 529}
}

local function CharacterFlyingTable() -- Ensures existence of table used for sanity checks on login/logout, instances, etc.
    CharDBExecute([[
        CREATE TABLE IF NOT EXISTS character_flying (
            GUID BIGINT NOT NULL,
            isflying TINYINT(1) NOT NULL DEFAULT 0,
            posX FLOAT,
            posY FLOAT,
            posZ FLOAT,
            mapID INT,
            PRIMARY KEY (GUID)
        );
    ]])
end

local function CreatePlayerTimer(player, delay, callback) -- Used for parachute delay
    local playerData = player:GetData("flyingData") or {}
    playerData.timers = playerData.timers or {}
    local timerId = math.random(1, 1000000)
    playerData.timers[timerId] = {
        executeTime = os.time() + delay,
        callback = callback
    }
    player:SetData("flyingData", playerData)
    return timerId
end

local function CheckTimers() -- Used for delaying the parachute
    local currentTime = os.time()
    for timerId, timer in pairs(timerMap) do
        if currentTime >= timer.executeTime then
            timer.callback()
            timerMap[timerId] = nil
        end
    end
end

local function CheckObstaclesForPlayer(player)
    local x, y, z = player:GetLocation()
    --print("Player location:", x, y, z)
    
    local checkZ = z - OBSTACLE_CHECK_DISTANCE
    --print("Check Z:", checkZ)
    
    local allWithinLoS = true  -- Flag to track if all checks pass
    
    -- Check multiple points
    for i = 0, OBSTACLE_CHECK_DISTANCE * 2, 0.5 do
        local testZ = z - i
        local success, isWithinLoS = pcall(function() return player:IsWithinLoS(x, y, testZ) end)
        --print(string.format("Test Z: %.2f, IsWithinLoS: %s", testZ, tostring(isWithinLoS)))
        
        if not (success and isWithinLoS) then
            allWithinLoS = false
            break  -- Exit the loop early if any check fails
        end
    end
    
    local isNearBuilding = not allWithinLoS
    --print("Is near building:", isNearBuilding)
    
    -- Ground check
    local success, ground = pcall(function() return player:GetMap():GetHeight(x, y, z and z >= 0 and z or 0.01) end)
    if ground == nil then
		ground = 0.01
	end
	if not success or ground < 0.01
	then
        ground = 0.01
    end
    --print("GetHeight check success:", success)
    --print("Ground height:", ground)
    
    local distanceToGround = z - ground
    --print("Distance to ground:", distanceToGround)
    local isNearGround = distanceToGround <= OBSTACLE_CHECK_DISTANCE
    --print("Is near ground:", isNearGround)
    
    local isNearObstacle = isNearBuilding or isNearGround
    --print("Is near obstacle:", isNearObstacle)
    
    return isNearObstacle
end

local function DelayedParachuteCheck(player, areaId)
    local randomDelay = math.random() * 0.04  -- Random delay between 0 and 0.2 seconds
    CreatePlayerTimer(player, 0.48 + randomDelay, function(p)
        if p and p:IsInWorld() then
            local isNearObstacle = CheckObstaclesForPlayer(p)
            
            if (not p:HasAura(SLOW_FLIGHT_FORM_AURA) and not p:HasAura(SWIFT_FLIGHT_FORM_AURA)) and not p:HasAura(PARACHUTE_SPELL_ID) and not isNearObstacle then
                print("[AZEROTH FLIGHT MODULE]: ALERT! Flying player ID ".. p:GetGUIDLow() .." has no flight form, applying parachute! Area: "..areaId)
                p:AddAura(PARACHUTE_SPELL_ID, p)
                p:SendBroadcastMessage("Oh no! Your Feathers have flown away!")
            end
        end
    end)
end

local function contains(table, value) -- Breaks up some of the {} tables above, not used consistently. Perhaps a to-do
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

local function isPointInPolygon(x, y, polygon) -- Checks if player is within specified boundaries
    local odd = false
    local j = #polygon
    for i = 1, #polygon do
        if (polygon[i].y < y and polygon[j].y >= y or polygon[j].y < y and polygon[i].y >= y) and
           (polygon[i].x <= x or polygon[j].x <= x) then
            if polygon[i].x + (y - polygon[i].y) / (polygon[j].y - polygon[i].y) * (polygon[j].x - polygon[i].x) < x then
                odd = not odd
            end
        end
        j = i
    end
    return odd
end

local function CheckPlayerHeight(player) -- Function to teleport players down if they hit the Z cap
    local mapId = player:GetMapId()
    local zoneId = player:GetZoneId()
	local areaId = player:GetAreaId()
	local x, y, z = player:GetLocation()
	--local mapForMaxZ = player:GetMap() -- May be used to teleport to in unusual circumstances? Not in use currently
    --local mapZ = mapForMaxZ:GetHeight(x, y) -- ibid
	
    local maxObjectZ = z - 1
	local canTeleport = player:IsWithinLoS(x, y, maxObjectZ)
	
    if (mapId == OUTLAND_MAP and zoneId == SILVERMOON) or zoneId == ISLEOFQD or zoneId == EVERSONG or zoneId == GHOSTLANDS or mapId == EASTERN_KINGDOMS or (mapId == KALIMDOR and zoneId ~= TELDRASSIL and zoneId ~= DARNASSUS and zoneId ~= HYJAL and zoneId ~= WINTERSPRING and zoneId ~= ASHENVALE and zoneId ~= FELWOOD) then
        local maxAllowedZ = MAX_Z
        local teleportZ = MAX_Z - TELEPORT_Z_OFFSET
        if zoneId == ORGRIMMAR then
            maxAllowedZ = ORGRIMMAR_MAX_Z
            teleportZ = ORGRIMMAR_MAX_Z
        end
        if zoneId == UNDERCITY then
            maxAllowedZ = UNDERCITY_MAX_Z
            teleportZ = UNDERCITY_MAX_Z-1
        end
        if areaId == RUINSOFLORDAERON then
            maxAllowedZ = RUINSOFLORADERON_MAX_Z
            teleportZ = RUINSOFLORADERON_MAX_Z-1
        end
        if areaId == SHININGSTRAND then
            maxAllowedZ = RUINSOFLORADERON_MAX_Z
            teleportZ = RUINSOFLORADERON_MAX_Z-1
        end
        if zoneId == SILVERMOON then
            maxAllowedZ = SILVERMOON_MAX_Z
            teleportZ = SILVERMOON_MAX_Z
        end
        if zoneId == ISLEOFQD then
            maxAllowedZ = ISLEOFQD_MAX_Z
            teleportZ = ISLEOFQD_MAX_Z
        end
        if zoneId == SWHARBOR then -- SW polygons
            maxAllowedZ = SWHARBOR_ZONE_MAX_Z
            teleportZ = SWHARBOR_ZONE_MAX_Z
        elseif mapId == EASTERN_KINGDOMS and isPointInPolygon(x, y, SW_MAGE_TOWER) then
            maxAllowedZ = SW_MAGE_TOWER_Z
            teleportZ = SW_MAGE_TOWER_Z
        elseif mapId == EASTERN_KINGDOMS and isPointInPolygon(x, y, SW_MAGE_DISTRICT) then
            maxAllowedZ = SW_MAGE_DISTRICT_Z
            teleportZ = SW_MAGE_DISTRICT_Z
        elseif mapId == EASTERN_KINGDOMS and isPointInPolygon(x, y, SW_FP) then
            maxAllowedZ = SW_FP_Z
            teleportZ = SW_FP_Z
        elseif mapId == EASTERN_KINGDOMS and isPointInPolygon(x, y, SW_ENTRANCE) then
            maxAllowedZ = SW_ENTRANCE_Z
            teleportZ = SW_ENTRANCE_Z
			
        elseif zoneId == STORMWIND then
            maxAllowedZ = SW_Z
			teleportZ = SW_Z
		end
        
        if z > maxAllowedZ and canTeleport then
            local currentTime = os.time()
            player:Teleport(mapId, x, y, teleportZ, player:GetO())
            if not LAST_WARNING_TIME[player:GetGUIDLow()] or currentTime - LAST_WARNING_TIME[player:GetGUIDLow()] >= 5 then
                player:SendBroadcastMessage("You can't fly that high in this area!")
                LAST_WARNING_TIME[player:GetGUIDLow()] = currentTime
            end
            if not player:HasAura(SWIFT_FLIGHT_FORM_AURA) and not player:HasAura(SLOW_FLIGHT_FORM_AURA) then
                playerData[player:GetGUIDLow()] = playerData[player:GetGUIDLow()] or {}
				playerData[player:GetGUIDLow()].isflying = false
                flyingPlayers[player:GetGUIDLow()] = nil
            end
		elseif z > maxAllowedZ and not canTeleport then
			if player:HasAura(SWIFT_FLIGHT_FORM_AURA) then
				player:RemoveAura(SWIFT_FLIGHT_FORM_AURA)
			elseif player:HasAura(SLOW_FLIGHT_FORM_AURA) then
				player:RemoveAura(SLOW_FLIGHT_FORM_AURA)
			end
			player:SendBroadcastMessage("You can't fly here.")
        end
    end
end

local function CheckFlightForm(event, delay, repeats) -- Registers whether player is flying or not, used to reapply aura if it drops
    
    local players = GetPlayersInWorld()

    for _, player in ipairs(players) do
        if player and type(player) == "userdata" then
            local isFlying = player:HasAura(SWIFT_FLIGHT_FORM_AURA) or player:HasAura(SLOW_FLIGHT_FORM_AURA)
            
            playerData[player:GetGUIDLow()] = playerData[player:GetGUIDLow()] or {}
            playerData[player:GetGUIDLow()].isflying = isFlying
            
            if isFlying and not flyingPlayers[player:GetGUIDLow()] then
                flyingPlayers[player:GetGUIDLow()] = player
            elseif not isFlying and flyingPlayers[player:GetGUIDLow()] then
                flyingPlayers[player:GetGUIDLow()] = nil
            end
        end
    end

    local count = 0
    for _, player in pairs(flyingPlayers) do -- I don't think this is used for anything anymore
        count = count + 1
    end
    -- print("[AZEROTH FLIGHT MODULE]: Number of flying players: " .. count)
end

local function ReapplyFlyAura(eventId, delay, repeats, worldobject) -- Reapplies flight aura on break as called by other functions and flight sanity check circumventions
    local player = worldobject
    
    if not player or type(player) ~= "userdata" then
        print("[AZEROTH FLIGHT MODULE]: Error: Invalid player object in ReapplyFlyAura!")
        return
    end

    local mapId = player:GetMapId()
    local zoneId = player:GetZoneId()
    local areaId = player:GetAreaId()

    if mapId == 0 or mapId == 1 then
        if player:HasSpell(34091) or player:HasSpell(34093) then
            player:AddAura(SWIFT_FLIGHT_FORM_AURA, player)
			playerData[player:GetGUIDLow()] = playerData[player:GetGUIDLow()] or {}
			playerData[player:GetGUIDLow()].isflying = true
            flyingPlayers[player:GetGUIDLow()] = player
			--print("[AZEROTH FLIGHT MODULE]: Flight form reapplied for character ID: ".. player:GetGUIDLow())
        elseif player:HasSpell(34090) or player:HasSpell(34092) then
            player:AddAura(SLOW_FLIGHT_FORM_AURA, player)
			playerData[player:GetGUIDLow()] = playerData[player:GetGUIDLow()] or {}
			playerData[player:GetGUIDLow()].isflying = true
            flyingPlayers[player:GetGUIDLow()] = player
			--print("[AZEROTH FLIGHT MODULE]: Flight form reapplied for character ID: ".. player:GetGUIDLow())
        end
    elseif zoneId == 3430 or zoneId == 3433 or zoneId == 3557 or zoneId == 3524 or zoneId == 4080 or zoneId == 3487 or zoneId == 3455 or zoneId == 3525 or zoneId == 3479 then
        if player:HasSpell(34091) or player:HasSpell(34093) then
            player:AddAura(SWIFT_FLIGHT_FORM_AURA, player)
			playerData[player:GetGUIDLow()] = playerData[player:GetGUIDLow()] or {}
			playerData[player:GetGUIDLow()].isflying = true
            flyingPlayers[player:GetGUIDLow()] = player
			--print("[AZEROTH FLIGHT MODULE]: Flight form reapplied for character ID: ".. player:GetGUIDLow())
        elseif player:HasSpell(34090) or player:HasSpell(34092) then
            player:AddAura(SLOW_FLIGHT_FORM_AURA, player)
			playerData[player:GetGUIDLow()] = playerData[player:GetGUIDLow()] or {}
			playerData[player:GetGUIDLow()].isflying = true
            flyingPlayers[player:GetGUIDLow()] = player
			--print("[AZEROTH FLIGHT MODULE]: Flight form reapplied for character ID: ".. player:GetGUIDLow())
        end
    end
end

local function IsPlayerIndoors(player) -- As ELUNA has no functional method for tracking whether players are outdoors, our best approximation is measuring the Z distance to nearest LOS to prevent players from using Feather indoors
    local x, y, z = player:GetLocation()
 	local pointAbove = {x, y, z + checkHeight}
	
    if not player:IsWithinLoS(pointAbove[1], pointAbove[2], pointAbove[3]) then -- Check if there's an obstruction above the player
        return true  -- Player is likely indoors
    end
    
    return false  -- Player is likely outdoors
end

local function IsPlayerIndoorsSW(player) -- As ELUNA has no functional method for tracking whether players are outdoors, our best approximation is measuring the Z distance to nearest LOS to prevent players from using Feather indoors
    local x, y, z = player:GetLocation()
 	local pointAbove = {x, y, z + checkSWHeight}
	
    if not player:IsWithinLoS(pointAbove[1], pointAbove[2], pointAbove[3]) then -- Check if there's an obstruction above the player
        return true  -- Player is likely indoors
    end
    
    return false  -- Player is likely outdoors
end

local function ApplyFlyAura(eventId, delay, repeats, player) -- Initial application of flight aura as called by item use
    local actualPlayer = player or eventId
    
    if not actualPlayer or type(actualPlayer) ~= "userdata" then
        print("[AZEROTH FLIGHT MODULE]: Error: Invalid player object in ApplyFlyAura")
        return
    end

    local mapId = actualPlayer:GetMapId()
    local zoneId = actualPlayer:GetZoneId()
    local areaId = actualPlayer:GetAreaId()

    local function setFlying(player)
		playerData[player:GetGUIDLow()] = playerData[player:GetGUIDLow()] or {}
		playerData[player:GetGUIDLow()].isflying = true
        flyingPlayers[player:GetGUIDLow()] = player
    end

    if mapId == 0 or mapId == 1 then
        if actualPlayer:HasSpell(34091) then
            actualPlayer:Dismount() 
            actualPlayer:AddAura(SWIFT_FLIGHT_FORM_AURA, actualPlayer)
            setFlying(actualPlayer)
        elseif actualPlayer:HasSpell(34093) then
            actualPlayer:Dismount() 
            actualPlayer:AddAura(SWIFT_FLIGHT_FORM_AURA, actualPlayer)
            setFlying(actualPlayer)
        elseif actualPlayer:HasSpell(34090) then
            actualPlayer:Dismount() 
            actualPlayer:AddAura(SLOW_FLIGHT_FORM_AURA, actualPlayer)
            setFlying(actualPlayer)
        elseif actualPlayer:HasSpell(34092) then
            actualPlayer:Dismount() 
            actualPlayer:AddAura(SLOW_FLIGHT_FORM_AURA, actualPlayer)
            setFlying(actualPlayer)
        else
            actualPlayer:SendBroadcastMessage("You don't have sufficient riding skill to use the Feathers of Azeroth.")
        end
    elseif zoneId == 3430 or zoneId == 3433 or zoneId == 3557 or zoneId == 3524 or zoneId == 4080 or zoneId == 3487 or zoneId == 3455 or zoneId == 3525 or zoneId == 3479 then
        if actualPlayer:HasSpell(34091) then
            actualPlayer:Dismount() 
            actualPlayer:AddAura(SWIFT_FLIGHT_FORM_AURA, actualPlayer)
            setFlying(actualPlayer)
        elseif actualPlayer:HasSpell(34093) then
            actualPlayer:Dismount() 
            actualPlayer:AddAura(SWIFT_FLIGHT_FORM_AURA, actualPlayer)
            setFlying(actualPlayer)
        elseif actualPlayer:HasSpell(34090) then
            actualPlayer:Dismount() 
            actualPlayer:AddAura(SLOW_FLIGHT_FORM_AURA, actualPlayer)
            setFlying(actualPlayer)
        elseif actualPlayer:HasSpell(34092) then
            actualPlayer:Dismount() 
            actualPlayer:AddAura(SLOW_FLIGHT_FORM_AURA, actualPlayer)
            setFlying(actualPlayer)
        else
            actualPlayer:SendBroadcastMessage("You don't have sufficient riding skill to use the Feathers of Azeroth.")
        end
    elseif areaId == 3496 or areaId == 2274 or areaId == 4281 then
        if actualPlayer:HasSpell(34091) then
            actualPlayer:Dismount() 
            actualPlayer:AddAura(SWIFT_FLIGHT_FORM_AURA, actualPlayer)
            setFlying(actualPlayer)
        elseif actualPlayer:HasSpell(34093) then
            actualPlayer:Dismount() 
            actualPlayer:AddAura(SWIFT_FLIGHT_FORM_AURA, actualPlayer)
            setFlying(actualPlayer)
        elseif actualPlayer:HasSpell(34090) then
            actualPlayer:Dismount() 
            actualPlayer:AddAura(SLOW_FLIGHT_FORM_AURA, actualPlayer)
            setFlying(actualPlayer)
        elseif actualPlayer:HasSpell(34092) then
            actualPlayer:Dismount() 
            actualPlayer:AddAura(SLOW_FLIGHT_FORM_AURA, actualPlayer)
            setFlying(actualPlayer)
        else
            actualPlayer:SendBroadcastMessage("You don't have sufficient riding skill to use the Feathers of Azeroth.")
        end    
    elseif actualPlayer:HasAura(SWIFT_FLIGHT_FORM_AURA) or actualPlayer:HasAura(SLOW_FLIGHT_FORM_AURA) then -- Is this outdated now?
        actualPlayer:SendBroadcastMessage("You are already flying.")
    else
        actualPlayer:SendBroadcastMessage("The Feathers of Azeroth can't carry you here.")
    end
end

local function CanFlyChecks() -- Adjusts Z in Z-limited areas, and reapplies flight aura in case player gets glitch where they can't fly in flight form. Runs timer as set by MS in FLIGHTFORM_SANITY_CHECK_INTERVAL
    for _, player in pairs(GetPlayersInWorld()) do
		local mapId = player:GetMapId()
		local zoneId = player:GetZoneId()
		local areaId = player:GetAreaId()
        for _, buffId in ipairs(BUFF_IDS) do
		
            if player:HasAura(buffId) and not player:CanFly() and (zoneId == 3430 or zoneId == 3433 or zoneId == 3557 or zoneId == 3524 or zoneId == 4080 or zoneId == 3487 or zoneId == 3455 or zoneId == 3525 or zoneId == 3479 or mapId == 1 or mapId == 0) then
                local x = player:GetX()
                local y = player:GetY()
                local z = player:GetZ()
                print(string.format("[AZEROTH FLIGHT MODULE]: ALERT! Flying character with ID %s is falling! Area: %.0f. Location: %.2f, %.2f, %.2f", player:GetGUIDLow(), areaId, x, y, z)) -- Important debug, we want this in the console!
                local startTime = os.clock() 
                player:RemoveAura(buffId)
				player:RegisterEvent(ReapplyFlyAura, FLIGHTFORM_SANITY_CHECK_INTERVAL, REPETITIONS_ON_REAPPLY)
                -- while os.clock() - startTime < REAPPLICATION_ON_BREAK_CHECK_INTERVAL/1000 do        
					-- player:RemoveAura(40120,player) -- Remove aura to confuse sanity checks
					-- player:AddAura(40120,player) -- Reapply aura as sanity check effectively disabled by removing aura before sanity check did
                -- end
                break 
            end
            if player:HasAura(buffId) and player:CanFly() and (zoneId == 3430 or zoneId == 3433 or zoneId == 3557 or zoneId == 3524 or zoneId == 4080 or zoneId == 3487 or zoneId == 3455 or zoneId == 3525 or zoneId == 3479 or mapId == 1 or mapId == 0) then
                CheckPlayerHeight(player)
                break 
            end
            -- if not player:CanFly() and (playerData[player:GetGUIDLow()] and playerData[player:GetGUIDLow()].isflying) then
            --    player:RegisterEvent(ReapplyFlyAura, FLIGHTFORM_SANITY_CHECK_INTERVAL, REPETITIONS_ON_REAPPLY)
            -- end
        end
    end
end

local function OnItemUse(event, player, item, target) -- Triggers initial cast of Feathers of Azeroth flight buff
    local mapId = player:GetMapId()
    local zoneId = player:GetZoneId()
	local areaId = player:GetAreaId()
    
    local itemEntry = item:GetEntry()
    
    local isValidItem = false -- Check if the item used is one of the Feathers of Azeroth items
    for _, id in ipairs(ITEM_IDS) do
        if itemEntry == id then
            isValidItem = true
            break
        end
    end
    
    if isValidItem then
        if player:IsInCombat() then
            player:SendBroadcastMessage("You can't use this item while in combat.")
            return false
        end
        
        if player:IsInWater() then
            player:SendBroadcastMessage("You can't use the Feathers of Azeroth while in water.")
            return false
        end
        
        
		if (mapId == OUTLAND_MAP and zoneId == SILVERMOON) or zoneId == ISLEOFQD or zoneId == EVERSONG or zoneId == GHOSTLANDS or mapId == EASTERN_KINGDOMS or (mapId == KALIMDOR and zoneId ~= TELDRASSIL and zoneId ~= DARNASSUS and zoneId ~= HYJAL and zoneId ~= WINTERSPRING and zoneId ~= ASHENVALE and zoneId ~= FELWOOD) then
			if not player:HasAura(SWIFT_FLIGHT_FORM_AURA) or not player:HasAura(SLOW_FLIGHT_FORM_AURA) then
				local x, y, z = player:GetLocation()
				if (isPointInPolygon(x, y, SW_CANALS) or isPointInPolygon(x, y, MAGE_DISTRICT_EXCEPTION)) and not isPointInPolygon(x, y, SW_STOCKADES) then
						player:RegisterEvent(ReapplyFlyAura, REAPPLICATION_ON_BREAK_CHECK_INTERVAL, REPETITIONS_ON_REAPPLY)
				elseif isPointInPolygon(x, y, INSIDE_SW_MAGE_TOWER) or isPointInPolygon(x, y, SW_CASTLE) or isPointInPolygon(x, y, SW_STOCKADES) or isPointInPolygon(x, y, SW_DWARVEN_DISTRICT_EXCEPTION) or isPointInPolygon(x, y, SW_CHURCH) then
						player:SendBroadcastMessage("You need to be under clear sky to use the Feathers of Azeroth.")
						return false
				elseif not (isPointInPolygon(x, y, SW_MAGE_DISTRICT)) and not (isPointInPolygon(x, y, SW_ENTRANCE)) and not (isPointInPolygon(x, y, SW_OLD_TOWN)) and not (isPointInPolygon(x, y, SW_DWARVEN_DISTRICT)) and not (isPointInPolygon(x, y, SW_CANALS)) then
					if (IsPlayerIndoors(player)) then
						if (playerData[player:GetGUIDLow()] and playerData[player:GetGUIDLow()].isflying) then
							player:RegisterEvent(ReapplyFlyAura, REAPPLICATION_ON_BREAK_CHECK_INTERVAL, REPETITIONS_ON_REAPPLY)
						else
							player:SendBroadcastMessage("You need to be under clear sky to use the Feathers of Azeroth.")
						return false
						end
					end
				elseif (isPointInPolygon(x, y, SW_MAGE_DISTRICT)) or isPointInPolygon(x, y, SW_ENTRANCE) or isPointInPolygon(x, y, SW_OLD_TOWN) or isPointInPolygon(x, y, SW_DWARVEN_DISTRICT) then
					if (IsPlayerIndoorsSW(player)) then
						if (playerData[player:GetGUIDLow()] and playerData[player:GetGUIDLow()].isflying) then
							player:RegisterEvent(ReapplyFlyAura, REAPPLICATION_ON_BREAK_CHECK_INTERVAL, REPETITIONS_ON_REAPPLY)
						else
							player:SendBroadcastMessage("You need to be under clear sky to use the Feathers of Azeroth.")
						return false
						end
					end
				else
					player:SendBroadcastMessage("You need to be under clear sky to use the Feathers of Azeroth.")
				end
			elseif player:HasAura(SWIFT_FLIGHT_FORM_AURA) then
				player:RemoveAura(SWIFT_FLIGHT_FORM_AURA)
			elseif player:HasAura(SLOW_FLIGHT_FORM_AURA) then
				player:RemoveAura(SLOW_FLIGHT_FORM_AURA)
			end
		end
        
        local mapId = player:GetMapId()
        local zoneId = player:GetZoneId()
        local areaId = player:GetAreaId()
        if mapId == 0 or mapId == 1 or areaId == 3496 or zoneId == 3430 or zoneId == 3433 or zoneId == 3557 or zoneId == 3524 or zoneId == 4080 or zoneId == 3487 or zoneId == 3455 or zoneId == 3525 or zoneId == 3479 then    
			player:CastSpell(player, 45322, true)
			-- player:CastSpell(player, 40405, true) -- Dummy to despawn companion, useful or not?
            player:RegisterEvent(ApplyFlyAura, 1, 1, player)
            player:RemoveAura(45322)
			if CarryMessage == false then
			    player:SendBroadcastMessage("The Feathers of Azeroth carry you into the sky.")
				CarryMessage = true
			end
        else
            player:SendBroadcastMessage("The Feathers of Azeroth can't carry you here.")
        end
        return false
    end
end

local function ApplyFlightAura(player)
    if player:HasSpell(34091) or player:HasSpell(34093) then
        player:AddAura(SWIFT_FLIGHT_FORM_AURA, player)
        --print("[AZEROTH FLIGHT MODULE]: Attempting to apply Swift Flight Form for character ID: ".. player:GetGUIDLow())
    elseif player:HasSpell(34090) or player:HasSpell(34092) then
        player:AddAura(SLOW_FLIGHT_FORM_AURA, player)
        --print("[AZEROTH FLIGHT MODULE]: Attempting to apply Slow Flight Form for character ID: ".. player:GetGUIDLow())
    end
end

--local function LoopApplyAura(player) -- Deprecated function
--    for i = 1, 3 do
--        player:RegisterEvent(function(eventId, delay, repeats, player)
--            print(string.format("[AZEROTH FLIGHT MODULE]: ALERT! FLight form loop triggered! Attempt %d for character ID: ".. player:GetGUIDLow(), i)) -- We want this in console too although ti's mostly used for quests
--            ReapplyFlyAura(player)
--        end, i * PROBLEMZONEDELAY, 1)
--    end
--end

-- local function OnAreaUpdate(event, player, oldArea, newArea) -- Triggers reapplication on area change as this triggers server-side sanity check. Commented out as zone update does the same job for now
-- 		print("[AZEROTH FLIGHT MODULE]: Player leaving "..oldArea.." and entering "..newArea..". Character ID: ".. player:GetGUIDLow(), i)
-- 			if (playerData[player:GetGUIDLow()] and playerData[player:GetGUIDLow()].isflying) then -- Breaks because players aren't flying on area change?
-- 			LoopApplyAura(player)
-- 		else
-- 			playerData[player:GetGUIDLow()] = playerData[player:GetGUIDLow()] or {}
-- 			playerData[player:GetGUIDLow()].isflying = false
-- 			flyingPlayers[player:GetGUIDLow()] = nil
-- 		end
-- 	end

local function OnZoneChange(event, player, newZone, newArea) -- Triggers reapplication on zone change as this triggers server-side sanity check. If both zone and area change, only zone change register has effect.
	--print("[AZEROTH FLIGHT MODULE]: Player entering area "..newArea..". Checking if need to reapply flight aura to character ID: ".. player:GetGUIDLow())
	if (playerData[player:GetGUIDLow()] and playerData[player:GetGUIDLow()].isflying) then
		-- player:RemoveAura(40120,player) -- Remove aura to confuse sanity checks
		-- player:AddAura(40120,player) -- Reapply aura as sanity check effectively disabled by removing aura before sanity check did
		player:RegisterEvent(ReapplyFlyAura, REAPPLICATION_ON_BREAK_CHECK_INTERVAL, REPETITIONS_ON_REAPPLY) -- This may be an overcomplication?
	else
		playerData[player:GetGUIDLow()] = playerData[player:GetGUIDLow()] or {}
		playerData[player:GetGUIDLow()].isflying = false
		flyingPlayers[player:GetGUIDLow()] = nil
	end
end

local function OnMapChange(event, player)
    local guid = player:GetGUIDLow()
    local newMap = player:GetMap():GetMapId()
    
    if not contains(MAP_CHANGE_TO_REAPPLY_FLIGHT_FORM, newMap) then
        for _, buffId in ipairs(BUFF_IDS) do
            player:RemoveAura(buffId)
            playerData[guid] = playerData[guid] or {}
            playerData[guid].isflying = false
        end
    end
    if not contains(MAP_CHANGE_TO_REAPPLY_FLIGHT_FORM, newMap) then -- Maps with "old world" flying. Could probably add zone/area checks for other areas as done otherwise but not sure if necessary
		--print("[AZEROTH FLIGHT MODULE]: Map change to old world detected for character ID: ".. player:GetGUIDLow()..". Checking if flight needs to be reapplied...")
    
		local query = CharDBQuery(string.format("SELECT posX, posY, posZ FROM character_flying WHERE GUID = %u AND isflying = 1", guid))
		if not query then
			return
		end
    
		local storedX, storedY, storedZ = query:GetFloat(0), query:GetFloat(1), query:GetFloat(2)
		local currentX, currentY, currentZ = player:GetLocation()
		local distance = math.sqrt((currentX - storedX)^2 + (currentY - storedY)^2 + (currentZ - storedZ)^2)
		
		if distance <= 5 then        
			local attempt = 0
			local maxAttempts = 3
			local function ApplyAuraRepeatedly()
				attempt = attempt + 1
				local currentPlayer = GetPlayerByGUID(guid)
				if currentPlayer then
					currentPlayer:AddAura(40120, currentPlayer)
					if attempt < maxAttempts then
						CreateLuaEvent(ApplyAuraRepeatedly, REAPPLICATION_ON_BREAK_CHECK_INTERVAL, 1)
					end
				end
			end
			ApplyAuraRepeatedly()
		end
	end
end

local function CheckQuestChanges() -- Tracks quest changes for all players. The only check for whether or not player was flying is in the loop function called if a player has a quest status change. Is it efficient to do it this way?
    local players = GetPlayersInWorld()

    for _, player in pairs(players) do
        local playerGuid = player:GetGUIDLow()
        local playerName = player:GetName()
        local currentQuests = {}
        
        for questId = 1, 30000 do -- Maybe adjust to actual max number of quests 
            local status = player:GetQuestStatus(questId)
            if status ~= QUEST_STATUS.NONE then
                currentQuests[questId] = status
            end
        end
        
        if not playerQuestStatus[playerGuid] then
            playerQuestStatus[playerGuid] = currentQuests
        else
            local changed = false
            local changes = {}

            for questId, status in pairs(currentQuests) do
                if not playerQuestStatus[playerGuid][questId] then
                    changed = true
                    table.insert(changes, string.format("Quest %d added with status %d", questId, status))
                    if playerData[playerGuid] and playerData[playerGuid].isflying then
						player:RegisterEvent(ReapplyFlyAura, REAPPLICATION_ON_BREAK_CHECK_INTERVAL, REPETITIONS_ON_REAPPLY, playerGuid) -- This may be an overcomplication?
                    end
                elseif playerQuestStatus[playerGuid][questId] ~= status then
                    changed = true
                    table.insert(changes, string.format("Quest %d status changed from %d to %d", questId, playerQuestStatus[playerGuid][questId], status))
                    if playerData[playerGuid] and playerData[playerGuid].isflying then
						player:RegisterEvent(ReapplyFlyAura, REAPPLICATION_ON_BREAK_CHECK_INTERVAL, REPETITIONS_ON_REAPPLY, playerGuid) -- This may be an overcomplication?
                    end
                end
            end

            for questId in pairs(playerQuestStatus[playerGuid]) do
                if not currentQuests[questId] then
                    changed = true
                    table.insert(changes, string.format("Quest %d removed", questId))
                    if playerData[playerGuid] and playerData[playerGuid].isflying then
						player:RegisterEvent(ReapplyFlyAura, REAPPLICATION_ON_BREAK_CHECK_INTERVAL, REPETITIONS_ON_REAPPLY, playerGuid) -- This may be an overcomplication?
                    end
                end
            end
            
            if changed then
                for _, change in ipairs(changes) do
                    if playerData[playerGuid] and playerData[playerGuid].isflying then
						player:RegisterEvent(ReapplyFlyAura, REAPPLICATION_ON_BREAK_CHECK_INTERVAL, REPETITIONS_ON_REAPPLY, playerGuid) -- This may be an overcomplication?
                    end
                end
                playerQuestStatus[playerGuid] = currentQuests
            end
        end
    end
end

local function OnPlayerLogout(event, player) -- Logout handler, saves aura state
    local guid = player:GetGUIDLow()
    local hasBuff = false

    for _, buffId in ipairs(BUFF_IDS) do
        if player:HasAura(buffId) then
            hasBuff = true
            break
        end
    end

    if hasBuff then
        CharDBExecute(string.format("REPLACE INTO character_flying (GUID, isflying) VALUES (%d, 1);", guid))
    else
        CharDBExecute(string.format("REPLACE INTO character_flying (GUID, isflying) VALUES (%d, 0);", guid))
    end
end

local function OnPlayerLogin(event, player) -- Login handler, loads last aura state
    local guid = player:GetGUIDLow()
    local query = string.format("SELECT isflying FROM character_flying WHERE GUID = %d;", guid)
    local result = CharDBQuery(query)

    if result then
        local isFlying = result:GetInt32(0)
        if isFlying == 1 then
            for _, buffId in ipairs(BUFF_IDS) do
                player:AddAura(buffId, player)
            end
        end
    end
end

local function SavePlayerFlyingData(player) -- Stores flying players' location data in database
    local guid = player:GetGUIDLow()
    local map = player:GetMap():GetMapId()
    
    if not contains(MAP_CHANGE_TO_REAPPLY_FLIGHT_FORM, map) then -- Do not do anything if player is not in Kalimdor, Eastern Kingdoms, or the Outland map (where the TBC Azeroth areas are)
        return
    end
    
    local hasFlightBuff = false -- Function to check for flight buff
    for _, buffId in ipairs(BUFF_IDS) do
        if player:HasAura(buffId) then
            hasFlightBuff = true
            break
        end
    end
    
    if not hasFlightBuff then -- If no flight buff, do not do anything
        return
    end
    
    local x, y, z = player:GetLocation()
    
    if hasFlightBuff then -- Store location if player has flight buff
        CharDBExecute(string.format([[
            REPLACE INTO character_flying (GUID, isflying, posX, posY, posZ, mapID)
            VALUES (%u, %d, %f, %f, %f, %d)
        ]], guid, 1, x, y, z, map))
    end
end

local function StorePlayerFlyingStatus(event, diff) -- Schedules storage of flying players' location data
    lastUpdateTime = lastUpdateTime + diff
	--print("[AZEROTH FLIGHT MODULE]: Last tick: "..lastUpdateTime) -- Ticks troubleshooter
    if lastUpdateTime >= UPDATE_INTERVAL then
        for _, player in pairs(GetPlayersInWorld()) do
            SavePlayerFlyingData(player)
        end
        lastUpdateTime = 0
    end
end


local function HasFlightBuff(player, buffIds) -- Used as simplification in some functions
    for _, buffId in ipairs(buffIds) do
        if player:HasAura(buffId) then
            return true
        end
    end
    return false
end

local function ParachuteTimerForAllPlayers()
    local players = GetPlayersInWorld()
    local currentTime = os.time()

    for _, player in pairs(players) do
        if player and player:IsInWorld() then
            local playerGuid = player:GetGUIDLow()
            local x, y, z = player:GetLocation()
            local mapId = player:GetMapId()
            local zoneId = player:GetZoneId()
            local areaId = player:GetAreaId()
            
            -- Get player data
            

            if (zoneId == SILVERMOON or zoneId == ISLEOFQD or zoneId == EVERSONG or zoneId == GHOSTLANDS or mapId == EASTERN_KINGDOMS or mapId == KALIMDOR) and not isPointInPolygon(x, y, SW_MAGE_DISTRICT) then
                local playerData = player:GetData("flyingData") or {}
            
				-- Process timers for this player
				if playerData.timers then
					for timerId, timer in pairs(playerData.timers) do
						if currentTime >= timer.executeTime then
							timer.callback(player)
							playerData.timers[timerId] = nil
						end
					end
				end-- Update area history
                playerData.areaHistory = playerData.areaHistory or {}
                table.insert(playerData.areaHistory, 1, areaId)
                if #playerData.areaHistory > AREA_CACHE then
                    table.remove(playerData.areaHistory)
                end
                
                local areaChanged = false
                for i = 2, #playerData.areaHistory do
                    if playerData.areaHistory[i] ~= areaId then
                        areaChanged = true
                        break
                    end
                end
                
                local isNearObstacle = CheckObstaclesForPlayer(player)
                
                local hasBirdBuff = HasFlightBuff(player, BUFF_IDS)
                
                if hasBirdBuff then
                    playerData.lastFlightBuffCheck = currentTime
                end

                local recentFlightBuffCheck = playerData.lastFlightBuffCheck and (currentTime - playerData.lastFlightBuffCheck) <= FLIGHT_CHECK_INTERVAL/1000
                
                if not isNearObstacle then
                    if hasBirdBuff and player:HasAura(PARACHUTE_SPELL_ID) and recentFlightBuffCheck then
                        player:RemoveAura(PARACHUTE_SPELL_ID)
                    elseif not hasBirdBuff and not player:HasAura(PARACHUTE_SPELL_ID) and recentFlightBuffCheck and areaChanged and (player:HasItem(39163) or player:HasItem(28326) or player:HasItem(20739) or player:HasItem(208800)) and not player:IsMounted() and not player:IsInWater() then
                        if player:HasSpell(34091) or player:HasSpell(34093) then
                            player:AddAura(SWIFT_FLIGHT_FORM_AURA, player)
                            playerData.isflying = true
                            print("[AZEROTH FLIGHT MODULE]: Parachute function stopped player ID ".. playerGuid.." from falling in area ID "..areaId)
                        elseif player:HasSpell(34090) or player:HasSpell(34092) then
                            player:AddAura(SLOW_FLIGHT_FORM_AURA, player)
                            playerData.isflying = true
                            print("[AZEROTH FLIGHT MODULE]: Parachute function stopped player ID ".. playerGuid.." from falling in area ID "..areaId)
                        end
                    elseif not hasBirdBuff and not player:HasAura(PARACHUTE_SPELL_ID) and recentFlightBuffCheck and (player:HasItem(39163) or player:HasItem(28326) or player:HasItem(20739) or player:HasItem(208800)) and not player:IsMounted() and not player:IsInWater() then
                        DelayedParachuteCheck(player, areaId)
                    elseif hasBirdBuff and not recentFlightBuffCheck then
                        print("[AZEROTH FLIGHT MODULE]: ALERT! Player ID ".. playerGuid.." is flying but flying check failed!")    
                    end
                end
            end
            player:SetData("flyingData", playerData)
        end
    end
end


-- Player event triggers
RegisterPlayerEvent(3, OnPlayerLogin)
RegisterPlayerEvent(4, OnPlayerLogout)
RegisterPlayerEvent(27, OnZoneChange)
RegisterPlayerEvent(28, OnMapChange)
RegisterPlayerEvent(47, OnZoneChange)

-- Stores player location and flying status (0 or 1) to database on server ticks
RegisterServerEvent(13, StorePlayerFlyingStatus)

-- Periodic events running all the time
flightquestid = CreateLuaEvent(CheckQuestChanges, REAPPLICATION_ON_BREAK_CHECK_INTERVAL, 0)
flightformid = CreateLuaEvent(CheckFlightForm, FLIGHTFORM_SANITY_CHECK_INTERVAL, 0)
parachutecheckid = CreateLuaEvent(ParachuteTimerForAllPlayers, PARACHUTE_CHECK_INTERVAL, 0)
canflycheckid = CreateLuaEvent(CanFlyChecks, FALLING_CHECK_INTERVAL, 0)

-- Item use events
for _, itemId in ipairs(ITEM_IDS) do
    RegisterItemEvent(itemId, 2, OnItemUse) -- TO-DO, clean up leftover item IDs
end

CharacterFlyingTable() -- Ensures table exists on startup, used to hot load SQL changes

print("[AZEROTH FLIGHT MODULE]: Flight mode script loaded and events registered. Quest check ID "..flightquestid..". Flight form check ID: "..flightformid..". Parachute check ID: "..parachutecheckid..". Can fly check ID: "..canflycheckid)
