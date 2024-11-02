local ITEM_ENTRY = 20739
local MOUNTS_PER_PAGE = 10
local MOUNT_DATA = {}
local MOUNT_ICONS = {}
local standardmount = {}
local BUFFIDS = {
    3363, 8153, 32235, 32239, 32240,
    32242, 32243, 32244, 32245, 32246, 32289, 32290, 32292, 32295, 32296, 32297, 32345,
    33943, 37015, 39798, 39800, 39801, 39802, 39803, 39910, 40120, 40192,
    40212, 41513, 41514, 41515, 41516, 41517, 41518, 42667, 42668, 42673, 42679, 43810,
    43927, 44151, 44153, 44317, 44655, 44744, 44824, 44825, 44827, 46197, 46199,
    47037, 48023, 49193, 51617, 51960, 54726, 54727, 54729, 54903, 58615,
    59567, 59568, 59569, 59570, 59571, 59650, 59961, 59976, 59996, 60002, 60021, 60024, 60025,
    60099, 61229, 61230, 61289, 61294, 61309, 61442, 61444, 61446, 61451,
    61996, 61997, 62048, 63796, 63844, 63956, 63963, 64927, 65439, 66087,
    66088, 67336, 69395, 71346, 71347, 71810, 72283, 72284, 72807, 72808, 74854, 74855,
    75596, 75617, 75618, 76153
}

local LAST_WARNING_TIME = {}  -- Table to store the last warning time for each player, to not flood chat box
local ZCheckActive = {}

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
local SW_MAGE_DISTRICT_Z = 125 -- Used with polygon
local SW_Z = 115 -- Areas of SW not covered by above polygon Zs
local TELEPORT_Z_OFFSET = 0.2

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

-- Query spell names and icons from spell_dbc and build the lookup tables
do
    local result = WorldDBQuery("SELECT ID, Name_Lang_enUS, SpellIconID FROM spell_dbc WHERE ID IN (3363, 8153, 32235, 32239, 32240, 32242, 32243, 32244, 32245, 32246, 32289, 32290, 32292, 32295, 32296, 32297, 32345, 32420, 33943, 37015, 39798, 39800, 39801, 39802, 39803, 39910, 40120, 40192, 40212, 41513, 41514, 41515, 41516, 41517, 41518, 42667, 42668, 42673, 42679, 43810, 43927, 44151, 44153, 44317, 44655, 44744, 44824, 44825, 44827, 46197, 46199, 47037, 48023, 49193, 51617, 51960, 54726, 54727, 54729, 54903, 58615, 59567, 59568, 59569, 59570, 59571, 59650, 59961, 59976, 59996, 60002, 60021, 60024, 60025, 60099, 61229, 61230, 61289, 61294, 61309, 61442, 61444, 61446, 61451, 61996, 61997, 62048, 63796, 63844, 63956, 63963, 64927, 65439, 66087, 66088, 67336, 69395, 71346, 71347, 71810, 72283, 72284, 72807, 72808, 74854, 74855, 75596, 75617, 75618, 76153)")
    
    local spellIconIds = {}
    if result then
        repeat
            local id = result:GetUInt32(0)
            local name = result:GetString(1)
            local iconId = result:GetUInt32(2)
            MOUNT_DATA[id] = name
            spellIconIds[iconId] = true
        until not result:NextRow()
    end

    -- Build icon ID query string
    local iconIdList = {}
    for iconId in pairs(spellIconIds) do
        table.insert(iconIdList, tostring(iconId))
    end
    
    -- Query spellicon_dbc for icon paths
    local iconResult = WorldDBQuery(string.format("SELECT ID, Field1 FROM spellicon_dbc WHERE ID IN (%s)", table.concat(iconIdList, ",")))
    local iconPaths = {}
    if iconResult then
        repeat
            local iconId = iconResult:GetUInt32(0)
            local iconName = iconResult:GetString(1)
            -- Format the icon path
            iconPaths[iconId] = string.format("Interface/Icons/%s", iconName:gsub("InterfaceIcons", ""))
        until not iconResult:NextRow()
    end
    
    -- Build spell ID list for final query
    local spellIds = {}
    for id in pairs(MOUNT_DATA) do
        table.insert(spellIds, tostring(id))
    end

    -- Link spell IDs to their formatted icon paths
    local spellResult = WorldDBQuery(string.format("SELECT ID, SpellIconID FROM spell_dbc WHERE ID IN (%s)", table.concat(spellIds, ",")))
    if spellResult then
        repeat
            local spellId = spellResult:GetUInt32(0)
            local iconId = spellResult:GetUInt32(1)
            MOUNT_ICONS[spellId] = iconPaths[iconId]
        until not spellResult:NextRow()
    end
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


