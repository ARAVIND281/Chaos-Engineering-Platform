# Chaos Engineering Platform

<div align="center">

![Chaos Engineering](https://img.shields.io/badge/Chaos-Engineering-red?style=for-the-badge)
![AWS](https://img.shields.io/badge/AWS-Cloud-orange?style=for-the-badge&logo=amazon-aws)
![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)
![TypeScript](https://img.shields.io/badge/TypeScript-007ACC?style=for-the-badge&logo=typescript&logoColor=white)
![React](https://img.shields.io/badge/React-20232A?style=for-the-badge&logo=react&logoColor=61DAFB)

**A production-ready, full-stack Chaos Engineering platform built on AWS**

Test your system's resilience by injecting controlled failures into your infrastructure.

[Features](#-features) • [Quick Start](#-quick-start) • [Documentation](#-documentation) • [Architecture](#-architecture)

</div>

---

## Overview

This Chaos Engineering Platform enables you to test the resilience of your AWS infrastructure by injecting controlled failures and monitoring system behavior. Built entirely on AWS serverless technologies, it provides a complete solution for chaos experimentation with a modern React frontend, TypeScript backend, and automated workflows.

### What is Chaos Engineering?

Chaos Engineering is the discipline of experimenting on a system to build confidence in the system's capability to withstand turbulent conditions in production.

---

## Features

### Core Capabilities

- **Automated Chaos Experiments** - Inject failures into EC2 instances, Auto Scaling Groups
- **Step Functions Orchestration** - 18-state workflow for safe, controlled chaos injection
- **Real-time Monitoring** - Track system health before, during, and after experiments
- **Dry Run Mode** - Test experiments without actual impact
- **Full-Stack Dashboard** - Modern React UI for managing experiments
- **Results Analytics** - Comprehensive experiment results and metrics

### Infrastructure

- **Multi-AZ VPC** - High-availability networking with public/private subnets
- **Auto Scaling Target App** - Sample application to test chaos experiments against
- **Serverless Backend** - Lambda functions with DynamoDB for data persistence
- **CloudWatch Integration** - Detailed logging and metrics
- **Infrastructure as Code** - Complete CloudFormation templates

---

## Quick Start

### Prerequisites

- AWS Account with appropriate permissions
- AWS CLI configured
- Node.js 18+ and npm
- Git

### One-Command Deployment

```bash
# Clone the repository
git clone https://github.com/ARAVIND281/Chaos-Engineering-Platform.git
cd chaos-engineering-platform

# Deploy everything
./scripts/deploy-fullstack-complete.sh dev
```

**Deployment time:** ~15-20 minutes

### Access Your Platform

After deployment:

```
Frontend URL: http://chaos-platform-frontend-dev-[account-id].s3-website-us-east-1.amazonaws.com
Login: admin@chaos-platform.com / any-password
```

---

## Architecture

```
User Interface (React Dashboard)
         |
Backend API (Lambda + DynamoDB)
         |
Chaos Orchestration (Step Functions)
         |
Target Infrastructure (VPC + EC2 + ALB)
```

### Component Breakdown

#### Week 1: Foundation
- VPC Infrastructure (Multi-AZ)
- Target Application (Auto Scaling Group + Load Balancer)

#### Week 2: Chaos Functions
- get-target-instance
- inject-failure
- validate-system-health

#### Week 3: Orchestration
- Step Functions State Machine (18 states)

#### Weeks 5-8: Full-Stack Application
- Backend API (TypeScript Lambda)
- Frontend Dashboard (React + shadcn/ui)
- Database (DynamoDB)

---

## Documentation

### Quick References

- [Quick Start Guide](docs/deployment/DEPLOY_NOW.md)
- [Step-by-Step Deployment](docs/deployment/STEP_BY_STEP_GUIDE.md)
- [AWS IAM Setup](docs/deployment/AWS_IAM_SETUP.md)

### Weekly Guides

- [Week 1: VPC & Target Application](docs/weeks/week1.md)
- [Week 2: Lambda Functions](docs/weeks/week2.md)
- [Week 3: Step Functions](docs/weeks/week3.md)
- [Week 4: Monitoring](docs/weeks/week4.md)

### Full-Stack Documentation

- [Full-Stack Design](docs/fullstack/FULL_STACK_DESIGN.md)
- [Full-Stack Summary](docs/fullstack/FULL_STACK_SUMMARY.md)
- [Quick Start](docs/fullstack/FULLSTACK_QUICKSTART.md)

---

## Project Structure

```
chaos-engineering-platform/
├── infrastructure/              # CloudFormation templates
├── lambda-functions/            # Chaos Lambda functions
├── backend/                     # Backend API (TypeScript)
├── frontend/                    # React Dashboard
├── scripts/                     # Deployment & utility scripts
└── docs/                        # Documentation
```

---

## Usage

### Creating Your First Experiment

1. Access the dashboard
2. Login with provided credentials
3. Click "New Experiment"
4. Select target and failure type
5. Enable "Dry Run" for safe testing
6. Click "Start Experiment"
7. Monitor progress in real-time
8. View results and analytics

---

## Cost Estimation

### Monthly Costs (if left running 24/7)

| Service | Cost |
|---------|------|
| EC2 Instances (2x t3.micro) | ~$12/month |
| Application Load Balancer | ~$16/month |
| NAT Gateways (2) | ~$64/month |
| Lambda + DynamoDB + S3 | ~$13/month |
| **Total** | **~$105/month** |

---

## Cleanup

To avoid AWS charges:

```bash
./scripts/cleanup.sh
```

---

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md).

---

## License

MIT License - see [LICENSE](LICENSE) file.

---

## Support

- **Documentation**: [Full Documentation](docs/)
- **Issues**: [GitHub Issues](https://github.com/ARAVIND281/Chaos-Engineering-Platform/issues)

---

<div align="center">

**Built with ❤️ for the DevOps and SRE community**

</div>
