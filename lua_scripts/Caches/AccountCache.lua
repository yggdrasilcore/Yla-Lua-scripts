
playerAccountID = {}
accountIDbyCharName = {}
playerOfflineName = {}

local function OnCharacterCreate(event, player)
	local guid = player:GetGUIDLow()
	local accountId = player:GetAccountId()
	local name = player:GetName()
	
	playerAccountID[guid] = accountId
	playerOfflineName[guid] = name
	accountIDbyCharName[name] = accountId
end

local function OnCharacterDelete(event, guid)
	local name = player:GetName()
	playerAccountID[guid] = nil
	playerOfflineName[guid] = nil
	accountIDbyCharName[name] = nil
end

local function LoadCharactersOnStartup()
	CharDBQueryAsync("SELECT guid, account, name FROM characters", function(query)
		if query then
			repeat
				local guid = query:GetUInt32(0)
				local accountId = query:GetUInt32(1)
				local name = query:GetString(2)
				playerAccountID[guid] = accountId
				accountIDbyCharName[name] = accountId
				playerOfflineName[guid] = name
			until not query:NextRow()
			
			local count = 0
			for _ in pairs(playerAccountID) do count = count + 1 end
		end
	end)
end

RegisterPlayerEvent(1, OnCharacterCreate)
RegisterPlayerEvent(2, OnCharacterDelete)
LoadCharactersOnStartup()