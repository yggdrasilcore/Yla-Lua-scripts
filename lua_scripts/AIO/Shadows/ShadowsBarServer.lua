-- Multistate: AIO addon-message handlers run in the global state (Group API is
-- world-only as well).
if GetStateMapId() ~= -1 then return end

local ShadowsCacheHandlers = AIO.AddHandlers("ShadowsCache", {})

function ShadowsCacheHandlers.RequestCache(player)
    local group = player:GetGroup()
    if not group then return end
    
    local cache = {}
    local members = group:GetMembers()
    local playerAccountId = player:GetAccountId()
    local playerName = player:GetName()
    
    for _, member in pairs(members) do
        local memberName = member:GetName()
        if member:GetAccountId() == playerAccountId and memberName ~= playerName then
            cache[memberName] = member:GetClassAsString()
        end
    end
    
    AIO.Handle(player, "ShadowsCache", "LoadCache", cache)
end