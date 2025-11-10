-- Sample Seed Data for UniPortals
-- This file contains sample data for testing and development

-- Insert Sample University
INSERT INTO universities (id, code, name, short_name, type, nuc_code, established_year, city, state, country, email, phone)
VALUES 
(uuid_generate_v4(), 'UNILAG', 'University of Lagos', 'UNILAG', 'federal', 'NUC001', 1962, 'Lagos', 'Lagos', 'Nigeria', 'info@unilag.edu.ng', '+234-1-4932396');

-- Insert Sample Campus
INSERT INTO campuses (id, university_id, name, code, city, state, is_main_campus)
SELECT uuid_generate_v4(), id, 'Main Campus - Akoka', 'AKOKA', 'Lagos', 'Lagos', TRUE
FROM universities WHERE code = 'UNILAG';

-- Insert Sample Faculties
INSERT INTO faculties (id, university_id, campus_id, name, code)
SELECT 
    uuid_generate_v4(),
    u.id,
    c.id,
    faculty_data.name,
    faculty_data.code
FROM universities u
CROSS JOIN campuses c
CROSS JOIN (VALUES
    ('Faculty of Arts', 'ARTS'),
    ('Faculty of Science', 'SCI'),
    ('Faculty of Engineering', 'ENG'),
    ('Faculty of Social Sciences', 'SOCSCI'),
    ('Faculty of Law', 'LAW'),
    ('Faculty of Education', 'EDU'),
    ('Faculty of Environmental Sciences', 'ENVSCI')
) AS faculty_data(name, code)
WHERE u.code = 'UNILAG' AND c.code = 'AKOKA';

-- Insert Sample Departments
INSERT INTO departments (id, faculty_id, name, code)
SELECT 
    uuid_generate_v4(),
    f.id,
    dept_data.name,
    dept_data.code
FROM faculties f
CROSS JOIN (VALUES
    ('Computer Science', 'CSC'),
    ('Mathematics', 'MAT'),
    ('Physics', 'PHY'),
    ('Chemistry', 'CHM'),
    ('Biology', 'BIO')
) AS dept_data(name, code)
WHERE f.code = 'SCI';

-- Insert Sample Programs
INSERT INTO programs (id, university_id, department_id, code, name, degree_type, duration_years, duration_semesters, minimum_utme_score, accepts_direct_entry)
SELECT 
    uuid_generate_v4(),
    u.id,
    d.id,
    'BSC-CSC',
    'Computer Science',
    'BSc',
    4,
    8,
    200,
    TRUE
FROM universities u
CROSS JOIN departments d
WHERE u.code = 'UNILAG' AND d.code = 'CSC';

-- Insert Sample Courses
INSERT INTO courses (id, university_id, department_id, code, title, credit_units, level, semester, course_type)
SELECT 
    uuid_generate_v4(),
    u.id,
    d.id,
    course_data.code,
    course_data.title,
    course_data.credits,
    course_data.level,
    course_data.semester,
    course_data.type
FROM universities u
CROSS JOIN departments d
CROSS JOIN (VALUES
    ('CSC101', 'Introduction to Computer Science', 3, 100, 1, 'compulsory'),
    ('CSC102', 'Introduction to Problem Solving', 3, 100, 1, 'compulsory'),
    ('CSC103', 'Computer Programming I', 4, 100, 1, 'compulsory'),
    ('CSC201', 'Data Structures and Algorithms', 3, 200, 1, 'compulsory'),
    ('CSC202', 'Database Management Systems', 3, 200, 1, 'compulsory'),
    ('CSC301', 'Software Engineering', 3, 300, 1, 'compulsory'),
    ('CSC302', 'Operating Systems', 3, 300, 1, 'compulsory'),
    ('CSC401', 'Artificial Intelligence', 3, 400, 1, 'elective'),
    ('CSC402', 'Machine Learning', 3, 400, 1, 'elective')
) AS course_data(code, title, credits, level, semester, type)
WHERE u.code = 'UNILAG' AND d.code = 'CSC';

-- Insert Academic Session
INSERT INTO academic_sessions (id, university_id, name, start_date, end_date, is_current, registration_start_date, registration_end_date)
SELECT 
    uuid_generate_v4(),
    id,
    '2023/2024',
    '2023-09-01',
    '2024-08-31',
    TRUE,
    '2023-08-15',
    '2023-09-15'
FROM universities WHERE code = 'UNILAG';

-- Insert Semesters
INSERT INTO semesters (id, academic_session_id, semester_number, start_date, end_date, is_current, registration_start_date, registration_end_date)
SELECT 
    uuid_generate_v4(),
    id,
    1,
    '2023-09-01',
    '2024-01-31',
    TRUE,
    '2023-08-15',
    '2023-09-15'
FROM academic_sessions WHERE name = '2023/2024';

