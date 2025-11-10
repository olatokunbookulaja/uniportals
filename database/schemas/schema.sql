-- UniPortals Database Schema
-- PostgreSQL 13+
-- 
-- This schema supports comprehensive university management with native Nigerian
-- admissions process support (JAMB/UTME, Direct Entry, Post-UTME)

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- CORE ADMINISTRATIVE TABLES
-- ============================================================================

-- Universities/Institutions (Multi-tenancy support)
CREATE TABLE universities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    short_name VARCHAR(50),
    type VARCHAR(50), -- 'federal', 'state', 'private'
    nuc_code VARCHAR(20),
    established_year INTEGER,
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100) DEFAULT 'Nigeria',
    website VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(50),
    logo_url VARCHAR(500),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Campuses
CREATE TABLE campuses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    university_id UUID REFERENCES universities(id),
    name VARCHAR(255) NOT NULL,
    code VARCHAR(20) NOT NULL,
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    is_main_campus BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(university_id, code)
);

-- Faculties/Schools
CREATE TABLE faculties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    university_id UUID REFERENCES universities(id),
    campus_id UUID REFERENCES campuses(id),
    name VARCHAR(255) NOT NULL,
    code VARCHAR(20) NOT NULL,
    dean_staff_id UUID,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(university_id, code)
);

-- Departments
CREATE TABLE departments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    faculty_id UUID REFERENCES faculties(id),
    name VARCHAR(255) NOT NULL,
    code VARCHAR(20) NOT NULL,
    hod_staff_id UUID,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- USER MANAGEMENT
-- ============================================================================

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    university_id UUID REFERENCES universities(id),
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    user_type VARCHAR(50) NOT NULL, -- 'student', 'staff', 'admin', 'applicant'
    is_active BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    last_login TIMESTAMP,
    failed_login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMP,
    mfa_enabled BOOLEAN DEFAULT FALSE,
    mfa_secret VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    permissions JSONB, -- Store permissions as JSON
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID REFERENCES roles(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    assigned_by UUID REFERENCES users(id),
    UNIQUE(user_id, role_id)
);

-- ============================================================================
-- ACADEMIC PROGRAMS AND COURSES
-- ============================================================================

CREATE TABLE programs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    university_id UUID REFERENCES universities(id),
    department_id UUID REFERENCES departments(id),
    code VARCHAR(20) NOT NULL,
    name VARCHAR(255) NOT NULL,
    degree_type VARCHAR(50), -- 'BSc', 'BA', 'BTech', 'MSc', 'PhD', etc.
    duration_years INTEGER,
    duration_semesters INTEGER,
    admission_requirements TEXT,
    utme_subjects JSONB, -- Required UTME subjects
    minimum_utme_score INTEGER,
    olevel_requirements JSONB, -- O'Level requirements
    accepts_direct_entry BOOLEAN DEFAULT FALSE,
    direct_entry_requirements TEXT,
    capacity INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(university_id, code)
);

CREATE TABLE courses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    university_id UUID REFERENCES universities(id),
    department_id UUID REFERENCES departments(id),
    code VARCHAR(20) NOT NULL,
    title VARCHAR(255) NOT NULL,
    credit_units INTEGER NOT NULL,
    level INTEGER, -- 100, 200, 300, 400, 500, etc.
    semester INTEGER, -- 1 (First/Harmattan), 2 (Second/Rain)
    course_type VARCHAR(50), -- 'compulsory', 'elective', 'general'
    prerequisite_course_ids UUID[],
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(university_id, code)
);

CREATE TABLE academic_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    university_id UUID REFERENCES universities(id),
    name VARCHAR(100) NOT NULL, -- e.g., '2023/2024'
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_current BOOLEAN DEFAULT FALSE,
    registration_start_date DATE,
    registration_end_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE semesters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    academic_session_id UUID REFERENCES academic_sessions(id),
    semester_number INTEGER, -- 1 or 2
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_current BOOLEAN DEFAULT FALSE,
    registration_start_date DATE,
    registration_end_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE course_offerings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_id UUID REFERENCES courses(id),
    semester_id UUID REFERENCES semesters(id),
    lecturer_staff_id UUID,
    venue VARCHAR(100),
    schedule JSONB, -- Days and times
    capacity INTEGER,
    enrolled_count INTEGER DEFAULT 0,
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- ADMISSIONS MODULE (JAMB/UTME Integration)
-- ============================================================================

