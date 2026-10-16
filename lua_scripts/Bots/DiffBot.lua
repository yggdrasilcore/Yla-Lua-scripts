-- Multistate: WORLD_EVENT_ON_UPDATE (server event 13) and GetPlayersInWorld()
-- only exist in the global state, so this script is global-only.
if GetStateMapId() ~= -1 then return end

if not (GetRealmID() == 1) then return end -- Only on prod

local highDiffCount = 0
local lastalert = 0

local function onServerUpdate(event, diff)
    if os.time() - lastalert < 300 then
        return
    end
    
    if diff > 300 then
        highDiffCount = highDiffCount + 1
    end
    
    if highDiffCount >= 500 then
        print("ALERT! Diff: "..diff)
        
        local playerCount = #GetPlayersInWorld()
		local message
        
        message = string.format("High server diff alert! Diff: %d ms, Players online: %d. Consult the logs to learn why.", diff, playerCount)
		
        SendToDiscord(message)
        
        lastalert = os.time()
        highDiffCount = 0
    end
end

RegisterServerEvent(13, onServerUpdate)