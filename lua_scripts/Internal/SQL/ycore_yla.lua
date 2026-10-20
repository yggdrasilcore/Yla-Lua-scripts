local M = {}

local function Escape(value)
    return tostring(value):gsub("'", "''")
end

local function EnsureUpdatesTable()
    CharDBQuery([[
        CREATE TABLE IF NOT EXISTS ycore_yla.updates (
            `name` varchar(255) NOT NULL,
            `run` int unsigned NOT NULL,
            PRIMARY KEY (`name`)
        )
    ]])
end

local function HasRun(name)
    return CharDBQuery(string.format(
        "SELECT 1 FROM ycore_yla.updates WHERE name = '%s' LIMIT 1",
        Escape(name))) ~= nil
end

local function MarkRun(name)
    local run = os.time()

    CharDBQueryAsync(string.format(
        "INSERT INTO ycore_yla.updates (name, run) VALUES ('%s', %d)",
        Escape(name), run), function()
        CharDBQueryAsync(string.format(
            "SELECT name, run FROM ycore_yla.updates WHERE name = '%s' LIMIT 1",
            Escape(name)), function(result)
            if not result then
                print(string.format(
                    "[ycore_yla] ERROR: %s was not inserted into ycore_yla.updates",
                    name))
                return
            end

            local storedName = result:GetString(0)
            local storedRun = result:GetUInt32(1)
            if storedName == name and storedRun == run then
                print(string.format("[ycore_yla] Executed %s", name))
                RunCommand(".server restart 5")
            else
                print(string.format(
                    "[ycore_yla] ERROR: %s verification failed (expected %s/%d, found %s/%d)",
                    name, name, run, tostring(storedName), storedRun))
            end
        end)
    end)
end

function M.updates(name, fn)
    EnsureUpdatesTable()

    if HasRun(name) then
        print("[ycore_yla] Skipping " .. name .. " (already run)")
        return
    end

    print("[ycore_yla] Running " .. name)
    fn()
    MarkRun(name)
end

if GetStateMapId() ~= -1 then
    M.updates = function() end
end

return M
