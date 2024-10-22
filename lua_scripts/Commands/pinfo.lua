local function GetGenderName(genderId)
    return genderId == 0 and "Male" or "Female"
end

local function GetRaceName(raceId)
    local races = {
        [1] = "Human",
        [2] = "Orc",
        [3] = "Dwarf",
        [4] = "Night Elf",
        [5] = "Undead",
        [6] = "Tauren",
        [7] = "Gnome",
        [8] = "Troll",
        [9] = "Goblin",
        [10] = "Blood Elf",
        [11] = "Draenei"
    }
    return races[raceId] or "Unknown"
end

local function GetClassName(classId)
    local classes = {
        [1] = "Warrior",
        [2] = "Paladin",
        [3] = "Hunter",
        [4] = "Rogue",
        [5] = "Priest",
        [6] = "Death Knight",
        [7] = "Shaman",
        [8] = "Mage",
        [9] = "Warlock",
        [11] = "Druid"
    }
    return classes[classId] or "Unknown"
end

local function CapitalizeName(name)
    return name:sub(1,1):upper() .. name:sub(2):lower()
end

local function UnixToDateTime(unixTimestamp)
    return os.date("%Y-%m-%d %H:%M:%S", tonumber(unixTimestamp))
end

local function bitwise_and(a, b)
    local result = 0
    local bitval = 1
    while a > 0 and b > 0 do
        if a % 2 == 1 and b % 2 == 1 then
            result = result + bitval
        end
        a = math.floor(a / 2)
        b = math.floor(b / 2)
        bitval = bitval * 2
    end
    return result
end

