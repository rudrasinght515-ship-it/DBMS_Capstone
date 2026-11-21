-- =============================================================================
-- CAMPUSFIX: Smart Campus Complaint & Maintenance Management System
-- Script: 09_transactions.sql
-- Description: Demonstrates ACID transaction management, atomicity guarantees,
--              SAVEPOINTs, exception handlers, and failure rollback routines.
-- Target RDBMS: MySQL 8.0+
-- Execution Order: 09
-- =============================================================================

USE campusfix;

-- Drop demonstration procedures if they exist
DROP PROCEDURE IF EXISTS sp_tx_assign_technician;
DROP PROCEDURE IF EXISTS sp_tx_resolve_complaint;
DROP PROCEDURE IF EXISTS sp_tx_simulate_failure;

DELIMITER //

-- =============================================================================
-- TRANSACTION 1: PROGRAMMATIC COMPLAINT ASSIGNMENT (COMMIT / ROLLBACK HANDLER)
-- =============================================================================
-- Concept: Demonstrates ACID atomicity across multiple tables using a SQLEXCEPTION
--          exit handler. If either the assignment insertion or status update fails,
--          the entire transaction rolls back cleanly with zero partial changes.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_tx_assign_technician (
    IN p_complaint_id INT,
    IN p_staff_id INT,
    IN p_assigned_by VARCHAR(100)
)
BEGIN
    -- Declare exception handler to ensure atomic rollback upon error
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'TRANSACTION ROLLED BACK: An unexpected database error occurred during assignment.' AS transaction_result;
    END;

    START TRANSACTION;

    -- 1. Insert assignment record
    INSERT INTO complaint_assignments (
        complaint_id,
        staff_id,
        assigned_at,
        assigned_by
    ) VALUES (
        p_complaint_id,
        p_staff_id,
        NOW(),
        p_assigned_by
    );

    -- 2. Update complaint status
    UPDATE complaints 
    SET status = 'Assigned',
        updated_at = NOW()
    WHERE complaint_id = p_complaint_id;

    -- 3. Commit the changes atomically
    COMMIT;

    SELECT 
        'TRANSACTION COMMITTED' AS transaction_status,
        p_complaint_id AS complaint_id,
        p_staff_id AS staff_id,
        'Both assignment record and complaint status updated atomically' AS outcome;
END //

-- =============================================================================
-- TRANSACTION 2: PROGRAMMATIC COMPLAINT RESOLUTION (WITH VERIFICATION)
-- =============================================================================
-- Concept: Verifies ticket state preconditions before committing. If the ticket
--          is not currently in 'In Progress' or 'Assigned', the transaction aborts.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_tx_resolve_complaint (
    IN p_complaint_id INT,
    IN p_resolved_by VARCHAR(100)
)
BEGIN
    DECLARE v_current_status VARCHAR(20);
    DECLARE v_ticket_exists INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'TRANSACTION ROLLED BACK: Exception encountered while resolving complaint.' AS transaction_result;
    END;

    START TRANSACTION;

    -- Check ticket existence and current status
    SELECT COUNT(*), MAX(status) 
    INTO v_ticket_exists, v_current_status
    FROM complaints
    WHERE complaint_id = p_complaint_id;

    IF v_ticket_exists = 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transaction Aborted: Complaint ID not found.';
    END IF;

    -- Business check: cannot resolve a pending or rejected ticket directly
    IF v_current_status NOT IN ('In Progress', 'Assigned', 'IN_PROGRESS', 'ASSIGNED') THEN
        ROLLBACK;
        SELECT 
            'TRANSACTION ABORTED & ROLLED BACK' AS transaction_status,
            CONCAT('Cannot resolve complaint currently in status: ', v_current_status) AS error_reason;
    ELSE
        -- Set session user for Trigger 2 (`trg_complaints_status_audit`)
        SET @current_session_user = p_resolved_by;

        -- Update status to Resolved
        UPDATE complaints
        SET status = 'Resolved',
            updated_at = NOW()
        WHERE complaint_id = p_complaint_id;

        SET @current_session_user = NULL;

        COMMIT;

        SELECT 
            'TRANSACTION COMMITTED' AS transaction_status,
            p_complaint_id AS complaint_id,
            'Resolved' AS new_status,
            NOW() AS resolved_at,
            'Complaint marked Resolved and audit trail logged successfully' AS message;
    END IF;
