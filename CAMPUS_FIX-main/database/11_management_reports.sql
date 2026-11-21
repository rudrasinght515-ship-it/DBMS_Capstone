-- =============================================================================
-- CAMPUSFIX: Smart Campus Complaint & Maintenance Management System
-- Script: 11_management_reports.sql
-- Description: Executive Management & Operational KPI Reporting Suite.
--              Contains 10 specialized reports for institutional oversight,
--              workload monitoring, infrastructure reliability, and SLA auditing.
-- Target RDBMS: MySQL 8.0+
-- Execution Order: 11
-- =============================================================================

USE campusfix;

-- =============================================================================
-- REPORT 1: TOTAL COMPLAINTS BY DEPARTMENT (ORIGINATION & WORKLOAD IMPACT)
-- Business Value: Identifies which academic divisions generate the greatest
--                 volume of maintenance demands across campus.
-- =============================================================================
SELECT 
    d.department_id,
    d.department_name,
    COUNT(c.complaint_id) AS total_complaints_filed,
    SUM(CASE WHEN c.status IN ('Resolved', 'RESOLVED', 'Closed', 'CLOSED') THEN 1 ELSE 0 END) AS resolved_count,
    SUM(CASE WHEN c.status IN ('In Progress', 'IN_PROGRESS') THEN 1 ELSE 0 END) AS in_progress_count,
    SUM(CASE WHEN c.status IN ('Pending', 'PENDING', 'Assigned', 'ASSIGNED') THEN 1 ELSE 0 END) AS pending_count,
    SUM(CASE WHEN c.status IN ('Rejected', 'REJECTED') THEN 1 ELSE 0 END) AS rejected_count,
    ROUND(SUM(CASE WHEN c.status IN ('Resolved', 'RESOLVED', 'Closed', 'CLOSED') THEN 1 ELSE 0 END) * 100.0 / 
          NULLIF(COUNT(c.complaint_id), 0), 1) AS department_resolution_rate_pct
FROM departments d
LEFT JOIN students s ON d.department_id = s.department_id
LEFT JOIN complaints c ON s.student_id = c.student_id
GROUP BY d.department_id, d.department_name
ORDER BY total_complaints_filed DESC;

-- =============================================================================
-- REPORT 2: PENDING COMPLAINTS BACKLOG BY PRIORITY & SLA URGENCY
-- Business Value: Critical triage queue for facilities dispatchers showing
--                 unresolved tickets prioritized by severity and waiting time.
-- =============================================================================
SELECT 
    c.priority,
    COUNT(*) AS pending_ticket_count,
    MIN(c.created_at) AS oldest_pending_ticket,
    MAX(c.created_at) AS newest_pending_ticket,
    ROUND(AVG(TIMESTAMPDIFF(HOUR, c.created_at, NOW())), 1) AS avg_wait_time_hours,
    MAX(TIMESTAMPDIFF(HOUR, c.created_at, NOW())) AS max_wait_time_hours,
    CASE c.priority
        WHEN 'Critical' THEN 'Emergency SLA: Target Dispatch Within 2 Hours'
        WHEN 'High'     THEN 'High SLA: Target Resolution Within 8 Hours'
        WHEN 'Medium'   THEN 'Standard SLA: Target Resolution 24-48 Hours'
        WHEN 'Low'      THEN 'Routine SLA: Target Resolution 3-5 Days'
    END AS target_sla_window
FROM complaints c
WHERE c.status IN ('Pending', 'Assigned', 'PENDING', 'ASSIGNED')
GROUP BY c.priority
ORDER BY 
    CASE c.priority 
        WHEN 'Critical' THEN 1 
        WHEN 'High' THEN 2 
        WHEN 'Medium' THEN 3 
        ELSE 4 
    END;

-- =============================================================================
-- REPORT 3: STAFF WORKLOAD & RESOLUTION PERFORMANCE REPORT
-- Business Value: Balances staff assignments and audits technician turnaround.
--                 Uses COUNT(DISTINCT) to eliminate duplicate assignment rows.
-- =============================================================================
SELECT 
    st.staff_id,
    st.full_name AS staff_name,
    st.role AS staff_role,
    d.department_name,
    COUNT(DISTINCT ca.complaint_id) AS total_assigned_tickets,
    COUNT(DISTINCT CASE WHEN c.status IN ('In Progress', 'IN_PROGRESS', 'Assigned', 'ASSIGNED') THEN ca.complaint_id END) AS active_load,
    COUNT(DISTINCT CASE WHEN c.status IN ('Resolved', 'RESOLVED', 'Closed', 'CLOSED') THEN ca.complaint_id END) AS completed_tickets,
    ROUND(COUNT(DISTINCT CASE WHEN c.status IN ('Resolved', 'RESOLVED', 'Closed', 'CLOSED') THEN ca.complaint_id END) * 100.0 / 
          NULLIF(COUNT(DISTINCT ca.complaint_id), 0), 1) AS technician_completion_pct,
    ROUND(AVG(f.rating), 2) AS avg_technician_satisfaction_rating
