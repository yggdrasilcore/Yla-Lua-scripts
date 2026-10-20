/*
SQLyog Community v13.3.1 (64 bit)
MySQL - 8.3.0 : Database - ycore_yla
*********************************************************************
*/

/*!40101 SET NAMES utf8 */;

/*!40101 SET SQL_MODE=''*/;

/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
CREATE DATABASE /*!32312 IF NOT EXISTS*/`ycore_yla` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `ycore_yla`;

/*Table structure for table `account_currencies` */

DROP TABLE IF EXISTS `account_currencies`;

CREATE TABLE `account_currencies` (
  `id` int NOT NULL,
  `vp` int DEFAULT NULL,
  `dp` int DEFAULT NULL,
  `total_votes` int DEFAULT NULL,
  `location` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `nickname` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `language` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `avatar` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

/*Table structure for table `account_raf` */

DROP TABLE IF EXISTS `account_raf`;

CREATE TABLE `account_raf` (
  `account_id` int NOT NULL,
  `referer_id` int DEFAULT NULL,
  `status` int DEFAULT NULL,
  `progress` int DEFAULT '0',
  `date` int DEFAULT NULL,
  `IP` varchar(15) DEFAULT NULL,
  `IP_referer` varchar(15) DEFAULT NULL,
  PRIMARY KEY (`account_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Table structure for table `account_raf_claimed` */

DROP TABLE IF EXISTS `account_raf_claimed`;

CREATE TABLE `account_raf_claimed` (
  `account_id` int DEFAULT NULL,
  `claimed` int DEFAULT NULL,
  `date` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Table structure for table `accounts_vip` */

DROP TABLE IF EXISTS `accounts_vip`;

CREATE TABLE `accounts_vip` (
  `ACCOUNT` int NOT NULL,
  `VIPTIME` int NOT NULL,
  PRIMARY KEY (`ACCOUNT`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Table structure for table `accountwide_currency` */

DROP TABLE IF EXISTS `accountwide_currency`;

CREATE TABLE `accountwide_currency` (
  `accountId` int NOT NULL,
  `currencyId` int NOT NULL,
  `count` int NOT NULL,
  PRIMARY KEY (`accountId`,`currencyId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

/*Table structure for table `character_cooldowns` */

DROP TABLE IF EXISTS `character_cooldowns`;

CREATE TABLE `character_cooldowns` (
  `guid` int unsigned NOT NULL,
  `item_id` int unsigned NOT NULL,
  `cooldown_end` int unsigned NOT NULL,
  PRIMARY KEY (`guid`,`item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

/*Table structure for table `character_custom_data` */

DROP TABLE IF EXISTS `character_custom_data`;

CREATE TABLE `character_custom_data` (
  `guid` int unsigned NOT NULL,
  `type` tinyint unsigned NOT NULL,
  `time` int unsigned NOT NULL,
  `data` blob NOT NULL,
  PRIMARY KEY (`guid`,`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Table structure for table `character_flight` */

DROP TABLE IF EXISTS `character_flight`;

CREATE TABLE `character_flight` (
  `guid` int unsigned NOT NULL,
  `standardmount` int unsigned DEFAULT NULL,
  `X` float DEFAULT NULL,
  `Y` float DEFAULT NULL,
  `Z` float DEFAULT NULL,
  `O` float DEFAULT NULL,
  `var1` int unsigned DEFAULT NULL,
  `var2` int unsigned DEFAULT NULL,
  `var3` int unsigned DEFAULT NULL,
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Table structure for table `character_gift_events` */

DROP TABLE IF EXISTS `character_gift_events`;

CREATE TABLE `character_gift_events` (
  `guid` int NOT NULL,
  `event` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `awarded` tinyint(1) NOT NULL,
  `date` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

/*Table structure for table `character_instance_vendor_reset` */

DROP TABLE IF EXISTS `character_instance_vendor_reset`;

CREATE TABLE `character_instance_vendor_reset` (
  `guid` int NOT NULL,
  `time` int NOT NULL,
  `count` int DEFAULT '0',
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Table structure for table `character_login_transfer` */

DROP TABLE IF EXISTS `character_login_transfer`;

CREATE TABLE `character_login_transfer` (
  `guid` int DEFAULT NULL,
  `itemid` int DEFAULT NULL,
  `count` int DEFAULT NULL,
  `type` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

/*Table structure for table `character_morphs` */

DROP TABLE IF EXISTS `character_morphs`;

CREATE TABLE `character_morphs` (
  `guid` int DEFAULT NULL,
  `name` text,
  `id` int DEFAULT NULL,
  `form` int DEFAULT NULL,
  `active` smallint DEFAULT NULL,
  UNIQUE KEY `unique_guid_form` (`guid`,`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Table structure for table `character_rate_xp` */

DROP TABLE IF EXISTS `character_rate_xp`;

CREATE TABLE `character_rate_xp` (
  `guid` int unsigned NOT NULL,
  `rate` int NOT NULL DEFAULT '0',
  `max_paid_rate` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

/*Table structure for table `command_queue` */

DROP TABLE IF EXISTS `command_queue`;

CREATE TABLE `command_queue` (
  `command` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `inserted` int NOT NULL,
  `executed` int DEFAULT NULL,
  `comment` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Table structure for table `custom_transmogrification` */

DROP TABLE IF EXISTS `custom_transmogrification`;

CREATE TABLE `custom_transmogrification` (
  `GUID` int unsigned NOT NULL COMMENT 'Item guidLow',
  `FakeEntry` int unsigned NOT NULL COMMENT 'Item entry',
  `Owner` int unsigned NOT NULL COMMENT 'Player guidLow',
  PRIMARY KEY (`GUID`),
  KEY `Owner` (`Owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='6_2';

/*Table structure for table `custom_transmogrification_sets` */

DROP TABLE IF EXISTS `custom_transmogrification_sets`;

CREATE TABLE `custom_transmogrification_sets` (
  `Owner` int unsigned NOT NULL COMMENT 'Player guidlow',
  `PresetID` tinyint unsigned NOT NULL COMMENT 'Preset identifier',
  `SetName` text COMMENT 'SetName',
  `SetData` text COMMENT 'Slot1 Entry1 Slot2 Entry2',
  PRIMARY KEY (`Owner`,`PresetID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='6_1';

/*Table structure for table `disable_shadows_spells` */

DROP TABLE IF EXISTS `disable_shadows_spells`;

CREATE TABLE `disable_shadows_spells` (
  `guid` int unsigned NOT NULL,
  `spell_id` int unsigned NOT NULL,
  PRIMARY KEY (`guid`,`spell_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Table structure for table `legacy_transfer_queue` */

DROP TABLE IF EXISTS `legacy_transfer_queue`;

CREATE TABLE `legacy_transfer_queue` (
  `command` text NOT NULL,
  `inserted` int NOT NULL,
  `guid` int DEFAULT NULL,
  `comment` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Table structure for table `persistent_storage` */

DROP TABLE IF EXISTS `persistent_storage`;

CREATE TABLE `persistent_storage` (
  `entry` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `value` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `comment` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  PRIMARY KEY (`entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Table structure for table `shadows_bots` */

DROP TABLE IF EXISTS `shadows_bots`;

CREATE TABLE `shadows_bots` (
  `bot_name` varchar(12) NOT NULL,
  `master_name` varchar(12) NOT NULL,
  PRIMARY KEY (`bot_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Table structure for table `statistics` */

DROP TABLE IF EXISTS `statistics`;

CREATE TABLE `statistics` (
  `event` varchar(32) NOT NULL,
  `param1` int unsigned DEFAULT NULL,
  `param2` varchar(32) DEFAULT NULL,
  `param3` int unsigned DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
