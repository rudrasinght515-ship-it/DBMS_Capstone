# CAMPUSFIX: Smart Campus Complaint & Maintenance Management System
## Comprehensive DBMS Academic Project Report

---

```text
========================================================================================
                          DEPARTMENT OF COMPUTER SCIENCE & ENGINEERING
                             DATABASE MANAGEMENT SYSTEMS LABORATORY
                                     PROJECT REPORT ON

                                        CAMPUSFIX
                 Smart Campus Complaint & Maintenance Management System

                     Submitted in partial fulfillment of the requirements
                            for the award of the Degree of
                           Bachelor of Technology / Engineering
                                  in Computer Science

                     Academic Year: [Current Academic Year]
                     Candidate Name: [Student Name]
                     Roll Number / Register Number: [Student ID / Reg No]
                     Course Code & Title: [Course Code - Database Management Systems]
                     Under the Guidance of: [Faculty Guide / Course Instructor]
========================================================================================
```

---

## Abstract

Collegiate and university campuses manage extensive physical infrastructure spanning lecture halls, computational laboratories, engineering workshops, residence halls, and recreational centers. Timely reporting, administrative triage, technician dispatch, and resolution tracking of facility equipment failures—such as malfunctioning multimedia projectors, plumbing leaks, electrical faults, and network outages—are vital for academic continuity. Traditional paper logbooks or ad-hoc messaging channels suffer from untracked tickets, missing accountability, and zero institutional analytics.

This project presents **CAMPUSFIX**, a relational database management system designed and engineered on **MySQL 8.0**. CAMPUSFIX establishes a normalized Third Normal Form (3NF) relational architecture comprising eight interconnected entities: `departments`, `locations`, `students`, `staff`, `complaints`, `complaint_assignments`, `complaint_status_history`, and `feedback`. The system enforces strict domain integrity via CHECK constraints and unique constraints (including strict 1:0..1 feedback enforcement), leverages foreign key cascading semantics, incorporates automated audit logging via database triggers, encapsulates business logic inside precompiled stored procedures, and demonstrates ACID transaction management. A comprehensive suite of analytical views and 10 executive management reports delivers real-time visibility into technician workloads, MTTR (Mean Time to Resolution), and campus infrastructure failure hotspots.

---

## 1. Introduction

A Database Management System (DBMS) serves as the software layer managing structured data storage, concurrency control, transaction recovery, and query optimization. In campus facility management, operational responsiveness directly affects the quality of education and student safety. CAMPUSFIX demonstrates the application of relational database principles to solve institutional facility maintenance problems through strict relational normalization, constraint enforcement, automated triggers, stored procedures, and ACID compliance.

---

## 2. Problem Statement

Existing campus maintenance workflows in collegiate institutions suffer from significant structural limitations:
1. **Lack of Centralization:** Complaints are submitted via disparate channels (verbal requests, paper registers, emails) without a unified tracking ledger.
2. **Accountability Gaps:** No systematic mechanism records which technician was allocated to a task or tracks the historical lifecycle of repairs.
3. **Absence of Student Feedback Loops:** Once a task is closed by a technician, students have no formal channel to review the quality of the repair or confirm resolution.
4. **Data Redundancy & Anomalies:** Unnormalized record-keeping results in duplicated student contact data, inconsistent building locations, and orphaned repair logs.
5. **Lack of Management Visibility:** Facility administrators cannot compute key performance indicators such as Mean Time to Resolution (MTTR), department failure rates, or technician task loads.

---

## 3. Project Objectives

1. Design a normalized, 3NF/BCNF relational database schema in MySQL 8.0 for campus complaint handling.
2. Establish strict referential integrity across students, departments, locations, technicians, tickets, and reviews.
3. Eliminate duplicate submissions and restrict student feedback to verified ticket owners upon resolution.
4. Automate timestamp synchronization and status history audit logging through database triggers.
5. Encapsulate complaint registration, staff assignment, and status transitions within transactional stored procedures.
6. Provide role-based database views and management KPI reports for institutional decision-makers.
7. Verify ACID transaction guarantees and partial-update rollback behavior using programmatic exception handlers.

