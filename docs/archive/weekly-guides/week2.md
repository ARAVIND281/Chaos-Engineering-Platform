# Week 2 - COMPLETE ✓

## Summary

Week 2 of the Chaos Engineering Platform has been successfully completed! All three Lambda functions are built, tested, and ready for Step Functions orchestration in Week 3.

## Deliverables Completed

### 📦 Lambda Functions (Python 3.9)

#### 1. Get-Target-Instance ([lambda-functions/get-target-instance/](lambda-functions/get-target-instance/))
**Purpose**: Selects a random healthy EC2 instance from Auto Scaling Group

**Features**:
- Queries Auto Scaling Group API
- Filters for healthy, InService instances
- Tag-based safety check (ChaosTarget=true)
- Random selection algorithm
- Detailed instance information output

**Code Statistics**:
- Lines of Code: ~240
- Functions: 4
- Error Handling: Comprehensive

**IAM Permissions**: Read-only (ASG, EC2)

#### 2. Inject-Failure ([lambda-functions/inject-failure/](lambda-functions/inject-failure/))
**Purpose**: Safely terminates EC2 instances with multiple safety layers

**Features**:
- Multi-layer safety checks
- Tag verification (ChaosTarget=true required)
- Dry run mode for testing
- State validation (skip if already terminated)
- IAM condition enforcement
- Comprehensive audit logging

**Code Statistics**:
- Lines of Code: ~270
- Functions: 4
- Safety Checks: 3 layers

**IAM Permissions**: EC2 DescribeInstances (all), TerminateInstances (conditional on tag)

#### 3. Validate-System-Health ([lambda-functions/validate-system-health/](lambda-functions/validate-system-health/))
**Purpose**: Comprehensive health validation using CloudWatch and ELB metrics

**Features**:
- Real-time target health check via ELBv2 API
- CloudWatch metrics query (5-minute lookback)
- Multi-criteria health evaluation
- Pass/fail determination with detailed reporting
- Configurable thresholds

**Metrics Analyzed**:
- HealthyHostCount
- UnHealthyHostCount
- HTTPCode_Target_5XX_Count
- TargetResponseTime
- RequestCount

**Code Statistics**:
- Lines of Code: ~380
- Functions: 10
- Health Checks: 4 criteria

**IAM Permissions**: Read-only (ELB, CloudWatch)

### 🏗️ Infrastructure as Code

#### CloudFormation Template ([infrastructure/chaos-lambda-functions.yaml](infrastructure/chaos-lambda-functions.yaml))
**Purpose**: Deploys all Lambda functions with proper IAM roles

**Resources Created**:
- 3 IAM Roles (least privilege, one per function)
- 3 Lambda Functions (Python 3.9 runtime)
- 3 CloudWatch Log Groups (7-day retention)

**IAM Security**:
- Least privilege principle enforced
- Tag-based conditional policies for termination
- Separate roles for each function
- No cross-function access

**Outputs**: 9 exports (function ARNs, names, role ARNs)

### 🚀 Automation Scripts

#### 1. Deploy Script ([scripts/deploy-lambda-functions.sh](scripts/deploy-lambda-functions.sh))
**Purpose**: Automated deployment of all Lambda functions

**Features**:
- Creates CloudFormation stack
- Packages functions into ZIP files
- Updates Lambda function code
- Verifies deployments
- Displays testing commands

**Lines of Code**: ~200

#### 2. Test Script ([scripts/test-lambda-functions.sh](scripts/test-lambda-functions.sh))
**Purpose**: Automated testing of Lambda functions

**Features**:
- Retrieves infrastructure details automatically
- Tests all functions or individual functions
- Dry run mode for inject-failure
- Formatted output with status indicators
- Chain testing (all functions in sequence)

**Test Modes**:
- `get-target` - Test target selection
- `inject-failure` - Test termination (dry run)
- `validate-health` - Test health validation
- `all` - Test all functions sequentially

**Lines of Code**: ~250

### 📚 Documentation

#### 1. Week 2 Implementation Guide ([docs/week2-guide.md](docs/week2-guide.md))
**Contents**:
- Detailed function descriptions
- Deployment procedures
- Testing scenarios (3 comprehensive scenarios)
- Troubleshooting guide
- Local testing instructions
- Cost breakdown
- Success criteria checklist

**Lines**: ~450

#### 2. Function-Specific READMEs
Each Lambda function has detailed documentation:
- Input/output specifications
- Logic flow diagrams
- IAM permissions required
- Testing examples
- Error scenarios
- Integration notes

