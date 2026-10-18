-- 1_db_migrate.lua
-- One-shot (idempotent, safe to run on every startup) migrater that copies all
-- custom Eluna tables from their legacy databases into acore_eluna.
--
-- Loads first (1_ prefix). Each COPY keeps the original query DB type so the
-- unqualified source resolves in the connection's default DB:
--   AuthDB*  -> acore_auth, CharDB* -> acore_characters, WorldDB* -> acore_world
-- silicon: CREATE TABLE ... LIKE is a schema-only copy; INSERT IGNORE copies rows.
-- Fresh installs (source missing): LIKE fails harmlessly, feature scripts below
-- create the acore_eluna table empty via their rewritten CREATE TABLE IF NOT EXISTS.
--
-- World-state only: every state loads every script, but the copy must run once.
-- GetStateMapId() == -1 in the world state (and in compatibility mode).
if GetStateMapId() ~= -1 then return end

local AUTH_TABLES = {
    "account_raf",
    "account_raf_claimed",
    "accounts_vip",
}

local CHAR_TABLES = {
    "account_currencies",
    "accountwide_currency",
    "character_cooldowns",
    "character_custom_data",
    "character_flight",
    "character_gift_events",
    "character_login_transfer",
    "character_morphs",
    "character_rate_xp",
    "custom_transmogrification",
    "custom_transmogrification_sets",
    "shadows_bots",
    "statistics",
}

local function Migrate(exec, tbl)
    exec(string.format(
        "CREATE TABLE IF NOT EXISTS acore_eluna.%s LIKE %s", tbl, tbl))
    exec(string.format(
        "INSERT IGNORE INTO acore_eluna.%s SELECT * FROM %s", tbl, tbl))
end

print("[1_db_migrate] Copying custom tables to acore_eluna...")

for _, tbl in ipairs(AUTH_TABLES) do
    Migrate(AuthDBExecute, tbl)
end

for _, tbl in ipairs(CHAR_TABLES) do
    Migrate(CharDBExecute, tbl)
end

print("[1_db_migrate] Done.")
