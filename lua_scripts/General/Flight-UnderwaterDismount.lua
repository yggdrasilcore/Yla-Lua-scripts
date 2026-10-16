if GetStateMapId() ~= -1 then return end

local BUFFIDS = {
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
    75596, 75617, 75618, 76153
}

local function OnTimer(event, packet, player)
    if not player then
        return
    end
    
    local opcode = packet:GetOpcode()
    local guid = player:GetGUIDLow()

    local timer = packet:ReadULong()      -- Read Timer as unsigned 32-bit
    local value = packet:ReadULong()      -- Read Value as unsigned 32-bit
    local maxValue = packet:ReadULong()   -- Read MaxValue as unsigned 32-bit
    local scale = packet:ReadLong()       -- Read Scale as signed 32-bit
    local paused = packet:ReadByte() > 0  -- Read Paused (bool), assuming 0 is false
    local spellID = packet:ReadULong()    -- Read SpellID as unsigned 32-bit

    if timer == 1 and scale == -1 then -- Timer 1 is swimming, scale -1 means "start breath timer"
        for _, id in ipairs(BUFFIDS) do
            if player:HasAura(id) then
                player:RemoveAura(id)
            end
        end
    end
end

RegisterPacketEvent(0x1D9, 7, OnTimer)
					