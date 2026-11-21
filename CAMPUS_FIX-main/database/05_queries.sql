-- =============================================================================
-- CAMPUSFIX: Smart Campus Complaint & Maintenance Management System
-- Script: 05_queries.sql
-- Description: Practical and comprehensive SQL queries demonstrating foundational
--              operations, aggregations, groupings, multi-table joins, subqueries,
--              conditional expressions, temporal/string functions, and query plan
--              performance analysis with EXPLAIN.
-- Target RDBMS: MySQL 8.0+
-- Execution Order: 05
-- =============================================================================

USE campusfix;

-- =============================================================================
-- SECTION 1: BASIC SQL OPERATIONS (DML & DQL)
-- =============================================================================

-- 1.1 SELECT & WHERE: Filter complaints by critical urgency
-- Concept: Basic projection and predicate filtering.
SELECT 
    complaint_id,
    title,
    category,
    priority,
    status,
    created_at
FROM complaints
WHERE priority = 'Critical';

-- 1.2 DISTINCT: Retrieve all distinct complaint categories currently logged
-- Concept: Eliminating duplicate row values in the result set.
SELECT DISTINCT 
    category 
FROM complaints
ORDER BY category ASC;

-- 1.3 ORDER BY & LIMIT: Retrieve the 5 most recently logged complaints
-- Concept: Result set sorting (descending) and pagination limiter.
SELECT 
    complaint_id,
    title,
    priority,
    status,
    created_at
FROM complaints
ORDER BY created_at DESC
LIMIT 5;

-- 1.4 BETWEEN: Find complaints registered during the first week of October 2026
-- Concept: Inclusive range comparison on temporal attributes.
SELECT 
    complaint_id,
    title,
    category,
    created_at
FROM complaints
WHERE created_at BETWEEN '2026-10-01 00:00:00' AND '2026-10-07 23:59:59'
ORDER BY created_at ASC;

-- 1.5 IN: Filter complaints belonging to specific critical infrastructure categories
-- Concept: Discrete set membership testing.
SELECT 
    complaint_id,
    title,
    category,
    priority,
    status
FROM complaints
WHERE category IN ('Electrical', 'Internet', 'Plumbing')
ORDER BY category, priority;

-- 1.6 LIKE: Search for complaints containing specific equipment keywords
-- Concept: Pattern matching using the wildcard character '%'.
SELECT 
    complaint_id,
    title,
    description
FROM complaints
WHERE title LIKE '%projector%' 
   OR description LIKE '%wi-fi%'
   OR description LIKE '%wifi%';

-- 1.7 IS NULL: Find initial status transitions where there was no previous status
-- Concept: Three-valued logic (3VL) testing for NULL existence.
SELECT 
    history_id,
    complaint_id,
    old_status,
    new_status,
    changed_at,
    changed_by
FROM complaint_status_history
WHERE old_status IS NULL;

-- 1.8 UPDATE Demonstration: Escalate priority of an unresolved complaint
-- Concept: Data modification with atomic transaction rollback to preserve seed data.
START TRANSACTION;

UPDATE complaints
SET priority = 'Critical',
    updated_at = NOW()
WHERE complaint_id = 25 
  AND status = 'Assigned';

-- Verify the update within the transaction scope
SELECT complaint_id, title, priority, updated_at 
FROM complaints 
WHERE complaint_id = 25;

-- Rollback immediately to preserve original baseline data
ROLLBACK;

-- 1.9 DELETE Demonstration: Demonstrate safe deletion within transaction boundary
-- Concept: Tuple deletion, relational cascade validation, and transaction abort.
START TRANSACTION;

-- Insert a temporary test record
INSERT INTO locations (location_id, building_name, room_number, location_type)
VALUES (999, 'Test Annex', 'TEMP-01', 'Storage');

-- Delete the temporary test record
DELETE FROM locations 
WHERE location_id = 999;

-- Verify deletion
SELECT * FROM locations WHERE location_id = 999;

ROLLBACK;


-- =============================================================================
-- SECTION 2: AGGREGATE FUNCTIONS
-- =============================================================================

