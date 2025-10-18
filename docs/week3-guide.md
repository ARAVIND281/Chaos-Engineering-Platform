# Week 3 Implementation Guide - Step Functions Orchestration

## Objective
Create the Step Functions state machine that orchestrates the complete chaos engineering workflow, integrating all three Lambda functions with error handling, retry logic, and optional automated scheduling.

## What We Built

### 1. Step Functions State Machine
**Purpose**: Orchestrates the complete chaos engineering experiment workflow

**File**: [step-functions/chaos-experiment-workflow.json](../step-functions/chaos-experiment-workflow.json)

**Workflow States**:
1. **LogExperimentStart** - Records experiment metadata
2. **PreExperimentHealthCheck** - Validates system is healthy
3. **EvaluatePreExperimentHealth** - Decision: Proceed or abort?
4. **SelectTargetInstance** - Chooses random healthy instance
5. **RecordTargetSelection** - Logs selected target
6. **InjectFailure** - Terminates the instance
7. **WaitForRecovery** - Waits 3 minutes for auto-scaling
8. **PostExperimentHealthCheck** - Validates recovery
9. **EvaluatePostExperimentHealth** - Decision: Success or failure?
10. **ExperimentSucceeded** / **SystemDidNotRecover** - Final states

**Error Handling States**:
- ExperimentAbortedUnhealthy
- ExperimentFailedPreCheck
- ExperimentFailedTargetSelection
- ExperimentFailedInjection
- ExperimentFailedPostCheck

**Key Features**:
- Retry logic with exponential backoff
- Comprehensive error handling
- Detailed logging at each step
- Pass/fail determination
- Execution metadata tracking

### 2. CloudFormation Template
**Purpose**: Deploys Step Functions with IAM roles and EventBridge scheduling

**File**: [infrastructure/chaos-step-functions.yaml](../infrastructure/chaos-step-functions.yaml)

**Resources Created**:
- Step Functions IAM Role (with Lambda invoke permissions)
- Step Functions State Machine
- CloudWatch Log Group (14-day retention)
- EventBridge IAM Role (optional)
- EventBridge Schedule Rule (optional)

**Parameters**:
- `EnableScheduling`: Enable/disable automated experiments
- `ScheduleExpression`: Cron expression for scheduling (default: 2 AM daily)

### 3. Deployment Script
**Purpose**: Automated deployment of Step Functions infrastructure

**File**: [scripts/deploy-step-functions.sh](../scripts/deploy-step-functions.sh)

**Features**:
- Prerequisite validation (Lambda functions, target app)
- Automatic infrastructure detail retrieval
- CloudFormation stack deployment
- Scheduling configuration
- Output display with useful commands

**Usage**:
```bash
# Deploy without scheduling (manual only)
./scripts/deploy-step-functions.sh

# Deploy with automated scheduling
./scripts/deploy-step-functions.sh true
```

### 4. Manual Execution Script
**Purpose**: Trigger chaos experiments manually with real-time monitoring

**File**: [scripts/run-chaos-experiment.sh](../scripts/run-chaos-experiment.sh)

**Features**:
- Interactive confirmation prompt
- Automatic payload generation
- Real-time execution monitoring
- Result parsing and display
- Execution history
- AWS Console links

**Workflow**:
1. Retrieves infrastructure details
2. Displays experiment summary
3. Asks for confirmation
4. Starts Step Functions execution
5. Monitors status in real-time
6. Displays final results
7. Shows useful commands

## Architecture Overview

### Complete Workflow Visualization

```
START
  ↓
Log Experiment Start
  ↓
Pre-Experiment Health Check
  ↓
Healthy? ──No──> Experiment Aborted
  ↓ Yes
Select Target Instance
  ↓
Record Selection
  ↓
Inject Failure (Terminate Instance)
  ↓
Wait 180 seconds
  ↓
Post-Experiment Health Check
  ↓
Recovered? ──No──> System Did Not Recover (FAIL)
  ↓ Yes
Experiment Succeeded (SUCCESS)
  ↓
END
```

### Integration with Week 1 & 2

