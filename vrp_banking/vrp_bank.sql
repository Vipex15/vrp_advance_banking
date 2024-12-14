-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Aug 10, 2024 at 09:44 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `vrp`
--

-- --------------------------------------------------------

--
-- Table structure for table `vrp_banks`
--

CREATE TABLE `vrp_banks` (
  `owner_id` int(11) NOT NULL DEFAULT 0,
  `bank_id` int(11) NOT NULL,
  `bank_name` varchar(255) NOT NULL,
  `money` decimal(12,0) NOT NULL DEFAULT 1000,
  `taxes_profit` int(11) NOT NULL DEFAULT 0,
  `taxes_in` int(11) NOT NULL DEFAULT 0,
  `taxes_out` int(11) NOT NULL DEFAULT 0,
  `create_acc` int(11) NOT NULL DEFAULT 0,
  `deposit_level` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `vrp_banks`
--

INSERT INTO `vrp_banks` (`owner_id`, `bank_id`, `bank_name`, `money`, `taxes_profit`, `taxes_in`, `taxes_out`, `create_acc`, `deposit_level`) VALUES
(0, 1, 'Pillbox Hills', 100000, 0, 0, 0, 0, 1),
(0, 2, 'Rockford hills', 100000, 0, 0, 0, 0, 1),
(0, 3, 'Alta', 100000, 0, 0, 0, 0, 1),
(0, 4, 'Burton', 100000, 0, 0, 0, 0, 1),
(0, 5, 'Los Santos County', 100000, 0, 0, 0, 0, 1),
(0, 6, 'Harmony', 100000, 0, 0, 0, 0, 1),
(0, 7, 'Blaine County', 100000, 0, 0, 0, 0, 1);

-- --------------------------------------------------------

--
-- Table structure for table `vrp_banks_accounts`
--

CREATE TABLE `vrp_banks_accounts` (
  `character_id` int(11) NOT NULL,
  `dkey` varchar(100) NOT NULL,
  `dvalue` blob DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `vrp_banks_transactions`
--

CREATE TABLE `vrp_banks_transactions` (
  `character_id` int(11) NOT NULL,
  `dkey` varchar(100) NOT NULL,
  `dvalue` blob DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `vrp_banks`
--
ALTER TABLE `vrp_banks`
  ADD PRIMARY KEY (`bank_id`);

--
-- Indexes for table `vrp_banks_accounts`
--
ALTER TABLE `vrp_banks_accounts`
  ADD PRIMARY KEY (`character_id`,`dkey`);

--
-- Indexes for table `vrp_banks_transactions`
--
ALTER TABLE `vrp_banks_transactions`
  ADD PRIMARY KEY (`character_id`,`dkey`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `vrp_banks`
--
ALTER TABLE `vrp_banks`
  MODIFY `bank_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `vrp_banks_accounts`
--
ALTER TABLE `vrp_banks_accounts`
  ADD CONSTRAINT `ac_character_data_accounts` FOREIGN KEY (`character_id`) REFERENCES `vrp_characters` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `vrp_banks_transactions`
--
ALTER TABLE `vrp_banks_transactions`
  ADD CONSTRAINT `ta_character_data_transacations` FOREIGN KEY (`character_id`) REFERENCES `vrp_characters` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
