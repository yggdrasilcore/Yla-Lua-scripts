local EMQ = require("EMQ")
local FeathersItem = 20739
local FeathersSpell = 29118
local MOUNTS_PER_PAGE = 10
local MOUNT_DATA = {}
local MOUNT_ICONS = {}
-- Multistate: standardmount cache replaced by shared player Data (see below).
local FLYING_MOUNTS = {
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
    75596, 75617, 75618, 76153, 75973, 75972, 75957
}

-- ELEVATION BARRIERS
local MAX_Z = 1700 -- Max Z in Kalimdor and Eastern Kingdoms unless zone/area exception
local TELDRASSIL_MAX_Z = 1500
local AZSHARACRATER_MAX_Z = 650
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
local AZSHARACRATER = 268000 -- change to 268 to enable flight in azshara crater

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
local function LoadMountData()
    WorldDBQueryAsync("SELECT ID, Name_Lang_enUS, SpellIconID FROM spell_dbc WHERE ID IN (3363, 8153, 32235, 32239, 32240, 32242, 32243, 32244, 32245, 32246, 32289, 32290, 32292, 32295, 32296, 32297, 32345, 33943, 37015, 39798, 39800, 39801, 39802, 39803, 39910, 40120, 40192, 40212, 41513, 41514, 41515, 41516, 41517, 41518, 42667, 42668, 42673, 42679, 43810, 43927, 44151, 44153, 44317, 44655, 44744, 44824, 44825, 44827, 46197, 46199, 47037, 48023, 49193, 51617, 51960, 54726, 54727, 54729, 54903, 58615, 59567, 59568, 59569, 59570, 59571, 59650, 59961, 59976, 59996, 60002, 60021, 60024, 60025, 60099, 61229, 61230, 61289, 61294, 61309, 61442, 61444, 61446, 61451, 61996, 61997, 62048, 63796, 63844, 63956, 63963, 64927, 65439, 66087, 66088, 67336, 69395, 71346, 71347, 71810, 72283, 72284, 72807, 72808, 74854, 74855, 75596, 75973, 75617, 75618, 76153)",
   function(result)
       local spellIconIds = {}
       local spellIds = {}
       
       if result then
           repeat
               local id = result:GetUInt32(0)
               local name = result:GetString(1)
               local iconId = result:GetUInt32(2)
               MOUNT_DATA[id] = name
               spellIconIds[iconId] = true
               table.insert(spellIds, tostring(id))
           until not result:NextRow()
       end
       
       local iconIdList = {}
       for iconId in pairs(spellIconIds) do
           table.insert(iconIdList, tostring(iconId))
       end
       
       WorldDBQueryAsync(string.format("SELECT ID, Field1 FROM spellicon_dbc WHERE ID IN (%s)", table.concat(iconIdList, ",")),
       function(iconResult)
           local iconPaths = {}
           
           if iconResult then
               repeat
                   local iconId = iconResult:GetUInt32(0)
                   local iconName = iconResult:GetString(1)
                   iconPaths[iconId] = string.format("Interface/Icons/%s", iconName:gsub("InterfaceIcons", ""))
               until not iconResult:NextRow()
           end
           
           WorldDBQueryAsync(string.format("SELECT ID, SpellIconID FROM spell_dbc WHERE ID IN (%s)", table.concat(spellIds, ",")),
            function(spellResult)
                if spellResult then
                    repeat
                        local spellId = spellResult:GetUInt32(0)
                        local iconId = spellResult:GetUInt32(1)
                        MOUNT_ICONS[spellId] = iconPaths[iconId]
                    until not spellResult:NextRow()
                end
                if SetWorldData then
                    SetWorldData("FeathersMountData", {data = MOUNT_DATA, icons = MOUNT_ICONS})
                end
                local n = 0
                for _ in pairs(MOUNT_DATA) do n = n + 1 end
                print("[Feathers of Azeroth]: Published " .. n .. " mounts to world data")
            end)
        end)
    end)
end

local function AdoptFeathersMountData()
    local shared = GetWorldData("FeathersMountData")
    if type(shared) == "table" and shared.AsTable then
        shared = shared:AsTable()
    end
    if type(shared) ~= "table" or type(shared.data) ~= "table" then
        return false
    end
    for k, v in pairs(shared.data) do MOUNT_DATA[k] = v end
    if type(shared.icons) == "table" then
        for k, v in pairs(shared.icons) do MOUNT_ICONS[k] = v end
    end
    return true
