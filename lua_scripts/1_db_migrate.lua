-- 1_db_migrate.lua
-- One-shot (idempotent, safe to run on every startup) migrater that copies all
-- custom Eluna tables from their legacy databases into ycore_yla.
--
-- Loads first (1_ prefix). Auth tables are looked up in acore_auth, character
-- tables in acore_characters; tables are always created through CharDBExecute
-- so they land in ycore_yla.
--
-- World-state only: every state loads every script, but the copy must run once.
if GetStateMapId() ~= -1 then return end

print("[1_db_migrate] Copying custom tables to ycore_yla...")

-- account_raf
if AuthDBQuery("SELECT 1 FROM information_schema.tables WHERE table_schema = 'acore_auth' AND table_name = 'account_raf' LIMIT 1") then
    CharDBExecute("CREATE TABLE IF NOT EXISTS ycore_yla.account_raf LIKE acore_auth.account_raf")
    CharDBExecute("INSERT IGNORE INTO ycore_yla.account_raf SELECT * FROM acore_auth.account_raf")
end

-- account_raf_claimed
if AuthDBQuery("SELECT 1 FROM information_schema.tables WHERE table_schema = 'acore_auth' AND table_name = 'account_raf_claimed' LIMIT 1") then
    CharDBExecute("CREATE TABLE IF NOT EXISTS ycore_yla.account_raf_claimed LIKE acore_auth.account_raf_claimed")
    CharDBExecute("INSERT IGNORE INTO ycore_yla.account_raf_claimed SELECT * FROM acore_auth.account_raf_claimed")
end

-- accounts_vip
if AuthDBQuery("SELECT 1 FROM information_schema.tables WHERE table_schema = 'acore_auth' AND table_name = 'accounts_vip' LIMIT 1") then
    CharDBExecute("CREATE TABLE IF NOT EXISTS ycore_yla.accounts_vip LIKE acore_auth.accounts_vip")
    CharDBExecute("INSERT IGNORE INTO ycore_yla.accounts_vip SELECT * FROM acore_auth.accounts_vip")
end

-- account_currencies
if CharDBQuery("SELECT 1 FROM information_schema.tables WHERE table_schema = 'acore_characters' AND table_name = 'account_currencies' LIMIT 1") then
    CharDBExecute("CREATE TABLE IF NOT EXISTS ycore_yla.account_currencies LIKE acore_characters.account_currencies")
    CharDBExecute("INSERT IGNORE INTO ycore_yla.account_currencies SELECT * FROM acore_characters.account_currencies")
end

-- accountwide_currency
if CharDBQuery("SELECT 1 FROM information_schema.tables WHERE table_schema = 'acore_characters' AND table_name = 'accountwide_currency' LIMIT 1") then
    CharDBExecute("CREATE TABLE IF NOT EXISTS ycore_yla.accountwide_currency LIKE acore_characters.accountwide_currency")
    CharDBExecute("INSERT IGNORE INTO ycore_yla.accountwide_currency SELECT * FROM acore_characters.accountwide_currency")
end

-- character_cooldowns
if CharDBQuery("SELECT 1 FROM information_schema.tables WHERE table_schema = 'acore_characters' AND table_name = 'character_cooldowns' LIMIT 1") then
    CharDBExecute("CREATE TABLE IF NOT EXISTS ycore_yla.character_cooldowns LIKE acore_characters.character_cooldowns")
    CharDBExecute("INSERT IGNORE INTO ycore_yla.character_cooldowns SELECT * FROM acore_characters.character_cooldowns")
end

-- character_custom_data
if CharDBQuery("SELECT 1 FROM information_schema.tables WHERE table_schema = 'acore_characters' AND table_name = 'character_custom_data' LIMIT 1") then
    CharDBExecute("CREATE TABLE IF NOT EXISTS ycore_yla.character_custom_data LIKE acore_characters.character_custom_data")
    CharDBExecute("INSERT IGNORE INTO ycore_yla.character_custom_data SELECT * FROM acore_characters.character_custom_data")
end

