# CAMPUSFIX: Comprehensive DBMS Concepts & University Viva Guide

This technical guide explains core Relational Database Management System (DBMS) concepts using concrete architecture, schema models, and operational examples from **CAMPUSFIX**. It is structured for academic coursework submission and university oral examinations (viva voce).

---

## 1. DBMS vs. Traditional File Processing System

In a naive manual or file-based approach, campus complaints would be stored in CSV files, text logs, or spreadsheet sheets (e.g. `complaints.csv`, `students.csv`).

| Parameter | Traditional File System | CAMPUSFIX Relational DBMS |
| :--- | :--- | :--- |
| **Data Redundancy** | Student names, phone numbers, and room details are duplicated in every complaint line. | Normalized into distinct tables (`students`, `locations`). A student's details exist in exactly one row. |
| **Data Inconsistency** | Updating a student's phone number in one file leaves outdated numbers in historical complaint records. | Updating `students.phone` in one row is immediately reflected everywhere across foreign key joins. |
| **Data Isolation** | Data is scattered across disparate files; complex custom code is needed to correlate complaints with technicians. | Relational queries (`JOIN`) effortlessly correlate students, complaints, staff, and departments in a single query. |
| **Atomicity** | If the system crashes after assigning a staff member but before writing the status update, the file is corrupted. | Transactions (`START TRANSACTION ... COMMIT / ROLLBACK`) ensure all steps succeed or none take effect. |
| **Concurrent Access** | File locking prevents multiple dispatchers and technicians from updating records simultaneously. | Multi-Version Concurrency Control (MVCC) and row-level locking allow hundreds of concurrent users without conflicts. |
| **Integrity Enforcement** | Application code must manually validate ratings, emails, and foreign keys; bad scripts can write corrupt values. | Enforced at the engine level via `CHECK (rating BETWEEN 1 AND 5)`, `UNIQUE(email)`, and foreign key constraints. |

---

## 2. The Relational Model

