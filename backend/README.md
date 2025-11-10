# UniPortals Backend API

## Overview

This is the backend API server for UniPortals - a comprehensive university management system. The API provides endpoints for admissions, student management, academic operations, financial transactions, and administrative functions.

## Technology Stack

- **Runtime**: Node.js 16+
- **Framework**: Express.js
- **Language**: TypeScript
- **Database**: PostgreSQL 13+
- **Cache**: Redis 6+
- **Authentication**: JWT (JSON Web Tokens)
- **Validation**: Express Validator
- **File Upload**: Multer
- **Email**: Nodemailer
- **Testing**: Jest + Supertest

## Project Structure

```
backend/
├── src/
│   ├── modules/
│   │   ├── admissions/       # Admissions management
│   │   │   ├── controllers/  # Request handlers
│   │   │   ├── services/     # Business logic
│   │   │   ├── models/       # Data models
│   │   │   ├── routes/       # API routes
│   │   │   └── validators/   # Input validation
│   │   ├── students/         # Student management
│   │   ├── academic/         # Academic operations
│   │   ├── financial/        # Financial management
│   │   ├── administrative/   # Admin operations
│   │   └── integrations/     # External integrations
│   │       ├── jamb/         # JAMB integration
│   │       ├── payments/     # Payment gateways
│   │       └── notifications/ # SMS/Email services
│   ├── database/
│   │   ├── connection.ts     # Database connection
│   │   ├── migrations/       # Database migrations
│   │   └── repositories/     # Data access layer
│   ├── middleware/
│   │   ├── auth.ts           # Authentication middleware
│   │   ├── errorHandler.ts  # Error handling
│   │   ├── validation.ts    # Request validation
│   │   └── rateLimiter.ts   # Rate limiting
│   ├── utils/
│   │   ├── logger.ts         # Winston logger
│   │   ├── cache.ts          # Redis cache wrapper
│   │   ├── email.ts          # Email utilities
│   │   └── helpers.ts        # Helper functions
│   └── index.ts              # Application entry point
├── tests/
│   ├── unit/                 # Unit tests
│   ├── integration/          # Integration tests
│   └── fixtures/             # Test data
├── config/
│   ├── database.ts           # Database configuration
│   ├── redis.ts              # Redis configuration
│   └── app.ts                # Application configuration
├── .env.example              # Environment variables template
├── package.json              # Dependencies and scripts
├── tsconfig.json             # TypeScript configuration
└── README.md                 # This file
```

## Getting Started

### Prerequisites

- Node.js 16 or higher
- npm or yarn
- PostgreSQL 13 or higher
- Redis 6 or higher

### Installation

1. **Install dependencies**:
```bash
npm install
```

2. **Setup environment variables**:
```bash
cp .env.example .env
# Edit .env with your configuration
```

3. **Setup database**:
```bash
# Create database
createdb uniportals

# Run migrations
npm run migrate

# Seed sample data (optional)
npm run seed
```

4. **Start development server**:
```bash
npm run dev
```

The API will be available at `http://localhost:3000`

### Environment Variables

See `.env.example` for all required environment variables. Key variables include:

```env
# Application
NODE_ENV=development
PORT=3000

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/uniportals

# Redis
REDIS_URL=redis://localhost:6379

# JWT
JWT_SECRET=your-secret-key
JWT_EXPIRY=24h

# JAMB Integration
JAMB_API_URL=https://api.jamb.gov.ng
JAMB_CLIENT_ID=your_client_id
JAMB_CLIENT_SECRET=your_client_secret

# Payment Gateways
PAYSTACK_SECRET_KEY=sk_test_xxxxx
FLUTTERWAVE_SECRET_KEY=FLWSECK_TEST-xxxxx

# Email
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@domain.com
SMTP_PASSWORD=your-password
```

## Available Scripts

```bash
# Development
npm run dev          # Start development server with hot reload

# Building
npm run build        # Compile TypeScript to JavaScript
npm start            # Start production server

# Testing
npm test             # Run all tests
npm run test:watch   # Run tests in watch mode
npm run test:coverage # Generate coverage report

# Code Quality
npm run lint         # Run ESLint
npm run lint:fix     # Fix ESLint errors

# Database
npm run migrate      # Run database migrations
npm run migrate:rollback # Rollback last migration
npm run seed         # Seed database with sample data
```

## API Documentation

Complete API documentation is available in the `/docs/api` directory:

