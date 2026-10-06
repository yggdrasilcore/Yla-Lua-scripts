-- Multistate: Northrend-only script (map 571).
if not IsCompatibilityMode() and GetStateMapId() ~= 571 then return end

local FLYING_MOUNTS = {
   3363, 8153, 32235, 32239, 32240,
   32242, 32243, 32244, 32245, 32246, 32289, 32290, 32292, 32295, 32296, 32297, 32345,
   33943, 37015, 39798, 39800, 39801, 39802, 39803, 39910, 40120, 40192,
   40212, 41513, 41514, 41515, 41516, 41517, 41518, 42667, 42668, 42673, 42679, 43810,
   43927, 44151, 44153, 44317, 44655, 44744, 44824, 44825, 44827, 46197, 46199,
   47037, 48023, 49193, 51617, 51960, 54726, 54727, 54729, 54903, 58615,
   59567, 59568, 59569, 59570, 59571, 59650, 59961, 59976, 59996, 60002, 60021, 60024, 60025,
   60099, 61229, 61230, 61289, 61294, 61309, 61442, 61444, 61446, 61451,
   61996, 61997, 62048, 63796, 63844, 63956, 63963, 64927, 65439, 66087,
   66088, 67336, 69395, 71346, 71347, 71810, 72283, 72284, 72807, 72808, 74854, 74855,
   75596, 75617, 75618, 76153, 75973, 75972, 75957
}

local function OnLeaveWintergrasp(event, player, oldArea, newArea)
    if oldArea == 4584
	or (oldArea == 4197 and newArea == 3711)
	or (oldArea == 4197 and newArea == 210)
	or (oldArea == 4197 and newArea == 65)
	or (oldArea == 4197 and newArea == 4163)
	or (oldArea == 4197 and newArea == 4034)
	or (oldArea == 4197 and newArea == 4125)
	or (oldArea == 4197 and newArea == 4034)
	or (oldArea == 4197 and newArea == 4124)
	or (oldArea == 4575 and newArea == 210)
	or (oldArea == 4585 and newArea == 210)
	or (oldArea == 4585 and newArea == 4172)
	then
		if not player:IsPvPFlagged() then return end

		for _, id in ipairs(FLYING_MOUNTS) do
			if player:HasAura(id) then return end
		end

		local x = player:GetX()
		local y = player:GetY()
		local z = player:GetZ()
		local mapHeight = player:GetMap():GetHeight(x, y)

		if z >= (mapHeight + 2) then
			player:SetPvP(false)
		end
	end
end

RegisterPlayerEvent(47, OnLeaveWintergrasp)