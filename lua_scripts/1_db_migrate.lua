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

--[[
DROP TABLE IF EXISTS `acore_auth`.`acore_cms_subscriptions`;
DROP TABLE IF EXISTS `acore_characters`.`accountwide_achievements`;
DROP TABLE IF EXISTS `acore_characters`.`accountwide_money`;
DROP TABLE IF EXISTS `acore_characters`.`accountwide_mounts`;
DROP TABLE IF EXISTS `acore_characters`.`accountwide_pets`;
DROP TABLE IF EXISTS `acore_characters`.`accountwide_reputation`;
DROP TABLE IF EXISTS `acore_characters`.`auctionbidders`;
DROP TABLE IF EXISTS `acore_characters`.`character_battleground_data`;
DROP TABLE IF EXISTS `acore_characters`.`character_fishingsteps`;
DROP TABLE IF EXISTS `acore_characters`.`character_flying`;
DROP TABLE IF EXISTS `acore_characters`.`character_xp_rate`;
DROP TABLE IF EXISTS `acore_characters`.`custom_unlocked_appearances`;
DROP TABLE IF EXISTS `acore_characters`.`__del_ability_spell`;
DROP TABLE IF EXISTS `acore_characters`.`__del_override_spell`;
DROP TABLE IF EXISTS `acore_characters`.`__del_shapeshift_spell`;
DROP TABLE IF EXISTS `acore_characters`.`__del_spell_learn_spell`;
DROP TABLE IF EXISTS `acore_characters`.`__del_spells_with_learn_effect`;
DROP TABLE IF EXISTS `acore_characters`.`__del_talent_pyroblast`;
DROP TABLE IF EXISTS `acore_characters`.`__del_talent_pyroblast2`;
DROP TABLE IF EXISTS `acore_characters`.`__del_talent_rest_ranks`;
DROP TABLE IF EXISTS `acore_characters`.`gm_subsurveys`;
DROP TABLE IF EXISTS `acore_characters`.`group_instance`;
DROP TABLE IF EXISTS `acore_characters`.`InstanceFaction`;
DROP TABLE IF EXISTS `acore_characters`.`item_loot_items`;
DROP TABLE IF EXISTS `acore_characters`.`item_loot_money`;
DROP TABLE IF EXISTS `acore_characters`.`__playercreateinfo_spell`;
DROP TABLE IF EXISTS `acore_characters`.`__profession_autolearn`;
DROP TABLE IF EXISTS `acore_characters`.`__profession_skill`;
DROP TABLE IF EXISTS `acore_characters`.`__profession_spell_req_skill`;
DROP TABLE IF EXISTS `acore_characters`.`__profession_spell_req_spell`;
DROP TABLE IF EXISTS `acore_characters`.`__spell_ranks`;
DROP TABLE IF EXISTS `acore_characters`.`transferlog`;
DROP TABLE IF EXISTS `acore_characters`.`transferredspells`;
DROP TABLE IF EXISTS `acore_world`.`access_requirement`;
DROP TABLE IF EXISTS `acore_world`.`battlefield_template`;
DROP TABLE IF EXISTS `acore_world`.`creature_default_trainer`;
DROP TABLE IF EXISTS `acore_world`.`creature_movement_info`;
DROP TABLE IF EXISTS `acore_world`.`gameobject_overrides`;
DROP TABLE IF EXISTS `acore_world`.`instance_spawn_groups`;
DROP TABLE IF EXISTS `acore_world`.`mod_auctionhousebot`;
DROP TABLE IF EXISTS `acore_world`.`mod_auctionhousebot_disabled_items`;
DROP TABLE IF EXISTS `acore_world`.`playerbots_rpg_races`;
DROP TABLE IF EXISTS `acore_world`.`player_classlevelstats`;
DROP TABLE IF EXISTS `acore_world`.`player_levelstats`;
DROP TABLE IF EXISTS `acore_world`.`pool_members`;
DROP TABLE IF EXISTS `acore_world`.`quest_pool_members`;
DROP TABLE IF EXISTS `acore_world`.`quest_pool_template`;
DROP TABLE IF EXISTS `acore_world`.`script_spline_chain_meta`;
DROP TABLE IF EXISTS `acore_world`.`script_spline_chain_waypoints`;
DROP TABLE IF EXISTS `acore_world`.`spawn_group`;
DROP TABLE IF EXISTS `acore_world`.`spawn_group_template`;
DROP TABLE IF EXISTS `acore_world`.`spell_dbc_bck`;
DROP TABLE IF EXISTS `acore_world`.`trainer_locale`;
DROP TABLE IF EXISTS `acore_world`.`trinity_string`;
DROP TABLE IF EXISTS `acore_world`.`vehicleseat_dbc_copy`;
DROP TABLE IF EXISTS `acore_world`.`vehicle_template`;
DROP TABLE IF EXISTS `acore_world`.`vw_conditions_with_labels`;
DROP TABLE IF EXISTS `acore_world`.`vw_disables_with_labels`;
DROP TABLE IF EXISTS `acore_world`.`vw_smart_scripts_with_labels`;
DROP TABLE IF EXISTS `acore_world`.`trainer`;
DROP TABLE IF EXISTS `acore_world`.`trainer_spell`;
DROP TABLE IF EXISTS `acore_world`.`spell_learn_spell`;
DROP TABLE IF EXISTS `acore_world`.`icons`;
DROP TABLE IF EXISTS `acore_eluna`.`icons`;
--]]