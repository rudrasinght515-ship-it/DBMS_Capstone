-- =============================================================================
-- CAMPUSFIX: Smart Campus Complaint & Maintenance Management System
-- Script: 04_sample_data.sql
-- Description: Inserts realistic seed data across all 8 tables in dependency-safe order.
-- Target RDBMS: MySQL 8.0+
-- Execution Order: 04
-- =============================================================================

USE campusfix;

-- Disable autocommit temporarily for transactional bulk load consistency
SET autocommit = 0;

-- -----------------------------------------------------------------------------
-- 1. Departments (5 records)
-- -----------------------------------------------------------------------------
INSERT INTO departments (department_id, department_name, description) VALUES
(1, 'Computer Science', 'Department of Computer Science & Engineering, handles computing infrastructure, software, and networking labs.'),
(2, 'Mechanical Engineering', 'Department of Mechanical Engineering, covers fabrication labs, workshops, central ventilation, and HVAC systems.'),
(3, 'Electrical Engineering', 'Department of Electrical & Electronics Engineering, oversees power systems, substations, and high-voltage laboratories.'),
(4, 'Civil Engineering', 'Department of Civil Engineering, oversees campus structural maintenance, environmental labs, and plumbing systems.'),
(5, 'Administration', 'Central Campus Administration & Facilities Management, covers general estate, hostels, and administrative offices.');

-- -----------------------------------------------------------------------------
-- 2. Locations (12 records)
-- -----------------------------------------------------------------------------
INSERT INTO locations (location_id, building_name, room_number, location_type) VALUES
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
(12, 'Campus Auditorium',           'AUD-MainHall',     'Auditorium');

-- -----------------------------------------------------------------------------
-- 3. Students (20 records)
-- -----------------------------------------------------------------------------
INSERT INTO students (student_id, full_name, email, phone, department_id, enrollment_date) VALUES
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
(20, 'Kavya Pillai',     'kavya.pillai@campus.edu',     '9876543229', 2, '2024-08-01');

-- -----------------------------------------------------------------------------
-- 4. Staff (10 records)
-- -----------------------------------------------------------------------------
INSERT INTO staff (staff_id, full_name, email, phone, department_id, role) VALUES
(1,  'Rajesh Kumar',   'rajesh.kumar@staff.campus.edu',   '9123456701', 1, 'Network Engineer'),
(2,  'Suresh Babu',    'suresh.babu@staff.campus.edu',    '9123456702', 1, 'Systems Administrator'),
(3,  'Mahesh Shinde',  'mahesh.shinde@staff.campus.edu',  '9123456703', 2, 'HVAC Technician'),
(4,  'Ramesh Patil',   'ramesh.patil@staff.campus.edu',   '9123456704', 2, 'Mechanical Workshop Supervisor'),
(5,  'Dinesh Sharma',  'dinesh.sharma@staff.campus.edu',  '9123456705', 3, 'Senior Electrician'),
(6,  'Ganesh Gupta',   'ganesh.gupta@staff.campus.edu',   '9123456706', 3, 'Electrical Maintenance Technician'),
(7,  'Sunil Yadav',    'sunil.yadav@staff.campus.edu',    '9123456707', 4, 'Lead Plumber'),
(8,  'Anil Chauhan',   'anil.chauhan@staff.campus.edu',   '9123456708', 4, 'Civil Works Contractor'),
(9,  'Santosh Jadhav', 'santosh.jadhav@staff.campus.edu', '9123456709', 5, 'General Facilities Manager'),
(10, 'Vinod Tiwari',   'vinod.tiwari@staff.campus.edu',   '9123456710', 5, 'Sanitation & Housekeeping Lead');

-- -----------------------------------------------------------------------------
-- 5. Complaints (35 records)
-- Statuses: Resolved (1-16), In Progress (17-24), Assigned (25-30), Pending (31-33), Rejected (34-35)
-- Categories: Electrical, Plumbing, Furniture, Internet, Laboratory Equipment, Classroom Equipment, Cleaning, Other
-- Priorities: Low, Medium, High, Critical
-- -----------------------------------------------------------------------------
INSERT INTO complaints (complaint_id, student_id, location_id, title, description, category, priority, status, created_at, updated_at) VALUES
-- Resolved Complaints (1 to 16)
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

