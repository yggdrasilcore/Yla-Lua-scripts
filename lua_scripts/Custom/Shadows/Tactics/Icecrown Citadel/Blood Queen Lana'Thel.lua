if not (GetStateMapId() == 631) then return end

-- ============================================================
-- Blood-Queen Lana'thel (ICC, map 631)
-- Spell IDs from boss_blood_queen_lana_thel.cpp
-- ============================================================

local BLOOD_QUEEN_ENTRY          = 37955

-- Boss spells
local SPELL_VAMPIRIC_BITE        = 71726
local SPELL_ESSENCE_OF_BLOOD_QUEEN   = 70867
local SPELL_ESSENCE_OF_THE_BLOOD_QUEEN_PLR = 70879
local SPELL_FRENZIED_BLOODTHIRST = 70877
local SPELL_PACT_OF_THE_DARKFALLEN = 71340
local SPELL_SWARMING_SHADOWS     = 71264
local SPELL_INCITE_TERROR        = 73070
local SWARMING_SHADOWS_DYNOBJ    = 71266

-- Shadow abilities used by this script
local SPELL_TREMOR_TOTEM         = 8143
local SPELL_FEAR_WARD            = 6346
local SPELL_MASS_DISPEL          = 32375
local SPELL_EVERY_MAN_FOR_HIMSELF = 59752

-- CLASS_PRIEST, CLASS_SHAMAN, RACE_HUMAN
local CLASS_PRIEST               = 5
local CLASS_SHAMAN               = 7
local RACE_HUMAN                 = 1

-- Positions
local CENTER                     = {4596, 2769, 400}
local TANK_GROUND                = {4603, 2769, 400}

-- Radii
local ROOM_RADIUS                = 38
local HEALER_RADIUS              = 10
local AIR_RADIUS                 = 25
local RANGED_RADIUS              = 25
local RANGED_LIMIT               = 40

local PULL_DURATION              = 10
local SUPPRESS_MS                = 900000
local MESH_STEP                  = 2
local ANGLE_STEP                 = 10

local function InRoom(p)
    return p:GetX() > 4537 and p:GetX() < 4635
        and p:GetY() > 2729 and p:GetY() < 2808
        and math.abs(p:GetZ() - CENTER[3]) <= 5
end

-- ============================================================
-- Room mesh
-- ============================================================

local function BuildBaseMesh(boss)
    local mesh = {}
    local steps = math.floor(ROOM_RADIUS / MESH_STEP)
    for ix = -steps, steps do
        for iy = -steps, steps do
            local dx, dy = ix * MESH_STEP, iy * MESH_STEP
            if dx * dx + dy * dy <= ROOM_RADIUS * ROOM_RADIUS then
                local x, y = CENTER[1] + dx, CENTER[2] + dy
                table.insert(mesh, {
                    x = x,
                    y = y,
                    z = boss:GetMap():GetNearestFloor(x, y, 405),
                })
            end
        end
    end
    boss:Data():Set("BQBaseMesh", mesh)
end

local function GetDynobjSignature(dynobjs)
    local parts = {}
    for _, d in ipairs(dynobjs) do
        table.insert(parts, string.format("%.1f:%.1f", d:GetX(), d:GetY()))
    end
    table.sort(parts)
    return table.concat(parts, "|")
end

local function UpdateMesh(boss, dynobjs)
    if not boss:Data():Get("BQBaseMesh") then BuildBaseMesh(boss) end
    local sig = GetDynobjSignature(dynobjs)
    if sig == boss:Data():Get("BQMeshSignature") then return end
    boss:Data():Set("BQMeshSignature", sig)
    local mesh = boss:Data():Get("BQBaseMesh")
    local valid = {}
    for i, p in ipairs(mesh) do
        valid[i] = true
        for _, d in ipairs(dynobjs) do
            local dx, dy = p.x - d:GetX(), p.y - d:GetY()
            if dx * dx + dy * dy < 25 then
                valid[i] = false
                break
            end
        end
    end
    boss:Data():Set("BQMeshValid", valid)
end

