WG_FightActive = false
WG_Controller = nil

CharDBQueryAsync("SELECT value FROM worldstates WHERE entry = 3802", function(query)
    if query then
        local v = query:GetUInt32(0)
        if v == 0 then
            WG_Controller = "Alliance"
        else
            WG_Controller = "Horde"
        end
    end
end)

local function InitializeWGState()
    CharDBQueryAsync("SELECT value FROM worldstates WHERE entry = 3801", function(query)
        WG_FightActive = false
        if not query then return end
        local value = query:GetUInt32(0)
        if value == 1 then
            WG_FightActive = true
        end
    end)
end

local WG_DbCheckHistory = {}

local function CheckWintergraspDatabase()
    CharDBQueryAsync("SELECT value FROM worldstates WHERE entry = 3801", function(query)
        if not query then return end
        
        local value = query:GetUInt32(0)
        local dbFightActive = (value == 1)
        local statesMatch = (dbFightActive == WG_FightActive)
        
        table.insert(WG_DbCheckHistory, {
            timestamp = os.time(),
            dbState = dbFightActive,
            localState = WG_FightActive,
            match = statesMatch
        })
        
        if #WG_DbCheckHistory > 3 then
            table.remove(WG_DbCheckHistory, 1)
        end
        
        if #WG_DbCheckHistory >= 2 then
            local consecutiveDeviations = 0
            for i = #WG_DbCheckHistory, 1, -1 do
                if not WG_DbCheckHistory[i].match then
                    consecutiveDeviations = consecutiveDeviations + 1
                else
                    break
                end
            end
            
            if consecutiveDeviations >= 2 then
                print(string.format("[WG DB CHECK] CORRECTION NEEDED! Updating WG_FightActive from %s to %s", 
                    tostring(WG_FightActive), tostring(dbFightActive)))
                
                WG_FightActive = dbFightActive
                
                local statusText = dbFightActive and "true (fight active)" or "false (fight ended)"
                print(string.format("[WG DB CHECK] Fight status corrected to: %s", statusText))
                
                WG_DbCheckHistory = {}
            end
        end
    end)
end

InitializeWGState()
CreateLuaEvent(CheckWintergraspDatabase, 60000, 0)