local function killKologarn(event, player, kologarn)
	if kologarn:GetEntry() == 32930 then
		kologarn:RegisterEvent(function(e, d, r, kologarn)
			local bridge = kologarn:GetNearestCreature(50, 34297)
			if not bridge then print("Error finding bridge") return end
			print("despawning kolo")
			kologarn:DespawnOrUnsummon()
			print("showing bridge")
			bridge:SetDisplayId(kologarn:GetDisplayId())
			print("making bridge invis")
			bridge:AddAura(74490, bridge)
		end, 10000)
	end
end

local function enterUlduar(event, player)
	local map = player:GetMap()
	if not (map:GetMapId() == 603) then return end
	
	local kologarn = player:GetNearestCreature(50000, 32930)
	
	if not kologarn then print("Error finding kologarn") return end
	
	print("kolo found")
	
	local bridge = kologarn:GetNearestCreature(50, 34297)
	
	if not bridge then print("Error finding bridge") return end
	
	print("bridge found")
	
	bridge:SetFaction(35)
	
	if kologarn:GetHealth() < 1 then
		print("kolo dead")
		
		if (bridge:GetDisplayId() == kologarn:GetDisplayId()) then return end
		
		bridge:SetDisplayId(kologarn:GetDisplayId())
	else
		print("kolo not dead, hiding bridge")
		bridge:SetDisplayId(15435)
	end
end

RegisterPlayerEvent(7, killKologarn)
RegisterPlayerEvent(28, enterUlduar)
WorldDBExecute("REPLACE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (63342, 'spell_kologarn_focused_eyebeam');")
WorldDBExecute("REPLACE INTO `creature` (`guid`, `id1`, `id2`, `id3`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) values('15001785','34297','0','0','603','0','0','3','1','0','1797.15','-24.4027','448.741','3.1935','604800','0','0','3625700','0','0','0','0','0','','0','0',NULL);")