**Total Documentation Lines**: ~1,000+

#### 3. Updated Main README ([README.md](README.md))
- Updated timeline (Week 2 complete)
- Added Week 2 quick start commands
- Updated directory structure

## Project Statistics

### Week 2 Additions

- **New Files**: 11
- **Lines of Code**: ~1,400+
- **Lines of Documentation**: ~1,000+
- **Lambda Functions**: 3
- **IAM Roles**: 3
- **CloudFormation Resources**: 9
- **Automation Scripts**: 2

### Cumulative Project Stats

- **Total Files**: 26
- **Total Lines of Code/Config**: 3,400+
- **AWS Resources Defined**: 44+
- **Git Commits**: 7 (+ Week 2 commit pending)
- **AWS Services**: 14+

## Code Quality

### Python Code Standards

- ✅ PEP 8 compliant formatting
- ✅ Comprehensive docstrings
- ✅ Type hints where beneficial
- ✅ Error handling for all AWS API calls
- ✅ Logging at appropriate levels
- ✅ No hardcoded values
- ✅ Modular function design

### Security Best Practices

- ✅ Least privilege IAM policies
- ✅ Tag-based resource targeting
- ✅ IAM condition enforcement
- ✅ Multiple safety check layers
- ✅ Dry run capability
- ✅ Comprehensive audit logging
- ✅ No secrets in code

### Testing Coverage

- ✅ Manual testing procedures documented
- ✅ Automated test scripts provided
- ✅ AWS Console testing instructions
- ✅ Local testing examples
- ✅ Dry run mode for destructive operations
- ✅ Error scenario testing

## AWS Services Utilized

### New in Week 2

1. **AWS Lambda** - Serverless compute for chaos functions
2. **AWS IAM** - Fine-grained access control
3. **CloudWatch Logs** - Function execution logging

### Continued from Week 1

4. **Amazon EC2** - Target instances
5. **Auto Scaling** - Instance lifecycle management
6. **Elastic Load Balancing** - Health checks and metrics
7. **Amazon CloudWatch** - Metrics and monitoring
8. **AWS CloudFormation** - Infrastructure as Code

## Function Capabilities

### Get-Target-Instance

**Input**:
```json
{
  "autoScalingGroupName": "chaos-platform-asg"
}
```

**Output**:
```json
{
  "statusCode": 200,
  "instanceId": "i-0123456789abcdef0",
  "availabilityZone": "us-east-1a",
  "healthStatus": "Healthy",
  "totalHealthyInstances": 2
}
```

### Inject-Failure

**Input**:
```json
{
  "instanceId": "i-0123456789abcdef0",
  "dryRun": false
}
```

**Output**:
```json
{
  "statusCode": 200,
  "action": "terminated",
  "previousState": "running",
  "currentState": "shutting-down",
  "timestamp": "2025-10-18T14:30:00"
}
```

### Validate-System-Health

**Input**:
```json
{
  "targetGroupArn": "arn:aws:elasticloadbalancing:...",
  "expectedHealthyHosts": 2,
  "checkType": "post"
}
```

**Output**:
```json
{
  "statusCode": 200,
  "healthStatus": "PASS",
  "healthy": true,
  "metrics": { ... },
  "evaluation": [ ... ],
  "summary": "System is HEALTHY"
}
```

## Testing Procedures

### Automated Testing

```bash
# Deploy functions
./scripts/deploy-lambda-functions.sh

# Test all functions
./scripts/test-lambda-functions.sh all

# Test individually
./scripts/test-lambda-functions.sh get-target
./scripts/test-lambda-functions.sh inject-failure
./scripts/test-lambda-functions.sh validate-health
```

### Manual Testing via AWS Console

1. Navigate to Lambda console
2. Select function
3. Create test event with sample payload
4. Execute and review logs

### Local Testing

```bash
cd lambda-functions/get-target-instance
pip3 install -r requirements.txt
python3 -c "from lambda_function import lambda_handler; import json; print(json.dumps(lambda_handler({'autoScalingGroupName':'chaos-platform-asg'}, None), indent=2, default=str))"
```

## Cost Analysis

### Week 2 Costs

**Lambda**:
- Requests: Free tier (1M/month)
- Duration: Free tier (400,000 GB-seconds/month)
- Estimated: <$1/month

**CloudWatch Logs**:
- Log ingestion: $0.50/GB
- Log storage (7-day retention): Minimal
- Estimated: <$2/month

**Total Week 2 Cost**: ~$3/month (negligible during development/testing)

### Cumulative Project Cost

