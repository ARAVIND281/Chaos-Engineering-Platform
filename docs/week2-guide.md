# Week 2 Implementation Guide - Lambda Functions

## Objective
Develop and test the three core Lambda functions that power the Chaos Engineering experiments.

## What We Built

### 1. Get-Target-Instance Lambda Function
**Purpose**: Selects a random healthy EC2 instance from the Auto Scaling Group for chaos experiments.

**Key Features**:
- Queries Auto Scaling Group for all instances
- Filters for healthy instances (HealthStatus=Healthy, LifecycleState=InService)
- Tag-based safety check (only selects instances with ChaosTarget=true)
- Random selection from eligible instances
- Returns detailed instance information

**Code**: [lambda-functions/get-target-instance/lambda_function.py](../lambda-functions/get-target-instance/lambda_function.py)

**IAM Permissions**:
```json
{
  "autoscaling:DescribeAutoScalingGroups",
  "ec2:DescribeInstances"
}
```

### 2. Inject-Failure Lambda Function
**Purpose**: Safely terminates a specified EC2 instance to inject chaos into the system.

**Key Features**:
- Multi-layer safety checks (tag verification, state validation)
- Dry run mode for testing without actual termination
- IAM policy condition enforcement (ChaosTarget tag required)
- Comprehensive logging and audit trail
- Graceful handling of already-terminated instances

**Code**: [lambda-functions/inject-failure/lambda_function.py](../lambda-functions/inject-failure/lambda_function.py)

**IAM Permissions**:
```json
{
  "ec2:DescribeInstances" (all resources),
  "ec2:TerminateInstances" (conditional on ChaosTarget=true tag)
}
```

### 3. Validate-System-Health Lambda Function
**Purpose**: Validates system health by querying CloudWatch metrics and ELB target health.

**Key Features**:
- Real-time target health check via ELBv2 API
- CloudWatch metrics analysis (5-minute lookback)
- Multiple health criteria evaluation
- Pass/fail determination with detailed reporting
- Configurable thresholds

**Metrics Checked**:
- HealthyHostCount (Target Group)
- UnHealthyHostCount (Target Group)
- HTTPCode_Target_5XX_Count (Load Balancer)
- TargetResponseTime (Load Balancer)
- RequestCount (Load Balancer)

**Code**: [lambda-functions/validate-system-health/lambda_function.py](../lambda-functions/validate-system-health/lambda_function.py)

**IAM Permissions**:
```json
{
  "elasticloadbalancing:DescribeTargetHealth",
  "elasticloadbalancing:DescribeLoadBalancers",
  "elasticloadbalancing:DescribeTargetGroups",
  "cloudwatch:GetMetricStatistics",
  "cloudwatch:ListMetrics"
}
```

### 4. CloudFormation Template
**Purpose**: Deploys all Lambda functions with proper IAM roles and CloudWatch log groups.

**File**: [infrastructure/chaos-lambda-functions.yaml](../infrastructure/chaos-lambda-functions.yaml)

**Resources Created**:
- 3 IAM Roles (one per Lambda function, least privilege)
- 3 Lambda Functions (with placeholder code)
- 3 CloudWatch Log Groups (7-day retention)

### 5. Deployment Scripts
**Purpose**: Automate Lambda function deployment and testing.

**Files**:
- [scripts/deploy-lambda-functions.sh](../scripts/deploy-lambda-functions.sh) - Deploy all functions
- [scripts/test-lambda-functions.sh](../scripts/test-lambda-functions.sh) - Test each function

## Prerequisites

Before starting Week 2, ensure:

1. ✅ Week 1 is complete (VPC and Target Application deployed)
2. ✅ AWS CLI configured with proper credentials
3. ✅ `zip` command available on your system
4. ✅ Python 3 available for local testing

## Deployment Steps

### Step 1: Deploy Lambda Functions

```bash
cd "/Users/aravinds/project/Chaos Engineering"
./scripts/deploy-lambda-functions.sh
```

This script will:
1. Create CloudFormation stack with IAM roles and Lambda functions
2. Package each Lambda function into a ZIP file
3. Update Lambda function code
4. Verify deployments
5. Display function ARNs and testing commands

**Expected time**: 2-3 minutes

### Step 2: Verify Deployment

```bash
# List all Lambda functions
aws lambda list-functions --query 'Functions[?starts_with(FunctionName, `chaos-platform`)].FunctionName'

# Check function details
aws lambda get-function --function-name chaos-platform-get-target-instance
aws lambda get-function --function-name chaos-platform-inject-failure
aws lambda get-function --function-name chaos-platform-validate-system-health
```

### Step 3: Test Lambda Functions

#### Test All Functions (Recommended)

```bash
./scripts/test-lambda-functions.sh all
```