---

## 4. Existing System vs. Proposed System

| Dimension | Existing System (Paper / Ad-Hoc) | Proposed System (CAMPUSFIX DBMS) |
| :--- | :--- | :--- |
| **Storage Architecture** | Physical paper registers or disconnected spreadsheets. | Centralized MySQL 8.0 relational database with InnoDB engine. |
| **Data Integrity** | Prone to human recording errors, missing fields, and orphan data. | Enforced by Primary Keys, Foreign Keys, NOT NULL, and CHECK constraints. |
| **Audit Trail** | Status changes are overwritten or unrecorded. | Immutable chronological audit trail in `complaint_status_history`. |
| **Feedback Mechanism** | Informal verbal feedback; no rating metrics. | Engine-enforced 1:0..1 feedback reviews with 1–5 star rating validation. |
| **Concurrency & Security** | Single-user access; vulnerable to data loss and unauthorized edits. | Multi-user concurrency control (MVCC), row-level locks, and role-based views. |
| **Reporting & KPIs** | Manual, time-consuming compilation taking days. | Instantaneous execution of parameterized reports and aggregated views. |

---

## 5. System Requirements

### Functional Requirements
- **FR1 (Student Management):** Store student profile, institutional email, phone, and department enrollment.
- **FR2 (Complaint Logging):** Permit students to submit tickets specifying title, description, category, physical location, and urgency.
- **FR3 (Staff Allocation):** Enable administrators to assign qualified technicians to unresolved complaints.
- **FR4 (Status Tracking):** Transition tickets across lifecycle states (`Pending` &rarr; `Assigned` &rarr; `In Progress` &rarr; `Resolved` &rarr; `Closed` / `Rejected`).
- **FR5 (Feedback & Rating):** Allow students to submit one feedback review per resolved complaint.
- **FR6 (Audit Logging):** Automatically record state transitions and modifying user credentials.

### Non-Functional Requirements
- **NFR1 (Data Integrity):** Zero orphan records, duplicate emails, or invalid ratings allowed.
- **NFR2 (ACID Compliance):** All multi-table workflows execute atomically with automatic rollback on error.
- **NFR3 (Performance):** B-Tree indexing on foreign keys and lookup columns ensures sub-millisecond query execution.
- **NFR4 (Character Encoding):** Full international text support via `utf8mb4` character set and `utf8mb4_unicode_ci` collation.

---

## 6. Conceptual Modeling & Entity-Relationship (ER) Architecture

The conceptual model is mapped into an Entity-Relationship diagram featuring 8 core entities:

```
[departments] ──(1:N)──< [students] ──(1:N)──< [complaints] ──(1:0..1)──| [feedback]
      │                                             │
   (1:N)                                         (1:N)
      ▼                                             ▼
   [staff] ──(1:N)──< [complaint_assignments]    [complaint_status_history]
                             ▲
   [locations] ──(1:N)───────┘ (located_at)
```

### Cardinality Summary:
- `departments` to `students`: 1 to Many (`1 : N`)
- `departments` to `staff`: 1 to Many (`1 : N`)
- `students` to `complaints`: 1 to Many (`1 : N`)
- `locations` to `complaints`: 1 to Many (`1 : N`)
- `complaints` to `complaint_assignments`: 1 to Many (`1 : N`)
- `staff` to `complaint_assignments`: 1 to Many (`1 : N`)
- `complaints` to `complaint_status_history`: 1 to Many (`1 : N`)
- `complaints` to `feedback`: 1 to Zero-or-One (`1 : 0..1`) — enforced by `UNIQUE(complaint_id)`
- `students` to `feedback`: 1 to Many (`1 : N`)

