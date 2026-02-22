function MoveImmediately(player, x, y, z)
    DisableSpellCast(player, 0.2)
    player:RemoveAura(35340)
    player:MoveTo(1, x, y, z, true)
end