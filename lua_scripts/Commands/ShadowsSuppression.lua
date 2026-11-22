-- Manual override of shadow movement/targeting suppression.

local SUPPRESS_MS = 900000

local function SelectedBot(player)
    local unit = player:GetSelection()
    if not unit or not unit:IsPlayer() or not unit:IsBot() then
        player:SendBroadcastMessage("Target not a bot, cannot proceed")
        return nil
    end
    return unit
end

local function OnCommand(event, player, command)
    if command == "stoptargeting" then
        local bot = SelectedBot(player)
        if bot then
            bot:ToShadow():SuppressTargeting(SUPPRESS_MS)
            player:SendBroadcastMessage("Bot "..bot:GetName().." targeting suppressed.")
        end
        return false
    end

    if command == "starttargeting" then
        local bot = SelectedBot(player)
        if bot then
            if not bot:ToShadow():IsTargetingSuppressed() then
                player:SendBroadcastMessage("Bot "..bot:GetName().." targeting is not suppressed.")
            else
                bot:ToShadow():ClearTargetingSuppression()
                player:SendBroadcastMessage("Bot "..bot:GetName().." targeting suppression cleared.")
            end
        end
        return false
    end

    if command == "stopmovement" then
        local bot = SelectedBot(player)
        if bot then
            bot:ToShadow():SuppressMovement(SUPPRESS_MS)
            player:SendBroadcastMessage("Bot "..bot:GetName().." movement suppressed.")
        end
        return false
    end

    if command == "startmovement" then
        local bot = SelectedBot(player)
        if bot then
            if not bot:ToShadow():IsMovementSuppressed() then
                player:SendBroadcastMessage("Bot "..bot:GetName().." movement is not suppressed.")
            else
                bot:ToShadow():ClearMovementSuppression()
                player:SendBroadcastMessage("Bot "..bot:GetName().." movement suppression cleared.")
            end
        end
        return false
    end

    if command == "suppressionstatus" then
        local bot = SelectedBot(player)
        if bot then
            local shadow = bot:ToShadow()
            player:SendBroadcastMessage("Bot "..bot:GetName()..": targeting "..
                (shadow:IsTargetingSuppressed() and "suppressed" or "not suppressed")..
                ", movement "..
                (shadow:IsMovementSuppressed() and "suppressed" or "not suppressed"))
        end
        return false
    end
end

RegisterPlayerEvent(42, OnCommand)
