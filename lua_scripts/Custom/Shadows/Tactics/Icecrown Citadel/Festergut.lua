if GetStateMapId() ~= 631 then return end

local FESTERGUT_ENTRY  = 36626
local GASTRIC_BLOAT    = {72214, 72219, 72231, 72551, 72552, 72553}
local SPORE_AURA_1     = 69278
local SPORE_AURA_2     = 69279
local SPORE_AURA_3     = 71221
local PUNGENT_BLIGHT   = {69195, 71219, 73031, 73032}
local MALLEABLE_GOO    = 72296
local tankPos            = {4269,                        3144,                       360.385}
local rangedStackPos10   = {4263,                        3119,                       360.385}
local rangedStackPos25_1 = {rangedStackPos10[1] + 10,    rangedStackPos10[2],        rangedStackPos10[3]}
local rangedStackPos25_2 = {rangedStackPos10[1] - 10,    rangedStackPos10[2],        rangedStackPos10[3]}
local rightLeg           = {4272,                        3130,                       360.385}
local leftLeg            = {4260,                        3135,                       360.385}
local festergutPos       = {4268,                        3137,                       360.59}
local GOO_AVOID_DIST     = 13
local SPREAD_MIN_DIST    = 13
local tickTimer          = 200
local HC_RECALC_INTERVAL = 3

-- ============================================================
-- Helpers
-- ============================================================

local function HasSpore(player)
    return player:HasAura(SPORE_AURA_1) or player:HasAura(SPORE_AURA_2) or player:HasAura(SPORE_AURA_3)
end

local function NearGoo(x, y, gooPos)
    if not gooPos then return false end
    local dx = x - gooPos[1]
    local dy = y - gooPos[2]
    return math.sqrt(dx*dx + dy*dy) < GOO_AVOID_DIST
end

local function PushFromGoo(pos, gooPos)
    if not gooPos then return {pos[1], pos[2], pos[3]} end
    local dx = pos[1] - gooPos[1]
    local dy = pos[2] - gooPos[2]
    local dist = math.sqrt(dx*dx + dy*dy)
    if dist >= GOO_AVOID_DIST then return {pos[1], pos[2], pos[3]} end
    if dist == 0 then dx, dy = 1, 0 else dx, dy = dx / dist, dy / dist end
    return {gooPos[1] + dx * (GOO_AVOID_DIST + 2), gooPos[2] + dy * (GOO_AVOID_DIST + 2), pos[3]}
end

local function GetBloatStacks(player)
    for _, spellId in ipairs(GASTRIC_BLOAT) do
        local aura = player:GetAura(spellId)
        if aura then
            return aura:GetStackAmount()
        end
    end
    return 0
end

local function TryRootAtPos(player, gooPos, duration)
    if not NearGoo(player:GetX(), player:GetY(), gooPos) then
        AddRootAura(player, duration)
    else
        player:RemoveAura(35340)
    end
end

-- ============================================================
-- Main Loop
-- ============================================================

