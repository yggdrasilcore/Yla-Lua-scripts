local MOVE_IMMEDIATELY_RETARGET_DISTANCE = 2
local MOVE_IMMEDIATELY_RETRY_TIME = 1000
local POINT_MOTION_TYPE = 8

function MoveImmediately(player, x, y, z)
    DisableSpellCast(player, 0.2)
    player:RemoveAura(35340)

    local lx = player:Data():Get("MoveImmediatelyX")
    local ly = player:Data():Get("MoveImmediatelyY")
    local lz = player:Data():Get("MoveImmediatelyZ")
    if lx and ly and lz and (x - lx)^2 + (y - ly)^2 + (z - lz)^2 <= MOVE_IMMEDIATELY_RETARGET_DISTANCE^2 then
        -- already walking to this spot: reissuing every tick restarts the spline mid-flight
        if player:GetMovementType() == POINT_MOTION_TYPE then return end
        if GetCurrTime() - (player:Data():Get("MoveImmediatelyTime") or 0) < MOVE_IMMEDIATELY_RETRY_TIME then return end
    end

    player:Data():Set("MoveImmediatelyX", x)
    player:Data():Set("MoveImmediatelyY", y)
    player:Data():Set("MoveImmediatelyZ", z)
    player:Data():Set("MoveImmediatelyTime", GetCurrTime())
    player:MoveTo(1, x, y, z, true)
end