-- Insert Admission Cycle
INSERT INTO admission_cycles (id, university_id, academic_session_id, name, jamb_year, application_start_date, application_end_date, post_utme_date)
SELECT 
    uuid_generate_v4(),
    u.id,
    s.id,
    '2023/2024 Admission',
    2023,
    '2023-06-01',
    '2023-07-31',
    '2023-08-15'
FROM universities u
CROSS JOIN academic_sessions s
WHERE u.code = 'UNILAG' AND s.name = '2023/2024';

-- Insert Sample Fee Categories (using NULL for university_id to make them system-wide)
INSERT INTO fee_categories (id, university_id, name, code, description, is_mandatory)
VALUES
(uuid_generate_v4(), NULL, 'Tuition Fee', 'TUITION', 'Main tuition fee', TRUE),
(uuid_generate_v4(), NULL, 'Acceptance Fee', 'ACCEPTANCE', 'One-time acceptance fee for new students', TRUE),
(uuid_generate_v4(), NULL, 'Development Levy', 'DEVELOPMENT', 'University development levy', TRUE),
(uuid_generate_v4(), NULL, 'Library Fee', 'LIBRARY', 'Library services fee', TRUE),
(uuid_generate_v4(), NULL, 'Medical Fee', 'MEDICAL', 'Student health services', TRUE),
(uuid_generate_v4(), NULL, 'Sports Fee', 'SPORTS', 'Sports facilities fee', TRUE),
(uuid_generate_v4(), NULL, 'ICT Fee', 'ICT', 'Information and communication technology fee', TRUE),
(uuid_generate_v4(), NULL, 'Hostel Fee', 'HOSTEL', 'Accommodation fee', FALSE),
(uuid_generate_v4(), NULL, 'Late Registration Fee', 'LATE_REG', 'Penalty for late registration', FALSE);

-- Insert Sample Fee Structures
INSERT INTO fee_structures (id, university_id, academic_session_id, program_id, level, semester, fee_category_id, amount)
SELECT 
    uuid_generate_v4(),
    u.id,
    s.id,
    p.id,
    100,
    1,
    fc.id,
    CASE fc.code
        WHEN 'TUITION' THEN 75000.00
        WHEN 'ACCEPTANCE' THEN 50000.00
        WHEN 'DEVELOPMENT' THEN 10000.00
        WHEN 'LIBRARY' THEN 5000.00
        WHEN 'MEDICAL' THEN 3000.00
        WHEN 'SPORTS' THEN 2000.00
        WHEN 'ICT' THEN 10000.00
        WHEN 'HOSTEL' THEN 50000.00
    END
FROM universities u
CROSS JOIN academic_sessions s
CROSS JOIN programs p
CROSS JOIN fee_categories fc
WHERE u.code = 'UNILAG' 
  AND s.name = '2023/2024'
  AND p.code = 'BSC-CSC'
  AND fc.code IN ('TUITION', 'ACCEPTANCE', 'DEVELOPMENT', 'LIBRARY', 'MEDICAL', 'SPORTS', 'ICT', 'HOSTEL');

-- Insert Sample Admin User
INSERT INTO users (id, university_id, username, email, password_hash, user_type, is_active, is_verified)
SELECT 
    uuid_generate_v4(),
    id,
    'admin',
    'admin@unilag.edu.ng',
    '$2a$10$XQVZqN6K9h4h4h4h4h4h4OqN6K9h4h4h4h4h4h4OqN6K9h4h4h4h4', -- Password: Admin@123
    'admin',
    TRUE,
    TRUE
FROM universities WHERE code = 'UNILAG';

-- Insert Sample JAMB Records
INSERT INTO jamb_records (id, jamb_registration_number, candidate_name, date_of_birth, gender, state_of_origin, lga, utme_score, utme_subjects, utme_year, first_choice_institution, first_choice_course)
VALUES
(uuid_generate_v4(), '12345678AB', 'ADEWALE JOHN OLUWASEUN', '2005-03-15', 'Male', 'Lagos', 'Ikeja', 245, 
 '{"Mathematics": 62, "English": 58, "Physics": 65, "Chemistry": 60}'::jsonb, 2023, 'University of Lagos', 'Computer Science'),
(uuid_generate_v4(), '23456789CD', 'OKONKWO CHIOMA GRACE', '2004-07-22', 'Female', 'Anambra', 'Awka', 268,
 '{"Mathematics": 70, "English": 65, "Physics": 68, "Chemistry": 65}'::jsonb, 2023, 'University of Lagos', 'Computer Science'),
(uuid_generate_v4(), '34567890EF', 'BELLO MOHAMMED ABUBAKAR', '2005-01-10', 'Male', 'Kano', 'Kano Municipal', 232,
 '{"Mathematics": 60, "English": 55, "Physics": 62, "Chemistry": 55}'::jsonb, 2023, 'University of Lagos', 'Computer Science');