```
┌──────────────────────────────────────────────────────┐
│            Step Functions (Week 3)                   │
│                                                       │
│  ┌────────────────────────────────────────────────┐ │
│  │ State Machine: chaos-platform-chaos-experiment │ │
│  └────────────────────────────────────────────────┘ │
│                                                       │
│    ↓ Invokes         ↓ Invokes        ↓ Invokes     │
│                                                       │
│  Lambda             Lambda            Lambda         │
│  (Week 2)           (Week 2)          (Week 2)       │
│  ┌──────┐          ┌──────┐          ┌──────┐       │
│  │ Get  │ ──────> │Inject│ ──────> │Valid.│        │
│  │Target│          │Fail  │          │Health│        │
│  └──────┘          └──────┘          └──────┘       │
│                                                       │
│    ↓                    ↓                  ↓          │
└──────────────────────────────────────────────────────┘
         ↓                                    ↓
┌──────────────────────────────────────────────────────┐
│           Target Application (Week 1)                │
│                                                       │
│  Auto Scaling Group → Instances → Load Balancer     │
└──────────────────────────────────────────────────────┘
```

## Prerequisites

Before starting Week 3:

1. ✅ Week 1 complete (VPC and Target Application deployed)
2. ✅ Week 2 complete (Lambda functions deployed)
3. ✅ AWS CLI configured
4. ✅ Target application healthy and accessible

## Deployment Steps

### Step 1: Deploy Step Functions (Manual Mode)

```bash
cd "/Users/aravinds/project/Chaos Engineering"
./scripts/deploy-step-functions.sh
```

This deploys:
- Step Functions state machine
- IAM role for Step Functions
- CloudWatch log group
- **No scheduling** (manual execution only)

**Expected time**: 1-2 minutes

### Step 2: Verify Deployment

```bash
# Check state machine
aws stepfunctions list-state-machines \
  --query 'stateMachines[?starts_with(name, `chaos-platform`)].name'

# View state machine definition
aws stepfunctions describe-state-machine \
  --state-machine-arn <ARN>
```

### Step 3: Run First Chaos Experiment

```bash
./scripts/run-chaos-experiment.sh
```

**Experiment Flow**:
1. Script displays experiment details
2. Asks for confirmation
3. Starts execution
4. Monitors in real-time (~3-4 minutes)
5. Displays results

### Step 4: Review Results

**View in AWS Console**:
- Go to Step Functions > State Machines
- Click on `chaos-platform-chaos-experiment`
- View execution history and details

**View CloudWatch Logs**:
```bash
aws logs tail /aws/vendedlogs/states/chaos-platform-chaos-experiment --follow
```

## Input Payload Structure

```json
{
  "experimentId": "manual-20251018-143000",
  "experimentStartTime": "2025-10-18T14:30:00Z",
  "autoScalingGroupName": "chaos-platform-asg",
  "targetGroupArn": "arn:aws:elasticloadbalancing:...",
  "loadBalancerArn": "arn:aws:elasticloadbalancing:...",
  "expectedHealthyHosts": 2
}
```

## Output Structure

### Success Output

```json
{
  "status": "SUCCESS",
  "message": "Chaos experiment completed successfully. System demonstrated resilience.",
  "experimentId": "manual-20251018-143000",
  "experimentStartTime": "2025-10-18T14:30:00Z",
  "experimentEndTime": "2025-10-18T14:33:45Z",
  "targetInstance": {
    "instanceId": "i-0123456789abcdef0",
    "availabilityZone": "us-east-1a"
  },
  "healthChecks": {
    "preExperiment": {
      "status": "PASS",
      "summary": "System is HEALTHY: 2 targets healthy, all checks passed"
    },
    "postExperiment": {
      "status": "PASS",
      "summary": "System is HEALTHY: 2 targets healthy, all checks passed"
    }
  },
  "conclusion": "System successfully withstood infrastructure failure and auto-recovered"
}
```

### Failure Output

```json
{
  "status": "FAILED",
  "reason": "SystemRecoveryFailure",
  "message": "System did not return to healthy state after chaos injection",
  "experimentId": "manual-20251018-143000",
  "targetInstance": {
    "instanceId": "i-0123456789abcdef0"
  },
  "recommendation": "Review Auto Scaling configuration and instance health checks"
}
```

