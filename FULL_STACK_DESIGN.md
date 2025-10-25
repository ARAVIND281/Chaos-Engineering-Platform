# Full-Stack Chaos Engineering Platform - Architecture Design

## Overview

Transform the existing Chaos Engineering Platform into a complete full-stack application with:
- **Frontend**: React-based dashboard for managing and monitoring chaos experiments
- **Backend**: Node.js/Express REST API for experiment orchestration
- **Database**: DynamoDB for storing experiment results and configurations
- **Authentication**: AWS Cognito for user management
- **Real-time Updates**: WebSocket support for live experiment monitoring
- **Monitoring**: Custom CloudWatch dashboards and metrics

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                           End Users                                  │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             │ HTTPS
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      CloudFront Distribution                         │
│                    (SSL/TLS, CDN, Caching)                          │
└────────────────────────────┬────────────────────────────────────────┘
                             │
        ┌────────────────────┴────────────────────┐
        │                                         │
        ▼                                         ▼
┌──────────────────┐                    ┌──────────────────┐
│   S3 Bucket      │                    │   API Gateway    │
│  (React SPA)     │                    │   (REST API)     │
│  - Dashboard     │                    │   - /experiments │
│  - Reports       │                    │   - /results     │
│  - Analytics     │                    │   - /health      │
└──────────────────┘                    └────────┬─────────┘
                                                 │
                             ┌───────────────────┼───────────────────┐
                             │                   │                   │
                             ▼                   ▼                   ▼
                    ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
                    │  Lambda: Auth   │ │ Lambda: Exp API │ │ Lambda: Results │
                    │  (Cognito)      │ │ (Orchestration) │ │ (Query/Report)  │
                    └─────────────────┘ └────────┬────────┘ └────────┬────────┘
                                                 │                   │
                             ┌───────────────────┼───────────────────┘
                             │                   │
                             ▼                   ▼
                    ┌─────────────────┐ ┌─────────────────┐
                    │  DynamoDB       │ │  Step Functions │
                    │  - Experiments  │ │  (Chaos Workflow)│
                    │  - Results      │ │                 │
                    │  - Users        │ │  ┌──────────────┤
                    └─────────────────┘ │  │ Lambda: Get  │
                                        │  │ Lambda: Inject│
                                        │  │ Lambda: Valid │
                                        └──┴──────────────┘
                                                 │
                             ┌───────────────────┴───────────────────┐
                             │                                       │
                             ▼                                       ▼
                    ┌─────────────────┐                    ┌─────────────────┐
                    │  Target App     │                    │   CloudWatch    │
                    │  (EC2 + ALB)    │                    │  (Metrics/Logs) │
                    │  Auto Scaling   │                    │   SNS Alerts    │
                    └─────────────────┘                    └─────────────────┘
