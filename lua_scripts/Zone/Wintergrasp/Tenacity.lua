local WG_LossCount = {}
local WG_LossRecorded = false

local MAP_NORTHREND = 571
local ZONE_WINTERGRASP = 4197

local VEHICLE_ENTRY_IDS = {
    [28319] = true,
    [32629] = true,
    [28312] = true,
    [32627] = true,
    [27881] = true,
    [28094] = true,
    [28366] = true,
}

local ALLIANCE_FACTIONS = {
    [1] = true,
    [3] = true,
    [4] = true,
    [8] = true,
    [927] = true,
}

local HORDE_FACTIONS = {
    [2] = true,
    [5] = true,
    [6] = true,
    [9] = true,
    [914] = true,
}

local TENACITY_PLAYER = 58549
local TENACITY_VEHICLE = 59911
local MAX_TENACITY = 20

CharDBExecute([[CREATE TABLE IF NOT EXISTS acore_eluna.persistent_storage (entry varchar(100) NOT NULL, value varchar(100) NULL, comment varchar(100) NULL, PRIMARY KEY (entry))]])

local function SaveLossCount()
    local alliance = WG_LossCount["Alliance"] or 0
    local horde = WG_LossCount["Horde"] or 0
    -- positive = alliance losses, negative = horde losses
    local encoded = alliance - horde
    CharDBExecute("REPLACE INTO acore_eluna.persistent_storage (entry, value, comment) VALUES ('wg_loss_count', '" .. encoded .. "', 'WG tenacity loss count: positive=alliance losses, negative=horde losses')")
end

CharDBQueryAsync("SELECT value FROM acore_eluna.persistent_storage WHERE entry = 'wg_loss_count'", function(query)
    if query then
        local encoded = tonumber(query:GetString(0)) or 0
        if encoded > 0 then
            WG_LossCount["Alliance"] = encoded
            WG_LossCount["Horde"] = 0
        elseif encoded < 0 then
            WG_LossCount["Horde"] = -encoded
            WG_LossCount["Alliance"] = 0
        end
        print("[WG] Restored loss count: Alliance=" .. (WG_LossCount["Alliance"] or 0) .. " Horde=" .. (WG_LossCount["Horde"] or 0))
    else
        print("[WG] No loss count found in DB, starting fresh")
    end
end)

function CompoundTenacity(controllerChanged)
    if controllerChanged then
        WG_LossCount["Alliance"] = 0
        WG_LossCount["Horde"] = 0
        SaveLossCount()
        print("[WG] Defender changed to " .. WG_Controller .. ". Loss counts reset.")
    else
        local loser = WG_Controller == "Alliance" and "Horde" or "Alliance"
        WG_LossCount[loser] = (WG_LossCount[loser] or 0) + 1
        WG_LossCount[WG_Controller] = 0
        SaveLossCount()
        print("[WG] " .. WG_Controller .. " won. " .. loser .. " lost (loss count: " .. WG_LossCount[loser] .. ")")
    end
end

local function GetTenacityStacks(allianceCount, hordeCount)
    if allianceCount == 0 and hordeCount == 0 then
        return 0, nil
    end

    local stack = 0
    local team = nil

    if allianceCount == 0 then
        team = "horde"
    elseif hordeCount == 0 then
        team = "alliance"
    elseif allianceCount < hordeCount then
        stack = math.floor(((hordeCount / allianceCount) - 1.0) * 4.0)
        team = "alliance"
    elseif allianceCount > hordeCount then
        stack = math.floor(((allianceCount / hordeCount) - 1.0) * 4.0)
        team = "horde"
    end

    stack = math.min(stack, MAX_TENACITY)
    return stack, team
end