## Automated Scheduling (Optional)

### Enable Automated Experiments

```bash
# Deploy with scheduling enabled
./scripts/deploy-step-functions.sh true
```

This enables:
- EventBridge schedule rule
- Automatic execution at 2 AM daily (default)
- EventBridge IAM role

### Custom Schedule

Edit the CloudFormation parameter:

```yaml
ScheduleExpression: 'cron(0 2 * * ? *)'  # 2 AM daily
# OR
ScheduleExpression: 'rate(12 hours)'      # Every 12 hours
```

Then redeploy:
```bash
./scripts/deploy-step-functions.sh true
```

### Disable Scheduling

```bash
# Redeploy without scheduling
./scripts/deploy-step-functions.sh false
```

### Cron Expression Examples

| Expression | Description |
|------------|-------------|
| `cron(0 2 * * ? *)` | 2 AM every day |
| `cron(0 0/6 * * ? *)` | Every 6 hours |
| `cron(0 22 * * 1-5 *)` | 10 PM weekdays only |
| `cron(0 12 * * SUN *)` | Noon every Sunday |
| `rate(1 hour)` | Every hour |
| `rate(30 minutes)` | Every 30 minutes |

## Testing Scenarios

### Scenario 1: Successful Resilience Test

**Expected Outcome**: System passes both health checks and auto-recovers

```bash
./scripts/run-chaos-experiment.sh
```

**What Happens**:
1. Pre-check: PASS (2 healthy instances)
2. Terminates 1 instance
3. Wait 3 minutes
4. Auto Scaling launches replacement
5. Post-check: PASS (2 healthy instances)
6. Result: SUCCESS

### Scenario 2: Pre-Experiment Unhealthy

**Setup**: Manually terminate all instances

```bash
# Terminate all instances
ASG_NAME=chaos-platform-asg
INSTANCES=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $ASG_NAME \
  --query 'AutoScalingGroups[0].Instances[*].InstanceId' \
  --output text)

for INSTANCE in $INSTANCES; do
  aws ec2 terminate-instances --instance-ids $INSTANCE
done

# Run experiment (should abort)
./scripts/run-chaos-experiment.sh
```

**Expected Outcome**: ABORTED (pre-experiment unhealthy)

### Scenario 3: Recovery Failure

**Setup**: Set Auto Scaling min/max to 1, then run experiment

```bash
# Reduce Auto Scaling capacity
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name chaos-platform-asg \
  --min-size 1 \
  --desired-capacity 1 \
  --max-size 1

# Wait for scaling down

# Run experiment (may fail post-check)
./scripts/run-chaos-experiment.sh

# Restore capacity
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name chaos-platform-asg \
  --min-size 2 \
  --desired-capacity 2 \
  --max-size 4
```

**Expected Outcome**: FAILED (insufficient healthy hosts)

## Monitoring & Observability

### CloudWatch Logs

**Step Functions Execution Logs**:
```bash
aws logs tail /aws/vendedlogs/states/chaos-platform-chaos-experiment --follow
```

**Lambda Function Logs** (from within experiment):
```bash
aws logs tail /aws/lambda/chaos-platform-get-target-instance --follow
aws logs tail /aws/lambda/chaos-platform-inject-failure --follow
aws logs tail /aws/lambda/chaos-platform-validate-system-health --follow
```

### CloudWatch Metrics

**Step Functions Metrics**:
- ExecutionsStarted
- ExecutionsSucceeded
- ExecutionsFailed
- ExecutionTime

**View in Console**: CloudWatch > Metrics > States

### Execution History

```bash
# List recent executions
aws stepfunctions list-executions \
  --state-machine-arn <ARN> \
  --max-items 10

# Get execution details
aws stepfunctions describe-execution \
  --execution-arn <EXECUTION_ARN>

# Get execution history (all state transitions)
aws stepfunctions get-execution-history \
  --execution-arn <EXECUTION_ARN>
```

## Troubleshooting

### Issue: Execution fails immediately

