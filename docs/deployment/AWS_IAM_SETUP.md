# AWS IAM User Setup Guide

Complete guide to create an IAM user with the exact permissions needed for the Chaos Engineering Platform.

---

## Quick Summary

You need an IAM user with these permissions:
- ✅ CloudFormation (create/update/delete stacks)
- ✅ EC2 (VPC, instances, load balancers, auto scaling)
- ✅ Lambda (create/update functions)
- ✅ Step Functions (create/execute state machines)
- ✅ DynamoDB (create/read/write tables)
- ✅ S3 (create buckets, upload files)
- ✅ IAM (create roles for Lambda/Step Functions)
- ✅ CloudWatch (logs and metrics)

---

## Option 1: Quick Setup (Administrator Access)

### ⚠️ Warning
This gives full AWS access. **Only use for testing/development!**

### Steps

1. **Go to IAM Console**
   - Open: https://console.aws.amazon.com/iam/
   - Click **Users** → **Create user**

2. **Create User**
   - User name: `chaos-platform-admin`
   - Check: ✅ **Provide user access to the AWS Management Console**
   - Click **Next**

3. **Set Permissions**
   - Select: **Attach policies directly**
   - Search and select: **AdministratorAccess**
   - Click **Next**

4. **Review and Create**
   - Click **Create user**

5. **Save Credentials**
   - Download the CSV file with:
     - Access Key ID
     - Secret Access Key
   - **Keep this file secure!**

6. **Configure AWS CLI**
   ```bash
   aws configure
   ```

   Enter when prompted:
   - AWS Access Key ID: `[paste from CSV]`
   - AWS Secret Access Key: `[paste from CSV]`
   - Default region name: `us-east-1`
   - Default output format: `json`

**✅ Done! You can now deploy the platform.**

---

## Option 2: Least Privilege (Production Ready)

### Create IAM Policy

This gives **only** the permissions needed for the Chaos Engineering Platform.

### Step 1: Create Custom Policy

1. **Go to IAM Console**
   - Open: https://console.aws.amazon.com/iam/
   - Click **Policies** → **Create policy**

