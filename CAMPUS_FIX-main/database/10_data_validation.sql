-- =============================================================================
-- CAMPUSFIX: Smart Campus Complaint & Maintenance Management System
-- Script: 10_data_validation.sql
-- Description: Automated data integrity and relational validation script.
--              Verifies record counts, referential integrity, domain constraints,
--              uniqueness, and cross-table logical consistency.
-- Target RDBMS: MySQL 8.0+
-- Execution Order: 10
-- =============================================================================

USE campusfix;

-- =============================================================================
-- 1. RECORD COUNT VERIFICATION AGAINST TARGET THRESHOLDS
-- =============================================================================
SELECT 
    'Table Record Counts' AS audit_category,
    t.table_name,
    t.actual_count,
    t.min_required,
    CASE 
        WHEN t.actual_count >= t.min_required THEN 'PASS' 
        ELSE 'FAIL - INSUFFICIENT DATA' 
    END AS audit_status
FROM (
    SELECT 'departments' AS table_name, COUNT(*) AS actual_count, 5 AS min_required FROM departments
    UNION ALL SELECT 'locations', COUNT(*), 12 FROM locations
    UNION ALL SELECT 'students', COUNT(*), 20 FROM students
    UNION ALL SELECT 'staff', COUNT(*), 10 FROM staff
    UNION ALL SELECT 'complaints', COUNT(*), 35 FROM complaints
    UNION ALL SELECT 'complaint_assignments', COUNT(*), 35 FROM complaint_assignments
    UNION ALL SELECT 'complaint_status_history', COUNT(*), 50 FROM complaint_status_history
    UNION ALL SELECT 'feedback', COUNT(*), 15 FROM feedback
) AS t;

-- =============================================================================
-- 2. ORPHANED FOREIGN KEY AUDIT (Must return 0 rows for PASS)
-- =============================================================================

-- A. Students with invalid department
SELECT 'students -> departments' AS relationship, COUNT(*) AS orphan_count,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL - ORPHANS DETECTED' END AS status
FROM students s
LEFT JOIN departments d ON s.department_id = d.department_id
WHERE d.department_id IS NULL;

-- B. Staff with invalid department
SELECT 'staff -> departments' AS relationship, COUNT(*) AS orphan_count,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL - ORPHANS DETECTED' END AS status
FROM staff st
LEFT JOIN departments d ON st.department_id = d.department_id
WHERE d.department_id IS NULL;

-- C. Complaints with invalid student or location
SELECT 'complaints -> students' AS relationship, COUNT(*) AS orphan_count,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL - ORPHANS DETECTED' END AS status
FROM complaints c
LEFT JOIN students s ON c.student_id = s.student_id
WHERE s.student_id IS NULL;

SELECT 'complaints -> locations' AS relationship, COUNT(*) AS orphan_count,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL - ORPHANS DETECTED' END AS status
FROM complaints c
LEFT JOIN locations l ON c.location_id = l.location_id
WHERE l.location_id IS NULL;

-- D. Assignments with invalid complaint or staff
SELECT 'assignments -> complaints' AS relationship, COUNT(*) AS orphan_count,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL - ORPHANS DETECTED' END AS status
FROM complaint_assignments ca
LEFT JOIN complaints c ON ca.complaint_id = c.complaint_id
WHERE c.complaint_id IS NULL;

SELECT 'assignments -> staff' AS relationship, COUNT(*) AS orphan_count,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL - ORPHANS DETECTED' END AS status
FROM complaint_assignments ca
LEFT JOIN staff st ON ca.staff_id = st.staff_id
WHERE st.staff_id IS NULL;

-- E. Status History with invalid complaint
SELECT 'history -> complaints' AS relationship, COUNT(*) AS orphan_count,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL - ORPHANS DETECTED' END AS status
FROM complaint_status_history csh
LEFT JOIN complaints c ON csh.complaint_id = c.complaint_id
WHERE c.complaint_id IS NULL;

-- F. Feedback with invalid complaint or student
SELECT 'feedback -> complaints' AS relationship, COUNT(*) AS orphan_count,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL - ORPHANS DETECTED' END AS status
FROM feedback f
LEFT JOIN complaints c ON f.complaint_id = c.complaint_id
WHERE c.complaint_id IS NULL;

SELECT 'feedback -> students' AS relationship, COUNT(*) AS orphan_count,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL - ORPHANS DETECTED' END AS status
FROM feedback f
LEFT JOIN students s ON f.student_id = s.student_id
WHERE s.student_id IS NULL;

-- =============================================================================
-- 3. UNIQUENESS CONSTRAINT AUDIT (Must return 0 rows for PASS)
-- =============================================================================

