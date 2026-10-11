-- Multistate: Utgarde Keep-only script (map 574).
if not IsCompatibilityMode() and GetStateMapId() ~= 574 then return end

local INGVAR_ENTRY               = 23954

local UTGARDE_KEEP_MAP_ID        = 574

local SPELL_STAGGERING_ROAR_N    = 42708
local SPELL_STAGGERING_ROAR_H    = 59708
local SPELL_SMASH_N              = 42669
local SPELL_SMASH_H              = 59706
local SPELL_DREADFUL_ROAR_N      = 42729
local SPELL_DREADFUL_ROAR_H      = 59734
local SPELL_WOE_STRIKE_N         = 42730
local SPELL_WOE_STRIKE_H         = 59735
local SPELL_DARK_SMASH_N         = 42723
local SPELL_DARK_SMASH_H         = 59709

local REMOVE_CURSE               = 475

local PILLAR_1                   = {213.88, -316.06}
local PILLAR_2                   = {244.54, -300.06}
local PILLAR_RADIUS              = 4.2

local STAGE_CENTER                = {228.68, -307.82}
local STAGE_RADIUS                = 34

local TANK_SPOT                   = {229.85, -310.44}

local Z_HEIGHT                    = 180.492

local TICK_FREQUENCY              = 500

local function GetClosestPillar(px, py)
    local d1 = math.sqrt((px - PILLAR_1[1])^2 + (py - PILLAR_1[2])^2)
    local d2 = math.sqrt((px - PILLAR_2[1])^2 + (py - PILLAR_2[2])^2)
    if d1 <= d2 then
        return PILLAR_1
    end
    return PILLAR_2
end

local function TryFindLosBreakPos(ingvar, pillar)
    local ix, iy = ingvar:GetX(), ingvar:GetY()
    local dx, dy = pillar[1] - ix, pillar[2] - iy
    local len = math.sqrt(dx*dx + dy*dy)
    if len == 0 then return nil end

    local nx, ny = dx / len, dy / len
    local baseX = pillar[1] + nx * PILLAR_RADIUS
    local baseY = pillar[2] + ny * PILLAR_RADIUS

    local px_, py_ = -ny, nx

    local offsets = {0, 0.5, -0.5, 1.0, -1.0}
    for _, offset in ipairs(offsets) do
        local testX = baseX + px_ * offset
        local testY = baseY + py_ * offset
        if not ingvar:IsWithinLoS(testX, testY, Z_HEIGHT) then
            return testX, testY
        end
    end
    return nil
end

local function MoveBehindTarget(player, target, distance)
    local facing = target:GetO()
    local behindAngle = facing + math.pi
    local tx, ty = target:GetLocation()
    local targetX = tx + distance * math.cos(behindAngle)
    local targetY = ty + distance * math.sin(behindAngle)

    for _, pillar in ipairs({PILLAR_1, PILLAR_2}) do
        local dx, dy = targetX - pillar[1], targetY - pillar[2]
        local dist = math.sqrt(dx*dx + dy*dy)
        local minDist = PILLAR_RADIUS + 3
        if dist < minDist then
            local nx, ny = dx / dist, dy / dist
            targetX = pillar[1] + nx * minDist
            targetY = pillar[2] + ny * minDist
        end
    end

    player:MoveTo(1, targetX, targetY, Z_HEIGHT, true)
end

