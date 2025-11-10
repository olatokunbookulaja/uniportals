# JAMB Integration Specification

## Overview

This document outlines the integration strategy for connecting UniPortals with the Joint Admissions and Matriculation Board (JAMB) systems to retrieve candidate information, UTME scores, and facilitate the admissions process.

## Integration Architecture

### 1. Integration Type
- **API Integration**: RESTful API calls to JAMB's data services
- **Batch Processing**: Scheduled bulk data synchronization
- **Real-time Lookup**: On-demand candidate verification
- **File-based Integration**: CSV/Excel import for offline scenarios

### 2. Data Flow

```
┌──────────────────┐
│  JAMB Database   │
│  - Candidate Info│
│  - UTME Scores   │
│  - O'Level Data  │
│  - Choices       │
└────────┬─────────┘
         │ API Calls / File Export
         ↓
┌──────────────────┐
│ Integration      │
│ Service          │
│ - Fetch Data     │
│ - Transform      │
│ - Validate       │
└────────┬─────────┘
         │
         ↓
┌──────────────────┐
│ UniPortals DB    │
│ - jamb_records   │
│ - applications   │
└──────────────────┘
```

## JAMB API Endpoints (Hypothetical)

**Note**: The actual JAMB API endpoints would be provided by JAMB. These are representative examples.

### 1. Authentication

```http
POST https://api.jamb.gov.ng/v1/auth/token
Content-Type: application/json

{
  "client_id": "your_client_id",
  "client_secret": "your_client_secret",
  "grant_type": "client_credentials"
}

Response:
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

### 2. Get Candidate Information

```http
GET https://api.jamb.gov.ng/v1/candidates/{jamb_registration_number}
Authorization: Bearer {access_token}

Response:
{
  "registration_number": "12345678AB",
  "candidate_name": "JOHN DOE",
  "date_of_birth": "2005-03-15",
  "gender": "M",
  "state_of_origin": "25",
  "lga": "Lagos Mainland",
  "phone": "08012345678",
  "email": "john.doe@example.com",
  "exam_year": 2024,
  "exam_center": "Lagos Center 05"
}
```

### 3. Get UTME Scores

```http
GET https://api.jamb.gov.ng/v1/candidates/{jamb_registration_number}/scores
Authorization: Bearer {access_token}

Response:
{
  "registration_number": "12345678AB",
  "total_score": 245,
  "subjects": [
    {
      "subject_code": "MAT",
      "subject_name": "Mathematics",
      "score": 62
    },
    {
      "subject_code": "ENG",
      "subject_name": "English Language",
      "score": 58
    },
    {
      "subject_code": "PHY",
      "subject_name": "Physics",
      "score": 65
    },
    {
      "subject_code": "CHE",
      "subject_name": "Chemistry",
      "score": 60
    }
  ]
}
```

### 4. Get Institutional Choices

```http
GET https://api.jamb.gov.ng/v1/candidates/{jamb_registration_number}/choices
Authorization: Bearer {access_token}

Response:
{
  "registration_number": "12345678AB",
  "choices": [
    {
      "choice_number": 1,
      "institution_code": "0109",
      "institution_name": "UNIVERSITY OF LAGOS",
      "course_code": "0407",
      "course_name": "COMPUTER SCIENCE"
    },
    {
      "choice_number": 2,
      "institution_code": "0112",
      "institution_name": "COVENANT UNIVERSITY",
      "course_code": "0408",
      "course_name": "SOFTWARE ENGINEERING"
    }
  ]
}
```

### 5. Get O'Level Results

```http
GET https://api.jamb.gov.ng/v1/candidates/{jamb_registration_number}/olevel
Authorization: Bearer {access_token}