FROM staff st
JOIN departments d ON st.department_id = d.department_id
LEFT JOIN complaint_assignments ca ON st.staff_id = ca.staff_id
LEFT JOIN complaints c ON ca.complaint_id = c.complaint_id
LEFT JOIN feedback f ON c.complaint_id = f.complaint_id
GROUP BY st.staff_id, st.full_name, st.role, d.department_name
ORDER BY active_load DESC, total_assigned_tickets DESC;

-- =============================================================================
-- REPORT 4: CAMPUS-WIDE COMPLAINT RESOLUTION RATE & OPERATIONAL KPI
-- Business Value: High-level executive scorecard summarizing total volume,
--                 resolution efficiency, and average turnaround duration.
-- =============================================================================
SELECT 
    COUNT(*) AS total_recorded_complaints,
    SUM(CASE WHEN status IN ('Resolved', 'RESOLVED', 'Closed', 'CLOSED') THEN 1 ELSE 0 END) AS total_resolved,
    SUM(CASE WHEN status IN ('In Progress', 'IN_PROGRESS') THEN 1 ELSE 0 END) AS total_in_progress,
    SUM(CASE WHEN status IN ('Assigned', 'ASSIGNED') THEN 1 ELSE 0 END) AS total_assigned_unstarted,
    SUM(CASE WHEN status IN ('Pending', 'PENDING') THEN 1 ELSE 0 END) AS total_unassigned_pending,
    SUM(CASE WHEN status IN ('Rejected', 'REJECTED') THEN 1 ELSE 0 END) AS total_rejected_invalid,
    ROUND(SUM(CASE WHEN status IN ('Resolved', 'RESOLVED', 'Closed', 'CLOSED') THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS campus_resolution_rate_pct,
    ROUND(AVG(CASE WHEN status = 'Resolved' THEN TIMESTAMPDIFF(HOUR, created_at, updated_at) END), 1) AS avg_turnaround_hours_resolved
FROM complaints;

-- =============================================================================
-- REPORT 5: STUDENT SATISFACTION INDEX & RATING DISTRIBUTION
-- Business Value: Measures qualitative and quantitative student satisfaction
--                 across departments and tracks rating distribution percentiles.
-- =============================================================================
SELECT 
    COUNT(f.feedback_id) AS total_feedbacks_submitted,
    ROUND(AVG(f.rating), 2) AS overall_satisfaction_index,
    SUM(CASE WHEN f.rating = 5 THEN 1 ELSE 0 END) AS count_5_star_excellent,
    SUM(CASE WHEN f.rating = 4 THEN 1 ELSE 0 END) AS count_4_star_good,
    SUM(CASE WHEN f.rating = 3 THEN 1 ELSE 0 END) AS count_3_star_average,
    SUM(CASE WHEN f.rating <= 2 THEN 1 ELSE 0 END) AS count_subpar_ratings,
    ROUND(SUM(CASE WHEN f.rating >= 4 THEN 1 ELSE 0 END) * 100.0 / COUNT(f.feedback_id), 1) AS satisfaction_approval_rate_pct
FROM feedback f;

-- =============================================================================
-- REPORT 6: MOST REPORTED COMPLAINT CATEGORIES (PARETO RELIABILITY ANALYSIS)
-- Business Value: Details breakdown of failure domains to target preventive
--                 maintenance investments (e.g. electrical vs plumbing vs IT).
-- =============================================================================
SELECT 
    category,
    COUNT(*) AS incident_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM complaints), 1) AS percentage_of_total_incidents,
    SUM(CASE WHEN priority = 'Critical' THEN 1 ELSE 0 END) AS critical_severity_count,
    SUM(CASE WHEN priority = 'High' THEN 1 ELSE 0 END) AS high_severity_count,
    ROUND(AVG(CASE WHEN status = 'Resolved' THEN TIMESTAMPDIFF(HOUR, created_at, updated_at) END), 1) AS avg_category_resolution_hours
FROM complaints
GROUP BY category
ORDER BY incident_count DESC;

