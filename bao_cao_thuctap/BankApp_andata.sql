-- MySQL dump 10.13  Distrib 8.0.42, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: bank_users
-- ------------------------------------------------------
-- Server version	8.0.42

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `PinCodes`
--

DROP TABLE IF EXISTS `PinCodes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `PinCodes` (
  `Id` int NOT NULL AUTO_INCREMENT,
  `OwnerType` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `OwnerId` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `PinHash` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `FailedAttempts` int NOT NULL,
  `IsLocked` tinyint(1) NOT NULL,
  `LastChanged` datetime(6) NOT NULL,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `PinCodes`
--

LOCK TABLES `PinCodes` WRITE;
/*!40000 ALTER TABLE `PinCodes` DISABLE KEYS */;
INSERT INTO `PinCodes` VALUES (1,'account','fd6365f5-4923-4f46-a0f8-5b6fd01cbf4e','$2a$11$IZB4lWY3AqFDvuekgcbEaugChU09HeTow1Ca47lIckHKDOAniPSem',0,0,'2025-08-08 01:16:31.230558'),(2,'account','0bfe4aab-c87c-4fa7-b2e5-12856dbdfe7a','$2a$11$kOafajmBQCJhbXBDjX23KOAMGV1aZodzw1z1XE6BGoPIBulvolyqO',0,0,'2025-08-08 02:50:47.267210'),(3,'account','0a09525c-b448-4a8b-979d-73805d54b860','$2a$11$0epAPuh92hNbUL8.LR9GRu/ouWn0N6nYy.CEJMc/nU3k590CyLuM.',0,0,'2025-08-08 04:18:02.852638'),(4,'account','32ee1af4-7ecc-4c50-8dc3-691adc501874','$2a$11$N4oIWdWV/ssWgxV5l644vOq500s738dWg/I1S6SavlA0tHWhw6tY2',0,0,'2025-08-08 06:42:22.174120'),(5,'account','bb4b7c4f-9faa-4797-8caf-59dde7ae55a1','$2a$11$I6FI7mtogXFFOnq6vntvtu.UBSNTGShOKsl1k8LBGM6yyfTbakuM6',0,0,'2025-08-08 07:33:38.948426'),(6,'account','4fd2505f-9ba5-4684-b7af-d4914eabc3b7','$2a$11$XoSLCXPG94v4Q66VsKA7FuHnhOSkhbb5jotAa0oUCghsMO.iacDx.',0,0,'2025-08-08 07:39:32.035040'),(7,'account','15c2da7f-40dd-469f-93fc-ea0d364c85bb','$2a$11$u270qu8/oSFg4tST2Y5X5OLFyH1A/RX4NLDX4rvKF0h2SECeyL4.u',0,0,'2025-08-10 15:18:42.436910');
/*!40000 ALTER TABLE `PinCodes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `RefreshTokens`
--

DROP TABLE IF EXISTS `RefreshTokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `RefreshTokens` (
  `Id` int NOT NULL AUTO_INCREMENT,
  `Token` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `ExpiryDate` datetime(6) NOT NULL,
  `UserId` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  PRIMARY KEY (`Id`),
  KEY `IX_RefreshTokens_UserId` (`UserId`),
  CONSTRAINT `FK_RefreshTokens_users_UserId` FOREIGN KEY (`UserId`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=54 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `RefreshTokens`
--

LOCK TABLES `RefreshTokens` WRITE;
/*!40000 ALTER TABLE `RefreshTokens` DISABLE KEYS */;
INSERT INTO `RefreshTokens` VALUES (35,'14dc3260-f838-4887-b1b2-df37543ad9cc','2025-08-15 02:49:11.574454','e47a4e22-e1fe-4fc5-add1-62159b4d66ee'),(36,'edb7d379-cb26-4822-af11-b6d6d8ccb647','2025-08-15 03:17:32.493205','1c1dc249-2fd8-4a31-a833-519b9cc3e20f'),(48,'2c390866-dc47-4984-a50d-25750008fa2b','2025-08-15 06:12:01.304852','880e0542-cc29-4032-893c-4436dc784139'),(49,'292f3f09-17a2-4e06-8722-3c6704c7b09d','2025-08-15 06:42:03.172704','f8bcd120-b657-4aec-8317-2672852741fe'),(51,'6ef2f5ac-d6ef-4582-92f4-917f953fa205','2025-08-15 07:33:11.085927','88fccf1b-a44d-46c1-b6a9-9d24ad3c4e4a'),(52,'dab4784f-1d40-4ef1-b843-1b5543403d75','2025-08-15 07:39:05.625938','bdf67cb5-f387-4959-937c-8f1cb5362e15'),(53,'4971416a-99ba-4423-9499-f4a0001465ef','2025-08-17 15:18:31.719125','a8dff327-3d5a-4671-b07d-7a165296d441');
/*!40000 ALTER TABLE `RefreshTokens` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `__EFMigrationsHistory`
--

DROP TABLE IF EXISTS `__EFMigrationsHistory`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `__EFMigrationsHistory` (
  `MigrationId` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `ProductVersion` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  PRIMARY KEY (`MigrationId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `__EFMigrationsHistory`
