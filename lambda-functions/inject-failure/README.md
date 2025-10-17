# Inject Failure Lambda Function

## Purpose

Safely terminates a specified EC2 instance to inject chaos into the system. This function includes multiple safety checks to prevent accidental termination of non-target instances.

## Function Details

- **Runtime**: Python 3.9
- **Timeout**: 30 seconds
- **Memory**: 128 MB

## Input

```json
{
  "instanceId": "i-0123456789abcdef0",
  "dryRun": false
}
```

### Parameters

- `instanceId` (required): EC2 instance ID to terminate
- `dryRun` (optional): If `true`, validates the request without actually terminating. Default: `false`

## Output

### Success Response - Terminated (200)

```json
{
  "statusCode": 200,
  "instanceId": "i-0123456789abcdef0",
  "action": "terminated",
  "previousState": "running",
  "currentState": "shutting-down",
  "availabilityZone": "us-east-1a",
  "instanceType": "t3.micro",
  "privateIpAddress": "10.0.1.45",
  "message": "Successfully initiated termination of instance i-0123456789abcdef0",
  "timestamp": "2025-10-18T14:30:00.123456",
  "chaosExperiment": true
}
```

### Success Response - Dry Run (200)

```json
{
  "statusCode": 200,
  "instanceId": "i-0123456789abcdef0",
  "action": "validated",
  "dryRun": true,
  "previousState": "running",
  "message": "Validation successful. Instance i-0123456789abcdef0 is eligible for termination",
  "instanceDetails": { ... },
  "timestamp": "2025-10-18T14:30:00.123456"
}
```

### Success Response - Already Terminated (200)

```json
{
  "statusCode": 200,
  "instanceId": "i-0123456789abcdef0",
  "action": "skipped",
  "previousState": "terminated",
  "currentState": "terminated",
  "message": "Instance i-0123456789abcdef0 is already terminated",
  "timestamp": "2025-10-18T14:30:00.123456"
}
```

### Error Response (400/500)

```json
{
  "statusCode": 500,
  "error": "InternalError",
  "message": "Instance i-xxx is not tagged as ChaosTarget=true. Refusing to terminate for safety reasons.",
  "timestamp": "2025-10-18T14:30:00.123456"
}
```

## Logic Flow

1. Receive instance ID from event
2. **SAFETY CHECK #1**: Verify instance exists
3. **SAFETY CHECK #2**: Verify instance is tagged with `ChaosTarget=true`
4. Get current instance details (state, type, IP, etc.)
5. Check if instance is already terminated/terminating
6. If dry run mode, return validation result only
7. Call EC2 TerminateInstances API
8. Return termination status and details

## Safety Features

### Multi-Layer Safety Checks

1. **Tag-based Protection**: ONLY terminates instances tagged with `ChaosTarget=true`
2. **State Verification**: Checks current state before terminating
3. **Dry Run Mode**: Allows validation without actual termination
4. **Instance Verification**: Confirms instance exists and is accessible
5. **Detailed Logging**: All actions logged to CloudWatch for audit trail

### What This Function Will NOT Do

- ❌ Terminate instances without `ChaosTarget=true` tag
- ❌ Terminate already terminated/terminating instances
- ❌ Operate without proper IAM permissions
- ❌ Terminate instances outside the specified instance ID

## IAM Permissions Required

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:TerminateInstances"
      ],
      "Resource": "arn:aws:ec2:*:*:instance/*",
      "Condition": {
        "StringEquals": {
          "ec2:ResourceTag/ChaosTarget": "true"
        }
      }
    }
  ]
}
```

**Note**: The TerminateInstances permission is restricted to instances with `ChaosTarget=true` tag using IAM conditions for an additional layer of safety.

## Testing Locally

### Dry Run Test

```json
{
  "instanceId": "i-0123456789abcdef0",
  "dryRun": true
}
```

```bash
pip install -r requirements.txt

python -c "
import json
from lambda_function import lambda_handler

event = {
    'instanceId': 'i-0123456789abcdef0',
    'dryRun': True
}

result = lambda_handler(event, None)
print(json.dumps(result, indent=2, default=str))
"
```

### Real Termination Test (BE CAREFUL!)

```json
{
  "instanceId": "i-0123456789abcdef0",
  "dryRun": false
}
```

**WARNING**: This will actually terminate the instance!

## Environment Variables

None required.

## Dependencies

- boto3 (AWS SDK for Python)
- botocore

Both are included in the Lambda runtime by default.

## Error Scenarios

1. **Missing instanceId**: Returns 400 validation error
2. **Instance not found**: Returns 500 with error message
3. **Instance not tagged as ChaosTarget**: Returns 500 refusing to terminate
4. **AWS API error**: Returns 500 with AWS error details
5. **Insufficient permissions**: Returns 500 with permission error

## Monitoring

CloudWatch Logs will contain:
- Input event (instance ID, dry run mode)
- Safety check results
- Instance details before termination
- Termination API response
- State changes (before -> after)
- Any errors or warnings

## Integration

This function is called by the Step Functions state machine after get-target-instance selects a victim.

**Previous Function**: get-target-instance (provides instanceId)
**Next Step**: Wait period (2-3 minutes) then validate-system-health

## Best Practices

1. **Always test with dry run first**: Use `dryRun: true` to validate without terminating
2. **Tag all target instances**: Ensure all chaos experiment instances have `ChaosTarget=true` tag
3. **Monitor CloudWatch**: Review logs after each experiment
4. **Use IAM conditions**: Enforce tag-based termination at IAM policy level
5. **Test in non-production first**: Validate the function in a test environment

## Example Usage in Step Functions

```json
{
  "Type": "Task",
  "Resource": "arn:aws:lambda:us-east-1:123456789012:function:chaos-inject-failure",
  "InputPath": "$",
  "ResultPath": "$.terminationResult",
  "Next": "Wait"
}
```

Input from previous step:
```json
{
  "instanceId": "i-0123456789abcdef0",
  "dryRun": false
}
```
