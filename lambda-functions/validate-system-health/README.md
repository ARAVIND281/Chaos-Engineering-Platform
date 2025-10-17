# Validate System Health Lambda Function

## Purpose

Queries CloudWatch metrics and ELB target health to determine if the target application is healthy. Used both before and after chaos experiments to validate system resilience.

## Function Details

- **Runtime**: Python 3.9
- **Timeout**: 60 seconds
- **Memory**: 256 MB

## Input

```json
{
  "targetGroupArn": "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/chaos-platform-tg/abc123",
  "loadBalancerArn": "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/chaos-platform-alb/xyz789",
  "expectedHealthyHosts": 2,
  "checkType": "post"
}
```

### Parameters

- `targetGroupArn` (required): ARN of the ELB target group
- `loadBalancerArn` (optional): ARN of the load balancer
- `expectedHealthyHosts` (optional): Minimum expected healthy hosts. Default: 2
- `checkType` (optional): 'pre' or 'post' experiment for logging. Default: 'unknown'

## Output

### Success Response - HEALTHY (200)

```json
{
  "statusCode": 200,
  "checkType": "post",
  "healthStatus": "PASS",
  "healthy": true,
  "timestamp": "2025-10-18T14:35:00.123456",
  "metrics": {
    "targetHealth": {
      "healthy": 2,
      "unhealthy": 0,
      "draining": 0,
      "unused": 0,
      "total": 2,
      "details": [
        {
          "targetId": "i-0123456789abcdef0",
          "state": "healthy",
          "reason": "N/A"
        },
        {
          "targetId": "i-0fedcba987654321",
          "state": "healthy",
          "reason": "N/A"
        }
      ]
    },
    "healthyHostCount": {
      "value": 2,
      "timestamp": "2025-10-18T14:34:00",
      "available": true,
      "unit": "Count"
    },
    "unhealthyHostCount": {
      "value": 0,
      "timestamp": "2025-10-18T14:34:00",
      "available": true,
      "unit": "Count"
    },
    "target5xxErrors": {
      "value": 0,
      "timestamp": "2025-10-18T14:34:00",
      "available": true,
      "unit": "Count"
    },
    "responseTime": {
      "value": 0.015,
      "timestamp": "2025-10-18T14:34:00",
      "available": true,
      "unit": "Seconds"
    },
    "requestCount": {
      "value": 150,
      "timestamp": "2025-10-18T14:34:00",
      "available": true,
      "unit": "Count"
    }
  },
  "evaluation": [
    {
      "check": "Target Health",
      "status": "PASS",
      "details": "2 healthy targets (expected >= 2)"
    },
    {
      "check": "HealthyHostCount Metric",
      "status": "PASS",
      "details": "CloudWatch reports 2 healthy hosts"
    },
    {
      "check": "5XX Errors",
      "status": "PASS",
      "details": "0 errors (threshold: 10)"
    },
    {
      "check": "Response Time",
      "status": "PASS",
      "details": "15.00ms (threshold: 2000ms)"
    }
  ],
  "summary": "System is HEALTHY: 2 targets healthy, all checks passed"
}
```

### Success Response - UNHEALTHY (200)

```json
{
  "statusCode": 200,
  "checkType": "post",
  "healthStatus": "FAIL",
  "healthy": false,
  "timestamp": "2025-10-18T14:35:00.123456",
  "metrics": { ... },
  "evaluation": [
    {
      "check": "Target Health",
      "status": "FAIL",
      "details": "Only 1 healthy targets (expected >= 2)"
    },
    {
      "check": "5XX Errors",
      "status": "FAIL",
      "details": "25 errors exceeds threshold of 10"
    }
  ],
  "summary": "System is UNHEALTHY: Insufficient healthy targets: 1/2, High error rate: 25 5XX errors"
}
```

## Logic Flow

1. Receive Target Group ARN and parameters
2. Extract resource names from ARNs
3. **Check Target Health** via ELBv2 API
   - Query target group for health status
   - Count healthy, unhealthy, draining targets
4. **Query CloudWatch Metrics** (5-minute lookback)
   - HealthyHostCount
   - UnHealthyHostCount
   - HTTPCode_Target_5XX_Count
   - TargetResponseTime
   - RequestCount
5. **Evaluate Health** against thresholds
   - Minimum healthy hosts
   - Maximum 5XX errors
   - Maximum response time
6. Return comprehensive health report

## Health Check Criteria

| Metric | Threshold | Status |
|--------|-----------|--------|
| Healthy Hosts | >= 2 | FAIL if below |
| 5XX Errors | <= 10 | FAIL if above |
| Response Time | <= 2000ms | WARN if above |
| Unhealthy Hosts | 0 | WARN if above |

### Thresholds (Configurable in Code)