-- 2.1 Total complaints and distinct reporting students
-- Concept: COUNT(*) vs COUNT(DISTINCT column).
SELECT 
    COUNT(*) AS total_complaints,
    COUNT(DISTINCT student_id) AS total_reporting_students,
    COUNT(DISTINCT location_id) AS affected_locations
FROM complaints;

-- 2.2 Satisfaction metrics: Average, Minimum, Maximum, and Sum of ratings
-- Concept: Numeric aggregations across student feedback.
SELECT 
    COUNT(*) AS total_feedbacks_received,
    ROUND(AVG(rating), 2) AS average_satisfaction_rating,
    MIN(rating) AS lowest_rating_given,
    MAX(rating) AS highest_rating_given,
    SUM(rating) AS total_score_sum
FROM feedback;

-- 2.3 Total resolved complaints count and percentage
-- Concept: Conditional aggregation using SUM with boolean expressions.
SELECT 
    COUNT(*) AS total_complaints,
    SUM(CASE WHEN status = 'Resolved' THEN 1 ELSE 0 END) AS total_resolved,
    ROUND(SUM(CASE WHEN status = 'Resolved' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS resolution_percentage
FROM complaints;

-- 2.4 Complaints count per category with priority extremes
-- Concept: Aggregating grouped records with descriptive summaries.
SELECT 
    category,
    COUNT(*) AS complaint_count,
    SUM(CASE WHEN priority = 'Critical' THEN 1 ELSE 0 END) AS critical_count,
    SUM(CASE WHEN priority = 'High' THEN 1 ELSE 0 END) AS high_count
FROM complaints
GROUP BY category
ORDER BY complaint_count DESC;

-- 2.5 Workload distribution: Complaints assigned to each maintenance technician
-- Concept: Aggregation over a foreign-key join relationship.
SELECT 
    st.staff_id,
    st.full_name AS technician_name,
    st.role,
    d.department_name,
    COUNT(ca.assignment_id) AS total_assigned_tasks
FROM staff st
JOIN departments d ON st.department_id = d.department_id
LEFT JOIN complaint_assignments ca ON st.staff_id = ca.staff_id
GROUP BY st.staff_id, st.full_name, st.role, d.department_name
ORDER BY total_assigned_tasks DESC;


-- =============================================================================
-- SECTION 3: GROUP BY AND HAVING
-- =============================================================================

-- 3.1 GROUP BY complaint status
-- Concept: Partitioning rows by categorical lifecycle state.
SELECT 
    status,
    COUNT(*) AS status_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM complaints), 1) AS pct_of_total
FROM complaints
GROUP BY status
ORDER BY status_count DESC;

-- 3.2 GROUP BY priority level
-- Concept: Distribution of operational urgency.
SELECT 
    priority,
    COUNT(*) AS complaint_count
FROM complaints
GROUP BY priority
ORDER BY 
    CASE priority 
        WHEN 'Critical' THEN 1 
        WHEN 'High' THEN 2 
        WHEN 'Medium' THEN 3 
        WHEN 'Low' THEN 4 
    END;

-- 3.3 GROUP BY student department (complaint origination)
-- Concept: Aggregating across parent entity attributes.
SELECT 
    d.department_name,
    COUNT(c.complaint_id) AS complaints_filed
FROM departments d
JOIN students s ON d.department_id = s.department_id
LEFT JOIN complaints c ON s.student_id = c.student_id
GROUP BY d.department_name
ORDER BY complaints_filed DESC;

-- 3.4 HAVING: Categories having more than 4 recorded complaints
-- Concept: Post-aggregation group filtering using HAVING.
SELECT 
    category,
    COUNT(*) AS total_complaints,
    ROUND(AVG(CASE WHEN f.rating IS NOT NULL THEN f.rating ELSE NULL END), 2) AS avg_category_rating
FROM complaints c
LEFT JOIN feedback f ON c.complaint_id = f.complaint_id
GROUP BY category
HAVING COUNT(*) > 4
ORDER BY total_complaints DESC;