Response:
{
  "registration_number": "12345678AB",
  "sittings": [
    {
      "sitting_number": 1,
      "exam_type": "WAEC",
      "exam_number": "1234567890",
      "exam_year": 2023,
      "results": [
        {"subject": "Mathematics", "grade": "B3"},
        {"subject": "English Language", "grade": "C4"},
        {"subject": "Physics", "grade": "B2"},
        {"subject": "Chemistry", "grade": "C5"},
        {"subject": "Biology", "grade": "B3"},
        {"subject": "Further Mathematics", "grade": "C4"},
        {"subject": "Civic Education", "grade": "B2"},
        {"subject": "Economics", "grade": "C5"},
        {"subject": "Geography", "grade": "C6"}
      ]
    }
  ]
}
```

### 6. Bulk Candidate Lookup

```http
POST https://api.jamb.gov.ng/v1/candidates/bulk
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "institution_code": "0109",
  "course_codes": ["0407", "0408"],
  "exam_year": 2024,
  "choice_number": 1,
  "minimum_score": 200
}

Response:
{
  "total_candidates": 2500,
  "candidates": [
    {
      "registration_number": "12345678AB",
      "candidate_name": "JOHN DOE",
      "total_score": 245,
      "choice_number": 1,
      "course_code": "0407"
    },
    // ... more candidates
  ],
  "pagination": {
    "page": 1,
    "per_page": 100,
    "total_pages": 25
  }
}
```

## Integration Implementation

### 1. JAMB Service Class (Node.js/TypeScript)

```typescript
// backend/src/modules/integrations/jamb/JambService.ts

import axios, { AxiosInstance } from 'axios';
import { Cache } from '../../../utils/cache';
import { Logger } from '../../../utils/logger';

interface JambConfig {
  apiUrl: string;
  clientId: string;
  clientSecret: string;
  institutionCode: string;
}

interface JambCandidate {
  registration_number: string;
  candidate_name: string;
  date_of_birth: string;
  gender: string;
  state_of_origin: string;
  lga: string;
  phone?: string;
  email?: string;
}

interface JambScore {
  total_score: number;
  subjects: Array<{
    subject_code: string;
    subject_name: string;
    score: number;
  }>;
}

export class JambService {
  private client: AxiosInstance;
  private cache: Cache;
  private logger: Logger;
  private config: JambConfig;
  private accessToken?: string;
  private tokenExpiry?: Date;

  constructor(config: JambConfig) {
    this.config = config;
    this.client = axios.create({
      baseURL: config.apiUrl,
      timeout: 30000,
    });
    this.cache = new Cache({ ttl: 3600 }); // 1 hour cache
    this.logger = new Logger('JambService');
  }

  /**
   * Authenticate with JAMB API and get access token
   */
  private async authenticate(): Promise<string> {
    // Check if we have a valid cached token
    if (this.accessToken && this.tokenExpiry && new Date() < this.tokenExpiry) {
      return this.accessToken;
    }

    try {
      const response = await this.client.post('/v1/auth/token', {
        client_id: this.config.clientId,
        client_secret: this.config.clientSecret,
        grant_type: 'client_credentials',
      });

      this.accessToken = response.data.access_token;
      this.tokenExpiry = new Date(Date.now() + response.data.expires_in * 1000);
      
      this.logger.info('Successfully authenticated with JAMB API');
      return this.accessToken;
    } catch (error) {
      this.logger.error('JAMB authentication failed', error);
      throw new Error('Failed to authenticate with JAMB API');
    }
  }

  /**
   * Get candidate information by JAMB registration number
   */
  async getCandidateInfo(jambNumber: string): Promise<JambCandidate> {
    // Check cache first
    const cacheKey = `jamb:candidate:${jambNumber}`;
    const cached = await this.cache.get(cacheKey);
    if (cached) {
      this.logger.debug(`Cache hit for JAMB candidate ${jambNumber}`);
      return cached;
    }

    try {
      const token = await this.authenticate();
      const response = await this.client.get(`/v1/candidates/${jambNumber}`, {
        headers: { Authorization: `Bearer ${token}` },
      });

      const candidate = response.data;
      
      // Cache the result
      await this.cache.set(cacheKey, candidate);
      
      this.logger.info(`Fetched candidate info for ${jambNumber}`);
      return candidate;
    } catch (error: any) {
      if (error.response?.status === 404) {
        throw new Error(`Candidate ${jambNumber} not found in JAMB database`);
      }
      this.logger.error(`Failed to fetch candidate ${jambNumber}`, error);
      throw new Error('Failed to fetch candidate information from JAMB');
    }
  }