local function GetWGPlayers()
    local allianceCount = 0
    local hordeCount = 0
    local wgPlayers = {}

    local players = GetPlayersInWorld()
    if not players then return wgPlayers, allianceCount, hordeCount end

    for _, player in ipairs(players) do
        if player:GetMapId() == MAP_NORTHREND and player:GetZoneId() == ZONE_WINTERGRASP then
            if player:GetAura(37795) or player:GetAura(33280) or player:GetAura(55629) then
                wgPlayers[#wgPlayers + 1] = player
                if player:GetTeam() == 0 then
                    allianceCount = allianceCount + 1
                else
                    hordeCount = hordeCount + 1
                end
            end
        end
    end

    return wgPlayers, allianceCount, hordeCount
end

local function GetStacksForTeam(playerTeam, stack, team)
    local lossBonus = math.max((WG_LossCount[playerTeam == "alliance" and "Alliance" or "Horde"] or 0) - 1, 0)
    local outnumberedBonus = (team == playerTeam) and stack or 0
    return math.min(outnumberedBonus + lossBonus, MAX_TENACITY)
end

local function UpdatePlayerTenacity(eventid, delay, repeats, player)
    if player:GetZoneId() ~= ZONE_WINTERGRASP then
        player:RemoveAura(TENACITY_PLAYER)
        player:RemoveEventById(eventid)
        return
    end

    if not (player:GetAura(37795) or player:GetAura(33280) or player:GetAura(55629)) then
        player:RemoveAura(TENACITY_PLAYER)
        return
    end

    if not WG_FightActive then
        player:RemoveAura(TENACITY_PLAYER)
        return
    end

    if not WG_FightActive then return end

    local _, allianceCount, hordeCount = GetWGPlayers()
    local stack, team = GetTenacityStacks(allianceCount, hordeCount)

    local playerTeam = player:GetTeam() == 0 and "alliance" or "horde"
    local totalStack = GetStacksForTeam(playerTeam, stack, team)

    if totalStack == 0 then
        player:RemoveAura(TENACITY_PLAYER)
    else
        local aura = player:GetAura(TENACITY_PLAYER)
        if not aura then
            player:AddAura(TENACITY_PLAYER, player)
            aura = player:GetAura(TENACITY_PLAYER)
        end
        if aura and aura:GetStackAmount() ~= totalStack then
            aura:SetStackAmount(totalStack)
        end
    end
end

local function UpdateVehicleTenacity()
    if not WG_FightActive then return end

    local wgPlayers, allianceCount, hordeCount = GetWGPlayers()
    if #wgPlayers == 0 then return end

    local stack, team = GetTenacityStacks(allianceCount, hordeCount)

    local seenGuids = {}
    local allVehicles = {}

    for _, player in ipairs(wgPlayers) do
        local creatures = player:GetCreaturesInRange(200)
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
        local faction = creature:GetFaction()
        local vehicleTeam = ALLIANCE_FACTIONS[faction] and "alliance" or (HORDE_FACTIONS[faction] and "horde" or nil)

        if vehicleTeam then
            local totalStack = GetStacksForTeam(vehicleTeam, stack, team)
            if totalStack == 0 then
                creature:RemoveAura(TENACITY_VEHICLE)
            else
                local aura = creature:GetAura(TENACITY_VEHICLE)
                if not aura then
                    creature:AddAura(TENACITY_VEHICLE, creature)
                    aura = creature:GetAura(TENACITY_VEHICLE)
                end
                if aura and aura:GetStackAmount() ~= totalStack then
                    aura:SetStackAmount(totalStack)
                end
            end
        else
            creature:RemoveAura(TENACITY_VEHICLE)
        end
    end
end

local function OnPlayerEnterWintergrasp(event, player, newZone, newArea)
    if event == 4 then -- Logout
        if player:HasAura(TENACITY_PLAYER) then
            player:RemoveAura(TENACITY_PLAYER)
        end
    elseif player:GetZoneId() == ZONE_WINTERGRASP then
        player:RegisterEvent(UpdatePlayerTenacity, 1000, 0)
    end
end

for _, player in ipairs(GetPlayersInWorld()) do OnPlayerEnterWintergrasp(_, player, _, _) end

CreateLuaEvent(UpdateVehicleTenacity, 1000, 0)
RegisterPlayerEvent(4, OnPlayerEnterWintergrasp)
RegisterPlayerEvent(27, OnPlayerEnterWintergrasp)









--- WG Lua Controller


WG_FightActive = false
WG_Controller = nil

local WG_LastTimer = nil
local WG_LastController = nil
local WG_WasWarTime = false

local function CheckWintergraspState()
    local timer = GetWintergraspTimer()
    local hasValidTimer = (timer ~= nil and timer > 0)

    local defender = GetWintergraspDefenderTeam()
    if defender == 0 then
        WG_Controller = "Alliance"
    else
        WG_Controller = "Horde"
    end

    local hadValidTimer = (WG_LastTimer ~= nil and WG_LastTimer > 0)
    local controllerChanged = (WG_LastController ~= nil and WG_LastController ~= WG_Controller)

    if IsWintergraspWarTime() then
        ProcessWintergraspWorldstate(3801, 0)
        WG_FightActive = true
    else
        WG_FightActive = false
    end

    if WG_WasWarTime and not IsWintergraspWarTime() then
        CompoundTenacity(controllerChanged)
    end

    WG_LastTimer = timer
    WG_LastController = WG_Controller
    WG_WasWarTime = WG_FightActive
end

CreateLuaEvent(CheckWintergraspState, 5000, 0)

CharDBQueryAsync("SELECT value FROM worldstates WHERE entry = 3802", function(query)
    if query then
        local v = query:GetUInt32(0)
        if v == 0 then
            WG_Controller = "Alliance"
        else
            WG_Controller = "Horde"
        end
    end
end)

local function InitializeWGState()
    if IsWintergraspWarTime() then
        WG_FightActive = true
    else
        WG_FightActive = false
    end
end

InitializeWGState()