The relational model organizes data into two-dimensional tables called **relations**.
- **Relation (Table):** An unordered set of tuples sharing identical attributes (e.g. `complaints`).
- **Tuple (Row / Record):** A single entity instance (e.g. Complaint #1 representing a broken projector in LH-101).
- **Attribute (Column / Field):** A named characteristic of the relation (e.g. `priority`, `status`, `created_at`).
- **Domain:** The permitted pool of values for an attribute (e.g. domain of `rating` is integers from 1 to 5).
- **Degree:** The number of attributes in a relation (e.g. `departments` has degree 3; `complaints` has degree 10).
- **Cardinality:** The number of tuples currently stored in a relation (e.g. `students` has cardinality 20; `complaints` has cardinality 35).

---

## 3. Entities and Attributes

- **Entity:** A real-world object or concept distinguishable from other objects.
  - *Strong Entity:* Can exist independently of other entities (e.g. `departments`, `locations`, `students`).
  - *Weak Entity / Associative Entity:* Depends on the existence of another entity for its identification or relational context (e.g. `complaint_assignments`, `feedback`).
- **Attribute Types:**
  - *Simple / Atomic:* Indivisible values (e.g. `rating = 5`, `room_number = 'LH-101'`).
  - *Single-Valued:* Holds one value per tuple (e.g. `enrollment_date`).
  - *Stored vs. Derived:* `created_at` and `updated_at` are stored; the complaint's *age in hours* (`TIMESTAMPDIFF(HOUR, created_at, NOW())`) is dynamically derived in `v_pending_complaints`.

---

## 4. Keys in Relational Databases

Keys are fundamental mechanisms used to establish identity, uniqueness, and relational links.

```
Superkey (Any attribute set uniquely identifying a row)
  └── Candidate Key (Minimal Superkey)
        ├── Primary Key (Chosen Unique Identifier)
        └── Alternate / Unique Key (Secondary Unique Identifier)
```

1. **Superkey:** Any set of one or more attributes that uniquely identifies a row in a table.
   - Example in `students`: `{student_id}`, `{email}`, `{student_id, full_name}`, `{student_id, email, phone}` are all superkeys.
2. **Candidate Key:** A **minimal** superkey—no proper subset is a superkey.
   - Example in `students`: `{student_id}` and `{email}` are both candidate keys.
3. **Primary Key (PK):** The chosen candidate key used by the RDBMS engine as the definitive row identifier.
   - Example: `student_id` is the primary key for `students`; `complaint_id` is the primary key for `complaints`.
4. **Alternate / Unique Key (UK):** Candidate keys not chosen as the primary key.
   - Example: `email` in `students` and `staff`; `department_name` in `departments`.
5. **Foreign Key (FK):** An attribute in a child relation that references a candidate/primary key in a parent relation.
   - Example: `complaints.student_id` references `students.student_id`.

---

## 5. Referential Integrity & Referential Actions

**Referential Integrity Rule:** A foreign key value must either match an existing primary key value in the referenced parent table or be `NULL`.

CAMPUSFIX implements targeted referential actions:
- **`ON DELETE RESTRICT` (Master Tables):**
  - Applied to `students.department_id`, `complaints.student_id`, and `complaints.location_id`.
  - *Rationale:* Prevents accidental deletion of a department if students belong to it, or deleting a student who has active incident history.
- **`ON DELETE CASCADE` (Transactional Logs):**
  - Applied to `complaint_assignments.complaint_id`, `complaint_status_history.complaint_id`, and `feedback.complaint_id`.
  - *Rationale:* If an invalid or test complaint ticket is purged, its dependent assignment logs, audit transitions, and feedback reviews are safely removed automatically.
- **`ON UPDATE CASCADE` (All FKs):**
  - If a primary key value changes, the engine automatically propagates the update down to all referencing child tuples.

---

## 6. Functional Dependencies & Normalization

A functional dependency $\alpha \to \beta$ states that the value of attribute set $\alpha$ uniquely determines the value of attribute set $\beta$.

### 1NF (First Normal Form)
- **Requirement:** All attribute values are atomic; no repeating groups; explicit primary key defined.
- **CAMPUSFIX Implementation:** Phone numbers and emails are stored in distinct scalar columns (never comma-separated lists); technician assignments are stored in distinct rows in `complaint_assignments` rather than repeating columns (`technician_1`, `technician_2`) inside `complaints`.

### 2NF (Second Normal Form)
- **Requirement:** In 1NF, and **no non-prime attribute is partially dependent** on any candidate key ($\alpha \subset \text{PK} \to \text{non-prime}$).
- **CAMPUSFIX Implementation:** All 8 tables utilize **single-column surrogate primary keys** (`student_id`, `complaint_id`, etc.). Because no candidate key is composite, partial key dependencies are mathematically impossible. The schema strictly satisfies 2NF.

### 3NF (Third Normal Form)
- **Requirement:** In 2NF, and **no non-prime attribute is transitively dependent** on the primary key ($X \to Y \to Z$ where $Z$ is non-prime).
- **CAMPUSFIX Implementation:**
  - In `complaints`, we store `location_id`. We intentionally do *not* store `building_name` or `room_number`. Storing `building_name` would create `complaint_id -> location_id -> building_name` (transitive dependency).
  - In `students`, we store `department_id`. We do *not* store `department_name` in `students`. Doing so would create `student_id -> department_id -> department_name`.
  - All non-prime attributes depend **only on the key, the whole key, and nothing but the key**.

### BCNF (Boyce-Codd Normal Form)
- **Requirement:** For every non-trivial functional dependency $X \to Y$, the determinant $X$ must be a **superkey**.
- **CAMPUSFIX Proof:**
  - Across all 8 tables, every functional determinant is either the table's primary key (`complaint_id`, `student_id`) or an alternate candidate key (`email`, `department_name`, `feedback.complaint_id`).
  - Because no non-superkey determines any attribute, the schema strictly satisfies **BCNF**.

### Anomalies Eliminated
- **Insertion Anomaly:** A new department (e.g., 'Biomedical Engineering') can be inserted into `departments` immediately without requiring any enrolled students.
- **Update Anomaly:** Renaming a building in `locations` takes effect in a single row; every query joining `complaints` immediately reflects the new name.
- **Deletion Anomaly:** Deleting a resolved complaint record cascades to assignments and feedback without deleting the student profile or maintenance technician.

---

## 7. SQL Sublanguages

SQL is partitioned into specialized sublanguages demonstrated across CAMPUSFIX scripts:

1. **DDL (Data Definition Language):** Defines schema structures and constraints.
   - `CREATE DATABASE campusfix;`
   - `CREATE TABLE complaints (...);`
   - `CREATE INDEX idx_complaints_status ON complaints(status);`
2. **DML (Data Manipulation Language):** Populates, modifies, and removes table records.
   - `INSERT INTO complaints (...) VALUES (...);`
   - `UPDATE complaints SET status = 'Assigned' WHERE complaint_id = 31;`
   - `DELETE FROM locations WHERE location_id = 999;`
3. **DQL (Data Query Language):** Queries and extracts information.
   - `SELECT c.title, s.full_name FROM complaints c JOIN students s ...;`
4. **TCL (Transaction Control Language):** Manages atomic transactions.
   - `START TRANSACTION;`
   - `COMMIT;`
   - `ROLLBACK;`
5. **DCL (Data Control Language):** Controls database permissions and security.
   - `GRANT SELECT, INSERT ON campusfix.* TO 'student_user'@'%';`

---

## 8. Relational Joins

Joins combine attributes from two or more relations based on matching conditions:

| Join Type | Behavior in CAMPUSFIX | Example Scenario |
| :--- | :--- | :--- |
| **INNER JOIN** | Returns rows where the join condition evaluates to TRUE in both tables. | Matching students with their academic department (`students s JOIN departments d`). |
| **LEFT JOIN** | Returns all rows from the left table; matching rows from the right table, or `NULL` if no match exists. | All complaints with assigned technicians (`complaints c LEFT JOIN complaint_assignments ca`). Unassigned tickets show `NULL` technician. |
| **RIGHT JOIN** | Returns all rows from the right table, and matching rows from the left table. | All locations and their incident counts (`complaints c RIGHT JOIN locations l`). Shows rooms with 0 complaints. |
| **CROSS JOIN** | Cartesian product ($M \times N$). Every row of table A paired with every row of table B. | Pairing 5 departments with 12 locations to generate a 60-row campus facility inspection matrix. |
| **SELF JOIN** | Joins a table to itself using table aliases. | Detecting incident hotspots: matching complaints that share the same `location_id` (`c1.location_id = c2.location_id AND c1.complaint_id < c2.complaint_id`). |

---

## 9. Subqueries

A subquery is a nested query enclosed in parentheses inside another SQL statement:
- **Scalar Subquery:** Returns a single value (one row, one column).
  - *Example:* Find complaints submitted after the average creation date: `WHERE created_at > (SELECT AVG(created_at) FROM complaints)`.
- **Multiple-Row Subquery:** Returns a column of values used with `IN`, `NOT IN`, `ANY`, or `ALL`.
  - *Example:* Find students who reported Critical tickets: `WHERE student_id IN (SELECT student_id FROM complaints WHERE priority = 'Critical')`.
- **Correlated Subquery:** An inner query that references columns from the outer query, evaluated once per candidate row.
  - *Example:* Find staff members assigned more complaints than the institutional average: `WHERE (SELECT COUNT(*) FROM assignments WHERE staff_id = st.staff_id) > (SELECT AVG(...) FROM ...)`.
- **Semi-Join (`EXISTS` / `NOT EXISTS`):** Returns outer rows based on the presence or absence of matching rows in the subquery, short-circuiting on the first match.

---

## 10. Database Views

A **view** is a virtual table defined by a stored SQL query. It does not store physical data; rows are computed dynamically upon execution.

- **Purpose & Benefits:**
  1. *Security & Access Control:* Hides sensitive student contact credentials while exposing incident details to maintenance dispatchers.
  2. *Simplicity:* Encapsulates complex 4-table joins (`v_complaint_details`) behind a single `SELECT * FROM v_complaint_details`.
  3. *Consistency:* Prevents join double-counting in workload metrics across multiple applications (`v_staff_workload`).

---

## 11. Database Triggers

A **trigger** is a specialized procedural block executed automatically by the RDBMS engine in response to specific DML events (`INSERT`, `UPDATE`, `DELETE`).

- **ECA Model:** **Event** (BEFORE/AFTER UPDATE), **Condition** (status changed), **Action** (write audit row).
- **CAMPUSFIX Triggers:**
  - `trg_complaints_before_update`: Enforces automated timestamping (`NEW.updated_at = NOW()`).
  - `trg_complaints_status_audit`: Automatically inserts historical transitions into `complaint_status_history`.
  - `trg_feedback_before_insert`: Validates student ownership and asserts that the ticket is in `'Resolved'` status before feedback is accepted.
- **Trigger Recursion Prevention:** Triggers that validate data using `SIGNAL SQLSTATE '45000'` never mutate the base table, eliminating infinite loop risks.

---

## 12. Stored Procedures

A **stored procedure** is a precompiled collection of SQL statements and control logic stored in the database catalog.

- **Advantages over Client-Side Code:**
  - *Performance:* Precompiled execution plans; reduces network roundtrips.
  - *Security:* Grants users `EXECUTE` privileges on `sp_assign_complaint` without granting direct `UPDATE` access to the `complaints` table.
  - *Centralized Business Logic:* Ticket assignment, lifecycle transition validation, and KPI generation are maintained in the database layer.

---

## 13. Transactions and ACID Properties

A **transaction** is a logical unit of work comprising one or more SQL operations that must be executed as an inseparable whole.

```
                  ┌──────────────────────┐
                  │  START TRANSACTION   │
                  └──────────┬───────────┘
                             ▼
                  ┌──────────────────────┐
                  │  Insert Assignment   │
                  └──────────┬───────────┘
                             ▼
                  ┌──────────────────────┐
                  │    Update Status     │
                  └──────────┬───────────┘
                       /           \
           (Success)  /             \  (Exception / Failure)
                     ▼               ▼
              ┌────────────┐   ┌────────────┐
              │   COMMIT   │   │  ROLLBACK  │
              └────────────┘   └────────────┘
```

1. **Atomicity (All or Nothing):** In `sp_tx_assign_technician`, both the assignment insertion and status update commit together. If an error occurs, `ROLLBACK` undoes all partial updates.
2. **Consistency (Preserving Invariants):** Transactions transition the database from one valid state to another, strictly satisfying foreign key, check, and unique constraints.
3. **Isolation (Concurrency Control):** Concurrent transactions cannot view uncommitted changes made by other transactions (preventing dirty reads, non-repeatable reads, and phantom reads under InnoDB).
4. **Durability (Persistence):** Once committed, updates are recorded in the write-ahead transaction log (WAL / `ib_logfile`) and survive system crashes or power failures.

---

## 14. Indexing & Query Execution Plans

An **index** is an auxiliary B-Tree data structure that speeds up tuple retrieval at the expense of storage and write performance.

- **B-Tree Navigation:** Searches balance logarithmic time $O(\log N)$ instead of a full table scan $O(N)$.
- **Clustered Index:** In InnoDB, the primary key forms the clustered index where table leaf pages contain actual row data.
- **Secondary Index:** Maps indexed columns to primary key pointers (e.g. `idx_complaints_status` maps status values to `complaint_id`).
- **Composite Index Leftmost Prefix Rule:** `idx_complaints_student_status (student_id, status)` optimizes queries filtering on `student_id` alone or `(student_id, status)` together, but does *not* cover queries filtering on `status` alone.
- **Cost of Indexing:**
  - *Storage Overhead:* Index trees consume memory in the InnoDB buffer pool.
  - *Write Amplification:* Every `INSERT`, `UPDATE`, or `DELETE` on indexed columns requires rebalancing B-Tree leaf pages.