-- character_flight
if CharDBQuery("SELECT 1 FROM information_schema.tables WHERE table_schema = 'acore_characters' AND table_name = 'character_flight' LIMIT 1") then
    CharDBExecute("CREATE TABLE IF NOT EXISTS ycore_yla.character_flight LIKE acore_characters.character_flight")
    CharDBExecute("INSERT IGNORE INTO ycore_yla.character_flight SELECT * FROM acore_characters.character_flight")
end

-- character_gift_events
if CharDBQuery("SELECT 1 FROM information_schema.tables WHERE table_schema = 'acore_characters' AND table_name = 'character_gift_events' LIMIT 1") then
    CharDBExecute("CREATE TABLE IF NOT EXISTS ycore_yla.character_gift_events LIKE acore_characters.character_gift_events")
    CharDBExecute("INSERT IGNORE INTO ycore_yla.character_gift_events SELECT * FROM acore_characters.character_gift_events")
end

-- character_login_transfer
if CharDBQuery("SELECT 1 FROM information_schema.tables WHERE table_schema = 'acore_characters' AND table_name = 'character_login_transfer' LIMIT 1") then
    CharDBExecute("CREATE TABLE IF NOT EXISTS ycore_yla.character_login_transfer LIKE acore_characters.character_login_transfer")
    CharDBExecute("INSERT IGNORE INTO ycore_yla.character_login_transfer SELECT * FROM acore_characters.character_login_transfer")
end

-- character_morphs
if CharDBQuery("SELECT 1 FROM information_schema.tables WHERE table_schema = 'acore_characters' AND table_name = 'character_morphs' LIMIT 1") then
    CharDBExecute("CREATE TABLE IF NOT EXISTS ycore_yla.character_morphs LIKE acore_characters.character_morphs")
    CharDBExecute("INSERT IGNORE INTO ycore_yla.character_morphs SELECT * FROM acore_characters.character_morphs")
end

-- character_rate_xp
if CharDBQuery("SELECT 1 FROM information_schema.tables WHERE table_schema = 'acore_characters' AND table_name = 'character_rate_xp' LIMIT 1") then
    CharDBExecute("CREATE TABLE IF NOT EXISTS ycore_yla.character_rate_xp LIKE acore_characters.character_rate_xp")
    CharDBExecute("INSERT IGNORE INTO ycore_yla.character_rate_xp SELECT * FROM acore_characters.character_rate_xp")
end

-- custom_transmogrification
if CharDBQuery("SELECT 1 FROM information_schema.tables WHERE table_schema = 'acore_characters' AND table_name = 'custom_transmogrification' LIMIT 1") then
    CharDBExecute("CREATE TABLE IF NOT EXISTS ycore_yla.custom_transmogrification LIKE acore_characters.custom_transmogrification")
    CharDBExecute("INSERT IGNORE INTO ycore_yla.custom_transmogrification SELECT * FROM acore_characters.custom_transmogrification")
    CharDBExecute("ALTER TABLE ycore_yla.custom_transmogrification MODIFY `GUID` BIGINT UNSIGNED NOT NULL")
end

-- custom_transmogrification_sets
if CharDBQuery("SELECT 1 FROM information_schema.tables WHERE table_schema = 'acore_characters' AND table_name = 'custom_transmogrification_sets' LIMIT 1") then
    CharDBExecute("CREATE TABLE IF NOT EXISTS ycore_yla.custom_transmogrification_sets LIKE acore_characters.custom_transmogrification_sets")
    CharDBExecute("INSERT IGNORE INTO ycore_yla.custom_transmogrification_sets SELECT * FROM acore_characters.custom_transmogrification_sets")
end

-- statistics
if CharDBQuery("SELECT 1 FROM information_schema.tables WHERE table_schema = 'acore_characters' AND table_name = 'statistics' LIMIT 1") then
    CharDBExecute("CREATE TABLE IF NOT EXISTS ycore_yla.statistics LIKE acore_characters.statistics")
    CharDBExecute("INSERT IGNORE INTO ycore_yla.statistics SELECT * FROM acore_characters.statistics")
end

print("[1_db_migrate] Done.")