CREATE TABLE admission_cycles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    university_id UUID REFERENCES universities(id),
    academic_session_id UUID REFERENCES academic_sessions(id),
    name VARCHAR(100) NOT NULL,
    jamb_year INTEGER NOT NULL,
    application_start_date DATE,
    application_end_date DATE,
    post_utme_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE jamb_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    jamb_registration_number VARCHAR(20) UNIQUE NOT NULL,
    candidate_name VARCHAR(255) NOT NULL,
    date_of_birth DATE,
    gender VARCHAR(10),
    state_of_origin VARCHAR(100),
    lga VARCHAR(100),
    utme_score INTEGER,
    utme_subjects JSONB, -- Subjects and scores
    utme_year INTEGER,
    first_choice_institution VARCHAR(255),
    first_choice_course VARCHAR(255),
    sync_date TIMESTAMP,
    raw_data JSONB, -- Full JAMB API response
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE olevel_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    exam_type VARCHAR(50), -- 'WAEC', 'NECO', 'NABTEB', 'GCE'
    exam_number VARCHAR(50),
    exam_year INTEGER,
    sitting_number INTEGER, -- 1 or 2
    subjects JSONB, -- Array of {subject, grade}
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE applications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    university_id UUID REFERENCES universities(id),
    admission_cycle_id UUID REFERENCES admission_cycles(id),
    jamb_record_id UUID REFERENCES jamb_records(id),
    application_number VARCHAR(50) UNIQUE NOT NULL,
    application_type VARCHAR(50), -- 'utme', 'direct_entry'
    program_id UUID REFERENCES programs(id),
    applicant_email VARCHAR(255) NOT NULL,
    applicant_phone VARCHAR(50),
    olevel_result1_id UUID REFERENCES olevel_results(id),
    olevel_result2_id UUID REFERENCES olevel_results(id),
    status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'screening_scheduled', 'screened', 'admitted', 'rejected'
    post_utme_venue VARCHAR(255),
    post_utme_date DATE,
    post_utme_time TIME,
    documents JSONB, -- Uploaded document references
    submitted_at TIMESTAMP,
    reviewed_at TIMESTAMP,
    reviewed_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE post_utme_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    application_id UUID REFERENCES applications(id),
    score DECIMAL(5,2),
    max_score DECIMAL(5,2),
    subjects_tested JSONB,
    aggregate_score DECIMAL(5,2), -- Combined UTME + Post-UTME
    status VARCHAR(50), -- 'passed', 'failed'
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE admission_lists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    university_id UUID REFERENCES universities(id),
    admission_cycle_id UUID REFERENCES admission_cycles(id),
    batch_number INTEGER,
    list_type VARCHAR(50), -- 'merit', 'catchment', 'elds', 'supplementary'
    generated_date DATE,
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMP,
    published BOOLEAN DEFAULT FALSE,
    published_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE admission_offers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admission_list_id UUID REFERENCES admission_lists(id),
    application_id UUID REFERENCES applications(id),
    program_id UUID REFERENCES programs(id),
    offer_type VARCHAR(50), -- 'provisional', 'final'
    acceptance_status VARCHAR(50), -- 'pending', 'accepted', 'rejected'
    acceptance_deadline DATE,
    accepted_at TIMESTAMP,
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- STUDENT RECORDS
-- ============================================================================

