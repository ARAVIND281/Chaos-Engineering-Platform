# Cloud-Native Chaos Engineering Platform - Full-Stack Application

A **complete full-stack** automated Chaos Engineering platform on AWS with modern React dashboard and REST API backend that proactively tests fault tolerance by injecting infrastructure-level failures.

## Project Overview

This platform validates cloud application resilience through a professional web interface backed by serverless AWS infrastructure. It orchestrates controlled chaos experiments using AWS Step Functions and Lambda, ensuring auto-scaling and failover mechanisms work as designed.

### Key Features
- ⚛️ **Modern React Frontend** - Beautiful, responsive dashboard for managing chaos experiments
- 🔌 **RESTful API Backend** - Node.js/TypeScript API on AWS Lambda
- 📊 **Real-time Monitoring** - Live experiment progress tracking
- 📈 **Analytics Dashboard** - Success rates, recovery times, and trends
- 🔐 **Authentication** - JWT-based user authentication
- 💾 **DynamoDB Storage** - Scalable NoSQL database for experiments and results
- 🎯 **Step Functions Integration** - Automated chaos experiment orchestration
- 📱 **Responsive Design** - Works on mobile, tablet, and desktop

## Architecture

### Target Application
- **VPC**: Custom VPC across 2 Availability Zones
- **Compute**: Auto Scaling Group (2-4 EC2 instances)
- **Load Balancer**: Application Load Balancer
- **Database**: RDS Multi-AZ (optional)

### Chaos Platform
- **Scheduler**: Amazon EventBridge
- **Orchestrator**: AWS Step Functions
- **Execution**: AWS Lambda functions
- **Monitoring**: Amazon CloudWatch
- **Security**: AWS IAM with least privilege

## Project Timeline

### Week 1: Foundation & Target ✅ COMPLETE
- [x] Project structure setup
- [x] VPC and networking infrastructure
- [x] Target application deployment (EC2 Auto Scaling + ALB)
- [x] Manual high availability verification

### Week 2: Chaos Lambda Functions ✅ COMPLETE
- [x] Get-Target-Instance function
- [x] Inject-Failure function
- [x] Validate-System-Health function

### Week 3: Orchestration ✅ COMPLETE
- [x] Step Functions state machine (18 states)
- [x] EventBridge scheduling
- [x] Deployment and execution scripts

### Week 4: Testing & Documentation ✅ COMPLETE
- [x] End-to-end testing (14 automated tests)
- [x] Final project report (800+ lines)
- [x] Presentation guide with demo

### Week 5-8: Full-Stack Application ✅ COMPLETE
- [x] **Frontend**: React + TypeScript dashboard with Lovable.dev
- [x] **Backend**: Node.js/TypeScript REST API on Lambda
- [x] **Database**: DynamoDB tables (Experiments, Results, Users)
- [x] **API Gateway**: RESTful endpoints for all operations
- [x] **Integration**: Frontend ↔ Backend ↔ Step Functions
- [x] **Deployment**: Automated scripts for full-stack deployment
- [x] **Documentation**: Complete guides and API documentation

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI configured
- Python 3.9+ or Node.js 18+
- Git

## Quick Start

### Week 1: Deploy Infrastructure

```bash
# Deploy VPC and Target Application
./scripts/deploy.sh

# Verify high availability
./scripts/verify-deployment.sh
```

### Week 2: Deploy Lambda Functions

```bash
# Deploy Lambda functions
./scripts/deploy-lambda-functions.sh

# Test all functions
./scripts/test-lambda-functions.sh all
```

### Week 3: Deploy Step Functions

```bash
# Deploy Step Functions (manual mode)
./scripts/deploy-step-functions.sh

# Run chaos experiment manually
./scripts/run-chaos-experiment.sh

# Deploy with automated scheduling (optional)
./scripts/deploy-step-functions.sh true
```

### Week 4: Coming Soon
End-to-end testing and final documentation

## Directory Structure

```
.
├── README.md
├── docs/
│   └── design-document.md
├── infrastructure/
│   ├── vpc-infrastructure.yaml
│   ├── target-application.yaml
│   ├── parameters.json
│   └── chaos-platform.yaml (Week 3)
├── lambda-functions/
│   ├── get-target-instance/
│   ├── inject-failure/
│   └── validate-system-health/
├── step-functions/
│   └── chaos-experiment-workflow.json
└── scripts/
    ├── deploy.sh
    └── cleanup.sh
```

## Security Considerations

- All Lambda functions follow principle of least privilege
- EC2 instances are tagged for chaos experiment targeting
- Security groups restrict traffic to minimum required
- CloudWatch logging enabled for all components

## Cost Estimation

- VPC: Free
- EC2 (t3.micro): ~$12/month for 2 instances
- ALB: ~$22/month
- Lambda: <$1/month (free tier)
- CloudWatch: <$5/month

**Estimated Total**: ~$40/month

## Monitoring

Access CloudWatch dashboards:
```bash
aws cloudwatch get-dashboard --dashboard-name ChaosEngineeringPlatform
```

## Cleanup

To avoid ongoing charges:
```bash
./scripts/cleanup.sh
```

## Team

- **Aravind S** - Project Lead

## License

This project is for educational purposes as part of a Cloud Engineering curriculum.
