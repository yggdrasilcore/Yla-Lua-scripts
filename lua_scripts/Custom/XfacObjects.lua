local XFacMaps = {[631]=1, [658]=1, [632]=1, [668]=1}

local MaxGOCharges = {
    -- {gameObjectId, maxCharges}
    [193061] = 50, -- Refreshment Table (level 80)
    [186812] = 50, -- Refreshment Table (level 70)
    -- [181622] = 25, -- Ritual of Souls WRONG ID
    [192152] = 10, -- Big Berry Pie Cake
    [192783] = 10, -- Dalaran Apple Bowl
    [193965] = 10, -- Dalaran Swiss Wheel
    [192151] = 5,  -- Lovely Cake
    [193964] = 5,  -- Aged Dalaran Sharp Wheel
    [192150] = 5,  -- Chocolate Celebration Cake
    [195303] = -1, -- Bountiful Feast
    [193056] = -1, -- Small Feast
    [193055] = -1, -- Gigantic Feast
    [192675] = -1, -- Fish Feast
    [192625] = -1, -- Great Feast
    -- [194108] = -1  -- Ritual of Summoning WRONG ID
}

local XfacGOTable = {}
local GOCount = {}
local GoSpawnToggle = true -- We can use an on/off toggle since mod-Eluna is sync, not async, and only processes one spawn event at a time. When multistate is launched this toggle needs to be map-specific

local function removeObject(e, d, r, go)
    go:RemoveEvents()
    go:RemoveFromWorld(false)
end

local function XFacGO(event, go, diff)
    local guid = go:GetGUIDLow()
    local entry = go:GetEntry()
    local map = go:GetMapId()
    if not XFacMaps[map] then return end
    
    if event == 1 then -- On update, check if event should be removed
        if not XfacGOTable[guid] then XfacGOTable[guid] = os.time() + 180 return end -- Reload Eluna-proofing the objects to not last forever
        
        if XfacGOTable[guid] < os.time() then go:RegisterEvent(removeObject, 50) end
        
    elseif event == 2 then -- On player's spawn of object, replace with ownerless object
        if not GoSpawnToggle then return end

        GoSpawnToggle = false -- Don't attempt new spawn if already spawning

        local newGO = PerformIngameSpawn(2, entry, go:GetMapId(), go:GetInstanceId(), go:GetX(), go:GetY(), go:GetZ(), go:GetO(), false, 0, go:GetPhaseMask())
        if not newGO then GoSpawnToggle = true return end -- Don't do anything if spawn failed
        
        local newGuid = newGO:GetGUIDLow()
        
        if MaxGOCharges[entry] > 0 then GOCount[newGuid] = 0 end -- Initialize charge counter if object has charges
        
        XfacGOTable[newGuid] = os.time() + 180
        go:RegisterEvent(removeObject, 50)
        GoSpawnToggle = true
        
    elseif event == 14 then -- On use, iterate count
        if MaxGOCharges[entry] > 0 and not GOCount[newGuid] then GOCount[newGuid] = 0 end -- Reload Eluna-proofing the objects to not last forever
        
        if GOCount[guid] then GOCount[guid] = GOCount[guid] + 1 end
        
        if GOCount[guid] and GOCount[guid] > MaxGOCharges[entry] then go:RegisterEvent(removeObject, 50) return end
    end
end

-- Register events for all game objects
for gameObjectId, _ in pairs(MaxGOCharges) do
    RegisterGameObjectEvent(gameObjectId, 1, XFacGO)
    RegisterGameObjectEvent(gameObjectId, 2, XFacGO)
end