-- Insert Sample O'Level Results
INSERT INTO olevel_results (id, exam_type, exam_number, exam_year, sitting_number, subjects)
VALUES
(uuid_generate_v4(), 'WAEC', '1234567890', 2022, 1,
 '[
   {"subject": "Mathematics", "grade": "B3"},
   {"subject": "English Language", "grade": "C4"},
   {"subject": "Physics", "grade": "B2"},
   {"subject": "Chemistry", "grade": "C5"},
   {"subject": "Biology", "grade": "B3"},
   {"subject": "Further Mathematics", "grade": "C4"},
   {"subject": "Civic Education", "grade": "B2"},
   {"subject": "Economics", "grade": "C5"},
   {"subject": "Geography", "grade": "C6"}
 ]'::jsonb);

-- Insert Sample Hostels
INSERT INTO hostels (id, university_id, campus_id, name, hostel_type, total_rooms, total_bed_spaces)
SELECT 
    uuid_generate_v4(),
    u.id,
    c.id,
    hostel_data.name,
    hostel_data.type,
    hostel_data.rooms,
    hostel_data.spaces
FROM universities u
CROSS JOIN campuses c
CROSS JOIN (VALUES
    ('Moremi Hall', 'female', 100, 200),
    ('Eni Njoku Hall', 'male', 120, 240),
    ('Mariere Hall', 'female', 80, 160),
    ('Jaja Hall', 'male', 100, 200)
) AS hostel_data(name, type, rooms, spaces)
WHERE u.code = 'UNILAG' AND c.code = 'AKOKA';

-- Insert Sample Hostel Rooms
INSERT INTO hostel_rooms (id, hostel_id, room_number, room_type, bed_spaces)
SELECT 
    uuid_generate_v4(),
    h.id,
    'ROOM-' || LPAD(room_num::text, 3, '0'),
    'double',
    2
FROM hostels h
CROSS JOIN generate_series(1, 50) AS room_num
WHERE h.name = 'Moremi Hall';

-- Insert Sample Announcements
INSERT INTO announcements (id, university_id, title, content, announcement_type, target_audience, published, published_at)
SELECT 
    uuid_generate_v4(),
    id,
    'Welcome to 2023/2024 Academic Session',
    'We are pleased to welcome all students to the new academic session. Classes commence on Monday, September 4, 2023. Please ensure you have completed your registration and paid all necessary fees.',
    'general',
    'all',
    TRUE,
    CURRENT_TIMESTAMP
FROM universities WHERE code = 'UNILAG';

INSERT INTO announcements (id, university_id, title, content, announcement_type, target_audience, published, published_at)
SELECT 
    uuid_generate_v4(),
    id,
    'Course Registration Deadline',
    'All students are advised that course registration for first semester ends on September 15, 2023. Late registration attracts a penalty fee of ₦5,000.',
    'academic',
    'students',
    TRUE,
    CURRENT_TIMESTAMP
FROM universities WHERE code = 'UNILAG';

-- Add comments to key tables
COMMENT ON TABLE universities IS 'Stores university/institution information for multi-tenancy support';
COMMENT ON TABLE students IS 'Core student records with academic and personal information';
COMMENT ON TABLE applications IS 'Admission applications linked to JAMB records';
COMMENT ON TABLE jamb_records IS 'JAMB/UTME candidate data synchronized from JAMB portal';
COMMENT ON TABLE payments IS 'All payment transactions including fees, acceptance, hostel, etc.';
COMMENT ON TABLE courses IS 'Course catalog with all available courses';
COMMENT ON TABLE enrollments IS 'Student enrollments per semester';
COMMENT ON TABLE course_registrations IS 'Student course registrations per semester';
COMMENT ON TABLE grades IS 'Student grades for each registered course';

-- Create sample data summary view
CREATE OR REPLACE VIEW system_summary AS
SELECT 
    (SELECT COUNT(*) FROM universities) as total_universities,
    (SELECT COUNT(*) FROM students WHERE is_deleted = FALSE) as total_students,
    (SELECT COUNT(*) FROM applications) as total_applications,
    (SELECT COUNT(*) FROM staff WHERE is_deleted = FALSE) as total_staff,
    (SELECT COUNT(*) FROM courses) as total_courses,
    (SELECT COUNT(*) FROM programs) as total_programs,
    (SELECT COUNT(*) FROM payments WHERE status = 'successful') as successful_payments,
    (SELECT SUM(amount) FROM payments WHERE status = 'successful') as total_revenue;

-- Grant appropriate permissions (adjust as needed for your setup)
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO uniportals_user;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO uniportals_user;

SELECT 'Sample data inserted successfully!' as message;
SELECT * FROM system_summary;
