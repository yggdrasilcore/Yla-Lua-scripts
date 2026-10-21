if GetStateMapId() ~= 631 then return end

-- OBJECT IDs
-- Bosses
local MURADIN_ENTRY            = 36948
local SAURFANG_ENTRY           = 36939
-- Mages
local ALLY_FIGHT_MAGE_ENTRY    = 37117
local HORDE_FIGHT_MAGE_ENTRY   = 37116
-- Transport game objects
local OGRIM_ENTRY              = 37215
local SKYBREAKER_ENTRY         = 37540
-- Spells
local ROCKET_PACK_SPELL        = 68645
local ORGRIMS_HAMMER_DECK_AURA = 70121
-- Trash, misc.
local KORKRON_ENTRIES          = { 36957, 36960 }
local SKYBREAKERS_ENTRIES      = { 36950, 36961 }
local ZAFOD                    = 37184

-- TRANSPORTS
local OGRIMS_HAMMER = 201812
local SKYBREAKER    = 201811

-- Ally pos
local ALLY_SKYBREAKER_START_POS   = { x = -391, y = 2058, z = 466.6 }
local ALLY_OGRIM_TANK_JUMP        = { x = -368, y = 2022, z = 467.6 }
local ALLY_HEALER_POS             = { x = -387, y = 2047, z = 467.54 }
local ALLY_OGRIM_Y_LIMIT          = 2023
local ALLY_SKYBREAKER_Y_LIMIT     = 2041
local ALLY_SKYBREAKER_WALK_LIMIT  = 2045
local ALLY_Y_LIMIT                = 2100
local ALLY_SKYBREAKER_EDGE_Z      = 467.65
local ALLY_SKYBREAKER_DECK_Z      = 466.34
local ALLY_BAND_X_MIN             = -405
local ALLY_BAND_X_MAX             = -369
local ALLY_BAND_Y_MIN             = 2040
local ALLY_BAND_Y_MAX             = 2053
local JUMP_COOLDOWN               = 2

-- Horde pos
local HORDE_OGRIM_START_POS       = { x = -414.33, y = 2409.74, z = 472.41 }
local HORDE_SKYBREAKER_TANK_JUMP  = { x = -452.26, y = 2458.43, z = 470.15 }
local HORDE_HEALER_POS            = { x = -432.38, y = 2427.99, z = 472.25 }
local HORDE_SKYBREAKER_Y_LIMIT    = 2453
local HORDE_ORGIM_Y_LIMIT         = 2429
local HORDE_Y_LIMIT               = 2360
local HORDE_SKYBREAKER_JUMP_POS   = { x = -437.62, y = 2454.50, z = 470.60 }
local HORDE_OGRIM_JUMP_POS        = { x = -433.09, y = 2425.85, z = 471.73 }
local HORDE_OGRIM_TANK_POS        = { HORDE_OGRIM_START_POS.x, HORDE_OGRIM_START_POS.y - 10, HORDE_OGRIM_START_POS.z }
local HORDE_OGRIM_TANK_TRANSITION = { x = -436.86, y = 2426.79, z = 471.97 }
local HORDE_MIN_Z                 = 471.5
local HORDE_MAX_Z                 = 490
local HORDE_JUMP_EXEMPT           = 473

-- Helpers
local function GetCorrectedZ(x, y)
    if not x or not y then return nil end
    if x >= ALLY_BAND_X_MIN and x <= ALLY_BAND_X_MAX and y >= ALLY_BAND_Y_MIN and y <= ALLY_BAND_Y_MAX then
        return ALLY_SKYBREAKER_EDGE_Z
    elseif y > ALLY_BAND_Y_MAX then
        return ALLY_SKYBREAKER_DECK_Z
    end
    return nil
end

local function JumpCooldown(x1, y1, z1, x2, y2, z2)
    local dist = math.sqrt((x2-x1)^2 + (y2-y1)^2 + (z2-z1)^2)
    return dist / 5
end

local function HandleRocketPack(event, player)
    if not player then return end
    if event == 33 then -- Enter combat
        player:AddAura(69188, player)
    elseif event == 28 and player:HasAura(69188) then -- Change map
        player:RemoveAura(69188) 
    end
end

local function BuildThreat(tank, target)
    local class = tank:GetClass()
    if class == 6 then
        tank:CastSpell(target, 49909, true)
    elseif class == 11 then
        tank:CastSpell(target, 48564, true)
    elseif class == 2 then
        local last = tank:GetData("BuildThreatLast")
        if last == 61411 then
            tank:CastSpell(target, 53595, true)
            tank:SetData("BuildThreatLast", 53595)
        else
            tank:CastSpell(target, 61411, true)
            tank:SetData("BuildThreatLast", 61411)
        end
    elseif class == 1 then
        local last = tank:GetData("BuildThreatLast")
        if last == 47488 then
            tank:CastSpell(target, 47498, true)
            tank:SetData("BuildThreatLast", 47498)
        else
            tank:CastSpell(target, 47488, true)
            tank:SetData("BuildThreatLast", 47488)
        end
    end
