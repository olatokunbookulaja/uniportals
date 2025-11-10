# UniPortals API Documentation

## Overview

Welcome to the UniPortals API documentation. This API provides comprehensive access to university management operations including admissions, student management, academic operations, financial transactions, and administrative functions.

## API Version

Current Version: **v1**

Base URL: `https://api.uniportals.ng/v1`

## Quick Start

### 1. Authentication

All API requests require authentication using JWT tokens. Obtain a token by calling the login endpoint:

```bash
curl -X POST https://api.uniportals.ng/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "your_username",
    "password": "your_password"
  }'
```

Response:
```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
    "expires_in": 86400,
    "user": {
      "id": "uuid",
      "username": "john_doe",
      "email": "john@example.com",
      "user_type": "student"
    }
  }
}
```

### 2. Making Authenticated Requests

Include the JWT token in the Authorization header:

```bash
curl -X GET https://api.uniportals.ng/v1/students/profile \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIs..."
```

### 3. Rate Limits

- Anonymous: 20 requests/minute
- Authenticated: 100 requests/minute
- Admin: 500 requests/minute

## API Modules

### 1. [Admissions API](./admissions-api.md)

Complete admissions workflow management:
- Application submission and tracking
- JAMB/UTME integration
- Post-UTME screening management
- Admission list generation
- Direct Entry applications
- Admission status checking

**Key Endpoints:**
- `POST /admissions/applications` - Create new application
- `GET /admissions/applications/:id` - Get application details
- `GET /admissions/check-status` - Check admission status
- `POST /admissions/jamb/fetch` - Fetch JAMB candidate data
- `POST /admissions/post-utme/schedule` - Schedule Post-UTME
- `POST /admissions/admission-lists/generate` - Generate admission list

### 2. Student Management API

Student lifecycle and academic records:
- Student profile management
- Course registration
- Enrollment tracking
- Hostel allocation
- Academic records access
- Document management

**Key Endpoints:**
- `GET /students/profile` - Get student profile
- `PUT /students/profile` - Update profile
- `POST /students/registration/courses` - Register for courses
- `GET /students/results` - View academic results
- `GET /students/transcript` - Generate transcript
- `POST /students/hostel/apply` - Apply for hostel accommodation

### 3. Academic Management API

Course and grade management:
- Course catalog and offerings
- Grade entry and approval
- Result computation
- Timetable management
- Exam scheduling
- Academic calendar

**Key Endpoints:**
- `GET /academic/courses` - List available courses
- `GET /academic/courses/:id/offerings` - Get course offerings
- `POST /academic/grades` - Enter student grades
- `GET /academic/results/:student_id` - Get student results
- `POST /academic/timetables/generate` - Generate timetables
- `GET /academic/calendar` - Get academic calendar

### 4. Financial Management API

Fee and payment processing:
- Fee structure management
- Invoice generation
- Payment processing
- Scholarship management
- Revenue reporting
- Payment verification

**Key Endpoints:**
- `GET /financial/invoices` - List student invoices
- `POST /financial/payments/initiate` - Initiate payment
- `GET /financial/payments/:reference/verify` - Verify payment
- `GET /financial/scholarships` - List available scholarships
- `POST /financial/scholarships/apply` - Apply for scholarship
- `GET /financial/reports/revenue` - Revenue reports (admin)

### 5. Administrative API

System administration and configuration:
- User management
- Role and permission management
- Department/Faculty management
- System configuration
- Audit logs
- Announcements and notifications

**Key Endpoints:**
- `POST /admin/users` - Create user
- `GET /admin/users` - List users
- `PUT /admin/users/:id/roles` - Update user roles
- `POST /admin/departments` - Create department
- `POST /admin/announcements` - Create announcement
- `GET /admin/audit-logs` - View audit logs

### 6. Integration API

External system integrations:
- JAMB synchronization
- Payment gateway webhooks
- SMS/Email notifications
- Document verification
- Third-party integrations

**Key Endpoints:**
- `POST /integrations/jamb/sync` - Sync JAMB data
- `POST /integrations/payments/webhook` - Payment webhook
- `POST /integrations/notifications/sms` - Send SMS
- `POST /integrations/notifications/email` - Send email

## Common Response Formats

### Success Response

```json
{
  "success": true,
  "data": {
    // Response data
  },
  "message": "Operation completed successfully",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### Error Response

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format"
      }
    ]
  },
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### Paginated Response

```json
{
  "success": true,
  "data": {
    "items": [
      // Array of items
    ],
    "pagination": {
      "total": 1000,
      "page": 1,
      "limit": 50,
      "total_pages": 20,
      "has_next": true,
      "has_prev": false
    }
  }
}
```

## Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `VALIDATION_ERROR` | 400 | Invalid input data |
| `UNAUTHORIZED` | 401 | Authentication required |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `DUPLICATE_ENTRY` | 409 | Resource already exists |
| `UNPROCESSABLE_ENTITY` | 422 | Validation failed |
| `RATE_LIMIT_EXCEEDED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Server error |
| `SERVICE_UNAVAILABLE` | 503 | Service temporarily unavailable |

## Data Types

### Date/Time Format

All dates and times use ISO 8601 format:
- Date: `2024-01-15`
- DateTime: `2024-01-15T10:30:00Z`
- Time: `10:30:00`