local function OnPinfo(event, player, command)
    local cmdPrefix = "pinfo "
    if (command:sub(1, #cmdPrefix) == cmdPrefix or command == "pinfo") and player:GetGMRank() > 0 then
        local name = player:GetName()
        local targetName = command:sub(#cmdPrefix + 1)

        if targetName == "" then
            local target = player:GetSelection()
            if target and target:GetTypeId() == 4 then
                targetName = target:GetName()
            else
                targetName = name
            end
        end

        targetName = CapitalizeName(targetName)
        local targetPlayer = GetPlayerByName(targetName)
        local zone
        if targetPlayer then 
            zone = targetPlayer:GetZoneId()
        end
        
        CharDBQueryAsync(
            "SELECT guid, account, gender, level, money, race, class, zone, totaltime as playedtime, logout_time, creation_date, playerFlags " ..
            "FROM characters WHERE name = '" .. targetName .. "'",
            function(result)
                if not result then
                    local currentPlayer = GetPlayerByName(name)
                    if currentPlayer then currentPlayer:SendBroadcastMessage("Invalid player name.") end
                    return
                end

                local charRow = result:GetRow()
                
                if not charRow or not charRow["guid"] or not charRow["account"] or not charRow["gender"] or 
                   not charRow["level"] or not charRow["money"] or not charRow["race"] or not charRow["class"] or 
                   not charRow["zone"] or not charRow["playedtime"] or not charRow["logout_time"] or 
                   not charRow["creation_date"] or not charRow["playerFlags"] then
                    local currentPlayer = GetPlayerByName(name)
                    if currentPlayer then currentPlayer:SendBroadcastMessage("Invalid player data in database! Contact a dev for aid.") end
                    return
                end

                local days = math.floor(charRow["playedtime"] / 86400)
                local hours = math.floor((charRow["playedtime"] % 86400) / 3600)
                local minutes = math.floor((charRow["playedtime"] % 3600) / 60)
                local seconds = charRow["playedtime"] % 60

                local playedTimeFormatted = string.format("%d days, %d hours, %d minutes, %d seconds", days, hours, minutes, seconds)

                local alive
                if targetPlayer then 
                    alive = "Yes" 
                else 
                    alive = (bitwise_and(tonumber(charRow["playerFlags"]), 16) == 16) and "Yes" or "No" 
                end

                AuthDBQueryAsync(
                    "SELECT username, email, last_ip, last_login, failed_logins, locked " ..
                    "FROM account WHERE id = " .. charRow["account"],
                    function(authResult)
                        if not authResult then
                            local currentPlayer = GetPlayerByName(name)
                            if currentPlayer then currentPlayer:SendBroadcastMessage("Account not found.") end
                            return
                        end

                        local authRow = authResult:GetRow()

                        if not authRow or not authRow["username"] or not authRow["email"] or 
                           not authRow["last_ip"] or not authRow["last_login"] or 
                           not authRow["failed_logins"] or not authRow["locked"] then
                            local currentPlayer = GetPlayerByName(name)
                            if currentPlayer then currentPlayer:SendBroadcastMessage("Invalid player data in database! Contact a dev for aid.") end
                            return
                        end
                        
                        local status
                        if targetPlayer then status = "Online" else status = "Offline" end

                        local zoneName
                        if zone then 
                            zoneName = GetAreaName(zone)
                        else 
                            zoneName = tonumber(charRow["zone"]) > 4987 and "Unknown" or GetAreaName(charRow["zone"])
                        end
                        
                        local logoutTime = UnixToDateTime(charRow["logout_time"])

                        local message = "Player found. GUID: " .. charRow["guid"] .. ". Account: " .. charRow["account"] .. ", " .. authRow["username"] .. ".\n" ..
                                        "Email: " .. authRow["email"] .. ". IP: " .. authRow["last_ip"] .. "\n" ..
                                        "Details: Level " .. charRow["level"] .. " " .. GetGenderName(tonumber(charRow["gender"])) .. ", " .. GetRaceName(tonumber(charRow["race"])) .. " " .. GetClassName(tonumber(charRow["class"])) .. ".\n" ..
                                        "Status: " .. status .. ". Alive: " .. alive .. ". Last area: " .. zoneName .. "\n" ..
                                        "Created: " .. charRow["creation_date"] .. ". Last login: " .. authRow["last_login"] .. ".\n" ..
                                        "Last logout: " .. logoutTime .. ". Failed logins: " .. authRow["failed_logins"] .. ".\n" ..
                                        "Played time: " .. playedTimeFormatted .. ".\n" ..
                                        "Money: " .. string.format("%.2f", tonumber(charRow["money"]) / 10000) .. " gold.\n"

                        CharDBQueryAsync("SELECT guildid, `rank` FROM guild_member WHERE guid = " .. charRow["guid"],
                            function(guildMemberResult)
                                local guildid
                                local rank
                                if not guildMemberResult or not guildMemberResult:GetRow() then
                                    guldid = 1
                                    message = message .. "Guild: No guild.\n"
                                else
                                    local guildMemberRow = guildMemberResult:GetRow()
                                    local guildid = guildMemberRow["guildid"]
                                    rank = guildMemberRow["rank"]
                                end
                                if not guildid then guildid = 1 rank = 1 end
                                
                                CharDBQueryAsync(
                                    "SELECT name FROM guild WHERE guildid = " .. tonumber(guildid),
                                    function(guildResult)
                                        local guildName
                                        if not guildResult or not guildResult:GetRow() then
                                            guildName = "None"
                                        else
                                            local guildRow = guildResult:GetRow()
                                            guildName = guildRow["name"]
                                        end
                                        if not guildName then rankName = "None" end
                                        
                                        CharDBQueryAsync(
                                            "SELECT rname FROM guild_rank WHERE guildid = " .. tonumber(guildid) .. " AND rid = " .. tonumber(rank),
                                            function(guildRankResult)
                                                local rankName = "None"
                                                if not guildRankResult or not guildRankResult:GetRow() then
                                                else
                                                    local guildRankRow = guildRankResult:GetRow()
                                                    rankName = guildRankRow["rname"]
                                                end
                                                if not rankName then rankName = "None" end
                                                message = message .. "Guild: " .. guildName .. ", Rank: " .. rankName .. "\n"
                                                
                                                CharDBQueryAsync(
                                                    "SELECT " ..
                                                    "SUM(CASE WHEN checked = 0 THEN 1 ELSE 0 END) AS checked_0_count, " ..
                                                    "SUM(CASE WHEN checked = 1 THEN 1 ELSE 0 END) AS checked_1_count " ..
                                                    "FROM mail WHERE receiver = " .. charRow["guid"],
                                                    function(mailResult)
                                                        if not mailResult or not mailResult:GetRow() then
                                                            message = message .. "Mails: None\n"
                                                            return
                                                        end

                                                        local row = mailResult:GetRow()
                                                        local checked_0_count = row["checked_0_count"] or 0
                                                        local checked_1_count = (row["checked_1_count"] + row["checked_0_count"]) or 0

                                                        message = message .. "Mails: " .. checked_0_count .. " read / " .. checked_1_count .. " total"

                                                        local currentPlayer = GetPlayerByName(name)
                                                        if currentPlayer then
                                                            currentPlayer:SendBroadcastMessage(message)
                                                            if authRow["locked"] and authRow["locked"] > 0 then
                                                                currentPlayer:SendBroadcastMessage("Locked: Yes")
                                                            end
                                                        end
                                                    end
                                                )
                                            end
                                        )
                                    end
                                )
                            end
                        )
                    end
                )
            end
        )
        return false
    end
end

RegisterPlayerEvent(42, OnPinfo)