end

local function GetMageChanneling(player)
    local mages = player:GetCreaturesInRange(200, ALLY_FIGHT_MAGE_ENTRY)
    for _, mage in ipairs(mages) do
        if mage:IsCasting() and IsAtPos(mage, -372, 1994, 3) then
            return mage
        end
    end
    return nil
end

local function RemovePassengerFromTransport(transport, player)
    if not transport or not player then return end
    local x, y, z, o = player:GetLocation()
    transport:RemovePassenger(player, true)
    player:RemoveMovementFlag(0x00000200)
    player:SendMovementFlagUpdate()
    player:NearTeleport(x, y, z, o)
end

local function AddPassengerToTransport(transport, player)
    if not transport or not player then return end
    local x, y, z, o = player:GetLocation()
    transport:AddPassenger(player, true)
    player:AddMovementFlag(0x00000200)
    player:SendMovementFlagUpdate()
    player:NearTeleport(x, y, z, o)
end

local function AddToEnemyTransport(player, enemy)
    if not enemy or not player then return end
    local transport = enemy:GetTransport()
    if not transport then return end
    local current = player:GetTransport()
    if current then
        if current == transport then return end
        print("[GunshipDebug] " .. player:GetName() .. " removing from existing transport "..current:GetName()..", ID: " .. tostring(current:GetGUIDLow()))
        RemovePassengerFromTransport(current, player)
    end
    AddPassengerToTransport(transport, player)
    local newTransport = player:GetTransport()
    if not newTransport then
        print("[GunshipDebug] " .. player:GetName() .. " failed to add transport Ogrim's Hammer ID " .. tostring(transport:GetGUIDLow()))
    end
end

local function AddToFactionTransport(player)
    if not player then return end
    local zafod = player:GetNearestCreature(200, ZAFOD)
    if not zafod then return end
    local transport = zafod:GetTransport()
    if not transport then return end
    local current = player:GetTransport()
    if current then
        if current == transport then return end
        print("[GunshipDebug] " .. player:GetName() .. " removing from existing transport "..current:GetName()..", ID: " .. tostring(current:GetGUIDLow()))
        RemovePassengerFromTransport(current, player)
    end
    AddPassengerToTransport(transport, player)
    if not player:GetTransport() then
        print("[GunshipDebug] " .. player:GetName() .. " has no transport after add to SKybreaker ID " .. tostring(transport:GetGUIDLow()))
    end
end

local function MarkTargetSkull(player, target)
    local tick = (player:GetData("GunshipMarkTick") or 0) + 1
    player:SetData("GunshipMarkTick", tick)

    if tick % 30 ~= 0 then return end

    if not target then return end

    if target:GetData("SkullSet") and (os.time() - (target:GetData("SkullSetTime") or 0)) < 6 then return end

    target:SetData("SkullSet", true)
    target:SetData("SkullSetTime", os.time())
    SetTargetIconDeferred(player, 7, target)
end