local function FestergutLoop(eventId, delay, repeats, festergut)
    if festergut:IsDead() or not festergut:IsInCombat() then
        StopLuaEvent(festergut)
        return
    end

    local allPlayers = festergut:GetPlayersInRange(100)
    local bots       = {}

    for _, player in ipairs(allPlayers) do
        if player:IsAlive() and player:IsInCombat() and player:IsBot() then
            table.insert(bots, player)
        end
    end

    if #bots == 0 then
        StopLuaEvent(festergut)
        return
    end

    -- for _, bot in ipairs(bots) do DisableManualSpells(bot) end

    local gooX    = festergut:Data():Get("GooX")
    local gooY    = festergut:Data():Get("GooY")
    local gooZ    = festergut:Data():Get("GooZ")
    local gooTime = festergut:Data():Get("GooTime")
    local gooPos  = (gooX and gooY and gooZ and gooTime and (os.time() - gooTime < 10))
                    and {gooX, gooY, gooZ} or nil

    local sporePlayers = {}
    for _, player in ipairs(allPlayers) do
        if player:IsAlive() and HasSpore(player) then
            table.insert(sporePlayers, player)
        end
    end

    local anySporeActive  = #sporePlayers > 0
    local sporeDetectTime = festergut:Data():Get("SporeDetectTime")

    if anySporeActive then
        if not sporeDetectTime then
            festergut:Data():Set("SporeDetectTime", os.time())
            festergut:Data():Set("CachedSporeCount", #sporePlayers)
            festergut:Data():Set("SporeAssignmentDone", nil)
        end
    else
        if sporeDetectTime and (os.time() - sporeDetectTime > 10) then
            festergut:Data():Set("SporeDetectTime", nil)
            festergut:Data():Set("CachedSporeCount", nil)
            festergut:Data():Set("SporeAssignmentDone", nil)
            for _, bot in ipairs(bots) do
                bot:Data():Set("FestergutSpreadPos", nil)
            end
            festergut:Data():Set("LastHCReassignTime", nil)
        end
    end

    local wasSporeActive = festergut:Data():Get("WasSporeActive") or false
    if wasSporeActive and not anySporeActive then
        for _, bot in ipairs(bots) do
            bot:Data():Set("FestergutSpreadPos", nil)
        end
        festergut:Data():Set("LastHCReassignTime", nil)
    end
    festergut:Data():Set("WasSporeActive", anySporeActive)

    local cachedSporeCount = festergut:Data():Get("CachedSporeCount") or #sporePlayers

    local botTanks   = {}
    local botMelee   = {}
    local botHealers = {}
    local botCasters = {}

    for _, bot in ipairs(bots) do
        if bot:HasTankSpec() then
            table.insert(botTanks, bot)
        elseif bot:HasMeleeSpec() then
            table.insert(botMelee, bot)
        elseif bot:HasHealSpec() then
            table.insert(botHealers, bot)
        else
            table.insert(botCasters, bot)
        end
    end

    FestergutHandleTanks(festergut, botTanks, gooPos)

    if anySporeActive then
        FestergutHandleSpore(festergut, bots, sporePlayers, cachedSporeCount, gooPos)
    else
        FestergutHandleMelee(festergut, botMelee, gooPos)
        FestergutHandleHealersCasters(festergut, botHealers, botCasters, botTanks, allPlayers, gooPos)
    end

    festergut:RegisterEvent(FestergutLoop, tickTimer, 1)
end

-- ============================================================
-- Tank Handler
-- ============================================================

function FestergutHandleTanks(festergut, botTanks, gooPos)
    if #botTanks == 0 then return end

    local victim = festergut:GetVictim()
    if victim and victim:IsPlayer() and IsAtPos(victim, tankPos[1], tankPos[2], 5) then
        if not IsAtPos(festergut, festergutPos[1], festergutPos[2], 5) then
            festergut:MoveTo(1, festergutPos[1], festergutPos[2], festergutPos[3], true)
        end
    end

    local safeTankPos = tankPos
    if gooPos and NearGoo(tankPos[1], tankPos[2], gooPos) then
        local rightSafe = not NearGoo(rightLeg[1], rightLeg[2], gooPos)
        local leftSafe  = not NearGoo(leftLeg[1],  leftLeg[2],  gooPos)
        if rightSafe then
            safeTankPos = rightLeg
        elseif leftSafe then
            safeTankPos = leftLeg
        else
            safeTankPos = PushFromGoo(tankPos, gooPos)
        end
    end

    local mainTank, offTank = IdentifyTanks(festergut)

    local activeTank  = mainTank
    local passiveTank = offTank

    if mainTank and GetBloatStacks(mainTank) >= 6 then
        activeTank  = offTank
        passiveTank = mainTank
    elseif offTank and GetBloatStacks(offTank) >= 6 then
        activeTank  = mainTank
        passiveTank = offTank
    end

    for _, tank in ipairs(botTanks) do
        ApplyDamageReductionStacks(tank, (20 + tank:GetDifficulty()*15), 30000)
        if safeTankPos then
            if not IsAtPos(tank, safeTankPos[1], safeTankPos[2], 5) then
                local tx, ty, tz = tank:GetLocation()
                MoveImmediately(tank, safeTankPos[1], safeTankPos[2], safeTankPos[3])
            else
                TryRootAtPos(tank, gooPos, 2000)
            end
        else
            UseDefensive(tank)
        end

        if tank == activeTank then
            local v = festergut:GetVictim()
            if v and v ~= tank then
                festergut:AddThreat(tank, 10000 + math.random(-500, 500))
                Taunt(tank, festergut, true)
            end
        elseif tank == passiveTank then
            UseDefensive(tank)
        end
    end
end

-- ============================================================
-- Spore Handler
-- ============================================================

function FestergutHandleSpore(festergut, bots, sporePlayers, cachedSporeCount, gooPos)
    local rawPositions = {}
    if cachedSporeCount == 1 then
        rawPositions = {tankPos}
    elseif cachedSporeCount == 2 then
        rawPositions = {tankPos, rangedStackPos10}
    elseif cachedSporeCount >= 3 then
        rawPositions = {tankPos, rangedStackPos25_1, rangedStackPos25_2}
    else
        return
    end

    local sporePositions = {}
    for _, pos in ipairs(rawPositions) do
        table.insert(sporePositions, PushFromGoo(pos, gooPos))
    end

    if not festergut:Data():Get("SporeAssignmentDone") then
        local victim = festergut:GetVictim()

        local victimSpore = nil
        local tankSpores  = {}
        local otherSpores = {}

        for _, sp in ipairs(sporePlayers) do
            if victim and sp == victim then
                victimSpore = sp
            elseif sp:HasTankSpec() then
                table.insert(tankSpores, sp)
            else
                table.insert(otherSpores, sp)
            end
        end

        local priorityPos1 = {}
        if victimSpore then table.insert(priorityPos1, victimSpore) end
        for _, sp in ipairs(tankSpores)  do table.insert(priorityPos1, sp) end
        for _, sp in ipairs(otherSpores) do table.insert(priorityPos1, sp) end

        local assignedNames = {}

        local pos1Player = priorityPos1[1]
        if pos1Player then
            festergut:Data():Set("SporeAssigned1", pos1Player:GetName())
            assignedNames[pos1Player:GetName()] = true
        end

        local remaining = {}
        for _, sp in ipairs(sporePlayers) do
            if not assignedNames[sp:GetName()] then
                table.insert(remaining, sp)
            end
        end

        if #sporePositions >= 2 and #remaining >= 1 then
            if #sporePositions == 2 or #remaining == 1 then
                festergut:Data():Set("SporeAssigned2", remaining[1]:GetName())
            elseif #remaining >= 2 then
                local r1, r2 = remaining[1], remaining[2]
                local p2, p3 = sporePositions[2], sporePositions[3]
                local distA  = r1:GetDistance2d(p2[1], p2[2]) + r2:GetDistance2d(p3[1], p3[2])
                local distB  = r1:GetDistance2d(p3[1], p3[2]) + r2:GetDistance2d(p2[1], p2[2])
                if distA <= distB then
                    festergut:Data():Set("SporeAssigned2", r1:GetName())
                    festergut:Data():Set("SporeAssigned3", r2:GetName())
                else
                    festergut:Data():Set("SporeAssigned2", r2:GetName())
                    festergut:Data():Set("SporeAssigned3", r1:GetName())
                end
            end
        end

        festergut:Data():Set("SporePositionCount", #sporePositions)
        festergut:Data():Set("SporeAssignmentDone", true)
    end

    local posCount = festergut:Data():Get("SporePositionCount") or #sporePositions

    for i = 1, posCount do
        local assignedName = festergut:Data():Get("SporeAssigned" .. i)
        if assignedName and sporePositions[i] then
            for _, sp in ipairs(sporePlayers) do
                if sp:GetName() == assignedName and sp:IsBot() then
                    local tp = sporePositions[i]
                    if not IsAtPos(sp, tp[1], tp[2], 3) then
                        MoveImmediately(sp, tp[1], tp[2], tp[3])
                    else
                        TryRootAtPos(sp, gooPos, 2000)
                    end
                    break
                end
            end
        end
    end

    for _, bot in ipairs(bots) do
        if not bot:HasTankSpec() and not HasSpore(bot) then
            local closestPos  = nil
            local closestDist = math.huge

            for _, sp in ipairs(sporePositions) do
                local d = bot:GetDistance2d(sp[1], sp[2])
                if d < closestDist then closestDist = d; closestPos = sp end
            end

            if closestPos then
                local offsetX = math.random(-2, 2)
                local offsetY = math.random(-2, 2)
                if not IsAtPos(bot, closestPos[1] + offsetX, closestPos[2] + offsetY, 3) then
                    MoveImmediately(bot, closestPos[1] + offsetX, closestPos[2] + offsetY, closestPos[3])
                else
                    TryRootAtPos(bot, gooPos, 2000)
                end
            end
        end
    end
end

-- ============================================================
-- Melee Handler
-- ============================================================

function FestergutHandleMelee(festergut, botMelee, gooPos)
    if #botMelee == 0 then return end

    local atPos = IsAtPos(festergut, festergutPos[1], festergutPos[2], 7)

    for _, player in ipairs(botMelee) do
        local target = rightLeg

        if atPos then
            if gooPos then
                local rightNearGoo = NearGoo(rightLeg[1], rightLeg[2], gooPos)
                local leftNearGoo  = NearGoo(leftLeg[1],  leftLeg[2],  gooPos)
                if rightNearGoo and not leftNearGoo then
                    target = leftLeg
                elseif rightNearGoo and leftNearGoo then
                    target = tankPos
                end
            end
        else
            target = tankPos
        end

        local offsetX = math.random(-2, 2)
        local offsetY = math.random(-2, 2)
        if not IsAtPos(player, target[1], target[2], 3) then
            player:MoveTo(1, target[1] + offsetX, target[2] + offsetY, target[3], true)
        else
            TryRootAtPos(player, gooPos, 2000)
        end
    end
end

-- ============================================================
-- Healer / Caster Handler
-- ============================================================

local function RecalcHCPositions(festergut, botHealers, botCasters, botTanks, allPlayers, gooPos)
    local fx, fy, fz = festergut:GetLocation()

    local isHCBot = {}
    for _, h in ipairs(botHealers) do isHCBot[h:GetName()] = true end
    for _, c in ipairs(botCasters) do isHCBot[c:GetName()] = true end

    local occupied = {}
    for _, player in ipairs(allPlayers) do
        if player:IsAlive() and not isHCBot[player:GetName()] then
            local ox, oy = player:GetLocation()
            table.insert(occupied, {x = ox, y = oy})
        end
    end

    local tankAnchorX, tankAnchorY = fx, fy
    if #botTanks > 0 then
        tankAnchorX = botTanks[1]:GetX()
        tankAnchorY = botTanks[1]:GetY()
    end

    local healerPositions = {}

    for _, player in ipairs(botHealers) do
        local bestPos, bestDist = nil, math.huge

        for radius = 15, 40, 5 do
            for angle = 0, 345, 15 do
                local rad   = math.rad(angle)
                local testX = tankAnchorX + radius * math.cos(rad)
                local testY = tankAnchorY + radius * math.sin(rad)
                local valid = true

                if NearGoo(testX, testY, gooPos) then valid = false end

                if valid then
                    for _, op in ipairs(occupied) do
                        local dx = testX - op.x
                        local dy = testY - op.y
                        if math.sqrt(dx*dx + dy*dy) < SPREAD_MIN_DIST then valid = false; break end
                    end
                end

                if valid then
                    local dist = player:GetDistance2d(testX, testY)
                    if dist < bestDist then
                        bestDist = dist
                        bestPos  = {x = testX, y = testY, z = fz}
                    end
                end
            end
        end

        if bestPos then
            player:Data():Set("FestergutSpreadPos", bestPos)
            table.insert(occupied,       {x = bestPos.x, y = bestPos.y})
            table.insert(healerPositions, bestPos)
        end
    end

    for _, player in ipairs(botCasters) do
        local bestPos, bestDist = nil, math.huge

        local function TryFindCasterPos(requireHealer)
            for radius = 10, 30, 5 do
                for angle = 0, 345, 15 do
                    local rad   = math.rad(angle)
                    local testX = fx + radius * math.cos(rad)
                    local testY = fy + radius * math.sin(rad)
                    local valid = true

                    if NearGoo(testX, testY, gooPos) then valid = false end

                    if valid and requireHealer and #healerPositions > 0 then
                        local nearHealer = false
                        for _, hp in ipairs(healerPositions) do
                            local dx = testX - hp.x
                            local dy = testY - hp.y
                            if math.sqrt(dx*dx + dy*dy) <= 40 then nearHealer = true; break end
                        end
                        if not nearHealer then valid = false end
                    end

                    if valid then
                        for _, op in ipairs(occupied) do
                            local dx = testX - op.x
                            local dy = testY - op.y
                            if math.sqrt(dx*dx + dy*dy) < SPREAD_MIN_DIST then valid = false; break end
                        end
                    end

                    if valid then
                        local dist = player:GetDistance2d(testX, testY)
                        if dist < bestDist then
                            bestDist = dist
                            bestPos  = {x = testX, y = testY, z = fz}
                        end
                    end
                end
            end
        end

        TryFindCasterPos(true)
        if not bestPos then
            TryFindCasterPos(false)
        end

        if bestPos then
            player:Data():Set("FestergutSpreadPos", bestPos)
            table.insert(occupied, {x = bestPos.x, y = bestPos.y})
        end
    end
end

function FestergutHandleHealersCasters(festergut, botHealers, botCasters, botTanks, allPlayers, gooPos)
    if #botHealers == 0 and #botCasters == 0 then return end

    local now        = os.time()
    local lastRecalc = festergut:Data():Get("LastHCReassignTime") or 0
    local forceRecalc = false

    if not forceRecalc then
        for _, player in ipairs(botHealers) do
            local pos = player:Data():Get("FestergutSpreadPos")
            if pos then pos = pos:AsTable() end
            if not pos or (gooPos and NearGoo(pos.x, pos.y, gooPos)) then
                forceRecalc = true; break
            end
        end
    end

    if not forceRecalc then
        for _, player in ipairs(botCasters) do
            local pos = player:Data():Get("FestergutSpreadPos")
            if pos then pos = pos:AsTable() end
            if not pos or (gooPos and NearGoo(pos.x, pos.y, gooPos)) then
                forceRecalc = true; break
            end
        end
    end

    if forceRecalc or (now - lastRecalc) >= HC_RECALC_INTERVAL then
        RecalcHCPositions(festergut, botHealers, botCasters, botTanks, allPlayers, gooPos)
        festergut:Data():Set("LastHCReassignTime", now)
    end

    for _, player in ipairs(botHealers) do
        local pos = player:Data():Get("FestergutSpreadPos")
        if pos then pos = pos:AsTable() end
        if pos and not IsAtPos(player, pos.x, pos.y, 2) then
            MoveImmediately(player, pos.x, pos.y, pos.z)
        elseif pos then
            TryRootAtPos(player, gooPos, 2000)
        end
    end

    for _, player in ipairs(botCasters) do
        local pos = player:Data():Get("FestergutSpreadPos")
        if pos then pos = pos:AsTable() end
        if pos and not IsAtPos(player, pos.x, pos.y, 2) then
            MoveImmediately(player, pos.x, pos.y, pos.z)
        elseif pos then
            TryRootAtPos(player, gooPos, 2000)
        end
    end
end

-- ============================================================
-- Enter Combat
-- ============================================================

local function FestergutOnEnterCombat(event, festergut, target)
    if not festergut or festergut:GetEntry() ~= FESTERGUT_ENTRY then return end

    for _, player in ipairs(festergut:GetPlayersInRange(100)) do
        local shadow = player:ToShadow()
        if shadow then shadow:ToggleCombatStrategy("-icc") end
        if player:GetDifficulty() > 1 then ApplyHiddenBuffsToShadows(player) end
    end

    local players = festergut:GetPlayersInRange(100)
    for _, p in ipairs(players) do
        if p:IsBot() then
            p:Data():Set("FestergutSpreadPos", nil)
        end
    end
    festergut:Data():Set("CachedMainTank", nil)
    festergut:Data():Set("CachedOffTank", nil)
    festergut:Data():Set("LastAssignedMain", nil)
    festergut:Data():Set("LastAssignedOff", nil)
    festergut:Data():Set("SporeDetectTime", nil)
    festergut:Data():Set("CachedSporeCount", nil)
    festergut:Data():Set("SporeAssignmentDone", nil)
    festergut:Data():Set("WasSporeActive", nil)
    festergut:Data():Set("GooX", nil)
    festergut:Data():Set("GooY", nil)
    festergut:Data():Set("GooZ", nil)
    festergut:Data():Set("GooTime", nil)
    festergut:Data():Set("LastHCReassignTime", nil)
    StartLuaEvent(festergut, FestergutLoop)
end

RegisterCreatureEvent(FESTERGUT_ENTRY, 1, FestergutOnEnterCombat)

-- ============================================================
-- Spell Events
-- ============================================================

function OnPungentBlight(event, caster, spell)
    local players = caster:GetPlayersInRange(100)
    for _, player in ipairs(players) do
        if player:IsBot() then
            --print(player:GetName().." using defensive!")
            UseDefensive(player)
        end
    end
end

for _, spellId in ipairs(PUNGENT_BLIGHT) do
    RegisterSpellEvent(spellId, 1, OnPungentBlight)
end

function OnMalleableGooCast(event, caster, spell, skipCheck)
    local target = spell:GetTarget()
    local x, y, z = spell:GetTargetDest()

    if target then
        local festergut = target:GetNearestCreature(100, FESTERGUT_ENTRY, 0)
        if festergut then
            --print("[Festergut] Malleable Goo cast at: " .. x .. ", " .. y .. ", " .. z)
            festergut:Data():Set("GooX", x)
            festergut:Data():Set("GooY", y)
            festergut:Data():Set("GooZ", z)
            festergut:Data():Set("GooTime", os.time())
        end
    end
end

RegisterSpellEvent(MALLEABLE_GOO, 2, OnMalleableGooCast)