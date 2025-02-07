local fishTable = {}

local function eventtest(event, go, diff)
    if event == 1 then
        
        local guid = go:GetGUIDLow()
        if fishTable[guid] and fishTable[guid] < os.time() then
            go:RegisterEvent(function(e, d, r, go)
                go:RemoveFromWorld(false)
                fishTable[guid] = nil
            end, 30)
        end
        
    elseif event == 2 then
        print("spawnd fish")
        if fishToggle then
            fishToggle = false
            print("Toggled off")
   
            if not (go:GetMapId() == 631) then return end
            print("map OK")
            local newFish = PerformIngameSpawn(2, 192675, go:GetMapId(), go:GetInstanceId(), go:GetX(), go:GetY(), go:GetZ(), go:GetO(), false, 0, go:GetPhaseMask())
            if not newFish then print("Error making factionless fish!") return end
            print("New fish OK")
            local guid = newFish:GetGUIDLow()
            fishTable[guid] = os.time() + 180
            
            go:RegisterEvent(function(e, d, r, go)
                print("Removed old fish")
                go:RemoveFromWorld(false)
            end, 100)
        else
            fishToggle = true
        end
    end
end
    

RegisterGameObjectEvent(192675, 1, eventtest)
RegisterGameObjectEvent(192675, 2, eventtest)