local function ClampToRoom(x, y)
    local dx, dy = x - CENTER[1], y - CENTER[2]
    local d = math.sqrt(dx * dx + dy * dy)
    if d <= ROOM_RADIUS then return x, y end
    return CENTER[1] + dx / d * ROOM_RADIUS, CENTER[2] + dy / d * ROOM_RADIUS
end

local function IsPosValid(x, y, dynobjs)
    for _, d in ipairs(dynobjs) do
        if d:GetExactDistance2d(x, y) < 5 then
            return false
        end
    end
    return true
end

local function GetSafePos(boss, x, y, maxSearchRadius, dynobjs)
    x, y = ClampToRoom(x, y)
    local map = boss:GetMap()
    if IsPosValid(x, y, dynobjs) then
        return {x, y, map:GetNearestFloor(x, y, 405)}
    end
    if not boss:Data():Get("BQBaseMesh") then BuildBaseMesh(boss) end
    local mesh = boss:Data():Get("BQBaseMesh")
    local valid = boss:Data():Get("BQMeshValid") or {}
    local maxSq = maxSearchRadius and (maxSearchRadius * maxSearchRadius) or math.huge
    local best, bestSq = nil, math.huge
    for i, p in ipairs(mesh) do
        if valid[i] then
            local dx, dy = p.x - x, p.y - y
            local d2 = dx * dx + dy * dy
            if d2 <= maxSq and d2 < bestSq then
                bestSq = d2
                best = p
            end
        end
    end
    if best then
        return {best.x, best.y, best.z}
    end
    return {x, y, map:GetNearestFloor(x, y, 405)}
end

local function FindBestSpot(boss, cx, cy, minRadius, maxRadius, occupied, dynobjs, filter)
    local best, bestScore = nil, -1
    local angleCount = math.floor(360 / ANGLE_STEP)
    for radius = minRadius, maxRadius do
        for ai = 0, angleCount - 1 do
            local angle = ai * ANGLE_STEP * math.pi / 180
            local x = cx + math.cos(angle) * radius
            local y = cy + math.sin(angle) * radius
            if IsPosValid(x, y, dynobjs) and (not filter or filter(x, y)) then
                local score
                if #occupied == 0 then
                    score = radius
                else
                    score = math.huge
                    for _, p in ipairs(occupied) do
                        local d = math.sqrt((x - p.x) ^ 2 + (y - p.y) ^ 2)
                        if d < score then score = d end
                    end
                end
                if score > bestScore then
                    bestScore = score
                    best = {x, y, boss:GetMap():GetNearestFloor(x, y, 405)}
                end
            end
        end
    end
    return best
end

-- ============================================================
-- Role positions
-- ============================================================

local function GetHealerPos(healer, occupied, dynobjs)
    local locked = healer:Data():Get("BQHealerPos")
    if locked and IsPosValid(locked[1], locked[2], dynobjs) then
        return locked
    end
    local pos = FindBestSpot(boss, CENTER[1], CENTER[2], HEALER_RADIUS, HEALER_RADIUS,
                             occupied, dynobjs)
    pos = pos or {CENTER[1], CENTER[2], boss:GetMap():GetNearestFloor(CENTER[1], CENTER[2], 405)}
    healer:Data():Set("BQHealerPos", pos)
    return pos
end

local function IsBehindBoss(boss, x, y)
    local bo = boss:GetO()
    return (x - boss:GetX()) * math.cos(bo) + (y - boss:GetY()) * math.sin(bo) <= 0
end

local function GetMeleePos(boss, occupied, dynobjs)
    return FindBestSpot(boss, boss:GetX(), boss:GetY(), 1, 10, occupied, dynobjs,
                        function(x, y) return IsBehindBoss(boss, x, y) end)
end

local function GetRangedPos(boss, occupied, healerPositions, dynobjs)
    local bx, by = boss:GetX(), boss:GetY()
    return FindBestSpot(boss, bx, by, RANGED_RADIUS, RANGED_RADIUS, occupied, dynobjs,
                        function(x, y)
        if boss:GetExactDistance2d(x, y) > RANGED_LIMIT then return false end
        for _, hp in ipairs(healerPositions) do
            if math.sqrt((x - hp[1]) ^ 2 + (y - hp[2]) ^ 2) <= RANGED_LIMIT then
                return true
            end
        end
        return false
    end)