local function GunshipHordeActions(eventId, delay, repeats, player)
    if player:IsDead() or not player:IsInCombat() or not (player:GetMapId() == 631) then
        StopLuaEvent(player)
        return
    end

    if player:IsOnVehicle() then
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end

    local px, py, pz = player:GetLocation()
    local muradin = player:GetNearestCreature(200, MURADIN_ENTRY)

    -- Fight over
    local Skybreaker = player:GetNearestCreature(200, SKYBREAKER_ENTRY, 0, 0)
    if Skybreaker and (Skybreaker:IsDead() or Skybreaker:GetHealth() == 1) then
        player:NearTeleport(HORDE_OGRIM_START_POS.x, HORDE_OGRIM_START_POS.y, HORDE_OGRIM_START_POS.z, player:GetO())
        AddToFactionTransport(player)
        AddRootAura(player, 20000)
        HandleRocketPack(33, player)
        return
    end

    -- Outside of Ogrim's Hammer main deck? Correct pos.
    if (pz >= 400 and pz <= 469) or py < 2360 or py > 2500 then
        player:NearTeleport(HORDE_OGRIM_START_POS.x, HORDE_OGRIM_START_POS.y, HORDE_OGRIM_START_POS.z, player:GetO())
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end
    
    -- Z correction on Ogrim's Hammer deck
    local inOgrimRect = (px >= -438 and px <= -406) and (py >= 2365 and py <= 2429)
    if inOgrimRect then
        local minZ = px > -420 and 472 or 473
        if pz + 1 < minZ then
            player:NearTeleport(px, py, minZ, player:GetO())
        end
    end
    
    -- Floor Z misalignment? Correct.
    if py <= HORDE_ORGIM_Y_LIMIT and py >= HORDE_Y_LIMIT and (not player:IsMoving() or not player:IsCasting()) and pz > player:GetFloorZ() + 2 and player:GetFloorZ() > HORDE_MIN_Z and player:GetFloorZ() < HORDE_MAX_Z then
        player:NearTeleport(px, py, player:GetFloorZ(), player:GetO())
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end

    if pz > HORDE_JUMP_EXEMPT and (py >= HORDE_ORGIM_Y_LIMIT and py <= HORDE_SKYBREAKER_Y_LIMIT) then -- Don't queue multiple commands mid-air, let bot AI fix height bugs
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end

    local mage = nil
    local mages = player:GetCreaturesInRange(200, HORDE_FIGHT_MAGE_ENTRY)
    for _, m in ipairs(mages) do
        if m:IsCasting() and m:GetX() < 440 then
            mage = m
            break
        end
    end

    local mainTank, offTank = IdentifyTanks(muradin)

    local tick = (player:GetData("GunshipTick") or 0) + 1
    player:SetData("GunshipTick", tick)

    -- Ensure bots are added to correct transports
    if py > HORDE_SKYBREAKER_Y_LIMIT then
        AddToEnemyTransport(player, muradin)
    elseif py < HORDE_ORGIM_Y_LIMIT then
        AddToFactionTransport(player)
    else
        local current = player:GetTransport()
        if current then
            RemovePassengerFromTransport(current, player)
        end
    end

    -- Target prio mage, always
    if mage then MarkTargetSkull(player, mage) end
    
    -- Facing correction
    if player:GetSelection() then player:SetFacingToObject(player:GetSelection()) end

    -- Off tank: stay on Ogrim at HORDE_OGRIM_TANK_POS, cycle threat on Skybreaker boarders
    if IsTank(player) and offTank and offTank == player then
        local tx, ty = HORDE_OGRIM_TANK_POS[1], HORDE_OGRIM_TANK_POS[2]
        if IsAtPos(player, tx, ty, 2) then
            AddRootAura(player, 2000)
        else
            MoveImmediately(player, tx, ty, HORDE_OGRIM_TANK_POS[3])
        end
        local skullTarget = nil
        for _, entry in ipairs(SKYBREAKERS_ENTRIES) do
            local boarders = player:GetCreaturesInRange(40, entry)
            for _, boarder in ipairs(boarders) do
                player:AddThreat(boarder, 300)
                if (boarder:GetVictim() and boarder:GetVictim() ~= player) then
                    if not IsAtPos(boarder, px, py, 5) then
                        boarder:MoveTo(99, px - 3, py, pz, 0)
                        Taunt(player, boarder, false)
                    elseif boarder:GetVictim() and boarder:GetVictim():GetEntry() == SAURFANG_ENTRY then
                        -- Do nothing, let Saurfang tank
                    end
                end
                if tick % 10 == 0 then
                    player:SetFacingToObject(boarder)
                    BuildThreat(player, boarder)
                end
                if not skullTarget or boarder:GetGUIDLow() < skullTarget:GetGUIDLow() then
                    skullTarget = boarder
                end
            end
        end
        if skullTarget and not mage then MarkTargetSkull(player, skullTarget) end
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end

    -- Healers: pin to HORDE_HEALER_POS, root 5s on arrival
    if player:HasHealSpec() then
        local tx, ty = HORDE_HEALER_POS.x, HORDE_HEALER_POS.y
        if IsAtPos(player, tx, ty, 1) then
            AddRootAura(player, 5000)
        else
            MoveImmediately(player, tx + math.random(-1, 1), ty + math.random(-1, 1), HORDE_HEALER_POS.z)
        end
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end

    -- DPS: free roam on Ogrim deck if no mage
    if not mage and py <= 2422 and not (IsTank(player) and mainTank and mainTank == player) then
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end

    -- DPS and main tank: route back to start if drifted into Ogrim edge zone and no mage
    if not mage and py > 2422 and py <= HORDE_ORGIM_Y_LIMIT then
        MoveImmediately(player, HORDE_OGRIM_START_POS.x, HORDE_OGRIM_START_POS.y, HORDE_OGRIM_START_POS.z)
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end

    -- Jump cooldown gate
    if (player:GetData("GunshipJumpCooldown") or 0) > os.time() then
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end

    -- Between ships: rocket jump toward Skybreaker if mage, toward Ogrim if not
    if py > 2428 and py < HORDE_SKYBREAKER_Y_LIMIT and not (player == mainTank) then
        player:MoveStop()
        if mage and not mainTank or (mainTank and mainTank:GetY() > HORDE_SKYBREAKER_Y_LIMIT) then
            print("[GunshipDebug] " .. player:GetName() .. " between ships, mage present and tank ready, jumping to Skybreaker")
            AllowSpellCast(player) local aura = player:AddAura(65985, player) if aura then aura:SetDuration(3000) end player:CastSpellAoF(HORDE_SKYBREAKER_JUMP_POS.x, HORDE_SKYBREAKER_JUMP_POS.y, HORDE_SKYBREAKER_JUMP_POS.z, ROCKET_PACK_SPELL, true)
        elseif mage then
            AddRootAura(player, 15000)
        elseif not mage and py > 2429 then
            print("[GunshipDebug] " .. player:GetName() .. " between ships, no mage, jumping back to Ogrim")
            AllowSpellCast(player) local aura = player:AddAura(65985, player) if aura then aura:SetDuration(3000) end player:CastSpellAoF(HORDE_OGRIM_START_POS.x, HORDE_OGRIM_START_POS.y, HORDE_OGRIM_START_POS.z, ROCKET_PACK_SPELL, true)
        end
        player:SetData("GunshipJumpCooldown", os.time() + JUMP_COOLDOWN)
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end

    -- Main tank: taunt/threat Muradin on Skybreaker, jump when mage appears
    if IsTank(player) and mainTank and mainTank == player then
        ApplyDamageReductionStacks(player, (20 + player:GetDifficulty()*15), 30000)

        -- anyForward check: tank should not jump back if DPS are still on Skybreaker
        if py > HORDE_SKYBREAKER_Y_LIMIT then
            local anyForward = false
            local players = player:GetPlayersInRange(200)
            for _, p in ipairs(players) do
                if not IsTank(p) and p:GetY() > 2446 then
                    anyForward = true
                    break
                end
            end
            
            if not anyForward and not mage then
                print("[GunshipDebug] " .. player:GetName() .. " main tank jumping back to Ogrim's Hammer!")
                AllowSpellCast(player) local aura = player:AddAura(65985, player) if aura then aura:SetDuration(3000) end player:CastSpellAoF(HORDE_OGRIM_TANK_TRANSITION.x, HORDE_OGRIM_TANK_TRANSITION.y, HORDE_OGRIM_TANK_TRANSITION.z, ROCKET_PACK_SPELL, true)
                player:SetData("GunshipJumpCooldown", os.time() + JUMP_COOLDOWN)
                player:RegisterEvent(GunshipLoop, 200, 1)
                return
            elseif anyForward then
                if IsAtPos(player, HORDE_SKYBREAKER_TANK_JUMP.x, HORDE_SKYBREAKER_TANK_JUMP.y, 2) then
                    AddRootAura(player, 2000)
                else
                    MoveImmediately(player, HORDE_SKYBREAKER_TANK_JUMP.x, HORDE_SKYBREAKER_TANK_JUMP.y, HORDE_SKYBREAKER_TANK_JUMP.z)
                end
            end

            -- On Skybreaker (enemy ship): tank Muradin
            if not player:HasAura(ORGRIMS_HAMMER_DECK_AURA) then
                player:AddAura(ORGRIMS_HAMMER_DECK_AURA, player)
            end
            if muradin then
                if not IsAtPos(muradin, px, py - 3, 4) then
                    muradin:MoveTo(999, px, py - 3, pz)
                else
                    AddRootAura(muradin, 2000)
                end
                player:SetFacingToObject(muradin)
                Taunt(player, muradin, true)
                if tick % 8 == 0 then
                    BuildThreat(player, muradin)
                end
            end
            if mage then
                if IsAtPos(player, HORDE_SKYBREAKER_TANK_JUMP.x, HORDE_SKYBREAKER_TANK_JUMP.y, 2) then
                    AddRootAura(player, 2000)
                else
                    MoveImmediately(player, HORDE_SKYBREAKER_TANK_JUMP.x, HORDE_SKYBREAKER_TANK_JUMP.y, HORDE_SKYBREAKER_TANK_JUMP.z)
                end
            end
        end

        if mage then
            if py < HORDE_OGRIM_TANK_TRANSITION.y - 2 then
                UseRocketBoots(player)
                MoveImmediately(player, HORDE_OGRIM_TANK_TRANSITION.x, HORDE_OGRIM_TANK_TRANSITION.y, HORDE_OGRIM_TANK_TRANSITION.z)
            elseif py >= HORDE_OGRIM_TANK_TRANSITION.y - 1 and py <= HORDE_SKYBREAKER_Y_LIMIT then
                AllowSpellCast(player) local aura = player:AddAura(65985, player) if aura then aura:SetDuration(3000) end player:CastSpellAoF(HORDE_SKYBREAKER_JUMP_POS.x - 3, HORDE_SKYBREAKER_JUMP_POS.y, HORDE_SKYBREAKER_JUMP_POS.z, ROCKET_PACK_SPELL, true)
                player:SetData("GunshipJumpCooldown", os.time() + JUMP_COOLDOWN)
                print("MT Jumping to skybreaker")
            elseif py > HORDE_SKYBREAKER_Y_LIMIT then
                player:SetData("GunshipJumpCooldown", 0)
                if IsAtPos(player, HORDE_SKYBREAKER_TANK_JUMP.x, HORDE_SKYBREAKER_TANK_JUMP.y, 2) then
                    AddRootAura(player, 2000)
                else
                    MoveImmediately(player, HORDE_SKYBREAKER_TANK_JUMP.x, HORDE_SKYBREAKER_TANK_JUMP.y, HORDE_SKYBREAKER_TANK_JUMP.z)
                end
            end
        end
    else
        -- DPS

        -- Save bots from falling through Skybreaker deck
        if py > HORDE_SKYBREAKER_Y_LIMIT then
            if pz < 469 then
                player:NearTeleport(px, py, HORDE_SKYBREAKER_TANK_JUMP.z, player:GetO())
                AddToEnemyTransport(player, muradin)
            end
        end

        -- Fix facing jank
        local target = player:GetSelection()
        if target then player:SetFacingToObject(target) end

        if py < 2422 and mage then
            -- Too far back on Ogrim, walk to jump edge
            MoveImmediately(player, -429.911, 2423, 471.86655)
        elseif py > HORDE_SKYBREAKER_Y_LIMIT then
            -- On Skybreaker
            player:SetData("GunshipJumpCooldown", 0)
            if not mage then
                if not IsAtPos(player, HORDE_SKYBREAKER_JUMP_POS.x, HORDE_SKYBREAKER_JUMP_POS.y, 2) then
                    MoveImmediately(player, HORDE_SKYBREAKER_JUMP_POS.x, HORDE_SKYBREAKER_JUMP_POS.y, HORDE_SKYBREAKER_JUMP_POS.z)
                else
                    AllowSpellCast(player) local aura = player:AddAura(65985, player) if aura then aura:SetDuration(3000) end player:CastSpellAoF(HORDE_OGRIM_JUMP_POS.x, HORDE_OGRIM_JUMP_POS.y, HORDE_OGRIM_JUMP_POS.z, ROCKET_PACK_SPELL, true)
                    player:SetData("GunshipJumpCooldown", os.time() + JUMP_COOLDOWN)
                end
            end
        end
    end

    player:RegisterEvent(GunshipLoop, 200, 1)