end

-- World queries names/icons once and publishes them; map states adopt on
-- demand when a menu opens (world -> map).
if GetStateMapId() == -1 then
    LoadMountData()
end

local function IsInOldWorld(player)
	local mapId = player:GetMapId()
	local zoneId = player:GetZoneId()
	local areaId = player:GetAreaId()

	return mapId == 0 or mapId == 1
	or zoneId == 3430 or zoneId == 3433 or zoneId == 3557
	or zoneId == 3524 or zoneId == 4080 or zoneId == 3487
	or zoneId == 3455 or zoneId == 3525 or zoneId == 3479
	or areaId == 3496 or areaId == 2274 or areaId == 4281
end

local function CanFly(player)
	if player:GetMapId() == 530 or player:GetMapId() == 571 then return true end
	if IsInOldWorld(player) and player:HasSpell(FeathersSpell) then return true end
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

local function ZonesToCheckZ(player)
   if not player then return end
   local zoneId = player:GetZoneId()
   local areaId = player:GetAreaId()
   local mapId = player:GetMapId()
   
   return (
       mapId == KALIMDOR or mapId == EASTERN_KINGDOMS or
       zoneId == SILVERMOON or zoneId == ISLEOFQD or zoneId == EVERSONG or zoneId == GHOSTLANDS or zoneId == STORMWIND or
       zoneId == ORGRIMMAR or zoneId == UNDERCITY or areaId == RUINSOFLORDAERON or areaId == SHININGSTRAND or 
       zoneId == SWHARBOR or zoneId == AZSHARACRATER
   )
end

local function CheckZ(eventId, delay, repeats, player)
  local mapId = player:GetMapId()
  local zoneId = player:GetZoneId()
  local areaId = player:GetAreaId()
  local x, y, z, o = player:GetLocation()
  
  local maxObjectZ = z - 1
  local canTeleport = player:IsWithinLoS(x, y, maxObjectZ)
  local mountId
  
  for _, id in ipairs(FLYING_MOUNTS) do
      if player:HasAura(id) then
          mountId = (id)
      end
  end
  
   if not mountId or not ZonesToCheckZ(player) then
       player:SetData("MountEvent", false)
       return
   end
  
  local currentLocKey = player:GetData("CurrentLocKey") or "Loc1"
  local nextLocKey = currentLocKey == "Loc1" and "Loc2" or "Loc1"
  
  local maxAllowedZ = MAX_Z
  local teleportZ = MAX_Z - TELEPORT_Z_OFFSET
  if zoneId == ORGRIMMAR then
      maxAllowedZ = ORGRIMMAR_MAX_Z
      teleportZ = ORGRIMMAR_MAX_Z
  elseif zoneId == UNDERCITY then
      maxAllowedZ = UNDERCITY_MAX_Z
      teleportZ = UNDERCITY_MAX_Z-1
  elseif areaId == RUINSOFLORDAERON then
      maxAllowedZ = RUINSOFLORADERON_MAX_Z
      teleportZ = RUINSOFLORADERON_MAX_Z-1
  elseif areaId == SHININGSTRAND then
      maxAllowedZ = RUINSOFLORADERON_MAX_Z
      teleportZ = RUINSOFLORADERON_MAX_Z-1
  elseif zoneId == SILVERMOON then
      maxAllowedZ = SILVERMOON_MAX_Z
      teleportZ = SILVERMOON_MAX_Z
  elseif zoneId == AZSHARACRATER then
      maxAllowedZ = AZSHARACRATER_MAX_Z
      teleportZ = AZSHARACRATER_MAX_Z
  elseif zoneId == ISLEOFQD then
      maxAllowedZ = ISLEOFQD_MAX_Z
      teleportZ = ISLEOFQD_MAX_Z
  elseif zoneId == SWHARBOR then
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
  
  if z <= teleportZ then
      player:SetData(currentLocKey, string.format("%f,%f,%f,%f", x, y, z, o))
      player:SetData("CurrentLocKey", nextLocKey)
  end
  
  if z > maxAllowedZ and canTeleport then
      local prevLoc = player:GetData(nextLocKey)
      if prevLoc then
          local lastX, lastY, lastZ, lastO = prevLoc:match("([^,]+),([^,]+),([^,]+),([^,]+)")
          lastX, lastY, lastZ, lastO = tonumber(lastX), tonumber(lastY), tonumber(lastZ), tonumber(lastO)
          
          player:Teleport(mapId, lastX, lastY, math.min(lastZ, teleportZ), lastO)
      else
          player:Teleport(mapId, x, y, teleportZ, o)
      end
      
       if not player:GetData("LastWarning") or os.time() - player:GetData("LastWarning") >= 5 then
           player:SendBroadcastMessage("You can't fly that high in this area!")
           player:SetData("LastWarning", os.time())
       end
   end
   player:RegisterEvent(CheckZ, 200, 1)