This will test all three functions in sequence with dry-run mode for inject-failure.

#### Test Individual Functions

```bash
# Test Get-Target-Instance
./scripts/test-lambda-functions.sh get-target

# Test Inject-Failure (dry run)
./scripts/test-lambda-functions.sh inject-failure

# Test Validate-System-Health
./scripts/test-lambda-functions.sh validate-health
```

### Step 4: Review CloudWatch Logs

```bash
# Follow logs in real-time
aws logs tail /aws/lambda/chaos-platform-get-target-instance --follow
aws logs tail /aws/lambda/chaos-platform-inject-failure --follow
aws logs tail /aws/lambda/chaos-platform-validate-system-health --follow
```

## Local Testing

### Setup

```bash
cd lambda-functions/get-target-instance
pip3 install -r requirements.txt
```

### Test Get-Target-Instance

```python
import json
from lambda_function import lambda_handler

event = {
    'autoScalingGroupName': 'chaos-platform-asg'
}

result = lambda_handler(event, None)
print(json.dumps(result, indent=2, default=str))
```

### Test Inject-Failure (Dry Run)

```python
import json
from lambda_function import lambda_handler

event = {
    'instanceId': 'i-0123456789abcdef0',
    'dryRun': True
}

result = lambda_handler(event, None)
print(json.dumps(result, indent=2, default=str))
```

### Test Validate-System-Health

```python
import json
from lambda_function import lambda_handler

event = {
    'targetGroupArn': 'arn:aws:elasticloadbalancing:...',
    'loadBalancerArn': 'arn:aws:elasticloadbalancing:...',
    'expectedHealthyHosts': 2,
    'checkType': 'test'
}

result = lambda_handler(event, None)
print(json.dumps(result, indent=2, default=str))
```

## Manual Testing via AWS Console

### Test Get-Target-Instance

1. Go to Lambda Console
2. Open `chaos-platform-get-target-instance`
3. Create test event:

```json
{
  "autoScalingGroupName": "chaos-platform-asg"
}
```

4. Click "Test"
5. Review execution results and logs

### Test Inject-Failure (Dry Run)

1. Go to Lambda Console
2. Open `chaos-platform-inject-failure`
3. Create test event:

```json
{
  "instanceId": "i-0123456789abcdef0",
  "dryRun": true
}
```

4. Click "Test"
5. Verify it returns validation success without terminating

### Test Validate-System-Health

1. Get Target Group ARN from CloudFormation outputs
2. Go to Lambda Console
3. Open `chaos-platform-validate-system-health`
4. Create test event:

```json
{
  "targetGroupArn": "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/chaos-platform-tg/abc123",
  "loadBalancerArn": "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/chaos-platform-alb/xyz789",
  "expectedHealthyHosts": 2,
  "checkType": "test"
}
```

5. Click "Test"
6. Review health check results

## Testing Scenarios

### Scenario 1: End-to-End Manual Test

```bash
# 1. Get a target instance
./scripts/test-lambda-functions.sh get-target
# Note the instance ID

# 2. Validate current health (should PASS)
./scripts/test-lambda-functions.sh validate-health

# 3. Dry run termination
./scripts/test-lambda-functions.sh inject-failure

# 4. (Optional) Actually terminate an instance
# WARNING: This will cause a brief outage
aws lambda invoke \
  --function-name chaos-platform-inject-failure \
  --payload '{"instanceId":"i-xxx","dryRun":false}' \
  --cli-binary-format raw-in-base64-out \
  /tmp/result.json

# 5. Wait 3 minutes for Auto Scaling recovery

# 6. Validate health again (should PASS after recovery)
./scripts/test-lambda-functions.sh validate-health
```

### Scenario 2: Safety Test (No Tag)

Try to terminate an instance without the ChaosTarget tag - it should be refused:

```bash
# Find any EC2 instance without ChaosTarget tag
RANDOM_INSTANCE=$(aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text)

# Try to terminate it (should FAIL)
aws lambda invoke \
  --function-name chaos-platform-inject-failure \
  --payload "{\"instanceId\":\"$RANDOM_INSTANCE\",\"dryRun\":true}" \
  --cli-binary-format raw-in-base64-out \
  /tmp/result.json

cat /tmp/result.json
# Should return error: "Instance is not tagged as ChaosTarget=true"
```

### Scenario 3: Health Validation During Failure

```bash
# Terminal 1: Monitor health continuously
watch -n 10 './scripts/test-lambda-functions.sh validate-health'

# Terminal 2: Terminate an instance
./scripts/test-lambda-functions.sh inject-failure
# Use actual termination (dryRun: false) if testing recovery

# Observe health status change from PASS -> FAIL -> PASS
```

## Troubleshooting

### Issue: Lambda function not found