-- 3.5 HAVING: Locations with multiple complaints and at least one Critical complaint
-- Concept: Compound filtering conditions in the HAVING clause.
SELECT 
    l.building_name,
    l.room_number,
    COUNT(c.complaint_id) AS incident_count,
    SUM(CASE WHEN c.priority = 'Critical' THEN 1 ELSE 0 END) AS critical_incidents
FROM locations l
JOIN complaints c ON l.location_id = c.location_id
GROUP BY l.location_id, l.building_name, l.room_number
HAVING COUNT(c.complaint_id) >= 2 
   AND SUM(CASE WHEN c.priority = 'Critical' THEN 1 ELSE 0 END) >= 1
ORDER BY incident_count DESC;


-- =============================================================================
-- SECTION 4: SQL JOINS
-- =============================================================================

-- 4.1 INNER JOIN: Students with their academic Department
-- Explanation: Returns only students with a valid matching department.
SELECT 
    s.student_id,
    s.full_name AS student_name,
    s.email AS student_email,
    d.department_name,
    s.enrollment_date
FROM students s
INNER JOIN departments d ON s.department_id = d.department_id
ORDER BY s.student_id ASC;

-- 4.2 INNER JOIN: Multi-table join connecting Complaints, Students, Locations & Departments
-- Explanation: Returns complaints where student, location, and department all exist.
SELECT 
    c.complaint_id,
    c.title,
    c.category,
    c.priority,
    c.status,
    s.full_name AS reported_by,
    d.department_name AS student_dept,
    CONCAT(l.building_name, ' (', l.room_number, ')') AS location_details
FROM complaints c
INNER JOIN students s ON c.student_id = s.student_id
INNER JOIN departments d ON s.department_id = d.department_id
INNER JOIN locations l ON c.location_id = l.location_id
ORDER BY c.complaint_id ASC;

-- 4.3 LEFT JOIN: All Complaints and their assigned Staff Members
-- Explanation: Returns every complaint. If a complaint is still 'Pending' (no technician assigned),
-- staff fields return NULL.
SELECT 
    c.complaint_id,
    c.title,
    c.status AS complaint_status,
    ca.assigned_at,
    COALESCE(st.full_name, 'Unassigned / Pending Triage') AS assigned_technician,
    COALESCE(st.role, 'N/A') AS technician_role
FROM complaints c
LEFT JOIN complaint_assignments ca ON c.complaint_id = ca.complaint_id
LEFT JOIN staff st ON ca.staff_id = st.staff_id
ORDER BY c.complaint_id ASC;

-- 4.4 LEFT JOIN: All Complaints and their optional Feedback
-- Explanation: Returns all complaints. Complaints that are pending or unresolved have NULL feedback.
SELECT 
    c.complaint_id,
    c.title,
    c.status,
    f.rating,
    COALESCE(f.comments, 'No feedback submitted yet') AS student_review
FROM complaints c
LEFT JOIN feedback f ON c.complaint_id = f.complaint_id
ORDER BY c.complaint_id ASC;

-- 4.5 RIGHT JOIN: All Locations and their incident counts
-- Explanation: Returns all locations from the right table (locations), even if no complaint
-- has occurred in that location (complaint attributes return NULL).
SELECT 
    l.location_id,
    l.building_name,
    l.room_number,
    l.location_type,
    COUNT(c.complaint_id) AS total_incidents
FROM complaints c
RIGHT JOIN locations l ON c.location_id = l.location_id
GROUP BY l.location_id, l.building_name, l.room_number, l.location_type
ORDER BY total_incidents DESC, l.location_id ASC;

-- 4.6 CROSS JOIN: Cartesian Product of Departments and Locations
-- Explanation: Pairs every department with every location, useful for matrix scheduling
-- or facility maintenance inspection coverage audits. (5 depts * 12 locations = 60 rows).
SELECT 
    d.department_name,
    l.building_name,
    l.room_number,
    l.location_type
FROM departments d
CROSS JOIN locations l
WHERE l.location_type = 'Laboratory'
ORDER BY d.department_name, l.building_name;