-- In Progress Complaints (17 to 24)
(17, 17, 3,  'Core switch packet loss in Lab 301',      'Intermittent ping spikes and 20% packet drop across whole computing cluster bench A.',               'Internet',            'Critical', 'In Progress', '2026-10-25 08:30:00', '2026-10-26 10:00:00'),
(18, 18, 5,  'Hydraulic oil leak on press machine 1',   'Slow drip from primary hydraulic cylinder pressure hose onto safety catchment tray.',               'Laboratory Equipment','High',     'In Progress', '2026-10-25 10:15:00', '2026-10-26 11:30:00'),
(19, 19, 12, 'Stage motorized curtain track stuck',     'Left stage wing traveler rope frayed and jammed midway through opening sequence.',                   'Other',               'Medium',   'In Progress', '2026-10-26 09:45:00', '2026-10-26 14:15:00'),
(20, 20, 9,  'Corridor lighting failure in Hostel A',   'Four fluorescent light fixtures along 1st floor west wing corridor are dead.',                      'Electrical',          'Medium',   'In Progress', '2026-10-26 14:00:00', '2026-10-27 09:20:00'),
(21, 1,  4,  'Server rack cooling fan failure',         'Cabinet exhaust fan 2 on lab server enclosure is rattling and throwing overheat warning.',          'Laboratory Equipment','High',     'In Progress', '2026-10-27 11:20:00', '2026-10-27 15:40:00'),
(22, 2,  11, 'Main water supply line valve dripping',   'Isolation gate valve on exterior admin riser pipe has worn packing gland.',                          'Plumbing',            'Medium',   'In Progress', '2026-10-27 13:10:00', '2026-10-28 09:00:00'),
(23, 3,  2,  'Classroom window latch broken',           'Second window from front in LH-204 cannot be secured, rattling violently in wind.',                  'Furniture',           'Low',      'In Progress', '2026-10-28 10:30:00', '2026-10-28 14:00:00'),
(24, 4,  7,  'Spilled beverage on library study desk',  'Sticky drink residue left across tables 12 and 13 in central reading room needing sanitization.',     'Cleaning',            'Low',      'In Progress', '2026-10-28 11:00:00', '2026-10-28 13:45:00'),

-- Assigned Complaints (25 to 30)
(25, 5,  1,  'Flickering fluorescent tube lights',      'Front row lights above chalkboard flicker constantly causing severe glare and eyestrain.',           'Electrical',          'Medium',   'Assigned',    '2026-11-01 09:10:00', '2026-11-01 11:30:00'),
(26, 6,  6,  'Oscilloscope calibration certificate overdue','Tektronix DSO bench 4 displaying inaccurate frequency readings during harmonic lab.',           'Laboratory Equipment','Medium',   'Assigned',    '2026-11-01 10:45:00', '2026-11-01 14:15:00'),
(27, 7,  10, 'Window mesh torn in hostel room 208',     'Mosquito screen mesh on west-facing window is ripped along bottom frame.',                           'Furniture',           'Low',      'Assigned',    '2026-11-02 08:30:00', '2026-11-02 10:00:00'),
(28, 8,  8,  'Barcode scanner not registering books',   'USB handheld scanner at library circulation kiosk 2 fails to read standard ISBN labels.',            'Classroom Equipment', 'Low',      'Assigned',    '2026-11-02 11:15:00', '2026-11-02 13:30:00'),
(29, 9,  3,  'Dust accumulation in workstation vents',  'System towers in rows C and D have clogged intake filters causing fan throttling.',                  'Cleaning',            'Low',      'Assigned',    '2026-11-03 09:00:00', '2026-11-03 12:00:00'),
(30, 10, 5,  'Air compressor pressure relief valve leak','Pneumatics supply tank leaking pressurized air continuously through relief valve.',                 'Laboratory Equipment','High',     'Assigned',    '2026-11-03 14:20:00', '2026-11-03 16:00:00'),

