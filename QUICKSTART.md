# Quick Start Guide - Week 1

Get the Chaos Engineering Platform running in 15 minutes!

## Prerequisites

- AWS Account configured with AWS CLI
- Bash shell (macOS/Linux/WSL)
- Git installed

## Fast Track Deployment

### 1. Verify AWS Setup

```bash
aws sts get-caller-identity
```

You should see your AWS account information.

### 2. Deploy Everything

```bash
cd "/Users/aravinds/project/Chaos Engineering"
./scripts/deploy.sh
```

This will:
- Create VPC with multi-AZ setup (~3 min)
- Deploy highly available web application (~7 min)
- Output the application URL

### 3. Test Your Application

Open the URL provided at the end of deployment. You should see a web page showing:
- Instance ID
- Availability Zone
- Private IP address

Refresh a few times - you might see different instance IDs as the load balancer distributes traffic.

### 4. Verify High Availability

```bash
./scripts/verify-deployment.sh
```

This runs 5 automated tests:
1. Auto Scaling Group configuration
2. Instance health status
3. Target Group health
4. Application availability
5. Multi-AZ distribution

### 5. Manual Chaos Test (Optional)

Test resilience by killing an instance:

```bash
# Get an instance ID
INSTANCE_ID=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names chaos-platform-asg \
  --query 'AutoScalingGroups[0].Instances[0].InstanceId' \
  --output text)

echo "Terminating instance: $INSTANCE_ID"

# Terminate it
aws ec2 terminate-instances --instance-ids $INSTANCE_ID

# Watch the application URL - it should stay available!
# The Auto Scaling Group will launch a replacement instance
```

### 6. Monitor Recovery

```bash
# Watch Auto Scaling Group instances
watch -n 5 'aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names chaos-platform-asg \
  --query "AutoScalingGroups[0].Instances[].[InstanceId,HealthStatus,LifecycleState]" \
  --output table'
```

Expected behavior:
- Instance terminates
- Load balancer detects failure (30-60 sec)
- Auto Scaling launches replacement (2-3 min)
- Application stays available via other instance(s)

### 7. Clean Up (When Done)

**IMPORTANT**: To avoid AWS charges, delete all resources:

```bash
./scripts/cleanup.sh
```

Type `yes` to confirm deletion.

## What Did We Build?

- **VPC**: 10.0.0.0/16 across 2 Availability Zones
- **Subnets**: 2 public + 2 private subnets
- **Load Balancer**: Application Load Balancer (internet-facing)
- **Compute**: Auto Scaling Group with 2-4 EC2 instances (t3.micro)
- **Monitoring**: CloudWatch metrics, logs, and alarms
- **Security**: Minimal security groups + IAM roles

## File Structure

```
.
├── README.md                    # Full documentation
├── QUICKSTART.md               # This file
├── infrastructure/
│   ├── vpc-infrastructure.yaml      # VPC CloudFormation
│   ├── target-application.yaml      # App CloudFormation
│   └── parameters.json              # Configuration
├── scripts/
│   ├── deploy.sh                    # Deploy everything
│   ├── cleanup.sh                   # Delete everything
│   └── verify-deployment.sh         # Test high availability
├── docs/
│   ├── design-document.md           # Full project design
│   ├── week1-guide.md              # Detailed Week 1 guide
│   └── architecture-diagram.md      # Architecture diagrams
├── lambda-functions/               # Week 2
└── step-functions/                 # Week 3
```

## Costs

Estimated: **~$1.50/day** ($40-50/month)

Most expensive components:
- NAT Gateways: ~$0.045/hour each ($65/month for 2)
- Application Load Balancer: ~$0.025/hour ($18/month)
- EC2 instances: ~$0.0104/hour each ($15/month for 2)

**Save money**: Run `./scripts/cleanup.sh` when not actively testing!

## Troubleshooting

### Scripts won't run
```bash
chmod +x scripts/*.sh
```

### CloudFormation errors
Check IAM permissions - you need admin-level access for this project.

### Application not responding
Wait 10 minutes after deployment. Instances need time to initialize.

### Can't find jq (for verify script)
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq
```

## Next Steps

Once Week 1 is complete and verified:

1. **Week 2**: Build Lambda functions for chaos experiments
2. **Week 3**: Create Step Functions workflow for orchestration
3. **Week 4**: End-to-end testing and presentation

## Support

- Full documentation: [README.md](README.md)
- Week 1 details: [docs/week1-guide.md](docs/week1-guide.md)
- Architecture: [docs/architecture-diagram.md](docs/architecture-diagram.md)

---

**Ready to start?** Run `./scripts/deploy.sh` and let's build some resilience!
