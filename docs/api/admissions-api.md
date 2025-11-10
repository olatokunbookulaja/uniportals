# Admissions API Documentation

## Overview

The Admissions API provides endpoints for managing the complete admissions lifecycle, including JAMB/UTME integration, application processing, Post-UTME screening, and admission list generation.

## Base URL

```
Production: https://api.uniportals.ng/v1
Staging: https://staging-api.uniportals.ng/v1
Development: http://localhost:3000/api/v1
```

## Authentication

All API requests require authentication unless specified otherwise. Include the JWT token in the Authorization header:

```
Authorization: Bearer <your_jwt_token>
```

## Rate Limiting

- Anonymous users: 20 requests/minute
- Authenticated users: 100 requests/minute
- Admin users: 500 requests/minute

## Common Response Codes

- `200 OK`: Request successful
- `201 Created`: Resource created successfully
- `400 Bad Request`: Invalid request parameters
- `401 Unauthorized`: Authentication required or failed
- `403 Forbidden`: Insufficient permissions
- `404 Not Found`: Resource not found
- `422 Unprocessable Entity`: Validation errors
- `429 Too Many Requests`: Rate limit exceeded
- `500 Internal Server Error`: Server error

## Error Response Format

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format"
      }
    ]
  }
}
```

---

## Endpoints

### 1. Application Management

#### Create Application

Submit a new admission application.

**Endpoint**: `POST /admissions/applications`

**Authentication**: Optional (applicant can apply without account)

**Request Body**:
```json
{
  "admission_cycle_id": "uuid",
  "jamb_registration_number": "12345678AB",
  "program_id": "uuid",
  "applicant_email": "john.doe@example.com",
  "applicant_phone": "+2348012345678",
  "application_type": "utme",
  "olevel_results": [
    {
      "exam_type": "WAEC",
      "exam_number": "1234567890",
      "exam_year": 2023,
      "sitting_number": 1,
      "subjects": [
        {"subject": "Mathematics", "grade": "B3"},
        {"subject": "English Language", "grade": "C4"},
        {"subject": "Physics", "grade": "B2"},
        {"subject": "Chemistry", "grade": "C5"},
        {"subject": "Biology", "grade": "B3"}
      ]
    }
  ],
  "documents": {
    "passport_photo": "url_or_base64",
    "birth_certificate": "url_or_base64",
    "olevel_certificate": "url_or_base64"
  }
}
```

**Response**: `201 Created`
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "application_number": "APP2024/001234",
    "status": "pending",
    "jamb_data": {
      "candidate_name": "JOHN DOE",
      "utme_score": 245,
      "utme_subjects": {
        "Mathematics": 62,
        "English": 58,
        "Physics": 65,
        "Chemistry": 60
      }
    },
    "program": {
      "id": "uuid",
      "name": "Computer Science",
      "code": "CSC"
    },
    "created_at": "2024-01-15T10:30:00Z"
  }
}
```

#### Get Application Details

Retrieve details of a specific application.

**Endpoint**: `GET /admissions/applications/:application_id`

**Authentication**: Required (applicant or admin)

