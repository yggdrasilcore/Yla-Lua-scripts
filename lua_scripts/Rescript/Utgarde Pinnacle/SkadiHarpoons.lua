-- Multistate: Utgarde Pinnacle-only script (map 575).
if not IsCompatibilityMode() and GetStateMapId() ~= 575 then return end

local function OnShootHarpoonLauncher(event, player, itemEntry)
    if itemEntry == 37372 then
        local turret = player:GetNearestGameObject(6)
        
        if not turret then return end
        
        local harpoonShooter = turret:SpawnCreature(36737, turret:GetX(), turret:GetY(), 107.85, turret:GetO(), 1, 5000)
        
        if not harpoonShooter then return end
        
        harpoonShooter:SetHover(true)
        harpoonShooter:SetDisableGravity(true)
        
        local grauf = harpoonShooter:GetNearestCreature(50, 26893)
        
        if grauf then
            if not (grauf:GetX() < 491 and grauf:GetX() > 489) then return end
            
            local target = turret:SpawnCreature(17286, grauf:GetX()+2, grauf:GetY(), grauf:GetZ()+1, 0, 1, 5000)
            
            harpoonShooter:SetFacingToObject(target)
            
            harpoonShooter:CastSpell(target, 63045, true)
            
            target:SetHover(true)
            target:SetDisableGravity(true)
            target:AddAura(44312, target)
            
            if grauf:GetHealthPct() < 33 then return end
            harpoonShooter:DealDamage(grauf, grauf:GetMaxHealth()/3.01)
        else
            local target = turret:SpawnCreature(17286, 538, -547, 80, 0, 1, 5000)
            if not target then return end
            
            target:SetHover(true)
            target:SetDisableGravity(true)
            
            harpoonShooter:CastSpell(target, 63045, true)
        end
    end
end

RegisterPlayerEvent(31, OnShootHarpoonLauncher)

local function OnKillHarpooner(event, player, killed)
    if killed:GetEntry() == 26692 then
        local harpoonSpawner = player:SpawnCreature(36737, killed:GetX(), killed:GetY(), killed:GetZ(), killed:GetO(), 1, 5000)
        
        if not harpoonSpawner then return end
        
        harpoonSpawner:CastSpell(harpoonSpawner, 56789, true)
    end
end

RegisterPlayerEvent(7, OnKillHarpooner)
WorldDBExecute("DELETE FROM `smart_scripts` WHERE `entryorguid` = 26692 AND `source_type` = 0");
WorldDBExecute("INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES (26692, 0, 0, 0, 0, 0, 70, 518, 4000, 45000, 4000, 45000, 0, 0, 11, 49092, 2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Ymirjar Harpooner - In Combat - Cast ''Net'' (Phase 1) (No Repeat)'), (26692, 0, 1, 0, 0, 0, 70, 518, 2000, 25000, 2000, 25000, 0, 0, 11, 49091, 2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Ymirjar Harpooner - In Combat - Cast ''Throw'' (Phase 1) (No Repeat)')");