local function CheckZ(eventId, delay, repeats, player)
    local mapId = player:GetMapId()
    local zoneId = player:GetZoneId()
    local areaId = player:GetAreaId()
    local x, y, z = player:GetLocation()
    
    local maxObjectZ = z - 1
    local canTeleport = player:IsWithinLoS(x, y, maxObjectZ)
    local mountId
    
    for _, id in ipairs(BUFFIDS) do
        if player:HasAura(id) then
            mountId = (id)
        end
    end
    
    if not player or not mountId or not (
    zoneId == SILVERMOON or zoneId == ISLEOFQD or zoneId == EVERSONG or zoneId == GHOSTLANDS or zoneId == STORMWIND or
    zoneId == ORGRIMMAR or zoneId == UNDERCITY or areaId == RUINSOFLORDAERON or areaId == SHININGSTRAND or 
    zoneId == SWHARBOR
    )   
    then
        player:RemoveEventById(eventId)
        ZCheckActive[player:GetGUIDLow()] = nil
        print("Event removed")
        return
    end
    
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
    if zoneId == SWHARBOR then
        maxAllowedZ = SWHARBOR_ZONE_MAX_Z
        teleportZ = SWHARBOR_ZONE_MAX_Z
    elseif zoneId == STORMWIND and isPointInPolygon(x, y, SW_MAGE_TOWER) then
        maxAllowedZ = SW_MAGE_TOWER_Z
        teleportZ = SW_MAGE_TOWER_Z
    elseif zoneId == STORMWIND and isPointInPolygon(x, y, SW_MAGE_DISTRICT) then
        maxAllowedZ = SW_MAGE_DISTRICT_Z
        teleportZ = SW_MAGE_DISTRICT_Z
    elseif zoneId == STORMWIND and isPointInPolygon(x, y, SW_ENTRANCE) then
        maxAllowedZ = SW_ENTRANCE_Z
        teleportZ = SW_ENTRANCE_Z
        
    elseif zoneId == STORMWIND then
        maxAllowedZ = SW_Z
        teleportZ = SW_Z
    end
    
    if z > maxAllowedZ and canTeleport then
        player:Teleport(mapId, x, y, teleportZ, player:GetO())
        if not LAST_WARNING_TIME[player:GetGUIDLow()] or os.time() - LAST_WARNING_TIME[player:GetGUIDLow()] >= 5 then
            player:SendBroadcastMessage("You can't fly that high in this area!")
            LAST_WARNING_TIME[player:GetGUIDLow()] = os.time()
        end
    end
end

-- Start gossip management

local function ShowManageStandardMount(event, player)
    player:GossipClearMenu()
    player:GossipMenuAddItem(0, "|TInterface/ICONS/INV_Misc_QuestionMark:32:32:-22:0|tWhat is standard mount?", 0, 300000)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/spell_nature_swiftness:32:32:-22:0|tChoose standard mount", 0, 400000)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_enggizmos_27:32:32:-22:0|tRemove standard mount", 0, 500000)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_map_01:32:32:-22:0|tBack", 0, 1)
    player:GossipSendMenu(12, player, 182746573)
end

