# CAMPUSFIX: Smart Campus Complaint & Maintenance Management System
## Database Architecture & Project Overview

---

### 1. Executive Summary

**CAMPUSFIX** is a database-driven maintenance and incident management system designed for academic and collegiate institutions. In large campus environments, physical infrastructure failures—such as malfunctioning classroom projectors, air conditioning breakdowns, laboratory equipment faults, electrical hazards, and plumbing leaks—frequently suffer from delayed turnaround times, lack of accountability, and opaque resolution tracking.

CAMPUSFIX establishes a centralized, relational database management system (RDBMS) foundation using **MySQL 8.0**. It supports role-based interaction patterns for **Students**, **Maintenance Staff / Technicians**, and **Campus Administrators**, ensuring strict data integrity, automated status auditing, and operational reporting.

---

### 2. Core Entities & Conceptual Model

The relational model is designed to Third Normal Form (3NF) standards to eliminate redundancy while preserving referential integrity:

```
[Departments] ──< [Staff] ──< [Complaint Assignments] >── [Complaints] >── [Feedback]
      │                                                           │
      └──< [Students] ─────────────────────────────────────────────┘
                                      │
[Locations] ──────────────────────────┘
                                      │
                         [Complaint Status History]
```

1. **Departments (`departments`)**:
   - Represents administrative and operational divisions (e.g., Electrical Maintenance, Information Technology / AV, Civil & Plumbing, Hostel Affairs).
2. **Locations (`locations`)**:
   - Physical campus landmarks, building blocks, floors, room numbers, and facility identifiers (e.g., "Block B - Room 304", "Computer Science Lab 2").
3. **Students (`students`)**:
   - Campus student population with unique registration numbers, departmental affiliations, and contact details.
4. **Staff (`staff`)**:
   - Maintenance personnel and technicians with departmental assignment, job title, and active availability flags.
5. **Complaints (`complaints`)**:
   - Central incident records capturing the student reporter, affected location, category, severity/priority level, description, and current lifecycle status.
6. **Complaint Assignments (`complaint_assignments`)**:
   - Many-to-many relationship tracking which technician(s) are assigned to an incident, assignment timestamps, and assignment-specific notes.
7. **Complaint Status History (`complaint_status_history`)**:
   - Append-only audit ledger recording every lifecycle transition (`SUBMITTED`, `ASSIGNED`, `IN_PROGRESS`, `RESOLVED`, `CLOSED`, `REJECTED`), the modifying entity, and timestamps.
8. **Feedback (`feedback`)**:
   - Post-resolution student evaluations featuring quantitative satisfaction scores (1–5 scale) and qualitative feedback comments.

