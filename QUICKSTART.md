# Chaos Engineering Platform - Complete Quick Start Guide

This guide will walk you through deploying and using your complete Chaos Engineering Platform (Weeks 1-4) in minutes.

---

## Prerequisites

Before you begin, ensure you have:

1. **AWS Account** with appropriate permissions
2. **AWS CLI** installed and configured (`aws configure`)
3. **Bash shell** (macOS/Linux or WSL on Windows)
4. **Git** installed
5. **jq** installed (`brew install jq` on macOS or `apt-get install jq` on Linux)

**Required AWS Permissions:**
- CloudFormation (Create/Update/Delete stacks)
- EC2 (VPC, Instances, Auto Scaling, Load Balancers)
- Lambda (Create/Update functions)
- Step Functions (Create/Execute state machines)
- IAM (Create roles and policies)
- CloudWatch (Logs and Metrics)

---

## Step-by-Step Deployment

### Step 1: Deploy the Complete Platform (15-20 minutes)

Deploy all infrastructure with a single command:

```bash
cd "/Users/aravinds/project/Chaos Engineering"
./scripts/deploy.sh
```

**What this does:**
- Creates VPC with multi-AZ networking
- Deploys Auto Scaling Group with 2-4 EC2 instances
- Creates Application Load Balancer
- Deploys 3 Lambda functions for chaos experiments
- Creates Step Functions orchestration workflow
- Sets up CloudWatch monitoring

**Expected Output:**
```
========================================
Chaos Engineering Platform Deployment
========================================

Step 1: Deploying VPC Infrastructure...
✓ VPC Stack deployed successfully

Step 2: Deploying Target Application...
✓ Application Stack deployed successfully

Step 3: Deploying Lambda Functions...
✓ Lambda Functions deployed successfully

Step 4: Deploying Step Functions...
✓ Step Functions deployed successfully

========================================
Deployment Summary
========================================
VPC ID: vpc-xxxxx
Load Balancer DNS: chaos-target-lb-xxxxx.us-east-1.elb.amazonaws.com
Auto Scaling Group: chaos-target-asg
Step Functions ARN: arn:aws:states:us-east-1:xxxx:stateMachine:chaos-experiment-workflow
```

**Save the output!** You'll need these values for testing.

---

### Step 2: Verify the Deployment (2-3 minutes)

Run automated verification tests:

```bash
./scripts/verify-deployment.sh
```

**What this tests:**
1. VPC infrastructure exists
2. Auto Scaling Group has healthy instances
3. Load Balancer is active
4. Target Group has healthy targets
5. Application is responding to HTTP requests

**Expected Output:**
```
========================================
Running Deployment Verification Tests
========================================

Test 1: VPC Infrastructure ✓ PASS
Test 2: Auto Scaling Group ✓ PASS
Test 3: Load Balancer Status ✓ PASS
Test 4: Target Health ✓ PASS
Test 5: Application Response ✓ PASS

All verification tests passed!
```

---

### Step 3: Run Your First Chaos Experiment (5-10 minutes)

Execute a complete chaos engineering workflow:

```bash
./scripts/run-chaos-experiment.sh
```

**What this does:**
1. **Pre-Experiment Baseline**: Validates system is healthy
2. **Target Selection**: Picks a random healthy EC2 instance
3. **Failure Injection**: Terminates the selected instance
4. **System Recovery**: Monitors Auto Scaling recovery
5. **Health Validation**: Confirms system returned to healthy state
6. **Results Recording**: Saves experiment results

**Interactive Output:**
```
========================================
Starting Chaos Experiment
========================================

Execution ARN: arn:aws:states:us-east-1:xxxx:execution:chaos-experiment-workflow:xxxxx

Monitoring execution in real-time...
[12:34:56] State: ValidatePreExperimentHealth - Running...
[12:35:12] State: ValidatePreExperimentHealth - Succeeded ✓
[12:35:13] State: GetTargetInstance - Running...
[12:35:28] State: GetTargetInstance - Succeeded ✓
           Target: i-0abc123def456 (10.0.1.45)
[12:35:29] State: InjectFailure - Running...
[12:35:45] State: InjectFailure - Succeeded ✓
           Instance terminated!
[12:35:46] State: WaitForRecovery - Running... (60s)
[12:36:46] State: ValidateSystemHealth - Running...
[12:37:02] State: ValidateSystemHealth - Succeeded ✓

========================================
Experiment Completed Successfully! ✓
========================================

Duration: 2m 15s
Result: PASS
System successfully recovered from instance failure!
```

---

## Understanding the Results

### What Just Happened?

