local extendedDebug = 0 -- Crashes on extended debug...
local lastTeleportTime = {}

RegisterPacketEvent(0x38D, 5, function(event, packet, player)
    if not player then return end
    if not (player:GetAreaId() == 4220) then return end
    local name = player:GetName()
    if not lastTeleportTime[name] then lastTeleportTime[name] = os.time() end
    if lastTeleportTime[name] > os.time() then return end
    
    print("player is "..player:GetName())
    
    print("Client transport change")

    local packetLength = tonumber(tostring(packet:GetSize())) -- unsigned long longs can't be printed directly, nor can they be converted to numbers, so we're doing a double conversion
    print("Packet Length: " .. packetLength)
    
    if packetLength == 59 or packetLength == 75 then -- Apparently packet length seems to be 59 when monsters get off lifts and 58 when players get off lifts. 75 is monsters jump off/fall off lift
        local guid = packet:ReadGUID()
        local movementInfo = {}

        movementInfo.flags = packet:ReadULong() -- This is definitely not read correctly
        movementInfo.time = packet:ReadULong() -- Nor is this
        movementInfo.notsurewhat = packet:ReadByte() -- No idea what this field is even supposed to be, just reading placeholders to find position
        movementInfo.pos = {
            x = packet:ReadFloat(),
            y = packet:ReadFloat(),
            z = packet:ReadFloat(),
            o = packet:ReadFloat()
        }

        print("Position: x=" .. movementInfo.pos.x .. ", y=" .. movementInfo.pos.y .. ", z=" .. movementInfo.pos.z .. ", o=" .. movementInfo.pos.o)
        if player:GetAreaId() == 4220 then
            golem = player:GetNearestCreature(5, 29005)
            if golem then
                golem:RegisterEvent(function(eventId, delay, repeats, golem)
                    if golem and ((golem:GetZ() < (movementInfo.pos.z - 10)) or (golem:GetZ() > (movementInfo.pos.z + 10))) then
                        local player = GetPlayerByName(name)
                        if golem:GetX() < 3307 and golem:GetX() > 3296 then
                            golem:NearTeleport(movementInfo.pos.x, movementInfo.pos.y-4, movementInfo.pos.z+1, movementInfo.pos.o)
                        elseif golem:GetX() < 3290 then
                            golem:NearTeleport(movementInfo.pos.x+4, movementInfo.pos.y, movementInfo.pos.z+1, movementInfo.pos.o)
                        else
                            golem:NearTeleport(movementInfo.pos.x-4, movementInfo.pos.y, movementInfo.pos.z+1, movementInfo.pos.o)
                        end
                        print("Teleporting golem")
                        lastTeleportTime[name] = os.time() + 2
                        --player:NearTeleport(movementInfo.pos.x, movementInfo.pos.y, movementInfo.pos.z, movementInfo.pos.o)
                    end
                end, 200, 10)
            end
        end
    end 
    if extendedDebug == 1 then -- Not sure how to use this, disabled until I figure out
        if packetLength > 32 then
            movementInfo.transport = {
                guid = packet:ReadGUID(),
                pos = {
                    x = packet:ReadFloat(),
                    y = packet:ReadFloat(),
                    z = packet:ReadFloat(),
                    o = packet:ReadFloat()
                },
                time = packet:ReadULong(),
                seat = packet:ReadByte()
            }

            print("Transport GUID: " .. movementInfo.transport.guid)
            print("Transport Position: x=" .. movementInfo.transport.pos.x .. ", y=" .. movementInfo.transport.pos.y .. ", z=" .. movementInfo.transport.pos.z .. ", o=" .. movementInfo.transport.pos.o)
            print("Transport Time: " .. movementInfo.transport.time)
            print("Transport Seat: " .. movementInfo.transport.seat)
        end

        if packetLength > 56 then -- Adjust this condition based on the actual structure
            movementInfo.fallTime = packet:ReadULong()
            movementInfo.jump = {
                velocity = packet:ReadFloat(),
                sinAngle = packet:ReadFloat(),
                cosAngle = packet:ReadFloat(),
                xySpeed = packet:ReadFloat()
            }

            print("Fall Time: " .. movementInfo.fallTime)
            print("Jump Velocity: " .. movementInfo.jump.velocity)
            print("Jump SinAngle: " .. movementInfo.jump.sinAngle)
            print("Jump CosAngle: " .. movementInfo.jump.cosAngle)
            print("Jump XYSpeed: " .. movementInfo.jump.xySpeed)
        end

        if packetLength > 76 then -- Adjust this condition based on the actual structure
            movementInfo.splineElevation = packet:ReadFloat()
            print("Spline Elevation: " .. movementInfo.splineElevation)
        end
    end
end)
