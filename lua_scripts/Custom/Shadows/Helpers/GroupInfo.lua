local SMSG_GROUP_LIST = 0x07D
local PACKET_EVENT_ON_PACKET_SEND = 7

local MEMBER_FLAG_ASSISTANT = 0x01
local MEMBER_FLAG_MAINTANK = 0x02
local MEMBER_FLAG_MAINASSIST = 0x04

local groupCache = {}
local MainTanks = {}
local OffTanks = {}

local function HasFlag(flags, flag)
    return flags % (flag * 2) >= flag
end

function IsMainTank(group, player)
    if not group or not player then return false end
    
    if not IsTank(player) then return false end
    
    local playerName = player:GetName()
    local groupGuid = tostring(group:GetGUID())
    local key = playerName .. ", " .. groupGuid
    
    return MainTanks[key] ~= nil
end

function IsOffTank(group, player)
    if not group or not player then return false end
    
    if not IsTank(player) then return false end
    
    local playerName = player:GetName()
    local groupGuid = tostring(group:GetGUID())
    local key = playerName .. ", " .. groupGuid
    
    return OffTanks[key] ~= nil
end

local function OnGroupListSend(event, packet, player)
    local packetSize = packet:GetSize()
    
    -- Rough estimate: ~20 bytes per player minimum (name + guid + flags)
    -- Header is ~20 bytes, so 6 players = ~140 bytes minimum
    if packetSize < 140 then
        return
    end
    
    local groupType = packet:ReadUByte()
    
    -- Only process normal party (0) and raid (2)
    if groupType ~= 0 and groupType ~= 2 then
        return
    end
    
    local slotGroup = packet:ReadUByte()
    local slotFlags = packet:ReadUByte()
    local slotRoles = packet:ReadUByte()
    
    local groupGuid = packet:ReadGUID()
    local counter = packet:ReadULong()
    local memberCount = packet:ReadULong()
    
    -- Also check actual member count
    if memberCount <= 6 then
        return
    end
    
    groupCache[tostring(groupGuid)] = {
        groupType = groupType,
        counter = counter,
        members = {},
        assistants = {},
        mainTanks = {},
        mainAssists = {}
    }
    
    local cache = groupCache[tostring(groupGuid)]
    local groupGuidStr = tostring(groupGuid)
    
    if player then
        local playerName = player:GetName()
        local key = playerName .. ", " .. groupGuidStr
        
        if HasFlag(slotFlags, MEMBER_FLAG_MAINTANK) then
            MainTanks[key] = true
        else
            MainTanks[key] = nil
        end
        
        if HasFlag(slotFlags, MEMBER_FLAG_MAINASSIST) then
            OffTanks[key] = true
        else
            OffTanks[key] = nil
        end
    end
    
    for i = 1, memberCount do
        local name = packet:ReadString()
        local guid = packet:ReadGUID()
        local onlineState = packet:ReadUByte()
        local group = packet:ReadUByte()
        local flags = packet:ReadUByte()
        local roles = packet:ReadUByte()
        
        cache.members[tostring(guid)] = {
            name = name,
            guid = tostring(guid),
            onlineState = onlineState,
            group = group,
            flags = flags,
            roles = roles
        }
        
        local key = name .. ", " .. groupGuidStr
        
        if HasFlag(flags, MEMBER_FLAG_MAINTANK) then
            MainTanks[key] = true
        else
            MainTanks[key] = nil
        end
        
        if HasFlag(flags, MEMBER_FLAG_MAINASSIST) then
            OffTanks[key] = true
        else
            OffTanks[key] = nil
        end
        
        if HasFlag(flags, MEMBER_FLAG_ASSISTANT) then
            table.insert(cache.assistants, name)
        end
        
        if HasFlag(flags, MEMBER_FLAG_MAINTANK) then
            table.insert(cache.mainTanks, name)
        end
        
        if HasFlag(flags, MEMBER_FLAG_MAINASSIST) then
            table.insert(cache.mainAssists, name)
        end
    end
    
    local leaderGuid = packet:ReadGUID()
    cache.leaderGuid = tostring(leaderGuid)
    
    if memberCount > 0 then
        local lootMethod = packet:ReadUByte()
        local masterLooterGuid = packet:ReadGUID()
        cache.masterLooterGuid = tostring(masterLooterGuid)
        
        local lootThreshold = packet:ReadUByte()
        local dungeonDifficulty = packet:ReadUByte()
        local raidDifficulty = packet:ReadUByte()
        local dynamicDifficulty = packet:ReadUByte()
        
        cache.lootMethod = lootMethod
        cache.lootThreshold = lootThreshold
        cache.dungeonDifficulty = dungeonDifficulty
        cache.raidDifficulty = raidDifficulty
    end
end

RegisterPacketEvent(SMSG_GROUP_LIST, PACKET_EVENT_ON_PACKET_SEND, OnGroupListSend)

local function OnCheckRoleCommand(event, player, command)
    if command == "checkrole" then
        local target = player:GetSelection()
        if not target or not target:IsPlayer() then
            target = player
        end
        
        local group = target:GetGroup()
        if not group then
            player:SendBroadcastMessage(target:GetName() .. " is not in a group")
            return false
        end
        
        local isMainTank = IsMainTank(group, target)
        local isOffTank = IsOffTank(group, target)
        
        local message = target:GetName() .. ": "
        if isMainTank then
            message = message .. "Main Tank"
        end
        if isOffTank then
            if isMainTank then
                message = message .. ", "
            end
            message = message .. "Off Tank"
        end
        if not isMainTank and not isOffTank then
            message = message .. "No role"
        end
        
        player:SendBroadcastMessage(message)
        return false
    end
end

RegisterPlayerEvent(42, OnCheckRoleCommand)

local processedGroups = {}

-- Multistate: load-time group sweep uses world-only APIs (GetPlayersInWorld,
-- Group methods), so it runs in the global state only. The helper functions
-- above stay available in every state for the tactics scripts.
if require("Multistate").IsCompat() or require("Multistate").IsWorld() then
local players = GetPlayersInWorld()
for _, player in ipairs(players) do
    local group = player:GetGroup()
    if group then
        local groupGuid = tostring(group:GetGUID())
        if not processedGroups[groupGuid] then
            processedGroups[groupGuid] = true
            
            local members = group:GetMembers()
            local foundAssistant = false
            
            for _, member in ipairs(members) do
                local memberGuid = member:GetGUIDLow()
                if group:IsAssistant(memberGuid) then
                    group:SetMemberFlag(memberGuid, false, MEMBER_FLAG_ASSISTANT)
                    group:SetMemberFlag(memberGuid, true, MEMBER_FLAG_ASSISTANT)
                    foundAssistant = true
                    break
                end
            end
            
            if not foundAssistant and #members > 0 then
                local randomMember = members[1]
                local randomGuid = randomMember:GetGUIDLow()
                group:SetMemberFlag(randomGuid, true, MEMBER_FLAG_ASSISTANT)
                group:SetMemberFlag(randomGuid, false, MEMBER_FLAG_ASSISTANT)
            end
        end
    end
end
end