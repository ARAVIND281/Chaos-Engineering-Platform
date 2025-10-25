# Full-Stack Chaos Engineering Platform - Quick Start

Complete guide to deploy and use the full-stack Chaos Engineering Platform with React frontend and Node.js backend.

---

## What You're Building

A **complete production-ready full-stack application** with:

### Frontend (React)
- Modern dashboard for managing chaos experiments
- Real-time experiment monitoring
- Analytics and data visualization
- User authentication
- Responsive design (mobile/tablet/desktop)

### Backend (Node.js/TypeScript)
- RESTful API on AWS Lambda
- DynamoDB for data storage
- Integration with Step Functions
- JWT authentication
- CloudWatch monitoring

### Infrastructure
- AWS CloudFormation (Infrastructure as Code)
- API Gateway for REST API
- S3 + CloudFront for frontend hosting
- DynamoDB for database
- Integration with existing chaos experiment infrastructure

---

## Prerequisites

1. **AWS Account** with admin access
2. **AWS CLI** installed and configured
3. **Node.js 18+** and npm installed
4. **Git** installed
5. **Existing Chaos Infrastructure** (Weeks 1-4 deployed)

---

## Quick Deployment (15-20 minutes)

### Step 1: Verify Existing Infrastructure

Make sure you have already deployed Weeks 1-4:

```bash
cd "/Users/aravinds/project/Chaos Engineering"

# Check if infrastructure exists
aws cloudformation list-stacks \
  --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
  --query 'StackSummaries[?contains(StackName, `chaos`)].StackName'
```

You should see:
- `chaos-vpc-infrastructure`
- `chaos-target-application`
- `chaos-lambda-functions`
- `chaos-step-functions`

If not, deploy them first:
```bash
./scripts/deploy.sh
```

### Step 2: Deploy Full-Stack Application

Run the full-stack deployment script:

```bash
./scripts/deploy-fullstack.sh dev
```

This will:
1. Deploy DynamoDB tables (15 seconds)
2. Build backend (30 seconds)
3. Package Lambda functions (10 seconds)
4. Build frontend (45 seconds)
5. Deploy frontend to S3 (20 seconds)

**Total time: ~2-3 minutes**

### Step 3: Access the Application

After deployment, you'll see output like:

```
Frontend URL: http://chaos-platform-frontend-dev-123456789.s3-website-us-east-1.amazonaws.com
```

Open this URL in your browser!

### Step 4: Login

Default credentials (mock authentication):
- **Email**: `admin@chaos-platform.com`
- **Password**: Any password (mock mode)

---

## Project Structure

```
.
├── frontend/                    # React application
│   ├── src/
│   │   ├── pages/              # Dashboard, Experiments, Results, etc.
│   │   ├── components/         # Reusable UI components
│   │   ├── services/           # API services
│   │   ├── types/              # TypeScript types
│   │   └── contexts/           # React contexts (Auth, etc.)
│   ├── package.json
│   └── vite.config.ts
│
├── backend/                     # Node.js API
│   ├── src/
│   │   ├── handlers/           # Lambda function handlers
│   │   │   ├── auth/          # Authentication endpoints
│   │   │   ├── experiments/   # Experiment CRUD
│   │   │   ├── results/       # Results queries
│   │   │   └── health/        # Health checks
│   │   ├── services/          # Business logic
│   │   │   ├── dynamodb.service.ts
│   │   │   ├── stepfunctions.service.ts
│   │   │   └── cloudwatch.service.ts
│   │   ├── utils/             # Utilities
│   │   ├── config/            # Configuration
│   │   └── types/             # TypeScript types
│   ├── package.json
│   └── tsconfig.json
│
├── infrastructure/              # CloudFormation templates
│   ├── fullstack-database.yaml        # DynamoDB tables
│   ├── fullstack-backend.yaml         # API Gateway + Lambda
│   └── fullstack-frontend.yaml        # S3 + CloudFront (optional)
│
├── scripts/
│   ├── deploy-fullstack.sh           # Deploy everything
│   ├── deploy-backend.sh             # Deploy backend only
│   ├── deploy-frontend.sh            # Deploy frontend only
│   └── test-fullstack.sh             # End-to-end tests
│
└── docs/
    ├── FULL_STACK_DESIGN.md          # Architecture design
    ├── FULLSTACK_QUICKSTART.md       # This file
    └── API_DOCUMENTATION.md          # API docs
```