local function ShowInfoPage(event, player)
    player:GossipClearMenu()
    player:GossipMenuAddItem(0, "|TInterface/ICONS/INV_Misc_QuestionMark:32:32:-22:0|tWhat is standard mount?\n \nStandard mount allows you to set a preferred mount that will be automatically cast when using the Feathers of Azeroth.\n \nYou can change or remove your standard mount at any time by talking to your Twiggy.\n \n ", 0, 300000)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_map_01:32:32:-22:0|tBack", 0, 600000)
    player:GossipSendMenu(12, player, 182746573)
end

local function ShowMountMenu(event, player, item, target, page, isStandardMount)
    page = page or 1
    
    -- Get available mounts for this player
    local availableMounts = {}
    for spellId, spellName in pairs(MOUNT_DATA) do
        if player:HasSpell(spellId) then
            table.insert(availableMounts, spellId)
        end
    end
    
    local totalMounts = #availableMounts
    local maxPages = math.ceil(totalMounts / MOUNTS_PER_PAGE)
    
    -- Create gossip menu
    player:GossipClearMenu()
    if isStandardMount then
        player:GossipMenuAddItem(0, "|TInterface/ICONS/spell_nature_swiftness:32:32:-22:0|tChoosing standard mount", 0, 0)
    else
        player:GossipMenuAddItem(0, "|TInterface/ICONS/trade_engineering:32:32:-22:0|tManage standard mount", 0, 700000)
    end
    
    -- Add mount options for current page
    local startIndex = ((page - 1) * MOUNTS_PER_PAGE) + 1
    local endIndex = math.min(startIndex + MOUNTS_PER_PAGE - 1, totalMounts)
    
    for i = startIndex, endIndex do
        local spellId = availableMounts[i]
        local spellName = MOUNT_DATA[spellId]
        local iconPath = MOUNT_ICONS[spellId]
        if spellId == 75596 then 
            iconPath = "Interface/ICONS/ability_mount_frostyflyingcarpet"
        end
        -- Add icon to gossip menu item
        if isStandardMount then
            player:GossipMenuAddItem(4, "|T" .. iconPath .. ":32:32:-22:0|t" .. spellName, 0, 800000 + spellId)
        else
            player:GossipMenuAddItem(4, "|T" .. iconPath .. ":32:32:-22:0|t" .. spellName, 0, spellId)
        end
    end
    
    -- Navigation buttons
    if page < maxPages then
        player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_map_01:32:32:-22:0|tNext Page", 0, 100000 + page)
    end
    
    if page > 1 then
        player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_map_01:32:32:-22:0|tPrevious Page", 0, 200000 + page)
    end
    
    player:GossipSendMenu(12, player, 182746573)
end

local function OnGossipSelect(event, player, object, sender, intid, code, menu_id)
    if intid == 1 then
        ShowMountMenu(event, player, item, target, 1)
    elseif intid >= 100000 and intid < 200000 then
        -- Next page
        local currentPage = intid - 100000
        ShowMountMenu(event, player, nil, nil, currentPage + 1)
    elseif intid >= 200000 and intid < 300000 then
        -- Previous page
        local currentPage = intid - 200000
        ShowMountMenu(event, player, nil, nil, currentPage - 1)
    elseif intid == 300000 then
        -- What is standard mount?
        ShowInfoPage(event, player)
    elseif intid == 400000 then
        -- Choose standard mount
        ShowMountMenu(event, player, nil, nil, 1, true)
    elseif intid == 500000 then
        -- Remove standard mount
        standardmount[player:GetGUIDLow()] = nil
        player:SendBroadcastMessage("Standard mount removed.")
        ShowManageStandardMount(event, player)
    elseif intid == 600000 then
        -- Back button from info page
        ShowManageStandardMount(event, player)
    elseif intid == 700000 then
        -- Manage standard mount button
        ShowManageStandardMount(event, player)
    elseif intid >= 800000 then
        -- Mount selected as standard
        local mountId = intid - 800000
        standardmount[player:GetGUIDLow()] = mountId
        CharDBExecute(string.format("REPLACE INTO character_flight (guid, standardmount) VALUES (%d, %d)", player:GetGUIDLow(), mountId))
        player:SendBroadcastMessage("Standard mount set successfully.")
        player:GossipComplete()
    elseif intid > 0 then
        -- Normal mount selected
        if not player:IsFlying() and player:IsMounted() then
            player:Dismount()
        end
        if not player:IsCasting() then
            player:CastSpell(player, intid, false)
            player:RegisterEvent(function(eventId, delay, repeats, player)
                player:RegisterEvent(CheckZ, 200, 0)
            end, 3000, 1)
            print("Starting zone-based Z check")
            player:GossipComplete()
        else
            player:SendBroadcastMessage("You can't use this item while casting!") 
        end
    end