```python
HEALTHY_HOST_THRESHOLD = 2      # Minimum healthy hosts
MAX_5XX_ERRORS = 10             # Maximum 5XX errors
MAX_RESPONSE_TIME_MS = 2000     # Maximum response time (ms)
METRIC_PERIOD_SECONDS = 60      # CloudWatch metric period
```

## IAM Permissions Required

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:DescribeTargetHealth",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DescribeTargetGroups"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:ListMetrics"
      ],
      "Resource": "*"
    }
  ]
}
```

## Testing Locally

```bash
pip install -r requirements.txt

python -c "
import json
from lambda_function import lambda_handler

event = {
    'targetGroupArn': 'arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/chaos-platform-tg/abc123',
    'loadBalancerArn': 'arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/chaos-platform-alb/xyz789',
    'expectedHealthyHosts': 2,
    'checkType': 'pre'
}

result = lambda_handler(event, None)
print(json.dumps(result, indent=2, default=str))
"
```

## Environment Variables

None required. All thresholds are defined as constants in the code.

## Dependencies

- boto3 (AWS SDK for Python)
- botocore

Both are included in the Lambda runtime by default.

## Error Scenarios

1. **Missing targetGroupArn**: Returns 400 validation error
2. **Invalid ARN format**: May fail to extract resource names
3. **No CloudWatch data**: Returns available=false for metrics
4. **AWS API error**: Returns 500 with error details
5. **Insufficient permissions**: Returns 500 with permission error

## Monitoring

CloudWatch Logs will contain:
- Input parameters (ARNs, expected hosts, check type)
- Metric query results
- Health evaluation details
- Pass/fail determination
- Summary of health status

## Use Cases

### 1. Pre-Experiment Validation

Ensures the system is healthy before injecting chaos:

```json
{
  "checkType": "pre",
  "expectedHealthyHosts": 2
}
```

If this fails, the chaos experiment should abort.

### 2. Post-Experiment Validation

Verifies the system recovered after chaos:

```json
{
  "checkType": "post",
  "expectedHealthyHosts": 2
}
```

If this fails, the experiment is marked as unsuccessful.

### 3. Continuous Health Monitoring

Can be called independently to monitor system health:

```json
{
  "checkType": "monitoring"
}
```

## Integration with Step Functions

### Pre-Experiment Check

```json
{
  "Type": "Task",
  "Resource": "arn:aws:lambda:...:function:chaos-validate-health",
  "ResultPath": "$.preExperimentHealth",
  "Next": "CheckPreHealth"
}
```

### Post-Experiment Check

```json
{
  "Type": "Task",
  "Resource": "arn:aws:lambda:...:function:chaos-validate-health",
  "ResultPath": "$.postExperimentHealth",
  "Next": "EvaluateResult"
}
```

## Customization

To adjust health check criteria, modify these constants in the code:

```python
# lambda_function.py

HEALTHY_HOST_THRESHOLD = 3      # Require 3 healthy hosts
MAX_5XX_ERRORS = 5              # Stricter error tolerance
MAX_RESPONSE_TIME_MS = 1000     # Require faster response
METRIC_PERIOD_SECONDS = 30      # More frequent sampling
```

## CloudWatch Metrics Used

### From AWS/ApplicationELB Namespace

1. **HealthyHostCount**
   - Dimensions: TargetGroup, LoadBalancer
   - Statistic: Average
   - Purpose: Primary health indicator

2. **UnHealthyHostCount**
   - Dimensions: TargetGroup, LoadBalancer
   - Statistic: Average
   - Purpose: Detect unhealthy instances

3. **HTTPCode_Target_5XX_Count**
   - Dimensions: LoadBalancer
   - Statistic: Sum
   - Purpose: Detect application errors

4. **TargetResponseTime**
   - Dimensions: LoadBalancer
   - Statistic: Average
   - Purpose: Detect performance degradation

5. **RequestCount**
   - Dimensions: LoadBalancer
   - Statistic: Sum
   - Purpose: Verify traffic is flowing

## Best Practices

1. **Always run pre-experiment check**: Don't inject chaos into an already unhealthy system
2. **Wait before post-experiment check**: Give the system time to recover (2-3 minutes)
3. **Review CloudWatch logs**: Understand why health checks pass or fail
4. **Adjust thresholds for your application**: Default values may not suit all workloads
5. **Monitor trends**: Track health check results over time

## Example Step Functions Integration

```json
{
  "CheckPreHealth": {
    "Type": "Choice",
    "Choices": [
      {
        "Variable": "$.preExperimentHealth.healthy",
        "BooleanEquals": true,
        "Next": "SelectTarget"
      }
    ],
    "Default": "ExperimentAborted"
  }
}
```