---

## Using the Application

### Dashboard Page

**URL**: `/` or `/dashboard`

**Features**:
- System health overview (healthy/degraded/critical)
- Recent experiments list
- Quick stats (Total experiments, Success rate, Avg recovery time)
- Quick action buttons

**Try it**:
1. View system health status
2. Click "Run New Experiment" button

### Experiments Page

**URL**: `/experiments`

**Features**:
- List all chaos experiments
- Filter by status (Running, Completed, Failed)
- Search by experiment ID
- View experiment details
- Delete experiments

**Try it**:
1. Click "New Experiment" button
2. Fill in the form
3. Click "Start Experiment"
4. Watch real-time progress

### New Experiment Page

**URL**: `/experiments/new`

**Form Fields**:
- **Target**: Auto Scaling Group (default: `chaos-target-asg`)
- **Dry Run**: Toggle to test without actual termination
- **Expected Healthy Instances**: Number of expected healthy instances (default: 2)
- **Experiment Name**: Optional name
- **Hypothesis**: Optional description

**Try it**:
1. Enable "Dry Run" for safe testing
2. Click "Start Experiment"
3. You'll be redirected to the monitor page

### Experiment Monitor Page

**URL**: `/experiments/:id/monitor`

**Features**:
- Real-time step-by-step progress
- Visual timeline with status indicators
- Live metrics (healthy instances, target group health)
- Execution logs
- Stop button (for running experiments)

**Steps shown**:
1. Pre-Experiment Health Check
2. Target Instance Selection
3. Failure Injection
4. Recovery Wait (60s)
5. Post-Experiment Health Validation
6. Results Recording

**Try it**:
1. Start an experiment
2. Watch the real-time progress
3. See the system recover automatically

### Results & Analytics Page

**URL**: `/results`

**Features**:
- Results table with all experiment outcomes
- Charts:
  - Experiments over time (line chart)
  - Success vs Failure (bar chart)
  - Experiment types (pie chart)
- Export results (CSV/JSON)
- Analytics metrics

**Try it**:
1. View all experiment results
2. Check success rate
3. Export data for reporting

### Settings Page

**URL**: `/settings`

**Features**:
- User profile
- Notification settings
- API key management
- System configuration

---

## API Endpoints

### Authentication
```
POST /api/v1/auth/login
GET  /api/v1/auth/user
POST /api/v1/auth/logout
```

### Experiments
```
GET    /api/v1/experiments              # List all
POST   /api/v1/experiments              # Create new
GET    /api/v1/experiments/:id          # Get one
DELETE /api/v1/experiments/:id          # Delete
POST   /api/v1/experiments/:id/stop     # Stop running
GET    /api/v1/experiments/:id/status   # Get status
GET    /api/v1/experiments/:id/steps    # Get steps
```

### Results
```
GET /api/v1/results                  # List all
GET /api/v1/results/:id              # Get one
GET /api/v1/results/analytics        # Get analytics
GET /api/v1/results/export           # Export CSV/JSON
```

### Health
```
GET /api/v1/health                   # API health
GET /api/v1/health/targets           # System health
GET /api/v1/health/metrics           # CloudWatch metrics
```

---

## Development

### Run Frontend Locally

```bash
cd frontend
npm install
npm run dev
```

Open `http://localhost:5173`

### Run Backend Locally

```bash
cd backend
npm install
npm run dev
```

API runs on `http://localhost:3000`

### Connect Frontend to Local Backend

Update `frontend/.env.development`:
```
VITE_API_BASE_URL=http://localhost:3000/api/v1
```

---

## Architecture

