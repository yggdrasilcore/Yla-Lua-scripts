local function FixSharkPath(event, creature)
	creature:NearTeleport(creature:GetX(),creature:GetY(),creature:GetZ()-5,creature:GetO())
	creature:MoveRandom(20)
end

RegisterCreatureEvent(29392, 5, FixSharkPath)