-- 4.7 SELF JOIN: Detect incident clusters occurring in the exact same location
-- Explanation: Joins the complaints table with itself on matching location_id to identify
-- repeat infrastructure failures in the same physical space.
SELECT 
    c1.location_id,
    l.building_name,
    l.room_number,
    c1.complaint_id AS complaint_1_id,
    c1.title AS incident_1,
    c2.complaint_id AS complaint_2_id,
    c2.title AS incident_2
FROM complaints c1
JOIN complaints c2 ON c1.location_id = c2.location_id AND c1.complaint_id < c2.complaint_id
JOIN locations l ON c1.location_id = l.location_id
ORDER BY c1.location_id, c1.complaint_id;


-- =============================================================================
-- SECTION 5: SUBQUERIES
-- =============================================================================

-- 5.1 Single-Row Subquery: Complaints created after the average creation timestamp
-- Concept: Inner subquery computes scalar scalar average date; outer filters rows.
SELECT 
    complaint_id,
    title,
    priority,
    created_at
FROM complaints
WHERE created_at > (
    SELECT FROM_UNIXTIME(AVG(UNIX_TIMESTAMP(created_at)))
    FROM complaints
)
ORDER BY created_at ASC;

-- 5.2 Multiple-Row Subquery with IN: Students who filed 'Critical' complaints
-- Concept: Inner subquery returns a set of IDs; outer matches with IN.
SELECT 
    student_id,
    full_name,
    email,
    phone
FROM students
WHERE student_id IN (
    SELECT DISTINCT student_id 
    FROM complaints 
    WHERE priority = 'Critical'
);

-- 5.3 Subquery with NOT IN: Students who have never submitted any complaint
-- Concept: Set difference using NOT IN.
SELECT 
    student_id,
    full_name,
    email
FROM students
WHERE student_id NOT IN (
    SELECT DISTINCT student_id 
    FROM complaints 
    WHERE student_id IS NOT NULL
);

-- 5.4 EXISTS: Staff members who have been assigned to at least one 'Critical' complaint
-- Concept: Semi-join optimization; short-circuits upon first matching row.
SELECT 
    st.staff_id,
    st.full_name,
    st.role
FROM staff st
WHERE EXISTS (
    SELECT 1 
    FROM complaint_assignments ca
    JOIN complaints c ON ca.complaint_id = c.complaint_id
    WHERE ca.staff_id = st.staff_id 
      AND c.priority = 'Critical'
);

-- 5.5 NOT EXISTS: Resolved complaints that have not received feedback
-- Concept: Anti-semi-join finding resolved tickets missing customer satisfaction reviews.
SELECT 
    c.complaint_id,
    c.title,
    c.status,
    c.created_at
FROM complaints c
WHERE c.status = 'Resolved'
  AND NOT EXISTS (
      SELECT 1 
      FROM feedback f 
      WHERE f.complaint_id = c.complaint_id
  );

-- 5.6 Correlated Subquery: Staff members assigned more complaints than the staff average
-- Concept: Outer query tuple value evaluated within inner query calculation.
SELECT 
    st.staff_id,
    st.full_name,
    st.role,
    (SELECT COUNT(*) FROM complaint_assignments ca WHERE ca.staff_id = st.staff_id) AS total_assignments
FROM staff st
WHERE (SELECT COUNT(*) FROM complaint_assignments ca WHERE ca.staff_id = st.staff_id) > (
    SELECT COUNT(*) * 1.0 / COUNT(DISTINCT staff_id) FROM staff
)
ORDER BY total_assignments DESC;

-- 5.7 Correlated Subquery: Departments with above-average complaint counts
-- Concept: Department-level aggregation compared against overall department average.
SELECT 
    d.department_id,
    d.department_name,
    COUNT(c.complaint_id) AS department_complaints
FROM departments d
JOIN students s ON d.department_id = s.department_id
JOIN complaints c ON s.student_id = c.student_id
GROUP BY d.department_id, d.department_name
HAVING COUNT(c.complaint_id) > (
    SELECT COUNT(*) * 1.0 / (SELECT COUNT(*) FROM departments) FROM complaints
)
ORDER BY department_complaints DESC;