-- =============================================================================
-- REPORT 7: MONTHLY COMPLAINT VOLUME & RESOLUTION TRENDS
-- Business Value: Time-series analysis enabling institutional planning, budget
--                 allocation, and seasonal infrastructure load tracking.
-- =============================================================================
SELECT 
    YEAR(created_at) AS report_year,
    MONTH(created_at) AS report_month,
    MONTHNAME(created_at) AS month_name,
    COUNT(*) AS total_complaints_logged,
    SUM(CASE WHEN status IN ('Resolved', 'RESOLVED', 'Closed', 'CLOSED') THEN 1 ELSE 0 END) AS total_resolved,
    SUM(CASE WHEN status IN ('In Progress', 'IN_PROGRESS', 'Assigned', 'ASSIGNED', 'Pending', 'PENDING') THEN 1 ELSE 0 END) AS active_at_month_close,
    ROUND(AVG(TIMESTAMPDIFF(HOUR, created_at, updated_at)), 1) AS avg_turnaround_hours
FROM complaints
GROUP BY YEAR(created_at), MONTH(created_at), MONTHNAME(created_at)
ORDER BY report_year DESC, report_month DESC;

-- =============================================================================
-- REPORT 8: INFRASTRUCTURE HOTSPOTS (LOCATIONS WITH MOST INCIDENTS)
-- Business Value: Pinpoints physical campus facilities that suffer recurring
--                 equipment failures requiring capital replacement or overhaul.
-- =============================================================================
SELECT 
    l.location_id,
    l.building_name,
    l.room_number,
    l.location_type,
    COUNT(c.complaint_id) AS total_reported_incidents,
    SUM(CASE WHEN c.priority = 'Critical' THEN 1 ELSE 0 END) AS critical_failures,
    SUM(CASE WHEN c.status = 'Resolved' THEN 1 ELSE 0 END) AS resolved_incidents,
    GROUP_CONCAT(DISTINCT c.category ORDER BY c.category SEPARATOR ', ') AS failure_categories_observed
FROM locations l
JOIN complaints c ON l.location_id = c.location_id
GROUP BY l.location_id, l.building_name, l.room_number, l.location_type
ORDER BY total_reported_incidents DESC, critical_failures DESC
LIMIT 10;

-- =============================================================================
-- REPORT 9: STUDENT ENGAGEMENT (STUDENTS WITH HIGHEST COMPLAINT COUNTS)
-- Business Value: Highlights active student contributors to campus maintenance
--                 and validates student satisfaction per individual.
-- =============================================================================
SELECT 
    s.student_id,
    s.full_name AS student_name,
    s.email AS student_email,
    d.department_name,
    COUNT(c.complaint_id) AS total_complaints_filed,
    SUM(CASE WHEN c.status IN ('Resolved', 'RESOLVED') THEN 1 ELSE 0 END) AS resolved_complaints,
    COUNT(f.feedback_id) AS feedback_reviews_submitted,
    ROUND(AVG(f.rating), 2) AS avg_rating_given
FROM students s
JOIN departments d ON s.department_id = d.department_id
JOIN complaints c ON s.student_id = c.student_id
LEFT JOIN feedback f ON c.complaint_id = f.complaint_id
GROUP BY s.student_id, s.full_name, s.email, d.department_name
ORDER BY total_complaints_filed DESC, s.student_id ASC
LIMIT 10;

-- =============================================================================
-- REPORT 10: MEAN TIME TO RESOLUTION (MTTR) BY CATEGORY & PRIORITY
-- Business Value: SLA compliance reporting measuring maintenance efficiency
--                 across combinations of problem domain and urgency level.
-- =============================================================================
SELECT 
    category,
    priority,
    COUNT(*) AS resolved_ticket_volume,
    MIN(TIMESTAMPDIFF(HOUR, created_at, updated_at)) AS fastest_resolution_hours,
    ROUND(AVG(TIMESTAMPDIFF(HOUR, created_at, updated_at)), 1) AS mean_resolution_hours,
    MAX(TIMESTAMPDIFF(HOUR, created_at, updated_at)) AS longest_resolution_hours,
    ROUND(AVG(TIMESTAMPDIFF(HOUR, created_at, updated_at)) / 24.0, 1) AS mean_resolution_days
FROM complaints
WHERE status IN ('Resolved', 'RESOLVED', 'Closed', 'CLOSED')
GROUP BY category, priority
ORDER BY category, 
    CASE priority 
        WHEN 'Critical' THEN 1 
        WHEN 'High' THEN 2 
        WHEN 'Medium' THEN 3 
        ELSE 4 
    END;