- [API Overview](../docs/api/README.md)
- [Admissions API](../docs/api/admissions-api.md)
- [Authentication](#authentication)
- [Error Handling](#error-handling)

### Quick Start Example

#### Authentication

```bash
# Login
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "password"
  }'

# Response
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "user": {
      "id": "uuid",
      "username": "admin",
      "user_type": "admin"
    }
  }
}
```

#### Creating an Application

```bash
curl -X POST http://localhost:3000/api/v1/admissions/applications \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "jamb_registration_number": "12345678AB",
    "program_id": "uuid",
    "applicant_email": "john@example.com"
  }'
```

## Development Guidelines

### Code Style

This project uses:
- **TypeScript** for type safety
- **ESLint** for code linting
- **Prettier** for code formatting

Run linter before committing:
```bash
npm run lint:fix
```

### Writing Tests

```typescript
// tests/unit/admissions/admissions.service.test.ts
describe('AdmissionsService', () => {
  describe('createApplication', () => {
    it('should create application with valid JAMB number', async () => {
      const applicationData = {
        jamb_registration_number: '12345678AB',
        program_id: 'uuid',
        applicant_email: 'test@example.com'
      };

      const result = await admissionsService.createApplication(applicationData);

      expect(result).toBeDefined();
      expect(result.application_number).toMatch(/^APP\d{4}\/\d{6}$/);
    });
  });
});
```

### Error Handling

All errors should extend the base `ApiError` class:

```typescript
import { ApiError } from '../utils/errors';

// Usage
if (!user) {
  throw new ApiError(404, 'User not found', 'USER_NOT_FOUND');
}
```

### Logging

Use the Winston logger:

```typescript
import { logger } from '../utils/logger';

logger.info('User logged in', { userId: user.id });
logger.error('Failed to process payment', { error: error.message });
logger.debug('Processing admission application', { applicationId });
```

## Database Migrations

### Creating a Migration

```bash
npx knex migrate:make migration_name
```

### Running Migrations

```bash
npm run migrate
```

### Rolling Back

```bash
npm run migrate:rollback
```

## JAMB Integration

The JAMB integration module provides:
- Candidate data retrieval
- UTME score validation
- O'Level results verification
- Bulk candidate synchronization

See [JAMB Integration Specification](src/modules/integrations/jamb-integration-spec.md) for details.

## Payment Gateway Integration

Supported payment gateways:
- **Paystack** - Card, Bank Transfer, USSD
- **Flutterwave** - Card, Bank Transfer, Mobile Money
- **Remita** - RRR, Bank Branch, Direct Debit

Each gateway has its own service class and webhook handler.

## Security

### Authentication

- JWT-based authentication
- Token expiry: 24 hours (configurable)
- Refresh tokens: 7 days (configurable)

### Authorization

Role-based access control (RBAC):
- `super_admin` - Full system access
- `admin` - University-level administration
- `admissions_officer` - Admissions management
- `academic_officer` - Academic operations
- `finance_officer` - Financial management
- `lecturer` - Grade entry and course management
- `student` - Student portal access
- `applicant` - Admissions portal access

### Rate Limiting

- Anonymous: 20 requests/minute
- Authenticated: 100 requests/minute
- Admin: 500 requests/minute

### Data Encryption

- Passwords: bcrypt with 10 rounds
- Sensitive data: AES-256 encryption
- Communication: TLS 1.3

## Performance

### Caching Strategy

Redis is used for:
- Session storage
- JAMB candidate data (1 hour TTL)
- Program and course data (24 hours TTL)
- Fee structures (6 hours TTL)

### Database Optimization

- Indexes on frequently queried columns
- Connection pooling (min: 2, max: 10)
- Query result pagination
- Prepared statements

## Monitoring

### Health Check Endpoints

```bash
# Basic health check
GET /health

# Detailed readiness check
GET /ready
```

### Logging

Logs are written to:
- Console (development)
- Files: `logs/app.log`, `logs/error.log`
- External service (production): Sentry, LogDNA

### Metrics

Application metrics exposed at `/metrics` (Prometheus format):
- Request count and duration
- Database query duration
- Cache hit/miss ratio
- Active connections

## Deployment

### Docker

```bash
# Build image
docker build -t uniportals-backend .

# Run container
docker run -p 3000:3000 --env-file .env uniportals-backend
```

### Docker Compose

```bash
docker-compose up -d
```

### Production Considerations

1. **Environment Variables**: Use secrets management (e.g., AWS Secrets Manager)
2. **Database**: Use managed PostgreSQL service (e.g., AWS RDS)
3. **Redis**: Use managed Redis service (e.g., AWS ElastiCache)
4. **Load Balancing**: Use Nginx or cloud load balancer
5. **SSL/TLS**: Terminate at load balancer or use reverse proxy
6. **Monitoring**: Set up Prometheus + Grafana or cloud monitoring
7. **Backup**: Automated database backups with point-in-time recovery

## Troubleshooting

### Common Issues

**Database connection failed**
```bash
# Check PostgreSQL is running
pg_isready

# Verify connection string in .env
psql $DATABASE_URL
```

**Redis connection failed**
```bash
# Check Redis is running
redis-cli ping

# Should return: PONG
```

**Port already in use**
```bash
# Find process using port 3000
lsof -i :3000

# Kill process
kill -9 <PID>
```

## Contributing

Please read [CONTRIBUTING.md](../CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## Testing

```bash
# Run all tests
npm test

# Run specific test file
npm test -- tests/unit/admissions/admissions.service.test.ts

# Run with coverage
npm run test:coverage

# Watch mode
npm run test:watch
```

## Support

- **Documentation**: [Full API Docs](../docs/api/README.md)
- **Issues**: [GitHub Issues](https://github.com/olatokunbookulaja/uniportals/issues)
- **Email**: api-support@uniportals.ng

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

## Acknowledgments

- National Universities Commission (NUC)
- Joint Admissions and Matriculation Board (JAMB)
- Nigerian university community

---

**Status**: 🚀 Foundation Complete - Ready for Implementation

For system architecture details, see [System Architecture](../docs/architecture/system-architecture.md)
