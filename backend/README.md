# Chaos Engineering Platform - Backend API

Node.js/TypeScript REST API backend for the Chaos Engineering Platform, deployed on AWS Lambda + API Gateway.

## Architecture

```
API Gateway → Lambda Functions → DynamoDB
                              → Step Functions
                              → CloudWatch
                              → Auto Scaling
                              → Load Balancer
```

## Tech Stack

- **Runtime**: Node.js 20.x
- **Language**: TypeScript
- **Framework**: AWS Lambda (Serverless)
- **Database**: DynamoDB
- **Authentication**: JWT + AWS Cognito
- **Infrastructure**: AWS CloudFormation

## Project Structure

```
backend/
├── src/
│   ├── handlers/              # Lambda function handlers
│   │   ├── auth/             # Authentication endpoints
│   │   ├── experiments/      # Experiment CRUD
│   │   ├── results/          # Results queries
│   │   └── health/           # Health checks
│   ├── services/             # Business logic
│   │   ├── dynamodb.service.ts
│   │   ├── stepfunctions.service.ts
│   │   └── cloudwatch.service.ts
│   ├── middleware/           # Express middleware
│   ├── models/               # Data models
│   ├── utils/                # Utilities
│   ├── config/               # Configuration
│   └── types/                # TypeScript types
├── package.json
├── tsconfig.json
└── README.md
```

## API Endpoints

### Authentication
- `POST /api/v1/auth/login` - User login
- `POST /api/v1/auth/logout` - User logout
- `GET /api/v1/auth/user` - Get current user

### Experiments
- `GET /api/v1/experiments` - List experiments
- `POST /api/v1/experiments` - Create/start experiment
- `GET /api/v1/experiments/:id` - Get experiment details
- `DELETE /api/v1/experiments/:id` - Delete experiment
- `POST /api/v1/experiments/:id/stop` - Stop experiment
- `GET /api/v1/experiments/:id/status` - Get real-time status
- `GET /api/v1/experiments/:id/steps` - Get execution steps

### Results
- `GET /api/v1/results` - List results
- `GET /api/v1/results/:id` - Get result details
- `GET /api/v1/results/analytics` - Get analytics
- `GET /api/v1/results/export` - Export results (CSV/JSON)

### Health
- `GET /api/v1/health` - API health check
- `GET /api/v1/health/targets` - Target system health
- `GET /api/v1/health/metrics` - CloudWatch metrics

## Environment Variables

Create a `.env` file:

```bash
# AWS Configuration
AWS_REGION=us-east-1

# DynamoDB Tables
EXPERIMENTS_TABLE=chaos-experiments
RESULTS_TABLE=chaos-results
USERS_TABLE=chaos-users

# Step Functions
STATE_MACHINE_ARN=arn:aws:states:us-east-1:ACCOUNT:stateMachine:chaos-experiment-workflow

# Auto Scaling
TARGET_ASG_NAME=chaos-target-asg

# Load Balancer
TARGET_GROUP_ARN=arn:aws:elasticloadbalancing:us-east-1:ACCOUNT:targetgroup/...
LOAD_BALANCER_ARN=arn:aws:elasticloadbalancing:us-east-1:ACCOUNT:loadbalancer/...

# Cognito
COGNITO_USER_POOL_ID=us-east-1_XXXXXXXXX
COGNITO_CLIENT_ID=xxxxxxxxxxxxxxxxxxxx

# JWT
JWT_SECRET=your-secret-key-change-in-production
JWT_EXPIRES_IN=24h

# Application
NODE_ENV=development
PORT=3000
LOG_LEVEL=info

# CORS
CORS_ORIGIN=http://localhost:5173
```

## Development

### Install Dependencies

```bash
cd backend
npm install
```

### Run Locally

```bash
npm run dev
```

The API will be available at `http://localhost:3000`.

### Build

```bash
npm run build
```

### Run Tests

```bash
npm test
```

## Deployment

### Prerequisites

1. AWS CLI configured
2. DynamoDB tables created
3. Step Functions state machine deployed
4. API Gateway configured

### Deploy Backend

```bash
# Build and package
npm run build
npm run package

# Deploy with CloudFormation
aws cloudformation deploy \
  --template-file ../infrastructure/fullstack-backend.yaml \
  --stack-name chaos-backend-api \
  --capabilities CAPABILITY_IAM
```

Or use the deployment script:

```bash
cd ../scripts
./deploy-backend.sh
```

## API Response Format

All API responses follow this format:

### Success Response
```json
{
  "success": true,
  "data": { ... },
  "message": "Operation successful"
}
```

### Error Response
```json
{
  "success": false,
  "data": null,
  "error": "Error message"
}
```

## Authentication

### JWT Token

Include JWT token in Authorization header:

```
Authorization: Bearer <token>
```

### Token Payload

```json
{
  "sub": "user-id",
  "email": "user@example.com",
  "name": "User Name",
  "role": "ADMIN",
  "iat": 1234567890,
  "exp": 1234657890
}
```

## Database Schema

### Experiments Table

```
PartitionKey: experimentId (String)
Attributes:
  - status: PENDING | RUNNING | COMPLETED | FAILED
  - targetType: String
  - targetId: String
  - configuration: Map
  - startTime: String (ISO 8601)
  - endTime: String (ISO 8601)
  - duration: Number (seconds)
  - createdBy: String (email)
  - metadata: Map
```

### Results Table

```
PartitionKey: resultId (String)
GSI: ExperimentIdIndex (experimentId)
Attributes:
  - experimentId: String
  - timestamp: String (ISO 8601)
  - success: Boolean
  - targetInstance: String
  - recoveryTime: Number (seconds)
  - metricsSnapshot: Map
  - logs: List<String>
  - stepFunctionOutput: Map
```

### Users Table

```
PartitionKey: userId (String)
GSI: EmailIndex (email)
Attributes:
  - email: String
  - name: String
  - role: ADMIN | OPERATOR | VIEWER
  - createdAt: String (ISO 8601)
  - lastLogin: String (ISO 8601)
```

## Error Handling

- All errors are caught and returned with appropriate HTTP status codes
- Errors are logged to CloudWatch Logs
- Client receives user-friendly error messages
- Stack traces are not exposed in production

## Security

- JWT authentication on all endpoints (except login)
- Role-based access control (RBAC)
- Input validation using Zod
- SQL injection prevention (NoSQL)
- CORS configuration
- Rate limiting (API Gateway)
- Encryption at rest (DynamoDB)
- Encryption in transit (TLS 1.3)

## Monitoring

- CloudWatch Logs for all Lambda functions
- CloudWatch Metrics for API performance
- X-Ray tracing for request flow
- Custom metrics for business KPIs

## Testing

### Unit Tests

```bash
npm test
```

### Integration Tests

```bash
npm run test:integration
```

### Load Tests

Use Artillery or similar tool:

```bash
artillery run load-test.yml
```

## Troubleshooting

### Lambda Timeout
- Increase timeout in CloudFormation template
- Optimize database queries
- Add caching layer

### DynamoDB Throttling
- Increase provisioned capacity
- Use on-demand pricing
- Add exponential backoff

### Step Functions Execution Failed
- Check execution history in AWS Console
- Review CloudWatch Logs
- Verify IAM permissions

## Contributing

1. Create feature branch
2. Write tests
3. Submit pull request
4. Code review required

## License

MIT