2. **Use JSON Editor**
   - Click **JSON** tab
   - Paste this policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CloudFormationAccess",
      "Effect": "Allow",
      "Action": [
        "cloudformation:CreateStack",
        "cloudformation:UpdateStack",
        "cloudformation:DeleteStack",
        "cloudformation:DescribeStacks",
        "cloudformation:DescribeStackEvents",
        "cloudformation:DescribeStackResources",
        "cloudformation:GetTemplate",
        "cloudformation:ValidateTemplate",
        "cloudformation:ListStacks",
        "cloudformation:CreateChangeSet",
        "cloudformation:ExecuteChangeSet",
        "cloudformation:DescribeChangeSet",
        "cloudformation:ListChangeSets",
        "cloudformation:DeleteChangeSet"      
      ],
      "Resource": "*"
    },
    {
      "Sid": "EC2VPCAccess",
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVpc",
        "ec2:DeleteVpc",
        "ec2:DescribeVpcs",
        "ec2:ModifyVpcAttribute",
        "ec2:CreateSubnet",
        "ec2:DeleteSubnet",
        "ec2:DescribeSubnets",
        "ec2:ModifySubnetAttribute",
        "ec2:DescribeAvailabilityZones",
        "ec2:CreateInternetGateway",
        "ec2:AttachInternetGateway",
        "ec2:DetachInternetGateway",
        "ec2:DeleteInternetGateway",
        "ec2:DescribeInternetGateways",
        "ec2:CreateNatGateway",
        "ec2:DeleteNatGateway",
        "ec2:DescribeNatGateways",
        "ec2:AllocateAddress",
        "ec2:ReleaseAddress",
        "ec2:DescribeAddresses",
        "ec2:CreateRouteTable",
        "ec2:DeleteRouteTable",
        "ec2:DescribeRouteTables",
        "ec2:CreateRoute",
        "ec2:DeleteRoute",
        "ec2:AssociateRouteTable",
        "ec2:DisassociateRouteTable",
        "ec2:CreateTags",
        "ec2:DeleteTags",
        "ec2:DescribeTags"
      ],
      "Resource": "*"
    },
    {
      "Sid": "EC2InstanceAccess",
      "Effect": "Allow",
      "Action": [
        "ec2:RunInstances",
        "ec2:TerminateInstances",
        "ec2:StopInstances",
        "ec2:StartInstances",
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceStatus",
        "ec2:DescribeImages",
        "ec2:DescribeKeyPairs",
        "ec2:CreateSecurityGroup",
        "ec2:DeleteSecurityGroup",
        "ec2:DescribeSecurityGroups",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupEgress"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AutoScalingAccess",
      "Effect": "Allow",
      "Action": [
        "autoscaling:CreateAutoScalingGroup",
        "autoscaling:UpdateAutoScalingGroup",
        "autoscaling:DeleteAutoScalingGroup",
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:CreateLaunchConfiguration",
        "autoscaling:DeleteLaunchConfiguration",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:PutScalingPolicy",
        "autoscaling:DeletePolicy",
        "autoscaling:DescribePolicies"
      ],
      "Resource": "*"
    },
    {
      "Sid": "LoadBalancerAccess",
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:CreateLoadBalancer",
        "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:ModifyLoadBalancerAttributes",
        "elasticloadbalancing:CreateTargetGroup",
        "elasticloadbalancing:DeleteTargetGroup",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:ModifyTargetGroup",
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:DescribeTargetHealth",
        "elasticloadbalancing:CreateListener",
        "elasticloadbalancing:DeleteListener",
        "elasticloadbalancing:DescribeListeners",
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:RemoveTags"
      ],
      "Resource": "*"
    },
    {
      "Sid": "LambdaAccess",
      "Effect": "Allow",
      "Action": [
        "lambda:CreateFunction",
        "lambda:UpdateFunctionCode",
        "lambda:UpdateFunctionConfiguration",
        "lambda:DeleteFunction",
        "lambda:GetFunction",
        "lambda:ListFunctions",
        "lambda:InvokeFunction",
        "lambda:PublishVersion",
        "lambda:CreateAlias",
        "lambda:UpdateAlias",
        "lambda:DeleteAlias",
        "lambda:AddPermission",
        "lambda:RemovePermission",
        "lambda:TagResource",
        "lambda:UntagResource"
      ],
      "Resource": "*"
    },
    {
      "Sid": "StepFunctionsAccess",
      "Effect": "Allow",
      "Action": [
        "states:CreateStateMachine",
        "states:UpdateStateMachine",
        "states:DeleteStateMachine",
        "states:DescribeStateMachine",
        "states:ListStateMachines",
        "states:StartExecution",
        "states:StopExecution",
        "states:DescribeExecution",
        "states:ListExecutions",
        "states:GetExecutionHistory",
        "states:TagResource",
        "states:UntagResource"
      ],
      "Resource": "*"
    },
    {
      "Sid": "DynamoDBAccess",
      "Effect": "Allow",
      "Action": [
        "dynamodb:CreateTable",
        "dynamodb:UpdateTable",
        "dynamodb:DeleteTable",
        "dynamodb:DescribeTable",
        "dynamodb:ListTables",
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:BatchGetItem",
        "dynamodb:BatchWriteItem",
        "dynamodb:TagResource",
        "dynamodb:UntagResource"
      ],
      "Resource": "*"
    },
    {
      "Sid": "S3Access",
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket",
        "s3:DeleteBucket",
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:GetBucketWebsite",
        "s3:PutBucketWebsite",
        "s3:DeleteBucketWebsite",
        "s3:PutBucketPolicy",
        "s3:GetBucketPolicy",
        "s3:DeleteBucketPolicy",
        "s3:PutBucketVersioning",
        "s3:GetBucketVersioning",
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:PutObjectAcl",
        "s3:ListAllMyBuckets"
      ],
      "Resource": "*"
    },
    {
      "Sid": "IAMRoleAccess",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:GetRole",
        "iam:PassRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:GetRolePolicy",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies",
        "iam:CreatePolicy",
        "iam:DeletePolicy",
        "iam:GetPolicy",
        "iam:ListPolicies",
        "iam:TagRole",
        "iam:UntagRole"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CloudWatchAccess",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:DeleteLogGroup",
        "logs:DescribeLogGroups",
        "logs:CreateLogStream",
        "logs:DeleteLogStream",
        "logs:PutLogEvents",
        "logs:GetLogEvents",
        "logs:FilterLogEvents",
        "logs:TagLogGroup",
        "cloudwatch:PutMetricData",
        "cloudwatch:GetMetricData",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:ListMetrics",
        "cloudwatch:PutMetricAlarm",
        "cloudwatch:DeleteAlarms",
        "cloudwatch:DescribeAlarms"
      ],
      "Resource": "*"
    },
    {
      "Sid": "EventBridgeAccess",
      "Effect": "Allow",
      "Action": [
        "events:PutRule",
        "events:DeleteRule",
        "events:DescribeRule",
        "events:EnableRule",
        "events:DisableRule",
        "events:PutTargets",
        "events:RemoveTargets",
        "events:ListRules",
        "events:ListTargetsByRule"
      ],
      "Resource": "*"
    },
    {
      "Sid": "STSAccess",
      "Effect": "Allow",
      "Action": [
        "sts:GetCallerIdentity"
      ],
      "Resource": "*"
    }
  ]
}
```

3. **Name the Policy**
   - Policy name: `ChaosEngineeringPlatformPolicy`
   - Description: `Permissions for Chaos Engineering Platform deployment`
   - Click **Create policy**

### Step 2: Create IAM User

1. **Create User**
   - Go to **Users** → **Create user**
   - User name: `chaos-platform-user`
   - Check: ✅ **Provide user access to the AWS Management Console** (optional)
   - Click **Next**

2. **Attach Policy**
   - Select: **Attach policies directly**
   - Search: `ChaosEngineeringPlatformPolicy`
   - Check the policy you just created
   - Click **Next**

3. **Create User**
   - Review and click **Create user**

### Step 3: Create Access Keys

1. **Go to User**
   - Click on the user you just created

2. **Create Access Key**
   - Click **Security credentials** tab
   - Scroll to **Access keys**
   - Click **Create access key**

3. **Select Use Case**
   - Choose: **Command Line Interface (CLI)**
   - Check: ✅ I understand...
   - Click **Next**

4. **Download Credentials**
   - Click **Create access key**
   - Click **Download .csv file**
   - **Keep this file secure!**

### Step 4: Configure AWS CLI

```bash
aws configure
```

Enter:
- **AWS Access Key ID**: [from CSV]
- **AWS Secret Access Key**: [from CSV]
- **Default region name**: `us-east-1`
- **Default output format**: `json`

**✅ Done! You now have least-privilege access.**

---

## Verify Setup

### Test Your Credentials

```bash
# Verify identity
aws sts get-caller-identity

