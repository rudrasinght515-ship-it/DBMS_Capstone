-- =============================================================================
-- CAMPUSFIX: Smart Campus Complaint & Maintenance Management System
-- Script: 08_procedures.sql
-- Description: Stored procedures encapsulating routine operational workflows,
--              status lifecycle transitions, and parameterized reporting.
-- Target RDBMS: MySQL 8.0+
-- Execution Order: 08
-- =============================================================================

USE campusfix;

-- Drop existing procedures to support clean idempotent re-execution
DROP PROCEDURE IF EXISTS sp_assign_complaint;
DROP PROCEDURE IF EXISTS sp_update_complaint_status;
DROP PROCEDURE IF EXISTS sp_get_student_complaints;
DROP PROCEDURE IF EXISTS sp_get_department_report;

DELIMITER //

-- -----------------------------------------------------------------------------
-- Procedure 1: sp_assign_complaint
-- Purpose: Assigns a maintenance technician to an active complaint, records the
--          delegation record, and updates complaint status to 'Assigned'.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_assign_complaint (
    IN p_complaint_id INT,
    IN p_staff_id INT,
    IN p_assigned_by VARCHAR(100)
)
proc_label: BEGIN
    DECLARE v_complaint_exists INT DEFAULT 0;
    DECLARE v_staff_exists INT DEFAULT 0;
    DECLARE v_current_status VARCHAR(20);
    DECLARE v_staff_name VARCHAR(100);

    -- 1. Validate complaint existence and current status
    SELECT COUNT(*), MAX(status) 
    INTO v_complaint_exists, v_current_status
    FROM complaints 
    WHERE complaint_id = p_complaint_id;

    IF v_complaint_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Execution Error: Complaint ID not found.';
    END IF;

    -- Prevent assigning closed/rejected complaints
    IF v_current_status IN ('Resolved', 'RESOLVED', 'Closed', 'CLOSED', 'Rejected', 'REJECTED') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Execution Error: Cannot assign staff to a Resolved, Closed, or Rejected complaint.';
    END IF;

    -- 2. Validate staff existence
    SELECT COUNT(*), MAX(full_name) 
    INTO v_staff_exists, v_staff_name
    FROM staff 
    WHERE staff_id = p_staff_id;

    IF v_staff_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Execution Error: Staff ID not found.';
    END IF;

    -- 3. Set session variable so status history trigger attributes the change correctly
    SET @current_session_user = p_assigned_by;

    -- 4. Insert assignment record
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

    -- 5. Update complaint status to 'Assigned' if it was previously 'Pending'
    IF v_current_status IN ('Pending', 'PENDING') THEN
        UPDATE complaints 
        SET status = 'Assigned',
            updated_at = NOW()
        WHERE complaint_id = p_complaint_id;
    END IF;

    -- Reset session variable
    SET @current_session_user = NULL;

    -- Return confirmation result set
    SELECT 
        p_complaint_id AS complaint_id,
        p_staff_id AS staff_id,
        v_staff_name AS assigned_technician,
        'Assigned' AS updated_status,
        NOW() AS assigned_timestamp,
        CONCAT('Successfully assigned complaint #', p_complaint_id, ' to ', v_staff_name) AS message;
END //