- Week 1 (VPC + Target App): ~$40/month
- Week 2 (Lambda Functions): ~$3/month
- **Total**: ~$43/month

**Note**: Run `./scripts/cleanup.sh` when not actively testing to avoid charges!

## Success Criteria - All Met ✓

- ✅ Get-Target-Instance function implemented
- ✅ Inject-Failure function implemented with safety checks
- ✅ Validate-System-Health function implemented
- ✅ All functions use least privilege IAM roles
- ✅ CloudFormation template created
- ✅ Deployment automation created
- ✅ Testing automation created
- ✅ Comprehensive documentation written
- ✅ Local testing procedures documented
- ✅ Safety features verified (tag-based targeting)
- ✅ Dry run mode tested
- ✅ CloudWatch logging verified
- ✅ All functions callable via AWS CLI
- ✅ Integration-ready for Step Functions

## How to Deploy & Test

### Quick Start

```bash
cd "/Users/aravinds/project/Chaos Engineering"

# Deploy Lambda functions
./scripts/deploy-lambda-functions.sh

# Test all functions
./scripts/test-lambda-functions.sh all

# View logs
aws logs tail /aws/lambda/chaos-platform-get-target-instance --follow
```

### Detailed Testing

See [docs/week2-guide.md](docs/week2-guide.md) for:
- Step-by-step deployment
- 3 testing scenarios
- Troubleshooting guide
- Cost optimization tips

## Next Steps: Week 3

With Week 2 complete, we're ready for Week 3 orchestration:

### Step Functions State Machine

**Components to Build**:
1. State machine definition (Amazon States Language)
2. IAM role for Step Functions
3. Integration with all three Lambda functions
4. Error handling and retry logic
5. Wait states for recovery periods
6. Conditional logic based on health checks

### EventBridge Scheduling (Optional)

**Components to Build**:
1. EventBridge rule for scheduling
2. Cron expression for experiment timing
3. Integration with Step Functions
4. Manual triggering capability

### Week 3 Deliverables

- Step Functions state machine (JSON/YAML)
- CloudFormation template for orchestration
- Deployment scripts
- End-to-end testing
- Documentation updates

## Repository Status

- **Location**: `/Users/aravinds/project/Chaos Engineering`
- **Branch**: main
- **Commits**: 7 (Week 1) + Week 2 commit pending
- **Status**: Week 2 Complete, Ready for Week 3 ✓

## Key Files Reference

| File | Purpose | Lines |
|------|---------|-------|
| lambda-functions/get-target-instance/lambda_function.py | Target selection | 240 |
| lambda-functions/inject-failure/lambda_function.py | Instance termination | 270 |
| lambda-functions/validate-system-health/lambda_function.py | Health validation | 380 |
| infrastructure/chaos-lambda-functions.yaml | Lambda deployment | 280 |
| scripts/deploy-lambda-functions.sh | Deployment automation | 200 |
| scripts/test-lambda-functions.sh | Testing automation | 250 |
| docs/week2-guide.md | Implementation guide | 450 |

## Lessons Learned

### Best Practices Implemented

1. **Safety First**: Multiple layers of safety checks prevent accidental damage
2. **Least Privilege**: Each function has only the permissions it needs
3. **Dry Run Mode**: Test destructive operations without actual impact
4. **Comprehensive Logging**: Every action is logged for audit trails
5. **Tag-Based Targeting**: Explicit tagging required for chaos targets
6. **Error Handling**: Graceful handling of all error scenarios
7. **Automation**: Deployment and testing fully automated

### Technical Achievements

- ✅ Serverless architecture
- ✅ Event-driven design
- ✅ Infrastructure as Code
- ✅ Automated testing
- ✅ Production-grade error handling
- ✅ Security-first design
- ✅ Cost-optimized implementation

## Resources for Learning

- [AWS Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [IAM Policy Conditions](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_condition.html)
- [CloudWatch Metrics](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/working_with_metrics.html)
- [Auto Scaling API](https://docs.aws.amazon.com/autoscaling/ec2/APIReference/Welcome.html)
- [Chaos Engineering Principles](https://principlesofchaos.org/)

---

## ✅ Week 2: COMPLETE AND READY FOR WEEK 3

**Team Member**: Aravind S

**Completion Date**: 2025-10-18

**Status**: All three Lambda functions built, tested, documented, and ready for Step Functions orchestration.

**Ready for**: Week 3 - Step Functions State Machine

---

*This week demonstrated professional serverless development practices including least privilege security, comprehensive testing, and production-grade error handling.*