end

local function GetAirPos(occupied, dynobjs)
    return FindBestSpot(boss, CENTER[1], CENTER[2], AIR_RADIUS, AIR_RADIUS, occupied, dynobjs)
end

-- ============================================================
-- Swarming Shadows trail
-- ============================================================

local function BuildSwarmPath(bot, dynobjs)
    local a0 = math.atan2(bot:GetY() - CENTER[2], bot:GetX() - CENTER[1])
    local step = 5 / ROOM_RADIUS

    local function Score(dir)
        local midA = a0 + dir * step * 4
        local mx = CENTER[1] + math.cos(midA) * ROOM_RADIUS
        local my = CENTER[2] + math.sin(midA) * ROOM_RADIUS
        local minD = math.huge
        for _, d in ipairs(dynobjs) do
            local dd = d:GetExactDistance2d(mx, my)
            if dd < minD then minD = dd end
        end
        return minD
    end

    local dir = (Score(-1) > Score(1)) and -1 or 1
    local path = {}
    for i = 0, 8 do
        local a = a0 + dir * step * i
        local x = CENTER[1] + math.cos(a) * ROOM_RADIUS
        local y = CENTER[2] + math.sin(a) * ROOM_RADIUS
        table.insert(path, {x, y, bot:GetMap():GetNearestFloor(x, y, 405)})
    end
    bot:Data():Set("BQSwarmPath", path)
    bot:Data():Set("BQSwarmIndex", 1)
    return path
end

local function GetSwarmWaypoint(bot, dynobjs)
    local path = bot:Data():Get("BQSwarmPath")
    local index = bot:Data():Get("BQSwarmIndex") or 1
    if not path or index > #path then
        path = BuildSwarmPath(bot, dynobjs)
        index = 1
    end
    local wp = path[index]
    if bot:GetExactDistance2d(wp[1], wp[2]) <= 2.5 then
        index = index + 1
        bot:Data():Set("BQSwarmIndex", index)
        wp = path[index] or wp
    end
    return wp
end

-- ============================================================
-- Bite
-- ============================================================

local function IsBiteable(p, bot)
    return not (p == bot) and p:IsAlive()
        and not p:HasAura(SPELL_ESSENCE_OF_BLOOD_QUEEN)
        and not p:HasAura(SPELL_ESSENCE_OF_THE_BLOOD_QUEEN_PLR)
        and not p:HasAura(SPELL_FRENZIED_BLOODTHIRST)
end

local function GetBiteTarget(bot, allPlayers)
    local melee, meleeHp = nil, -1
    local near, nearDist = nil, math.huge
    local tank, tankDist = nil, math.huge
    for _, p in ipairs(allPlayers) do
        if IsBiteable(p, bot) then
            local d = bot:GetExactDistance2d(p)
            if IsTank(p) or p:HasHealSpec() then
                -- Tank or healer: kept as closest, only used when no DPS is left.
                if d < tankDist then
                    tankDist = d
                    tank = p
                end
            else
                -- DPS in melee range: kept as highest HP.
                if bot:IsWithinDist2d(p, 5) then
                    local hp = p:GetHealth()
                    if hp > meleeHp then
                        meleeHp = hp
                        melee = p
                    end
                end
                -- DPS anywhere: kept as closest.
                if d < nearDist then
                    nearDist = d
                    near = p
                end
            end
        end
    end
    -- Priority: melee-range DPS, then closest DPS, then closest healer/tank.
    return melee or near or tank
end

-- ============================================================
-- Pact of the Darkfallen
-- ============================================================

local function GetPactMidpoint(boss, allPlayers)
    local linked, sx, sy = 0, 0, 0
    for _, p in ipairs(allPlayers) do
        if p:IsAlive() and p:HasAura(SPELL_PACT_OF_THE_DARKFALLEN) then
            linked = linked + 1
            sx = sx + p:GetX()
            sy = sy + p:GetY()
        end
    end
    if linked == 0 then return nil end
    return {sx / linked, sy / linked,
            boss:GetMap():GetNearestFloor(sx / linked, sy / linked, 405)}