end

-- Start gossip management
local function ShowManageStandardMount(event, player)
    player:GossipClearMenu()
    player:GossipMenuAddItem(0, "|TInterface/ICONS/INV_Misc_QuestionMark:32:32:-22:0|tWhat is standard mount?", 0, 300000)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/spell_nature_swiftness:32:32:-22:0|tChoose standard mount", 0, 400000)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_enggizmos_27:32:32:-22:0|tRemove standard mount", 0, 300002)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_map_01:32:32:-22:0|tBack", 0, 1)
    player:GossipSendMenu(12, player, 182746573)
end

local function ShowManageStandardMountCmd(event, player)
    player:GossipClearMenu()
    player:GossipMenuAddItem(0, "|TInterface/ICONS/INV_Misc_QuestionMark:32:32:-22:0|tWhat is standard mount?", 0, 300001)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/spell_nature_swiftness:32:32:-22:0|tChoose standard mount", 0, 400000)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_enggizmos_27:32:32:-22:0|tRemove standard mount", 0, 300003)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_map_01:32:32:-22:0|tClose", 0, 2)
    player:GossipSendMenu(12, player, 182746573)
end

local function ShowInfoPage(event, player)
    player:GossipClearMenu()
    player:GossipMenuAddItem(0, "|TInterface/ICONS/INV_Misc_QuestionMark:32:32:-22:0|tWhat is standard mount?\n \nStandard mount allows you to set a preferred mount that will be automatically cast when using the Feathers of Azeroth.\n \nYou can change or remove your standard mount at any time by talking to your Twiggy.\n \n ", 0, 300000)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_map_01:32:32:-22:0|tBack", 0, 600000)
    player:GossipSendMenu(12, player, 182746573)
end

local function ShowInfoPageCmd(event, player)
    player:GossipClearMenu()
    player:GossipMenuAddItem(0, "|TInterface/ICONS/INV_Misc_QuestionMark:32:32:-22:0|tWhat is standard mount?\n \nStandard mount allows you to set a preferred mount that will be automatically cast when using the Feathers of Azeroth.\n \nYou can change or remove your standard mount at any time by talking to your Twiggy.\n \n ", 0, 300001)
    player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_map_01:32:32:-22:0|tBack", 0, 600001)
    player:GossipSendMenu(12, player, 182746573)
end

