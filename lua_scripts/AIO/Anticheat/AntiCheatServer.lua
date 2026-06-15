local function StartAntiClipCheck(player)
    player:SetData("LastPosX", player:GetX())
    player:SetData("LastPosY", player:GetY())
    player:SetData("LastPosZ", player:GetZ())
    
    local eventId = player:RegisterEvent(function(e, d, r, player)
        local lastX = player:GetData("LastPosX")
        local lastY = player:GetData("LastPosY")
        local lastZ = player:GetData("LastPosZ")
        if not lastX then return end
        
        local curX, curY, curZ = player:GetX(), player:GetY(), player:GetZ()
        local serverDist = player:GetDistance(lastX, lastY, lastZ)
        
		if serverDist < 20 and not player:IsWithinLoS(lastX, lastY, lastZ) then
			local gObjects = player:GetGameObjectsInRange(10)
			if not gObjects or #gObjects == 0 then return end

			for _, gObject in ipairs(gObjects) do
				if gObject:GetName():lower():find("collision")
				or (gObject:GetGoState() == 1 and (
					gObject:GetName():lower():find("door")
					or gObject:GetName():lower():find("entrance")
					or gObject:GetName():lower():find("gate")
					or gObject:GetName():lower():find("port"))
				) then
					local x, y, z = gObject:GetLocation()
                    -- Just log for now, to avoid false positives
					OnAIOAntiCheatCommand(42, player, "AntiCheatAlert M2Clip")
					break
				end
			end
		end

        player:SetData("LastPosX", curX)
        player:SetData("LastPosY", curY)
        player:SetData("LastPosZ", curZ)
    end, 150, 0)
    
    player:SetData("StartAntiClipCheck", eventId)
end

local function SendAntiCheatChecks(player)
    local eventId = player:RegisterEvent(function(e, d, r, player)
        player:SendAddonMessage("AIO_AntiCheat", tostring(player:IsFlying()), 7, player)
        
        local speeds = {}
        for i = 0, 8 do
            speeds[i] = player:GetSpeed(i)
        end
        player:SendAddonMessage("AIO_AntiCheat_Speed", table.concat(speeds, ","), 7, player)
        
        player:SendAddonMessage("AIO_AntiCheat_Water", tostring(player:IsUnderWater()), 7, player)
    end, 1000, 0)
    
    player:SetData("SendAntiCheatChecks", eventId)
end

local function StartElunaAnticheat(event, player)
    if isPlayerBot[player:GetName()] then return end
    
    if player:GetData("SendAntiCheatChecks") then 
        player:RemoveEventById(player:GetData("SendAntiCheatChecks"))
    end 
    
    if player:GetData("StartAntiClipCheck") then
        player:RemoveEventById(player:GetData("StartAntiClipCheck"))
    end
    
    SendAntiCheatChecks(player)
    StartAntiClipCheck(player)
end

local function OnAIOAntiCheatCommand(event, player, command)
    if command:find("AntiCheatAlert") then
		if not player then return end
        local arg = command:match("AntiCheatAlert%s+(%S+)")
        if not arg then return false end
        if player:IsOnTransport() then return false end
        local x, y, z = player:GetLocation()
     
        print("[Anticheat]: Player "..player:GetName().." caught exploiting cheat type "..arg.." at map "..player:GetMapId()..", XYZ "..player:GetX()..", "..player:GetY()..", "..player:GetZ()..". ")
        if arg == "M2Clip" then
			-- Just log for now, to avoid false positives
        elseif arg == "SpeedHack" then
            local clientSpd, closestSpd = command:match("SpeedHack%s+(%S+)%s+(%S+)")
            local state = player:IsUnderWater() and "Swimming" or player:IsFlying() and "Flying" or player:IsFalling() and "Falling" or "Walking"
            SendToDiscord("SpeedHack detected. Offending player: "..player:GetName()..". Pos: "..string.format("%.2f, %.2f, %.2f", x, y, z)..". Map: "..player:GetMapId()..(clientSpd and ". Client speed: "..clientSpd..", Server speed: "..closestSpd or "")..". State: "..state)
        elseif arg == "WaterWalkHack" then
            player:KickPlayer()
        elseif arg == "FlyHack" then
            if not player:IsOutdoors() then
                player:AddAura(43775, player)
                player:RegisterEvent(function(e, d, r, player)
                    player:RemoveAura(43775)
                end, 200, 5)
                return false
            end
            if not player:IsMoving() then return end
            if player:IsDead() then return end
            SendToDiscord("FlyHack detected. Offending player: "..player:GetName()..". Pos: "..string.format("%.2f, %.2f, %.2f", x, y, z)..". Map: "..player:GetMapId())
        elseif arg == "FlyPvPHack" then
            player:KickPlayer()
        end
		return false
    end
end

local function ReloadEluna(event)
    CreateLuaEvent(function()
        local players = GetPlayersInWorld()
        for _, player in ipairs(players) do
            StartElunaAnticheat(event, player)
        end
    end, 5000, 1)
end

RegisterPlayerEvent(42, OnAIOAntiCheatCommand)
RegisterPlayerEvent(28, StartElunaAnticheat)
RegisterServerEvent(33, ReloadEluna)