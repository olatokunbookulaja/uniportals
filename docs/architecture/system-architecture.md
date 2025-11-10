# System Architecture Documentation

## Table of Contents
1. [Overview](#overview)
2. [Architecture Patterns](#architecture-patterns)
3. [System Components](#system-components)
4. [Data Flow](#data-flow)
5. [Integration Architecture](#integration-architecture)
6. [Security Architecture](#security-architecture)
7. [Deployment Architecture](#deployment-architecture)

## Overview

UniPortals follows a microservices-inspired modular monolith architecture that balances development simplicity with scalability. The system is designed to support multiple universities while maintaining data isolation and operational efficiency.

## Architecture Patterns

### 1. Modular Monolith
The system is organized into distinct modules that can be independently developed and potentially separated into microservices as needed:

- **Admissions Module**: Handles all admission-related operations
- **Student Module**: Manages student lifecycle and records
- **Academic Module**: Controls courses, grades, and academic operations
- **Financial Module**: Processes payments, invoices, and scholarships
- **Administrative Module**: Handles staff, departments, and system admin
- **Integration Module**: Manages external system integrations

### 2. Layered Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Presentation Layer                     │
│  (React/Vue Frontend, Mobile Apps, Admin Dashboard)     │
└─────────────────────────────────────────────────────────┘
                          ↓ HTTP/REST
┌─────────────────────────────────────────────────────────┐
│                    API Gateway Layer                     │
│        (Authentication, Rate Limiting, Routing)          │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                  Business Logic Layer                    │
│  ┌──────────┬──────────┬──────────┬──────────────────┐ │
│  │Admissions│ Student  │ Academic │ Financial        │ │
│  │  Module  │  Module  │  Module  │  Module          │ │
│  └──────────┴──────────┴──────────┴──────────────────┘ │
│  ┌──────────────────────┬──────────────────────────┐   │
│  │ Administrative       │ Integration              │   │
│  │ Module               │ Module                   │   │
│  └──────────────────────┴──────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                   Data Access Layer                      │
│        (Repository Pattern, Query Builders)              │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                   Persistence Layer                      │
│  ┌────────────┬─────────────┬───────────────────────┐  │
│  │ PostgreSQL │   Redis     │   File Storage        │  │
│  │  (Primary) │  (Cache)    │   (Documents/Media)   │  │
│  └────────────┴─────────────┴───────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## System Components

### Core Backend Services

#### 1. API Server
- **Technology**: Node.js/Express or Python/Django
- **Responsibilities**:
  - Handle HTTP requests
  - Route to appropriate modules
  - Enforce authentication and authorization
  - Request validation
  - Response formatting

#### 2. Authentication Service
- **JWT-based authentication**
- **Multi-factor authentication (MFA)**
- **Session management**
- **Password policies and reset flows**
- **Role-based access control (RBAC)**

#### 3. Module Services

**Admissions Service**
- Application processing
- JAMB data integration
- Post-UTME management
- Admission list generation
- Document verification

**Student Service**
- Student profile management
- Enrollment tracking
- Course registration
- Academic progress monitoring
- Hostel allocation

**Academic Service**
- Course management
- Grade entry and approval
- Result computation
- Timetable management
- Transcript generation

**Financial Service**
- Fee structure management
- Invoice generation
- Payment processing
- Revenue reporting
- Scholarship administration

**Administrative Service**
- User management
- Staff records
- Department/Faculty management
- System configuration
- Audit logging

**Integration Service**
- JAMB API integration
- Payment gateway connectors
- SMS/Email providers
- Document verification services
- External reporting systems

### Frontend Applications

#### 1. Student Portal
- **Technology**: React.js/Vue.js
- **Features**:
  - Dashboard with key metrics
  - Course registration
  - Result viewing
  - Payment processing
  - Profile management
  - Document downloads

#### 2. Admissions Portal
- **Technology**: React.js/Vue.js
- **Features**:
  - Application submission
  - Document upload
  - Application status tracking
  - Post-UTME scheduling
  - Admission offer acceptance

#### 3. Administrative Dashboard
- **Technology**: React.js with admin template
- **Features**:
  - System analytics
  - User management
  - Configuration management
  - Report generation
  - Audit log viewing

#### 4. Staff/Faculty Portal
- **Technology**: React.js/Vue.js
- **Features**:
  - Course management
  - Grade entry
  - Student list viewing
  - Attendance tracking
  - Report generation

#### 5. Mobile Application
- **Technology**: React Native
- **Features**:
  - Subset of web portal features
  - Push notifications
  - Offline capability
  - Mobile-optimized UI

## Data Flow

### 1. Admission Process Flow

```
┌─────────────┐
│  Applicant  │
└──────┬──────┘
       │ 1. Submit Application
       ↓
┌──────────────────┐
│ Admissions Portal│
└──────┬───────────┘
       │ 2. Create Application
       ↓
┌──────────────────┐     ┌──────────────┐
│ API Gateway      │────→│ JAMB Service │
└──────┬───────────┘  3. Fetch JAMB Data └──────────────┘
       │
       │ 4. Validate & Store
       ↓
┌──────────────────┐
│ Admissions Module│
└──────┬───────────┘
       │ 5. Schedule Post-UTME
       ↓
┌──────────────────┐
│  Notification    │────→ Email/SMS to Applicant
│    Service       │
└──────────────────┘
       ↓
┌──────────────────┐
│ Post-UTME Result │
│     Entry        │
└──────┬───────────┘
       │ 6. Generate Admission List
       ↓
┌──────────────────┐
│ Admission Offers │
└──────┬───────────┘
       │ 7. Notify Successful Candidates
       ↓
┌──────────────────┐
│  New Students    │
└──────────────────┘
```

### 2. Payment Processing Flow

```
┌─────────────┐
│   Student   │
└──────┬──────┘
       │ 1. Initiate Payment
       ↓
┌──────────────────┐
│  Student Portal  │
└──────┬───────────┘
       │ 2. Request Invoice
       ↓
┌──────────────────┐
│ Financial Module │
└──────┬───────────┘
       │ 3. Generate Invoice
       ↓
┌──────────────────┐
│  Payment Gateway │←──── Paystack/Flutterwave/Remita
│   Integration    │
└──────┬───────────┘
       │ 4. Process Payment
       ↓
┌──────────────────┐
│  Webhook Handler │
└──────┬───────────┘
       │ 5. Verify Payment
       ↓
┌──────────────────┐
│ Update Payment   │
│    & Invoice     │
└──────┬───────────┘
       │ 6. Send Receipt
       ↓
┌──────────────────┐
│  Notification    │────→ Email/SMS Receipt
│    Service       │
└──────────────────┘
```

### 3. Course Registration Flow

```
┌─────────────┐
│   Student   │
└──────┬──────┘
       │ 1. View Available Courses
       ↓
┌──────────────────┐
│ Academic Module  │
└──────┬───────────┘
       │ 2. Check Prerequisites
       ↓
┌──────────────────┐
│ Financial Module │
└──────┬───────────┘
       │ 3. Verify Payment Status
       ↓
┌──────────────────┐
│ Register Courses │
└──────┬───────────┘
       │ 4. Update Enrollment
       ↓
┌──────────────────┐
│ Generate Receipt │
└──────────────────┘
```

## Integration Architecture

### 1. JAMB Integration

```
┌─────────────────────────────────────────────┐
│          UniPortals System                  │
│  ┌───────────────────────────────────────┐ │
│  │     JAMB Integration Service          │ │
│  │  ┌─────────────────────────────────┐ │ │
│  │  │  - API Client                   │ │ │
│  │  │  - Data Transformation          │ │ │
│  │  │  - Validation & Mapping         │ │ │
│  │  │  - Sync Scheduler               │ │ │
│  │  │  - Error Handling & Retry       │ │ │
│  │  └─────────────────────────────────┘ │ │
│  └───────────────────────────────────────┘ │
└──────────────┬──────────────────────────────┘
               │ HTTPS/REST API
               ↓
┌─────────────────────────────────────────────┐
│          JAMB API Gateway                   │
│  - Candidate Data Retrieval                 │
│  - UTME Scores                              │
│  - O'Level Results                          │
│  - Institutional Choice                     │
└─────────────────────────────────────────────┘
```

**Integration Features:**
- Scheduled batch synchronization
- Real-time candidate lookup
- Data validation and cleansing
- Conflict resolution
- Audit logging

### 2. Payment Gateway Integration

Multiple payment gateways supported:

**Paystack Integration**
```javascript
{
  provider: 'paystack',
  apiUrl: 'https://api.paystack.co',
  features: ['card', 'bank_transfer', 'ussd'],
  webhookSupport: true,
  callbackUrl: '/api/payments/paystack/callback'
}
```

**Flutterwave Integration**
```javascript
{
  provider: 'flutterwave',
  apiUrl: 'https://api.flutterwave.com',
  features: ['card', 'bank_transfer', 'ussd', 'mobile_money'],
  webhookSupport: true,
  callbackUrl: '/api/payments/flutterwave/callback'
}
```

**Remita Integration**
```javascript
{
  provider: 'remita',
  apiUrl: 'https://remitademo.net',
  features: ['rrr', 'bank_branch', 'direct_debit'],
  webhookSupport: true,
  callbackUrl: '/api/payments/remita/callback'
}
```

### 3. Communication Services

**SMS Gateway Integration**
- Africa's Talking
- Twilio
- Bulk SMS Nigeria

**Email Service**
- SMTP (Gmail, Office 365)
- SendGrid
- Mailgun

**Push Notifications**
- Firebase Cloud Messaging (FCM)
- Apple Push Notification Service (APNS)

## Security Architecture

### 1. Authentication & Authorization

```
┌──────────────────────────────────────────────────┐
│          Authentication Flow                      │
│                                                   │
│  User Login → Validate Credentials → JWT Token   │
│       ↓                                           │
│  Store Session → Redis Cache                     │
│       ↓                                           │
│  Return Token + Refresh Token                    │
└──────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────┐
│          Authorization Flow                       │
│                                                   │
│  API Request → Extract JWT → Validate Token      │
│       ↓                                           │
│  Get User Roles → Check Permissions              │
│       ↓                                           │
│  Allow/Deny Access                               │
└──────────────────────────────────────────────────┘
```

### 2. Data Security

**Encryption**
- Data at rest: AES-256 encryption for sensitive fields
- Data in transit: TLS 1.3 for all communications
- Password hashing: bcrypt/Argon2

**Access Control**
- Role-Based Access Control (RBAC)
- Row-Level Security for multi-tenancy
- Attribute-Based Access Control (ABAC) for complex scenarios

**Audit Logging**
- All data modifications logged
- User actions tracked
- IP address and user agent captured
- Immutable audit trail

### 3. API Security

- Rate limiting (100 requests/minute per user)
- CORS configuration
- CSRF protection
- XSS prevention
- SQL injection prevention (parameterized queries)
- Input validation and sanitization
- API key management for external integrations

## Deployment Architecture

### 1. Development Environment

```
┌─────────────────────────────────────────┐
│     Developer Workstation               │
│  - Local Backend Server                 │
│  - Local Frontend Dev Server            │
│  - PostgreSQL (Docker)                  │
│  - Redis (Docker)                       │
└─────────────────────────────────────────┘
```

### 2. Staging Environment

```
┌─────────────────────────────────────────┐
│     Staging Server                      │
│  ┌─────────────────────────────────┐   │
│  │  Backend API (PM2/Gunicorn)     │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │  Frontend (Nginx)               │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │  PostgreSQL (RDS/Managed)       │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │  Redis (ElastiCache/Managed)    │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

### 3. Production Environment (Recommended)

```
┌────────────────────────────────────────────────────────┐
│                 Load Balancer (Nginx/ALB)              │
└────────────────┬───────────────────────┬───────────────┘
                 │                       │
    ┌────────────┴────────────┐ ┌───────┴──────────────┐
    │   Backend API Server 1  │ │ Backend API Server 2 │
    │   (Docker Container)    │ │ (Docker Container)   │
    └────────────┬────────────┘ └───────┬──────────────┘
                 │                       │
    ┌────────────┴───────────────────────┴──────────────┐
    │         PostgreSQL (Primary + Replicas)           │
    └───────────────────────────────────────────────────┘
                               │
    ┌──────────────────────────┴────────────────────────┐
    │              Redis Cluster                         │
    └───────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│                 CDN (CloudFlare/CloudFront)            │
└────────────────┬───────────────────────────────────────┘
                 │
    ┌────────────┴────────────┐
    │   Frontend Static Files │
    │   (S3/Cloud Storage)    │
    └─────────────────────────┘

┌────────────────────────────────────────────────────────┐
│              Background Job Processor                  │
│  - Email Queue Worker                                  │
│  - SMS Queue Worker                                    │
│  - Report Generation Worker                            │
│  - JAMB Sync Worker                                    │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│              File Storage (S3/MinIO)                   │
│  - Student Documents                                   │
│  - Profile Photos                                      │
│  - Generated Reports                                   │
└────────────────────────────────────────────────────────┘
```

### 4. Infrastructure as Code

**Docker Compose** (Development)
```yaml
version: '3.8'
services:
  backend:
    build: ./backend
    ports: ["3000:3000"]
    environment:
      - DATABASE_URL=postgresql://db:5432/uniportals
      - REDIS_URL=redis://redis:6379
  
  frontend:
    build: ./frontend
    ports: ["80:80"]
  
  db:
    image: postgres:13
    volumes: ["postgres_data:/var/lib/postgresql/data"]
  
  redis:
    image: redis:6
```

**Kubernetes** (Production)
- Deployment manifests for each service
- Service definitions for load balancing
- ConfigMaps for configuration
- Secrets for sensitive data
- Horizontal Pod Autoscaling
- Ingress for routing

### 5. Monitoring & Observability

```
┌────────────────────────────────────────────────┐
│          Monitoring Stack                      │
│  ┌──────────────────────────────────────────┐ │
│  │  Application Metrics                     │ │
│  │  - Response times                        │ │
│  │  - Error rates                           │ │
│  │  - Throughput                            │ │
│  └──────────────────────────────────────────┘ │
│  ┌──────────────────────────────────────────┐ │
│  │  Infrastructure Metrics                  │ │
│  │  - CPU/Memory usage                      │ │
│  │  - Disk I/O                              │ │
│  │  - Network traffic                       │ │
│  └──────────────────────────────────────────┘ │
│  ┌──────────────────────────────────────────┐ │
│  │  Business Metrics                        │ │
│  │  - Active users                          │ │
│  │  - Applications processed                │ │
│  │  - Payments completed                    │ │
│  └──────────────────────────────────────────┘ │
│  ┌──────────────────────────────────────────┐ │
│  │  Log Aggregation                         │ │
│  │  - Application logs                      │ │
│  │  - Access logs                           │ │
│  │  - Error logs                            │ │
│  └──────────────────────────────────────────┘ │
└────────────────────────────────────────────────┘
        ↓
┌────────────────────────────────────────────────┐
│  Visualization & Alerting                      │
│  - Grafana Dashboards                          │
│  - Prometheus Alerts                           │
│  - PagerDuty/Slack Notifications               │
└────────────────────────────────────────────────┘
```

### 6. Disaster Recovery

**Backup Strategy**
- Database: Automated daily backups with 30-day retention
- Files: Replicated across multiple availability zones
- Configuration: Version controlled in Git

**Recovery Procedures**
- RPO (Recovery Point Objective): 1 hour
- RTO (Recovery Time Objective): 4 hours
- Automated failover to standby systems
- Regular disaster recovery drills

## Scalability Considerations

### Horizontal Scaling
- Stateless API servers can be scaled horizontally
- Load balancer distributes traffic
- Session data stored in Redis (shared state)

### Database Scaling
- Read replicas for query optimization
- Connection pooling
- Query optimization and indexing
- Caching layer (Redis)

### Caching Strategy
- Application-level caching
- Database query result caching
- API response caching
- CDN for static assets

### Performance Optimization
- Lazy loading of data
- Pagination for large datasets
- Background job processing for heavy tasks
- Database query optimization
- Code profiling and optimization

## Technology Choices

### Backend Options

**Option 1: Node.js + Express**
- Pros: Fast, async I/O, large ecosystem
- Cons: Callback complexity, less structure

**Option 2: Python + Django**
- Pros: Batteries included, ORM, admin interface
- Cons: Slower than Node.js, GIL limitations

**Recommendation**: Either works well. Choose based on team expertise.

### Frontend

**React.js**
- Component-based
- Large ecosystem
- Virtual DOM performance
- Excellent developer tools

### Database

**PostgreSQL**
- ACID compliance
- Advanced features (JSONB, full-text search)
- Strong data integrity
- Excellent performance

### Caching

**Redis**
- In-memory performance
- Data structure support
- Pub/sub capabilities
- Session storage

## Conclusion

This architecture provides a solid foundation for building a scalable, secure, and maintainable university management system with specific support for Nigerian educational requirements. The modular design allows for incremental development and future enhancements while maintaining system integrity and performance.
