-- =============================================================================
-- CAMPUSFIX: Smart Campus Complaint & Maintenance Management System
-- Script: 03_constraints.sql
-- Description: Establishes secondary performance indexes and documents relational
--              integrity constraint architecture.
-- Target RDBMS: MySQL 8.0+
-- Execution Order: 03
-- =============================================================================

USE campusfix;

-- -----------------------------------------------------------------------------
-- ARCHITECTURAL APPROACH DOCUMENTATION:
-- -----------------------------------------------------------------------------
-- In adherence to production database standards, all foundational constraints:
--   1. PRIMARY KEY constraints (pk_*)
--   2. FOREIGN KEY constraints with referential actions (fk_*)
--   3. UNIQUE constraints on emails, departments, and feedback (uq_*)
--   4. CHECK domain constraints for priority, status, and ratings (chk_*)
--
-- are declared directly within `02_create_tables.sql` during table definition.
--
-- RATIONALE:
--   - Inline declaration prevents tables from momentarily existing in an
--     unconstrained state, eliminating orphan insertion vulnerabilities.
--   - It avoids duplicate constraint exceptions in MySQL when scripts are executed.
--   - It ensures full transactional schema consistency under InnoDB.
--
-- THIS SCRIPT (03_constraints.sql):
--   - Adds targeted secondary B-Tree indexes on foreign keys and high-frequency
--     filtering columns (e.g. status, priority, dates) to optimize JOIN,
--     GROUP BY, and WHERE query performance.
--   - Provides metadata audit queries against `information_schema` to verify
--     that all relational constraints and checks are active.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 1. Secondary Indexes for High-Frequency Operational Lookups
-- -----------------------------------------------------------------------------

-- Index on complaints status and priority (accelerates triage & dashboard filtering)
CREATE INDEX idx_complaints_status 
    ON complaints (status);

CREATE INDEX idx_complaints_priority 
    ON complaints (priority);

CREATE INDEX idx_complaints_category 
    ON complaints (category);

-- Composite index: lookup complaints by student and filter by status
CREATE INDEX idx_complaints_student_status 
    ON complaints (student_id, status);

-- Composite index: lookup complaints by location and filter by status
CREATE INDEX idx_complaints_location_status 
    ON complaints (location_id, status);

-- Index on complaint submission date for time-series / SLA reporting
CREATE INDEX idx_complaints_created_at 
    ON complaints (created_at);

-- Index on staff assignments to optimize technician workload queries
CREATE INDEX idx_assignments_staff 
    ON complaint_assignments (staff_id);

CREATE INDEX idx_assignments_complaint 
    ON complaint_assignments (complaint_id);

-- Index on status history to optimize complaint timeline reconstruction
CREATE INDEX idx_status_history_complaint 
    ON complaint_status_history (complaint_id, changed_at);

-- Index on feedback rating for satisfaction metric aggregation
CREATE INDEX idx_feedback_rating 
    ON feedback (rating);

-- -----------------------------------------------------------------------------
-- 2. Constraint Verification Audit Queries (For MySQL Workbench)
-- -----------------------------------------------------------------------------

-- A. Verify all Table Constraints (PRIMARY KEY, UNIQUE, FOREIGN KEY)
SELECT 
    CONSTRAINT_NAME,
    TABLE_NAME,
    CONSTRAINT_TYPE
FROM information_schema.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA = 'campusfix'
ORDER BY TABLE_NAME, CONSTRAINT_TYPE;

-- B. Verify all Domain CHECK Constraints
SELECT 
    CONSTRAINT_NAME,
    CHECK_CLAUSE
FROM information_schema.CHECK_CONSTRAINTS
WHERE CONSTRAINT_SCHEMA = 'campusfix'
ORDER BY CONSTRAINT_NAME;

-- C. Verify Foreign Key Referential Rules
SELECT 
    CONSTRAINT_NAME,
    TABLE_NAME,
    REFERENCED_TABLE_NAME,
    UPDATE_RULE,
    DELETE_RULE
FROM information_schema.REFERENTIAL_CONSTRAINTS
WHERE CONSTRAINT_SCHEMA = 'campusfix'
ORDER BY TABLE_NAME;
