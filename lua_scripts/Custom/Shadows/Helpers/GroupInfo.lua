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
    local groupType = packet:ReadUByte()
    local slotGroup = packet:ReadUByte()
    local slotFlags = packet:ReadUByte()
    local slotRoles = packet:ReadUByte()
    
    if groupType >= 16 then
        local dungeonStatus = packet:ReadUByte()
        local dungeonId = packet:ReadULong()
    end
    
    local groupGuid = packet:ReadGUID()
    local counter = packet:ReadULong()
    local memberCount = packet:ReadULong()
    
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
        
        local hasRole = false
        
        if HasFlag(flags, MEMBER_FLAG_ASSISTANT) then
            table.insert(cache.assistants, name)
            hasRole = true
        end
        
        if HasFlag(flags, MEMBER_FLAG_MAINTANK) then
            table.insert(cache.mainTanks, name)
            hasRole = true
        end
        
        if HasFlag(flags, MEMBER_FLAG_MAINASSIST) then
            table.insert(cache.mainAssists, name)
            hasRole = true
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

-- Debug CMD

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

-- Refreshes main tank/off tank cache

local MEMBER_FLAG_ASSISTANT = 0x01

local processedGroups = {}

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