-- Pending Complaints (31 to 33)
(31, 11, 2,  'Microphone battery compartment broken',   'Lectern clip mic battery door latch snapped off; held together temporarily with tape.',              'Classroom Equipment', 'Low',      'Pending',     '2026-11-05 08:45:00', '2026-11-05 08:45:00'),
(32, 12, 11, 'Water cooler dispensing tepid water',     'Admin corridor drinking fountain compressor not activating; water is room temperature.',             'Plumbing',            'Medium',   'Pending',     '2026-11-05 10:30:00', '2026-11-05 10:30:00'),
(33, 13, 7,  'Loose carpet tile causing tripping hazard','Carpet border edge near central library staircase entrance has lifted up.',                        'Other',               'Medium',   'Pending',     '2026-11-05 12:00:00', '2026-11-05 12:00:00'),

-- Rejected Complaints (34 to 35)
(34, 14, 1,  'Requesting personal laptop charger',      'Lost my laptop charger during lecture; requesting department maintenance to provide a replacement.', 'Other',               'Low',      'Rejected',    '2026-10-18 10:00:00', '2026-10-18 11:30:00'),
(35, 15, 9,  'Requesting private gaming router install','Want unauthorized personal high-speed fiber connection wired directly into hostel room.',            'Internet',            'Low',      'Rejected',    '2026-10-19 14:15:00', '2026-10-19 15:45:00');

-- -----------------------------------------------------------------------------
-- 6. Complaint Assignments (35 records)
-- Assigned to technicians across complaints 1 to 30.
-- Includes primary assignments and re-assignment / collaborative escalations.
-- -----------------------------------------------------------------------------
INSERT INTO complaint_assignments (assignment_id, complaint_id, staff_id, assigned_at, assigned_by) VALUES
-- Resolved complaints (1 to 16) primary assignments
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

-- Secondary re-assignments / collaborative escalations on resolved tickets
(17, 1,  1,  '2026-10-01 14:00:00', 'IT Support Desk'),      -- Video engineer joined network specialist
(18, 3,  3,  '2026-10-03 14:00:00', 'Workshop Incharge'),    -- HVAC/electrical safety cross-check
(19, 5,  8,  '2026-10-06 09:00:00', 'Estate Officer'),       -- Civil carpenter called for welding support
(20, 12, 5,  '2026-10-12 14:30:00', 'Estate Officer'),       -- Electrician called to inspect AC compressor feed
(21, 13, 6,  '2026-10-13 15:30:00', 'Lab Superintendent'),   -- Assistant technician assigned for conduit pull

-- In Progress complaints (17 to 24) primary assignments
(22, 17, 1,  '2026-10-25 09:00:00', 'IT Support Desk'),
(23, 18, 4,  '2026-10-25 10:45:00', 'Workshop Incharge'),
(24, 19, 9,  '2026-10-26 10:15:00', 'Events Coordinator'),
(25, 20, 6,  '2026-10-26 14:30:00', 'Hostel Warden'),
(26, 21, 2,  '2026-10-27 12:00:00', 'IT Support Desk'),
(27, 22, 7,  '2026-10-27 13:45:00', 'Estate Officer'),
(28, 23, 8,  '2026-10-28 11:00:00', 'Estate Officer'),
(29, 24, 10, '2026-10-28 11:30:00', 'Chief Librarian'),

-- Secondary collaborative escalations on active in-progress tickets
(30, 17, 2,  '2026-10-25 11:30:00', 'IT Support Desk'),      -- Systems admin joined network engineer
(31, 18, 3,  '2026-10-25 13:00:00', 'Workshop Incharge'),    -- Pneumatic tech joined for pressure test

-- Assigned complaints (25 to 30) primary assignments
(32, 25, 6,  '2026-11-01 11:30:00', 'Estate Officer'),
(33, 26, 5,  '2026-11-01 14:15:00', 'Lab Superintendent'),
(34, 27, 8,  '2026-11-02 10:00:00', 'Hostel Warden'),
(35, 28, 2,  '2026-11-02 13:30:00', 'Chief Librarian');

