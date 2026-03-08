local MAP_NORTHREND = 571
local ZONE_WINTERGRASP = 4197

local VEHICLE_ENTRY_IDS = {
    [28319] = true, -- NPC_WINTERGRASP_SIEGE_ENGINE_TURRET_ALLIANCE
    [32629] = true, -- NPC_WINTERGRASP_SIEGE_ENGINE_TURRET_HORDE
    [28312] = true, -- NPC_WINTERGRASP_SIEGE_ENGINE_ALLIANCE
    [32627] = true, -- NPC_WINTERGRASP_SIEGE_ENGINE_HORDE
    [27881] = true, -- NPC_WINTERGRASP_CATAPULT
    [28094] = true, -- NPC_WINTERGRASP_DEMOLISHER
    [28366] = true, -- NPC_WINTERGRASP_TOWER_CANNON
}

local ALLIANCE_FACTIONS = {
    [1] = true,   -- Human
    [3] = true,   -- Dwarf
    [4] = true,   -- Night Elf
    [8] = true,   -- Gnome
    [927] = true, -- Draenei
}

local HORDE_FACTIONS = {
    [2] = true,   -- Orc
    [5] = true,   -- Undead
    [6] = true,   -- Tauren
    [9] = true,   -- Troll
    [914] = true, -- Blood Elf
}

local SPELL_TENACITY_VEHICLE = 59911
local MAX_TENACITY_STACK = 20

local function GetTenacityStacks(allianceCount, hordeCount)
    if allianceCount == 0 or hordeCount == 0 then
        return 0, nil
    end

    local stack = 0
    local team = nil

    if allianceCount < hordeCount then
        stack = math.floor(((hordeCount / allianceCount) - 1.0) * 4.0)
        team = "alliance"
    elseif allianceCount > hordeCount then
        stack = math.floor(((allianceCount / hordeCount) - 1.0) * 4.0)
        team = "horde"
    end

    stack = math.min(stack, MAX_TENACITY_STACK)
    return stack, team
end

local function UpdateVehicleTenacity()
    local allianceCount = 0
    local hordeCount = 0

    local players = GetPlayersInWorld()
    if not players then return end

    local wgPlayers = {}

    for _, player in ipairs(players) do
        if player:GetMapId() == MAP_NORTHREND and player:GetZoneId() == ZONE_WINTERGRASP then
            wgPlayers[#wgPlayers + 1] = player
            if player:GetTeam() == 0 then
                allianceCount = allianceCount + 1
            else
                hordeCount = hordeCount + 1
            end
        end
    end

    if #wgPlayers == 0 then return end

    local stack, team = GetTenacityStacks(allianceCount, hordeCount)

    -- Collect unique vehicles from all WG players' surroundings
    local seenGuids = {}
    local allVehicles = {}

    for _, player in ipairs(wgPlayers) do
        local creatures = player:GetCreaturesInRange(500)
        if creatures then
            for _, creature in ipairs(creatures) do
                if VEHICLE_ENTRY_IDS[creature:GetEntry()] then
                    local guid = creature:GetGUIDLow()
                    if not seenGuids[guid] then
                        seenGuids[guid] = true
                        allVehicles[#allVehicles + 1] = creature
                    end
                end
            end
        end
    end

    for _, creature in ipairs(allVehicles) do
        creature:RemoveAura(SPELL_TENACITY_VEHICLE)

        if stack > 0 and team then
            local faction = creature:GetFaction()
            local isAlliance = ALLIANCE_FACTIONS[faction] ~= nil
            local isHorde = HORDE_FACTIONS[faction] ~= nil

            if (team == "alliance" and isAlliance) or (team == "horde" and isHorde) then
                creature:AddAura(SPELL_TENACITY_VEHICLE, creature)
                local aura = creature:GetAura(SPELL_TENACITY_VEHICLE)
                if aura then
                    aura:SetStackAmount(stack)
                end
            end
        end
    end
end

CreateLuaEvent(UpdateVehicleTenacity, 15000, 0)