# Get Target Instance Lambda Function

## Purpose

Selects a random healthy EC2 instance from an Auto Scaling Group for chaos experiments.

## Function Details

- **Runtime**: Python 3.9
- **Timeout**: 30 seconds
- **Memory**: 128 MB

## Input

```json
{
  "autoScalingGroupName": "chaos-platform-asg"
}
```

## Output

### Success Response (200)

```json
{
  "statusCode": 200,
  "instanceId": "i-0123456789abcdef0",
  "availabilityZone": "us-east-1a",
  "healthStatus": "Healthy",
  "lifecycleState": "InService",
  "privateIpAddress": "10.0.1.45",
  "instanceType": "t3.micro",
  "launchTime": "2025-10-18T12:34:56",
  "totalHealthyInstances": 2,
  "autoScalingGroupName": "chaos-platform-asg",
  "message": "Selected instance i-0123456789abcdef0 from 2 healthy instances"
}
```

### Error Response (400/500)

```json
{
  "statusCode": 400,
  "error": "ValidationError",
  "message": "Missing required parameter: autoScalingGroupName"
}
```

## Logic Flow

1. Receive Auto Scaling Group name from event
2. Query Auto Scaling Group for all instances
3. Filter for instances that are:
   - HealthStatus = "Healthy"
   - LifecycleState = "InService"
   - Tagged with ChaosTarget=true
4. Select a random instance from the filtered list
5. Retrieve additional instance details from EC2
6. Return instance information

## Safety Features

- **Tag-based filtering**: Only selects instances tagged with `ChaosTarget=true`
- **Health check**: Only selects healthy instances
- **Lifecycle check**: Only selects instances that are InService
- **Error handling**: Comprehensive error handling for AWS API calls
- **Logging**: Detailed CloudWatch logging for audit trail

## IAM Permissions Required

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances"
      ],
      "Resource": "*"
    }
  ]
}
```

## Testing Locally

```python
# test_event.json
{
  "autoScalingGroupName": "chaos-platform-asg"
}
```

```bash
# Install dependencies
pip install -r requirements.txt

# Test locally
python -c "
import json
from lambda_function import lambda_handler

with open('test_event.json') as f:
    event = json.load(f)

result = lambda_handler(event, None)
print(json.dumps(result, indent=2, default=str))
"
```

## Environment Variables

None required.

## Dependencies

- boto3 (AWS SDK for Python)
- botocore

Both are included in the Lambda runtime by default, but versions are specified in requirements.txt for local testing.

## Error Scenarios

1. **No ASG name provided**: Returns 400 with validation error
2. **ASG not found**: Returns 500 with error message
3. **No healthy instances**: Returns 500 with error message
4. **AWS API error**: Returns 500 with AWS error details
5. **No instances tagged as ChaosTarget**: Returns 500 with error message

## Monitoring

CloudWatch Logs will contain:
- Input event details
- Number of instances found
- Number of healthy instances
- Selected instance details
- Any errors encountered

## Integration

This function is called by the Step Functions state machine as the first step in selecting a chaos experiment target.

**Next Function**: inject-failure (receives instanceId as input)