end

local function GunshipAllianceActions(eventId, delay, repeats, player)
    if player:IsDead() or not player:IsInCombat() or not (player:GetMapId() == 631) then
        StopLuaEvent(player)
        return
    end

    if player:IsOnVehicle() then
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end

    local px, py, pz = player:GetLocation()
    
    -- Fight over, do not re-schedule event
    local Ogrim = player:GetNearestCreature(200, OGRIM_ENTRY, 0, 0)
    if Ogrim and (Ogrim:IsDead() or Ogrim:GetHealth() == 1) then
        player:NearTeleport(ALLY_SKYBREAKER_START_POS.x, ALLY_SKYBREAKER_START_POS.y, ALLY_SKYBREAKER_START_POS.z, player:GetO())
        AddToFactionTransport(player)
        AddRootAura(player, 20000)
        HandleRocketPack(33, player)
        return
    end 

    -- Outside of Skybreaker main deck? Correct pos.
    if (pz >= 400 and pz <= 450) or px > -360 or px < -420 then
        player:NearTeleport(ALLY_SKYBREAKER_START_POS.x, ALLY_SKYBREAKER_START_POS.y, ALLY_SKYBREAKER_START_POS.z, player:GetO())
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end
    
    -- Floor Z misalignment? Correct.
    if py >= ALLY_SKYBREAKER_Y_LIMIT and py <= ALLY_Y_LIMIT and (not player:IsMoving() or not player:IsCasting()) and pz > player:GetFloorZ() + 2 and player:GetFloorZ() > 466 and player:GetFloorZ() < 470 then
        player:NearTeleport(px, py, player:GetFloorZ(), player:GetO())
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end

    if pz > 468 then -- Don't queue multiple commands mid-air, let bot AI fix height bugs
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end

    local mage = GetMageChanneling(player)
    local saurfang = player:GetNearestCreature(200, SAURFANG_ENTRY)
    if saurfang and saurfang:GetZ() + 1 < saurfang:GetFloorZ() then
        saurfang:NearTeleport(saurfang:GetX(), saurfang:GetY(), saurfang:GetFloorZ(), saurfang:GetO())
    end
    
    local mainTank, offTank = IdentifyTanks(saurfang)

    local tick = (player:GetData("GunshipTick") or 0) + 1
    player:SetData("GunshipTick", tick)

    -- Ensure bots are added to transports
    if py < ALLY_OGRIM_Y_LIMIT then
        AddToEnemyTransport(player, saurfang)
    elseif py > ALLY_SKYBREAKER_Y_LIMIT then
        AddToFactionTransport(player)
    else
        local current = player:GetTransport()
        if current then
            RemovePassengerFromTransport(current, player)
        end
    end
    
    -- Target prio mage, always
    if mage then MarkTargetSkull(player, mage) end

    -- Off tank stuff
    if IsTank(player) and offTank and offTank == player then
        local tx, ty = ALLY_SKYBREAKER_START_POS.x, ALLY_SKYBREAKER_START_POS.y + 5
        if player:GetSelection() then player:SetFacingToObject(player:GetSelection()) end
        if IsAtPos(player, tx, ty, 2) then
            AddRootAura(player, 2000)
        else
            MoveImmediately(player, tx, ty, GetCorrectedZ(tx, ty) or pz)
        end
        local skullTarget = nil
        for _, entry in ipairs(KORKRON_ENTRIES) do
            local korkrons = player:GetCreaturesInRange(40, entry)
            for _, korkron in ipairs(korkrons) do
                player:AddThreat(korkron, 300)
                if korkron:GetVictim() ~= player then
                    Taunt(player, korkron, false)
                end
                if tick % 10 == 0 then
                    player:SetFacingToObject(korkron)
                    BuildThreat(player, korkron)
                end
                if not skullTarget or korkron:GetGUIDLow() < skullTarget:GetGUIDLow() then
                    skullTarget = korkron
                end
            end
        end
        if skullTarget and not mage then MarkTargetSkull(player, skullTarget) end
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end

    -- Healer stuff
    if player:HasHealSpec() then
        local tx, ty = ALLY_HEALER_POS.x, ALLY_HEALER_POS.y
        if IsAtPos(player, tx, ty, 4) then
            AddRootAura(player, 3000)
        else
            MoveImmediately(player, tx + math.random(-2.8, 2.8), ty + math.random(-2.8, 2.8), GetCorrectedZ(tx, ty) or pz)
        end
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end

    -- Keep players on Skybreaker deck if no mage. There's a bit of a stutter due to the edge being higher but I think it's probably OK as is
    if not mage then
        if ((player:HasMeleeSpec() or player:HasTankSpec()) and py <= ALLY_SKYBREAKER_WALK_LIMIT + 5) then
            MoveImmediately(player, ALLY_SKYBREAKER_START_POS.x + math.random(-2, 2), ALLY_SKYBREAKER_START_POS.y + math.random(-2, 2), ALLY_SKYBREAKER_START_POS.z)
        elseif (py < ALLY_SKYBREAKER_Y_LIMIT + 2 and py >= ALLY_SKYBREAKER_Y_LIMIT) then
            MoveImmediately(player, px, ALLY_SKYBREAKER_WALK_LIMIT + math.random(-0.5, 0.5), 467.55)
        end
    end

    -- Don't jump between Skybreaker and Ogrim if we have recently jumped
    if (player:GetData("GunshipJumpCooldown") or 0) > os.time() then
        player:RegisterEvent(GunshipLoop, 200, 1)
        return
    end

    -- If we are between ships and no mage is present, jump back to Skybreaker
    if not mage and not mainTank then
        if py >= ALLY_OGRIM_Y_LIMIT and py <= ALLY_SKYBREAKER_Y_LIMIT then
            local tx, ty = ALLY_SKYBREAKER_START_POS.x, ALLY_SKYBREAKER_START_POS.y
            AllowSpellCast(player) local aura = player:AddAura(65985, player) if aura then aura:SetDuration(3000) end player:CastSpellAoF(tx, ty, GetCorrectedZ(tx, ty) or pz, ROCKET_PACK_SPELL, true)
            player:SetData("GunshipJumpCooldown", os.time() + JUMP_COOLDOWN)
            player:RegisterEvent(GunshipLoop, 200, 1)
            return
        end
    end

    -- Main tank stuff
    if IsTank(player) and mainTank and mainTank == player then
        ApplyDamageReductionStacks(player, (20 + player:GetDifficulty()*15), 30000)
        if py < ALLY_OGRIM_Y_LIMIT then
            if not player:HasAura(ORGRIMS_HAMMER_DECK_AURA) then
                player:AddAura(ORGRIMS_HAMMER_DECK_AURA, player)
            end
            if saurfang then
                if not IsAtPos(saurfang, px, py - 3, 4) then
                    saurfang:MoveTo(999, px, py - 3, pz)
                else
                    AddRootAura(saurfang, 2000)
                end
                player:SetFacingToObject(saurfang)
                Taunt(player, saurfang, true)
                if tick % 8 == 0 then
                    BuildThreat(player, saurfang)
                end
            end
            if mage then
                if IsAtPos(player, ALLY_OGRIM_TANK_JUMP.x, ALLY_OGRIM_TANK_JUMP.y, 2) then
                    AddRootAura(player, 2000)
                else
                    MoveImmediately(player, ALLY_OGRIM_TANK_JUMP.x, ALLY_OGRIM_TANK_JUMP.y, ALLY_OGRIM_TANK_JUMP.z)
                end
            end
        end
        if mage then
            if py > ALLY_SKYBREAKER_WALK_LIMIT + 2 then
                local tx, ty = ALLY_SKYBREAKER_START_POS.x, ALLY_SKYBREAKER_Y_LIMIT
                UseRocketBoots(player)
                MoveImmediately(player, tx, ty, GetCorrectedZ(tx, ty) or pz)
            elseif py <= ALLY_SKYBREAKER_WALK_LIMIT and py >= ALLY_SKYBREAKER_Y_LIMIT then
                AllowSpellCast(player) local aura = player:AddAura(65985, player) if aura then aura:SetDuration(3000) end player:CastSpellAoF(ALLY_OGRIM_TANK_JUMP.x, ALLY_OGRIM_TANK_JUMP.y, ALLY_OGRIM_TANK_JUMP.z, ROCKET_PACK_SPELL, true)
                player:SetData("GunshipJumpCooldown", os.time() + JUMP_COOLDOWN)
            elseif py < ALLY_SKYBREAKER_Y_LIMIT then
                if py < ALLY_OGRIM_Y_LIMIT then
                    player:SetData("GunshipJumpCooldown", 0)
                end
            end
        else
            if py < ALLY_SKYBREAKER_Y_LIMIT then
                RemoveRootAura(player)
                local anyForward = false
                local players = player:GetPlayersInRange(200)
                for _, p in ipairs(players) do
                    if not IsTank(p) and p:GetY() < ALLY_OGRIM_Y_LIMIT then
                        anyForward = true
                        break
                    end
                end
                if not anyForward then
                    print("[GunshipDebug] " .. player:GetName() .. " main tank jumping back to skybreaker!")
                    RemoveRootAura(player)
                    AllowSpellCast(player) player:CastSpellAoF(ALLY_SKYBREAKER_START_POS.x, ALLY_SKYBREAKER_START_POS.y - 5, ALLY_SKYBREAKER_START_POS.z, ROCKET_PACK_SPELL, true)
                    player:SetData("GunshipJumpCooldown", os.time() + JUMP_COOLDOWN)
                else
                    if IsAtPos(player, ALLY_OGRIM_TANK_JUMP.x, ALLY_OGRIM_TANK_JUMP.y, 2) then
                        AddRootAura(player, 2000)
                    else
                        RemoveRootAura(player)
                        MoveImmediately(player, ALLY_OGRIM_TANK_JUMP.x, ALLY_OGRIM_TANK_JUMP.y, ALLY_OGRIM_TANK_JUMP.z)
                    end
                end
            end
        end
    else -- DPS stuff
        
        -- Save bots from falling through Ogrim's Hammer
        if py < ALLY_OGRIM_Y_LIMIT then
            if pz < 466 then
                player:NearTeleport(px, py, 466.7, player:GetO())
                AddToEnemyTransport(player, saurfang)
            end
        end
        
        -- Fix facing jank
        local target = player:GetSelection()
        if target then player:SetFacingToObject(target) end
        
        local distToTank = math.abs(px - ALLY_OGRIM_TANK_JUMP.x)
        if py >= ALLY_OGRIM_Y_LIMIT and py <= ALLY_SKYBREAKER_Y_LIMIT and not mage then
            local tx, ty = ALLY_SKYBREAKER_START_POS.x, ALLY_SKYBREAKER_START_POS.y
            AllowSpellCast(player) local aura = player:AddAura(65985, player) if aura then aura:SetDuration(3000) end player:CastSpellAoF(tx, ty, GetCorrectedZ(tx, ty) or pz, ROCKET_PACK_SPELL, true)
            player:SetData("GunshipJumpCooldown", os.time() + JUMP_COOLDOWN)
        elseif py > ALLY_SKYBREAKER_WALK_LIMIT and mage then
            MoveImmediately(player, px, ALLY_SKYBREAKER_Y_LIMIT, GetCorrectedZ(px, ALLY_SKYBREAKER_Y_LIMIT) or pz)
        elseif py >= ALLY_OGRIM_Y_LIMIT and py <= ALLY_SKYBREAKER_WALK_LIMIT and mage then
            if not mainTank or (mainTank and mainTank:GetY() < ALLY_OGRIM_Y_LIMIT) then
                local tx = ALLY_OGRIM_TANK_JUMP.x - 12 + math.random(-2, 2)
                local ty = ALLY_OGRIM_TANK_JUMP.y - 4 - math.random(0, 2)
                AllowSpellCast(player) local aura = player:AddAura(65985, player) if aura then aura:SetDuration(3000) end player:CastSpellAoF(tx, ty, ALLY_OGRIM_TANK_JUMP.z, ROCKET_PACK_SPELL, true)
                player:SetData("GunshipJumpCooldown", os.time() + JUMP_COOLDOWN)
            end
        elseif py < ALLY_OGRIM_Y_LIMIT then
            player:SetData("GunshipJumpCooldown", 0)
            if not mage then
                if not IsAtPos(player, px, ALLY_OGRIM_Y_LIMIT, 2) then
                    MoveImmediately(player, px, ALLY_OGRIM_Y_LIMIT, math.min(pz, ALLY_OGRIM_TANK_JUMP.z))
                else
                    AllowSpellCast(player) local aura = player:AddAura(65985, player) if aura then aura:SetDuration(3000) end player:CastSpellAoF(px, py + 30, ALLY_OGRIM_TANK_JUMP.z, ROCKET_PACK_SPELL, true)
                    player:SetData("GunshipJumpCooldown", os.time() + JUMP_COOLDOWN)
                end
            end
        end
    end

    player:RegisterEvent(GunshipLoop, 200, 1)