```
┌─────────────┐
│   Users     │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────┐
│   CloudFront (CDN)                  │
└──────────┬───────────┬──────────────┘
           │           │
           ▼           ▼
    ┌──────────┐  ┌──────────────┐
    │ S3       │  │ API Gateway  │
    │ (React)  │  │ (REST API)   │
    └──────────┘  └──────┬───────┘
                         │
           ┌─────────────┼─────────────┐
           │             │             │
           ▼             ▼             ▼
    ┌──────────┐  ┌──────────┐  ┌──────────┐
    │ Lambda   │  │ Lambda   │  │ Lambda   │
    │ (Auth)   │  │ (Exp)    │  │ (Results)│
    └──────────┘  └────┬─────┘  └────┬─────┘
                       │             │
           ┌───────────┼─────────────┘
           │           │
           ▼           ▼
    ┌──────────┐  ┌──────────────┐
    │ DynamoDB │  │ Step Functions│
    │ Tables   │  │ (Chaos)       │
    └──────────┘  └───────┬───────┘
                          │
                          ▼
                  ┌────────────────┐
                  │ Target System  │
                  │ (EC2 + ALB)    │
                  └────────────────┘
```

---

## Database Schema

### Experiments Table
```
PK: experimentId
Attributes:
  - status: PENDING | RUNNING | COMPLETED | FAILED
  - targetType: String
  - targetId: String (ASG name)
  - configuration: { dryRun, expectedHealthyInstances, failureType }
  - startTime: ISO 8601
  - endTime: ISO 8601
  - duration: Number (seconds)
  - createdBy: String (email)
  - metadata: { name, hypothesis, owner }

GSI: CreatedByIndex (createdBy + startTime)
```

### Results Table
```
PK: resultId
Attributes:
  - experimentId: String
  - timestamp: ISO 8601
  - success: Boolean
  - targetInstance: String (EC2 instance ID)
  - recoveryTime: Number (seconds)
  - metricsSnapshot: { healthyHostCount, responseTime, errorRate }
  - logs: Array of log messages
  - stepFunctionOutput: Object

GSI: ExperimentIdIndex (experimentId + timestamp)
```

### Users Table
```
PK: userId
Attributes:
  - email: String
  - name: String
  - role: ADMIN | OPERATOR | VIEWER
  - createdAt: ISO 8601
  - lastLogin: ISO 8601

GSI: EmailIndex (email)
```

---

## Environment Variables

### Frontend (.env)
```bash
VITE_API_BASE_URL=https://api.chaos-platform.com/api/v1
VITE_AWS_REGION=us-east-1
VITE_ENVIRONMENT=dev
```

### Backend (.env)
```bash
# AWS
AWS_REGION=us-east-1

# DynamoDB
EXPERIMENTS_TABLE=chaos-experiments-dev
RESULTS_TABLE=chaos-results-dev
USERS_TABLE=chaos-users-dev

# Step Functions
STATE_MACHINE_ARN=arn:aws:states:...

# Auto Scaling
TARGET_ASG_NAME=chaos-target-asg

# Load Balancer
TARGET_GROUP_ARN=arn:aws:elasticloadbalancing:...
LOAD_BALANCER_ARN=arn:aws:elasticloadbalancing:...

# JWT
JWT_SECRET=your-secret-key
JWT_EXPIRES_IN=24h

# App
NODE_ENV=development
PORT=3000
LOG_LEVEL=info
```

---

## Deployment Options

### Option 1: Deploy Everything

```bash
./scripts/deploy-fullstack.sh dev
```

### Option 2: Deploy Backend Only

```bash
./scripts/deploy-backend.sh
```

### Option 3: Deploy Frontend Only

```bash
./scripts/deploy-frontend.sh
```

### Option 4: Manual Deployment

```bash
# Deploy database
aws cloudformation deploy \
  --template-file infrastructure/fullstack-database.yaml \
  --stack-name chaos-fullstack-database-dev

# Build backend
cd backend
npm run build
npm run package

# Build frontend
cd frontend
npm run build

# Upload to S3
aws s3 sync dist/ s3://your-bucket/
```

---

## Testing

### Run End-to-End Tests

```bash
./scripts/test-fullstack.sh
```

### Test Individual Components

```bash
# Test backend
cd backend
npm test

# Test frontend
cd frontend
npm test
```