local function ShowMountMenu(event, player, item, target, page, isStandardMount)
    page = page or 1
    
    -- Mount list comes from the static FLYING_MOUNTS table; MOUNT_DATA and
    -- MOUNT_ICONS are display-only (names/icons) with fallbacks. Shared data
    -- is adopted on demand (world -> map).
    if next(MOUNT_DATA) == nil then
        AdoptFeathersMountData()
    end
    local availableMounts = {}
    local knownMounts = 0
    for _ in pairs(MOUNT_DATA) do knownMounts = knownMounts + 1 end
    for _, spellId in ipairs(FLYING_MOUNTS) do
        if player:HasSpell(spellId) then
            table.insert(availableMounts, spellId)
        end
    end
    print("[Feathers of Azeroth]: Mount menu for " .. player:GetName() .. ": " .. knownMounts .. " indexed, " .. #availableMounts .. " known")
    
    local totalMounts = #availableMounts
    local maxPages = math.ceil(totalMounts / MOUNTS_PER_PAGE)
    
    -- Create gossip menu
    player:GossipClearMenu()
    if isStandardMount then
        player:GossipMenuAddItem(0, "|TInterface/ICONS/spell_nature_swiftness:32:32:-22:0|tChoosing standard mount", 0, 400000)
    else
        player:GossipMenuAddItem(0, "|TInterface/ICONS/trade_engineering:32:32:-22:0|tManage standard mount", 0, 700000)
    end
    
    -- Add mount options for current page
    local startIndex = ((page - 1) * MOUNTS_PER_PAGE) + 1
    local endIndex = math.min(startIndex + MOUNTS_PER_PAGE - 1, totalMounts)
    
    for i = startIndex, endIndex do
        local spellId = availableMounts[i]
        local spellName = MOUNT_DATA[spellId] or ("Spell " .. tostring(spellId))
        local iconPath = MOUNT_ICONS[spellId]
        if spellId == 75596 then 
            iconPath = "Interface/ICONS/ability_mount_frostyflyingcarpet"
        elseif spellId == 75973 then 
            iconPath = "Interface/ICONS/ability_mount_rocketmount2"
		end
        iconPath = iconPath or "Interface/ICONS/inv_misc_questionmark"
        -- Add icon to gossip menu item
        if isStandardMount then
            player:GossipMenuAddItem(4, "|T" .. iconPath .. ":32:32:-22:0|t" .. spellName, 0, 800000 + spellId)
        else
            player:GossipMenuAddItem(4, "|T" .. iconPath .. ":32:32:-22:0|t" .. spellName, 0, spellId)
        end
    end
    
    -- Navigation buttons
    if page < maxPages then
        local nextPageIntid = isStandardMount and (400000 + page) or (100000 + page)
        player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_map_01:32:32:-22:0|tNext Page", 0, nextPageIntid)
    end
    
    if page > 1 then
        local prevPageIntid = isStandardMount and (500000 + page) or (200000 + page)
        player:GossipMenuAddItem(0, "|TInterface/ICONS/inv_misc_map_01:32:32:-22:0|tPrevious Page", 0, prevPageIntid)
    end
    
    player:GossipSendMenu(12, player, 182746573)
end

local function OnGossipSelect(event, player, object, sender, intid, code, menu_id)
    print("[Feathers of Azeroth]: Player "..player:GetName().." just clicked Feathers of Azeroth button "..intid)
    if intid == 1 then
        ShowMountMenu(event, player, item, target, 1)
    elseif intid >= 100000 and intid < 200000 then
        -- Next page (normal mount)
        local currentPage = intid - 100000
        ShowMountMenu(event, player, nil, nil, currentPage + 1, false)
    elseif intid >= 200000 and intid < 300000 then
        -- Previous page (normal mount)
        local currentPage = intid - 200000
        ShowMountMenu(event, player, nil, nil, currentPage - 1, false)
    elseif intid == 300000 then
        ShowInfoPage(event, player)
    elseif intid == 300001 then
        ShowInfoPageCmd(event, player)
    elseif intid == 400000 then
        -- Choose standard mount
        ShowMountMenu(event, player, nil, nil, 1, true)
    elseif intid >= 400000 and intid < 500000 then
        -- Next page (standard mount)
        local currentPage = intid - 400000
        ShowMountMenu(event, player, nil, nil, currentPage + 1, true)
    elseif intid >= 500000 and intid < 600000 then
        -- Previous page (standard mount)
        local currentPage = intid - 500000
        ShowMountMenu(event, player, nil, nil, currentPage - 1, true)
    elseif intid == 300002 then
        player:Data():Set("FeathersStandardMount", nil)
        print("[Feathers of Azeroth]: Standard mount for "..player:GetName().." is nil")
        player:SendBroadcastMessage("Standard mount removed.")
        CharDBExecute(string.format("DELETE FROM acore_eluna.character_flight WHERE guid = %d", player:GetGUIDLow()))
        ShowManageStandardMount(event, player)
    elseif intid == 300003 then
        player:Data():Set("FeathersStandardMount", nil)
        print("[Feathers of Azeroth]: Standard mount for "..player:GetName().." is nil")
        player:SendBroadcastMessage("Standard mount removed.")
        CharDBExecute(string.format("DELETE FROM acore_eluna.character_flight WHERE guid = %d", player:GetGUIDLow()))
        ShowManageStandardMountCmd(event, player)
    elseif intid == 600000 then
        ShowManageStandardMount(event, player)
    elseif intid == 600001 then
        ShowManageStandardMountCmd(event, player)
    elseif intid == 700000 then
        ShowManageStandardMount(event, player)
    elseif intid == 700001 then
        ShowManageStandardMountCmd(event, player)
    elseif intid >= 800000 then
        -- Mount selected as standard
        local mountId = intid - 800000
        player:Data():Set("FeathersStandardMount", mountId)
        print("[Feathers of Azeroth]: Selecting standard mount for "..player:GetName().." is ".. tostring(player:Data():Get("FeathersStandardMount")) .." (mount ID "..mountId..")")
        CharDBExecute(string.format("REPLACE INTO acore_eluna.character_flight (guid, standardmount) VALUES (%d, %d)", player:GetGUIDLow(), mountId))
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
				CheckFlyableArea(event, player, player:GetZoneId(), player:GetAreaId())
            end, 3000, 1)
            player:GossipComplete()
        else
            player:SendBroadcastMessage("You can't use this item while casting!") 
        end
    end