1. **Baseline Check**: System had 2-4 healthy instances behind load balancer
2. **Chaos Injection**: One instance was randomly terminated
3. **Auto Scaling Response**: AWS Auto Scaling detected the failure
4. **New Instance Launch**: A replacement instance was automatically launched
5. **Health Validation**: System returned to healthy state with correct instance count
6. **Success**: Your system proved it can handle instance failures!

### Key Metrics to Watch

Check CloudWatch metrics during experiments:
- **Healthy Host Count**: Should drop by 1, then recover
- **Request Count**: Should remain stable (load balancer redistributes traffic)
- **Target Response Time**: May spike briefly, then normalize
- **HTTP 5xx Errors**: Should remain at 0 (no user impact)

---

## Running Different Types of Experiments

### Dry Run Mode (Safe Testing)

Test without actually terminating instances:

```bash
./scripts/run-chaos-experiment.sh --dry-run
```

### Manual Execution with Custom Parameters

```bash
# Start execution
EXECUTION_ARN=$(aws stepfunctions start-execution \
  --state-machine-arn arn:aws:states:REGION:ACCOUNT:stateMachine:chaos-experiment-workflow \
  --input '{
    "autoScalingGroupName": "chaos-target-asg",
    "loadBalancerArn": "arn:aws:elasticloadbalancing:...",
    "targetGroupArn": "arn:aws:elasticloadbalancing:...",
    "expectedHealthyInstances": 2,
    "dryRun": false
  }' \
  --query 'executionArn' \
  --output text)

# Monitor execution
aws stepfunctions describe-execution \
  --execution-arn $EXECUTION_ARN
```

### Scheduled Experiments

Enable automatic daily experiments at 2 AM UTC:

```bash
./scripts/deploy-step-functions.sh --enable-scheduling
```

Disable scheduling:

```bash
./scripts/deploy-step-functions.sh --disable-scheduling
```

---

## Testing Individual Components

### Test Lambda Functions Only

```bash
./scripts/test-lambda-functions.sh
```

**Options:**
```bash
# Test specific function
./scripts/test-lambda-functions.sh get-target-instance
./scripts/test-lambda-functions.sh inject-failure
./scripts/test-lambda-functions.sh validate-system-health

# Test all functions
./scripts/test-lambda-functions.sh all
```

### Run Complete End-to-End Tests

```bash
./scripts/test-end-to-end.sh
```

**14 Automated Tests:**
- Phase 1: Infrastructure (5 tests)
- Phase 2: Lambda Functions (4 tests)
- Phase 3: Step Functions (3 tests)
- Phase 4: Live Chaos Experiment (2 tests)

---

## Monitoring and Observability

### View Step Functions Execution History

```bash
# List recent executions
aws stepfunctions list-executions \
  --state-machine-arn arn:aws:states:REGION:ACCOUNT:stateMachine:chaos-experiment-workflow \
  --max-results 10

# Get execution details
aws stepfunctions get-execution-history \
  --execution-arn EXECUTION_ARN
```

### View Lambda Function Logs

```bash
# Get target instance function logs
aws logs tail /aws/lambda/chaos-get-target-instance --follow

# Get failure injection function logs
aws logs tail /aws/lambda/chaos-inject-failure --follow

# Get health validation function logs
aws logs tail /aws/lambda/chaos-validate-system-health --follow
```

### Check System Health in Real-Time

```bash
# Get current healthy instance count
aws elbv2 describe-target-health \
  --target-group-arn TARGET_GROUP_ARN \
  --query 'TargetHealthDescriptions[?TargetHealth.State==`healthy`] | length(@)'

# Get Auto Scaling Group status
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names chaos-target-asg \
  --query 'AutoScalingGroups[0].[DesiredCapacity,MinSize,MaxSize,Instances[].LifecycleState]'
```

### View CloudWatch Dashboard

1. Open AWS Console → CloudWatch → Dashboards
2. Look for "ChaosEngineeringPlatform" dashboard
3. View real-time metrics:
   - Healthy host count
   - Request count
   - Response times
   - Error rates

---

## Common Use Cases

### 1. Validate High Availability

**Goal**: Ensure your application handles instance failures gracefully

```bash
# Run experiment and verify zero downtime
./scripts/run-chaos-experiment.sh

# Check for any 5xx errors during experiment
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name HTTPCode_Target_5XX_Count \
  --dimensions Name=LoadBalancer,Value=app/chaos-target-lb/xxxxx \
  --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Sum
```

### 2. Test Auto Scaling Policies

**Goal**: Verify Auto Scaling responds correctly to instance termination