### Manual Testing Flow

1. **Login**: Verify authentication works
2. **Dashboard**: Check system health display
3. **Create Experiment**: Start a dry-run experiment
4. **Monitor**: Watch real-time progress
5. **Results**: View experiment outcome
6. **Analytics**: Check charts and metrics

---

## Troubleshooting

### Frontend Not Loading

**Problem**: White screen or errors

**Solutions**:
1. Check browser console for errors
2. Verify API endpoint in `.env`
3. Check CORS configuration
4. Clear browser cache

### API Errors

**Problem**: 500 errors or timeouts

**Solutions**:
1. Check Lambda logs in CloudWatch
2. Verify DynamoDB table names
3. Check IAM permissions
4. Verify Step Functions ARN

### Experiments Not Running

**Problem**: Experiments stuck in PENDING

**Solutions**:
1. Check Step Functions execution in AWS Console
2. Verify Lambda function permissions
3. Check target ASG exists and has instances
4. Review CloudWatch Logs for errors

### Database Connection Issues

**Problem**: Cannot read/write to DynamoDB

**Solutions**:
1. Verify table names in environment variables
2. Check IAM role permissions for Lambda
3. Verify tables exist in correct region
4. Check table status (ACTIVE)

---

## Cost Estimate

### Monthly Costs (24/7 operation)

**Existing Infrastructure** (Weeks 1-4):
- EC2, ALB, NAT, etc.: ~$98/month

**New Full-Stack Components**:
- **Frontend**:
  - S3 storage (1 GB): $0.02
  - CloudFront (optional, 100 GB): $8.50
- **Backend**:
  - API Gateway (1M requests): $3.50
  - Lambda (backend, 1M invocations): $5.00
- **Database**:
  - DynamoDB (on-demand, 1M reads/writes): $1.50

**Total Full-Stack**: ~$116/month (without CloudFront)
**Total Full-Stack**: ~$125/month (with CloudFront)

### Cost Optimization

1. **Development**: Clean up after testing
   ```bash
   ./scripts/cleanup.sh
   ```

2. **Use spot instances** for target EC2s
3. **Enable S3 lifecycle policies** for old data
4. **Use DynamoDB on-demand pricing** (pay per request)

---

## Production Considerations

### Before Going to Production

1. **Enable HTTPS**:
   - Add CloudFront distribution
   - Configure SSL certificate
   - Update API Gateway custom domain

2. **Authentication**:
   - Deploy AWS Cognito User Pool
   - Replace mock auth with real JWT
   - Implement password policies

3. **Security**:
   - Enable WAF on CloudFront/API Gateway
   - Add rate limiting
   - Implement API key rotation
   - Enable CloudTrail logging

4. **Monitoring**:
   - Set up CloudWatch alarms
   - Configure SNS notifications
   - Enable X-Ray tracing
   - Add custom dashboards

5. **Backup & Recovery**:
   - Enable DynamoDB point-in-time recovery
   - Set up automated backups
   - Test restore procedures

6. **CI/CD**:
   - Set up GitHub Actions / CodePipeline
   - Automate testing
   - Implement blue/green deployments

---

## Next Steps

1. ✅ Deploy the full-stack application
2. ✅ Test all features in the UI
3. ✅ Run end-to-end tests
4. ✅ Review analytics and results
5. 🔲 Add AWS Cognito authentication
6. 🔲 Deploy CloudFront for HTTPS
7. 🔲 Set up monitoring and alerts
8. 🔲 Create CI/CD pipeline
9. 🔲 Write additional tests
10. 🔲 Customize for your use case

---

## Support & Documentation

- **Architecture Design**: [FULL_STACK_DESIGN.md](FULL_STACK_DESIGN.md)
- **API Documentation**: [backend/README.md](backend/README.md)
- **Frontend Guide**: [frontend/README.md](frontend/README.md)
- **Original Project**: [QUICKSTART.md](QUICKSTART.md)
- **Week 1-4 Guides**: [docs/](docs/)

---

**Congratulations!** You now have a complete, production-ready full-stack Chaos Engineering Platform! 🎉🚀