-- =============================================================================
-- SECTION 6: CASE EXPRESSIONS
-- =============================================================================

-- 6.1 Urgency Classification & SLA Response Window
-- Concept: Mapping categorical priorities to operational action policies.
SELECT 
    complaint_id,
    title,
    category,
    priority,
    CASE priority
        WHEN 'Critical' THEN 'Emergency SLA: 2 Hours (Dispatch Immediate)'
        WHEN 'High'     THEN 'High SLA: 8 Hours (Same-Day Resolution)'
        WHEN 'Medium'   THEN 'Standard SLA: 24-48 Hours'
        WHEN 'Low'      THEN 'Routine SLA: 3-5 Business Days'
        ELSE 'Unclassified'
    END AS sla_service_target
FROM complaints
ORDER BY 
    CASE priority
        WHEN 'Critical' THEN 1
        WHEN 'High'     THEN 2
        WHEN 'Medium'   THEN 3
        ELSE 4
    END;

-- 6.2 Standardized Lifecycle Status Badges
-- Concept: Presenting intuitive progress milestones for UI presentation.
SELECT 
    complaint_id,
    title,
    status AS raw_status,
    CASE status
        WHEN 'Pending'     THEN '[Phase 1] Logged - Pending Administrative Triage'
        WHEN 'Assigned'    THEN '[Phase 2] Allocated to Maintenance Crew'
        WHEN 'In Progress' THEN '[Phase 3] Actively Under Repair'
        WHEN 'Resolved'    THEN '[Phase 4] Repaired - Awaiting Student Verification'
        WHEN 'Rejected'    THEN '[Terminated] Closed as Duplicate/Invalid'
        ELSE 'Unknown State'
    END AS lifecycle_stage_badge
FROM complaints
ORDER BY complaint_id;

-- 6.3 Technician Workload Banding
-- Concept: Categorizing maintenance staff by active assignment volumes.
SELECT 
    st.staff_id,
    st.full_name,
    st.role,
    COUNT(ca.assignment_id) AS assigned_count,
    CASE 
        WHEN COUNT(ca.assignment_id) >= 5 THEN 'Heavy Workload (Review Dispatch)'
        WHEN COUNT(ca.assignment_id) BETWEEN 2 AND 4 THEN 'Balanced Workload'
        WHEN COUNT(ca.assignment_id) = 1 THEN 'Light Workload'
        ELSE 'Available / Idle'
    END AS workload_band
FROM staff st
LEFT JOIN complaint_assignments ca ON st.staff_id = ca.staff_id
GROUP BY st.staff_id, st.full_name, st.role
ORDER BY assigned_count DESC;

-- 6.4 Department Maintenance Risk Index
-- Concept: Weighting complaint severities to establish departmental risk ratings.
SELECT 
    d.department_name,
    COUNT(c.complaint_id) AS total_complaints,
    SUM(CASE WHEN c.priority = 'Critical' THEN 3 WHEN c.priority = 'High' THEN 2 ELSE 1 END) AS weighted_risk_score,
    CASE 
        WHEN SUM(CASE WHEN c.priority = 'Critical' THEN 3 WHEN c.priority = 'High' THEN 2 ELSE 1 END) >= 15 THEN 'High Maintenance Zone'
        WHEN SUM(CASE WHEN c.priority = 'Critical' THEN 3 WHEN c.priority = 'High' THEN 2 ELSE 1 END) BETWEEN 8 AND 14 THEN 'Moderate Maintenance Zone'
        ELSE 'Normal Operating Zone'
    END AS facility_risk_rating
FROM departments d
JOIN students s ON d.department_id = s.department_id
JOIN complaints c ON s.student_id = c.student_id
GROUP BY d.department_name
ORDER BY weighted_risk_score DESC;


-- =============================================================================
-- SECTION 7: DATE AND STRING FUNCTIONS
-- =============================================================================