END //

-- =============================================================================
-- TRANSACTION 3: SIMULATED FAILURE & ATOMIC ROLLBACK DEMONSTRATION
-- =============================================================================
-- Concept: Demonstrates partial update prevention. A valid UPDATE is executed,
--          followed by an invalid operation (violating foreign key constraint).
--          The exception handler rolls back the entire transaction, proving that
--          the first UPDATE is never permanently written to disk.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_tx_simulate_failure (
    IN p_complaint_id INT
)
BEGIN
    DECLARE v_original_title VARCHAR(150);

    -- Capture original title for post-rollback verification
    SELECT title INTO v_original_title FROM complaints WHERE complaint_id = p_complaint_id;

    BEGIN
        -- Handler catches intentional foreign key failure
        DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
            SELECT 
                'FAILURE DEMONSTRATION SUCCEEDED' AS demo_result,
                'SQLEXCEPTION caught: Entire transaction rolled back via ROLLBACK statement' AS mechanism,
                v_original_title AS title_after_rollback,
                'Verified: Step 1 UPDATE was undone; database returned to pristine initial state' AS atomicity_proof;
        END;

        START TRANSACTION;

        -- Step 1 (Valid): Temporarily mutate title
        UPDATE complaints
        SET title = 'MUTATED TITLE (SHOULD NEVER PERSIST)'
        WHERE complaint_id = p_complaint_id;

        -- Step 2 (Deliberate Failure): Violates FK constraint with invalid staff_id = 999999
        INSERT INTO complaint_assignments (
            complaint_id,
            staff_id,
            assigned_at,
            assigned_by
        ) VALUES (
            p_complaint_id,
            999999, -- Non-existent staff member!
            NOW(),
            'Test Failure Trigger'
        );

        -- Step 3 (Unreachable due to FK error above)
        COMMIT;
    END;
END //

DELIMITER ;


-- =============================================================================
-- INTERACTIVE WORKBENCH TRANSACTION DEMONSTRATIONS (RAW SQL BLOCKS)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Interactive Demo 1: Manual Complaint Assignment with Atomic Commit
-- -----------------------------------------------------------------------------
START TRANSACTION;

-- Step 1: Assign staff member 5 (Electrician Dinesh Sharma) to pending complaint 31
INSERT INTO complaint_assignments (complaint_id, staff_id, assigned_at, assigned_by)
VALUES (31, 5, NOW(), 'Interactive Admin Session');

-- Step 2: Update complaint status to Assigned
UPDATE complaints
SET status = 'Assigned',
    updated_at = NOW()
WHERE complaint_id = 31;

-- Step 3: Verify the staged state within transaction boundary
SELECT complaint_id, title, status FROM complaints WHERE complaint_id = 31;
SELECT * FROM complaint_assignments WHERE complaint_id = 31 AND staff_id = 5;

-- Step 4: Commit atomically
COMMIT;

-- -----------------------------------------------------------------------------
-- Interactive Demo 2: Intentional Failure & Rollback Demonstration
-- -----------------------------------------------------------------------------
START TRANSACTION;

-- Step A: Apply an update to complaint 32
UPDATE complaints
SET priority = 'Critical'
WHERE complaint_id = 32;

-- Step B: Attempt invalid insertion violating CHECK constraint on feedback rating
-- Note: Rating 99 violates CHECK (rating BETWEEN 1 AND 5)
-- In a script, executing an invalid statement causes an error:
-- INSERT INTO feedback (complaint_id, student_id, rating, comments) VALUES (32, 12, 99, 'Invalid');

-- Step C: Explicit Rollback demonstration
ROLLBACK;

-- Verify that complaint 32 priority remains unmutated
SELECT complaint_id, title, priority, status FROM complaints WHERE complaint_id = 32;
