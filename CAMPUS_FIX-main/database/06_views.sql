-- =============================================================================
-- CAMPUSFIX: Smart Campus Complaint & Maintenance Management System
-- Script: 06_views.sql
-- Description: Reusable, abstracted database views for students, maintenance
--              staff, and campus administrators.
-- Target RDBMS: MySQL 8.0+
-- Execution Order: 06
-- =============================================================================

USE campusfix;

-- -----------------------------------------------------------------------------
-- View 1: v_complaint_details
-- Purpose: Unified operational view combining complaint data with student,
--          department, and physical location details.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_complaint_details AS
SELECT 
    c.complaint_id,
    c.title,
    c.description,
    c.category,
    c.priority,
    c.status,
    c.created_at,
    c.updated_at,
    s.student_id,
    s.full_name AS student_name,
    s.email AS student_email,
    s.phone AS student_phone,
    d.department_id,
    d.department_name,
    l.location_id,
    l.building_name,
    l.room_number,
    l.location_type,
    CONCAT(l.building_name, ' (', l.room_number, ')') AS location_summary
FROM complaints c
INNER JOIN students s ON c.student_id = s.student_id
INNER JOIN departments d ON s.department_id = d.department_id
INNER JOIN locations l ON c.location_id = l.location_id;

-- -----------------------------------------------------------------------------
-- View 2: v_pending_complaints
-- Purpose: Triage view for facility administrators displaying all unresolved
--          complaints currently in 'Pending' or 'Assigned' status.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_pending_complaints AS
SELECT 
    c.complaint_id,
    c.title,
    c.category,
    c.priority,
    c.status,
    c.created_at,
    TIMESTAMPDIFF(HOUR, c.created_at, NOW()) AS age_hours,
    s.full_name AS student_name,
    d.department_name,
    CONCAT(l.building_name, ' | Rm ', l.room_number) AS location_summary
FROM complaints c
INNER JOIN students s ON c.student_id = s.student_id
INNER JOIN departments d ON s.department_id = d.department_id
INNER JOIN locations l ON c.location_id = l.location_id
WHERE c.status IN ('Pending', 'Assigned', 'PENDING', 'ASSIGNED')
ORDER BY 
    CASE c.priority 
        WHEN 'Critical' THEN 1 
        WHEN 'High' THEN 2 
        WHEN 'Medium' THEN 3 
        ELSE 4 
    END,
    c.created_at ASC;

-- -----------------------------------------------------------------------------
-- View 3: v_staff_workload
-- Purpose: Staff allocation and performance monitoring view.
--          CRITICAL: Uses COUNT(DISTINCT ...) to strictly prevent double-counting
--          of complaints where multiple technician assignment records exist.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_staff_workload AS
SELECT 
    st.staff_id,
    st.full_name AS staff_name,
    st.role AS staff_role,
    d.department_name,
    COUNT(DISTINCT ca.complaint_id) AS total_assigned_complaints,
    COUNT(DISTINCT CASE 
        WHEN c.status IN ('Assigned', 'In Progress', 'ASSIGNED', 'IN_PROGRESS') 
        THEN ca.complaint_id 
    END) AS active_complaints,
    COUNT(DISTINCT CASE 
        WHEN c.status IN ('Resolved', 'RESOLVED', 'Closed', 'CLOSED') 
        THEN ca.complaint_id 
    END) AS resolved_complaints
FROM staff st
INNER JOIN departments d ON st.department_id = d.department_id
LEFT JOIN complaint_assignments ca ON st.staff_id = ca.staff_id
LEFT JOIN complaints c ON ca.complaint_id = c.complaint_id
GROUP BY 
    st.staff_id, 
    st.full_name, 
    st.role, 
    d.department_name;

-- -----------------------------------------------------------------------------
-- View 4: v_department_statistics
-- Purpose: Institutional KPI dashboard aggregating complaint counts, resolution
--          rates, and average satisfaction ratings by academic department.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_department_statistics AS
SELECT 
    d.department_id,
    d.department_name,
    COUNT(DISTINCT c.complaint_id) AS total_complaints,
    COUNT(DISTINCT CASE 
        WHEN c.status IN ('Resolved', 'RESOLVED', 'Closed', 'CLOSED') 
        THEN c.complaint_id 
    END) AS resolved_complaints,
    COUNT(DISTINCT CASE 
        WHEN c.status IN ('Pending', 'Assigned', 'In Progress', 'PENDING', 'ASSIGNED', 'IN_PROGRESS') 
        THEN c.complaint_id 
    END) AS pending_complaints,
    ROUND(AVG(f.rating), 2) AS average_feedback_rating
FROM departments d
LEFT JOIN students s ON d.department_id = s.department_id
LEFT JOIN complaints c ON s.student_id = c.student_id
LEFT JOIN feedback f ON c.complaint_id = f.complaint_id
GROUP BY 
    d.department_id, 
    d.department_name;

-- -----------------------------------------------------------------------------
-- View 5: v_complaint_feedback
-- Purpose: Combines complaint ticket history with student satisfaction ratings
--          and qualitative feedback comments (LEFT JOIN preserves unrated tickets).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_complaint_feedback AS
SELECT 
    c.complaint_id,
    c.title,
    c.category,
    c.status AS complaint_status,
    c.created_at AS complaint_filed_at,
    s.student_id,
    s.full_name AS student_name,
    f.feedback_id,
    f.rating,
    f.comments AS feedback_comments,
    f.submitted_at AS feedback_submitted_at
FROM complaints c
INNER JOIN students s ON c.student_id = s.student_id
LEFT JOIN feedback f ON c.complaint_id = f.complaint_id;

-- -----------------------------------------------------------------------------
-- Verification Sample Queries for the Views
-- -----------------------------------------------------------------------------
SELECT 'v_complaint_details' AS view_name, COUNT(*) AS record_count FROM v_complaint_details
UNION ALL
SELECT 'v_pending_complaints', COUNT(*) FROM v_pending_complaints
UNION ALL
SELECT 'v_staff_workload', COUNT(*) FROM v_staff_workload
UNION ALL
SELECT 'v_department_statistics', COUNT(*) FROM v_department_statistics
UNION ALL
SELECT 'v_complaint_feedback', COUNT(*) FROM v_complaint_feedback;