local function IngvarLoop(event, delay, repeats, player)
    if player:GetMapId() ~= UTGARDE_KEEP_MAP_ID then player:RemoveEventById(event) end

    local ingvar = player:GetNearestCreature(100, INGVAR_ENTRY)
    if not ingvar then return end
    
    if not ingvar:IsInCombat() then return end

    local px, py = player:GetLocation()
    local distToStage = math.sqrt((px - STAGE_CENTER[1])^2 + (py - STAGE_CENTER[2])^2)
    if distToStage > STAGE_RADIUS then return end

    if IsTank(player) then
        if ingvar:IsInCombat() and player:IsInCombat() and ingvar:GetVictim() == player and not ingvar:GetData("SmashActive") then
            if not IsAtPos(player, TANK_SPOT[1], TANK_SPOT[2], 2) then
                player:RemoveAura(1604)
                player:MoveTo(1, TANK_SPOT[1], TANK_SPOT[2], Z_HEIGHT, true)
            end
        end

        if IsAtPos(player, TANK_SPOT[1], TANK_SPOT[2], 2) and not ingvar:IsCasting() then
            if not IsAtPos(ingvar, STAGE_CENTER[1], STAGE_CENTER[2], 2) then
                ingvar:MoveTo(1, STAGE_CENTER[1], STAGE_CENTER[2], Z_HEIGHT, true)
            end
        end
    else
        if ingvar:IsInBack(player, 3*math.pi/2) then
            MoveBehindTarget(player, ingvar, 4)
        end

        if ingvar:GetData("RoarActive") then
            local pillar = GetClosestPillar(px, py)
            local losX, losY = TryFindLosBreakPos(ingvar, pillar)

            if losX then
                local dist = player:GetDistance2d(losX, losY)
                DisableSpellCast(player, 0.2)
                player:RemoveAura(1604)
                if dist > 10 then
                    UseRocketBoots(player)
                end
                player:MoveTo(1, losX, losY, Z_HEIGHT, true)
            end

            if not ingvar:IsWithinLoS(px, py, Z_HEIGHT) then
                AddRootAura(player, 2000)
            end
        end
    end

    if ingvar:GetData("SmashActive") and not ingvar:GetData("RoarActive") then
        if not ingvar:IsInBack(player, 3*math.pi/2) then
            MoveBehindTarget(player, ingvar, 4)
        end
    end
        
    if not ingvar:GetData("RoarActive") and not ingvar:GetData("SmashActive") then
        RemoveRootAura(player)
    end

    local nearbyPlayers = player:GetPlayersInRange(40)
    for _, target in ipairs(nearbyPlayers) do
        if target:HasAura(SPELL_WOE_STRIKE_N) or target:HasAura(SPELL_WOE_STRIKE_H) then
            player:CastSpell(target, REMOVE_CURSE, true)
            break
        end
    end
    
    if not player:IsMoving() then
        player:SetFacingToObject(ingvar)
    end
end

local function OnEnterUtgardeKeep(event, player)
    if not player:IsBot() then return end
    if not (player:GetMapId() == UTGARDE_KEEP_MAP_ID) then return end

    player:RegisterEvent(IngvarLoop, TICK_FREQUENCY, 0)
end

RegisterPlayerEvent(28, OnEnterUtgardeKeep)
local map = GetStateMap()
if map then
    for _, player in ipairs(map:GetPlayers()) do OnEnterUtgardeKeep(nil, player) end
end

local function OnRoarPrepare(event, caster, spell)
    caster:SetData("RoarActive", true)
end

local function OnRoarCast(event, caster, spell, skipCheck)
    caster:SetData("RoarActive", false)
end

local function OnSmashPrepare(event, caster, spell)
    caster:SetData("SmashActive", true)
end

local function OnSmashCast(event, caster, spell, skipCheck)
    caster:SetData("SmashActive", false)
end

RegisterSpellEvent(SPELL_STAGGERING_ROAR_N, 1, OnRoarPrepare)
RegisterSpellEvent(SPELL_STAGGERING_ROAR_H, 1, OnRoarPrepare)
RegisterSpellEvent(SPELL_DREADFUL_ROAR_N, 1, OnRoarPrepare)
RegisterSpellEvent(SPELL_DREADFUL_ROAR_H, 1, OnRoarPrepare)
RegisterSpellEvent(SPELL_STAGGERING_ROAR_N, 2, OnRoarCast)
RegisterSpellEvent(SPELL_STAGGERING_ROAR_H, 2, OnRoarCast)
RegisterSpellEvent(SPELL_DREADFUL_ROAR_N, 2, OnRoarCast)
RegisterSpellEvent(SPELL_DREADFUL_ROAR_H, 2, OnRoarCast)
RegisterSpellEvent(SPELL_SMASH_N, 1, OnSmashPrepare)
RegisterSpellEvent(SPELL_SMASH_H, 1, OnSmashPrepare)
RegisterSpellEvent(SPELL_DARK_SMASH_N, 1, OnSmashPrepare)
RegisterSpellEvent(SPELL_DARK_SMASH_H, 1, OnSmashPrepare)
RegisterSpellEvent(SPELL_SMASH_N, 2, OnSmashCast)
RegisterSpellEvent(SPELL_SMASH_H, 2, OnSmashCast)
RegisterSpellEvent(SPELL_DARK_SMASH_N, 2, OnSmashCast)
RegisterSpellEvent(SPELL_DARK_SMASH_H, 2, OnSmashCast)