```bash
# Before experiment - note current capacity
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names chaos-target-asg \
  --query 'AutoScalingGroups[0].Instances[*].[InstanceId,LifecycleState]'

# Run experiment
./scripts/run-chaos-experiment.sh

# After experiment - verify new instance launched
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names chaos-target-asg \
  --query 'AutoScalingGroups[0].Instances[*].[InstanceId,LifecycleState]'
```

### 3. Continuous Resilience Testing

**Goal**: Run daily automated chaos experiments

```bash
# Enable daily experiments at 2 AM UTC
./scripts/deploy-step-functions.sh --enable-scheduling

# Monitor results in CloudWatch Logs
aws logs tail /aws/lambda/chaos-experiment-workflow --follow
```

### 4. Chaos as Code - Custom Experiments

Create custom experiment scenarios:

```json
{
  "autoScalingGroupName": "chaos-target-asg",
  "loadBalancerArn": "arn:aws:elasticloadbalancing:...",
  "targetGroupArn": "arn:aws:elasticloadbalancing:...",
  "expectedHealthyInstances": 3,
  "dryRun": false,
  "experimentMetadata": {
    "name": "peak-traffic-resilience-test",
    "owner": "platform-team",
    "hypothesis": "System maintains 99.9% availability during instance failure at peak load"
  }
}
```

---

## Troubleshooting

### Issue: Deployment Fails

**Check AWS credentials:**
```bash
aws sts get-caller-identity
```

**Check required permissions:**
```bash
# List your IAM permissions
aws iam get-user
```

**View CloudFormation stack errors:**
```bash
aws cloudformation describe-stack-events \
  --stack-name chaos-vpc-infrastructure \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`]'
```

### Issue: Chaos Experiment Fails

**Check Lambda function logs:**
```bash
aws logs tail /aws/lambda/chaos-inject-failure --since 10m
```

**Verify instances have correct tags:**
```bash
aws ec2 describe-instances \
  --filters "Name=tag:ChaosTarget,Values=true" \
  --query 'Reservations[].Instances[*].[InstanceId,Tags]'
```

**Check Step Functions execution errors:**
```bash
aws stepfunctions describe-execution \
  --execution-arn EXECUTION_ARN \
  --query 'cause'
```

### Issue: No Healthy Instances

**Check Auto Scaling Group:**
```bash
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names chaos-target-asg
```

**Check instance health:**
```bash
aws elbv2 describe-target-health \
  --target-group-arn TARGET_GROUP_ARN
```

**Check security groups:**
```bash
# Ensure instances can receive traffic on port 80
aws ec2 describe-security-groups \
  --filters "Name=tag:Name,Values=chaos-target-instance-sg"
```

---

## Cost Management

### Estimated Monthly Costs

**Running 24/7:**
- EC2 instances (2x t3.micro): ~$12/month
- Application Load Balancer: ~$16/month
- NAT Gateways (2): ~$64/month
- Lambda invocations: <$1/month (minimal usage)
- Step Functions: <$1/month (minimal usage)
- Data transfer: ~$5/month
- **Total: ~$98/month**

### Cost Optimization Tips

1. **Use Spot Instances** (not recommended for production):
   ```bash
   # Modify Auto Scaling Group to use Spot
   # Edit infrastructure/target-application.yaml
   # Add MixedInstancesPolicy with SpotAllocationStrategy
   ```

2. **Stop When Not in Use**:
   ```bash
   # Set desired capacity to 0
   aws autoscaling set-desired-capacity \
     --auto-scaling-group-name chaos-target-asg \
     --desired-capacity 0

   # Restore when needed
   aws autoscaling set-desired-capacity \
     --auto-scaling-group-name chaos-target-asg \
     --desired-capacity 2
   ```

3. **Clean Up Completely**:
   ```bash
   ./scripts/cleanup.sh
   ```

---

## Cleanup

### Remove All Resources

When you're done experimenting, clean up to avoid ongoing costs:

```bash
./scripts/cleanup.sh
```

**What this deletes:**
- Step Functions state machine
- Lambda functions (3)
- Auto Scaling Group and EC2 instances
- Application Load Balancer
- VPC and all networking components
- CloudWatch log groups (7)
- IAM roles and policies

**Expected Output:**
```
========================================
Chaos Engineering Platform Cleanup
========================================

Step 1: Deleting Step Functions Stack...
✓ Stack deleted successfully

Step 2: Deleting Lambda Functions Stack...
✓ Stack deleted successfully

Step 3: Deleting Target Application Stack...
✓ Stack deleted successfully

Step 4: Deleting VPC Infrastructure Stack...
✓ Stack deleted successfully

Step 5: Cleaning up CloudWatch Log Groups...
✓ All log groups deleted