**Check**:
```bash
aws lambda list-functions --query 'Functions[?starts_with(FunctionName, `chaos-platform`)].FunctionName'
```

**Solution**: Deploy Lambda functions first:
```bash
./scripts/deploy-lambda-functions.sh
```

### Issue: Permission denied errors

**Check IAM roles**:
```bash
aws iam get-role --role-name chaos-platform-get-target-role
aws iam get-role --role-name chaos-platform-inject-failure-role
aws iam get-role --role-name chaos-platform-validate-health-role
```

**Solution**: Ensure CloudFormation stack created roles properly:
```bash
aws cloudformation describe-stack-resources \
  --stack-name chaos-platform-lambda-functions \
  --query 'StackResources[?ResourceType==`AWS::IAM::Role`].[LogicalResourceId,PhysicalResourceId]'
```

### Issue: No instances found

**Check Auto Scaling Group**:
```bash
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names chaos-platform-asg \
  --query 'AutoScalingGroups[0].Instances'
```

**Solution**: Ensure target application is running:
```bash
./scripts/verify-deployment.sh
```

### Issue: CloudWatch metrics not available

**Wait**: Metrics may take 5-10 minutes to appear after deployment.

**Check manually**:
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name HealthyHostCount \
  --dimensions Name=TargetGroup,Value=<TG_NAME> Name=LoadBalancer,Value=<LB_NAME> \
  --start-time 2025-10-18T00:00:00Z \
  --end-time 2025-10-18T23:59:59Z \
  --period 300 \
  --statistics Average
```

### Issue: Function timeout

**Increase timeout in CloudFormation**:
```yaml
Timeout: 60  # Default is 30 for inject-failure, 60 for validate-health
```

## Cost Considerations

### Lambda Costs (Free Tier Eligible)

- **Requests**: First 1M requests/month free
- **Duration**: First 400,000 GB-seconds/month free

**Estimated monthly cost**: <$1 for testing

### CloudWatch Logs

- **Ingestion**: $0.50/GB
- **Storage**: $0.03/GB/month
- **7-day retention**: Minimal cost

**Estimated monthly cost**: <$2

**Total Week 2 Cost**: ~$3/month (negligible during testing)

## Success Criteria

✅ **Week 2 is complete when**:
1. All three Lambda functions are deployed
2. IAM roles are properly configured with least privilege
3. Get-Target-Instance successfully selects instances
4. Inject-Failure validates safety checks (dry run mode)
5. Validate-System-Health correctly reports application status
6. CloudWatch logs show detailed execution traces
7. All functions can be invoked via AWS CLI
8. Test script executes all scenarios successfully

## Next Steps: Week 3

In Week 3, we will:
1. Create Step Functions state machine
2. Integrate all three Lambda functions
3. Implement the complete chaos experiment workflow
4. Add wait periods and conditional logic
5. Set up EventBridge scheduling
6. Test end-to-end automation

## Architecture Review

### Week 2 Accomplishments

```
┌─────────────────────────────────────────────────────────┐
│              Lambda Functions (Week 2)                   │
│                                                          │
│  ┌───────────────────────────────────────────────────┐ │
│  │ get-target-instance                               │ │
│  │ - Queries Auto Scaling Group                      │ │
│  │ - Filters healthy instances                       │ │
│  │ - Validates ChaosTarget tag                       │ │
│  │ - Returns random instance                         │ │
│  └───────────────────────────────────────────────────┘ │
│                          ↓                               │
│  ┌───────────────────────────────────────────────────┐ │
│  │ inject-failure                                    │ │
│  │ - Safety checks (tag, state)                      │ │
│  │ - Dry run capability                              │ │
│  │ - Terminates EC2 instance                         │ │
│  │ - Returns termination status                      │ │
│  └───────────────────────────────────────────────────┘ │
│                          ↓                               │
│  ┌───────────────────────────────────────────────────┐ │
│  │ validate-system-health                            │ │
│  │ - Queries ELB target health                       │ │
│  │ - Retrieves CloudWatch metrics                    │ │
│  │ - Evaluates health criteria                       │ │
│  │ - Returns PASS/FAIL status                        │ │
│  └───────────────────────────────────────────────────┘ │
│                                                          │
│  IAM Roles: Least privilege with tag-based conditions   │
│  Logging: All execution details to CloudWatch           │
└─────────────────────────────────────────────────────────┘
```

## References

- [AWS Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [IAM Policy Conditions](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_condition.html)
- [CloudWatch Metrics for ALB](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-cloudwatch-metrics.html)
- [Auto Scaling Group API](https://docs.aws.amazon.com/autoscaling/ec2/APIReference/API_DescribeAutoScalingGroups.html)

---

**Week 2 Complete!** You now have three production-ready Lambda functions that can be orchestrated by Step Functions in Week 3.