  /**
   * Get UTME scores for a candidate
   */
  async getUTMEScores(jambNumber: string): Promise<JambScore> {
    const cacheKey = `jamb:scores:${jambNumber}`;
    const cached = await this.cache.get(cacheKey);
    if (cached) return cached;

    try {
      const token = await this.authenticate();
      const response = await this.client.get(
        `/v1/candidates/${jambNumber}/scores`,
        { headers: { Authorization: `Bearer ${token}` } }
      );

      const scores = response.data;
      await this.cache.set(cacheKey, scores);
      
      return scores;
    } catch (error) {
      this.logger.error(`Failed to fetch UTME scores for ${jambNumber}`, error);
      throw new Error('Failed to fetch UTME scores from JAMB');
    }
  }

  /**
   * Get candidate choices (institution preferences)
   */
  async getCandidateChoices(jambNumber: string) {
    try {
      const token = await this.authenticate();
      const response = await this.client.get(
        `/v1/candidates/${jambNumber}/choices`,
        { headers: { Authorization: `Bearer ${token}` } }
      );

      return response.data;
    } catch (error) {
      this.logger.error(`Failed to fetch choices for ${jambNumber}`, error);
      throw new Error('Failed to fetch candidate choices from JAMB');
    }
  }

  /**
   * Get O'Level results for a candidate
   */
  async getOLevelResults(jambNumber: string) {
    const cacheKey = `jamb:olevel:${jambNumber}`;
    const cached = await this.cache.get(cacheKey);
    if (cached) return cached;

    try {
      const token = await this.authenticate();
      const response = await this.client.get(
        `/v1/candidates/${jambNumber}/olevel`,
        { headers: { Authorization: `Bearer ${token}` } }
      );

      const results = response.data;
      await this.cache.set(cacheKey, results);
      
      return results;
    } catch (error) {
      this.logger.error(`Failed to fetch O'Level results for ${jambNumber}`, error);
      throw new Error('Failed to fetch O\'Level results from JAMB');
    }
  }

  /**
   * Bulk fetch candidates who chose this institution
   */
  async bulkFetchCandidates(params: {
    courseCodes?: string[];
    examYear: number;
    choiceNumber?: number;
    minimumScore?: number;
    page?: number;
    perPage?: number;
  }) {
    try {
      const token = await this.authenticate();
      const response = await this.client.post(
        '/v1/candidates/bulk',
        {
          institution_code: this.config.institutionCode,
          course_codes: params.courseCodes,
          exam_year: params.examYear,
          choice_number: params.choiceNumber || 1,
          minimum_score: params.minimumScore,
        },
        {
          headers: { Authorization: `Bearer ${token}` },
          params: {
            page: params.page || 1,
            per_page: params.perPage || 100,
          },
        }
      );

      return response.data;
    } catch (error) {
      this.logger.error('Bulk fetch candidates failed', error);
      throw new Error('Failed to bulk fetch candidates from JAMB');
    }
  }

  /**
   * Sync candidate data to local database
   */
  async syncCandidateToDatabase(jambNumber: string) {
    try {
      // Fetch all candidate data
      const [candidate, scores, choices, olevelResults] = await Promise.all([
        this.getCandidateInfo(jambNumber),
        this.getUTMEScores(jambNumber),
        this.getCandidateChoices(jambNumber),
        this.getOLevelResults(jambNumber),
      ]);

      // Store in database (using repository pattern)
      const jambRecord = {
        jamb_registration_number: candidate.registration_number,
        candidate_name: candidate.candidate_name,
        date_of_birth: candidate.date_of_birth,
        gender: candidate.gender,
        state_of_origin: candidate.state_of_origin,
        lga: candidate.lga,
        utme_score: scores.total_score,
        utme_subjects: scores.subjects,
        first_choice_institution: choices.choices[0]?.institution_name,
        first_choice_course: choices.choices[0]?.course_name,
        sync_date: new Date(),
        raw_data: {
          candidate,
          scores,
          choices,
          olevelResults,
        },
      };

      // Save to database (implementation depends on ORM)
      // await this.jambRepository.upsert(jambRecord);

      this.logger.info(`Successfully synced candidate ${jambNumber} to database`);
      return jambRecord;
    } catch (error) {
      this.logger.error(`Failed to sync candidate ${jambNumber}`, error);
      throw error;
    }
  }

