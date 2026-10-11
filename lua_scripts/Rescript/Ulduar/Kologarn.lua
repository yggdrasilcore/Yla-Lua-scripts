-- Multistate: Ulduar-only script (map 603).
if GetStateMapId() ~= 603 then return end

local KOLOGARN_ENTRY = 32930
local BRIDGE_ENTRY = 342971
local BRIDGE_X, BRIDGE_Y, BRIDGE_Z, BRIDGE_O = 1797.15, -24.4027, 448.741, 3.1935

local killedKologarn = {}

local function checkBridge(e, d, r, player)
	if not (player:GetMapId() == 603) and e then player:RemoveEventById(e) return end

	local px, py = player:GetX(), player:GetY()
	local dx, dy = px - BRIDGE_X, py - BRIDGE_Y
	if (dx * dx + dy * dy) > (500 * 500) then return end

    local kologarn = player:GetNearestCreature(500, KOLOGARN_ENTRY, 0, 0)
	local bridge = player:GetNearestCreature(500, BRIDGE_ENTRY, 0, 0)
        
    if kologarn and kologarn:IsAlive() and bridge then
        print("Depsawning kologarn bridge")
        bridge:DespawnOrUnsummon() -- Removes bridge if glitched while Kologarn alive
        return
    end
    
	if not bridge and kologarn and not kologarn:IsAlive() then
        print("Kologarn dead and Bridge not found - spawning new")
		bridge = player:SpawnCreature(BRIDGE_ENTRY, BRIDGE_X, BRIDGE_Y, BRIDGE_Z, BRIDGE_O, 8, 0)
		if not bridge then print("Error spawning bridge") return end
	end
    
    if not bridge then return end
    
    if not kologarn:IsAlive() then
        kologarn:DespawnOrUnsummon()
    end
    
	bridge:NearTeleport(BRIDGE_X, BRIDGE_Y, BRIDGE_Z, BRIDGE_O)
    
    bridge:SetRooted()
    
    if not killedKologarn[bridge:GetInstanceId()] then
        killedKologarn[bridge:GetInstanceId()] = os.time() + 5
    end
    
    if killedKologarn[bridge:GetInstanceId()] < os.time() then
        bridge:RemoveAura(74490)
        bridge:SetUInt32Value(83, 383)
    else
        if not bridge:HasAura(74490) then
            bridge:AddAura(74490, bridge)
        end
        
    end
end

local function killKologarn(event, player, kologarn)
	if kologarn:GetEntry() ~= KOLOGARN_ENTRY then return end
	local instanceId = player:GetInstanceId()
	killedKologarn[instanceId] = os.time() + 5
	checkBridge(nil, nil, nil, player)
end

local function enterUlduar(event, player)
	local map = player:GetMap()
	if not map or map:GetMapId() ~= 603 then return end
	player:RegisterEvent(checkBridge, 5000, 0)
end

require("Multistate").ForEachPlayer(function(player) player:RegisterEvent(checkBridge, 5000, 0) end)

RegisterPlayerEvent(7, killKologarn)
RegisterPlayerEvent(28, enterUlduar)
WorldDBExecute("REPLACE INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (63342, 'spell_kologarn_focused_eyebeam');")