# Expected output:
# {
#     "UserId": "AIDAXXXXXXXXXXXXXXXXX",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/chaos-platform-user"
# }
```

### Test Permissions

```bash
# Test CloudFormation access
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE

# Test S3 access
aws s3 ls

# Test Lambda access
aws lambda list-functions
```

**If all commands work, you're ready to deploy!** ✅

---

## Quick Reference

### Services Used

| Service | What It's For | Permissions Needed |
|---------|---------------|-------------------|
| **CloudFormation** | Infrastructure deployment | Create/Update/Delete stacks |
| **EC2** | VPC, instances, networking | Full EC2 access |
| **Auto Scaling** | Scale instances | Create/Update ASG |
| **ELB** | Load balancer | Create/Manage ALB |
| **Lambda** | Serverless functions | Create/Update/Invoke functions |
| **Step Functions** | Workflow orchestration | Create/Execute state machines |
| **DynamoDB** | Database | Create/Read/Write tables |
| **S3** | Frontend hosting, Lambda packages | Create buckets, upload files |
| **IAM** | Service roles | Create roles for Lambda/Step Functions |
| **CloudWatch** | Logging and monitoring | Create log groups, put metrics |
| **EventBridge** | Scheduling (optional) | Create/Manage rules |

---

## Security Best Practices

### ✅ Do's

1. **Use Least Privilege**
   - Use Option 2 for production
   - Only grant needed permissions

2. **Rotate Access Keys**
   - Rotate keys every 90 days
   - Use temporary credentials when possible

3. **Enable MFA**
   - Enable MFA on your AWS account
   - Enable MFA for IAM user

4. **Monitor Usage**
   - Enable CloudTrail
   - Review IAM Access Advisor

5. **Use AWS Vault (Optional)**
   - Store credentials securely
   - Avoid storing in plain text

### ❌ Don'ts

1. **Never Share Credentials**
   - Don't commit to Git
   - Don't share via email/Slack

2. **Avoid Root User**
   - Never use root credentials
   - Create IAM users instead

3. **Don't Use AdministratorAccess in Production**
   - Only for testing/development
   - Use least privilege in production

---

## Troubleshooting

### Issue: Access Denied Errors

**Problem**: Getting "Access Denied" during deployment

**Solutions**:

1. **Check IAM permissions:**
   ```bash
   aws iam get-user
   aws iam list-attached-user-policies --user-name chaos-platform-user
   ```

2. **Verify policy is attached:**
   - Go to IAM Console → Users → [Your User] → Permissions
   - Check that the policy is listed

3. **Check CloudFormation permissions:**
   - The user needs `iam:PassRole` permission
   - This allows CloudFormation to create service roles

### Issue: Cannot Create IAM Roles

**Problem**: CloudFormation fails creating IAM roles

**Solution**: Add `CAPABILITY_IAM` to CloudFormation deploy command:
```bash
aws cloudformation deploy \
  --capabilities CAPABILITY_IAM \
  ...
