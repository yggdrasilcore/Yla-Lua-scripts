if GetStateMapId() == -1 then return end

local MOUNTS_60 = {
458,459,468,470,471,472,578,580,581,6648,6653,6654,6777,6896,6897,6898,6899,8394,8395,8980,10787,10788,10789,10790,10792,10793,10795,10796,10798,10799,10873,10969,15780,15781,16058,16059,16060,17453,17454,17455,17456,17458,17462,17463,17464,18363,18989,18990,25858,33630,34406,34795,35018,35020,35022,35710,35711,42776,43899,49378,50869,50870,51621,64657,64658,64731,64977,66847
}

local MOUNTS_100 = {
72286,61469,61470,61467,61465,61447,61425,60140,60136,59804,59802,59799,59797,59791,59793,59788,59785,36702,579,15779,16055,16056,16080,16081,16082,16084,17229,17450,17459,17460,17461,17465,18991,18992,22717,22718,22719,22720,22721,22722,22723,22724,23219,23220,23221,23227,23228,23229,23238,23239,23240,23241,23242,23243,23246,23247,23248,23249,23250,23251,23252,23338,23509,23510,24576,25859,25863,26655,26656,29059,33660,34407,34790,34896,34897,34898,34899,35025,35027,35028,35712,35713,35714,39315,39316,39317,39318,39319,39450,42777,43688,43900,46980,47037,48024,48027,48778,48954,49322,49379,50281,51412,54753,55293,58819,59572,59573,59785,59788,59791,59793,59797,59799,59802,59804,60114,60116,60118,60119,60136,60140,63232,63635,63636,63637,63638,63639,63640,63641,63642,63643,64656,64659,65637,65638,65639,65640,65641,65642,65643,65644,65645,65646,66090,66091,66122,66123,66124,66846,67466,68056,68057,68187,68188,73313,74918
}

local function GetFirstKnownMount(player, mountList)
    local order = {}
    for i, v in ipairs(mountList) do order[i] = v end
    for i = #order, 2, -1 do
        local j = math.random(i)
        order[i], order[j] = order[j], order[i]
    end
    for _, spellId in ipairs(order) do
        if player:HasSpell(spellId) then
            return spellId
        end
    end
    return nil
end

local function CastMatchingMasterMount(player, master, spell)
    local has100 = false
    for _, formSpell in pairs({33391, 34090, 34091}) do
        if master:HasSpell(formSpell) and player:HasSpell(formSpell) then
            has100 = true
            break
        end
    end

    local chosenSpellId
    if has100 then
        chosenSpellId = GetFirstKnownMount(player, MOUNTS_100)
    elseif player:HasSpell(33388) then
        chosenSpellId = GetFirstKnownMount(player, MOUNTS_60)
    end

    if chosenSpellId then
        if spell then player:StopSpellCast(spell:GetEntry()) end
        player:CastSpell(player, chosenSpellId, false)
        return true
    end

    return false
end

local function OnPrepareRidingTurtle(event, player, spell)
    if not player:IsBot() then return end

    local shadow = player:ToShadow()
    local master = shadow and shadow:GetMaster()
    if not master then return end
    if master:GetMapId() ~= player:GetMapId() or master:GetInstanceId() ~= player:GetInstanceId() then return end

    if not master:IsMounted() then return end
    CastMatchingMasterMount(player, master, spell)
end

RegisterSpellEvent(30174, 1, OnPrepareRidingTurtle)

local function OnPrepareSeaTurtle(event, player, spell)
    if not player:IsBot() then return end
    if player:IsInWater() then return end

    local shadow = player:ToShadow()
    local master = shadow and shadow:GetMaster()
    if not master then return end
    if master:GetMapId() ~= player:GetMapId() or master:GetInstanceId() ~= player:GetInstanceId() then return end

    if not master:IsMounted() then return end
    CastMatchingMasterMount(player, master, spell)
end

RegisterSpellEvent(64731, 1, OnPrepareSeaTurtle)