**Response**: `200 OK`
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "application_number": "APP2024/001234",
    "status": "screening_scheduled",
    "applicant_email": "john.doe@example.com",
    "applicant_phone": "+2348012345678",
    "jamb_registration_number": "12345678AB",
    "utme_score": 245,
    "program": {
      "id": "uuid",
      "name": "Computer Science",
      "minimum_utme_score": 200
    },
    "olevel_results": [...],
    "post_utme": {
      "venue": "Main Campus Hall A",
      "date": "2024-02-15",
      "time": "09:00:00",
      "status": "scheduled"
    },
    "documents": {
      "passport_photo": "https://...",
      "olevel_certificate": "https://..."
    },
    "timeline": [
      {
        "stage": "application_submitted",
        "date": "2024-01-15T10:30:00Z"
      },
      {
        "stage": "screening_scheduled",
        "date": "2024-01-20T14:00:00Z"
      }
    ],
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-20T14:00:00Z"
  }
}
```

#### Update Application

Update application information (before submission deadline).

**Endpoint**: `PUT /admissions/applications/:application_id`

**Authentication**: Required (applicant or admin)

**Request Body**: (partial update supported)
```json
{
  "applicant_phone": "+2348098765432",
  "documents": {
    "lga_certificate": "url_or_base64"
  }
}
```

**Response**: `200 OK`

#### List Applications

List all applications with filtering and pagination.

**Endpoint**: `GET /admissions/applications`

**Authentication**: Required (admin only)

**Query Parameters**:
- `admission_cycle_id` (optional): Filter by admission cycle
- `status` (optional): pending, screening_scheduled, screened, admitted, rejected
- `program_id` (optional): Filter by program
- `search` (optional): Search by name, application number, or JAMB number
- `page` (default: 1)
- `limit` (default: 50, max: 100)
- `sort` (default: created_at): created_at, status, utme_score
- `order` (default: desc): asc, desc

**Response**: `200 OK`
```json
{
  "success": true,
  "data": {
    "applications": [
      {
        "id": "uuid",
        "application_number": "APP2024/001234",
        "applicant_name": "JOHN DOE",
        "jamb_registration_number": "12345678AB",
        "utme_score": 245,
        "program_name": "Computer Science",
        "status": "screening_scheduled",
        "created_at": "2024-01-15T10:30:00Z"
      }
    ],
    "pagination": {
      "total": 1500,
      "page": 1,
      "limit": 50,
      "total_pages": 30
    }
  }
}
```

---

### 2. JAMB Integration

#### Fetch JAMB Candidate Data

Retrieve candidate information from JAMB database.

**Endpoint**: `POST /admissions/jamb/fetch`

**Authentication**: Required (admin only)

**Request Body**:
```json
{
  "jamb_registration_number": "12345678AB",
  "year": 2024
}
```

**Response**: `200 OK`
```json
{
  "success": true,
  "data": {
    "jamb_registration_number": "12345678AB",
    "candidate_name": "JOHN DOE",
    "date_of_birth": "2005-03-15",
    "gender": "Male",
    "state_of_origin": "Lagos",
    "lga": "Ikeja",
    "utme_score": 245,
    "utme_subjects": {
      "Mathematics": 62,
      "English": 58,
      "Physics": 65,
      "Chemistry": 60
    },
    "utme_year": 2024,
    "first_choice_institution": "University of Lagos",
    "first_choice_course": "Computer Science",
    "second_choice_institution": "Covenant University",
    "second_choice_course": "Software Engineering"
  }
}
```

#### Bulk JAMB Sync

Synchronize JAMB data for multiple candidates.

**Endpoint**: `POST /admissions/jamb/bulk-sync`

**Authentication**: Required (admin only)

**Request Body**:
```json
{
  "admission_cycle_id": "uuid",
  "program_ids": ["uuid1", "uuid2"],
  "sync_type": "incremental"
}
```

**Response**: `202 Accepted`
```json
{
  "success": true,
  "data": {
    "job_id": "uuid",
    "status": "processing",
    "message": "Bulk sync job started. Check status at /admissions/jamb/sync-status/:job_id"
  }
}
```

#### Get Sync Status

Check the status of a JAMB sync job.

**Endpoint**: `GET /admissions/jamb/sync-status/:job_id`

**Authentication**: Required (admin only)

**Response**: `200 OK`
```json
{
  "success": true,
  "data": {
    "job_id": "uuid",
    "status": "completed",
    "records_synced": 1234,
    "records_failed": 5,
    "started_at": "2024-01-15T10:00:00Z",
    "completed_at": "2024-01-15T10:15:00Z",
    "errors": [
      {
        "jamb_number": "12345678AB",
        "error": "Candidate not found in JAMB database"
      }
    ]
  }
}
```

---

### 3. Post-UTME Management

#### Schedule Post-UTME

Schedule Post-UTME screening for applicants.

**Endpoint**: `POST /admissions/post-utme/schedule`

**Authentication**: Required (admin only)

**Request Body**:
```json
{
  "admission_cycle_id": "uuid",
  "application_ids": ["uuid1", "uuid2", ...],
  "venue": "Main Campus Hall A",
  "date": "2024-02-15",
  "time": "09:00:00",
  "batch_name": "Batch 1 - Engineering"
}
```

**Response**: `201 Created`
```json
{
  "success": true,
  "data": {
    "scheduled_count": 150,
    "venue": "Main Campus Hall A",
    "date": "2024-02-15",
    "time": "09:00:00",
    "notification_status": "sending"
  }
}
```

#### Submit Post-UTME Results

Record Post-UTME screening results.

**Endpoint**: `POST /admissions/post-utme/results`

**Authentication**: Required (admin only)

**Request Body**:
```json
{
  "results": [
    {
      "application_id": "uuid",
      "score": 75.5,
      "max_score": 100,
      "subjects_tested": ["Mathematics", "Physics", "Chemistry"],
      "remarks": "Excellent performance"
    }
  ]
}
```

**Response**: `201 Created`
```json
{
  "success": true,
  "data": {
    "processed": 150,
    "successful": 148,
    "failed": 2,
    "errors": [
      {
        "application_id": "uuid",
        "error": "Invalid score value"
      }
    ]
  }
}
```

#### Get Post-UTME Result

Retrieve Post-UTME result for an application.

**Endpoint**: `GET /admissions/applications/:application_id/post-utme-result`

**Authentication**: Required (applicant or admin)

**Response**: `200 OK`
```json
{
  "success": true,
  "data": {
    "application_id": "uuid",
    "score": 75.5,
    "max_score": 100,
    "percentage": 75.5,
    "utme_score": 245,
    "aggregate_score": 160.275,
    "status": "passed",
    "remarks": "Excellent performance",
    "created_at": "2024-02-16T14:30:00Z"
  }
}
```

---

### 4. Admission List Management

#### Generate Admission List

Generate admission list based on aggregate scores and quotas.

**Endpoint**: `POST /admissions/admission-lists/generate`

**Authentication**: Required (admin only)

**Request Body**:
```json
{
  "admission_cycle_id": "uuid",
  "batch_number": 1,
  "list_type": "merit",
  "program_ids": ["uuid1", "uuid2"],
  "criteria": {
    "minimum_aggregate": 55.0,
    "merit_percentage": 45,
    "catchment_percentage": 35,
    "elds_percentage": 20
  }
}
```

**Response**: `201 Created`
```json
{
  "success": true,
  "data": {
    "admission_list_id": "uuid",
    "batch_number": 1,
    "list_type": "merit",
    "total_offers": 500,
    "programs": [
      {
        "program_id": "uuid",
        "program_name": "Computer Science",
        "offers": 50,
        "capacity": 60
      }
    ],
    "generated_date": "2024-03-01T10:00:00Z"
  }
}
```

#### Approve Admission List

Approve a generated admission list for publishing.

**Endpoint**: `POST /admissions/admission-lists/:list_id/approve`

**Authentication**: Required (admin only)

**Request Body**:
```json
{
  "approved_by_name": "Prof. John Smith",
  "approved_by_title": "Vice Chancellor",
  "remarks": "Approved for first batch admission"
}
```

**Response**: `200 OK`
```json
{
  "success": true,
  "data": {
    "admission_list_id": "uuid",
    "approved": true,
    "approved_at": "2024-03-02T09:00:00Z"
  }
}
```

#### Publish Admission List

Publish the approved admission list to applicants.

**Endpoint**: `POST /admissions/admission-lists/:list_id/publish`

**Authentication**: Required (admin only)

**Response**: `200 OK`
```json
{
  "success": true,
  "data": {
    "admission_list_id": "uuid",
    "published": true,
    "published_at": "2024-03-02T12:00:00Z",
    "offers_sent": 500,
    "notification_status": "completed"
  }
}
```

#### Check Admission Status

Allow applicants to check their admission status.

**Endpoint**: `GET /admissions/check-status`

**Authentication**: Optional

**Query Parameters**:
- `jamb_registration_number` OR `application_number`

**Response**: `200 OK`
```json
{
  "success": true,
  "data": {
    "application_number": "APP2024/001234",
    "applicant_name": "JOHN DOE",
    "program": "Computer Science",
    "admission_status": "admitted",
    "offer_type": "provisional",
    "admission_list": "First Batch - Merit",
    "acceptance_deadline": "2024-03-15",
    "next_steps": [
      "Accept admission offer",
      "Pay acceptance fee (₦50,000)",
      "Complete online registration",
      "Print admission letter"
    ],
    "documents_required": [
      "Original O'Level certificate",
      "Birth certificate",
      "LGA certificate",
      "Medical fitness certificate"
    ]
  }
}
```

---

### 5. Admission Offers

#### Accept Admission Offer

Accept a provisional admission offer.

**Endpoint**: `POST /admissions/offers/:offer_id/accept`

**Authentication**: Required (applicant)

**Request Body**:
```json
{
  "acceptance_confirmed": true,
  "payment_reference": "PAY123456789"
}
```

**Response**: `200 OK`
```json
{
  "success": true,
  "data": {
    "offer_id": "uuid",
    "acceptance_status": "accepted",
    "accepted_at": "2024-03-05T14:30:00Z",
    "next_steps": [
      "Complete registration",
      "Upload required documents",
      "Print admission letter"
    ],
    "registration_deadline": "2024-04-01"
  }
}
```

#### Reject Admission Offer

Decline an admission offer.

**Endpoint**: `POST /admissions/offers/:offer_id/reject`

**Authentication**: Required (applicant)

**Request Body**:
```json
{
  "reason": "Accepted offer at another institution"
}
```

**Response**: `200 OK`

---

### 6. Direct Entry Applications

#### Create Direct Entry Application

Submit a Direct Entry application.

**Endpoint**: `POST /admissions/direct-entry/applications`

**Authentication**: Optional

**Request Body**:
```json
{
  "admission_cycle_id": "uuid",
  "program_id": "uuid",
  "applicant_email": "jane.doe@example.com",
  "applicant_phone": "+2348012345678",
  "qualification_type": "ND",
  "qualification_details": {
    "institution": "Yaba College of Technology",
    "program": "Computer Science",
    "grade": "Upper Credit",
    "graduation_year": 2023
  },
  "olevel_results": [...],
  "documents": {
    "passport_photo": "url",
    "qualification_certificate": "url",
    "transcript": "url"
  }
}
```

**Response**: `201 Created` (similar structure to regular application)

---

### 7. Reports and Analytics

#### Get Admission Statistics

Retrieve admission cycle statistics.

**Endpoint**: `GET /admissions/statistics`

**Authentication**: Required (admin only)

**Query Parameters**:
- `admission_cycle_id` (required)

**Response**: `200 OK`
```json
{
  "success": true,
  "data": {
    "admission_cycle": "2024/2025",
    "total_applications": 15000,
    "applications_by_status": {
      "pending": 2000,
      "screening_scheduled": 3000,
      "screened": 8000,
      "admitted": 1500,
      "rejected": 500
    },
    "applications_by_program": [
      {
        "program_name": "Computer Science",
        "applications": 2500,
        "admitted": 250
      }
    ],
    "average_utme_score": 235.5,
    "average_post_utme_score": 72.3,
    "admission_offers": {
      "total": 2000,
      "accepted": 1500,
      "pending": 400,
      "rejected": 100
    },
    "gender_distribution": {
      "male": 9000,
      "female": 6000
    },
    "state_distribution": [
      {"state": "Lagos", "count": 3000},
      {"state": "Ogun", "count": 2500}
    ]
  }
}
```

---

## Webhooks

### Admission Status Updates

Receive notifications when application status changes.

**Webhook URL**: Configured in system settings

**Payload**:
```json
{
  "event": "application.status_changed",
  "timestamp": "2024-01-15T10:30:00Z",
  "data": {
    "application_id": "uuid",
    "application_number": "APP2024/001234",
    "old_status": "pending",
    "new_status": "screening_scheduled",
    "applicant_email": "john.doe@example.com"
  }
}
```

### Payment Confirmation

Receive notifications when admission-related payments are confirmed.

**Payload**:
```json
{
  "event": "payment.confirmed",
  "timestamp": "2024-01-15T10:30:00Z",
  "data": {
    "payment_reference": "PAY123456789",
    "application_id": "uuid",
    "amount": 50000.00,
    "payment_type": "acceptance_fee"
  }
}
```

---

## SDK Examples

### JavaScript/Node.js

```javascript
const UniPortalsAPI = require('@uniportals/api-client');

const client = new UniPortalsAPI({
  apiKey: 'your_api_key',
  baseURL: 'https://api.uniportals.ng/v1'
});

// Create application
const application = await client.admissions.createApplication({
  jamb_registration_number: '12345678AB',
  program_id: 'uuid',
  applicant_email: 'john.doe@example.com',
  // ... other fields
});

// Check admission status
const status = await client.admissions.checkStatus({
  jamb_registration_number: '12345678AB'
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
    applicant_email='john.doe@example.com'
)

# Check admission status
status = client.admissions.check_status(
    jamb_registration_number='12345678AB'
)
```

---

## Best Practices

1. **Error Handling**: Always check the `success` field in responses
2. **Pagination**: Use pagination for list endpoints to avoid large payloads
3. **Rate Limiting**: Implement exponential backoff for rate limit errors
4. **Webhooks**: Use webhooks for real-time updates instead of polling
5. **Caching**: Cache reference data (programs, fee structures) locally
6. **Security**: Never log or store JWT tokens in client-side code
7. **Validation**: Validate data client-side before sending to API

## Support

For API support:
- Email: api-support@uniportals.ng
- Documentation: https://docs.uniportals.ng
- Status Page: https://status.uniportals.ng