For the visual schema with data types, keys, and cardinalities, refer to [er_diagram.md](file:///c:/Users/raoak/Desktop/CAMPUSFIX%20dbms/documentation/er_diagram.md).

---

### 3. Normalization Analysis & Formal Justification

The schema was constructed strictly through functional dependency analysis to eliminate data redundancy and prevent anomalous behavior.

#### A. First Normal Form (1NF) Compliance
A relation is in **1NF** if and only if all attribute values are atomic (indivisible) and there are no repeating groups.
- **Atomicity:** All attributes store single scalar values. For instance, `students.full_name` is stored as an atomic entity, phone numbers are individual strings rather than comma-separated lists, and individual assignment records are stored in dedicated rows rather than array fields.
- **Unique Row Identification:** Every relation contains an explicit, unique primary key (`department_id`, `student_id`, `staff_id`, `location_id`, `complaint_id`, `assignment_id`, `history_id`, `feedback_id`).
- **No Repeating Groups:** Instead of creating columns like `assigned_staff_1`, `assigned_staff_2` in the `complaints` table, assignments are decomposed into the dedicated `complaint_assignments` entity.

#### B. Second Normal Form (2NF) Compliance
A relation is in **2NF** if and only if it is in 1NF and no non-prime attribute is partially dependent on any candidate key.
- Partial dependency can only exist when a candidate key is composite.
- In our schema, all 8 tables utilize **single-column surrogate primary keys** (e.g., `assignment_id` for assignments rather than composite `(complaint_id, staff_id)`, which allows a technician to be assigned multiple times across different stages).
- Since every candidate key consists of a single attribute, **partial key dependencies are mathematically impossible**. Every non-prime attribute is fully functionally dependent on the whole key.

#### C. Third Normal Form (3NF) Compliance
A relation is in **3NF** if and only if it is in 2NF and no non-prime attribute is transitively dependent on the primary key ($X \to Y$ and $Y \to Z$ where $Z$ is non-prime).
- **Elimination of Transitive Dependencies:**
  - In `complaints`, we store `student_id` and `location_id`. We intentionally do *not* store student email, student name, building name, or room number in `complaints`. Storing building name in `complaints` would create a transitive dependency: `complaint_id -> location_id -> building_name`.
  - In `students` and `staff`, we store `department_id`. We do *not* store `department_name` or `department_description`. Doing so would introduce `student_id -> department_id -> department_name`.
  - In `feedback`, we store `complaint_id` and `student_id`. We do *not* store complaint title, status, or staff details.
- Every non-prime attribute depends **solely on the key, the whole key, and nothing but the key**.

#### D. Boyce-Codd Normal Form (BCNF) Assessment
A relation is in **BCNF** (a stricter form of 3NF) if for every non-trivial functional dependency $X \to Y$, the determinant $X$ is a **superkey**.
- **Proof / Verification:**
  - In `departments`: Candidate keys are `department_id` and `department_name`. The dependencies are `department_id -> {department_name, description}` and `department_name -> {department_id, description}`. Both determinants are superkeys.
  - In `students`: Candidate keys are `student_id` and `email`. Both are superkeys.
  - In `staff`: Candidate keys are `staff_id` and `email`. Both are superkeys.
  - In `locations`: Candidate key is `location_id` (superkey).
  - In `complaints`: Candidate key is `complaint_id` (superkey).
  - In `complaint_assignments`: Candidate key is `assignment_id` (superkey).
  - In `complaint_status_history`: Candidate key is `history_id` (superkey).
  - In `feedback`: Candidate keys are `feedback_id` and `complaint_id` (due to `UNIQUE(complaint_id)`). Both determinants are superkeys.
- **Conclusion:** Because every determinant across all functional dependencies in every table is a superkey, **the schema strictly satisfies Boyce-Codd Normal Form (BCNF)**.

#### E. Reduction of Anomalies
| Anomaly Type | Unnormalized Risk | CAMPUSFIX Schema Solution |
| :--- | :--- | :--- |
| **Insertion Anomaly** | Cannot create a department without first enrolling a student or hiring a staff member. | `departments` is independent; departments exist autonomously before students or staff are assigned. |
| **Update Anomaly** | Changing a building's name or department title requires updating thousands of complaint rows. | Department and location names are updated in exactly one row in their parent tables; changes propagate seamlessly through foreign keys. |
| **Deletion Anomaly** | Deleting a resolved complaint record inadvertently deletes the student profile or technician account. | Deletion is controlled: deleting a complaint cascades only to its dependent transactional children (`assignments`, `history`, `feedback`), leaving student and technician master records intact (`ON DELETE RESTRICT`). |

---

### 4. Incident Lifecycle State Machine

```
              ┌─────────────┐
              │  SUBMITTED  │
              └──────┬──────┘
                     │ (Admin Review / Assignment)
                     ▼
              ┌─────────────┐
        ┌────>│  ASSIGNED   │
        │     └──────┬──────┘
        │            │ (Technician Starts Work)
(Reassign)           ▼
        │     ┌─────────────┐
        └─────┤ IN_PROGRESS ├──────┐
              └──────┬──────┘      │ (Declined / Duplicate)
                     │             ▼
                     │      ┌──────────────┐
                     │      │   REJECTED   │
                     │      └──────────────┘
                     ▼
              ┌─────────────┐
              │  RESOLVED   │
              └──────┬──────┘
                     │ (Student Feedback & Closure)
                     ▼
              ┌─────────────┐
              │   CLOSED    │
              └─────────────┘
```

- **SUBMITTED**: Incident logged by a student; awaiting administrative triage.
- **ASSIGNED**: Delegated to a maintenance technician from the appropriate department.
- **IN_PROGRESS**: Technician has acknowledged the task and commenced work.
- **RESOLVED**: Maintenance work is complete; ready for student verification.
- **CLOSED**: Student has verified resolution and submitted feedback, or administrative auto-closure has occurred.
- **REJECTED**: Duplicate, invalid, or policy-violating report.

---

### 5. Database Script Organization & Execution Order

All database logic is cleanly decomposed into modular, numbered scripts executed in sequential order:

| Script | Purpose | Status |
| :--- | :--- | :---: |
| `01_create_database.sql` | Creates `campusfix` database with `utf8mb4` character set and utf8mb4_unicode_ci collation. | **Ready** |
| `02_create_tables.sql` | Declares all 8 base tables with InnoDB engine, PKs, FKs, CHECKs, and NOT NULL constraints. | **Ready** |
| `03_constraints.sql` | Adds secondary B-Tree indexes on FKs/filter columns and provides constraint audit queries. | **Ready** |
| `04_sample_data.sql` | Seeds realistic campus data (departments, locations, users, sample complaints, and assignments). | *Stage 4* |
| `05_queries.sql` | Analytical and reporting queries (turnaround analysis, complaint aggregation, staff workload). | *Stage 5* |
| `06_views.sql` | Role-based abstracted views for student portals, staff boards, and admin dashboards. | *Stage 6* |
| `07_triggers.sql` | Automated audit logging of status changes and business rule enforcement. | *Stage 7* |
| `08_procedures.sql` | Stored procedures for routine operational workflows (ticket submission, assignment, resolution). | *Stage 8* |
| `09_transactions.sql` | Demonstrates ACID transaction management, savepoints, and failure rollback routines. | *Stage 9* |

---

### 6. Setup & Execution Guide (MySQL Workbench)

1. **Launch MySQL Workbench**:
   - Open MySQL Workbench 8.0 CE from the Windows Start menu or navigate to `C:\Program Files\MySQL\MySQL Workbench 8.0 CE\MySQLWorkbench.exe`.
2. **Connect to MySQL Server**:
   - In Workbench, open your local MySQL connection (typically `localhost:3306` with user `root`).
3. **Open & Execute Scripts**:
   - Go to `File` > `Open SQL Script...` (or press `Ctrl + Shift + O`).
   - Navigate to the `database/` folder in this project.
   - Execute the scripts sequentially using `Ctrl + Shift + Enter`:
     1. `01_create_database.sql` (Creates and selects `campusfix`)
     2. `02_create_tables.sql` (Creates all 8 tables with integrity constraints)
     3. `03_constraints.sql` (Applies secondary indexes and runs constraint audits)
4. **Alternative (MySQL Command Line Client)**:
   ```cmd
   "C:\Program Files\MySQL\MySQL Workbench 8.0 CE\mysql.exe" -u root -p < database\01_create_database.sql
   "C:\Program Files\MySQL\MySQL Workbench 8.0 CE\mysql.exe" -u root -p < database\02_create_tables.sql
   "C:\Program Files\MySQL\MySQL Workbench 8.0 CE\mysql.exe" -u root -p < database\03_constraints.sql
   ```