end

function GunshipLoop(eventId, delay, repeats, player)
    if player:IsDead() or not player:IsInCombat() then
        StopLuaEvent(player)
        return
    end

    local py = player:GetY()
    if py < 2150 then
        GunshipAllianceActions(eventId, delay, repeats, player)
    end
    if py > 2150 then
        GunshipHordeActions(eventId, delay, repeats, player)
    end
end

local function GunshipOnEnterCombat(event, player, creature)
    if player:GetMapId() ~= 631 then return end
    if not player:IsBot() then return end
    local pz = player:GetZ()
    if pz < 410 or pz > 500 then return end -- Ignore bots elsewhere
    
    local zafod = player:GetNearestCreature(200, ZAFOD) -- Only start if on/near gunship/Zafod
    if not zafod then return end
    
    player:Dismount() -- Dismount so e.g., Druids don't get stuck mounted
    HandleRocketPack(event, player) -- Add rocket pack visual on enter combat
    
    if player:GetDifficulty() > 1 then ApplyHiddenBuffsToShadows(player) end -- Buff on HC
    
    player:SetData("FightOver", false)
    
    player:RegisterEvent(GunshipLoop, 200, 1)
end

local function RootOnSkybreaker(eventId, delay, repeats, player)
    if not (player:GetMapId() == 631) then
        player:RemoveEventById(eventId)
        return
    end
    
    local OnSkybreakerDeck = player:GetNearestCreature(200, 37519)
    if not OnSkybreakerDeck then return end
    