-- A. Duplicate department names
SELECT 'departments.department_name' AS constraint_target, department_name, COUNT(*) AS duplicate_count
FROM departments
GROUP BY department_name
HAVING COUNT(*) > 1;

-- B. Duplicate student emails
SELECT 'students.email' AS constraint_target, email, COUNT(*) AS duplicate_count
FROM students
GROUP BY email
HAVING COUNT(*) > 1;

-- C. Duplicate staff emails
SELECT 'staff.email' AS constraint_target, email, COUNT(*) AS duplicate_count
FROM staff
GROUP BY email
HAVING COUNT(*) > 1;

-- D. Duplicate feedback per complaint (1:0..1 enforcement)
SELECT 'feedback.complaint_id' AS constraint_target, complaint_id, COUNT(*) AS duplicate_count
FROM feedback
GROUP BY complaint_id
HAVING COUNT(*) > 1;

-- E. Duplicate rooms within the same building (locations composite uniqueness)
SELECT 'locations(building_name, room_number)' AS constraint_target, building_name, room_number, COUNT(*) AS duplicate_count
FROM locations
GROUP BY building_name, room_number
HAVING COUNT(*) > 1;

-- =============================================================================
-- 4. DOMAIN CHECK CONSTRAINT AUDIT (Must return 0 rows for PASS)
-- =============================================================================

-- A. Feedback ratings outside [1, 5]
SELECT 'feedback.rating range [1,5]' AS check_target, COUNT(*) AS violation_count,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL - INVALID RATING' END AS status
FROM feedback
WHERE rating NOT BETWEEN 1 AND 5;

-- B. Complaints with invalid priority values
SELECT 'complaints.priority domain' AS check_target, COUNT(*) AS violation_count,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL - INVALID PRIORITY' END AS status
FROM complaints
WHERE priority NOT IN ('Low', 'Medium', 'High', 'Critical', 'Urgent',
                       'LOW', 'MEDIUM', 'HIGH', 'CRITICAL', 'URGENT');

-- C. Complaints with invalid status values
SELECT 'complaints.status domain' AS check_target, COUNT(*) AS violation_count,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL - INVALID STATUS' END AS status
FROM complaints
WHERE status NOT IN ('Pending', 'Assigned', 'In Progress', 'Resolved', 'Rejected', 'Closed',
                     'PENDING', 'ASSIGNED', 'IN_PROGRESS', 'RESOLVED', 'REJECTED', 'CLOSED', 'SUBMITTED');

-- =============================================================================
-- 5. CROSS-TABLE SEMANTIC CONSISTENCY (Must return 0 violations for PASS)
-- =============================================================================

-- A. Ensure feedback.student_id matches complaints.student_id
-- (A student can only review a complaint they originally filed)
SELECT 
    'Feedback Author Consistency' AS audit_test,
    COUNT(*) AS mismatch_count,
    CASE 
        WHEN COUNT(*) = 0 THEN 'PASS' 
        ELSE 'FAIL - STUDENT AUTHOR MISMATCH' 
    END AS audit_status
FROM feedback f
JOIN complaints c ON f.complaint_id = c.complaint_id
WHERE f.student_id <> c.student_id;

-- B. Ensure feedback is only recorded for complaints that reached 'Resolved' status
SELECT 
    'Feedback Status Pre-Condition' AS audit_test,
    COUNT(*) AS premature_feedback_count,
    CASE 
        WHEN COUNT(*) = 0 THEN 'PASS' 
        ELSE 'FAIL - FEEDBACK ON UNRESOLVED TICKET' 
    END AS audit_status
FROM feedback f
JOIN complaints c ON f.complaint_id = c.complaint_id
WHERE c.status NOT IN ('Resolved', 'RESOLVED', 'Closed', 'CLOSED');

-- C. Ensure all assigned / in-progress / resolved complaints have an assignment entry
SELECT 
    'Assignment Completeness' AS audit_test,
    COUNT(*) AS unassigned_progressed_count,
    CASE 
        WHEN COUNT(*) = 0 THEN 'PASS' 
        ELSE 'FAIL - UNASSIGNED ACTIVE COMPLAINT' 
    END AS audit_status
FROM complaints c
LEFT JOIN complaint_assignments ca ON c.complaint_id = ca.complaint_id
WHERE c.status IN ('Assigned', 'In Progress', 'Resolved')
  AND ca.assignment_id IS NULL;

-- =============================================================================
-- 6. FINAL INTEGRITY SUMMARY
-- =============================================================================
SELECT 'DATA INTEGRITY VALIDATION COMPLETED' AS summary_status, NOW() AS audited_at;