end

local function checkMount(player)
	for _, id in ipairs(FLYING_MOUNTS) do
		if player:HasAura(id) then
			if not player:GetData("MountEvent") then
				player:SetData("MountEvent", true)
				player:RegisterEvent(CheckZ, 200, 1)
				print("[Feathers of Azeroth]: Starting zone-based Z check")
			end
		end
	end
end

function CheckFlyableArea(event, player, zoneId, areaId)
    if ZonesToCheckZ(player) then
		if not event then checkMount(player) return end -- On script load, there's no event call, fire immediately
		local d = 100 -- Else, default to a delay
		if player:IsCasting() then d = 4000	end -- Set delay to at least 4 sec if player is casting during call (mounting in progress)
        player:RegisterEvent(function(eventId, delay, repeats, player)
			checkMount(player)
        end, d, 1)
    end
end

local function OnUseItem(event, player, item, target)
    if player:IsCasting() then return false end
    
    if not (player:HasSpell(34091) or player:HasSpell(34090)) then
        player:SendBroadcastMessage("You can't use this item without knowing how to fly!")
        return false
    end
    
    if not player:HasSpell(FeathersSpell) then
        player:LearnSpell(FeathersSpell)
    end
    
    if not IsInOldWorld(player) or player:GetInstanceId() > 0 or player:InBattleground() then
        player:SendBroadcastMessage("The Feathers of Azeroth can't carry you here.")
        return false
    end
    
    local standardMount = player:Data():Get("FeathersStandardMount")
    if standardMount and not player:IsCasting() then
        player:CastSpell(player, standardMount, false)
        print("[Feathers of Azeroth]: Standard mount for "..player:GetName().." is ".. standardMount)
		CheckFlyableArea(event, player, player:GetZoneId(), player:GetAreaId())
    else
        ShowMountMenu(event, player, item, target, 1)
    end
    return false
end

local function RemoveFlyingMount(eventId, delay, repeats, player)
	if not player:IsMounted() then return end
    
	if CanFly(player) then return end
	
	for _, id in ipairs(FLYING_MOUNTS) do
		if player:HasAura(id) then
			player:RemoveAura(id)
			break
		end
	end
end

local function OnMapChange(event, player)
	player:RegisterEvent(RemoveFlyingMount, 500, 1)
end

local function LoadStandardMount(event, player)
    local guid = player:GetGUIDLow()
    local result = CharDBQuery(string.format("SELECT standardmount FROM acore_eluna.character_flight WHERE guid = %d", guid))
    if result then
        local mountId = result:GetUInt32(0)
        if mountId  then
            player:Data():Set("FeathersStandardMount", mountId)
            print("[Feathers of Azeroth]: Standard mount for "..player:GetName().." is ".. mountId)
        end
    end
end

local function OnLoadScript()
    local dbQueryTable = {}
    
    -- Multistate: state-aware enumeration (GetPlayersInWorld is world-only).
    for _, player in ipairs(GetStateMapId() == -1 and GetPlayersInWorld() or GetStateMap():GetPlayers()) do
        if player:HasItem(FeathersItem) then
            table.insert(dbQueryTable, player:GetGUIDLow())
			CheckFlyableArea(event, player, player:GetZoneId(), player:GetAreaId())
        end
    end
    
    -- If we found any players with the item, query their standard mounts
    if #dbQueryTable > 0 then
        local queryStr = string.format("SELECT guid, standardmount FROM acore_eluna.character_flight WHERE guid IN (%s)", 
            table.concat(dbQueryTable, ","))
        local result = CharDBQuery(queryStr)
        
        if result then
            repeat
                local guid = result:GetUInt32(0)
                local mountId = result:GetUInt32(1)
                if mountId then
                    local p
                    if GetStateMapId() == -1 then p = GetPlayerByGUID(guid)
                    else for _, q in ipairs(GetStateMap():GetPlayers()) do
                        if q:GetGUIDLow() == guid then p = q break end
                    end end
                    if p then p:Data():Set("FeathersStandardMount", mountId) end
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
        RemoveFlyingMount(_, _, _, player)
    end
