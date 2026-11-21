-- =============================================================================
-- CAMPUSFIX: Smart Campus Complaint & Maintenance Management System
-- Script: 02_create_tables.sql
-- Description: DDL script creating all 8 core relational tables with primary keys,
--              foreign keys, NOT NULL constraints, UNIQUE constraints, CHECK
--              constraints, default values, and InnoDB engine configuration.
-- Target RDBMS: MySQL 8.0+
-- Execution Order: 02
-- =============================================================================

USE campusfix;

-- Drop tables in reverse-dependency order to support clean idempotent re-execution
DROP TABLE IF EXISTS feedback;
DROP TABLE IF EXISTS complaint_status_history;
DROP TABLE IF EXISTS complaint_assignments;
DROP TABLE IF EXISTS complaints;
DROP TABLE IF EXISTS locations;
DROP TABLE IF EXISTS staff;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS departments;

-- -----------------------------------------------------------------------------
-- 1. Table: departments
-- Purpose: Academic and operational divisions across campus.
-- -----------------------------------------------------------------------------
CREATE TABLE departments (
    department_id   INT             NOT NULL AUTO_INCREMENT,
    department_name VARCHAR(100)    NOT NULL,
    description     VARCHAR(255)    NULL,
    CONSTRAINT pk_departments PRIMARY KEY (department_id),
    CONSTRAINT uq_departments_name UNIQUE (department_name)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 2. Table: locations
-- Purpose: Physical spaces, buildings, and rooms across the campus estate.
-- -----------------------------------------------------------------------------
CREATE TABLE locations (
    location_id   INT          NOT NULL AUTO_INCREMENT,
    building_name VARCHAR(100) NOT NULL,
    room_number   VARCHAR(50)  NOT NULL,
    location_type VARCHAR(50)  NOT NULL,
    CONSTRAINT pk_locations PRIMARY KEY (location_id),
    CONSTRAINT uq_locations_building_room UNIQUE (building_name, room_number)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 3. Table: students
-- Purpose: Student accounts who submit maintenance complaints.
-- -----------------------------------------------------------------------------
CREATE TABLE students (
    student_id      INT          NOT NULL AUTO_INCREMENT,
    full_name       VARCHAR(100) NOT NULL,
    email           VARCHAR(100) NOT NULL,
    phone           VARCHAR(20)  NOT NULL,
    department_id   INT          NOT NULL,
    enrollment_date DATE         NOT NULL,
    CONSTRAINT pk_students PRIMARY KEY (student_id),
    CONSTRAINT uq_students_email UNIQUE (email),
    CONSTRAINT fk_students_department FOREIGN KEY (department_id)
        REFERENCES departments (department_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 4. Table: staff
-- Purpose: Maintenance technicians and departmental supervisors.
-- -----------------------------------------------------------------------------
CREATE TABLE staff (
    staff_id      INT          NOT NULL AUTO_INCREMENT,
    full_name     VARCHAR(100) NOT NULL,
    email         VARCHAR(100) NOT NULL,
    phone         VARCHAR(20)  NOT NULL,
    department_id INT          NOT NULL,
    role          VARCHAR(50)  NOT NULL,
    CONSTRAINT pk_staff PRIMARY KEY (staff_id),
    CONSTRAINT uq_staff_email UNIQUE (email),
    CONSTRAINT fk_staff_department FOREIGN KEY (department_id)
        REFERENCES departments (department_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 5. Table: complaints
-- Purpose: Central incident records for campus facilities issues.
-- -----------------------------------------------------------------------------
CREATE TABLE complaints (
    complaint_id INT          NOT NULL AUTO_INCREMENT,
    student_id   INT          NOT NULL,
    location_id  INT          NOT NULL,
    title        VARCHAR(150) NOT NULL,
    description  TEXT         NOT NULL,
    category     VARCHAR(50)  NOT NULL,
    priority     VARCHAR(20)  NOT NULL DEFAULT 'Medium',
    status       VARCHAR(20)  NOT NULL DEFAULT 'Pending',
    created_at   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_complaints PRIMARY KEY (complaint_id),
    CONSTRAINT fk_complaints_student FOREIGN KEY (student_id)
        REFERENCES students (student_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_complaints_location FOREIGN KEY (location_id)
        REFERENCES locations (location_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT chk_complaints_priority CHECK (
        priority IN ('Low', 'Medium', 'High', 'Critical', 'Urgent',
                     'LOW', 'MEDIUM', 'HIGH', 'CRITICAL', 'URGENT')
    ),
    CONSTRAINT chk_complaints_status CHECK (
        status IN ('Pending', 'Assigned', 'In Progress', 'Resolved', 'Rejected', 'Closed',
                   'PENDING', 'ASSIGNED', 'IN_PROGRESS', 'IN PROGRESS', 'RESOLVED', 'REJECTED', 'CLOSED', 'SUBMITTED')
    )
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 6. Table: complaint_assignments
-- Purpose: Tracks delegation of maintenance personnel to active complaints.
-- -----------------------------------------------------------------------------
CREATE TABLE complaint_assignments (
    assignment_id INT          NOT NULL AUTO_INCREMENT,
    complaint_id  INT          NOT NULL,
    staff_id      INT          NOT NULL,
    assigned_at   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    assigned_by   VARCHAR(100) NOT NULL,
    CONSTRAINT pk_complaint_assignments PRIMARY KEY (assignment_id),
    CONSTRAINT fk_assignments_complaint FOREIGN KEY (complaint_id)
        REFERENCES complaints (complaint_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_assignments_staff FOREIGN KEY (staff_id)
        REFERENCES staff (staff_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 7. Table: complaint_status_history
-- Purpose: Immutable audit trail recording each state transition of an incident.
-- -----------------------------------------------------------------------------
CREATE TABLE complaint_status_history (
    history_id   INT          NOT NULL AUTO_INCREMENT,
    complaint_id INT          NOT NULL,
    old_status   VARCHAR(20)  NULL,
    new_status   VARCHAR(20)  NOT NULL,
    changed_at   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    changed_by   VARCHAR(100) NOT NULL,
    CONSTRAINT pk_complaint_status_history PRIMARY KEY (history_id),
    CONSTRAINT fk_history_complaint FOREIGN KEY (complaint_id)
        REFERENCES complaints (complaint_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT chk_history_old_status CHECK (
        old_status IS NULL OR old_status IN (
            'Pending', 'Assigned', 'In Progress', 'Resolved', 'Rejected', 'Closed',
            'PENDING', 'ASSIGNED', 'IN_PROGRESS', 'IN PROGRESS', 'RESOLVED', 'REJECTED', 'CLOSED', 'SUBMITTED'
        )
    ),
    CONSTRAINT chk_history_new_status CHECK (
        new_status IN (
            'Pending', 'Assigned', 'In Progress', 'Resolved', 'Rejected', 'Closed',
            'PENDING', 'ASSIGNED', 'IN_PROGRESS', 'IN PROGRESS', 'RESOLVED', 'REJECTED', 'CLOSED', 'SUBMITTED'
        )
    )
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 8. Table: feedback
-- Purpose: Student evaluations and satisfaction ratings upon resolution.
--          Enforces 1:0..1 relationship: one complaint can have at most one feedback.
-- -----------------------------------------------------------------------------
CREATE TABLE feedback (
    feedback_id  INT        NOT NULL AUTO_INCREMENT,
    complaint_id INT        NOT NULL,
    student_id   INT        NOT NULL,
    rating       TINYINT    NOT NULL,
    comments     TEXT       NULL,
    submitted_at TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_feedback PRIMARY KEY (feedback_id),
    CONSTRAINT uq_feedback_complaint UNIQUE (complaint_id),
    CONSTRAINT fk_feedback_complaint FOREIGN KEY (complaint_id)
        REFERENCES complaints (complaint_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_feedback_student FOREIGN KEY (student_id)
        REFERENCES students (student_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT chk_feedback_rating CHECK (
        rating BETWEEN 1 AND 5
    )
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci;
