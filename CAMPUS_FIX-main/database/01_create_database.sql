-- =============================================================================
-- CAMPUSFIX: Smart Campus Complaint & Maintenance Management System
-- Script: 01_create_database.sql
-- Description: Creates the database schema with appropriate character set and collation.
-- Target RDBMS: MySQL 8.0+
-- Execution Order: 01
-- =============================================================================

-- Create the database if it doesn't already exist
CREATE DATABASE IF NOT EXISTS campusfix
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Switch context to campusfix
USE campusfix;

-- Display creation confirmation
SELECT 
    SCHEMA_NAME AS database_name,
    DEFAULT_CHARACTER_SET_NAME AS charset,
    DEFAULT_COLLATION_NAME AS collation
FROM information_schema.SCHEMATA
WHERE SCHEMA_NAME = 'campusfix';