-- -----------------------------------------------------------------------------
-- 7. Complaint Status History (76 records)
-- Complete lifecycle audit trails for all 35 complaints.
-- -----------------------------------------------------------------------------
INSERT INTO complaint_status_history (history_id, complaint_id, old_status, new_status, changed_at, changed_by) VALUES
-- Complaint 1 (Resolved)
(1,  1,  NULL,          'Pending',     '2026-10-01 09:15:00', 'Student Portal (Aarav Sharma)'),
(2,  1,  'Pending',     'Assigned',    '2026-10-01 10:00:00', 'Admin Facilities Desk'),
(3,  1,  'Assigned',    'In Progress', '2026-10-01 11:00:00', 'Technician Suresh Babu'),
(4,  1,  'In Progress', 'Resolved',    '2026-10-02 14:30:00', 'Technician Suresh Babu'),

-- Complaint 2 (Resolved)
(5,  2,  NULL,          'Pending',     '2026-10-02 10:00:00', 'Student Portal (Priya Patel)'),
(6,  2,  'Pending',     'Assigned',    '2026-10-02 10:30:00', 'Admin Facilities Desk'),
(7,  2,  'Assigned',    'In Progress', '2026-10-02 11:15:00', 'Technician Rajesh Kumar'),
(8,  2,  'In Progress', 'Resolved',    '2026-10-02 18:20:00', 'Technician Rajesh Kumar'),

-- Complaint 3 (Resolved)
(9,  3,  NULL,          'Pending',     '2026-10-03 11:30:00', 'Student Portal (Rohan Verma)'),
(10, 3,  'Pending',     'Assigned',    '2026-10-03 12:00:00', 'Workshop Incharge'),
(11, 3,  'Assigned',    'In Progress', '2026-10-03 13:00:00', 'Technician Ramesh Patil'),
(12, 3,  'In Progress', 'Resolved',    '2026-10-04 16:45:00', 'Technician Ramesh Patil'),

-- Complaint 4 (Resolved)
(13, 4,  NULL,          'Pending',     '2026-10-04 08:20:00', 'Student Portal (Ananya Iyer)'),
(14, 4,  'Pending',     'Assigned',    '2026-10-04 09:00:00', 'Estate Officer'),
(15, 4,  'Assigned',    'In Progress', '2026-10-04 09:45:00', 'Lead Plumber Sunil Yadav'),
(16, 4,  'In Progress', 'Resolved',    '2026-10-04 15:10:00', 'Lead Plumber Sunil Yadav'),

-- Complaint 5 (Resolved)
(17, 5,  NULL,          'Pending',     '2026-10-05 13:40:00', 'Student Portal (Vikram Malhotra)'),
(18, 5,  'Pending',     'Assigned',    '2026-10-05 14:30:00', 'Estate Officer'),
(19, 5,  'Assigned',    'In Progress', '2026-10-06 09:30:00', 'Technician Santosh Jadhav'),
(20, 5,  'In Progress', 'Resolved',    '2026-10-07 11:00:00', 'Civil Works Anil Chauhan'),

-- Complaint 6 (Resolved)
(21, 6,  NULL,          'Pending',     '2026-10-06 14:05:00', 'Student Portal (Sneha Kulkarni)'),
(22, 6,  'Pending',     'Assigned',    '2026-10-06 14:30:00', 'Lab Superintendent'),
(23, 6,  'Assigned',    'In Progress', '2026-10-06 15:30:00', 'Senior Electrician Dinesh Sharma'),
(24, 6,  'In Progress', 'Resolved',    '2026-10-07 17:30:00', 'Senior Electrician Dinesh Sharma'),

-- Complaint 7 (Resolved)
(25, 7,  NULL,          'Pending',     '2026-10-07 09:50:00', 'Student Portal (Karan Singh)'),
(26, 7,  'Pending',     'Assigned',    '2026-10-07 10:30:00', 'IT Support Desk'),
(27, 7,  'Assigned',    'In Progress', '2026-10-07 11:15:00', 'Technician Suresh Babu'),
(28, 7,  'In Progress', 'Resolved',    '2026-10-08 16:15:00', 'Technician Suresh Babu'),

