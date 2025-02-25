CharDBExecute("CREATE TABLE IF NOT EXISTS statistics (event VARCHAR(32) NOT NULL, param1 INT UNSIGNED, param2 VARCHAR(15), param3 INT UNSIGNED);")

local function OnPlayerLogin(event, player)
	CharDBExecute("INSERT INTO statistics (event, param1, param2, param3) VALUES ('login', "..player:GetGUIDLow()..", '"..player:GetPlayerIP().."', "..os.time().."), ('playerCount', "..#GetPlayersInWorld()..", NULL, "..os.time()..");")
end

local function OnPlayerLogout(event, player)
	local guid = player:GetGUIDLow()
	local IP = player:GetPlayerIP()
	CreateLuaEvent(function()
        CharDBExecute("UPDATE characters SET online = 0 WHERE guid = " .. guid)
		CharDBExecute("INSERT INTO statistics (event, param1, param2, param3) VALUES ('logout', "..guid..", '"..IP.."', "..os.time().."), ('playerCount', "..#GetPlayersInWorld()..", NULL, "..os.time()..");")
	end, 1000)
end

RegisterPlayerEvent(3, OnPlayerLogin)
RegisterPlayerEvent(4, OnPlayerLogout)