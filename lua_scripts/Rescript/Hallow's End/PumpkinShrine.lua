local horsemanTimer = {}

function PumpkinGossip(event, player, gameObject, sender, action)
    if not horsemanTimer[player:GetInstanceId()] then
        horsemanTimer[player:GetInstanceId()] = os.time() - 1
    end
    if (horsemanTimer[player:GetInstanceId()] < os.time()) then
        horsemanTimer[player:GetInstanceId()] = os.time() + 17
        player:GossipComplete()

        -- Check if Horseman already exists nearby
        if player:GetNearestCreature(23682, 100) then
            return false
        end

        -- Summon the Horseman
        local horseman = gameObject:SpawnCreature(23682, 1754.00, 1346.00, 17.50, 0.0, 8)
        print("ELUNA, "..player:GetName().." summoning horseman...")
        if horseman then
            horseman:CastSpell(player, 42878, true)
        else
            print("Error spawning headless horseman!")
        end
    end
    print("ELUNA Horseman Pumpkin Shrine, returning false")
    return false
end

RegisterGameObjectGossipEvent(186267, 2, PumpkinGossip)

WorldDBExecute("UPDATE gameobject_template SET ScriptName = '' WHERE entry = 186267")