### Currency

All monetary values are in Nigerian Naira (NGN) with 2 decimal places:
```json
{
  "amount": 50000.00,
  "currency": "NGN"
}
```

### UUID

All resource IDs use UUID v4 format:
```
"id": "550e8400-e29b-41d4-a716-446655440000"
```

## Query Parameters

### Common Query Parameters

- `page` (integer): Page number for pagination (default: 1)
- `limit` (integer): Items per page (default: 50, max: 100)
- `sort` (string): Sort field (default varies by endpoint)
- `order` (string): Sort order - `asc` or `desc` (default: `desc`)
- `search` (string): Search query
- `filter[field]` (string): Filter by field value

Example:
```
GET /students?page=2&limit=20&sort=created_at&order=desc&search=john&filter[status]=active
```

## Webhooks

UniPortals can send webhook notifications for important events. Configure webhook URLs in the admin panel.

### Webhook Event Types

- `application.created` - New application submitted
- `application.status_changed` - Application status updated
- `payment.successful` - Payment completed
- `payment.failed` - Payment failed
- `admission.offered` - Admission offer created
- `student.registered` - New student registered
- `grade.published` - Grades published

### Webhook Payload Format

```json
{
  "event": "payment.successful",
  "timestamp": "2024-01-15T10:30:00Z",
  "data": {
    "payment_reference": "PAY123456789",
    "student_id": "uuid",
    "amount": 50000.00,
    "status": "successful"
  },
  "signature": "sha256_hash_for_verification"
}
```

## SDK and Client Libraries

### Official SDKs

- **JavaScript/TypeScript**: `npm install @uniportals/api-client`
- **Python**: `pip install uniportals-sdk`
- **PHP**: `composer require uniportals/api-client`

### Community SDKs

- **Ruby**: `gem install uniportals`
- **Go**: `go get github.com/uniportals/go-client`

## Code Examples

### JavaScript/Node.js

```javascript
const UniPortals = require('@uniportals/api-client');

const client = new UniPortals({
  apiKey: 'your_api_key',
  baseURL: 'https://api.uniportals.ng/v1'
});

// Create application
const application = await client.admissions.createApplication({
  jamb_registration_number: '12345678AB',
  program_id: 'uuid',
  applicant_email: 'john@example.com'
});

// Check admission status
const status = await client.admissions.checkStatus({
  jamb_registration_number: '12345678AB'
});

// Get student profile
const profile = await client.students.getProfile();

// Make payment
const payment = await client.financial.initiatePayment({
  invoice_id: 'uuid',
  amount: 50000.00,
  payment_method: 'card'
});
```

### Python

```python
from uniportals import UniPortalsClient

client = UniPortalsClient(
    api_key='your_api_key',
    base_url='https://api.uniportals.ng/v1'
)

# Create application
application = client.admissions.create_application(
    jamb_registration_number='12345678AB',
    program_id='uuid',
    applicant_email='john@example.com'
)

# Check admission status
status = client.admissions.check_status(
    jamb_registration_number='12345678AB'
)

# Get student profile
profile = client.students.get_profile()

# Make payment
payment = client.financial.initiate_payment(
    invoice_id='uuid',
    amount=50000.00,
    payment_method='card'
)
```

### cURL

```bash
# Create application
curl -X POST https://api.uniportals.ng/v1/admissions/applications \
  -H "Content-Type: application/json" \
  -d '{
    "jamb_registration_number": "12345678AB",
    "program_id": "uuid",
    "applicant_email": "john@example.com"
  }'

# Check admission status
curl -X GET https://api.uniportals.ng/v1/admissions/check-status?jamb_registration_number=12345678AB

# Get student profile (requires auth)
curl -X GET https://api.uniportals.ng/v1/students/profile \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## Testing

### Sandbox Environment

Test your integration using our sandbox environment:
- Base URL: `https://sandbox-api.uniportals.ng/v1`
- Test credentials provided upon request
- No real transactions processed

### Test Data

```json
{
  "test_jamb_number": "12345678AB",
  "test_student_id": "550e8400-e29b-41d4-a716-446655440000",
  "test_program_id": "660e8400-e29b-41d4-a716-446655440001",
  "test_payment_card": {
    "number": "4084084084084081",
    "cvv": "408",
    "expiry": "12/25"
  }
}
```

## Changelog

### Version 1.0.0 (2024-01-15)
- Initial API release
- Admissions module complete
- Student management module
- Academic operations module
- Financial management module
- Administrative module
- Integration services

## Support

### Documentation
- API Reference: https://docs.uniportals.ng/api
- User Guides: https://docs.uniportals.ng/guides
- FAQs: https://docs.uniportals.ng/faq

### Contact
- Technical Support: api-support@uniportals.ng
- Sales: sales@uniportals.ng
- General: info@uniportals.ng

### Community
- GitHub: https://github.com/olatokunbookulaja/uniportals
- Discord: https://discord.gg/uniportals
- Forum: https://forum.uniportals.ng

## Legal

- [Terms of Service](https://uniportals.ng/terms)
- [Privacy Policy](https://uniportals.ng/privacy)
- [API Usage Policy](https://uniportals.ng/api-policy)

---

**Last Updated**: January 15, 2024
**API Version**: 1.0.0