**Check IAM permissions**:
```bash
# Verify Step Functions role
aws iam get-role --role-name chaos-platform-step-functions-role

# Check role can invoke Lambda
aws iam simulate-principal-policy \
  --policy-source-arn <ROLE_ARN> \
  --action-names lambda:InvokeFunction \
  --resource-arns <LAMBDA_ARN>
```

### Issue: Pre-check always fails

**Check target application health**:
```bash
./scripts/verify-deployment.sh
```

**Ensure minimum 2 healthy instances**:
```bash
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names chaos-platform-asg
```

### Issue: Post-check fails (system doesn't recover)

**Common causes**:
1. Auto Scaling grace period too short
2. Instance startup time too long
3. Wait period insufficient (< 180 seconds)

**Solutions**:
- Increase wait time in state machine (edit WaitForRecovery state)
- Check Auto Scaling health check grace period (default: 300s)
- Verify AMI boots quickly

### Issue: State machine not found

**Verify deployment**:
```bash
aws cloudformation describe-stacks \
  --stack-name chaos-platform-step-functions
```

**Redeploy if needed**:
```bash
./scripts/deploy-step-functions.sh
```

## Cost Considerations

### Step Functions Costs

**Standard Workflows**:
- First 4,000 state transitions/month: Free
- After: $0.025 per 1,000 state transitions

**Example Calculation**:
- 1 experiment = ~12 state transitions
- 30 experiments/month = 360 transitions
- Cost: **FREE** (under 4,000 threshold)

### CloudWatch Logs

- Log ingestion: $0.50/GB
- Log storage (14-day retention): $0.03/GB/month
- Estimated: <$1/month

### EventBridge (if enabled)

- First 14 million events/month: FREE
- Scheduled experiments = minimal events
- Cost: **FREE**

**Total Week 3 Cost**: ~$1/month (negligible)

## Success Criteria

✅ **Week 3 is complete when**:
1. Step Functions state machine deployed
2. IAM roles properly configured
3. CloudWatch logging enabled
4. Manual experiment execution successful
5. Experiment demonstrates system resilience
6. All error paths tested
7. Execution history visible in console
8. (Optional) Automated scheduling configured

## Best Practices

### 1. Start with Manual Execution

Always test manually before enabling scheduling:
```bash
# Test multiple times manually
./scripts/run-chaos-experiment.sh
# Verify success consistently
# Then enable scheduling
./scripts/deploy-step-functions.sh true
```

### 2. Monitor First Few Scheduled Runs

When scheduling is enabled:
- Monitor first 3-5 automated runs
- Check for consistent success
- Review CloudWatch logs
- Adjust schedule if needed

### 3. Set Appropriate Wait Times

Default wait time: 180 seconds (3 minutes)

Adjust based on your application:
- Fast startup: 120 seconds
- Slow startup: 240-300 seconds

### 4. Tag Experiments

Use meaningful experiment IDs:
```json
{
  "experimentId": "pre-deployment-validation-20251018",
  ...
}
```

### 5. Review Execution History Weekly

```bash
# Get summary of last week's experiments
aws stepfunctions list-executions \
  --state-machine-arn <ARN> \
  --status-filter SUCCEEDED \
  --max-items 50
```

## Next Steps: Week 4

In Week 4, we will:
1. **End-to-End Testing** - Run comprehensive test scenarios
2. **Documentation Finalization** - Complete all guides
3. **Presentation Preparation** - Create demo and slides
4. **Cleanup Procedures** - Document proper shutdown
5. **Future Enhancements** - Identify potential improvements

## Resources

- [AWS Step Functions Documentation](https://docs.aws.amazon.com/step-functions/)
- [Amazon States Language](https://states-language.net/spec.html)
- [EventBridge Schedule Expressions](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-create-rule-schedule.html)
- [Step Functions Best Practices](https://docs.aws.amazon.com/step-functions/latest/dg/best-practices.html)
- [Chaos Engineering Principles](https://principlesofchaos.org/)

---

**Week 3 Complete!** You now have a fully orchestrated chaos engineering platform that can automatically validate system resilience!