-- -----------------------------------------------------------------------------
-- Procedure 2: sp_update_complaint_status
-- Purpose: Validates and applies lifecycle status transitions, delegating audit
--          recording to the status history trigger via session context.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_update_complaint_status (
    IN p_complaint_id INT,
    IN p_new_status VARCHAR(20),
    IN p_changed_by VARCHAR(100)
)
proc_label: BEGIN
    DECLARE v_current_status VARCHAR(20);
    DECLARE v_complaint_exists INT DEFAULT 0;

    -- 1. Validate complaint existence
    SELECT COUNT(*), MAX(status) 
    INTO v_complaint_exists, v_current_status
    FROM complaints 
    WHERE complaint_id = p_complaint_id;

    IF v_complaint_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Execution Error: Complaint ID not found.';
    END IF;

    -- 2. Validate allowed status vocabulary
    IF p_new_status NOT IN ('Pending', 'Assigned', 'In Progress', 'Resolved', 'Rejected', 'Closed',
                           'PENDING', 'ASSIGNED', 'IN_PROGRESS', 'RESOLVED', 'REJECTED', 'CLOSED') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Execution Error: Invalid status value provided.';
    END IF;

    -- 3. Business rule validation on status transitions
    IF v_current_status IN ('Rejected', 'REJECTED') AND p_new_status NOT IN ('Pending', 'PENDING') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transition Error: A Rejected complaint can only be reopened to Pending status.';
    END IF;

    IF v_current_status IN ('Closed', 'CLOSED') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transition Error: Cannot modify a Closed complaint ticket.';
    END IF;

    -- 4. Set session user identity for Trigger 2 (`trg_complaints_status_audit`)
    SET @current_session_user = p_changed_by;

    -- 5. Perform the status update
    UPDATE complaints 
    SET status = p_new_status,
        updated_at = NOW()
    WHERE complaint_id = p_complaint_id;

    -- Reset session user
    SET @current_session_user = NULL;

    -- Return updated ticket snapshot
    SELECT 
        complaint_id,
        title,
        v_current_status AS previous_status,
        status AS current_status,
        updated_at,
        p_changed_by AS modified_by,
        'Status successfully updated; audit history logged by database trigger' AS status_note
    FROM complaints
    WHERE complaint_id = p_complaint_id;
END //

-- -----------------------------------------------------------------------------
-- Procedure 3: sp_get_student_complaints
-- Purpose: Returns all complaint records submitted by a specified student.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_get_student_complaints (
    IN p_student_id INT
)
BEGIN
    DECLARE v_student_exists INT DEFAULT 0;

    SELECT COUNT(*) INTO v_student_exists 
    FROM students 
    WHERE student_id = p_student_id;

    IF v_student_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Execution Error: Student ID not found.';
    END IF;

    SELECT 
        c.complaint_id,
        c.title,
        c.category,
        c.priority,
        c.status,
        c.created_at,
        c.updated_at,
        CONCAT(l.building_name, ' (', l.room_number, ')') AS location_name,
        l.location_type,
        f.rating AS student_rating,
        f.comments AS feedback_comments
    FROM complaints c
    INNER JOIN locations l ON c.location_id = l.location_id
    LEFT JOIN feedback f ON c.complaint_id = f.complaint_id
    WHERE c.student_id = p_student_id
    ORDER BY c.created_at DESC;
END //

-- -----------------------------------------------------------------------------
-- Procedure 4: sp_get_department_report
-- Purpose: Generates high-level operational metrics for a specific department.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE sp_get_department_report (
    IN p_department_id INT
)
BEGIN
    DECLARE v_dept_exists INT DEFAULT 0;
    DECLARE v_dept_name VARCHAR(100);

    SELECT COUNT(*), MAX(department_name) 
    INTO v_dept_exists, v_dept_name
    FROM departments 
    WHERE department_id = p_department_id;

    IF v_dept_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Execution Error: Department ID not found.';
    END IF;

    SELECT 
        p_department_id AS department_id,
        v_dept_name AS department_name,
        COUNT(DISTINCT c.complaint_id) AS total_complaints,
        COUNT(DISTINCT CASE WHEN c.status IN ('Resolved', 'RESOLVED', 'Closed', 'CLOSED') THEN c.complaint_id END) AS resolved_complaints,
        COUNT(DISTINCT CASE WHEN c.status IN ('In Progress', 'IN_PROGRESS') THEN c.complaint_id END) AS in_progress_complaints,
        COUNT(DISTINCT CASE WHEN c.status IN ('Pending', 'PENDING', 'Assigned', 'ASSIGNED') THEN c.complaint_id END) AS pending_complaints,
        ROUND(AVG(f.rating), 2) AS average_satisfaction_rating,
        ROUND(COUNT(DISTINCT CASE WHEN c.status IN ('Resolved', 'RESOLVED', 'Closed', 'CLOSED') THEN c.complaint_id END) * 100.0 / 
              NULLIF(COUNT(DISTINCT c.complaint_id), 0), 1) AS resolution_rate_percentage
    FROM departments d
    LEFT JOIN students s ON d.department_id = s.department_id
    LEFT JOIN complaints c ON s.student_id = c.student_id
    LEFT JOIN feedback f ON c.complaint_id = f.complaint_id
    WHERE d.department_id = p_department_id
    GROUP BY d.department_id, d.department_name;
END //

DELIMITER ;