  /**
   * Validate that a candidate chose this institution
   */
  async validateInstitutionChoice(
    jambNumber: string,
    programCode: string
  ): Promise<boolean> {
    try {
      const choices = await this.getCandidateChoices(jambNumber);
      
      return choices.choices.some(
        (choice: any) =>
          choice.institution_code === this.config.institutionCode &&
          choice.course_code === programCode
      );
    } catch (error) {
      this.logger.error('Failed to validate institution choice', error);
      return false;
    }
  }
}
```

### 2. Scheduled Sync Job

```typescript
// backend/src/modules/integrations/jamb/JambSyncJob.ts

import cron from 'node-cron';
import { JambService } from './JambService';
import { Logger } from '../../../utils/logger';

export class JambSyncJob {
  private jambService: JambService;
  private logger: Logger;

  constructor(jambService: JambService) {
    this.jambService = jambService;
    this.logger = new Logger('JambSyncJob');
  }

  /**
   * Schedule daily sync at 2 AM
   */
  scheduleDailySync() {
    cron.schedule('0 2 * * *', async () => {
      this.logger.info('Starting scheduled JAMB sync');
      await this.runBulkSync();
    });
  }

  /**
   * Run bulk synchronization for all pending applications
   */
  async runBulkSync() {
    try {
      // Get current admission cycle
      const admissionCycle = await this.getActiveAdmissionCycle();
      
      // Get all programs' JAMB codes
      const programs = await this.getActivePrograms();
      const courseCodes = programs.map(p => p.jamb_code);

      // Fetch candidates in batches
      let page = 1;
      let hasMore = true;

      while (hasMore) {
        const result = await this.jambService.bulkFetchCandidates({
          courseCodes,
          examYear: admissionCycle.jamb_year,
          choiceNumber: 1,
          page,
          perPage: 100,
        });

        // Process each candidate
        for (const candidate of result.candidates) {
          try {
            await this.jambService.syncCandidateToDatabase(
              candidate.registration_number
            );
          } catch (error) {
            this.logger.error(
              `Failed to sync candidate ${candidate.registration_number}`,
              error
            );
          }
        }

        hasMore = page < result.pagination.total_pages;
        page++;
        
        // Add delay to avoid rate limiting
        await this.delay(1000);
      }

      this.logger.info('Bulk JAMB sync completed successfully');
    } catch (error) {
      this.logger.error('Bulk JAMB sync failed', error);
    }
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  private async getActiveAdmissionCycle() {
    // Implementation depends on your database layer
    throw new Error('Not implemented');
  }

  private async getActivePrograms() {
    // Implementation depends on your database layer
    throw new Error('Not implemented');
  }
}
```

## File-Based Integration (Fallback)

For situations where API access is unavailable, support CSV import:

### CSV Format Specification

```csv
jamb_registration_number,candidate_name,date_of_birth,gender,state_of_origin,lga,utme_score,math_score,english_score,physics_score,chemistry_score,first_choice_course
12345678AB,JOHN DOE,2005-03-15,M,Lagos,Ikeja,245,62,58,65,60,COMPUTER SCIENCE
```

### Import Function

```typescript
async importFromCSV(filePath: string) {
  const records = await this.parseCSV(filePath);
  
  for (const record of records) {
    await this.jambRepository.upsert({
      jamb_registration_number: record.jamb_registration_number,
      candidate_name: record.candidate_name,
      date_of_birth: record.date_of_birth,
      gender: record.gender,
      state_of_origin: record.state_of_origin,
      lga: record.lga,
      utme_score: parseInt(record.utme_score),
      utme_subjects: {
        Mathematics: parseInt(record.math_score),
        English: parseInt(record.english_score),
        Physics: parseInt(record.physics_score),
        Chemistry: parseInt(record.chemistry_score),
      },
      first_choice_course: record.first_choice_course,
    });
  }
}
```

## Error Handling & Retry Strategy

```typescript
class RetryStrategy {
  async executeWithRetry<T>(
    fn: () => Promise<T>,
    maxRetries: number = 3,
    delay: number = 1000
  ): Promise<T> {
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await fn();
      } catch (error: any) {
        if (attempt === maxRetries) throw error;
        
        // Don't retry on client errors (4xx)
        if (error.response?.status >= 400 && error.response?.status < 500) {
          throw error;
        }
        
        // Exponential backoff
        await this.delay(delay * Math.pow(2, attempt - 1));
      }
    }
    throw new Error('Max retries exceeded');
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}
```

## Data Validation

```typescript
class JambDataValidator {
  validateJambNumber(jambNumber: string): boolean {
    // JAMB number format: 8 digits + 2 letters
    const regex = /^\d{8}[A-Z]{2}$/;
    return regex.test(jambNumber);
  }