CREATE TABLE students (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    university_id UUID REFERENCES universities(id),
    application_id UUID REFERENCES applications(id),
    registration_number VARCHAR(50) UNIQUE NOT NULL,
    jamb_registration_number VARCHAR(20),
    first_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE,
    gender VARCHAR(10),
    blood_group VARCHAR(5),
    genotype VARCHAR(5),
    marital_status VARCHAR(20),
    nationality VARCHAR(100) DEFAULT 'Nigerian',
    state_of_origin VARCHAR(100),
    lga VARCHAR(100),
    hometown VARCHAR(100),
    religion VARCHAR(50),
    email VARCHAR(255),
    phone VARCHAR(50),
    alternate_phone VARCHAR(50),
    profile_photo_url VARCHAR(500),
    program_id UUID REFERENCES programs(id),
    entry_year INTEGER,
    entry_mode VARCHAR(50), -- 'utme', 'direct_entry', 'transfer'
    current_level INTEGER,
    current_semester INTEGER,
    student_status VARCHAR(50) DEFAULT 'active', -- 'active', 'suspended', 'graduated', 'withdrawn'
    graduation_date DATE,
    cgpa DECIMAL(3,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMP
);

CREATE TABLE student_contacts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID REFERENCES students(id),
    contact_type VARCHAR(50), -- 'guardian', 'next_of_kin', 'sponsor'
    full_name VARCHAR(255) NOT NULL,
    relationship VARCHAR(50),
    email VARCHAR(255),
    phone VARCHAR(50),
    address TEXT,
    occupation VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE enrollments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID REFERENCES students(id),
    academic_session_id UUID REFERENCES academic_sessions(id),
    semester_id UUID REFERENCES semesters(id),
    level INTEGER NOT NULL,
    enrollment_status VARCHAR(50) DEFAULT 'enrolled', -- 'enrolled', 'deferred', 'withdrawn'
    enrollment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE course_registrations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID REFERENCES students(id),
    course_offering_id UUID REFERENCES course_offerings(id),
    enrollment_id UUID REFERENCES enrollments(id),
    registration_status VARCHAR(50) DEFAULT 'registered', -- 'registered', 'dropped', 'withdrawn'
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE grades (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    course_registration_id UUID REFERENCES course_registrations(id),
    student_id UUID REFERENCES students(id),
    course_offering_id UUID REFERENCES course_offerings(id),
    ca_score DECIMAL(5,2), -- Continuous Assessment
    exam_score DECIMAL(5,2),
    total_score DECIMAL(5,2),
    grade VARCHAR(2), -- A, B, C, D, E, F
    grade_point DECIMAL(3,2),
    remarks TEXT,
    entered_by UUID REFERENCES users(id),
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE semester_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID REFERENCES students(id),
    semester_id UUID REFERENCES semesters(id),
    total_credit_units INTEGER,
    total_credit_points DECIMAL(6,2),
    gpa DECIMAL(3,2),
    cgpa DECIMAL(3,2),
    remarks TEXT,
    is_approved BOOLEAN DEFAULT FALSE,
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- FINANCIAL MANAGEMENT
-- ============================================================================

CREATE TABLE fee_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    university_id UUID REFERENCES universities(id),
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) NOT NULL,
    description TEXT,
    is_mandatory BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE fee_structures (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    university_id UUID REFERENCES universities(id),
    academic_session_id UUID REFERENCES academic_sessions(id),
    program_id UUID REFERENCES programs(id),
    level INTEGER,
    semester INTEGER,
    fee_category_id UUID REFERENCES fee_categories(id),
    amount DECIMAL(12,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'NGN',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_number VARCHAR(50) UNIQUE NOT NULL,
    student_id UUID REFERENCES students(id),
    academic_session_id UUID REFERENCES academic_sessions(id),
    semester_id UUID REFERENCES semesters(id),
    total_amount DECIMAL(12,2) NOT NULL,
    amount_paid DECIMAL(12,2) DEFAULT 0,
    balance DECIMAL(12,2),
    status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'partial', 'paid', 'overdue'
    due_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE invoice_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_id UUID REFERENCES invoices(id),
    fee_category_id UUID REFERENCES fee_categories(id),
    description TEXT,
    amount DECIMAL(12,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    university_id UUID REFERENCES universities(id),
    payment_reference VARCHAR(100) UNIQUE NOT NULL,
    student_id UUID REFERENCES students(id),
    invoice_id UUID REFERENCES invoices(id),
    amount DECIMAL(12,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'NGN',
    payment_method VARCHAR(50), -- 'card', 'bank_transfer', 'ussd', 'bank_deposit', 'cash'
    payment_gateway VARCHAR(50), -- 'paystack', 'flutterwave', 'remita'
    gateway_reference VARCHAR(255),
    payer_name VARCHAR(255),
    payer_email VARCHAR(255),
    payer_phone VARCHAR(50),
    status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'successful', 'failed', 'cancelled'
    payment_date TIMESTAMP,
    verified BOOLEAN DEFAULT FALSE,
    verified_by UUID REFERENCES users(id),
    verified_at TIMESTAMP,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE scholarships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    university_id UUID REFERENCES universities(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    scholarship_type VARCHAR(50), -- 'merit', 'need_based', 'sports', 'cultural'
    amount DECIMAL(12,2),
    coverage_percentage INTEGER, -- 0-100
    eligibility_criteria JSONB,
    available_slots INTEGER,
    academic_session_id UUID REFERENCES academic_sessions(id),
    application_deadline DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE scholarship_awards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    scholarship_id UUID REFERENCES scholarships(id),
    student_id UUID REFERENCES students(id),
    academic_session_id UUID REFERENCES academic_sessions(id),
    award_amount DECIMAL(12,2),
    status VARCHAR(50) DEFAULT 'active', -- 'active', 'suspended', 'revoked'
    awarded_date DATE,
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- STAFF/FACULTY MANAGEMENT
-- ============================================================================

CREATE TABLE staff (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    university_id UUID REFERENCES universities(id),
    staff_number VARCHAR(50) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE,
    gender VARCHAR(10),
    email VARCHAR(255),
    phone VARCHAR(50),
    department_id UUID REFERENCES departments(id),
    staff_type VARCHAR(50), -- 'academic', 'administrative', 'technical'
    designation VARCHAR(100),
    rank VARCHAR(100), -- 'Professor', 'Dr.', 'Lecturer I', etc.
    employment_date DATE,
    employment_status VARCHAR(50) DEFAULT 'active', -- 'active', 'on_leave', 'retired', 'terminated'
    profile_photo_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_deleted BOOLEAN DEFAULT FALSE
);

-- ============================================================================
-- COMMUNICATION AND NOTIFICATIONS
-- ============================================================================

CREATE TABLE announcements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    university_id UUID REFERENCES universities(id),
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    announcement_type VARCHAR(50), -- 'general', 'academic', 'administrative', 'urgent'
    target_audience VARCHAR(50), -- 'all', 'students', 'staff', 'applicants'
    published BOOLEAN DEFAULT FALSE,
    published_at TIMESTAMP,
    published_by UUID REFERENCES users(id),
    expiry_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    notification_type VARCHAR(50), -- 'info', 'warning', 'success', 'error'
    category VARCHAR(50), -- 'admission', 'payment', 'academic', 'general'
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP,
    action_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- INTEGRATION AND SYNC LOGS
-- ============================================================================

CREATE TABLE jamb_sync_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sync_type VARCHAR(50), -- 'full', 'incremental', 'single'
    records_synced INTEGER,
    records_failed INTEGER,
    status VARCHAR(50), -- 'success', 'partial', 'failed'
    error_details TEXT,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sms_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recipient_phone VARCHAR(50) NOT NULL,
    message TEXT NOT NULL,
    provider VARCHAR(50),
    status VARCHAR(50), -- 'sent', 'failed', 'pending'
    response_data JSONB,
    sent_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE email_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recipient_email VARCHAR(255) NOT NULL,
    subject VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    status VARCHAR(50), -- 'sent', 'failed', 'pending'
    error_message TEXT,
    sent_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    table_name VARCHAR(100),
    record_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- HOSTEL/ACCOMMODATION MANAGEMENT
-- ============================================================================

CREATE TABLE hostels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    university_id UUID REFERENCES universities(id),
    campus_id UUID REFERENCES campuses(id),
    name VARCHAR(255) NOT NULL,
    hostel_type VARCHAR(50), -- 'male', 'female', 'mixed'
    total_rooms INTEGER,
    total_bed_spaces INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE hostel_rooms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    hostel_id UUID REFERENCES hostels(id),
    room_number VARCHAR(20) NOT NULL,
    room_type VARCHAR(50), -- 'single', 'double', 'triple', 'quad'
    bed_spaces INTEGER,
    occupied_spaces INTEGER DEFAULT 0,
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE hostel_allocations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID REFERENCES students(id),
    hostel_room_id UUID REFERENCES hostel_rooms(id),
    academic_session_id UUID REFERENCES academic_sessions(id),
    allocation_date DATE,
    check_in_date TIMESTAMP,
    check_out_date TIMESTAMP,
    bed_space_number INTEGER,
    status VARCHAR(50) DEFAULT 'allocated', -- 'allocated', 'checked_in', 'checked_out', 'cancelled'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- User indexes
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_university ON users(university_id);
CREATE INDEX idx_users_type ON users(user_type);

-- Student indexes
CREATE INDEX idx_students_registration_number ON students(registration_number);
CREATE INDEX idx_students_jamb_number ON students(jamb_registration_number);
CREATE INDEX idx_students_program ON students(program_id);
CREATE INDEX idx_students_status ON students(student_status);
CREATE INDEX idx_students_university ON students(university_id);

-- Application indexes
CREATE INDEX idx_applications_number ON applications(application_number);
CREATE INDEX idx_applications_jamb ON applications(jamb_record_id);
CREATE INDEX idx_applications_cycle ON applications(admission_cycle_id);
CREATE INDEX idx_applications_status ON applications(status);
CREATE INDEX idx_applications_email ON applications(applicant_email);

-- JAMB indexes
CREATE INDEX idx_jamb_records_reg_number ON jamb_records(jamb_registration_number);
CREATE INDEX idx_jamb_records_year ON jamb_records(utme_year);

-- Payment indexes
CREATE INDEX idx_payments_student ON payments(student_id);
CREATE INDEX idx_payments_reference ON payments(payment_reference);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_date ON payments(payment_date);

-- Invoice indexes
CREATE INDEX idx_invoices_student ON invoices(student_id);
CREATE INDEX idx_invoices_number ON invoices(invoice_number);
CREATE INDEX idx_invoices_status ON invoices(status);

-- Course registration indexes
CREATE INDEX idx_course_reg_student ON course_registrations(student_id);
CREATE INDEX idx_course_reg_offering ON course_registrations(course_offering_id);

-- Enrollment indexes
CREATE INDEX idx_enrollments_student ON enrollments(student_id);
CREATE INDEX idx_enrollments_session ON enrollments(academic_session_id);

-- Notification indexes
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(is_read);
CREATE INDEX idx_notifications_created ON notifications(created_at);

-- Audit log indexes
CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_created ON audit_logs(created_at);

-- Full-text search indexes
CREATE INDEX idx_students_name ON students USING gin(to_tsvector('english', first_name || ' ' || last_name));
CREATE INDEX idx_courses_title ON courses USING gin(to_tsvector('english', title));
CREATE INDEX idx_programs_name ON programs USING gin(to_tsvector('english', name));

-- ============================================================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to all tables with updated_at column
CREATE TRIGGER update_universities_updated_at BEFORE UPDATE ON universities FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_students_updated_at BEFORE UPDATE ON students FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_applications_updated_at BEFORE UPDATE ON applications FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_programs_updated_at BEFORE UPDATE ON programs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_courses_updated_at BEFORE UPDATE ON courses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- INITIAL DATA SEEDS
-- ============================================================================

-- Insert default roles
INSERT INTO roles (name, description, permissions) VALUES
('super_admin', 'Super Administrator with full system access', '{"all": true}'::jsonb),
('admin', 'University Administrator', '{"modules": ["all"]}'::jsonb),
('admissions_officer', 'Admissions Office Staff', '{"modules": ["admissions"]}'::jsonb),
('academic_officer', 'Academic Affairs Staff', '{"modules": ["academic", "students"]}'::jsonb),
('finance_officer', 'Finance Office Staff', '{"modules": ["financial"]}'::jsonb),
('lecturer', 'Faculty Member/Lecturer', '{"modules": ["academic"], "permissions": ["grade_entry", "course_management"]}'::jsonb),
('student', 'Student User', '{"modules": ["student_portal"]}'::jsonb),
('applicant', 'Admission Applicant', '{"modules": ["admissions_portal"]}'::jsonb);

-- Insert default fee categories
INSERT INTO fee_categories (id, university_id, name, code, description, is_mandatory) VALUES
(uuid_generate_v4(), NULL, 'Tuition Fee', 'TUITION', 'Main tuition fee', TRUE),
(uuid_generate_v4(), NULL, 'Acceptance Fee', 'ACCEPTANCE', 'One-time acceptance fee for new students', TRUE),
(uuid_generate_v4(), NULL, 'Development Levy', 'DEVELOPMENT', 'University development levy', TRUE),
(uuid_generate_v4(), NULL, 'Library Fee', 'LIBRARY', 'Library services fee', TRUE),
(uuid_generate_v4(), NULL, 'Medical Fee', 'MEDICAL', 'Student health services', TRUE),
(uuid_generate_v4(), NULL, 'Sports Fee', 'SPORTS', 'Sports facilities fee', TRUE),
(uuid_generate_v4(), NULL, 'ICT Fee', 'ICT', 'Information and communication technology fee', TRUE),
(uuid_generate_v4(), NULL, 'Hostel Fee', 'HOSTEL', 'Accommodation fee', FALSE),
(uuid_generate_v4(), NULL, 'Late Registration Fee', 'LATE_REG', 'Penalty for late registration', FALSE);

COMMENT ON DATABASE CURRENT_DATABASE() IS 'UniPortals - Comprehensive University Management System with Nigerian Admissions Support';