-- Complaint 8 (Resolved)
(29, 8,  NULL,          'Pending',     '2026-10-08 15:10:00', 'Student Portal (Diya Mukherjee)'),
(30, 8,  'Pending',     'Assigned',    '2026-10-08 16:00:00', 'Hostel Warden'),
(31, 8,  'Assigned',    'In Progress', '2026-10-09 10:00:00', 'Technician Ganesh Gupta'),
(32, 8,  'In Progress', 'Resolved',    '2026-10-10 12:00:00', 'Technician Ganesh Gupta'),

-- Complaint 9 (Resolved)
(33, 9,  NULL,          'Pending',     '2026-10-09 07:45:00', 'Student Portal (Aditya Joshi)'),
(34, 9,  'Pending',     'Assigned',    '2026-10-09 08:30:00', 'Hostel Warden'),
(35, 9,  'Assigned',    'In Progress', '2026-10-09 09:15:00', 'Lead Plumber Sunil Yadav'),
(36, 9,  'In Progress', 'Resolved',    '2026-10-09 16:50:00', 'Lead Plumber Sunil Yadav'),

-- Complaint 10 (Resolved)
(37, 10, NULL,          'Pending',     '2026-10-10 11:20:00', 'Student Portal (Ishita Rao)'),
(38, 10, 'Pending',     'Assigned',    '2026-10-10 12:00:00', 'Events Coordinator'),
(39, 10, 'Assigned',    'In Progress', '2026-10-10 14:00:00', 'Technician Rajesh Kumar'),
(40, 10, 'In Progress', 'Resolved',    '2026-10-11 15:40:00', 'Technician Rajesh Kumar'),

-- Complaint 11 (Resolved)
(41, 11, NULL,          'Pending',     '2026-10-11 16:30:00', 'Student Portal (Manish Nair)'),
(42, 11, 'Pending',     'Assigned',    '2026-10-11 17:00:00', 'Chief Librarian'),
(43, 11, 'Assigned',    'In Progress', '2026-10-12 09:15:00', 'Technician Rajesh Kumar'),
(44, 11, 'In Progress', 'Resolved',    '2026-10-13 10:20:00', 'Technician Rajesh Kumar'),

-- Complaint 12 (Resolved)
(45, 12, NULL,          'Pending',     '2026-10-12 10:15:00', 'Student Portal (Pooja Hegde)'),
(46, 12, 'Pending',     'Assigned',    '2026-10-12 11:00:00', 'Estate Officer'),
(47, 12, 'Assigned',    'In Progress', '2026-10-12 13:30:00', 'Technician Mahesh Shinde'),
(48, 12, 'In Progress', 'Resolved',    '2026-10-14 14:10:00', 'Technician Mahesh Shinde'),

-- Complaint 13 (Resolved)
(49, 13, NULL,          'Pending',     '2026-10-13 14:40:00', 'Student Portal (Siddharth Sen)'),
(50, 13, 'Pending',     'Assigned',    '2026-10-13 15:00:00', 'Lab Superintendent'),
(51, 13, 'Assigned',    'In Progress', '2026-10-13 15:30:00', 'Senior Electrician Dinesh Sharma'),
(52, 13, 'In Progress', 'Resolved',    '2026-10-14 11:30:00', 'Senior Electrician Dinesh Sharma'),

-- Complaint 14 (Resolved)
(53, 14, NULL,          'Pending',     '2026-10-14 09:00:00', 'Student Portal (Neha Choudhury)'),
(54, 14, 'Pending',     'Assigned',    '2026-10-14 09:30:00', 'IT Support Desk'),
(55, 14, 'Assigned',    'In Progress', '2026-10-14 11:00:00', 'Technician Suresh Babu'),
(56, 14, 'In Progress', 'Resolved',    '2026-10-15 13:25:00', 'Technician Suresh Babu'),