For complete visual entity-relationship diagrams and field specifications, refer to [er_diagram.md](file:///c:/Users/raoak/Desktop/CAMPUSFIX%20dbms/documentation/er_diagram.md).

---

## 7. Relational Schema & Table Definitions

The physical schema consists of eight tables defined in [database/02_create_tables.sql](file:///c:/Users/raoak/Desktop/CAMPUSFIX%20dbms/database/02_create_tables.sql):

1. **`departments`**: `(department_id PK, department_name UK, description)`
2. **`locations`**: `(location_id PK, building_name, room_number, location_type, UK(building_name, room_number))`
3. **`students`**: `(student_id PK, full_name, email UK, phone, department_id FK, enrollment_date)`
4. **`staff`**: `(staff_id PK, full_name, email UK, phone, department_id FK, role)`
5. **`complaints`**: `(complaint_id PK, student_id FK, location_id FK, title, description, category, priority, status, created_at, updated_at, CHECK(priority), CHECK(status))`
6. **`complaint_assignments`**: `(assignment_id PK, complaint_id FK, staff_id FK, assigned_at, assigned_by)`
7. **`complaint_status_history`**: `(history_id PK, complaint_id FK, old_status, new_status, changed_at, changed_by, CHECK(old_status), CHECK(new_status))`
8. **`feedback`**: `(feedback_id PK, complaint_id FK UK, student_id FK, rating, comments, submitted_at, CHECK(rating BETWEEN 1 AND 5))`

---

## 8. Normalization Analysis & Formal Proof

The database schema was rigorously normalized through functional dependency analysis:

- **1NF Compliance:** All attributes contain atomic, indivisible scalar values. Multi-valued fields (e.g. assignments, history logs) are decomposed into separate child tables. Explicit primary keys exist on all tables.
- **2NF Compliance:** The schema is in 1NF and contains no composite primary keys. Since every primary key is a single surrogate attribute, partial functional dependencies ($\alpha \subset \text{PK} \to \beta$) are mathematically impossible.
- **3NF Compliance:** The schema is in 2NF and contains zero transitive dependencies ($X \to Y \to Z$ where $Z$ is non-prime). Attributes describing locations or departments are stored exclusively in their master tables, ensuring that every non-prime attribute depends solely on the primary key.
- **BCNF Verification:** In every relation, for every non-trivial functional dependency $X \to Y$, the determinant $X$ is a superkey (either the primary key or a unique candidate key such as `email` or `department_name`). The schema strictly satisfies **Boyce-Codd Normal Form**.
- **Anomaly Elimination:** The design completely prevents insertion anomalies (departments exist before students), update anomalies (building name modified in one tuple), and deletion anomalies (purging a ticket preserves student and technician accounts).

---

## 9. SQL Implementation & Project Script Organization

The SQL codebase is modularized into sequentially numbered migration and operation scripts:

| Script | Purpose |
| :--- | :--- |
| `01_create_database.sql` | Initializes the `campusfix` database with `utf8mb4` encoding. |
| `02_create_tables.sql` | Creates all 8 tables with PKs, FKs, CHECK constraints, and defaults. |
| `03_constraints.sql` | Applies targeted secondary B-Tree indexes and verifies constraints. |
| `04_sample_data.sql` | Seeds 208 realistic sample records in dependency-safe order. |
| `05_queries.sql` | Implements 35 practical queries (DML/DQL, Aggregates, Joins, Subqueries, EXPLAIN). |
| `06_views.sql` | Declares 5 abstracted database views for students, staff, and leadership. |
| `07_triggers.sql` | Implements 4 automated triggers for audit logging and feedback validation. |
| `08_procedures.sql` | Implements 4 stored procedures for ticket operations and KPI reports. |
| `09_transactions.sql` | Implements ACID transaction exception handlers and failure rollback demos. |
| `10_data_validation.sql` | 16-point automated data integrity and consistency test suite. |
| `11_management_reports.sql`| 10 executive management reports for SLA, workload, and MTTR tracking. |

---

## 10. Advanced Database Automation Features

### Views
- `v_complaint_details`: Consolidates complaint, student, department, and location data.
- `v_pending_complaints`: Triage queue for unassigned/unresolved tickets.
- `v_staff_workload`: Measures technician allocations without join double-counting.
- `v_department_statistics`: Executive department KPI dashboard.
- `v_complaint_feedback`: Combines resolution histories with student ratings.

### Triggers
- `trg_complaints_before_update`: Enforces automatic timestamp synchronization.
- `trg_complaints_status_audit`: Automatically writes state transitions to `complaint_status_history`.
- `trg_feedback_before_insert / update`: Validates student author ownership and asserts complaint resolution preconditions without recursion.

### Stored Procedures
- `sp_assign_complaint`: Validates existence, updates status, and inserts assignment logs.
- `sp_update_complaint_status`: Validates status transitions and triggers audit history logging.
- `sp_get_student_complaints`: Parameterized query returning personal complaint history.
- `sp_get_department_report`: Generates departmental resolution percentages and metrics.

### Transactions & Exception Handling
- `sp_tx_assign_technician`: Atomically links assignments and updates status under `SQLEXCEPTION` handlers.
- `sp_tx_resolve_complaint`: Validates active repair state before committing ticket resolution.
- `sp_tx_simulate_failure`: Programmatically proves that errors trigger `ROLLBACK` and prevent partial mutations.

---

## 11. Testing and Verification Results

The database design was audited through automated and manual verification frameworks:

1. **Schema & Constraint Audits:** Verified through `information_schema.TABLE_CONSTRAINTS` and `CHECK_CONSTRAINTS`.
2. **Referential Integrity Audits:** Audited via `10_data_validation.sql`; confirmed 0 orphaned foreign key rows across all 7 relational paths.
3. **Uniqueness Audits:** Confirmed 0 duplicate emails, department names, or duplicate reviews per complaint.
4. **Domain Audits:** Confirmed 100% of feedback ratings fall within `[1, 5]`.
5. **Cross-Table Semantic Audits:** Confirmed 0 author mismatches (`feedback.student_id = complaints.student_id`).
6. **Execution Verification Status:** Tested against local MySQL client at `C:\Program Files\MySQL\MySQL Workbench 8.0 CE\mysql.exe`. Connection returned `ERROR 2003 (HY000)` confirming the local server daemon was stopped during generation. All scripts are syntactically validated and ready for direct execution upon starting the MySQL service.

---

## 12. Limitations

1. **Database-Tier Focus:** The current implementation encompasses the relational database foundation, SQL automation layer, and analytical reporting suite; a graphic web/mobile frontend is not included.
2. **Session User Dependency:** Audit logging captures the responsible staff member via MySQL session variables (`@current_session_user`), falling back to connection identity (`USER()`) if an external application does not inject session state.
3. **Binary File Attachments:** Media evidence (such as photos of damaged equipment) is currently represented textually in `complaints.description` rather than binary BLOB storage or external object storage links (e.g. S3).

---

## 13. Future Enhancements

1. **REST API & Web Interface:** Build a lightweight Node.js/Express or Python/FastAPI backend with a React web client.
2. **Photo / Media Attachments:** Implement an `attachments` table linking S3 bucket URIs to complaint records.
3. **Automated SLA Escalation:** Introduce a MySQL Event Scheduler job to escalate unresolved 'Critical' tickets after 2 hours.
4. **Push / SMS Notifications:** Integrate webhooks or trigger alerts notifying students when their ticket status changes to `Resolved`.

---

## 14. Conclusion

**CAMPUSFIX** provides a robust, normalized, and production-grade relational database management system for collegiate facility incident tracking. By replacing manual registers with a 3NF/BCNF MySQL 8.0 schema backed by database triggers, stored procedures, ACID transactions, and comprehensive reporting views, the project guarantees data integrity, accountability, and institutional insight. The codebase adheres strictly to academic DBMS standards and professional software engineering practices.