end

local function OnUseItem(event, player, item, target)
    if player:IsCasting() then
        return false
    end
    
    if not (player:HasSpell(34091) or player:HasSpell(34090)) then
        player:SendBroadcastMessage("You can't use this item without knowing how to fly!")
        return false
    end
    
    local mapId = player:GetMapId()
    local zoneId = player:GetZoneId()
    local areaId = player:GetAreaId()
    
    if not (mapId == 0 or mapId == 1
    or zoneId == 3430 or zoneId == 3433 or zoneId == 3557
    or zoneId == 3524 or zoneId == 4080 or zoneId == 3487
    or zoneId == 3455 or zoneId == 3525 or zoneId == 3479
    or areaId == 3496 or areaId == 2274 or areaId == 4281)
    or player:GetInstanceId() > 0 or player:InBattleground()
    then
        player:SendBroadcastMessage("The Feathers of Azeroth can't carry you here.")
        return false
    end
    
    if standardmount[player:GetGUIDLow()] and not player:IsCasting() then
        player:CastSpell(player, standardmount[player:GetGUIDLow()], false)
        player:RegisterEvent(function(eventId, delay, repeats, player)
            player:RegisterEvent(CheckZ, 200, 0)
        end, 3000, 1)
        print("Starting zone-based Z check")
    else
        ShowMountMenu(event, player, item, target, 1)
    end
    return false
end

local function OnNewMap(event, player)
    print("new map ok")
    local mapId = player:GetMapId()
    local zoneId = newZone
	local areaId = newArea
    if 
    (
    mapId == KALIMDOR or mapId == EASTERN_KINGDOMS or
    zoneId == SILVERMOON or zoneId == ISLEOFQD or zoneId == EVERSONG or zoneId == GHOSTLANDS or zoneId == STORMWIND or
    zoneId == ORGRIMMAR or zoneId == UNDERCITY or areaId == RUINSOFLORDAERON or areaId == SHININGSTRAND or 
    zoneId == SWHARBOR
    ) 
    and not player:HasItem(20739)
    then
        player:RegisterEvent(function(eventId, delay, repeats, player)
            for _, id in ipairs(BUFFIDS) do
                if player:HasAura(id) then
                    player:RemoveAura(id)
                    print("mount removed due to no FoA")
                end
            end
        end, 100, 1) -- Check for mount 100 ms after entering new map
    elseif player:GetInstanceId() > 0 or player:InBattleground() or player:GetMapId() == 573 then
        player:RegisterEvent(function(eventId, delay, repeats, player)
            if player then 
                for _, id in ipairs(BUFFIDS) do
                    if player:HasAura(id) then
                        player:RemoveAura(id)
                    end
                end
            end
        end, 100, 1) -- Check for mount 100 ms after entering instance
    end
end 