-- Complaint 15 (Resolved)
(57, 15, NULL,          'Pending',     '2026-10-15 12:10:00', 'Student Portal (Rahul Desai)'),
(58, 15, 'Pending',     'Assigned',    '2026-10-15 13:00:00', 'Estate Officer'),
(59, 15, 'Assigned',    'In Progress', '2026-10-15 14:30:00', 'Technician Ganesh Gupta'),
(60, 15, 'In Progress', 'Resolved',    '2026-10-16 17:00:00', 'Technician Ganesh Gupta'),

-- Complaint 16 (Resolved)
(61, 16, NULL,          'Pending',     '2026-10-16 11:00:00', 'Student Portal (Tanvi Bhat)'),
(62, 16, 'Pending',     'Assigned',    '2026-10-16 11:30:00', 'Estate Officer'),
(63, 16, 'Assigned',    'In Progress', '2026-10-16 14:00:00', 'Technician Santosh Jadhav'),
(64, 16, 'In Progress', 'Resolved',    '2026-10-17 15:15:00', 'Technician Santosh Jadhav'),

-- In Progress Complaints (17 to 24)
(65, 17, NULL,          'Pending',     '2026-10-25 08:30:00', 'Student Portal (Harsh Vardhan)'),
(66, 17, 'Pending',     'Assigned',    '2026-10-25 09:00:00', 'IT Support Desk'),
(67, 17, 'Assigned',    'In Progress', '2026-10-25 10:15:00', 'Technician Rajesh Kumar'),

(68, 18, NULL,          'Pending',     '2026-10-25 10:15:00', 'Student Portal (Meera Nambiar)'),
(69, 18, 'Pending',     'Assigned',    '2026-10-25 10:45:00', 'Workshop Incharge'),
(70, 18, 'Assigned',    'In Progress', '2026-10-25 12:30:00', 'Technician Ramesh Patil'),

-- Assigned Complaints (25, 26)
(71, 25, NULL,          'Pending',     '2026-11-01 09:10:00', 'Student Portal (Vikram Malhotra)'),
(72, 25, 'Pending',     'Assigned',    '2026-11-01 11:30:00', 'Estate Officer'),

(73, 26, NULL,          'Pending',     '2026-11-01 10:45:00', 'Student Portal (Sneha Kulkarni)'),
(74, 26, 'Pending',     'Assigned',    '2026-11-01 14:15:00', 'Lab Superintendent'),

-- Rejected Complaints (34, 35)
(75, 34, NULL,          'Pending',     '2026-10-18 10:00:00', 'Student Portal (Neha Choudhury)'),
(76, 34, 'Pending',     'Rejected',    '2026-10-18 11:30:00', 'Admin Facilities Desk');

-- -----------------------------------------------------------------------------
-- 8. Feedback (15 records)
-- Enforces:
--   - Valid complaint_id (1-15, all Resolved)
--   - UNIQUE(complaint_id): exactly 1 review per complaint
--   - Consistent student_id matching complaints.student_id
--   - Rating between 1 and 5
-- -----------------------------------------------------------------------------
INSERT INTO feedback (feedback_id, complaint_id, student_id, rating, comments, submitted_at) VALUES
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
(15, 15, 15, 3, 'Exhaust fan replaced, but took several days to source the correct replacement model.',   '2026-10-17 10:00:00');

-- Commit all inserted records cleanly
COMMIT;

-- Restore standard autocommit
SET autocommit = 1;

-- Confirmation output
SELECT 'departments' AS table_name, COUNT(*) AS total_records FROM departments
UNION ALL
SELECT 'locations', COUNT(*) FROM locations
UNION ALL
SELECT 'students', COUNT(*) FROM students
UNION ALL
SELECT 'staff', COUNT(*) FROM staff
UNION ALL
SELECT 'complaints', COUNT(*) FROM complaints
UNION ALL
SELECT 'complaint_assignments', COUNT(*) FROM complaint_assignments
UNION ALL
SELECT 'complaint_status_history', COUNT(*) FROM complaint_status_history
UNION ALL
SELECT 'feedback', COUNT(*) FROM feedback;