end

local function HandleMapEvents(event, player)
    HandleRocketPack(event, player)
    if not (player:GetMapId() == 631) then return end
    if not player:IsBot() then return end
    player:RegisterEvent(RootOnSkybreaker, 10000, 0)
end

local function AllianceGunshipLock(event, creature)
    local transport = creature:GetTransport()
    if not transport then return end
    local tEntry = transport:GetEntry()
    local cx, cy, cz, co = creature:GetLocation()
    
    if tEntry == SKYBREAKER and cz > 195 then return end
    if tEntry == OGRIMS_HAMMER and cz > 218 then return end
    if cz > 460 then return end

    local ox = creature:GetData("LockPosX")
    local oy = creature:GetData("LockPosY")
    local oz = creature:GetData("LockPosZ")
    if not ox then
        creature:SetData("LockPosX", cx)
        creature:SetData("LockPosY", cy)
        creature:SetData("LockPosZ", cz)
        return
    end
    local dist = math.sqrt((cx - ox)^2 + (cy - oy)^2 + (cz - oz)^2)
    local shouldRoot = dist > 1

    local RootZ = 189.5
    if tEntry == OGRIMS_HAMMER then RootZ = 214 end
    local players = creature:GetPlayersInRange(100)
    
    for _, player in ipairs(players) do
        if player:GetZ() > 230 then return end
        if player:IsBot() then
            if player:GetZ() < RootZ then
                player:NearTeleport(player:GetX(), player:GetY(), RootZ, player:GetO())
            end
            if shouldRoot then
                AddToFactionTransport(player)
                AddRootAura(player, 45000)
            end
        end
    end
end

RegisterCreatureEvent(37519, 7, AllianceGunshipLock)
RegisterPlayerEvent(33, GunshipOnEnterCombat)
RegisterPlayerEvent(28, HandleMapEvents) -- Remove rocket pack visual
if GetStateMap() then for _, player in ipairs(GetStateMap():GetPlayers()) do GunshipOnEnterCombat(nil, player, nil) end end