```

---

## Technology Stack

### Frontend (React SPA)
- **Framework**: React 18 with TypeScript
- **State Management**: Redux Toolkit + RTK Query
- **UI Library**: Material-UI (MUI) v5
- **Charts**: Recharts for data visualization
- **Authentication**: AWS Amplify (Cognito integration)
- **Real-time**: AWS IoT Core / AppSync for WebSocket
- **Build Tool**: Vite
- **Hosting**: S3 + CloudFront

### Backend (Node.js API)
- **Runtime**: Node.js 20.x
- **Framework**: Express.js
- **Language**: TypeScript
- **API Documentation**: OpenAPI/Swagger
- **Authentication**: JWT tokens via Cognito
- **Deployment**: Lambda + API Gateway
- **Testing**: Jest + Supertest

### Database
- **Primary**: DynamoDB
  - Experiments table (partition: experimentId)
  - Results table (partition: experimentId, sort: timestamp)
  - Users table (partition: userId)
- **Caching**: ElastiCache Redis (optional)

### Infrastructure
- **IaC**: AWS CloudFormation (SAM)
- **CI/CD**: GitHub Actions / AWS CodePipeline
- **Monitoring**: CloudWatch + X-Ray
- **Secrets**: AWS Secrets Manager

---

## Application Features

### 1. Frontend Dashboard

#### Home Page
- Overview of system health
- Recent experiment history
- Quick actions (Run experiment, View reports)
- Real-time status indicators

#### Experiments Page
- List all past experiments
- Filter by date, status, target
- Pagination and search
- Experiment details modal

#### Run Experiment Page
- Form to configure new experiment
- Target selection (ASG, specific instances)
- Dry run toggle
- Schedule future experiments
- Real-time execution monitoring

#### Results & Analytics Page
- Experiment success/failure rates
- System recovery time charts
- Incident timeline
- Downloadable reports (CSV, PDF)

#### Settings Page
- User profile management
- Notification preferences
- API key management
- System configuration

### 2. Backend API Endpoints

#### Authentication
```
POST   /api/v1/auth/login           - User login
POST   /api/v1/auth/logout          - User logout
POST   /api/v1/auth/refresh         - Refresh JWT token
GET    /api/v1/auth/user            - Get current user
```

#### Experiments
```
GET    /api/v1/experiments          - List all experiments
POST   /api/v1/experiments          - Create/start new experiment
GET    /api/v1/experiments/:id      - Get experiment details
DELETE /api/v1/experiments/:id      - Delete experiment
POST   /api/v1/experiments/:id/stop - Stop running experiment
```

#### Results
```
GET    /api/v1/results              - List all results (paginated)
GET    /api/v1/results/:id          - Get specific result
GET    /api/v1/results/analytics    - Get analytics data
GET    /api/v1/results/export       - Export results (CSV/JSON)
```

#### System Health
```
GET    /api/v1/health               - API health check
GET    /api/v1/health/targets       - Target system health
GET    /api/v1/metrics              - CloudWatch metrics
```

#### Configuration
```
GET    /api/v1/config               - Get system configuration
PUT    /api/v1/config               - Update configuration
GET    /api/v1/targets              - List available targets
```

### 3. Database Schema

#### Experiments Table (DynamoDB)
```json
{
  "experimentId": "exp-2024-01-15-abc123",      // Partition Key
  "userId": "user-123",
  "status": "RUNNING | COMPLETED | FAILED",
  "targetType": "AUTO_SCALING_GROUP",
  "targetId": "chaos-target-asg",
  "configuration": {
    "dryRun": false,
    "expectedHealthyInstances": 2,
    "failureType": "INSTANCE_TERMINATION"
  },
  "startTime": "2024-01-15T10:30:00Z",
  "endTime": "2024-01-15T10:35:00Z",
  "duration": 300,
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-15T10:35:00Z"
}
```

#### Results Table (DynamoDB)
```json
{
  "resultId": "res-2024-01-15-xyz789",         // Partition Key
  "experimentId": "exp-2024-01-15-abc123",     // GSI Partition Key
  "timestamp": "2024-01-15T10:35:00Z",         // Sort Key
  "success": true,
  "targetInstance": "i-0abc123def456",
  "recoveryTime": 125,
  "metricsSnapshot": {
    "healthyHostCount": 2,
    "responseTime": 45,
    "errorRate": 0
  },
  "stepFunctionOutput": { ... },
  "logs": [ ... ]
}
```

#### Users Table (DynamoDB)
```json
{
  "userId": "user-123",                        // Partition Key (Cognito sub)
  "email": "user@example.com",
  "name": "John Doe",
  "role": "ADMIN | OPERATOR | VIEWER",
  "preferences": {
    "notifications": true,
    "emailAlerts": true
  },
  "apiKey": "encrypted-api-key",
  "createdAt": "2024-01-01T00:00:00Z",
  "lastLogin": "2024-01-15T10:00:00Z"
}
```

---

## Project Structure

```
chaos-engineering-platform/
├── frontend/                          # React application
│   ├── public/
│   │   └── index.html
│   ├── src/
│   │   ├── components/
│   │   │   ├── Dashboard/
│   │   │   │   ├── SystemHealth.tsx
│   │   │   │   ├── RecentExperiments.tsx
│   │   │   │   └── QuickActions.tsx
│   │   │   ├── Experiments/
│   │   │   │   ├── ExperimentList.tsx
│   │   │   │   ├── ExperimentDetails.tsx
│   │   │   │   └── CreateExperiment.tsx
│   │   │   ├── Results/
│   │   │   │   ├── ResultsTable.tsx
│   │   │   │   ├── AnalyticsCharts.tsx
│   │   │   │   └── ExportResults.tsx
│   │   │   ├── Layout/
│   │   │   │   ├── Header.tsx
│   │   │   │   ├── Sidebar.tsx
│   │   │   │   └── Footer.tsx
│   │   │   └── Common/
│   │   │       ├── LoadingSpinner.tsx
│   │   │       ├── ErrorBoundary.tsx
│   │   │       └── ProtectedRoute.tsx
│   │   ├── pages/
│   │   │   ├── HomePage.tsx
│   │   │   ├── ExperimentsPage.tsx
│   │   │   ├── ResultsPage.tsx
│   │   │   ├── LoginPage.tsx
│   │   │   └── SettingsPage.tsx
│   │   ├── store/
│   │   │   ├── store.ts
│   │   │   ├── slices/
│   │   │   │   ├── authSlice.ts
│   │   │   │   ├── experimentsSlice.ts
│   │   │   │   └── resultsSlice.ts
│   │   │   └── api/
│   │   │       └── chaosApi.ts          # RTK Query API
│   │   ├── services/
│   │   │   ├── api.ts                   # Axios instance
│   │   │   ├── auth.ts                  # Cognito integration
│   │   │   └── websocket.ts             # Real-time updates
│   │   ├── hooks/
│   │   │   ├── useAuth.ts
│   │   │   ├── useExperiments.ts
│   │   │   └── useRealtime.ts
│   │   ├── utils/
│   │   │   ├── formatters.ts
│   │   │   ├── validators.ts
│   │   │   └── constants.ts
│   │   ├── types/
│   │   │   ├── experiment.ts
│   │   │   ├── result.ts
│   │   │   └── user.ts
│   │   ├── App.tsx
│   │   ├── main.tsx
│   │   └── vite-env.d.ts
│   ├── package.json
│   ├── tsconfig.json
│   ├── vite.config.ts
│   └── .env.example
│
├── backend/                           # Node.js API
│   ├── src/
│   │   ├── handlers/                  # Lambda function handlers
│   │   │   ├── auth/
│   │   │   │   ├── login.ts
│   │   │   │   ├── logout.ts
│   │   │   │   └── refresh.ts
│   │   │   ├── experiments/
│   │   │   │   ├── create.ts
│   │   │   │   ├── list.ts
│   │   │   │   ├── get.ts
│   │   │   │   └── delete.ts
│   │   │   ├── results/
│   │   │   │   ├── list.ts
│   │   │   │   ├── get.ts
│   │   │   │   ├── analytics.ts
│   │   │   │   └── export.ts
│   │   │   └── health/
│   │   │       ├── api.ts
│   │   │       ├── targets.ts
│   │   │       └── metrics.ts
│   │   ├── services/
│   │   │   ├── dynamodb.service.ts
│   │   │   ├── stepfunctions.service.ts
│   │   │   ├── cloudwatch.service.ts
│   │   │   ├── cognito.service.ts
│   │   │   └── sns.service.ts
│   │   ├── middleware/
│   │   │   ├── auth.middleware.ts
│   │   │   ├── error.middleware.ts
│   │   │   ├── validation.middleware.ts
│   │   │   └── logging.middleware.ts
│   │   ├── models/
│   │   │   ├── Experiment.ts
│   │   │   ├── Result.ts
│   │   │   └── User.ts
│   │   ├── utils/
│   │   │   ├── response.ts
│   │   │   ├── logger.ts
│   │   │   └── validators.ts
│   │   ├── types/
│   │   │   ├── api.types.ts
│   │   │   └── aws.types.ts
│   │   └── config/
│   │       ├── aws.config.ts
│   │       └── app.config.ts
│   ├── tests/
│   │   ├── unit/
│   │   └── integration/
│   ├── package.json
│   ├── tsconfig.json
│   └── .env.example
│
├── infrastructure/                    # CloudFormation templates
│   ├── vpc-infrastructure.yaml        # Existing
│   ├── target-application.yaml        # Existing
│   ├── chaos-lambda-functions.yaml    # Existing
│   ├── chaos-step-functions.yaml      # Existing
│   ├── fullstack-frontend.yaml        # NEW: S3 + CloudFront
│   ├── fullstack-backend.yaml         # NEW: API Gateway + Lambda
│   ├── fullstack-database.yaml        # NEW: DynamoDB tables
│   ├── fullstack-auth.yaml            # NEW: Cognito User Pool
│   └── fullstack-cicd.yaml            # NEW: CodePipeline
│
├── lambda-functions/                  # Existing chaos functions
│   ├── get-target-instance/
│   ├── inject-failure/
│   └── validate-system-health/
│
├── step-functions/                    # Existing
│   └── chaos-experiment-workflow.json
│
├── scripts/
│   ├── deploy.sh                      # Updated for full-stack
│   ├── deploy-frontend.sh             # NEW
│   ├── deploy-backend.sh              # NEW
│   ├── deploy-fullstack.sh            # NEW: Deploy everything
│   ├── build-frontend.sh              # NEW
│   ├── build-backend.sh               # NEW
│   ├── test-fullstack.sh              # NEW: E2E tests
│   └── cleanup.sh                     # Updated for full-stack
│
├── docs/
│   ├── FULL_STACK_DESIGN.md           # This file
│   ├── API_DOCUMENTATION.md           # NEW: API docs
│   ├── FRONTEND_GUIDE.md              # NEW: Frontend setup
│   ├── BACKEND_GUIDE.md               # NEW: Backend setup
│   ├── DEPLOYMENT_GUIDE.md            # NEW: Full deployment
│   └── ... (existing docs)
│
├── .github/
│   └── workflows/
│       ├── frontend-ci.yml
│       ├── backend-ci.yml
│       └── deploy.yml
│
├── README.md                          # Updated
├── QUICKSTART.md                      # Updated
└── package.json                       # Root monorepo config
```

---

## Implementation Plan (Weeks 5-8)

### Week 5: Frontend Development
**Goal**: Build React dashboard with all core features

**Tasks**:
1. Initialize React + TypeScript + Vite project
2. Set up Material-UI and project structure
3. Implement authentication with AWS Amplify
4. Create main dashboard with system health overview
5. Build experiments list and detail views
6. Implement create experiment form
7. Add results and analytics pages
8. Set up routing and navigation
9. Write unit tests for components
10. Deploy to S3 + CloudFront

**Deliverables**:
- Working React application
- CloudFormation template for S3 + CloudFront
- Deployment script
- Frontend documentation

### Week 6: Backend API Development
**Goal**: Build Node.js REST API with all endpoints

**Tasks**:
1. Initialize Node.js + TypeScript + Express project
2. Set up Lambda function handlers with API Gateway
3. Implement authentication middleware (Cognito JWT)
4. Create CRUD endpoints for experiments
5. Create query endpoints for results
6. Implement Step Functions integration
7. Add CloudWatch metrics collection
8. Write comprehensive API tests
9. Generate OpenAPI documentation
10. Deploy with SAM/CloudFormation

**Deliverables**:
- REST API with all endpoints
- CloudFormation template for API Gateway + Lambda
- API documentation (Swagger)
- Deployment script
- Backend documentation

### Week 7: Database & Integration
**Goal**: Set up database and integrate frontend/backend

**Tasks**:
1. Design DynamoDB table schemas
2. Create CloudFormation template for DynamoDB
3. Implement data access layer
4. Add GSIs for efficient querying
5. Integrate Step Functions with DynamoDB
6. Connect frontend to backend API
7. Implement real-time updates (AppSync/IoT Core)
8. Add error handling and retry logic
9. Set up CloudWatch dashboards
10. Write integration tests

**Deliverables**:
- DynamoDB tables with proper indexes
- Complete frontend-backend integration
- Real-time monitoring
- Integration tests
- Updated documentation

### Week 8: Authentication, CI/CD & Polish
**Goal**: Production-ready full-stack application

**Tasks**:
1. Set up Cognito User Pool and Identity Pool
2. Implement user registration and login flows
3. Add role-based access control (RBAC)
4. Create CI/CD pipeline (GitHub Actions/CodePipeline)
5. Set up automated testing in pipeline
6. Add monitoring and alerting (SNS)
7. Implement error tracking (CloudWatch Insights)
8. Performance optimization
9. Security hardening
10. Complete end-to-end testing

**Deliverables**:
- Complete authentication system
- Automated CI/CD pipeline
- Production monitoring setup
- Final project documentation
- Presentation materials

---

## Enhanced Features

### 1. Real-time Monitoring
- WebSocket connection for live experiment updates
- Server-Sent Events (SSE) for notifications
- Live metrics streaming from CloudWatch

### 2. Advanced Analytics
- Success/failure rate trends
- Mean time to recovery (MTTR)
- System availability percentages
- Incident correlation analysis

### 3. Notification System
- Email alerts via SNS
- In-app notifications
- Slack/Teams integration
- PagerDuty integration

### 4. Experiment Templates
- Pre-configured experiment templates
- Custom experiment builder
- Scheduled recurring experiments
- Experiment versioning

### 5. Multi-tenancy
- Organization support
- Team management
- User roles and permissions
- Resource quotas

### 6. Audit Logging
- Complete audit trail
- User action tracking
- Compliance reports
- GDPR compliance

---

## Security Considerations

### Authentication & Authorization
- AWS Cognito for user management
- JWT tokens with short expiration
- Refresh token rotation
- MFA support
- Role-based access control (RBAC)

### API Security
- API Gateway with request validation
- Rate limiting and throttling
- CORS configuration
- Request/response encryption
- API key rotation

### Data Security
- Encryption at rest (DynamoDB)
- Encryption in transit (TLS 1.3)
- Secrets in AWS Secrets Manager
- IAM least privilege policies
- VPC endpoints for private connectivity

### Frontend Security
- Content Security Policy (CSP)
- XSS protection
- CSRF tokens
- Secure cookie settings
- Dependency scanning

---

## Cost Estimate (Full-Stack)

### Monthly Costs (24/7 operation)

**Existing Infrastructure:**
- EC2 instances (2x t3.micro): $12
- Application Load Balancer: $16
- NAT Gateways (2): $64
- Lambda (chaos functions): <$1
- Step Functions: <$1

**New Full-Stack Components:**
- **Frontend Hosting**:
  - S3 storage (5 GB): $0.12
  - CloudFront (100 GB transfer): $8.50
- **Backend API**:
  - API Gateway (1M requests): $3.50
  - Lambda (backend functions): $5
- **Database**:
  - DynamoDB (On-demand, ~1M reads/writes): $1.50
- **Authentication**:
  - Cognito (10K MAU): Free (under 50K)
- **Monitoring**:
  - CloudWatch (extended metrics): $3
- **Data Transfer**: $5

**Total Monthly Cost: ~$119/month** (24/7 operation)

**Development/Testing**: ~$20-30/month (with cleanup)

---

## Success Metrics

### Technical Metrics
- API response time < 200ms (p95)
- Frontend load time < 2s
- 99.9% API availability
- Zero security vulnerabilities
- 80%+ test coverage

### Business Metrics
- Experiment execution success rate > 95%
- Mean time to recovery (MTTR) tracking
- User adoption rate
- System availability improvement

---

## Next Steps

1. **Review this design** with your team
2. **Choose implementation approach**:
   - Option A: Build Week 5-8 in sequence
   - Option B: Incremental additions to existing platform
   - Option C: Parallel development (frontend + backend)
3. **Set up development environment**
4. **Begin Week 5 implementation**

---

## Questions to Consider

1. **User Base**: How many users will use this platform?
2. **Authentication**: Do you need SSO/SAML integration?
3. **Multi-region**: Do you need global deployment?
4. **Compliance**: Any specific compliance requirements (HIPAA, SOC2)?
5. **Integration**: Need to integrate with existing systems?
6. **Customization**: How much customization do users need?

---

**Ready to build the full-stack application?** Let me know and I'll start with Week 5!
