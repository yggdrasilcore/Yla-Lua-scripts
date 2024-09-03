local function GetTimeUntilNextRestart()
    local currentTime = os.time()
    local currentDate = os.date("*t", currentTime)
    local daysUntilWednesday = (3 - currentDate.wday + 7) % 7
    local daysUntilSunday = (7 - currentDate.wday + 7) % 7
    
    local nextWednesday = os.time({
        year = currentDate.year, 
        month = currentDate.month, 
        day = currentDate.day + daysUntilWednesday, 
        hour = 10, 
        min = 0, 
        sec = 0
    })
    local nextSunday = os.time({
        year = currentDate.year, 
        month = currentDate.month, 
        day = currentDate.day + daysUntilSunday, 
        hour = 10, 
        min = 0, 
        sec = 0
    })

    -- If it's past 10 AM, move to the next occurrence
    if nextWednesday <= currentTime then
        nextWednesday = nextWednesday + 7 * 24 * 60 * 60 -- Add 7 days
    end
    if nextSunday <= currentTime then
        nextSunday = nextSunday + 7 * 24 * 60 * 60 -- Add 7 days
    end

    -- Return the time difference until the next restart
    if nextWednesday < nextSunday then
        return nextWednesday - currentTime
    else
        return nextSunday - currentTime
    end
end

local function ScheduledRestart()
	print("Test2")
    RunCommand("server restart 900 Periodical restart. Will be back shortly.")
end

local timeUntilRestart = GetTimeUntilNextRestart()

eventid = CreateLuaEvent(ScheduledRestart, timeUntilRestart * 1000, 1)

print("[Bot]: Restart bot loaded with event ID "..eventid..". Time until next restart: " .. math.floor(timeUntilRestart / 3600) .. " hours, " .. math.floor((timeUntilRestart % 3600) / 60) .. " minutes.")
