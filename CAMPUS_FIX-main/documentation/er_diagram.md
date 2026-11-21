# CAMPUSFIX: Entity-Relationship (ER) Diagram

This document models the conceptual, logical, and physical relational schema for **CAMPUSFIX: Smart Campus Complaint & Maintenance Management System**.

---

## 1. Visual ER Diagram (Mermaid)

```mermaid
erDiagram
    departments ||--o{ students : "enrolls (1:N)"
    departments ||--o{ staff : "employs (1:N)"
    students ||--o{ complaints : "files (1:N)"
    locations ||--o{ complaints : "located_at (1:N)"
    complaints ||--o{ complaint_assignments : "delegated_to (1:N)"
    staff ||--o{ complaint_assignments : "works_on (1:N)"
    complaints ||--o{ complaint_status_history : "tracks_audit (1:N)"
    complaints ||--o| feedback : "receives_rating (1:0..1)"
    students ||--o{ feedback : "submits_review (1:N)"

    departments {
        int department_id PK "Auto Increment"
        string department_name UK "Unique Name"
        string description "Division Details"
    }

    locations {
        int location_id PK "Auto Increment"
        string building_name "Building/Block"
        string room_number "Room/Hall/Lab"
        string location_type "Classroom/Lab/Hostel"
    }

    students {
        int student_id PK "Auto Increment"
        string full_name "Student Name"
        string email UK "Unique Institutional Email"
        string phone "Contact Number"
        int department_id FK "References departments"
        date enrollment_date "Date of Admission"
    }

    staff {
        int staff_id PK "Auto Increment"
        string full_name "Technician/Staff Name"
        string email UK "Unique Institutional Email"
        string phone "Contact Number"
        int department_id FK "References departments"
        string role "Technician/Electrician/Supervisor"
    }

    complaints {
        int complaint_id PK "Auto Increment"
        int student_id FK "References students"
        int location_id FK "References locations"
        string title "Incident Summary"
        text description "Detailed Issue Breakdown"
        string category "Electrical/Plumbing/IT/etc"
        string priority "Low/Medium/High/Critical"
        string status "Pending/Assigned/In Progress/Resolved/Rejected"
        timestamp created_at "Timestamp of Submission"
        timestamp updated_at "Timestamp of Last Change"
    }

    complaint_assignments {
        int assignment_id PK "Auto Increment"
        int complaint_id FK "References complaints"
        int staff_id FK "References staff"
        timestamp assigned_at "Delegation Timestamp"
        string assigned_by "Dispatcher/Admin User"
    }

    complaint_status_history {
        int history_id PK "Auto Increment"
        int complaint_id FK "References complaints"
        string old_status "Previous Lifecycle State"
        string new_status "Target Lifecycle State"
        timestamp changed_at "Transition Timestamp"
        string changed_by "Modifying User/Staff"
    }

    feedback {
        int feedback_id PK "Auto Increment"
        int complaint_id FK,UK "Unique 1:0..1 Complaint Reference"
        int student_id FK "References Author Student"
        tinyint rating "Score: 1 to 5 Stars"
        text comments "Student Review Notes"
        timestamp submitted_at "Review Submission Date"
    }
```

---

## 2. Cardinality & Relational Mappings

| Relationship | Cardinality | Parent Table | Child Table | Foreign Key | Enforcement & Referential Action |
| :--- | :---: | :--- | :--- | :--- | :--- |
| **Department Enrolls Students** | `1 : N` | `departments` | `students` | `department_id` | `ON UPDATE CASCADE, ON DELETE RESTRICT` |
| **Department Employs Staff** | `1 : N` | `departments` | `staff` | `department_id` | `ON UPDATE CASCADE, ON DELETE RESTRICT` |
| **Student Files Complaints** | `1 : N` | `students` | `complaints` | `student_id` | `ON UPDATE CASCADE, ON DELETE RESTRICT` |
| **Location Houses Complaints** | `1 : N` | `locations` | `complaints` | `location_id` | `ON UPDATE CASCADE, ON DELETE RESTRICT` |
| **Complaint Assignment History** | `1 : N` | `complaints` | `complaint_assignments` | `complaint_id` | `ON UPDATE CASCADE, ON DELETE CASCADE` |
| **Staff Work Allocations** | `1 : N` | `staff` | `complaint_assignments` | `staff_id` | `ON UPDATE CASCADE, ON DELETE RESTRICT` |
| **Complaint Status Transitions** | `1 : N` | `complaints` | `complaint_status_history` | `complaint_id` | `ON UPDATE CASCADE, ON DELETE CASCADE` |
| **Complaint Feedback (1:0..1)** | `1 : 0..1` | `complaints` | `feedback` | `complaint_id` | **`UNIQUE(complaint_id)`** + `ON UPDATE CASCADE, ON DELETE CASCADE` |
| **Student Submits Feedback** | `1 : N` | `students` | `feedback` | `student_id` | `ON UPDATE CASCADE, ON DELETE RESTRICT` |

---

## 3. Structural Integrity & Architectural Highlights

1. **Surrogate Primary Keys:**
   - Every entity uses an integer surrogate primary key with `AUTO_INCREMENT`. This keeps joins lightweight, stabilizes foreign key links against real-world changes (e.g. email or name modifications), and maximizes B-Tree index cache efficiency in InnoDB.
2. **Strict 1:0..1 Feedback Relationship:**
   - A complaint ticket must not receive multiple conflicting feedback reviews. This is enforced at the database engine level via `CONSTRAINT uq_feedback_complaint UNIQUE (complaint_id)` in the `feedback` table.
3. **Composite Uniqueness on Locations:**
   - Physical rooms are prevented from duplicate declaration within the same building via `CONSTRAINT uq_locations_building_room UNIQUE (building_name, room_number)`.
4. **Cascading vs. Restrictive Delete Semantics:**
   - Dependent transactional records (`complaint_assignments`, `complaint_status_history`, `feedback`) cascade-delete when a parent `complaints` row is removed (`ON DELETE CASCADE`).
   - Primary master accounts (`departments`, `locations`, `students`, `staff`) use `ON DELETE RESTRICT` to protect against accidental deletion of historical campus incident data.
