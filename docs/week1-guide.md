# Week 1 Implementation Guide

## Objective
Set up AWS account, deploy VPC infrastructure, and create a highly available target application.

## What We Built

### 1. VPC Infrastructure (`vpc-infrastructure.yaml`)
- Custom VPC with CIDR 10.0.0.0/16
- 2 Public Subnets (10.0.1.0/24, 10.0.2.0/24) across 2 Availability Zones
- 2 Private Subnets (10.0.11.0/24, 10.0.12.0/24) across 2 Availability Zones
- Internet Gateway for public internet access
- 2 NAT Gateways (one per AZ) for private subnet internet access
- Route Tables configured for public and private subnets
- VPC Flow Logs to CloudWatch for network monitoring

### 2. Target Application (`target-application.yaml`)
- **Application Load Balancer (ALB)**: Internet-facing, distributes traffic across instances
- **Auto Scaling Group**: 2-4 EC2 instances (t3.micro)
  - Minimum: 2 instances
  - Desired: 2 instances
  - Maximum: 4 instances
- **Launch Template**: Defines instance configuration
  - Amazon Linux 2023 AMI
  - Apache web server
  - Custom HTML page showing instance metadata
  - CloudWatch agent for metrics and logs
- **Security Groups**:
  - ALB SG: Allows HTTP (80) and HTTPS (443) from internet
  - Web Server SG: Allows HTTP (80) from ALB only
- **Health Checks**: ALB checks instance health every 30 seconds
- **IAM Roles**: EC2 instances have permissions for CloudWatch and SSM
- **CloudWatch Alarms**: Monitor healthy host count, response time, and errors

### 3. Deployment Scripts
- `deploy.sh`: Automated deployment of all infrastructure
- `cleanup.sh`: Complete cleanup of all AWS resources
- `verify-deployment.sh`: Comprehensive verification of high availability

## Prerequisites

Before starting, ensure you have:

1. **AWS Account**: With administrative access
2. **AWS CLI**: Installed and configured
   ```bash
   aws --version
   aws configure
   ```
3. **Git**: For version control
4. **jq**: JSON processor (for verification script)
   ```bash
   # macOS
   brew install jq

   # Linux
   sudo apt-get install jq
   ```

## Deployment Steps

### Step 1: Clone or Navigate to Project Directory

```bash
cd "/Users/aravinds/project/Chaos Engineering"
```

### Step 2: Make Scripts Executable

```bash
chmod +x scripts/*.sh
```

### Step 3: Set AWS Region (Optional)

```bash
export AWS_REGION=us-east-1
```

### Step 4: Deploy Infrastructure

```bash
./scripts/deploy.sh
```

This script will:
1. Validate AWS credentials
2. Deploy VPC infrastructure (3-5 minutes)
3. Deploy target application (5-10 minutes)
4. Output the Load Balancer URL

### Step 5: Verify Deployment

```bash
./scripts/verify-deployment.sh
```

This will check:
- Auto Scaling Group configuration
- Instance health status
- Target Group health
- Application availability (5 requests)
- Multi-AZ distribution

## Manual Verification

### 1. Access the Application

Open the Load Balancer URL in a browser (provided at end of deployment).

You should see a page displaying:
- Instance ID
- Availability Zone
- Private IP
- Application status

### 2. Test High Availability Manually

#### Via AWS Console:

1. **Navigate to EC2 > Auto Scaling Groups**
2. **Select**: `chaos-platform-asg`
3. **View**: Instance distribution across AZs

#### Via AWS CLI:

```bash
# Get ASG details
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names chaos-platform-asg

# Get ALB target health
aws elbv2 describe-target-health \
  --target-group-arn <TARGET_GROUP_ARN>
```

### 3. Simulate Manual Failover

**Test resilience by terminating an instance:**

```bash
# Get an instance ID
INSTANCE_ID=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names chaos-platform-asg \
  --query 'AutoScalingGroups[0].Instances[0].InstanceId' \
  --output text)

# Terminate the instance
aws ec2 terminate-instances --instance-ids $INSTANCE_ID

# Monitor recovery
watch -n 5 'aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names chaos-platform-asg \
  --query "AutoScalingGroups[0].Instances[].[InstanceId,HealthStatus,LifecycleState]" \
  --output table'
```