end

-- ============================================================
-- Tanks
-- ============================================================

local function GetSafeTankGround(boss, dynobjs)
    local pushFrom, pushDist = nil, math.huge
    for _, d in ipairs(dynobjs) do
        local tankDist = d:GetExactDistance2d(TANK_GROUND[1], TANK_GROUND[2])
        if tankDist < 5 and tankDist < pushDist then
            pushDist = tankDist
            pushFrom = d
        end
        if boss:GetExactDistance2d(d) < 10 then
            pushFrom = d
            break
        end
    end
    if not pushFrom then
        return GetSafePos(boss, TANK_GROUND[1], TANK_GROUND[2], 15, dynobjs)
    end
    local dx = TANK_GROUND[1] - pushFrom:GetX()
    local dy = TANK_GROUND[2] - pushFrom:GetY()
    local d = math.sqrt(dx * dx + dy * dy)
    if d < 0.01 then dx, dy, d = 1, 0, 1 end
    local x = pushFrom:GetX() + dx / d * 12
    local y = pushFrom:GetY() + dy / d * 12
    local ox, oy = x - TANK_GROUND[1], y - TANK_GROUND[2]
    local od = math.sqrt(ox * ox + oy * oy)
    if od > 10 then
        x = TANK_GROUND[1] + ox / od * 10
        y = TANK_GROUND[2] + oy / od * 10
    end
    return GetSafePos(boss, x, y, 15, dynobjs)
end

local function GetTankDesired(boss, botTanks, mainTank, offTank, inPull, dynobjs)
    local desired = {}
    local function Move(tank, x, y)
        if math.sqrt((tank:GetX() - x) ^ 2 + (tank:GetY() - y) ^ 2) > 3 then
            desired[tostring(tank:GetGUID())] = {x, y, boss:GetMap():GetNearestFloor(x, y, 405)}
        end
    end

    if inPull then
        if mainTank and mainTank:IsBot() then Taunt(mainTank, boss, true) end
        if boss:GetExactDistance2d(CENTER[1], CENTER[2]) > 7 then
            for _, tank in ipairs(botTanks) do Move(tank, CENTER[1], CENTER[2]) end
        else
            local ground = GetSafeTankGround(boss, dynobjs)
            for _, tank in ipairs(botTanks) do Move(tank, ground[1], ground[2]) end
        end
        return desired
    end

    if mainTank and mainTank:IsBot() then
        local ground = GetSafeTankGround(boss, dynobjs)
        for _, tank in ipairs(botTanks) do Move(tank, ground[1], ground[2]) end
    elseif mainTank and offTank and offTank:IsBot() then
        desired[tostring(offTank:GetGUID())] =
            {mainTank:GetX(), mainTank:GetY(), mainTank:GetZ()}
    end
    return desired
end

-- ============================================================
-- Movement
-- ============================================================

local function MoveBot(boss, bot, pos, tolerance, dynobjs)
    local x, y = ClampToRoom(pos[1], pos[2])
    local safe = GetSafePos(boss, x, y, 15, dynobjs)
    if not safe then return end
    if not IsAtPos(bot, safe[1], safe[2], tolerance) then
        MoveImmediately(bot, safe[1], safe[2], safe[3])
    end
end

-- ============================================================
-- Aura reactions
-- ============================================================

local function OnSwarmingShadowsApply(event, unit, aura)
    if not unit:IsBot() then return end
    ApplyDamageReductionStacks(unit, 60, 15000)
    unit:SetSpeed(1, 1.0)
    unit:Data():Set("BQSwarmPath", nil)
    unit:Data():Set("BQSwarmIndex", nil)
end
RegisterAuraEvent(SPELL_SWARMING_SHADOWS, 1, OnSwarmingShadowsApply)

local function OnSwarmingShadowsRemove(event, unit, aura, mode)
    if not unit:IsBot() then return end
    unit:Data():Set("BQSwarmPath", nil)
    unit:Data():Set("BQSwarmIndex", nil)
