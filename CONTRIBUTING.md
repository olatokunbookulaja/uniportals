# Contributing to UniPortals

Thank you for your interest in contributing to UniPortals! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Setup](#development-setup)
4. [Contribution Workflow](#contribution-workflow)
5. [Coding Standards](#coding-standards)
6. [Testing Guidelines](#testing-guidelines)
7. [Documentation](#documentation)
8. [Pull Request Process](#pull-request-process)
9. [Community](#community)

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inclusive environment for all contributors, regardless of background, identity, or experience level.

### Expected Behavior

- Be respectful and constructive in all interactions
- Welcome newcomers and help them get started
- Give and receive feedback gracefully
- Focus on what is best for the community and the project
- Show empathy towards other community members

### Unacceptable Behavior

- Harassment, discrimination, or offensive comments
- Trolling, insulting remarks, or personal attacks
- Publishing others' private information
- Any conduct that could reasonably be considered inappropriate

## Getting Started

### Prerequisites

Before contributing, ensure you have:
- Git installed and configured
- Node.js 16+ or Python 3.9+ (depending on the module)
- PostgreSQL 13+ for database development
- Redis 6+ for caching features
- Docker and Docker Compose (recommended)
- A code editor (VS Code recommended)

### Finding Issues to Work On

1. Browse the [issue tracker](https://github.com/olatokunbookulaja/uniportals/issues)
2. Look for issues labeled:
   - `good first issue` - Great for newcomers
   - `help wanted` - We need assistance on these
   - `bug` - Bug fixes needed
   - `enhancement` - New features or improvements
3. Comment on the issue to express your interest
4. Wait for maintainer approval before starting work

### Reporting Bugs

When reporting a bug, please include:

```markdown
**Bug Description**
A clear description of what the bug is.

**Steps to Reproduce**
1. Go to '...'
2. Click on '...'
3. See error

**Expected Behavior**
What you expected to happen.

**Actual Behavior**
What actually happened.

**Environment**
- OS: [e.g., Ubuntu 20.04]
- Browser: [e.g., Chrome 96]
- UniPortals Version: [e.g., 1.0.0]

**Screenshots**
If applicable, add screenshots.

**Additional Context**
Any other relevant information.
```

### Suggesting Enhancements

Enhancement suggestions should include:
- Clear use case and value proposition
- Detailed description of the proposed feature
- Mockups or examples (if applicable)
- Consideration of impact on existing functionality

## Development Setup

### 1. Fork and Clone

```bash
# Fork the repository on GitHub, then:
git clone https://github.com/YOUR_USERNAME/uniportals.git
cd uniportals

# Add upstream remote
git remote add upstream https://github.com/olatokunbookulaja/uniportals.git
```

### 2. Environment Setup

```bash
# Copy environment template
cp .env.example .env

# Edit .env with your local configuration
nano .env
```

### 3. Install Dependencies

**Backend (Node.js)**
```bash
cd backend
npm install
```

**Backend (Python)**
```bash
cd backend
pip install -r requirements.txt
```

**Frontend**
```bash
cd frontend/student-portal
npm install
```

### 4. Database Setup

```bash
# Start PostgreSQL and Redis
docker-compose up -d postgres redis

# Run migrations
npm run migrate
# or
python manage.py migrate

# Seed database (optional)
npm run seed
```

### 5. Start Development Servers

```bash
# Backend
cd backend
npm run dev  # or python manage.py runserver

# Frontend (separate terminal)
cd frontend/student-portal
npm start
```

## Contribution Workflow

### 1. Create a Feature Branch

```bash
# Update your local main branch
git checkout main
git pull upstream main

# Create a new feature branch
git checkout -b feature/your-feature-name
# or
git checkout -b fix/bug-description
```

### Branch Naming Convention

- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation changes
- `refactor/` - Code refactoring
- `test/` - Test additions or modifications
- `chore/` - Maintenance tasks

Examples:
- `feature/jamb-integration`
- `fix/payment-validation`
- `docs/api-documentation`

### 2. Make Your Changes

- Write clean, maintainable code
- Follow coding standards (see below)
- Add tests for new functionality
- Update documentation as needed
- Keep commits atomic and focused

### 3. Commit Your Changes

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```bash
git add .
git commit -m "feat: add JAMB candidate validation"
```

**Commit Message Format:**
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Test additions or changes
- `chore`: Maintenance tasks

**Examples:**
```
feat(admissions): add Post-UTME scheduling
fix(payments): resolve duplicate transaction issue
docs(api): update authentication examples
refactor(students): optimize course registration query
test(academic): add grade computation tests
```

### 4. Push to Your Fork

```bash
git push origin feature/your-feature-name
```

### 5. Open a Pull Request

1. Go to your fork on GitHub
2. Click "New Pull Request"
3. Select your feature branch
4. Fill out the PR template
5. Link related issues
6. Request review from maintainers

## Coding Standards

### General Principles

- **KISS**: Keep It Simple, Stupid
- **DRY**: Don't Repeat Yourself
- **SOLID**: Follow SOLID principles
- **Clean Code**: Write self-documenting code
- **Security First**: Always consider security implications

### JavaScript/TypeScript

```javascript
// Use ES6+ features
const fetchStudentData = async (studentId) => {
  try {
    const student = await Student.findById(studentId);
    return student;
  } catch (error) {
    logger.error('Failed to fetch student', { studentId, error });
    throw error;
  }
};

// Use descriptive variable names
const isEligibleForAdmission = (utmeScore, minimumScore) => {
  return utmeScore >= minimumScore;
};

// Add JSDoc comments for functions
/**
 * Calculate student's CGPA
 * @param {string} studentId - The student's ID
 * @param {string} semesterId - The semester ID
 * @returns {Promise<number>} The calculated CGPA
 */
async function calculateCGPA(studentId, semesterId) {
  // Implementation
}
```

### Python

```python
# Follow PEP 8 style guide
from typing import Optional

def calculate_aggregate_score(
    utme_score: int,
    post_utme_score: float,
    utme_weight: float = 0.6
) -> float:
    """
    Calculate aggregate admission score.
    
    Args:
        utme_score: UTME total score
        post_utme_score: Post-UTME score
        utme_weight: Weight for UTME score (default: 0.6)
        
    Returns:
        Calculated aggregate score
    """
    return (utme_score * utme_weight) + (post_utme_score * (1 - utme_weight))

# Use type hints
def get_student(student_id: str) -> Optional[Student]:
    return Student.objects.filter(id=student_id).first()
```

### Database

```sql
-- Use meaningful table and column names
-- Add comments for complex logic
-- Create indexes for frequently queried columns

-- Good
CREATE INDEX idx_students_registration_number 
ON students(registration_number);

-- Use transactions for multi-step operations
BEGIN;
  INSERT INTO enrollments (...) VALUES (...);
  UPDATE students SET current_level = 200 WHERE id = '...';
COMMIT;
```

### API Design

```javascript
// RESTful endpoint naming
// Good
GET    /api/v1/students/:id
POST   /api/v1/students
PUT    /api/v1/students/:id
DELETE /api/v1/students/:id

// Consistent response format
{
  "success": true,
  "data": { ... },
  "message": "Student created successfully"
}

// Proper error handling
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid student data",
    "details": [...]
  }
}
```

## Testing Guidelines

### Write Tests First (TDD)

1. Write a failing test
2. Write minimal code to pass the test
3. Refactor while keeping tests green

### Test Categories

**Unit Tests**
```javascript
describe('calculateCGPA', () => {
  it('should calculate correct CGPA for valid grades', () => {
    const grades = [
      { credit_units: 3, grade_point: 4.0 },
      { credit_units: 2, grade_point: 3.5 }
    ];
    const cgpa = calculateCGPA(grades);
    expect(cgpa).toBe(3.8);
  });

  it('should handle empty grades array', () => {
    expect(calculateCGPA([])).toBe(0);
  });
});
```

**Integration Tests**
```javascript
describe('POST /api/v1/admissions/applications', () => {
  it('should create application with valid JAMB number', async () => {
    const response = await request(app)
      .post('/api/v1/admissions/applications')
      .send({
        jamb_registration_number: '12345678AB',
        program_id: 'uuid',
        applicant_email: 'test@example.com'
      });
    
    expect(response.status).toBe(201);
    expect(response.body.success).toBe(true);
  });
});
```

**E2E Tests**
```javascript
describe('Student Registration Flow', () => {
  it('should complete full registration process', async () => {
    // Login
    await page.goto('/login');
    await page.fill('#username', 'testuser');
    await page.fill('#password', 'password');
    await page.click('button[type="submit"]');
    
    // Register for courses
    await page.goto('/registration');
    await page.click('.course-checkbox[data-id="CS101"]');
    await page.click('button#submit-registration');
    
    // Verify
    await expect(page.locator('.success-message')).toBeVisible();
  });
});
```

### Test Coverage

- Maintain minimum 80% code coverage
- Focus on critical paths and edge cases
- Don't test external dependencies (mock them)

### Running Tests

```bash
# Unit tests
npm test

# Integration tests
npm run test:integration

# E2E tests
npm run test:e2e

# Coverage report
npm run test:coverage
```

## Documentation

### Code Documentation

- Add JSDoc/docstring comments for all public functions
- Explain complex algorithms and business logic
- Document API endpoints with examples
- Keep README files up to date

### API Documentation

When adding new endpoints, update the API documentation:

```markdown
#### Create Student

**Endpoint**: `POST /api/v1/students`

**Authentication**: Required (Admin only)

**Request Body**:
\`\`\`json
{
  "first_name": "John",
  "last_name": "Doe",
  "email": "john.doe@example.com",
  "program_id": "uuid"
}
\`\`\`

**Response**: `201 Created`
\`\`\`json
{
  "success": true,
  "data": {
    "id": "uuid",
    "registration_number": "STU2024/001234",
    ...
  }
}
\`\`\`
```

### User Documentation

- Update user guides for UI changes
- Add screenshots for new features
- Provide clear step-by-step instructions

## Pull Request Process

### PR Template

When creating a PR, fill out the template:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Related Issue
Closes #123

## Changes Made
- Added JAMB integration
- Updated database schema
- Added API endpoints

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

## Screenshots (if applicable)
[Add screenshots here]

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings generated
- [ ] Tests added/updated
```

### Review Process

1. **Automated Checks**: CI/CD pipeline runs tests and linting
2. **Code Review**: At least one maintainer reviews the code
3. **Address Feedback**: Make requested changes
4. **Approval**: Once approved, PR can be merged
5. **Merge**: Maintainer merges the PR

### Review Guidelines

**For Contributors:**
- Respond to feedback promptly
- Be open to suggestions
- Don't take criticism personally
- Ask questions if unclear

**For Reviewers:**
- Be constructive and respectful
- Explain the reasoning behind suggestions
- Approve when ready, don't nitpick
- Recognize good work

## Community

### Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General discussions and Q&A
- **Discord**: Real-time chat and support
- **Email**: info@uniportals.ng

### Getting Help

1. Check existing documentation
2. Search closed issues
3. Ask in GitHub Discussions
4. Join our Discord community

### Recognition

Contributors are recognized in:
- CONTRIBUTORS.md file
- Release notes
- Project website

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Questions?

If you have questions not covered here, please:
1. Check the [FAQ](https://docs.uniportals.ng/faq)
2. Ask in [GitHub Discussions](https://github.com/olatokunbookulaja/uniportals/discussions)
3. Email us at dev@uniportals.ng

---

Thank you for contributing to UniPortals! 🎉

Together, we're building a better future for Nigerian universities.