local function OnChangeZone(event, player, newZone, newArea)
    local zoneId = newZone
	local areaId = newArea
    if (
    zoneId == SILVERMOON or zoneId == ISLEOFQD or zoneId == EVERSONG or zoneId == GHOSTLANDS or zoneId == STORMWIND or
    zoneId == ORGRIMMAR or zoneId == UNDERCITY or areaId == RUINSOFLORDAERON or areaId == SHININGSTRAND or 
    zoneId == SWHARBOR
    )
    then
        player:RegisterEvent(function(eventId, delay, repeats, player)
            if player then 
                for _, id in ipairs(BUFFIDS) do
                    if player:HasAura(id) and not ZCheckActive[player:GetGUIDLow()] then
                        ZCheckActive[player:GetGUIDLow()] = true
                        player:RegisterEvent(CheckZ, 200, 0)
                        print("Starting zone-based Z check")
                    end
                end
            end
        end, 100, 1) -- Check for mount 100 ms after entering instnace
    end
end 

local function LoadStandardMount(event, player)
    local guid = player:GetGUIDLow()
    local result = CharDBQuery(string.format("SELECT standardmount FROM character_flight WHERE guid = %d", guid))
    if result then
        local mountId = result:GetUInt32(0)
        if mountId  then
            standardmount[guid] = mountId
        end
    end
end

local function OnLoadScript()
    local dbQueryTable = {}
    
    local players = GetPlayersInWorld()
    for _, player in pairs(players) do
        if player:HasItem(20739) then
            table.insert(dbQueryTable, player:GetGUIDLow())
            local zoneId = player:GetZoneId()
            local areaId = player:GetAreaId()
            if player and player:CanFly() and (
            zoneId == SILVERMOON or zoneId == ISLEOFQD or zoneId == EVERSONG or zoneId == GHOSTLANDS or zoneId == STORMWIND or
            zoneId == ORGRIMMAR or zoneId == UNDERCITY or areaId == RUINSOFLORDAERON or areaId == SHININGSTRAND or 
            zoneId == SWHARBOR
            )   
            then
                ZCheckActive[player:GetGUIDLow()] = true
                player:RegisterEvent(CheckZ, 200, 0)
                print("Starting zone-based Z check")
            end
        end
    end
    
    -- If we found any players with the item, query their standard mounts
    if #dbQueryTable > 0 then
        local queryStr = string.format("SELECT guid, standardmount FROM character_flight WHERE guid IN (%s)", 
            table.concat(dbQueryTable, ","))
        local result = CharDBQuery(queryStr)
        
        if result then
            repeat
                local guid = result:GetUInt32(0)
                local mountId = result:GetUInt32(1)
                if mountId then
                    standardmount[guid] = mountId
                end
            until not result:NextRow()
        end
    end
end

local function OnMoveSetFly(event, packet, player)
    if player then
        if player:GetGossipTextId(player) == 12 then
            player:GossipComplete()
        end
        if player:GetInstanceId() > 0 then
            for _, id in ipairs(BUFFIDS) do
                if player:HasAura(id) then
                    if player:HasSpell(id) then
                        player:RemoveAura(id)
                    end
                end
            end
        end
    end
end

local function OnCommand(event, player, command)
    if command == "choosestandardfeathers" then
        ShowManageStandardMount(event, player)
        return false
    end
end

OnLoadScript()
WorldDBExecute("UPDATE item_template SET description = 'This item has the ability to wrap the wings of your flying mounts with the Feathers of Azeroth, permitting their use in Azeroth.' WHERE entry = 20739")
CharDBExecute("CREATE TABLE IF NOT EXISTS character_flight (guid INT UNSIGNED NOT NULL, standardmount INT UNSIGNED, X FLOAT, Y FLOAT, Z FLOAT, O FLOAT, var1 INT UNSIGNED, var2 INT UNSIGNED, var3 INT UNSIGNED, PRIMARY KEY (guid))")
RegisterPlayerEvent(3, LoadStandardMount)
RegisterPlayerEvent(27, OnChangeZone)
RegisterPlayerEvent(28, OnNewMap)
RegisterPlayerEvent(42, OnCommand)
RegisterItemEvent(ITEM_ENTRY, 2, OnUseItem)
RegisterPlayerGossipEvent(182746573, 2, OnGossipSelect)
RegisterPacketEvent(0x346, 5, OnMoveSetFly)