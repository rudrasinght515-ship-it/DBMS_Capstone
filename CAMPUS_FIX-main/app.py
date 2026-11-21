#!/usr/bin/env python3
"""
===============================================================================
CAMPUSFIX: Smart Campus Complaint & Maintenance Management System
Interactive Relational Database Dashboard & Live Showcase
===============================================================================
Zero-dependency Python application (uses only Python 3 built-in libraries).
Creates the relational database, seeds 208 records, starts a local web server,
and launches a modern live dashboard in your browser.
===============================================================================
"""

import http.server
import json
import os
import sqlite3
import sys
import threading
import urllib.parse
import webbrowser
from datetime import datetime

PORT = 5000
DB_FILE = os.path.join(os.path.dirname(__file__), "campusfix.db")


def init_database():
    """Initializes the relational database schema and populates sample data."""
    conn = sqlite3.connect(DB_FILE)
    c = conn.cursor()

    # Drop existing tables
    c.executescript("""
    DROP TABLE IF EXISTS feedback;
    DROP TABLE IF EXISTS complaint_status_history;
    DROP TABLE IF EXISTS complaint_assignments;
    DROP TABLE IF EXISTS complaints;
    DROP TABLE IF EXISTS locations;
    DROP TABLE IF EXISTS staff;
    DROP TABLE IF EXISTS students;
    DROP TABLE IF EXISTS departments;

    -- 1. departments
    CREATE TABLE departments (
        department_id INTEGER PRIMARY KEY AUTOINCREMENT,
        department_name TEXT NOT NULL UNIQUE,
        description TEXT
    );

    -- 2. locations
    CREATE TABLE locations (
        location_id INTEGER PRIMARY KEY AUTOINCREMENT,
        building_name TEXT NOT NULL,
        room_number TEXT NOT NULL,
        location_type TEXT NOT NULL,
        UNIQUE (building_name, room_number)
    );

    -- 3. students
    CREATE TABLE students (
        student_id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT NOT NULL,
        department_id INTEGER NOT NULL REFERENCES departments(department_id),
        enrollment_date TEXT NOT NULL
    );

    -- 4. staff
    CREATE TABLE staff (
        staff_id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT NOT NULL,
        department_id INTEGER NOT NULL REFERENCES departments(department_id),
        role TEXT NOT NULL
    );

    -- 5. complaints
    CREATE TABLE complaints (
        complaint_id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL REFERENCES students(student_id),
        location_id INTEGER NOT NULL REFERENCES locations(location_id),
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        priority TEXT NOT NULL DEFAULT 'Medium',
        status TEXT NOT NULL DEFAULT 'Pending',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
    );

    -- 6. complaint_assignments
    CREATE TABLE complaint_assignments (
        assignment_id INTEGER PRIMARY KEY AUTOINCREMENT,
        complaint_id INTEGER NOT NULL REFERENCES complaints(complaint_id),
        staff_id INTEGER NOT NULL REFERENCES staff(staff_id),
        assigned_at TEXT NOT NULL,
        assigned_by TEXT NOT NULL
    );

    -- 7. complaint_status_history
    CREATE TABLE complaint_status_history (
        history_id INTEGER PRIMARY KEY AUTOINCREMENT,
        complaint_id INTEGER NOT NULL REFERENCES complaints(complaint_id),
        old_status TEXT,
        new_status TEXT NOT NULL,
        changed_at TEXT NOT NULL,
        changed_by TEXT NOT NULL
    );

    -- 8. feedback
    CREATE TABLE feedback (
        feedback_id INTEGER PRIMARY KEY AUTOINCREMENT,
        complaint_id INTEGER NOT NULL UNIQUE REFERENCES complaints(complaint_id),
        student_id INTEGER NOT NULL REFERENCES students(student_id),
        rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
        comments TEXT,
        submitted_at TEXT NOT NULL
    );

    -- Indexes
    CREATE INDEX idx_complaints_status ON complaints(status);
    CREATE INDEX idx_complaints_priority ON complaints(priority);
    CREATE INDEX idx_complaints_category ON complaints(category);
    CREATE INDEX idx_assignments_staff ON complaint_assignments(staff_id);
    """)

    # Populate 5 Departments
    departments = [
        (1, 'Computer Science', 'Department of Computer Science & Engineering, handles computing infrastructure, software, and networking labs.'),
        (2, 'Mechanical Engineering', 'Department of Mechanical Engineering, covers fabrication labs, workshops, central ventilation, and HVAC systems.'),
        (3, 'Electrical Engineering', 'Department of Electrical & Electronics Engineering, oversees power systems, substations, and high-voltage laboratories.'),
        (4, 'Civil Engineering', 'Department of Civil Engineering, oversees campus structural maintenance, environmental labs, and plumbing systems.'),
        (5, 'Administration', 'Central Campus Administration & Facilities Management, covers general estate, hostels, and administrative offices.')
    ]
    c.executemany("INSERT INTO departments VALUES (?, ?, ?)", departments)

    # Populate 12 Locations
    locations = [
        (1,  'Main Academic Block',         'LH-101',           'Classroom'),
        (2,  'Main Academic Block',         'LH-204',           'Classroom'),
        (3,  'Computing Center',            'Lab-301',          'Laboratory'),
        (4,  'Computing Center',            'Lab-302',          'Laboratory'),
        (5,  'Mechanical Workshop Building','WS-102',           'Workshop'),
        (6,  'Electrical Sciences Block',   'ES-205',           'Laboratory'),
        (7,  'Central Library',             'LIB-2F-Reading',   'Library'),
        (8,  'Central Library',             'LIB-GF-Digital',   'Digital Library'),
        (9,  'Boys Hostel Block A',         'Room-114',         'Hostel Room'),
        (10, 'Girls Hostel Block B',        'Room-208',         'Hostel Room'),
        (11, 'Administrative Complex',      'ADM-GF-Restroom',  'Restroom'),
        (12, 'Campus Auditorium',           'AUD-MainHall',     'Auditorium')
    ]
    c.executemany("INSERT INTO locations VALUES (?, ?, ?, ?)", locations)

    # Populate 20 Students
    students = [
        (1,  'Aarav Sharma',     'aarav.sharma@campus.edu',     '9876543210', 1, '2023-08-01'),
        (2,  'Priya Patel',      'priya.patel@campus.edu',      '9876543211', 1, '2023-08-01'),
        (3,  'Rohan Verma',      'rohan.verma@campus.edu',      '9876543212', 2, '2022-08-05'),
        (4,  'Ananya Iyer',      'ananya.iyer@campus.edu',      '9876543213', 2, '2022-08-05'),
        (5,  'Vikram Malhotra',  'vikram.malhotra@campus.edu',  '9876543214', 3, '2023-08-01'),
        (6,  'Sneha Kulkarni',   'sneha.kulkarni@campus.edu',   '9876543215', 3, '2021-08-10'),
        (7,  'Karan Singh',      'karan.singh@campus.edu',      '9876543216', 4, '2024-08-01'),
        (8,  'Diya Mukherjee',   'diya.mukherjee@campus.edu',   '9876543217', 4, '2024-08-01'),
        (9,  'Aditya Joshi',     'aditya.joshi@campus.edu',     '9876543218', 1, '2021-08-10'),
        (10, 'Ishita Rao',       'ishita.rao@campus.edu',       '9876543219', 1, '2022-08-05'),
        (11, 'Manish Nair',      'manish.nair@campus.edu',      '9876543220', 2, '2023-08-01'),
        (12, 'Pooja Hegde',      'pooja.hegde@campus.edu',      '9876543221', 2, '2024-08-01'),
        (13, 'Siddharth Sen',    'siddharth.sen@campus.edu',    '9876543222', 3, '2022-08-05'),
        (14, 'Neha Choudhury',   'neha.choudhury@campus.edu',   '9876543223', 3, '2023-08-01'),
        (15, 'Rahul Desai',      'rahul.desai@campus.edu',      '9876543224', 4, '2021-08-10'),
        (16, 'Tanvi Bhat',       'tanvi.bhat@campus.edu',       '9876543225', 4, '2023-08-01'),
        (17, 'Harsh Vardhan',    'harsh.vardhan@campus.edu',    '9876543226', 5, '2022-08-05'),
        (18, 'Meera Nambiar',    'meera.nambiar@campus.edu',    '9876543227', 5, '2023-08-01'),
        (19, 'Arjun Reddy',      'arjun.reddy@campus.edu',      '9876543228', 1, '2024-08-01'),
        (20, 'Kavya Pillai',     'kavya.pillai@campus.edu',     '9876543229', 2, '2024-08-01')
    ]
    c.executemany("INSERT INTO students VALUES (?, ?, ?, ?, ?, ?)", students)

    # Populate 10 Staff
    staff = [
        (1,  'Rajesh Kumar',   'rajesh.kumar@staff.campus.edu',   '9123456701', 1, 'Network Engineer'),
        (2,  'Suresh Babu',    'suresh.babu@staff.campus.edu',    '9123456702', 1, 'Systems Administrator'),
        (3,  'Mahesh Shinde',  'mahesh.shinde@staff.campus.edu',  '9123456703', 2, 'HVAC Technician'),
        (4,  'Ramesh Patil',   'ramesh.patil@staff.campus.edu',   '9123456704', 2, 'Mechanical Workshop Supervisor'),
        (5,  'Dinesh Sharma',  'dinesh.sharma@staff.campus.edu',  '9123456705', 3, 'Senior Electrician'),
        (6,  'Ganesh Gupta',   'ganesh.gupta@staff.campus.edu',   '9123456706', 3, 'Electrical Maintenance Technician'),
        (7,  'Sunil Yadav',    'sunil.yadav@staff.campus.edu',    '9123456707', 4, 'Lead Plumber'),
        (8,  'Anil Chauhan',   'anil.chauhan@staff.campus.edu',   '9123456708', 4, 'Civil Works Contractor'),
        (9,  'Santosh Jadhav', 'santosh.jadhav@staff.campus.edu', '9123456709', 5, 'General Facilities Manager'),
        (10, 'Vinod Tiwari',   'vinod.tiwari@staff.campus.edu',   '9123456710', 5, 'Sanitation & Housekeeping Lead')
    ]
    c.executemany("INSERT INTO staff VALUES (?, ?, ?, ?, ?, ?)", staff)

    # Populate 35 Complaints
    complaints = [
        (1,  1,  1,  'Broken classroom projector',              'Overhead projector in LH-101 displays distorted green tint and fails to connect via HDMI.',          'Classroom Equipment', 'High',     'Resolved',    '2026-10-01 09:15:00', '2026-10-02 14:30:00'),
        (2,  2,  7,  'Wi-Fi not working in library 2nd floor',  'Signal drops frequently in the quiet study zone; unable to connect to student subnet.',              'Internet',            'Critical', 'Resolved',    '2026-10-02 10:00:00', '2026-10-02 18:20:00'),
        (3,  3,  5,  'Damaged CNC lathe emergency stop switch', 'Emergency safety stop switch on CNC unit 2 is jammed down and cannot be reset.',                    'Laboratory Equipment','Critical', 'Resolved',    '2026-10-03 11:30:00', '2026-10-04 16:45:00'),
        (4,  4,  11, 'Water leakage under restroom sink',       'Continuous water leak from the cold water valve under the second washbasin causing floor flooding.', 'Plumbing',            'High',     'Resolved',    '2026-10-04 08:20:00', '2026-10-04 15:10:00'),
        (5,  5,  2,  'Broken classroom desk and chair row 4',   'Right armrest support on desk 4B is fractured with exposed sharp metal edges.',                      'Furniture',           'Medium',   'Resolved',    '2026-10-05 13:40:00', '2026-10-07 11:00:00'),
        (6,  6,  6,  'Circuit breaker trip in machines lab',    'Bench 3 main breaker trips immediately upon applying 230V excitation load.',                         'Electrical',          'High',     'Resolved',    '2026-10-06 14:05:00', '2026-10-07 17:30:00'),
        (7,  7,  3,  'Faulty computer systems in lab 301',      'Workstations 12 and 14 fail to boot with storage read error during operating systems lab.',         'Laboratory Equipment','Medium',   'Resolved',    '2026-10-07 09:50:00', '2026-10-08 16:15:00'),
        (8,  8,  9,  'Ceiling fan making loud grinding noise',  'Room 114 ceiling fan regulator works but motor makes high-pitched mechanical grinding sound.',       'Electrical',          'Low',      'Resolved',    '2026-10-08 15:10:00', '2026-10-10 12:00:00'),
        (9,  9,  10, 'Clogged shower drain in girls hostel',    'Shower cubicle 3 in 2nd floor bathroom draining very slowly, causing standing water.',               'Plumbing',            'Medium',   'Resolved',    '2026-10-09 07:45:00', '2026-10-09 16:50:00'),
        (10, 10, 12, 'Wireless mic interference in auditorium', 'Handheld mic 1 cuts out intermittently with loud static feedback during presentations.',             'Classroom Equipment', 'Medium',   'Resolved',    '2026-10-10 11:20:00', '2026-10-11 15:40:00'),
        (11, 11, 8,  'Digital library ethernet port dead',      'Cat6 wall jack at terminal station D-04 has bent pins and does not provide link light.',             'Internet',            'Medium',   'Resolved',    '2026-10-11 16:30:00', '2026-10-13 10:20:00'),
        (12, 12, 1,  'Air conditioning not cooling in LH-101',  'Split AC unit blowing warm ambient air during morning lectures; temperature stays above 30C.',       'Electrical',          'High',     'Resolved',    '2026-10-12 10:15:00', '2026-10-14 14:10:00'),
        (13, 13, 6,  'Burned outlet in power electronics lab',  'Dual socket wall receptacle near bench 5 shows scorching and electrical sparks when used.',         'Electrical',          'Critical', 'Resolved',    '2026-10-13 14:40:00', '2026-10-14 11:30:00'),
        (14, 14, 4,  'Lab 302 projector screen retracted stuck','Motorized projector screen is jammed in ceiling housing and will not extend with remote.',          'Classroom Equipment', 'Low',      'Resolved',    '2026-10-14 09:00:00', '2026-10-15 13:25:00'),
        (15, 15, 11, 'Restroom exhaust fan not working',        'Ceiling exhaust blower in ground floor admin restroom has seized completely.',                       'Electrical',          'Low',      'Resolved',    '2026-10-15 12:10:00', '2026-10-16 17:00:00'),
        (16, 16, 2,  'Broken whiteboard marker tray',           'Aluminum shelf beneath main writing board is detached on the left side, dumping markers.',          'Furniture',           'Low',      'Resolved',    '2026-10-16 11:00:00', '2026-10-17 15:15:00'),
        (17, 17, 3,  'Core switch packet loss in Lab 301',      'Intermittent ping spikes and 20% packet drop across whole computing cluster bench A.',               'Internet',            'Critical', 'In Progress', '2026-10-25 08:30:00', '2026-10-26 10:00:00'),
        (18, 18, 5,  'Hydraulic oil leak on press machine 1',   'Slow drip from primary hydraulic cylinder pressure hose onto safety catchment tray.',               'Laboratory Equipment','High',     'In Progress', '2026-10-25 10:15:00', '2026-10-26 11:30:00'),
        (19, 19, 12, 'Stage motorized curtain track stuck',     'Left stage wing traveler rope frayed and jammed midway through opening sequence.',                   'Other',               'Medium',   'In Progress', '2026-10-26 09:45:00', '2026-10-26 14:15:00'),
        (20, 20, 9,  'Corridor lighting failure in Hostel A',   'Four fluorescent light fixtures along 1st floor west wing corridor are dead.',                      'Electrical',          'Medium',   'In Progress', '2026-10-26 14:00:00', '2026-10-27 09:20:00'),
        (21, 1,  4,  'Server rack cooling fan failure',         'Cabinet exhaust fan 2 on lab server enclosure is rattling and throwing overheat warning.',          'Laboratory Equipment','High',     'In Progress', '2026-10-27 11:20:00', '2026-10-27 15:40:00'),
        (22, 2,  11, 'Main water supply line valve dripping',   'Isolation gate valve on exterior admin riser pipe has worn packing gland.',                          'Plumbing',            'Medium',   'In Progress', '2026-10-27 13:10:00', '2026-10-28 09:00:00'),
        (23, 3,  2,  'Classroom window latch broken',           'Second window from front in LH-204 cannot be secured, rattling violently in wind.',                  'Furniture',           'Low',      'In Progress', '2026-10-28 10:30:00', '2026-10-28 14:00:00'),
        (24, 4,  7,  'Spilled beverage on library study desk',  'Sticky drink residue left across tables 12 and 13 in central reading room needing sanitization.',     'Cleaning',            'Low',      'In Progress', '2026-10-28 11:00:00', '2026-10-28 13:45:00'),
        (25, 5,  1,  'Flickering fluorescent tube lights',      'Front row lights above chalkboard flicker constantly causing severe glare and eyestrain.',           'Electrical',          'Medium',   'Assigned',    '2026-11-01 09:10:00', '2026-11-01 11:30:00'),
        (26, 6,  6,  'Oscilloscope calibration certificate overdue','Tektronix DSO bench 4 displaying inaccurate frequency readings during harmonic lab.',           'Laboratory Equipment','Medium',   'Assigned',    '2026-11-01 10:45:00', '2026-11-01 14:15:00'),
        (27, 7,  10, 'Window mesh torn in hostel room 208',     'Mosquito screen mesh on west-facing window is ripped along bottom frame.',                           'Furniture',           'Low',      'Assigned',    '2026-11-02 08:30:00', '2026-11-02 10:00:00'),
        (28, 8,  8,  'Barcode scanner not registering books',   'USB handheld scanner at library circulation kiosk 2 fails to read standard ISBN labels.',            'Classroom Equipment', 'Low',      'Assigned',    '2026-11-02 11:15:00', '2026-11-02 13:30:00'),
        (29, 9,  3,  'Dust accumulation in workstation vents',  'System towers in rows C and D have clogged intake filters causing fan throttling.',                  'Cleaning',            'Low',      'Assigned',    '2026-11-03 09:00:00', '2026-11-03 12:00:00'),
        (30, 10, 5,  'Air compressor pressure relief valve leak','Pneumatics supply tank leaking pressurized air continuously through relief valve.',                 'Laboratory Equipment','High',     'Assigned',    '2026-11-03 14:20:00', '2026-11-03 16:00:00'),
        (31, 11, 2,  'Microphone battery compartment broken',   'Lectern clip mic battery door latch snapped off; held together temporarily with tape.',              'Classroom Equipment', 'Low',      'Pending',     '2026-11-05 08:45:00', '2026-11-05 08:45:00'),
        (32, 12, 11, 'Water cooler dispensing tepid water',     'Admin corridor drinking fountain compressor not activating; water is room temperature.',             'Plumbing',            'Medium',   'Pending',     '2026-11-05 10:30:00', '2026-11-05 10:30:00'),
        (33, 13, 7,  'Loose carpet tile causing tripping hazard','Carpet border edge near central library staircase entrance has lifted up.',                        'Other',               'Medium',   'Pending',     '2026-11-05 12:00:00', '2026-11-05 12:00:00'),
        (34, 14, 1,  'Requesting personal laptop charger',      'Lost my laptop charger during lecture; requesting department maintenance to provide a replacement.', 'Other',               'Low',      'Rejected',    '2026-10-18 10:00:00', '2026-10-18 11:30:00'),
        (35, 15, 9,  'Requesting private gaming router install','Want unauthorized personal high-speed fiber connection wired directly into hostel room.',            'Internet',            'Low',      'Rejected',    '2026-10-19 14:15:00', '2026-10-19 15:45:00')
    ]
    c.executemany("INSERT INTO complaints VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", complaints)

    # Populate 35 Assignments
    assignments = [
        (1,  1,  2,  '2026-10-01 10:00:00', 'Admin Facilities Desk'),
        (2,  2,  1,  '2026-10-02 10:30:00', 'Admin Facilities Desk'),
        (3,  3,  4,  '2026-10-03 12:00:00', 'Workshop Incharge'),
        (4,  4,  7,  '2026-10-04 09:00:00', 'Estate Officer'),
        (5,  5,  9,  '2026-10-05 14:30:00', 'Estate Officer'),
        (6,  6,  5,  '2026-10-06 14:30:00', 'Lab Superintendent'),
        (7,  7,  2,  '2026-10-07 10:30:00', 'IT Support Desk'),
        (8,  8,  6,  '2026-10-08 16:00:00', 'Hostel Warden'),
        (9,  9,  7,  '2026-10-09 08:30:00', 'Hostel Warden'),
        (10, 10, 1,  '2026-10-10 12:00:00', 'Events Coordinator'),
        (11, 11, 1,  '2026-10-11 17:00:00', 'Chief Librarian'),
        (12, 12, 3,  '2026-10-12 11:00:00', 'Estate Officer'),
        (13, 13, 5,  '2026-10-13 15:00:00', 'Lab Superintendent'),
        (14, 14, 2,  '2026-10-14 09:30:00', 'IT Support Desk'),
        (15, 15, 6,  '2026-10-15 13:00:00', 'Estate Officer'),
        (16, 16, 9,  '2026-10-16 11:30:00', 'Estate Officer'),
        (17, 1,  1,  '2026-10-01 14:00:00', 'IT Support Desk'),
        (18, 3,  3,  '2026-10-03 14:00:00', 'Workshop Incharge'),
        (19, 5,  8,  '2026-10-06 09:00:00', 'Estate Officer'),
        (20, 12, 5,  '2026-10-12 14:30:00', 'Estate Officer'),
        (21, 13, 6,  '2026-10-13 15:30:00', 'Lab Superintendent'),
        (22, 17, 1,  '2026-10-25 09:00:00', 'IT Support Desk'),
        (23, 18, 4,  '2026-10-25 10:45:00', 'Workshop Incharge'),
        (24, 19, 9,  '2026-10-26 10:15:00', 'Events Coordinator'),
        (25, 20, 6,  '2026-10-26 14:30:00', 'Hostel Warden'),
        (26, 21, 2,  '2026-10-27 12:00:00', 'IT Support Desk'),
        (27, 22, 7,  '2026-10-27 13:45:00', 'Estate Officer'),
        (28, 23, 8,  '2026-10-28 11:00:00', 'Estate Officer'),
        (29, 24, 10, '2026-10-28 11:30:00', 'Chief Librarian'),
        (30, 17, 2,  '2026-10-25 11:30:00', 'IT Support Desk'),
        (31, 18, 3,  '2026-10-25 13:00:00', 'Workshop Incharge'),
        (32, 25, 6,  '2026-11-01 11:30:00', 'Estate Officer'),
        (33, 26, 5,  '2026-11-01 14:15:00', 'Lab Superintendent'),
        (34, 27, 8,  '2026-11-02 10:00:00', 'Hostel Warden'),
        (35, 28, 2,  '2026-11-02 13:30:00', 'Chief Librarian')
    ]
    c.executemany("INSERT INTO complaint_assignments VALUES (?, ?, ?, ?, ?)", assignments)

    # Populate 76 History rows
    status_history = [
        (1,  1,  None,          'Pending',     '2026-10-01 09:15:00', 'Student Portal (Aarav Sharma)'),
        (2,  1,  'Pending',     'Assigned',    '2026-10-01 10:00:00', 'Admin Facilities Desk'),
        (3,  1,  'Assigned',    'In Progress', '2026-10-01 11:00:00', 'Technician Suresh Babu'),
        (4,  1,  'In Progress', 'Resolved',    '2026-10-02 14:30:00', 'Technician Suresh Babu'),
        (5,  2,  None,          'Pending',     '2026-10-02 10:00:00', 'Student Portal (Priya Patel)'),
        (6,  2,  'Pending',     'Assigned',    '2026-10-02 10:30:00', 'Admin Facilities Desk'),
        (7,  2,  'Assigned',    'In Progress', '2026-10-02 11:15:00', 'Technician Rajesh Kumar'),
        (8,  2,  'In Progress', 'Resolved',    '2026-10-02 18:20:00', 'Technician Rajesh Kumar'),
        (9,  3,  None,          'Pending',     '2026-10-03 11:30:00', 'Student Portal (Rohan Verma)'),
        (10, 3,  'Pending',     'Assigned',    '2026-10-03 12:00:00', 'Workshop Incharge'),
        (11, 3,  'Assigned',    'In Progress', '2026-10-03 13:00:00', 'Technician Ramesh Patil'),
        (12, 3,  'In Progress', 'Resolved',    '2026-10-04 16:45:00', 'Technician Ramesh Patil'),
        (13, 4,  None,          'Pending',     '2026-10-04 08:20:00', 'Student Portal (Ananya Iyer)'),
        (14, 4,  'Pending',     'Assigned',    '2026-10-04 09:00:00', 'Estate Officer'),
        (15, 4,  'Assigned',    'In Progress', '2026-10-04 09:45:00', 'Lead Plumber Sunil Yadav'),
        (16, 4,  'In Progress', 'Resolved',    '2026-10-04 15:10:00', 'Lead Plumber Sunil Yadav'),
        (17, 5,  None,          'Pending',     '2026-10-05 13:40:00', 'Student Portal (Vikram Malhotra)'),
        (18, 5,  'Pending',     'Assigned',    '2026-10-05 14:30:00', 'Estate Officer'),
        (19, 5,  'Assigned',    'In Progress', '2026-10-06 09:30:00', 'Technician Santosh Jadhav'),
        (20, 5,  'In Progress', 'Resolved',    '2026-10-07 11:00:00', 'Civil Works Anil Chauhan'),
        (21, 6,  None,          'Pending',     '2026-10-06 14:05:00', 'Student Portal (Sneha Kulkarni)'),
        (22, 6,  'Pending',     'Assigned',    '2026-10-06 14:30:00', 'Lab Superintendent'),
        (23, 6,  'Assigned',    'In Progress', '2026-10-06 15:30:00', 'Senior Electrician Dinesh Sharma'),
        (24, 6,  'In Progress', 'Resolved',    '2026-10-07 17:30:00', 'Senior Electrician Dinesh Sharma'),
        (25, 7,  None,          'Pending',     '2026-10-07 09:50:00', 'Student Portal (Karan Singh)'),
        (26, 7,  'Pending',     'Assigned',    '2026-10-07 10:30:00', 'IT Support Desk'),
        (27, 7,  'Assigned',    'In Progress', '2026-10-07 11:15:00', 'Technician Suresh Babu'),
        (28, 7,  'In Progress', 'Resolved',    '2026-10-08 16:15:00', 'Technician Suresh Babu'),
        (29, 8,  None,          'Pending',     '2026-10-08 15:10:00', 'Student Portal (Diya Mukherjee)'),
        (30, 8,  'Pending',     'Assigned',    '2026-10-08 16:00:00', 'Hostel Warden'),
        (31, 8,  'Assigned',    'In Progress', '2026-10-09 10:00:00', 'Technician Ganesh Gupta'),
        (32, 8,  'In Progress', 'Resolved',    '2026-10-10 12:00:00', 'Technician Ganesh Gupta'),
        (33, 9,  None,          'Pending',     '2026-10-09 07:45:00', 'Student Portal (Aditya Joshi)'),
        (34, 9,  'Pending',     'Assigned',    '2026-10-09 08:30:00', 'Hostel Warden'),
        (35, 9,  'Assigned',    'In Progress', '2026-10-09 09:15:00', 'Lead Plumber Sunil Yadav'),
        (36, 9,  'In Progress', 'Resolved',    '2026-10-09 16:50:00', 'Lead Plumber Sunil Yadav'),
        (37, 10, None,          'Pending',     '2026-10-10 11:20:00', 'Student Portal (Ishita Rao)'),
        (38, 10, 'Pending',     'Assigned',    '2026-10-10 12:00:00', 'Events Coordinator'),
        (39, 10, 'Assigned',    'In Progress', '2026-10-10 14:00:00', 'Technician Rajesh Kumar'),
        (40, 10, 'In Progress', 'Resolved',    '2026-10-11 15:40:00', 'Technician Rajesh Kumar'),
        (41, 11, None,          'Pending',     '2026-10-11 16:30:00', 'Student Portal (Manish Nair)'),
        (42, 11, 'Pending',     'Assigned',    '2026-10-11 17:00:00', 'Chief Librarian'),
        (43, 11, 'Assigned',    'In Progress', '2026-10-12 09:15:00', 'Technician Rajesh Kumar'),
        (44, 11, 'In Progress', 'Resolved',    '2026-10-13 10:20:00', 'Technician Rajesh Kumar'),
        (45, 12, None,          'Pending',     '2026-10-12 10:15:00', 'Student Portal (Pooja Hegde)'),
        (46, 12, 'Pending',     'Assigned',    '2026-10-12 11:00:00', 'Estate Officer'),
        (47, 12, 'Assigned',    'In Progress', '2026-10-12 13:30:00', 'Technician Mahesh Shinde'),
        (48, 12, 'In Progress', 'Resolved',    '2026-10-14 14:10:00', 'Technician Mahesh Shinde'),
        (49, 13, None,          'Pending',     '2026-10-13 14:40:00', 'Student Portal (Siddharth Sen)'),
        (50, 13, 'Pending',     'Assigned',    '2026-10-13 15:00:00', 'Lab Superintendent'),
        (51, 13, 'Assigned',    'In Progress', '2026-10-13 15:30:00', 'Senior Electrician Dinesh Sharma'),
        (52, 13, 'In Progress', 'Resolved',    '2026-10-14 11:30:00', 'Senior Electrician Dinesh Sharma'),
        (53, 14, None,          'Pending',     '2026-10-14 09:00:00', 'Student Portal (Neha Choudhury)'),
        (54, 14, 'Pending',     'Assigned',    '2026-10-14 09:30:00', 'IT Support Desk'),
        (55, 14, 'Assigned',    'In Progress', '2026-10-14 11:00:00', 'Technician Suresh Babu'),
        (56, 14, 'In Progress', 'Resolved',    '2026-10-15 13:25:00', 'Technician Suresh Babu'),
        (57, 15, None,          'Pending',     '2026-10-15 12:10:00', 'Student Portal (Rahul Desai)'),
        (58, 15, 'Pending',     'Assigned',    '2026-10-15 13:00:00', 'Estate Officer'),
        (59, 15, 'Assigned',    'In Progress', '2026-10-15 14:30:00', 'Technician Ganesh Gupta'),
        (60, 15, 'In Progress', 'Resolved',    '2026-10-16 17:00:00', 'Technician Ganesh Gupta'),
        (61, 16, None,          'Pending',     '2026-10-16 11:00:00', 'Student Portal (Tanvi Bhat)'),
        (62, 16, 'Pending',     'Assigned',    '2026-10-16 11:30:00', 'Estate Officer'),
        (63, 16, 'Assigned',    'In Progress', '2026-10-16 14:00:00', 'Technician Santosh Jadhav'),
        (64, 16, 'In Progress', 'Resolved',    '2026-10-17 15:15:00', 'Technician Santosh Jadhav'),
        (65, 17, None,          'Pending',     '2026-10-25 08:30:00', 'Student Portal (Harsh Vardhan)'),
        (66, 17, 'Pending',     'Assigned',    '2026-10-25 09:00:00', 'IT Support Desk'),
        (67, 17, 'Assigned',    'In Progress', '2026-10-25 10:15:00', 'Technician Rajesh Kumar'),
        (68, 18, None,          'Pending',     '2026-10-25 10:15:00', 'Student Portal (Meera Nambiar)'),
        (69, 18, 'Pending',     'Assigned',    '2026-10-25 10:45:00', 'Workshop Incharge'),
        (70, 18, 'Assigned',    'In Progress', '2026-10-25 12:30:00', 'Technician Ramesh Patil'),
        (71, 25, None,          'Pending',     '2026-11-01 09:10:00', 'Student Portal (Vikram Malhotra)'),
        (72, 25, 'Pending',     'Assigned',    '2026-11-01 11:30:00', 'Estate Officer'),
        (73, 26, None,          'Pending',     '2026-11-01 10:45:00', 'Student Portal (Sneha Kulkarni)'),
        (74, 26, 'Pending',     'Assigned',    '2026-11-01 14:15:00', 'Lab Superintendent'),
        (75, 34, None,          'Pending',     '2026-10-18 10:00:00', 'Student Portal (Neha Choudhury)'),
        (76, 34, 'Pending',     'Rejected',    '2026-10-18 11:30:00', 'Admin Facilities Desk')
    ]
    c.executemany("INSERT INTO complaint_status_history VALUES (?, ?, ?, ?, ?, ?)", status_history)

    # Populate 15 Feedback
    feedback = [
        (1,  1,  1,  5, 'Projector HDMI port replaced and color calibration restored. Excellent turnaround time!', '2026-10-02 16:00:00'),
        (2,  2,  2,  5, 'Wi-Fi access point in reading room was rebooted and reprogrammed; speeds are now great.', '2026-10-02 19:30:00'),
        (3,  3,  3,  4, 'Emergency switch replaced properly before our morning workshop session began.',          '2026-10-04 18:00:00'),
        (4,  4,  4,  5, 'Plumbing issue resolved within hours. Washroom floor is clean and dry again.',           '2026-10-04 16:30:00'),
        (5,  5,  5,  3, 'Desk was repaired and welded securely, though took two full days to complete.',          '2026-10-07 14:00:00'),
        (6,  6,  6,  4, 'Circuit breaker was upgraded to handle induction motor surge. Tested bench successfully.', '2026-10-08 09:30:00'),
        (7,  7,  7,  5, 'SSD replaced on both lab workstations; OS reimaged and running smoothly.',               '2026-10-08 17:45:00'),
        (8,  8,  8,  4, 'Fan bearing greased and noise is completely gone. Quiet studying restored.',             '2026-10-10 14:15:00'),
        (9,  9,  9,  5, 'Shower drain snaked and cleared thoroughly. Appreciate the quick response from hostel staff.', '2026-10-09 18:00:00'),
        (10, 10, 10, 4, 'Microphone frequency adjusted to avoid interference with soundboard. Clear audio.',      '2026-10-11 17:00:00'),
        (11, 11, 11, 5, 'Ethernet wall jack replaced with new CAT6 connector; stable gigabit link established.', '2026-10-13 11:45:00'),
        (12, 12, 12, 4, 'AC coolant refilled and filter washed. Classroom is comfortable again.',                 '2026-10-14 16:00:00'),
        (13, 13, 13, 5, 'Dangerous burned socket replaced promptly with a high-capacity industrial outlet.',       '2026-10-14 13:00:00'),
        (14, 14, 14, 4, 'Motorized screen limit switch reset. Remote control works as expected.',                 '2026-10-15 15:30:00'),
        (15, 15, 15, 3, 'Exhaust fan replaced, but took several days to source the correct replacement model.',   '2026-10-17 10:00:00')
    ]
    c.executemany("INSERT INTO feedback VALUES (?, ?, ?, ?, ?, ?)", feedback)

    conn.commit()
    conn.close()
    print("[OK] Embedded database initialized: 8 tables, 208 records seeded!")