========================================
Cleanup Complete!
========================================
```

**Verification:**
```bash
# Verify no stacks remain
aws cloudformation list-stacks \
  --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
  --query 'StackSummaries[?contains(StackName, `chaos`)].StackName'

# Should return empty list: []
```

---

## Project Structure Overview

```
.
├── README.md                           # Project overview
├── QUICKSTART.md                       # This guide
├── infrastructure/
│   ├── vpc-infrastructure.yaml         # VPC CloudFormation (Week 1)
│   ├── target-application.yaml         # Target app CloudFormation (Week 1)
│   ├── chaos-lambda-functions.yaml     # Lambda CloudFormation (Week 2)
│   └── chaos-step-functions.yaml       # Step Functions CloudFormation (Week 3)
├── lambda-functions/                   # Week 2
│   ├── get-target-instance/
│   │   └── lambda_function.py          # Selects random healthy instance
│   ├── inject-failure/
│   │   └── lambda_function.py          # Terminates EC2 instance
│   └── validate-system-health/
│       └── lambda_function.py          # Validates system health
├── step-functions/                     # Week 3
│   └── chaos-experiment-workflow.json  # 18-state orchestration workflow
├── scripts/
│   ├── deploy.sh                       # Deploy complete platform
│   ├── verify-deployment.sh            # Verify Week 1 deployment
│   ├── deploy-lambda-functions.sh      # Deploy Lambda functions
│   ├── test-lambda-functions.sh        # Test Lambda functions
│   ├── deploy-step-functions.sh        # Deploy Step Functions
│   ├── run-chaos-experiment.sh         # Execute chaos experiment
│   ├── test-end-to-end.sh             # Complete automated testing (Week 4)
│   └── cleanup.sh                      # Delete all resources
├── docs/
│   ├── week1-guide.md                 # Week 1 detailed guide
│   ├── week2-guide.md                 # Week 2 detailed guide
│   ├── week3-guide.md                 # Week 3 detailed guide
│   ├── FINAL_PROJECT_REPORT.md        # Complete project report (Week 4)
│   └── PRESENTATION_GUIDE.md          # Presentation guide (Week 4)
└── .git/                              # Git repository
```

---

## Next Steps

### Learn More

- **Architecture Deep Dive**: See [docs/FINAL_PROJECT_REPORT.md](docs/FINAL_PROJECT_REPORT.md)
- **Week-by-Week Implementation**:
  - Week 1: [docs/week1-guide.md](docs/week1-guide.md)
  - Week 2: [docs/week2-guide.md](docs/week2-guide.md)
  - Week 3: [docs/week3-guide.md](docs/week3-guide.md)
- **Presentation Guide**: [docs/PRESENTATION_GUIDE.md](docs/PRESENTATION_GUIDE.md)

### Extend the Platform

1. **Add More Chaos Experiments**:
   - Network latency injection
   - CPU/Memory stress testing
   - Disk I/O degradation
   - AZ failure simulation

2. **Integrate with CI/CD**:
   - Run chaos tests before production deployment
   - Fail deployments if resilience tests don't pass

3. **Advanced Monitoring**:
   - Add X-Ray tracing
   - Custom CloudWatch dashboards
   - SNS notifications for experiment results

4. **Multi-Region Testing**:
   - Deploy to multiple regions
   - Test cross-region failover

---

## Quick Reference

### Key Commands

```bash
# Deploy everything
./scripts/deploy.sh

# Verify deployment
./scripts/verify-deployment.sh

# Run chaos experiment
./scripts/run-chaos-experiment.sh

# Test all components
./scripts/test-end-to-end.sh

# Clean up everything
./scripts/cleanup.sh
```

### Important ARNs and Values

After deployment, save these values:

```bash
# Get VPC ID
aws cloudformation describe-stacks \
  --stack-name chaos-vpc-infrastructure \
  --query 'Stacks[0].Outputs[?OutputKey==`VPCId`].OutputValue' \
  --output text

# Get Load Balancer DNS
aws cloudformation describe-stacks \
  --stack-name chaos-target-application \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
  --output text

# Get Step Functions ARN
aws cloudformation describe-stacks \
  --stack-name chaos-step-functions \
  --query 'Stacks[0].Outputs[?OutputKey==`StateMachineArn`].OutputValue' \
  --output text
```

---

## Support and Documentation

- **Project Documentation**: [docs/](docs/)
- **AWS CloudFormation**: [infrastructure/](infrastructure/)
- **Lambda Functions**: [lambda-functions/](lambda-functions/)
- **Step Functions**: [step-functions/](step-functions/)
- **Scripts**: [scripts/](scripts/)

---

**Happy Chaos Engineering!** Remember: Breaking things on purpose helps you build more resilient systems. 🚀