--

LOCK TABLES `__EFMigrationsHistory` WRITE;
/*!40000 ALTER TABLE `__EFMigrationsHistory` DISABLE KEYS */;
INSERT INTO `__EFMigrationsHistory` VALUES ('20250807064357_InitClean','8.0.0'),('20250807093058_AddPinCodeTable','8.0.0');
/*!40000 ALTER TABLE `__EFMigrationsHistory` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `accounts`
--

DROP TABLE IF EXISTS `accounts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `accounts` (
  `account_id` varchar(36) NOT NULL,
  `customer_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `type` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
  `label` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
  `balance` decimal(18,2) NOT NULL,
  `currency` char(3) NOT NULL,
  `bank_code` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
  `account_number` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `status` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `created_at` datetime(6) NOT NULL,
  PRIMARY KEY (`account_id`),
  KEY `IX_accounts_customer_id` (`customer_id`),
  CONSTRAINT `FK_accounts_customers_customer_id` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`customer_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `accounts`
--

LOCK TABLES `accounts` WRITE;
/*!40000 ALTER TABLE `accounts` DISABLE KEYS */;
INSERT INTO `accounts` VALUES ('0a09525c-b448-4a8b-979d-73805d54b860','b15c96d4-0205-4ee7-8ace-ad3e6fd6b4cf','CURRENT','Tài khoản CURRENT',100000.00,'VND','9704','9704255259860','active','2025-08-08 03:20:59.648683'),('15c2da7f-40dd-469f-93fc-ea0d364c85bb','e80fad51-bce4-47d6-b584-fa8b101ce6d5','CURRENT','Tài khoản CURRENT',100000.00,'VND','1024','1024869606','active','2025-08-10 12:28:44.394660'),('2d00a02c-5b1d-4af9-bf8a-9ccd66c576e3','e0c41f5b-0963-42fd-b383-2fa08b72bc6a','CURRENT','Tài khoản CURRENT',100000.00,'VND','1024','1024333333','active','2025-08-11 01:27:04.621885'),('32ee1af4-7ecc-4c50-8dc3-691adc501874','6f722050-50d5-4986-ac1d-4254b87df2e4','CURRENT','Tài khoản CURRENT',100000.00,'VND','9704','9704259014132','active','2025-08-08 06:41:22.773575'),('4f9334c8-81e7-4673-b652-534e9f2b79c3','4224b71d-15eb-4313-b31d-fbe5ba1da7f4','CURRENT','Tài khoản CURRENT',100000.00,'VND','1024','1024868686','active','2025-08-10 10:45:56.099338'),('4fd2505f-9ba5-4684-b7af-d4914eabc3b7','9a19bc45-37af-4658-9432-18de5666b05c','CURRENT','Tài khoản CURRENT',100000.00,'VND','9704','9704374484136','active','2025-08-08 07:38:11.081346'),('57a6d5ac-4f22-4117-970e-d80f32e5d8a1','39c217ec-26a8-4adb-9b67-57852578ec4b','CURRENT','Tài khoản CURRENT',100000.00,'VND','9704','9704347650474','active','2025-08-08 07:54:51.905219'),('a33932a6-9054-4605-9a0e-c52f21ed8f35','ab6173a1-78b5-4bc2-a80f-773263cda1be','CURRENT','Tài khoản CURRENT',100000.00,'VND','9704','9704611650106','active','2025-08-08 03:16:57.721466'),('bb4b7c4f-9faa-4797-8caf-59dde7ae55a1','7e16ee38-5c4d-4c74-9afb-92c842364f24','CURRENT','Tài khoản CURRENT',100000.00,'VND','9704','9704618779687','active','2025-08-08 07:17:08.786337'),('dabc6273-934f-4ae0-b2a3-1878e4c00481','eab80c4a-ee8e-4fba-9b35-e34e3983d68e','CURRENT','Tài khoản CURRENT',100000.00,'VND','1024','1024849406','active','2025-08-10 11:42:53.185300'),('external_liability','system','system','External Clearing',0.00,'VND','SYS','9999999999','active','2025-08-11 03:43:23.000000'),('fd6365f5-4923-4f46-a0f8-5b6fd01cbf4e','0bfe4aab-c87c-4fa7-b2e5-12856dbdfe7a','CURRENT','Tài khoản CURRENT',100000.00,'VND','9704','9704657733487','active','2025-08-07 07:10:54.667935');
/*!40000 ALTER TABLE `accounts` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER `protect_external_liability_account` BEFORE DELETE ON `accounts` FOR EACH ROW BEGIN
    IF OLD.account_id = 'external_liability' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot delete external liability account';
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `banks`
--

DROP TABLE IF EXISTS `banks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `banks` (
  `bank_id` varchar(16) NOT NULL,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY (`bank_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `banks`
--

LOCK TABLES `banks` WRITE;
/*!40000 ALTER TABLE `banks` DISABLE KEYS */;
INSERT INTO `banks` VALUES ('ACB','ACB'),('BIDV','BIDV'),('TCB','Techcombank'),('VCB','Vietcombank');
/*!40000 ALTER TABLE `banks` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `beneficiaries`
--

DROP TABLE IF EXISTS `beneficiaries`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `beneficiaries` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` varchar(36) NOT NULL,
  `type` enum('INTERNAL','EXTERNAL') NOT NULL,
  `bank_id` varchar(16) DEFAULT NULL,
  `account_or_card` varchar(64) NOT NULL,
  `display_name` varchar(255) NOT NULL,
  `last_verified_name` varchar(255) DEFAULT NULL,
  `verified_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ux_bene_user_bank_acc` (`user_id`,`type`,`bank_id`,`account_or_card`),
  KEY `fk_bene_bank` (`bank_id`),
  CONSTRAINT `fk_bene_bank` FOREIGN KEY (`bank_id`) REFERENCES `banks` (`bank_id`),
  CONSTRAINT `fk_bene_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `beneficiaries`
--

LOCK TABLES `beneficiaries` WRITE;
/*!40000 ALTER TABLE `beneficiaries` DISABLE KEYS */;
/*!40000 ALTER TABLE `beneficiaries` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `blacklist`
--

DROP TABLE IF EXISTS `blacklist`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `blacklist` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `customer_id` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `reason` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
  `blacklisted_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `blacklist`
--

LOCK TABLES `blacklist` WRITE;
/*!40000 ALTER TABLE `blacklist` DISABLE KEYS */;
/*!40000 ALTER TABLE `blacklist` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `customers`
--

DROP TABLE IF EXISTS `customers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `customers` (
  `customer_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `name` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `phone` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `cccd` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `dob` datetime(6) NOT NULL,
  `gender` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `hometown` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
  `email` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
  `kyc_status` tinyint(1) NOT NULL,
  `status` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `blacklisted` tinyint(1) NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `cif` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`customer_id`),
  UNIQUE KEY `ux_customers_cif` (`cif`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `customers`
--

LOCK TABLES `customers` WRITE;
/*!40000 ALTER TABLE `customers` DISABLE KEYS */;
INSERT INTO `customers` VALUES ('02b48a58-913c-4137-9981-c21f15dedbe3','Nguyễn Thị Thủy','0389997777','091200004444','1991-05-23 00:00:00.000000','male','Hồ Chí Minh','xuancuong@ittc.edu.vn',0,'pending',0,'2025-08-10 10:39:28.539353',NULL),('0bfe4aab-c87c-4fa7-b2e5-12856dbdfe7a','Tran Van Tam','0707555256','119904567455','1991-05-23 00:00:00.000000','male','Hồ Chí Minh','xuancuong@ittc.edu.vn',0,'active',0,'2025-08-07 07:10:03.482575',NULL),('0e056933-f4f1-4ed9-b432-30b901160733','Nguyễn Thị Thủy','0389998888','091200005555','1991-05-23 00:00:00.000000','male','Hồ Chí Minh','xuancuong@ittc.edu.vn',0,'pending',0,'2025-08-10 12:18:03.260000','CIF641356'),('1972e406-b29f-41bc-9a18-7ad09009ae37','Nguyễn Thị Thủy','0389997777','091200004444','1991-05-23 00:00:00.000000','male','Hồ Chí Minh','xuancuong@ittc.edu.vn',0,'pending',0,'2025-08-10 10:05:29.741153',NULL),('1a9dc73f-634b-4fc8-9073-34b460ac8052','Nguyễn Thị Thủy','0389997777','091200004444','1991-05-23 00:00:00.000000','male','Hồ Chí Minh','xuancuong@ittc.edu.vn',0,'pending',0,'2025-08-10 09:34:06.412798',NULL),('39c217ec-26a8-4adb-9b67-57852578ec4b','Nguyễn Thị Thủy','0389997777','091200004444','1991-05-23 00:00:00.000000','male','Hồ Chí Minh','xuancuong@ittc.edu.vn',0,'active',0,'2025-08-08 07:54:32.561419',NULL),('3f30e903-ebe1-4d9a-b7ed-187d485e78f8','Nguyễn Xuân Cường','0706608888','091204007906','2004-03-14 00:00:00.000000','male','Khu Phố 9, Dương Đông, Phú Quốc, Kiên Giang','xuancuong@ittc.edu.vn',0,'pending',0,'2025-08-10 15:17:04.961524',NULL),('4224b71d-15eb-4313-b31d-fbe5ba1da7f4','Nguyễn Thị Thủy','0389997777','091200004444','1991-05-23 00:00:00.000000','male','Hồ Chí Minh','xuancuong@ittc.edu.vn',0,'active',0,'2025-08-10 10:45:27.581581',NULL),('42e61d79-c0ff-4356-89be-5c19314c1820','Nguyễn Xuân Cường','0706608888','091204007908','2004-03-14 00:00:00.000000','male','Khu Phố 9, Dương Đông, Phú Quốc, Kiên Giang','xuancuong@ittc.edu.vn',0,'pending',0,'2025-08-10 14:34:21.824912',NULL),('445f0c79-81c0-4b22-b645-90e654359902','Nguyễn Thị Thủy','0389997777','091200004444','1991-05-23 00:00:00.000000','male','Hồ Chí Minh','xuancuong@ittc.edu.vn',0,'pending',0,'2025-08-10 09:56:53.533436',NULL),('4c4c0ddd-0f79-47c4-a93f-5de93a1d6a8f','Nguyễn Thị Thủy','0389997777','091200004444','1991-05-23 00:00:00.000000','male','Hồ Chí Minh','xuancuong@ittc.edu.vn',0,'pending',0,'2025-08-10 10:24:07.115424',NULL),('6f722050-50d5-4986-ac1d-4254b87df2e4','Nguyễn Thị Chinh','0348686066','091204005555','1991-05-23 00:00:00.000000','male','Hồ Chí Minh','xuancuong@ittc.edu.vn',0,'active',0,'2025-08-08 06:40:58.926822',NULL),('7e16ee38-5c4d-4c74-9afb-92c842364f24','Nguyễn Xuân Cường','0706668888','091204005689','2004-03-14 00:00:00.000000','male','Khu Phố 9, Dương Đông, Phú Quốc, Kiên Giang','xuancuong@ittc.edu.vn',0,'active',0,'2025-08-08 07:16:46.957530',NULL),('9a19bc45-37af-4658-9432-18de5666b05c','Nguyễn Thị Thanh','0389998888','091200005555','1991-05-23 00:00:00.000000','male','Hồ Chí Minh','xuancuong@ittc.edu.vn',0,'active',0,'2025-08-08 07:37:30.852605',NULL),('a2ff522f-0a8c-4559-97be-0817b41af960','Nguyễn Thị Thủy','0389997777','091200004444','1991-05-23 00:00:00.000000','male','Hồ Chí Minh','xuancuong@ittc.edu.vn',0,'pending',0,'2025-08-10 09:41:12.161841',NULL),('a82e5f48-91ff-4980-9456-592b49062e73','Nguyễn Xuân Vinh','0389980992','091204447777','2004-03-14 00:00:00.000000','male','Khu Phố 9, Dương Đông, Phú Quốc, Kiên Giang','xuancuong@ittc.edu.vn',0,'pending',0,'2025-08-11 00:39:57.182716',NULL),('ab6173a1-78b5-4bc2-a80f-773263cda1be','Tran Van Tam','0706608882','091204007906','1991-05-23 00:00:00.000000','male','Hồ Chí Minh','xuancuong@ittc.edu.vn',0,'active',0,'2025-08-08 03:16:40.633544',NULL),('b15c96d4-0205-4ee7-8ace-ad3e6fd6b4cf','Tran Van Tam','0389980492','091504007905','1991-05-23 00:00:00.000000','male','Hồ Chí Minh','xuancuong@ittc.edu.vn',0,'active',0,'2025-08-08 03:20:43.731048',NULL),('be39b55a-e107-4475-9344-be565aa0664b','Nguyễn Xuân Cường','0706608888','091240008888','2004-03-14 00:00:00.000000','male','Khu Phố 9, Dương Đông, Phú Quốc, Kiên Giang','xuancuong@ittc.edu.vn',0,'pending',0,'2025-08-10 13:48:17.628404',NULL),('c25b14f7-f75a-4ecf-968c-89c92eb70ee4','Nguyễn Xuân Cường','0706668888','091204007906','2004-03-14 00:00:00.000000','male','Khu Phố 9, Dương Đông, Phú Quốc, Kiên Giang',' xuancuong@ittc.edu.vn',0,'pending',0,'2025-08-10 14:54:12.742088',NULL),('e0c41f5b-0963-42fd-b383-2fa08b72bc6a','Nguyễn Xuân Cường','0706604444','091204007906','2004-03-14 00:00:00.000000','male','Khu Phố 9, Dương Đông, Phú Quốc, Kiên Giang','xuancuong@ittc.edu.vn',0,'active',0,'2025-08-11 01:26:27.993736','CIF634463'),('e80fad51-bce4-47d6-b584-fa8b101ce6d5','Nguyễn Thị Thủy','0389998888','091200005555','1991-05-23 00:00:00.000000','male','Hồ Chí Minh','xuancuong@ittc.edu.vn',0,'active',0,'2025-08-10 12:28:05.078023','CIF698951'),('eab80c4a-ee8e-4fba-9b35-e34e3983d68e','Nguyễn Thị Thủy','0389998888','091200005555','1991-05-23 00:00:00.000000','male','Hồ Chí Minh','xuancuong@ittc.edu.vn',0,'active',0,'2025-08-10 11:39:50.785953','CIF287542'),('eaf07d92-7fed-4904-9ef3-7183022be50f','Nguyễn Thị Thủy','0389997777','091200004444','1991-05-23 00:00:00.000000','male','Hồ Chí Minh','xuancuong@ittc.edu.vn',0,'pending',0,'2025-08-10 10:19:11.713549',NULL),('f3145daf-e64a-4334-95cd-79075fe76181','Nguyễn Thị Thủy','0389997777','091200004444','1991-05-23 00:00:00.000000','male','Hồ Chí Minh','xuancuong@ittc.edu.vn',0,'pending',0,'2025-08-10 09:52:42.334631',NULL),('system','System Account','0000000000','000000000000','2000-01-01 00:00:00.000000','other','System','system@example.com',1,'active',0,'2025-08-11 03:43:23.000000',NULL);
/*!40000 ALTER TABLE `customers` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER `protect_system_customer` BEFORE DELETE ON `customers` FOR EACH ROW BEGIN
    IF OLD.customer_id = 'system' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot delete system customer';
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `employee`
--

DROP TABLE IF EXISTS `employee`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `employee` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `email` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `position` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
  `hired_date` datetime(6) DEFAULT NULL,
  `active` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `employee`
--

LOCK TABLES `employee` WRITE;
/*!40000 ALTER TABLE `employee` DISABLE KEYS */;
/*!40000 ALTER TABLE `employee` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ledger_entries`
--

DROP TABLE IF EXISTS `ledger_entries`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ledger_entries` (
  `entry_id` char(36) NOT NULL,
  `transaction_id` char(36) NOT NULL,
  `account_id` varchar(36) NOT NULL,
  `direction` enum('DEBIT','CREDIT') NOT NULL,
  `amount` decimal(18,2) NOT NULL,
  `currency` char(3) NOT NULL DEFAULT 'VND',
  `posted_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`entry_id`),
  KEY `ix_ledger_tx` (`transaction_id`),
  KEY `ix_ledger_acc` (`account_id`,`posted_at`),
  CONSTRAINT `fk_ledger_acc` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`account_id`),
  CONSTRAINT `fk_ledger_tx` FOREIGN KEY (`transaction_id`) REFERENCES `transactions` (`transaction_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ledger_entries`
--

LOCK TABLES `ledger_entries` WRITE;
/*!40000 ALTER TABLE `ledger_entries` DISABLE KEYS */;
/*!40000 ALTER TABLE `ledger_entries` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `name_enquiry_cache`
--

DROP TABLE IF EXISTS `name_enquiry_cache`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `name_enquiry_cache` (
  `bank_id` varchar(16) NOT NULL,
  `account_or_card` varchar(64) NOT NULL,
  `account_name` varchar(255) NOT NULL,
  `provider_ref` varchar(64) DEFAULT NULL,
  `verified_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`bank_id`,`account_or_card`),
  CONSTRAINT `fk_nec_bank` FOREIGN KEY (`bank_id`) REFERENCES `banks` (`bank_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `name_enquiry_cache`
--

LOCK TABLES `name_enquiry_cache` WRITE;
/*!40000 ALTER TABLE `name_enquiry_cache` DISABLE KEYS */;
/*!40000 ALTER TABLE `name_enquiry_cache` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `otp_requests`
--

DROP TABLE IF EXISTS `otp_requests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `otp_requests` (
  `id` int NOT NULL AUTO_INCREMENT,
  `customer_id` varchar(36) NOT NULL,
  `otp_code` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `verified` tinyint(1) NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `expires_at` datetime(6) DEFAULT NULL,
  `transaction_id` varchar(36) DEFAULT NULL,
  `purpose` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ix_otp_tx` (`transaction_id`),
  KEY `fk_otp_customer` (`customer_id`),
  CONSTRAINT `fk_otp_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`customer_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_otp_tx` FOREIGN KEY (`transaction_id`) REFERENCES `transactions` (`transaction_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `otp_requests`
--

LOCK TABLES `otp_requests` WRITE;
/*!40000 ALTER TABLE `otp_requests` DISABLE KEYS */;
/*!40000 ALTER TABLE `otp_requests` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `refunds`
--

DROP TABLE IF EXISTS `refunds`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `refunds` (
  `refund_id` char(36) NOT NULL,
  `transaction_id` char(36) NOT NULL,
  `reason` varchar(64) NOT NULL,
  `amount` decimal(18,2) NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`refund_id`),
  KEY `fk_refund_tx` (`transaction_id`),
  CONSTRAINT `fk_refund_tx` FOREIGN KEY (`transaction_id`) REFERENCES `transactions` (`transaction_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `refunds`
--

LOCK TABLES `refunds` WRITE;
/*!40000 ALTER TABLE `refunds` DISABLE KEYS */;
/*!40000 ALTER TABLE `refunds` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `transaction_requests`
--

DROP TABLE IF EXISTS `transaction_requests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `transaction_requests` (
  `request_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `from_account_id` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `to_account_id` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `amount` decimal(65,30) NOT NULL,
  `currency` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `description` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
  `otp_code` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
  `otp_verified` tinyint(1) NOT NULL,
  `status` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `created_at` datetime(6) NOT NULL,
  PRIMARY KEY (`request_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `transaction_requests`
--

LOCK TABLES `transaction_requests` WRITE;
/*!40000 ALTER TABLE `transaction_requests` DISABLE KEYS */;
/*!40000 ALTER TABLE `transaction_requests` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `transactions`
--

DROP TABLE IF EXISTS `transactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `transactions` (
  `transaction_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `from_account_id` varchar(36) NOT NULL,
  `to_internal_account_id` varchar(36) DEFAULT NULL,
  `to_external_ref` varchar(64) DEFAULT NULL,
  `amount` decimal(18,2) NOT NULL,
  `currency` char(3) NOT NULL,
  `description` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
  `status` enum('pending','pending_otp','approved','pending_settlement','completed','failed') NOT NULL DEFAULT 'pending',
  `created_at` datetime(6) NOT NULL,
  `type` enum('INTERNAL','EXTERNAL') NOT NULL DEFAULT 'INTERNAL',
  `to_bank_id` varchar(16) DEFAULT NULL,
  `provider_ref` varchar(64) DEFAULT NULL,
  `client_request_id` varchar(64) DEFAULT NULL,
  `counterparty_name` varchar(255) DEFAULT NULL,
  `pre_balance` decimal(18,2) DEFAULT NULL,
  `post_balance` decimal(18,2) DEFAULT NULL,
  `failure_code` varchar(32) DEFAULT NULL,
  `failure_detail` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`transaction_id`),
  UNIQUE KEY `client_request_id` (`client_request_id`),
  KEY `ix_tx_status` (`status`,`created_at`),
  KEY `ix_tx_from` (`from_account_id`),
  KEY `fk_tx_to_internal_account` (`to_internal_account_id`),
  KEY `fk_tx_bank` (`to_bank_id`),
  CONSTRAINT `fk_tx_bank` FOREIGN KEY (`to_bank_id`) REFERENCES `banks` (`bank_id`),
  CONSTRAINT `fk_tx_from` FOREIGN KEY (`from_account_id`) REFERENCES `accounts` (`account_id`),
  CONSTRAINT `fk_tx_to_internal_account` FOREIGN KEY (`to_internal_account_id`) REFERENCES `accounts` (`account_id`),
  CONSTRAINT `chk_tx_target` CHECK ((((`type` = _utf8mb4'INTERNAL') and (`to_internal_account_id` is not null) and (`to_external_ref` is null) and (`to_bank_id` is null)) or ((`type` = _utf8mb4'EXTERNAL') and (`to_internal_account_id` is null) and (`to_external_ref` is not null) and (`to_bank_id` is not null))))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `transactions`
--

LOCK TABLES `transactions` WRITE;
/*!40000 ALTER TABLE `transactions` DISABLE KEYS */;
/*!40000 ALTER TABLE `transactions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `user_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `username` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `password_hash` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `role` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `linked_customer_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  PRIMARY KEY (`user_id`),
  KEY `IX_users_linked_customer_id` (`linked_customer_id`),
  CONSTRAINT `FK_users_customers_linked_customer_id` FOREIGN KEY (`linked_customer_id`) REFERENCES `customers` (`customer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES ('15e8b545-0520-44e5-aa4a-3735f4a84a97','091200004444','$2a$11$IiamDiwyIHRCV62.0UE0/Ohvt8uW9czcrjlHVgcq5fkSApugk0Mnq','customer','39c217ec-26a8-4adb-9b67-57852578ec4b'),('1c1dc249-2fd8-4a31-a833-519b9cc3e20f','091204007906','$2a$11$9CxB0em/PLJyhDZ9Cepy2.BBF8lZwr7WezrBTp.P6OZSMDPJ2g0zm','customer','ab6173a1-78b5-4bc2-a80f-773263cda1be'),('207e058d-8b1e-4b8c-91f3-2d639eb6989b','091204007906','$2a$11$3UDZPvHqzHwns12Gx.M0DeyEWPhfqWrP6Mu6NJ809/n7S9rJ.Zrb6','customer','e0c41f5b-0963-42fd-b383-2fa08b72bc6a'),('880e0542-cc29-4032-893c-4436dc784139','091504007905','$2a$11$fbW3sopFxbv6499sc9oL1OGzPjsvkMcAjkRrr.EQGz3rY3AS2YfvS','customer','b15c96d4-0205-4ee7-8ace-ad3e6fd6b4cf'),('88fccf1b-a44d-46c1-b6a9-9d24ad3c4e4a','091204005689','$2a$11$x0HfnajRCaA339Hlalpxre0ckuM2Xjc1q1sGzOw88jvEx0421KQYy','customer','7e16ee38-5c4d-4c74-9afb-92c842364f24'),('a8dff327-3d5a-4671-b07d-7a165296d441','091200005555','$2a$11$eFOftrSfjQELHbZOwdbcFukGICG5NP309wP1RqE3w9jmxNf8f1G6e','customer','e80fad51-bce4-47d6-b584-fa8b101ce6d5'),('b939f351-e70e-4d93-9f13-d9f64b970e74','091200005555','$2a$11$LPyS4zrjSE7GHdgdbgYPLuRKP1TvvKnOoh.znVy0/eSL/j/KRwT6K','customer','eab80c4a-ee8e-4fba-9b35-e34e3983d68e'),('bdf67cb5-f387-4959-937c-8f1cb5362e15','091200005555','$2a$11$xiEKBs8nzfHsXNo.WBwVV.jOyCtUHA0z6kPl3/2O8.uNlol3/X1Xa','customer','9a19bc45-37af-4658-9432-18de5666b05c'),('c431d4c2-ba29-49ed-90f7-88804781ea19','091200004444','$2a$11$SxLSDUPrNtQ9F2zsW1KIFO2g5AOLvbU5mOjNbP.OxWlBiL9QimruK','customer','4224b71d-15eb-4313-b31d-fbe5ba1da7f4'),('e47a4e22-e1fe-4fc5-add1-62159b4d66ee','119904567455','$2a$11$Nc5474hEJGZ2IDvz60CJOuSJDL8xKFgF60dYFbZ3eiBLhWkbvjmN.','customer','0bfe4aab-c87c-4fa7-b2e5-12856dbdfe7a'),('f8bcd120-b657-4aec-8317-2672852741fe','091204005555','$2a$11$yjp6bDo.cpGau5QOQoPQdu4BN10l2FMGgqI6iD1FEifOjRUwkJuPa','customer','6f722050-50d5-4986-ac1d-4254b87df2e4');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'bank_users'
--
/*!50003 DROP PROCEDURE IF EXISTS `POMELO_AFTER_ADD_PRIMARY_KEY` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`%` PROCEDURE `POMELO_AFTER_ADD_PRIMARY_KEY`(IN `SCHEMA_NAME_ARGUMENT` VARCHAR(255), IN `TABLE_NAME_ARGUMENT` VARCHAR(255), IN `COLUMN_NAME_ARGUMENT` VARCHAR(255))
BEGIN
	DECLARE HAS_AUTO_INCREMENT_ID INT(11);
	DECLARE PRIMARY_KEY_COLUMN_NAME VARCHAR(255);
	DECLARE PRIMARY_KEY_TYPE VARCHAR(255);
	DECLARE SQL_EXP VARCHAR(1000);
	SELECT COUNT(*)
		INTO HAS_AUTO_INCREMENT_ID
		FROM `information_schema`.`COLUMNS`
		WHERE `TABLE_SCHEMA` = (SELECT IFNULL(SCHEMA_NAME_ARGUMENT, SCHEMA()))
			AND `TABLE_NAME` = TABLE_NAME_ARGUMENT
			AND `COLUMN_NAME` = COLUMN_NAME_ARGUMENT
			AND `COLUMN_TYPE` LIKE '%int%'
			AND `COLUMN_KEY` = 'PRI';
	IF HAS_AUTO_INCREMENT_ID THEN
		SELECT `COLUMN_TYPE`
			INTO PRIMARY_KEY_TYPE
			FROM `information_schema`.`COLUMNS`
			WHERE `TABLE_SCHEMA` = (SELECT IFNULL(SCHEMA_NAME_ARGUMENT, SCHEMA()))
				AND `TABLE_NAME` = TABLE_NAME_ARGUMENT
				AND `COLUMN_NAME` = COLUMN_NAME_ARGUMENT
				AND `COLUMN_TYPE` LIKE '%int%'
				AND `COLUMN_KEY` = 'PRI';
		SELECT `COLUMN_NAME`
			INTO PRIMARY_KEY_COLUMN_NAME
			FROM `information_schema`.`COLUMNS`
			WHERE `TABLE_SCHEMA` = (SELECT IFNULL(SCHEMA_NAME_ARGUMENT, SCHEMA()))
				AND `TABLE_NAME` = TABLE_NAME_ARGUMENT
				AND `COLUMN_NAME` = COLUMN_NAME_ARGUMENT
				AND `COLUMN_TYPE` LIKE '%int%'
				AND `COLUMN_KEY` = 'PRI';
		SET SQL_EXP = CONCAT('ALTER TABLE `', (SELECT IFNULL(SCHEMA_NAME_ARGUMENT, SCHEMA())), '`.`', TABLE_NAME_ARGUMENT, '` MODIFY COLUMN `', PRIMARY_KEY_COLUMN_NAME, '` ', PRIMARY_KEY_TYPE, ' NOT NULL AUTO_INCREMENT;');
		SET @SQL_EXP = SQL_EXP;
		PREPARE SQL_EXP_EXECUTE FROM @SQL_EXP;
		EXECUTE SQL_EXP_EXECUTE;
		DEALLOCATE PREPARE SQL_EXP_EXECUTE;
	END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `POMELO_BEFORE_DROP_PRIMARY_KEY` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`%` PROCEDURE `POMELO_BEFORE_DROP_PRIMARY_KEY`(IN `SCHEMA_NAME_ARGUMENT` VARCHAR(255), IN `TABLE_NAME_ARGUMENT` VARCHAR(255))
BEGIN
	DECLARE HAS_AUTO_INCREMENT_ID TINYINT(1);
	DECLARE PRIMARY_KEY_COLUMN_NAME VARCHAR(255);
	DECLARE PRIMARY_KEY_TYPE VARCHAR(255);
	DECLARE SQL_EXP VARCHAR(1000);
	SELECT COUNT(*)
		INTO HAS_AUTO_INCREMENT_ID
		FROM `information_schema`.`COLUMNS`
		WHERE `TABLE_SCHEMA` = (SELECT IFNULL(SCHEMA_NAME_ARGUMENT, SCHEMA()))
			AND `TABLE_NAME` = TABLE_NAME_ARGUMENT
			AND `Extra` = 'auto_increment'
			AND `COLUMN_KEY` = 'PRI'
			LIMIT 1;
	IF HAS_AUTO_INCREMENT_ID THEN
		SELECT `COLUMN_TYPE`
			INTO PRIMARY_KEY_TYPE
			FROM `information_schema`.`COLUMNS`
			WHERE `TABLE_SCHEMA` = (SELECT IFNULL(SCHEMA_NAME_ARGUMENT, SCHEMA()))
				AND `TABLE_NAME` = TABLE_NAME_ARGUMENT
				AND `COLUMN_KEY` = 'PRI'
			LIMIT 1;
		SELECT `COLUMN_NAME`
			INTO PRIMARY_KEY_COLUMN_NAME
			FROM `information_schema`.`COLUMNS`
			WHERE `TABLE_SCHEMA` = (SELECT IFNULL(SCHEMA_NAME_ARGUMENT, SCHEMA()))
				AND `TABLE_NAME` = TABLE_NAME_ARGUMENT
				AND `COLUMN_KEY` = 'PRI'
			LIMIT 1;
		SET SQL_EXP = CONCAT('ALTER TABLE `', (SELECT IFNULL(SCHEMA_NAME_ARGUMENT, SCHEMA())), '`.`', TABLE_NAME_ARGUMENT, '` MODIFY COLUMN `', PRIMARY_KEY_COLUMN_NAME, '` ', PRIMARY_KEY_TYPE, ' NOT NULL;');
		SET @SQL_EXP = SQL_EXP;
		PREPARE SQL_EXP_EXECUTE FROM @SQL_EXP;
		EXECUTE SQL_EXP_EXECUTE;
		DEALLOCATE PREPARE SQL_EXP_EXECUTE;
	END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-08-11 11:20:29