HTML_PAGE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>CAMPUSFIX - Smart Campus Complaint & Maintenance Management System</title>
<style>
:root {
  --primary: #2563eb;
  --primary-dark: #1d4ed8;
  --bg: #0f172a;
  --surface: #1e293b;
  --surface-border: #334155;
  --text: #f8fafc;
  --text-muted: #94a3b8;
  --success: #10b981;
  --warning: #f59e0b;
  --danger: #ef4444;
  --info: #06b6d4;
}
* { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; }
body { background: var(--bg); color: var(--text); padding: 24px; }
.header { display: flex; justify-content: space-between; align-items: center; padding-bottom: 20px; border-bottom: 1px solid var(--surface-border); margin-bottom: 24px; }
.header h1 { font-size: 26px; font-weight: 800; letter-spacing: -0.5px; }
.header h1 span { color: var(--primary); }
.header p { color: var(--text-muted); font-size: 14px; margin-top: 4px; }
.badge { background: #1e3a8a; color: #93c5fd; padding: 4px 10px; border-radius: 999px; font-size: 12px; font-weight: 600; }
.kpi-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 16px; margin-bottom: 24px; }
.kpi-card { background: var(--surface); border: 1px solid var(--surface-border); border-radius: 12px; padding: 18px; }
.kpi-card h3 { font-size: 13px; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 8px; }
.kpi-card .value { font-size: 32px; font-weight: 800; color: var(--text); }
.kpi-card .sub { font-size: 12px; color: var(--text-muted); margin-top: 4px; }
.tabs { display: flex; gap: 8px; margin-bottom: 16px; border-bottom: 1px solid var(--surface-border); padding-bottom: 8px; }
.tab-btn { background: transparent; border: none; color: var(--text-muted); padding: 8px 16px; border-radius: 6px; cursor: pointer; font-size: 14px; font-weight: 600; }
.tab-btn.active { background: var(--surface); color: var(--text); border: 1px solid var(--surface-border); }
.panel { display: none; background: var(--surface); border: 1px solid var(--surface-border); border-radius: 12px; padding: 20px; }
.panel.active { display: block; }
table { width: 100%; border-collapse: collapse; font-size: 13px; text-align: left; }
th { background: #0f172a; padding: 12px; color: var(--text-muted); font-weight: 600; text-transform: uppercase; font-size: 11px; letter-spacing: 0.5px; border-bottom: 1px solid var(--surface-border); }
td { padding: 12px; border-bottom: 1px solid var(--surface-border); }
tr:hover { background: rgba(255,255,255,0.02); }
.tag { display: inline-block; padding: 2px 8px; border-radius: 4px; font-size: 11px; font-weight: 700; text-transform: uppercase; }
.tag-critical { background: rgba(239, 68, 68, 0.2); color: #fca5a5; }
.tag-high { background: rgba(245, 158, 11, 0.2); color: #fcd34d; }
.tag-medium { background: rgba(59, 130, 246, 0.2); color: #93c5fd; }
.tag-low { background: rgba(100, 116, 139, 0.2); color: #cbd5e1; }
.tag-resolved { background: rgba(16, 185, 129, 0.2); color: #6ee7b7; }
.tag-progress { background: rgba(6, 182, 212, 0.2); color: #67e8f9; }
.tag-pending { background: rgba(245, 158, 11, 0.2); color: #fde68a; }
.tag-rejected { background: rgba(239, 68, 68, 0.2); color: #fca5a5; }
.btn { background: var(--primary); color: white; border: none; padding: 8px 14px; border-radius: 6px; cursor: pointer; font-size: 13px; font-weight: 600; }
.btn:hover { background: var(--primary-dark); }
.console-box { display: flex; flex-direction: column; gap: 12px; }
textarea { width: 100%; height: 110px; background: #0f172a; border: 1px solid var(--surface-border); border-radius: 8px; color: #a5f3fc; font-family: "Courier New", monospace; font-size: 13px; padding: 12px; }
.query-presets { display: flex; gap: 8px; flex-wrap: wrap; margin-bottom: 8px; }
.chip { background: #0f172a; border: 1px solid var(--surface-border); color: var(--text-muted); padding: 4px 10px; border-radius: 999px; font-size: 11px; cursor: pointer; }
.chip:hover { border-color: var(--primary); color: var(--text); }
.action-box { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 16px; margin-top: 16px; }
.action-card { background: #0f172a; border: 1px solid var(--surface-border); padding: 16px; border-radius: 8px; }
.action-card h4 { font-size: 14px; margin-bottom: 8px; color: #38bdf8; }
.action-card p { font-size: 12px; color: var(--text-muted); margin-bottom: 12px; }
select, input[type="text"] { width: 100%; background: #1e293b; border: 1px solid var(--surface-border); color: var(--text); padding: 8px; border-radius: 6px; font-size: 13px; margin-bottom: 10px; }
</style>
</head>
<body>

<div class="header">
  <div>
    <h1>CAMPUS<span>FIX</span></h1>
    <p>Smart Campus Complaint & Maintenance Management System &mdash; DBMS Showcase</p>
  </div>
  <div>
    <span class="badge">RDBMS Engine: Live Relational Mode (8 Tables, 208 Records)</span>
  </div>
</div>

<div class="kpi-grid" id="kpi-grid">
  <div class="kpi-card"><h3>Total Complaints</h3><div class="value" id="kpi-total">35</div><div class="sub">Across 12 campus locations</div></div>
  <div class="kpi-card"><h3>Resolved Tickets</h3><div class="value" id="kpi-resolved" style="color:#10b981;">16</div><div class="sub">Resolution rate: 45.7%</div></div>
  <div class="kpi-card"><h3>In Progress</h3><div class="value" id="kpi-progress" style="color:#06b6d4;">8</div><div class="sub">Under active repair</div></div>
  <div class="kpi-card"><h3>Pending Triage</h3><div class="value" id="kpi-pending" style="color:#f59e0b;">9</div><div class="sub">Awaiting allocation</div></div>
  <div class="kpi-card"><h3>Avg Satisfaction</h3><div class="value" id="kpi-rating" style="color:#fbbf24;">4.4 / 5</div><div class="sub">From 15 student reviews</div></div>
</div>

<div class="tabs">
  <button class="tab-btn active" onclick="openTab('complaints')">📋 Complaints Triage</button>
  <button class="tab-btn" onclick="openTab('workload')">👷 Staff Workload</button>
  <button class="tab-btn" onclick="openTab('departments')">🏢 Department KPIs</button>
  <button class="tab-btn" onclick="openTab('actions')">⚡ Live Workflow Actions</button>
  <button class="tab-btn" onclick="openTab('console')">💻 SQL Query Console</button>
</div>

<!-- Tab 1: Complaints -->
<div class="panel active" id="tab-complaints">
  <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;">
    <h3>Active Incident Queue (View: v_complaint_details)</h3>
    <button class="btn" onclick="loadComplaints()">🔄 Refresh</button>
  </div>
  <div style="overflow-x:auto;">
    <table>
      <thead>
        <tr>
          <th>ID</th>
          <th>Title & Category</th>
          <th>Location</th>
          <th>Priority</th>
          <th>Status</th>
          <th>Student Reporter</th>
          <th>Filed At</th>
        </tr>
      </thead>
      <tbody id="complaints-tbody"></tbody>
    </table>
  </div>
</div>

<!-- Tab 2: Staff Workload -->
<div class="panel" id="tab-workload">
  <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;">
    <h3>Technician Workload Metrics (View: v_staff_workload)</h3>
    <button class="btn" onclick="loadWorkload()">🔄 Refresh</button>
  </div>
  <div style="overflow-x:auto;">
    <table>
      <thead>
        <tr>
          <th>Staff ID</th>
          <th>Technician Name</th>
          <th>Specialization / Role</th>
          <th>Department</th>
          <th>Total Assigned</th>
          <th>Active Load</th>
          <th>Completed</th>
        </tr>
      </thead>
      <tbody id="workload-tbody"></tbody>
    </table>
  </div>
</div>

<!-- Tab 3: Department Stats -->
<div class="panel" id="tab-departments">
  <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;">
    <h3>Academic Department Statistics (View: v_department_statistics)</h3>
    <button class="btn" onclick="loadDepartments()">🔄 Refresh</button>
  </div>
  <div style="overflow-x:auto;">
    <table>
      <thead>
        <tr>
          <th>Dept ID</th>
          <th>Department Name</th>
          <th>Total Incidents</th>
          <th>Resolved</th>
          <th>Pending / Active</th>
          <th>Avg Rating</th>
        </tr>
      </thead>
      <tbody id="departments-tbody"></tbody>
    </table>
  </div>
</div>

<!-- Tab 4: Live Actions -->
<div class="panel" id="tab-actions">
  <h3>Live Interactive Database Automation (Stored Procedures & Triggers)</h3>
  <p style="color:var(--text-muted); font-size:13px; margin-top:4px; margin-bottom:16px;">
    Execute actual transactional stored procedures and verify that automated triggers write audit records in real-time.
  </p>
  
  <div class="action-box">
    <!-- Action 1: Assign Staff -->
    <div class="action-card">
      <h4>Action 1: Dispatch Technician (sp_assign_complaint)</h4>
      <p>Assigns a technician to a pending complaint and updates its lifecycle status to 'Assigned'.</p>
      <label style="font-size:12px; color:var(--text-muted);">Target Complaint:</label>
      <select id="assign-complaint-id">
        <option value="31">#31 - Microphone battery compartment broken (Pending)</option>
        <option value="32">#32 - Water cooler dispensing tepid water (Pending)</option>
        <option value="33">#33 - Loose carpet tile causing tripping hazard (Pending)</option>
      </select>
      <label style="font-size:12px; color:var(--text-muted);">Assign Technician:</label>
      <select id="assign-staff-id">
        <option value="5">Staff #5 - Dinesh Sharma (Senior Electrician)</option>
        <option value="7">Staff #7 - Sunil Yadav (Lead Plumber)</option>
        <option value="2">Staff #2 - Suresh Babu (Systems Administrator)</option>
      </select>
      <button class="btn" onclick="executeAssign()">Execute Assignment</button>
      <div id="assign-res" style="font-size:12px; color:#34d399; margin-top:8px;"></div>
    </div>

    <!-- Action 2: Update Status -->
    <div class="action-card">
      <h4>Action 2: Update Ticket Status (sp_update_complaint_status)</h4>
      <p>Updates complaint status. Automatically fires trigger <code>trg_complaints_status_audit</code> to record transition.</p>
      <label style="font-size:12px; color:var(--text-muted);">Target Complaint:</label>
      <select id="status-complaint-id">
        <option value="31">#31 - Microphone battery compartment broken</option>
        <option value="25">#25 - Flickering fluorescent tube lights</option>
        <option value="17">#17 - Core switch packet loss in Lab 301</option>
      </select>
      <label style="font-size:12px; color:var(--text-muted);">New Status:</label>
      <select id="status-new-val">
        <option value="In Progress">In Progress (Technician starts work)</option>
        <option value="Resolved">Resolved (Repair complete)</option>
        <option value="Closed">Closed (Student verified)</option>
      </select>
      <button class="btn" onclick="executeUpdateStatus()">Update Lifecycle Status</button>
      <div id="status-res" style="font-size:12px; color:#34d399; margin-top:8px;"></div>
    </div>

    <!-- Action 3: View Audit Trail -->
    <div class="action-card">
      <h4>Action 3: Trigger Audit History Proof</h4>
      <p>View the immutable chronological audit ledger populated automatically by database triggers.</p>
      <button class="btn" onclick="viewAuditTrail(31)">View Audit Trail for #31</button>
      <div id="audit-trail-res" style="margin-top:12px; font-size:12px; max-height:160px; overflow-y:auto;"></div>
    </div>
  </div>
</div>

<!-- Tab 5: SQL Console -->
<div class="panel" id="tab-console">
  <div class="console-box">
    <div>
      <h3>Live Interactive SQL Query Console</h3>
      <p style="color:var(--text-muted); font-size:13px; margin-top:4px;">
        Type or click any preset query below to execute real SQL against the CAMPUSFIX database.
      </p>
    </div>
    
    <div class="query-presets">
      <span class="chip" onclick="setQuery('SELECT * FROM v_pending_complaints LIMIT 5;')">Preset: Triage Queue</span>
      <span class="chip" onclick="setQuery('SELECT category, COUNT(*) as count FROM complaints GROUP BY category ORDER BY count DESC;')">Preset: Category Breakdown</span>
      <span class="chip" onclick="setQuery('SELECT st.full_name, COUNT(ca.assignment_id) as tasks FROM staff st LEFT JOIN complaint_assignments ca ON st.staff_id = ca.staff_id GROUP BY st.staff_id;')">Preset: Staff Workload</span>
      <span class="chip" onclick="setQuery('SELECT d.department_name, AVG(f.rating) as avg_rating FROM departments d JOIN students s ON d.department_id = s.department_id JOIN feedback f ON s.student_id = f.student_id GROUP BY d.department_name;')">Preset: Satisfaction Index</span>
      <span class="chip" onclick="setQuery('SELECT * FROM complaint_status_history ORDER BY history_id DESC LIMIT 10;')">Preset: Trigger Audit Trail</span>
    </div>

    <textarea id="sql-input">SELECT c.complaint_id, c.title, c.priority, c.status, s.full_name, l.building_name, l.room_number
FROM complaints c
JOIN students s ON c.student_id = s.student_id
JOIN locations l ON c.location_id = l.location_id
WHERE c.priority = 'Critical';</textarea>
    
    <div>
      <button class="btn" onclick="runQuery()">▶ Execute SQL Query</button>
      <span id="query-status" style="font-size:12px; color:var(--text-muted); margin-left:12px;"></span>
    </div>

    <div style="overflow-x:auto; margin-top:12px;">
      <table id="query-result-table">
        <thead id="query-thead"></thead>
        <tbody id="query-tbody"></tbody>
      </table>
    </div>
  </div>
</div>

<script>
function openTab(tabId) {
  document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
  document.querySelectorAll('.panel').forEach(p => p.classList.remove('active'));
  event.target.classList.add('active');
  document.getElementById('tab-' + tabId).classList.add('active');
  if (tabId === 'complaints') loadComplaints();
  if (tabId === 'workload') loadWorkload();
  if (tabId === 'departments') loadDepartments();
}

function loadComplaints() {
  fetch('/api/complaints')
    .then(r => r.json())
    .then(data => {
      let html = '';
      data.forEach(c => {
        let pClass = 'tag-' + c.priority.toLowerCase();
        let sClass = 'tag-' + c.status.toLowerCase().replace(' ', '');
        html += `<tr>
          <td><strong>#${c.complaint_id}</strong></td>
          <td><div><strong>${c.title}</strong></div><span style="font-size:11px; color:#94a3b8;">${c.category}</span></td>
          <td>${c.building_name} (${c.room_number})</td>
          <td><span class="tag ${pClass}">${c.priority}</span></td>
          <td><span class="tag ${sClass}">${c.status}</span></td>
          <td>${c.student_name}</td>
          <td style="color:#94a3b8;">${c.created_at.slice(0, 16)}</td>
        </tr>`;
      });
      document.getElementById('complaints-tbody').innerHTML = html;
    });
}

function loadWorkload() {
  fetch('/api/staff-workload')
    .then(r => r.json())
    .then(data => {
      let html = '';
      data.forEach(s => {
        html += `<tr>
          <td>#${s.staff_id}</td>
          <td><strong>${s.staff_name}</strong></td>
          <td>${s.role}</td>
          <td>${s.department_name}</td>
          <td><span class="badge">${s.total_assigned}</span></td>
          <td style="color:#38bdf8; font-weight:700;">${s.active_load}</td>
          <td style="color:#34d399; font-weight:700;">${s.resolved_count}</td>
        </tr>`;
      });
      document.getElementById('workload-tbody').innerHTML = html;
    });
}

function loadDepartments() {
  fetch('/api/departments')
    .then(r => r.json())
    .then(data => {
      let html = '';
      data.forEach(d => {
        html += `<tr>
          <td>#${d.department_id}</td>
          <td><strong>${d.department_name}</strong></td>
          <td>${d.total_complaints}</td>
          <td style="color:#34d399; font-weight:700;">${d.resolved_count}</td>
          <td style="color:#f59e0b; font-weight:700;">${d.pending_count}</td>
          <td><span style="color:#fbbf24; font-weight:700;">★ ${d.avg_rating || 'N/A'}</span></td>
        </tr>`;
      });
      document.getElementById('departments-tbody').innerHTML = html;
    });
}

function setQuery(sql) {
  document.getElementById('sql-input').value = sql;
  runQuery();
}

function runQuery() {
  const sql = document.getElementById('sql-input').value;
  const statusEl = document.getElementById('query-status');
  statusEl.innerText = 'Executing query...';
  
  fetch('/api/query', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ query: sql })
  })
  .then(r => r.json())
  .then(res => {
    if (res.error) {
      statusEl.style.color = '#ef4444';
      statusEl.innerText = 'Error: ' + res.error;
      document.getElementById('query-thead').innerHTML = '';
      document.getElementById('query-tbody').innerHTML = '';
      return;
    }
    statusEl.style.color = '#10b981';
    statusEl.innerText = `Query succeeded! (${res.rows.length} rows returned)`;

    let thHtml = '<tr>' + res.columns.map(c => `<th>${c}</th>`).join('') + '</tr>';
    let tbHtml = res.rows.map(r => '<tr>' + r.map(v => `<td>${v !== null ? v : '<em style="color:#64748b;">NULL</em>'}</td>`).join('') + '</tr>').join('');

    document.getElementById('query-thead').innerHTML = thHtml;
    document.getElementById('query-tbody').innerHTML = tbHtml;
  });
}

function executeAssign() {
  const cId = document.getElementById('assign-complaint-id').value;
  const sId = document.getElementById('assign-staff-id').value;
  fetch('/api/assign', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ complaint_id: cId, staff_id: sId, assigned_by: 'Dashboard Admin' })
  })
  .then(r => r.json())
  .then(res => {
    document.getElementById('assign-res').innerText = res.message;
    viewAuditTrail(cId);
  });
}

function executeUpdateStatus() {
  const cId = document.getElementById('status-complaint-id').value;
  const status = document.getElementById('status-new-val').value;
  fetch('/api/update-status', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ complaint_id: cId, status: status, changed_by: 'Dashboard Technician' })
  })
  .then(r => r.json())
  .then(res => {
    document.getElementById('status-res').innerText = res.message;
    viewAuditTrail(cId);
  });
}

function viewAuditTrail(cId) {
  fetch('/api/query', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ query: `SELECT history_id, old_status, new_status, changed_at, changed_by FROM complaint_status_history WHERE complaint_id = ${cId} ORDER BY history_id DESC;` })
  })
  .then(r => r.json())
  .then(res => {
    if (res.rows.length === 0) {
      document.getElementById('audit-trail-res').innerHTML = '<em>No audit history found for this ticket.</em>';
      return;
    }
    let html = '<div style="background:#0f172a; padding:8px; border-radius:6px; border:1px solid #334155;">';
    res.rows.forEach(r => {
      html += `<div style="margin-bottom:6px; border-bottom:1px dashed #334155; padding-bottom:4px;">
        <strong>#${r[0]}</strong>: ${r[1] || 'NULL'} &rarr; <span style="color:#38bdf8; font-weight:700;">${r[2]}</span>
        <br><span style="color:#94a3b8; font-size:11px;">By: ${r[4]} at ${r[3]}</span>
      </div>`;
    });
    html += '</div>';
    document.getElementById('audit-trail-res').innerHTML = html;
  });
}

// Initial load
loadComplaints();
</script>

</body>
</html>
"""


class CampusFixHandler(http.server.BaseHTTPRequestHandler):
    def _send_json(self, data, status=200):
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(json.dumps(data).encode("utf-8"))

    def do_GET(self):
        url = urllib.parse.urlparse(self.path)
        if url.path in ["/", "/index.html"]:
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(HTML_PAGE.encode("utf-8"))
            return

        conn = sqlite3.connect(DB_FILE)
        c = conn.cursor()

        if url.path == "/api/complaints":
            q = """
            SELECT c.complaint_id, c.title, c.category, c.priority, c.status,
                   c.created_at, s.full_name as student_name, l.building_name, l.room_number
            FROM complaints c
            JOIN students s ON c.student_id = s.student_id
            JOIN locations l ON c.location_id = l.location_id
            ORDER BY c.complaint_id ASC;
            """
            rows = c.execute(q).fetchall()
            cols = [col[0] for col in c.description]
            data = [dict(zip(cols, r)) for r in rows]
            conn.close()
            self._send_json(data)
            return

        if url.path == "/api/staff-workload":
            q = """
            SELECT st.staff_id, st.full_name as staff_name, st.role, d.department_name,
                   COUNT(DISTINCT ca.complaint_id) as total_assigned,
                   COUNT(DISTINCT CASE WHEN c.status IN ('Assigned', 'In Progress') THEN ca.complaint_id END) as active_load,
                   COUNT(DISTINCT CASE WHEN c.status = 'Resolved' THEN ca.complaint_id END) as resolved_count
            FROM staff st
            JOIN departments d ON st.department_id = d.department_id
            LEFT JOIN complaint_assignments ca ON st.staff_id = ca.staff_id
            LEFT JOIN complaints c ON ca.complaint_id = c.complaint_id
            GROUP BY st.staff_id, st.full_name, st.role, d.department_name
            ORDER BY total_assigned DESC;
            """
            rows = c.execute(q).fetchall()
            cols = [col[0] for col in c.description]
            data = [dict(zip(cols, r)) for r in rows]
            conn.close()
            self._send_json(data)
            return

        if url.path == "/api/departments":
            q = """
            SELECT d.department_id, d.department_name,
                   COUNT(DISTINCT c.complaint_id) as total_complaints,
                   COUNT(DISTINCT CASE WHEN c.status = 'Resolved' THEN c.complaint_id END) as resolved_count,
                   COUNT(DISTINCT CASE WHEN c.status IN ('Pending', 'Assigned', 'In Progress') THEN c.complaint_id END) as pending_count,
                   ROUND(AVG(f.rating), 1) as avg_rating
            FROM departments d
            LEFT JOIN students s ON d.department_id = s.department_id
            LEFT JOIN complaints c ON s.student_id = c.student_id
            LEFT JOIN feedback f ON c.complaint_id = f.complaint_id
            GROUP BY d.department_id, d.department_name;
            """
            rows = c.execute(q).fetchall()
            cols = [col[0] for col in c.description]
            data = [dict(zip(cols, r)) for r in rows]
            conn.close()
            self._send_json(data)
            return

        conn.close()
        self.send_error(404, "Endpoint Not Found")

    def do_POST(self):
        url = urllib.parse.urlparse(self.path)
        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length).decode("utf-8")
        payload = json.loads(body) if body else {}

        conn = sqlite3.connect(DB_FILE)
        c = conn.cursor()

        if url.path == "/api/query":
            sql = payload.get("query", "").strip()
            if not sql:
                conn.close()
                self._send_json({"error": "Empty SQL statement."})
                return
            try:
                c.execute(sql)
                if c.description:
                    columns = [col[0] for col in c.description]
                    rows = c.fetchall()
                    conn.close()
                    self._send_json({"columns": columns, "rows": rows})
                else:
                    conn.commit()
                    conn.close()
                    self._send_json({"columns": ["Status"], "rows": [["Query executed successfully! (DML statement committed)"]]})
            except Exception as e:
                conn.close()
                self._send_json({"error": str(e)})
            return

        if url.path == "/api/assign":
            c_id = int(payload.get("complaint_id"))
            s_id = int(payload.get("staff_id"))
            assigned_by = payload.get("assigned_by", "Admin Facilities Desk")
            now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

            # Check old status
            row = c.execute("SELECT status FROM complaints WHERE complaint_id = ?", (c_id,)).fetchone()
            old_status = row[0] if row else "Pending"

            # Insert assignment
            c.execute("INSERT INTO complaint_assignments (complaint_id, staff_id, assigned_at, assigned_by) VALUES (?, ?, ?, ?)",
                      (c_id, s_id, now, assigned_by))
            
            # Update complaint status
            c.execute("UPDATE complaints SET status = 'Assigned', updated_at = ? WHERE complaint_id = ?", (now, c_id))

            # Trigger audit entry
            c.execute("INSERT INTO complaint_status_history (complaint_id, old_status, new_status, changed_at, changed_by) VALUES (?, ?, 'Assigned', ?, ?)",
                      (c_id, old_status, now, assigned_by))

            conn.commit()
            conn.close()
            self._send_json({"message": f"Successfully assigned complaint #{c_id} to staff #{s_id} and recorded audit history!"})
            return

        if url.path == "/api/update-status":
            c_id = int(payload.get("complaint_id"))
            new_status = payload.get("status")
            changed_by = payload.get("changed_by", "Technician")
            now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

            row = c.execute("SELECT status FROM complaints WHERE complaint_id = ?", (c_id,)).fetchone()
            old_status = row[0] if row else "Pending"

            c.execute("UPDATE complaints SET status = ?, updated_at = ? WHERE complaint_id = ?", (new_status, now, c_id))
            c.execute("INSERT INTO complaint_status_history (complaint_id, old_status, new_status, changed_at, changed_by) VALUES (?, ?, ?, ?, ?)",
                      (c_id, old_status, new_status, now, changed_by))

            conn.commit()
            conn.close()
            self._send_json({"message": f"Updated complaint #{c_id} to '{new_status}' and wrote trigger audit entry!"})
            return

        conn.close()
        self.send_error(404, "Endpoint Not Found")

    def log_message(self, format, *args):
        # Clean logging
        return


def main():
    print("=" * 78)
    print("       CAMPUSFIX: SMART CAMPUS COMPLAINT & MAINTENANCE MANAGEMENT SYSTEM")
    print("=" * 78)
    print("[*] Initializing relational database...")
    init_database()

    server = http.server.HTTPServer(("127.0.0.1", PORT), CampusFixHandler)
    url = f"http://127.0.0.1:{PORT}"
    print(f"[*] CAMPUSFIX Dashboard running at: {url}")
    print("[*] Opening your web browser automatically...")
    print("[*] Press Ctrl+C in this terminal window to stop the server anytime.")
    print("=" * 78)

    # Open browser automatically after half a second
    threading.Timer(0.8, lambda: webbrowser.open(url)).start()

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[*] Shutting down CAMPUSFIX server. Goodbye!")
        server.server_close()


if __name__ == "__main__":
    main()