-- 7.1 Complaint duration and turnaround time in hours and days
-- Concept: TIMESTAMPDIFF and DATEDIFF functions for SLA analytics.
SELECT 
    complaint_id,
    title,
    created_at,
    updated_at,
    TIMESTAMPDIFF(HOUR, created_at, updated_at) AS resolution_time_hours,
    ROUND(TIMESTAMPDIFF(HOUR, created_at, updated_at) / 24.0, 1) AS resolution_time_days
FROM complaints
WHERE status = 'Resolved'
ORDER BY resolution_time_hours ASC;

-- 7.2 Monthly trend aggregation using YEAR(), MONTH(), MONTHNAME()
-- Concept: Temporal bucketing for management time-series reports.
SELECT 
    YEAR(created_at) AS report_year,
    MONTH(created_at) AS report_month_num,
    MONTHNAME(created_at) AS report_month,
    COUNT(*) AS total_complaints_filed,
    SUM(CASE WHEN status = 'Resolved' THEN 1 ELSE 0 END) AS total_resolved
FROM complaints
GROUP BY YEAR(created_at), MONTH(created_at), MONTHNAME(created_at)
ORDER BY report_year, report_month_num;

-- 7.3 String concatenation and case formatting for reporting
-- Concept: CONCAT, UPPER, LOWER, and LENGTH for formatted output.
SELECT 
    c.complaint_id,
    UPPER(c.category) AS formatted_category,
    CONCAT(s.full_name, ' <', LOWER(s.email), '>') AS student_contact_card,
    CONCAT(l.building_name, ' | Rm ', l.room_number) AS physical_location,
    LENGTH(c.description) AS description_char_count,
    CONCAT(LEFT(c.description, 45), '...') AS description_snippet
FROM complaints c
JOIN students s ON c.student_id = s.student_id
JOIN locations l ON c.location_id = l.location_id
LIMIT 10;


-- =============================================================================
-- SECTION 8: INDEXING AND PERFORMANCE ANALYSIS (EXPLAIN)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- PERFORMANCE CONCEPTS EXPLAINED:
--
-- 1. How Indexes Improve Performance:
--    - Without an index, MySQL must perform a Full Table Scan (type: ALL), reading
--      every row from disk into memory buffer pool to evaluate predicates. Time complexity: O(N).
--    - With a B-Tree index, MySQL navigates a balanced tree structure from root to leaf,
--      locating matching pointers in O(log N) operations.
--
-- 2. Storage and Write Costs:
--    - Storage Cost: Indexes consume additional tablespace (.ibd file) and buffer pool memory.
--    - Write Amplification: Every INSERT, UPDATE, or DELETE on indexed columns requires the
--      engine to rebalance and update the corresponding B-Tree nodes, increasing I/O latency.
--
-- 3. Composite Index Leftmost Prefix Rule:
--    - An index on (student_id, status) can accelerate queries on:
--      (a) student_id alone
--      (b) student_id AND status together
--      However, it CANNOT be used effectively for queries filtering on `status` alone.
--      Hence, a separate single-column index on `status` is maintained.
-- -----------------------------------------------------------------------------

-- Query Plan 1: Status filtering using index `idx_complaints_status`
-- Expectation: `type: ref`, `key: idx_complaints_status`
EXPLAIN
SELECT complaint_id, title, priority, status 
FROM complaints 
WHERE status = 'Pending';

-- Query Plan 2: Composite index lookup on `idx_complaints_student_status`
-- Expectation: `type: ref`, `key: idx_complaints_student_status`
EXPLAIN
SELECT complaint_id, title, created_at 
FROM complaints 
WHERE student_id = 5 
  AND status = 'Resolved';

-- Query Plan 3: Multi-table JOIN with Foreign Key indexes
-- Expectation: Primary key and foreign key index lookups (`type: eq_ref` on joined tables)
EXPLAIN
SELECT 
    c.complaint_id,
    c.title,
    s.full_name,
    l.room_number,
    d.department_name
FROM complaints c
JOIN students s ON c.student_id = s.student_id
JOIN locations l ON c.location_id = l.location_id
JOIN departments d ON s.department_id = d.department_id
WHERE c.status = 'In Progress';
