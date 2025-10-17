# Lambda Functions

This directory contains the AWS Lambda functions for the Chaos Engineering Platform.

## Week 2 Development

The following Lambda functions will be developed in Week 2:

### 1. get-target-instance
- **Purpose**: Select a random healthy EC2 instance from the Auto Scaling Group
- **Input**: Auto Scaling Group name
- **Output**: Instance ID of the target instance
- **Language**: Python 3.9

### 2. inject-failure
- **Purpose**: Terminate the selected EC2 instance
- **Input**: Instance ID
- **Output**: Termination status
- **Language**: Python 3.9
- **Permissions**: EC2:TerminateInstances (restricted to ChaosTarget tag)

### 3. validate-system-health
- **Purpose**: Query CloudWatch metrics to determine application health
- **Input**: Target Group ARN, Load Balancer ARN
- **Output**: Health status (pass/fail)
- **Metrics Checked**:
  - HealthyHostCount
  - UnHealthyHostCount
  - HTTPCode_Target_5XX_Count
  - TargetResponseTime
- **Language**: Python 3.9

## Directory Structure (Week 2)

```
lambda-functions/
├── get-target-instance/
│   ├── lambda_function.py
│   ├── requirements.txt
│   └── README.md
├── inject-failure/
│   ├── lambda_function.py
│   ├── requirements.txt
│   └── README.md
└── validate-system-health/
    ├── lambda_function.py
    ├── requirements.txt
    └── README.md
```

## Deployment

Lambda functions will be packaged and deployed via CloudFormation in Week 2.