end

-- Map-state executor for mount-by-command (via EMQ, or directly in compat mode).
local function DoCastMountCommand(player, data)
    if not player or not data or not data.spellId then
        return
    end
    player:CastSpell(player, data.spellId, false)
    CheckFlyableArea(42, player, player:GetZoneId(), player:GetAreaId())
end

EMQ.RegisterQueue("FeathersCastMount", DoCastMountCommand)

local function OnCommand(event, player, command)
    if command == "choosestandardfeathers" then
        ShowManageStandardMountCmd(event, player)
        return false
    end

    for _, spellId in ipairs(FLYING_MOUNTS) do
        if command == tostring(spellId) then
            if player:IsCasting() or not player:HasSpell(spellId)
            then
                return false
            end
            -- Multistate: the cast and the follow-up zone check must run on the
            -- player's map state.
            local data = { spellId = spellId }
            player:SendEMQMessage("FeathersCastMount", data)
            return false
        end
    end
end

local function OnX53orInvincible(event, player, spell, skipCheck)
	if not IsInOldWorld(player) then return end -- Skips players on native flight areas
    
    if player:HasSpell(FeathersSpell) then -- Only proceed for Feather Burst
    
        if player:HasAura(75973) then -- x-53, no speed
            player:RemoveAura(75973)
            if player:HasSpell(34091) then player:AddAura(75972, player) -- Fast flight
            elseif player:HasSpell(34090) then player:AddAura(75957, player) -- Slow flight
            end
        elseif player:HasAura(72282) then -- Ground invincible
            player:RemoveAura(72282)
            if player:HasSpell(34091) then player:AddAura(72284, player) -- Fast Flight
            elseif player:HasSpell(34090) then player:AddAura(72283, player) -- Slow flight
            end
        end
        
    else
        if player:HasAura(72284) then player:RemoveAura(72284) player:AddAura(72282, player) -- Override fast Invincible to walking if no feathers
        elseif player:HasAura(72283) then player:RemoveAura(72283) player:AddAura(72282, player) -- Override slow Invincible to walking if no feathers
        end
   end
end

local function OnCastFlyingMount(event, player, spell)
	if CanFly(player) then return end
	
	player:SendNotification("You can't use that here.")
	spell:Cancel()
end

OnLoadScript()
WorldDBExecute("UPDATE item_template SET description = 'This item has the ability to wrap the wings of your flying mounts with the Feathers of Azeroth, permitting their use in Azeroth.' WHERE entry = 20739")
CharDBExecute("CREATE TABLE IF NOT EXISTS acore_eluna.character_flight (guid INT UNSIGNED NOT NULL, standardmount INT UNSIGNED, X FLOAT, Y FLOAT, Z FLOAT, O FLOAT, var1 INT UNSIGNED, var2 INT UNSIGNED, var3 INT UNSIGNED, PRIMARY KEY (guid))")
RegisterPlayerEvent(3, LoadStandardMount)
RegisterPlayerEvent(27, CheckFlyableArea)
RegisterPlayerEvent(28, OnMapChange)
RegisterPlayerEvent(42, OnCommand)
RegisterItemEvent(FeathersItem, 2, OnUseItem)
RegisterPlayerGossipEvent(182746573, 2, OnGossipSelect)
RegisterPacketEvent(0x346, 5, OnMoveSetFly) -- If a player tries to fly, check if they should be able to
RegisterSpellEvent(75973, 2, OnX53orInvincible)
RegisterSpellEvent(72282, 2, OnX53orInvincible)
RegisterSpellEvent(72283, 2, OnX53orInvincible)
RegisterSpellEvent(72284, 2, OnX53orInvincible)
for _, spellId in ipairs(FLYING_MOUNTS) do
    RegisterSpellEvent(spellId, 1, OnCastFlyingMount)
end