```

(This is already included in our deployment scripts)

### Issue: Region Mismatch

**Problem**: Resources not found in expected region

**Solution**:
```bash
# Set region
export AWS_REGION=us-east-1

# Or update AWS config
aws configure set region us-east-1
```

---

## Cost Tracking

### Enable Cost Alerts

1. **Go to Billing Dashboard**
   - https://console.aws.amazon.com/billing/

2. **Create Budget**
   - Click **Budgets** → **Create budget**
   - Choose **Cost budget**
   - Set amount: $150/month
   - Add email alerts

3. **Enable Cost Explorer**
   - Track spending by service
   - Identify cost optimization opportunities

---

## Next Steps

Once your IAM user is set up:

1. **✅ Verify credentials work:**
   ```bash
   aws sts get-caller-identity
   ```

2. **✅ Deploy the platform:**
   ```bash
   cd "/Users/aravinds/project/Chaos Engineering"
   ./scripts/deploy-fullstack-complete.sh dev
   ```

3. **✅ Access your application!**

---

## Summary

**Quick Setup (5 minutes):**
- Create IAM user with AdministratorAccess
- Create access keys
- Run `aws configure`
- Deploy!

**Production Setup (10 minutes):**
- Create custom IAM policy (copy JSON above)
- Create IAM user
- Attach custom policy
- Create access keys
- Run `aws configure`
- Deploy!

**Both options work perfectly!** Choose based on your security requirements.

---

**Ready to deploy?** See [DEPLOY_NOW.md](DEPLOY_NOW.md) for deployment instructions!