end
RegisterAuraEvent(SPELL_SWARMING_SHADOWS, 2, OnSwarmingShadowsRemove)

local function OnInciteTerrorApply(event, unit, aura)
    if not unit:IsBot() then return end
    if unit:GetRace() == RACE_HUMAN
        and not unit:HasSpellCooldown(SPELL_EVERY_MAN_FOR_HIMSELF) then
        unit:CastSpell(unit, SPELL_EVERY_MAN_FOR_HIMSELF, false)
    end
    if unit:GetClass() == CLASS_SHAMAN then
        unit:CastSpell(unit, SPELL_TREMOR_TOTEM, false)
    end
end
RegisterAuraEvent(SPELL_INCITE_TERROR, 1, OnInciteTerrorApply)

local AIR_PHASE_INTERVAL         = 124000

local function PrepareAirPhase(boss)
    local map = boss:GetMap()
    local bots = {}
    for _, p in ipairs(map and map:GetPlayers() or {}) do
        if p:IsBot() and p:IsAlive() and p:IsInCombat() and InRoom(p) then
            table.insert(bots, p)
        end
    end

    local swarmTarget = nil
    for _, bot in ipairs(bots) do
        if bot:HasAura(SPELL_SWARMING_SHADOWS) then
            swarmTarget = bot
            break
        end
    end

    if swarmTarget then
        for _, bot in ipairs(bots) do
            if bot:GetClass() == CLASS_PRIEST
                and not bot:HasSpellCooldown(SPELL_FEAR_WARD) then
                bot:CastSpell(swarmTarget, SPELL_FEAR_WARD, false)
                break
            end
        end
    end

    local priests = {}
    for _, bot in ipairs(bots) do
        if bot:GetClass() == CLASS_PRIEST then
            table.insert(priests, bot)
        end
    end
    if #priests > 0 then
        local caster = priests[math.random(#priests)]
        caster:CastSpellAoF(CENTER[1], CENTER[2], CENTER[3],
                            SPELL_MASS_DISPEL, true)
    end
end

-- ============================================================
-- Main loop
-- ============================================================

local function CleanupBQ(boss)
    local map = boss:GetMap()
    for _, p in ipairs(map and map:GetPlayers() or {}) do
        local shadow = p:ToShadow()
        if shadow then
            shadow:ClearMovementSuppression()
            shadow:ToggleCombatStrategy("+icc")
            p:Data():Set("BQHealerPos", nil)
            p:Data():Set("BQSwarmPath", nil)
            p:Data():Set("BQSwarmIndex", nil)
        end
    end
    boss:Data():Set("BQCombatStart", nil)
    boss:Data():Set("BQAirPrep", nil)
end

local function BQLoop(eventId, delay, repeats, boss)
    if boss:IsDead() or not boss:IsInCombat() then
        CleanupBQ(boss)
        StopLuaEvent(boss)
        return
    end

    local dynobjs = boss:GetDynamicObjectsInRange(100, SWARMING_SHADOWS_DYNOBJ)
    UpdateMesh(boss, dynobjs)

    local allPlayers = {}
    for _, p in ipairs(boss:GetPlayersInRange(100)) do
        if InRoom(p) then table.insert(allPlayers, p) end
    end
    local bots = {}
    for _, p in ipairs(allPlayers) do
        if p:IsAlive() and p:IsInCombat() and p:IsBot() then
            table.insert(bots, p)
        end
    end
    if #bots == 0 then
        CleanupBQ(boss)
        StopLuaEvent(boss)
        return
    end

    local now = os.time()
    local combatStart = boss:Data():Get("BQCombatStart") or now
    boss:Data():Set("BQCombatStart", combatStart)
    local inPull = (now - combatStart) < PULL_DURATION
    local airPhase = boss:HasAura(SPELL_INCITE_TERROR)

    local combatTime = (boss:Data():Get("CombatTime") or 0) + 200
    boss:Data():Set("CombatTime", combatTime)

    if not airPhase and combatTime >= AIR_PHASE_INTERVAL - 2000 then
        if not boss:Data():Get("BQAirPrep") then
            boss:Data():Set("BQAirPrep", true)
            PrepareAirPhase(boss)
        end
    elseif airPhase or combatTime < AIR_PHASE_INTERVAL - 2000 then
        boss:Data():Set("BQAirPrep", nil)
    end

    local mainTank, offTank = IdentifyTanks(boss)

    local botTanks, botHealers, botMelee, botRanged = {}, {}, {}, {}
    for _, bot in ipairs(bots) do
        if IsTank(bot) then
            table.insert(botTanks, bot)
        elseif bot:HasHealSpec() then
            table.insert(botHealers, bot)
        elseif bot:HasMeleeSpec() then
            table.insert(botMelee, bot)
        else
            table.insert(botRanged, bot)
        end
    end
    local function SortByName(a, b) return a:GetName() < b:GetName() end
    table.sort(botTanks, SortByName)
    table.sort(botHealers, SortByName)
    table.sort(botMelee, SortByName)
    table.sort(botRanged, SortByName)

    -- Pull threat
    if inPull and not boss:Data():Get("BQPullThreatApplied") then
        if mainTank then boss:AddThreat(mainTank, 10000) end
        if offTank and offTank:IsBot() then boss:AddThreat(offTank, 8000) end
        boss:Data():Set("BQPullThreatApplied", true)
    end

    -- Healer locked positions
    local healerSet = {}
    for _, h in ipairs(botHealers) do
        healerSet[tostring(h:GetGUID())] = true
    end
    local healerOccupied = {}
    for _, p in ipairs(allPlayers) do
        if p:IsAlive() and not healerSet[tostring(p:GetGUID())] then
            table.insert(healerOccupied, {x = p:GetX(), y = p:GetY()})
        end
    end

    local healerPos, healerPositions = {}, {}
    for _, healer in ipairs(botHealers) do
        local pos = GetHealerPos(healer, healerOccupied, dynobjs)
        healerPos[tostring(healer:GetGUID())] = pos
        table.insert(healerPositions, pos)
    end

    -- Melee spread behind the boss
    local meleePos = {}
    if #botMelee > 0 then
        local meleeSet = {}
        for _, m in ipairs(botMelee) do
            meleeSet[tostring(m:GetGUID())] = true
        end
        local occupied = {}
        for _, p in ipairs(allPlayers) do
            if p:IsAlive() and not meleeSet[tostring(p:GetGUID())] then
                table.insert(occupied, {x = p:GetX(), y = p:GetY()})
            end
        end
        for _, m in ipairs(botMelee) do
            local pos = GetMeleePos(boss, occupied, dynobjs)
            if pos then
                meleePos[tostring(m:GetGUID())] = pos
                table.insert(occupied, {x = pos[1], y = pos[2]})
            end
        end
    end

    -- Ranged spread around the boss
    local rangedPos = {}
    if #botRanged > 0 then
        local rangedSet = {}
        for _, r in ipairs(botRanged) do
            rangedSet[tostring(r:GetGUID())] = true
        end
        local occupied = {}
        for _, p in ipairs(allPlayers) do
            if p:IsAlive() and not rangedSet[tostring(p:GetGUID())] then
                table.insert(occupied, {x = p:GetX(), y = p:GetY()})
            end
        end
        for _, r in ipairs(botRanged) do
            local pos = GetRangedPos(boss, occupied, healerPositions, dynobjs)
            if pos then
                rangedPos[tostring(r:GetGUID())] = pos
                table.insert(occupied, {x = pos[1], y = pos[2]})
            end
        end
    end

    -- Air-phase spread up to 25 yds from center
    local airPos = {}
    if airPhase then
        local occupied = {}
        for _, p in ipairs(allPlayers) do
            if p:IsAlive() then
                table.insert(occupied, {x = p:GetX(), y = p:GetY()})
            end
        end
        for _, bot in ipairs(bots) do
            if not bot:HasHealSpec() then
                local pos = GetAirPos(occupied, dynobjs)
                if pos then
                    airPos[tostring(bot:GetGUID())] = pos
                    table.insert(occupied, {x = pos[1], y = pos[2]})
                end
            end
        end
    end

    local tankDesired = airPhase and {}
        or GetTankDesired(boss, botTanks, mainTank, offTank, inPull, dynobjs)

    local pactMid = GetPactMidpoint(boss, allPlayers)

    for _, bot in ipairs(bots) do
        local guidKey = tostring(bot:GetGUID())

        if not bot:IsMovementSuppressed() then
            shadow:SuppressMovement(SUPPRESS_MS)
        end

        local isSwarmer = bot:HasAura(SPELL_SWARMING_SHADOWS)
        local isPact = bot:HasAura(SPELL_PACT_OF_THE_DARKFALLEN)
        local isBloodthirst = bot:HasAura(SPELL_FRENZIED_BLOODTHIRST)
        local desired = nil

        if isSwarmer then
            local wp = GetSwarmWaypoint(bot, dynobjs)
            bot:MoveTo(1, wp[1], wp[2], wp[3], true)
        end

        if not isSwarmer and isPact and pactMid
            and bot:GetExactDistance2d(pactMid[1], pactMid[2]) > 2 then
            desired = pactMid
        end

        if not isSwarmer and not isPact and isBloodthirst then
            local target = GetBiteTarget(bot, allPlayers)
            if target then
                if bot:GetExactDistance2d(target) <= 5 then
                    bot:SetFacingToObject(target)
                    bot:CastSpell(target, SPELL_VAMPIRIC_BITE, false)
                else
                    local tx, ty = target:GetX(), target:GetY()
                    local dx, dy = bot:GetX() - tx, bot:GetY() - ty
                    local d = math.sqrt(dx * dx + dy * dy)
                    if d < 0.01 then dx, dy, d = 1, 0, 1 end
                    desired = {tx + dx / d * 3, ty + dy / d * 3}
                end
            end
        end

        if not isSwarmer and not isPact and not isBloodthirst then
            if airPhase then
                if bot:HasHealSpec() then
                    desired = healerPos[guidKey]
                else
                    desired = airPos[guidKey]
                end
            elseif IsTank(bot) then
                desired = tankDesired[guidKey]
            elseif bot:HasHealSpec() then
                desired = healerPos[guidKey]
            elseif bot:HasMeleeSpec() then
                desired = meleePos[guidKey]
            else
                desired = rangedPos[guidKey]
            end
        end

        if desired then
            MoveBot(boss, bot, desired, 2.5, dynobjs)
        end
    end

    boss:RegisterEvent(BQLoop, 200, 1)
end

-- ============================================================
-- Events
-- ============================================================

local function BQOnEnterCombat(event, player, boss)
    if not boss or not (boss:GetEntry() == BLOOD_QUEEN_ENTRY) then return end

    local shadow = player:ToShadow()
    if shadow then
        shadow:SuppressMovement(SUPPRESS_MS)
        shadow:ToggleCombatStrategy("-icc")
    end

    if player:GetDifficulty() > 1 then
        ApplyHiddenBuffsToShadows(player)
    end

    if boss:Data():Get("EventActive") == true then return end

    BuildBaseMesh(boss)
    local map = boss:GetMap()
    for _, p in ipairs(map and map:GetPlayers() or {}) do
        if p:IsBot() then
            p:Data():Set("BQHealerPos", nil)
            p:Data():Set("BQSwarmPath", nil)
            p:Data():Set("BQSwarmIndex", nil)
        end
    end

    boss:Data():Set("BQCombatStart", os.time())
    boss:Data():Set("BQPullThreatApplied", nil)
    boss:Data():Set("BQAirPrep", nil)
    boss:Data():Set("BQMeshSignature", nil)

    StartLuaEvent(boss, BQLoop)
end
RegisterPlayerEvent(33, BQOnEnterCombat)

local function BQOnLeaveCombat(event, player)
    if not (player:GetMapId() == 631) then return end
    local shadow = player:ToShadow()
    if shadow then
        shadow:ClearMovementSuppression()
        shadow:ToggleCombatStrategy("+icc")
    end
end
RegisterPlayerEvent(34, BQOnLeaveCombat)
