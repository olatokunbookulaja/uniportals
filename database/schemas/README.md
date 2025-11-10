# Database Schema Documentation

## Overview

The UniPortals database is designed to support comprehensive university management operations with a focus on Nigerian educational requirements, including JAMB/UTME integration and local financial practices.

## Database Design Principles

1. **Normalization**: Tables are normalized to 3NF to minimize redundancy
2. **Scalability**: Designed to handle multiple campuses and high transaction volumes
3. **Audit Trail**: All critical tables include created_at, updated_at, and audit fields
4. **Soft Deletes**: Important records use soft deletes (is_deleted flag)
5. **Multi-tenancy**: Support for multiple universities/campuses

## Core Schema Modules

### 1. Admissions Module
- `applications` - Main application records
- `jamb_records` - JAMB/UTME candidate data
- `post_utme_results` - Post-UTME screening results
- `admission_batches` - Admission list generations
- `direct_entry_applications` - Direct entry specific data
- `olevel_results` - O'Level examination results

### 2. Student Module
- `students` - Core student records
- `student_profiles` - Extended student information
- `enrollments` - Semester/session enrollments
- `registrations` - Course registrations
- `hostel_allocations` - Hostel/accommodation records

### 3. Academic Module
- `programs` - Academic programs/courses of study
- `courses` - Course catalog
- `course_offerings` - Course instances per semester
- `grades` - Student grades and assessments
- `results` - Compiled semester results
- `transcripts` - Official transcript records
- `timetables` - Class scheduling

### 4. Financial Module
- `fee_structures` - Fee definitions per program/level
- `payments` - Payment transactions
- `invoices` - Student bills/invoices
- `scholarships` - Scholarship awards
- `payment_plans` - Installment payment plans
- `revenue_reports` - Financial summaries

### 5. Administrative Module
- `users` - System users (students, staff, admin)
- `roles` - User roles and permissions
- `departments` - Academic departments
- `faculties` - Faculty/school divisions
- `staff` - Staff/faculty records
- `announcements` - System announcements
- `notifications` - User notifications

### 6. Integration Module
- `jamb_sync_logs` - JAMB API sync logs
- `payment_transactions` - Payment gateway transactions
- `sms_logs` - SMS notification logs
- `email_logs` - Email notification logs
- `api_keys` - External API credentials

## Entity Relationships

### Key Relationships

1. **Student Lifecycle**
   ```
   applications → students → enrollments → registrations → grades → results
   ```

2. **Academic Structure**
   ```
   faculties → departments → programs → courses → course_offerings
   ```

3. **Financial Flow**
   ```
   fee_structures → invoices → payments → revenue_reports
   ```

4. **JAMB Integration**
   ```
   jamb_records → applications → post_utme_results → admission_batches → students
   ```

## Data Types and Conventions

### Naming Conventions
- Table names: lowercase, plural (e.g., `students`, `courses`)
- Foreign keys: `{table}_id` (e.g., `student_id`, `program_id`)
- Timestamps: `created_at`, `updated_at`, `deleted_at`
- Boolean flags: `is_{property}` (e.g., `is_active`, `is_deleted`)

### Common Fields
All tables include:
- `id` (UUID or BIGINT primary key)
- `created_at` (timestamp)
- `updated_at` (timestamp)
- `created_by` (user reference)
- `updated_by` (user reference)

Critical tables also include:
- `is_deleted` (boolean for soft delete)
- `deleted_at` (timestamp)
- `deleted_by` (user reference)

## Indexing Strategy

### Primary Indexes
- Primary keys on all tables
- Unique constraints on natural keys (e.g., registration number, JAMB number)

### Performance Indexes
- Foreign key indexes for join optimization
- Composite indexes on frequently queried combinations
- Indexes on status and date fields for filtering

### Full-Text Indexes
- Student names and profiles
- Course names and descriptions
- Announcement and notification content

## Security Considerations

### Data Encryption
- Sensitive personal data encrypted at rest
- Password hashing using bcrypt/Argon2
- Payment information encryption

### Access Control
- Row-level security for multi-tenancy
- Role-based access control (RBAC)
- Audit logging on all modifications

### Compliance
- GDPR compliance with data retention policies
- Nigerian Data Protection Regulation (NDPR) compliance
- FERPA compliance for academic records

## Backup and Recovery

### Backup Strategy
- Daily full backups
- Transaction log backups every 15 minutes
- Retention: 30 days for dailies, 1 year for monthlies

### Recovery Procedures
- Point-in-time recovery capability
- Disaster recovery plan with 4-hour RPO
- Regular backup restoration testing

## Performance Optimization

### Partitioning
- Academic records partitioned by academic year
- Payment transactions partitioned by month
- Application records partitioned by admission cycle

### Caching Strategy
- Redis caching for frequently accessed reference data
- Application-level caching for computed values
- Cache invalidation on data updates

### Query Optimization
- Materialized views for complex reports
- Stored procedures for complex operations
- Database connection pooling

## Migration Strategy

### Version Control
- All schema changes tracked in version control
- Sequential migration scripts with rollback capability
- Migration testing in staging environment

### Deployment Process
1. Backup current database
2. Apply migrations in transaction
3. Verify data integrity
4. Update application code
5. Monitor for issues

## Future Enhancements

### Planned Additions
- Alumni management schema
- Research and publications tracking
- Library management integration
- E-learning content management
- Advanced analytics data warehouse

### Scalability Improvements
- Sharding strategy for very large datasets
- Read replicas for reporting workload
- Time-series database for analytics