  validateUTMEScore(score: number): boolean {
    return score >= 0 && score <= 400;
  }

  validateSubjectScore(score: number): boolean {
    return score >= 0 && score <= 100;
  }

  validateOLevelGrade(grade: string): boolean {
    const validGrades = ['A1', 'B2', 'B3', 'C4', 'C5', 'C6', 'D7', 'E8', 'F9'];
    return validGrades.includes(grade);
  }
}
```

## Testing

```typescript
describe('JambService', () => {
  let jambService: JambService;
  
  beforeEach(() => {
    jambService = new JambService({
      apiUrl: 'https://api.jamb.gov.ng',
      clientId: 'test_client',
      clientSecret: 'test_secret',
      institutionCode: '0109',
    });
  });

  it('should fetch candidate information', async () => {
    const candidate = await jambService.getCandidateInfo('12345678AB');
    
    expect(candidate).toHaveProperty('registration_number');
    expect(candidate).toHaveProperty('candidate_name');
    expect(candidate.registration_number).toBe('12345678AB');
  });

  it('should cache candidate information', async () => {
    await jambService.getCandidateInfo('12345678AB');
    const cached = await jambService.getCandidateInfo('12345678AB');
    
    // Second call should be from cache (faster)
    expect(cached).toBeDefined();
  });

  it('should handle candidate not found', async () => {
    await expect(
      jambService.getCandidateInfo('00000000XX')
    ).rejects.toThrow('Candidate 00000000XX not found');
  });
});
```

## Monitoring & Logging

```typescript
// Log all JAMB API interactions
logger.info('JAMB API Request', {
  endpoint: '/v1/candidates/12345678AB',
  method: 'GET',
  timestamp: new Date().toISOString(),
});

logger.info('JAMB API Response', {
  status: 200,
  responseTime: '250ms',
  cached: false,
});

logger.error('JAMB API Error', {
  endpoint: '/v1/candidates/12345678AB',
  error: error.message,
  statusCode: error.response?.status,
});

// Track sync metrics
metrics.increment('jamb.sync.total');
metrics.increment('jamb.sync.success');
metrics.increment('jamb.sync.failed');
metrics.timing('jamb.sync.duration', duration);
```

## Security Considerations

1. **API Credentials**: Store in environment variables, never in code
2. **Token Management**: Implement secure token storage and refresh
3. **Data Encryption**: Encrypt sensitive candidate data at rest
4. **Access Logging**: Log all JAMB data access for audit
5. **Rate Limiting**: Respect JAMB API rate limits
6. **Error Messages**: Don't expose internal JAMB API errors to end users

## Compliance

- Ensure JAMB data usage complies with their terms of service
- Obtain necessary approvals from JAMB for data access
- Implement data retention policies as per JAMB requirements
- Regular security audits of JAMB integration

---

**Note**: This is a specification document. Actual JAMB API endpoints and authentication mechanisms would need to be confirmed with JAMB directly. If official API is not available, the file-based integration approach should be used.
