function IsAtPos(unit, x, y, tolerance)
    local ux, uy, uz = unit:GetLocation()
    return math.abs(ux - x) <= tolerance and math.abs(uy - y) <= tolerance
end