**Expected Behavior:**
1. Instance terminates
2. ALB detects unhealthy instance (30-60 seconds)
3. Auto Scaling Group launches replacement instance (2-3 minutes)
4. New instance becomes healthy and receives traffic
5. Application remains available throughout (via other instance)

## Monitoring

### CloudWatch Dashboards

Create a custom dashboard:

```bash
aws cloudwatch put-dashboard \
  --dashboard-name ChaosEngineeringWeek1 \
  --dashboard-body file://docs/dashboard-week1.json
```

### Key Metrics to Monitor

1. **Auto Scaling Group**:
   - GroupDesiredCapacity
   - GroupInServiceInstances
   - GroupMinSize / GroupMaxSize

2. **Application Load Balancer**:
   - HealthyHostCount
   - UnHealthyHostCount
   - TargetResponseTime
   - HTTPCode_Target_2XX_Count
   - HTTPCode_Target_5XX_Count

3. **EC2 Instances**:
   - CPUUtilization
   - NetworkIn / NetworkOut

### View Logs

```bash
# Apache access logs
aws logs tail /aws/ec2/chaos-platform/httpd/access --follow

# Apache error logs
aws logs tail /aws/ec2/chaos-platform/httpd/error --follow

# VPC Flow Logs
aws logs tail /aws/vpc/chaos-platform --follow
```

## Architecture Validation Checklist

- [ ] VPC spans 2 Availability Zones
- [ ] Instances distributed across both AZs
- [ ] Load Balancer is internet-facing
- [ ] All instances are behind the Load Balancer
- [ ] At least 2 instances show "Healthy" status
- [ ] Application is accessible via Load Balancer URL
- [ ] Security groups properly restrict traffic
- [ ] CloudWatch alarms are configured
- [ ] Tags are properly applied (ChaosTarget=true)
- [ ] Manual instance termination triggers auto-recovery

## Cost Management

**Estimated Monthly Cost**: ~$40-50

Breakdown:
- EC2 (2x t3.micro): ~$12
- Application Load Balancer: ~$22
- NAT Gateways (2): ~$65 (⚠️ Most expensive component)
- Data Transfer: ~$5
- CloudWatch: <$5

**Cost Optimization Tips**:
- Use 1 NAT Gateway instead of 2 (reduces HA but saves ~$32/month)
- Stop instances when not actively testing
- Delete NAT Gateways if private subnet internet access isn't needed
- Run cleanup script when done: `./scripts/cleanup.sh`

## Troubleshooting

### Issue: Instances not becoming healthy

**Check**:
```bash
# View instance system logs
aws ec2 get-console-output --instance-id <INSTANCE_ID>

# Check target health
aws elbv2 describe-target-health --target-group-arn <TG_ARN>
```

**Common causes**:
- User data script failed
- Security group blocking ALB health checks
- Instance not responding on port 80

### Issue: Can't access Load Balancer URL

**Check**:
```bash
# Verify ALB is active
aws elbv2 describe-load-balancers \
  --names chaos-platform-alb \
  --query 'LoadBalancers[0].State.Code'
```

**Wait**: It can take 5-10 minutes for instances to fully initialize

### Issue: CloudFormation stack failed

**Check**:
```bash
# View stack events
aws cloudformation describe-stack-events \
  --stack-name chaos-platform-target-app \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`]'
```

**Common causes**:
- Insufficient IAM permissions
- AMI not available in region
- EC2 instance limit reached

## Success Criteria

✅ **Week 1 is complete when**:
1. VPC infrastructure is deployed
2. Target application is running with 2+ instances
3. Load Balancer URL is accessible
4. Instances are distributed across 2 AZs
5. All health checks are passing
6. Manual instance termination triggers auto-recovery
7. Application remains available during recovery

## Next Steps: Week 2

In Week 2, we will:
1. Develop the **Get-Target-Instance** Lambda function
2. Develop the **Inject-Failure** Lambda function
3. Develop the **Validate-System-Health** Lambda function
4. Define IAM roles with least-privilege permissions
5. Test each function individually

## Resources

- [AWS Well-Architected Framework - Reliability Pillar](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/welcome.html)
- [Auto Scaling Groups Documentation](https://docs.aws.amazon.com/autoscaling/ec2/userguide/what-is-amazon-ec2-auto-scaling.html)
- [Application Load Balancer Documentation](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html)
- [Principles of Chaos Engineering](https://principlesofchaos.org/)
