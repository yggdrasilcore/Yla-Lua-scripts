CharDBExecute("CREATE TABLE IF NOT EXISTS statistics (event VARCHAR(32) NOT NULL, param1 INT UNSIGNED, param2 VARCHAR(15), param3 INT UNSIGNED);")

local function RecordPlayerCount()
   CharDBExecute("INSERT INTO statistics (event, param1, param2, param3) VALUES ('playerCount', "..#GetPlayersInWorld()..", NULL, "..os.time()..");")
end

CreateLuaEvent(RecordPlayerCount, 300000, 0) -- Check player count every 5 min