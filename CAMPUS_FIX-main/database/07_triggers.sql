-- =============================================================================
-- CAMPUSFIX: Smart Campus Complaint & Maintenance Management System
-- Script: 07_triggers.sql
-- Description: Automated database triggers for timestamp synchronization,
--              lifecycle status audit logging, and student feedback validation.
-- Target RDBMS: MySQL 8.0+
-- Execution Order: 07
-- =============================================================================

USE campusfix;

-- Drop existing triggers to support clean idempotent re-execution
DROP TRIGGER IF EXISTS trg_complaints_before_update;
DROP TRIGGER IF EXISTS trg_complaints_status_audit;
DROP TRIGGER IF EXISTS trg_feedback_before_insert;
DROP TRIGGER IF EXISTS trg_feedback_before_update;

DELIMITER //

-- -----------------------------------------------------------------------------
-- Trigger 1: trg_complaints_before_update
-- Purpose: Automatically updates the `updated_at` timestamp on any update to
--          a complaint record, ensuring consistent temporal auditing.
-- -----------------------------------------------------------------------------
CREATE TRIGGER trg_complaints_before_update
BEFORE UPDATE ON complaints
FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END //

-- -----------------------------------------------------------------------------
-- Trigger 2: trg_complaints_status_audit
-- Purpose: Automatically inserts an immutable audit log record into
--          `complaint_status_history` whenever a complaint's status transitions.
-- Responsible User Identification:
--   - Uses the MySQL session variable `@current_session_user` if supplied by
--     an application or stored procedure (e.g. `sp_update_complaint_status`).
--   - If `@current_session_user` is not set, safely falls back to `USER()`
--     (the active database connection identity) or 'SYSTEM / DIRECT_UPDATE'.
-- -----------------------------------------------------------------------------
CREATE TRIGGER trg_complaints_status_audit
AFTER UPDATE ON complaints
FOR EACH ROW
BEGIN
    -- Detect state transition
    IF (OLD.status <> NEW.status) OR (OLD.status IS NULL AND NEW.status IS NOT NULL) THEN
        INSERT INTO complaint_status_history (
            complaint_id,
            old_status,
            new_status,
            changed_at,
            changed_by
        ) VALUES (
            NEW.complaint_id,
            OLD.status,
            NEW.status,
            NOW(),
            COALESCE(NULLIF(@current_session_user, ''), USER(), 'SYSTEM / DB_TRIGGER')
        );
    END IF;
END //

-- -----------------------------------------------------------------------------
-- Trigger 3: trg_feedback_before_insert
-- Purpose: Validates that:
--          1. The feedback author is strictly the student who filed the complaint.
--          2. The complaint has reached 'Resolved' or 'Closed' status before feedback is accepted.
-- Recursion Prevention:
--          Only validates fields and raises standard SQLSTATE '45000' errors.
--          Performs NO table mutations, completely eliminating recursion.
-- -----------------------------------------------------------------------------
CREATE TRIGGER trg_feedback_before_insert
BEFORE INSERT ON feedback
FOR EACH ROW
BEGIN
    DECLARE v_complaint_student_id INT;
    DECLARE v_complaint_status VARCHAR(20);

    -- Retrieve author and current lifecycle status of the target complaint
    SELECT student_id, status 
    INTO v_complaint_student_id, v_complaint_status
    FROM complaints
    WHERE complaint_id = NEW.complaint_id;

    -- 1. Ensure target complaint exists
    IF v_complaint_student_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Feedback Error: The specified complaint_id does not exist.';
    END IF;

    -- 2. Verify student ownership
    IF NEW.student_id <> v_complaint_student_id THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Feedback Error: Feedback author must match the student who filed the complaint.';
    END IF;

    -- 3. Verify complaint lifecycle stage (must be Resolved or Closed)
    IF v_complaint_status NOT IN ('Resolved', 'RESOLVED', 'Closed', 'CLOSED') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Feedback Error: Feedback can only be submitted for Resolved or Closed complaints.';
    END IF;
END //

-- -----------------------------------------------------------------------------
-- Trigger 4: trg_feedback_before_update
-- Purpose: Enforces the same ownership and lifecycle rules upon feedback modification.
-- -----------------------------------------------------------------------------
CREATE TRIGGER trg_feedback_before_update
BEFORE UPDATE ON feedback
FOR EACH ROW
BEGIN
    DECLARE v_complaint_student_id INT;
    DECLARE v_complaint_status VARCHAR(20);

    SELECT student_id, status 
    INTO v_complaint_student_id, v_complaint_status
    FROM complaints
    WHERE complaint_id = NEW.complaint_id;

    IF NEW.student_id <> v_complaint_student_id THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Feedback Error: Feedback author must match the student who filed the complaint.';
    END IF;

    IF v_complaint_status NOT IN ('Resolved', 'RESOLVED', 'Closed', 'CLOSED') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Feedback Error: Feedback can only be submitted for Resolved or Closed complaints.';
    END IF;
END //

DELIMITER ;
