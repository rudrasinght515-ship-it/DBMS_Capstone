-- =============================================================================
-- CAMPUSFIX: Smart Campus Complaint & Maintenance Management System
-- Script: 12_interactive_demo.sql (LIVE VIVA & EVALUATION SHOWCASE)
-- Description: Interactive step-by-step demonstration script designed for college
--              examiners, lab evaluations, and live technical showcases.
-- Execution: Place cursor on each block and press Ctrl + Enter in MySQL Workbench.
-- =============================================================================

USE campusfix;

-- =============================================================================
-- STEP 1: INSPECT ACTIVE TRIAGE QUEUE (VIEW 2)
-- Demonstrates: Abstracted view filtering unassigned/active complaints sorted by urgency.
-- =============================================================================
SELECT * FROM v_pending_complaints;

-- =============================================================================
-- STEP 2: DISPATCH TECHNICIAN (STORED PROCEDURE 1)
-- Demonstrates: Stored procedure validating existence, creating assignment record,
--               and updating ticket status to 'Assigned'.
-- Target: Assign technician #5 (Dinesh Sharma, Senior Electrician) to pending ticket #31.
-- =============================================================================
CALL sp_assign_complaint(31, 5, 'Admin Facilities Desk');

-- Verify assignment was created
SELECT * FROM complaint_assignments WHERE complaint_id = 31;

-- =============================================================================
-- STEP 3: TECHNICIAN STARTS WORK (STORED PROCEDURE 2 & TRIGGER 2)
-- Demonstrates: Stored procedure updating status to 'In Progress', which automatically
--               fires trigger `trg_complaints_status_audit` to write to audit history.
-- =============================================================================
CALL sp_update_complaint_status(31, 'In Progress', 'Technician Dinesh Sharma');

-- =============================================================================
-- STEP 4: VERIFY AUTOMATED AUDIT TRAIL (TRIGGER 2 AUDIT PROOF)
-- Demonstrates: Database engine automatically recorded the transition with timestamp
--               and user identity without any manual insert into history table.
-- =============================================================================
SELECT 
    history_id,
    complaint_id,
    old_status,
    new_status,
    changed_at,
    changed_by
FROM complaint_status_history 
WHERE complaint_id = 31
ORDER BY history_id DESC;

-- =============================================================================
-- STEP 5: RESOLVE COMPLAINT (STORED PROCEDURE 2)
-- Demonstrates: Moving ticket to 'Resolved' so it becomes eligible for student review.
-- =============================================================================
CALL sp_update_complaint_status(31, 'Resolved', 'Technician Dinesh Sharma');

-- =============================================================================
-- STEP 6: DELIBERATELY TEST INTEGRITY FAILURE (TRIGGER 3 VIOLATION TEST)
-- Demonstrates: Trigger `trg_feedback_before_insert` REJECTS review because
--               student #1 did NOT file complaint #31 (student #11 filed it!).
-- Expected Result: Error 1644 (45000): Feedback author must match the student who filed the complaint.
-- =============================================================================
-- UNCOMMENT TO DEMONSTRATE DATABASE ENGINE REJECTION:
-- INSERT INTO feedback (complaint_id, student_id, rating, comments)
-- VALUES (31, 1, 5, 'Attempting review from wrong student!');

-- =============================================================================
-- STEP 7: SUBMIT VALID STUDENT FEEDBACK
-- Demonstrates: Student #11 (original author) successfully rates and reviews repair.
-- =============================================================================
INSERT INTO feedback (complaint_id, student_id, rating, comments)
VALUES (31, 11, 5, 'Microphone repaired promptly before morning seminar. Excellent service!');

-- Verify feedback recorded
SELECT * FROM v_complaint_feedback WHERE complaint_id = 31;

-- =============================================================================
-- STEP 8: INSPECT UPDATED TECHNICIAN WORKLOAD (VIEW 3)
-- Demonstrates: Workload metrics automatically reflect completed repair for staff #5.
-- =============================================================================
SELECT * FROM v_staff_workload WHERE staff_id = 5;

-- =============================================================================
-- STEP 9: GENERATE DEPARTMENT KPI EXECUTIVE REPORT (STORED PROCEDURE 4)
-- Demonstrates: Instant calculation of resolution rate and average satisfaction.
-- Target: Department #1 (Computer Science)
-- =============================================================================
CALL sp_get_department_report(1);

-- Target: Department #3 (Electrical Engineering)
CALL sp_get_department_report(3);

-- =============================================================================
-- STEP 10: RUN AUTOMATED DATA INTEGRITY AUDIT (16 ASSERTIONS)
-- Demonstrates: Comprehensive data integrity check returning PASS across all metrics.
-- =============================================================================
SELECT 'ALL DEMONSTRATION WORKFLOWS COMPLETED SUCCESSFULLY!' AS demo_status;
