# Complete Step-by-Step Guide - Full-Stack Chaos Engineering Platform

## Table of Contents
1. [Prerequisites Setup](#prerequisites-setup)
2. [Deploy Infrastructure (Weeks 1-4)](#deploy-infrastructure-weeks-1-4)
3. [Deploy Full-Stack Application](#deploy-full-stack-application)
4. [Access and Use the Application](#access-and-use-the-application)
5. [Run Your First Chaos Experiment](#run-your-first-chaos-experiment)
6. [View Results and Analytics](#view-results-and-analytics)
7. [Cleanup (When Done)](#cleanup-when-done)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites Setup

### Step 1.1: Install AWS CLI

**macOS:**
```bash
# Using Homebrew
brew install awscli

# Verify installation
aws --version
```

**Linux:**
```bash
# Download and install
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Verify installation
aws --version
```

**Windows:**
Download from: https://aws.amazon.com/cli/

### Step 1.2: Configure AWS Credentials

```bash
aws configure
```

Enter when prompted:
- **AWS Access Key ID**: Your access key
- **AWS Secret Access Key**: Your secret key
- **Default region name**: `us-east-1` (recommended)
- **Default output format**: `json`

**Verify credentials:**
```bash
aws sts get-caller-identity
```

You should see your account ID, user ID, and ARN.

### Step 1.3: Install Node.js

**Check if already installed:**
```bash
node --version
npm --version
```

**If not installed:**

**macOS:**
```bash
brew install node@20
```

**Linux:**
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
```

**Windows:**
Download from: https://nodejs.org/

**Verify installation:**
```bash
node --version  # Should be v20.x or higher
npm --version   # Should be v10.x or higher
```

### Step 1.4: Install jq (for JSON parsing)

**macOS:**
```bash
brew install jq
```

**Linux:**
```bash
sudo apt-get install jq
```

**Verify:**
```bash
jq --version
```

---

## Deploy Infrastructure (Weeks 1-4)

### Step 2.1: Navigate to Project Directory

```bash
cd "/Users/aravinds/project/Chaos Engineering"
```

### Step 2.2: Check Existing Infrastructure

```bash
# Check if infrastructure is already deployed
aws cloudformation list-stacks \
  --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
  --query 'StackSummaries[?contains(StackName, `chaos`)].StackName'
```

**Expected output if already deployed:**
```json
[
    "chaos-vpc-infrastructure",
    "chaos-target-application",
    "chaos-lambda-functions",
    "chaos-step-functions"
]
```

### Step 2.3: Deploy Infrastructure (if not already deployed)

**If the stacks don't exist, deploy them:**

```bash
# Make sure deploy script is executable
chmod +x ./scripts/deploy.sh

# Deploy infrastructure (takes ~15-20 minutes)
./scripts/deploy.sh
```

**What this does:**
1. Creates VPC with multi-AZ networking (~3 min)
2. Deploys target application (EC2 + ALB) (~7 min)
3. Deploys chaos Lambda functions (~2 min)
4. Deploys Step Functions workflow (~2 min)

**Watch for output like:**
```
========================================
Deployment Summary
========================================
VPC ID: vpc-xxxxxxxxx
Load Balancer DNS: chaos-target-lb-xxxxx.us-east-1.elb.amazonaws.com
Auto Scaling Group: chaos-target-asg
Step Functions ARN: arn:aws:states:us-east-1:xxxxx:stateMachine:chaos-experiment-workflow
```

**💡 Important:** Save this output! You'll need these values later.

### Step 2.4: Verify Infrastructure Deployment

```bash
# Verify all stacks are deployed
./scripts/verify-deployment.sh
```

**Expected output:**
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

## Deploy Full-Stack Application

### Step 3.1: Check Frontend Files

```bash
# Verify frontend directory exists
ls -la frontend/

# You should see:
# - src/
# - package.json
# - vite.config.ts
# - etc.
```

### Step 3.2: Install Frontend Dependencies

```bash
cd frontend
npm install
```

**Wait for installation to complete** (~1-2 minutes)

### Step 3.3: Test Frontend Locally (Optional)

```bash
# Start development server
npm run dev
```

**Output:**
```
  VITE v5.x.x  ready in xxx ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
```

**Open browser to** `http://localhost:5173`

You should see the login page!

**Press Ctrl+C to stop the dev server when done testing**

### Step 3.4: Go Back to Project Root

```bash
cd ..
# You should now be in: /Users/aravinds/project/Chaos Engineering
```

### Step 3.5: Install Backend Dependencies

```bash
cd backend
npm install
```

**Wait for installation** (~1-2 minutes)

### Step 3.6: Build Backend (Optional - to verify it works)

```bash
npm run build
```

**Expected output:**
```
> chaos-engineering-backend@1.0.0 build
> tsc

✓ TypeScript compilation successful
```

### Step 3.7: Go Back to Project Root

```bash
cd ..
```

### Step 3.8: Deploy Full-Stack Application

**Make script executable:**
```bash
chmod +x ./scripts/deploy-fullstack.sh
```

**Deploy everything:**
```bash
./scripts/deploy-fullstack.sh dev
```

**This will take ~3-5 minutes and will:**
1. ✓ Check existing infrastructure
2. ✓ Deploy DynamoDB tables (~30 seconds)
3. ✓ Build backend (~45 seconds)
4. ✓ Package Lambda functions (~15 seconds)
5. ✓ Build frontend (~1 minute)
6. ✓ Deploy frontend to S3 (~30 seconds)

**Watch for the final output:**
```
========================================
Deployment Summary
========================================

✓ Full-Stack Deployment Complete!

Infrastructure Details:
  VPC ID: vpc-xxxxx
  Target ASG: chaos-target-asg
  State Machine: arn:aws:states:...

Database:
  Experiments Table: chaos-experiments-dev
  Results Table: chaos-results-dev
  Users Table: chaos-users-dev

Frontend:
  S3 Bucket: chaos-platform-frontend-dev-xxxxx
  Website URL: http://chaos-platform-frontend-dev-xxxxx.s3-website-us-east-1.amazonaws.com

Backend:
  Lambda Package: s3://chaos-platform-lambda-xxxxx/lambda-functions.zip
```

**💡 IMPORTANT: Copy the "Website URL" - you'll need it to access the app!**

---

## Access and Use the Application

### Step 4.1: Open the Application

**Copy the Website URL from the deployment output and open it in your browser:**

```
http://chaos-platform-frontend-dev-xxxxx.s3-website-us-east-1.amazonaws.com
```

**Or get it from AWS:**
```bash
# Get the frontend URL
aws cloudformation describe-stacks \
  --stack-name chaos-fullstack-database-dev \
  --query 'StackSummaries[0].Outputs[?OutputKey==`FrontendURL`].OutputValue' \
  --output text
```

### Step 4.2: Login to the Application

**You should see a login page with fields for email and password.**

**Login Credentials (Mock Authentication):**
- **Email**: `admin@chaos-platform.com`
- **Password**: `anything` (any password works in mock mode)

**Click "Login"**

### Step 4.3: Explore the Dashboard

**After login, you'll see the Dashboard page with:**

1. **System Health Card** (top left)
   - Status: Healthy/Degraded/Critical
   - Target instance count
   - Healthy instances
   - Load balancer status

2. **Recent Experiments** (top right)
   - List of recent chaos experiments
   - Click on any to view details

3. **Quick Stats** (middle - 4 cards)
   - Total Experiments Run
   - Success Rate (%)
   - Average Recovery Time
   - Active Experiments

4. **Quick Actions** (bottom)
   - "Run New Experiment" button
   - "View All Results" button
   - "System Health Check" button

**Take a moment to explore!**

---

## Run Your First Chaos Experiment

### Step 5.1: Navigate to New Experiment Page

**Click the big "Run New Experiment" button on the dashboard**

OR

**Click "Experiments" in the sidebar → Click "New Experiment" button**

### Step 5.2: Fill in the Experiment Form

**You'll see a form with several sections:**

#### **Target Selection:**
- **Auto Scaling Group**: Should be pre-filled with `chaos-target-asg`
- **Instance Selection**: Leave as "Random Instance"

#### **Experiment Configuration:**
- **Dry Run Mode**: ✅ **Turn this ON for your first test!**
  - This simulates the experiment without actually terminating instances
  - Safe for testing
- **Expected Healthy Instances**: Enter `2`
- **Failure Type**: Leave as "Instance Termination"

#### **Metadata (Optional):**
- **Experiment Name**: Enter `My First Chaos Test`
- **Hypothesis**: Enter `System should maintain availability when one instance fails`
- **Owner**: Enter your name or team

### Step 5.3: Review Configuration

**Your configuration should look like:**
```
Target: chaos-target-asg
Dry Run: ON (✓)
Expected Healthy Instances: 2
Experiment Name: My First Chaos Test
```

### Step 5.4: Start the Experiment

**Click the "Start Experiment" button**

**You'll be redirected to the Experiment Monitor page**

### Step 5.5: Watch the Experiment Progress

**On the Monitor page, you'll see:**

1. **Experiment Status** at the top
2. **Step-by-Step Progress Timeline** showing:
   - ✓ Pre-Experiment Health Check
   - ▶ Target Instance Selection
   - ⏸ Failure Injection (pending)
   - ⏸ Recovery Wait (pending)
   - ⏸ Post-Experiment Health Validation (pending)
   - ⏸ Results Recording (pending)

3. **Live Metrics Card** showing:
   - Current healthy instance count
   - Target group health
   - Load balancer status

4. **Logs Section** with real-time execution logs

**The page auto-refreshes every 5 seconds**

**Watch as each step completes!** ✅

### Step 5.6: Wait for Completion

**The experiment will take ~2-3 minutes to complete**

**Final status will be one of:**
- ✅ **COMPLETED** - Experiment succeeded
- ❌ **FAILED** - Experiment failed
- ⏹️ **STOPPED** - You stopped it manually

**Since this is a DRY RUN, no actual instances were terminated** ✅

---

## View Results and Analytics

### Step 6.1: Navigate to Results Page

**Click "Results & Analytics" in the sidebar**

OR

**Click "View All Results" button from the dashboard**

### Step 6.2: View Results Table

**You'll see a table with all experiment results:**

**Columns:**
- Result ID
- Experiment ID
- Timestamp
- Status (Success/Failed)
- Recovery Time (seconds)
- Actions (View Details, Export)

**Click on your experiment result to see details**

### Step 6.3: Explore Analytics

**Scroll down to see charts:**

1. **Experiments Over Time** (Line Chart)
   - Shows experiment frequency over last 30 days

2. **Success vs Failure Rate** (Bar Chart)
   - Shows success/failure breakdown by week

3. **Experiment Types Distribution** (Pie Chart)
   - Shows distribution of experiment types

### Step 6.4: Export Results (Optional)

**Click the "Export" button**

**Choose format:**
- CSV (for Excel/Google Sheets)
- JSON (for programmatic access)

**File will download automatically**

---

## Run a REAL Experiment (Optional)

### Step 7.1: Understanding the Impact

**⚠️ WARNING: This will actually terminate an EC2 instance!**

**What will happen:**
1. One instance in your Auto Scaling Group will be terminated
2. Auto Scaling will detect the failure (~30 seconds)
3. A new instance will be launched (~2-3 minutes)
4. System should remain available via the other instance(s)

**Cost impact:** None (replacement instance is covered by your existing Auto Scaling config)

### Step 7.2: Create a Real Experiment

**Go to: Experiments → New Experiment**

**Fill in the form:**
- **Dry Run Mode**: ❌ **Turn this OFF**
- **Expected Healthy Instances**: `2`
- **Experiment Name**: `Real Instance Termination Test`
- **Hypothesis**: `System maintains 99% availability during instance failure`

**Click "Start Experiment"**

### Step 7.3: Monitor the REAL Experiment

**Watch the monitor page:**
1. Pre-experiment health check (✓)
2. Target instance selected (shows actual instance ID)
3. **Failure injection** - Instance ACTUALLY terminated! ⚠️
4. Recovery wait (60 seconds)
5. Health validation (checks if system recovered)
6. Results recorded (✓)

**Meanwhile, verify in AWS Console:**
```bash
# Watch Auto Scaling Group
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names chaos-target-asg \
  --query 'AutoScalingGroups[0].Instances[*].[InstanceId,LifecycleState,HealthStatus]'
```

**You should see:**
- One instance terminating
- A new instance launching
- Eventually: 2 healthy instances

### Step 7.4: Verify System Availability

**During the experiment, test the application:**

```bash
# Get load balancer DNS
LB_DNS=$(aws cloudformation describe-stacks \
  --stack-name chaos-target-application \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
  --output text)

# Test availability (run multiple times during experiment)
curl -I http://$LB_DNS

# Expected: HTTP/1.1 200 OK (even during instance failure!)
```

### Step 7.5: Review Results

**Once complete, check:**
- Experiment status: COMPLETED ✓
- Recovery time: Should be ~120-180 seconds
- System health: Should return to "Healthy"
- Error rate: Should be 0%

**🎉 Congratulations! You've successfully validated your system's resilience!**

---

## Cleanup (When Done)

### Step 8.1: Delete Full-Stack Resources

**To avoid ongoing AWS charges, clean up all resources:**

```bash
cd "/Users/aravinds/project/Chaos Engineering"
./scripts/cleanup.sh
```

**You'll be prompted:**
```
WARNING: This will delete ALL Chaos Engineering Platform resources.
  - Step Functions state machine
  - Lambda functions (6 total)
  - Auto Scaling Group and EC2 instances
  - Application Load Balancer
  - VPC and networking
  - CloudWatch log groups
  - DynamoDB tables
  - Frontend S3 bucket

Are you sure? (yes/no)
```

**Type `yes` and press Enter**

### Step 8.2: Cleanup Full-Stack Specific Resources

**The main cleanup script handles Weeks 1-4. For full-stack resources:**

```bash
# Delete DynamoDB tables
aws cloudformation delete-stack \
  --stack-name chaos-fullstack-database-dev

# Delete frontend S3 bucket
BUCKET_NAME=$(aws s3 ls | grep chaos-platform-frontend-dev | awk '{print $3}')
aws s3 rm s3://$BUCKET_NAME --recursive
aws s3 rb s3://$BUCKET_NAME

# Delete Lambda package bucket
LAMBDA_BUCKET=$(aws s3 ls | grep chaos-platform-lambda | awk '{print $3}')
aws s3 rm s3://$LAMBDA_BUCKET --recursive
aws s3 rb s3://$LAMBDA_BUCKET
```

### Step 8.3: Verify Cleanup

```bash
# Verify all stacks are deleted
aws cloudformation list-stacks \
  --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
  --query 'StackSummaries[?contains(StackName, `chaos`)].StackName'

# Should return: []
```

**All resources deleted!** ✅

---

## Troubleshooting

### Issue 1: Frontend Shows White Screen

**Problem:** Browser shows blank page or errors

**Solutions:**

1. **Check browser console (F12):**
   ```
   Look for errors like:
   - CORS errors
   - 404 Not Found
   - Network errors
   ```

2. **Verify S3 bucket is configured correctly:**
   ```bash
   # Check bucket exists
   aws s3 ls | grep chaos-platform-frontend-dev

   # Check website hosting is enabled
   aws s3api get-bucket-website \
     --bucket chaos-platform-frontend-dev-XXXXX
   ```

3. **Check bucket policy:**
   ```bash
   aws s3api get-bucket-policy \
     --bucket chaos-platform-frontend-dev-XXXXX
   ```

4. **Redeploy frontend:**
   ```bash
   cd frontend
   npm run build
   aws s3 sync dist/ s3://chaos-platform-frontend-dev-XXXXX/ --delete
   ```

### Issue 2: Login Doesn't Work

**Problem:** Login button doesn't respond or shows errors

**Solutions:**

1. **Check browser console for errors**

2. **Verify mock authentication is working:**
   - Any email works
   - Any password works
   - Should redirect to dashboard

3. **Clear browser cache and cookies:**
   - Press Ctrl+Shift+Delete
   - Clear cached data
   - Refresh page

### Issue 3: Experiments Page Shows No Data

**Problem:** Experiments table is empty

**Solutions:**

1. **Create a test experiment:**
   - Click "New Experiment"
   - Fill in form
   - Start experiment

2. **Check DynamoDB tables exist:**
   ```bash
   aws dynamodb list-tables | grep chaos
   ```

3. **Check table has data:**
   ```bash
   aws dynamodb scan \
     --table-name chaos-experiments-dev \
     --limit 10
   ```

### Issue 4: Deployment Script Fails

**Problem:** `deploy-fullstack.sh` shows errors

**Solutions:**

1. **Check AWS credentials:**
   ```bash
   aws sts get-caller-identity
   ```

2. **Verify permissions:**
   - Need admin or CloudFormation permissions
   - Need S3, Lambda, DynamoDB permissions

3. **Check for existing resources:**
   ```bash
   # List existing stacks
   aws cloudformation list-stacks
   ```

4. **Check Node.js version:**
   ```bash
   node --version  # Should be v20+
   ```

5. **Run deployment steps manually:**
   ```bash
   # Deploy database only
   aws cloudformation deploy \
     --template-file infrastructure/fullstack-database.yaml \
     --stack-name chaos-fullstack-database-dev
   ```

### Issue 5: Experiment Fails to Start

**Problem:** Experiment stays in PENDING or fails immediately

**Solutions:**

1. **Check Step Functions state machine exists:**
   ```bash
   aws stepfunctions list-state-machines | grep chaos
   ```

2. **Verify Auto Scaling Group has instances:**
   ```bash
   aws autoscaling describe-auto-scaling-groups \
     --auto-scaling-group-names chaos-target-asg
   ```

3. **Check Lambda function permissions:**
   ```bash
   aws lambda get-function \
     --function-name chaos-inject-failure
   ```

4. **View Step Functions execution logs:**
   ```bash
   # Go to AWS Console → Step Functions → Executions
   # Click on failed execution
   # Review error details
   ```

### Issue 6: High AWS Costs

**Problem:** AWS bill is higher than expected

**Solutions:**

1. **Run cleanup script:**
   ```bash
   ./scripts/cleanup.sh
   ```

2. **Check for running resources:**
   ```bash
   # EC2 instances
   aws ec2 describe-instances --query 'Reservations[].Instances[?State.Name==`running`]'

   # NAT Gateways (expensive!)
   aws ec2 describe-nat-gateways

   # Load Balancers
   aws elbv2 describe-load-balancers
   ```

3. **Delete manually if cleanup fails:**
   - Go to AWS Console
   - CloudFormation → Delete stacks
   - EC2 → Terminate instances
   - VPC → Delete NAT Gateways

### Getting More Help

1. **Check CloudWatch Logs:**
   ```bash
   # List log groups
   aws logs describe-log-groups | grep chaos

   # Tail logs
   aws logs tail /aws/lambda/chaos-inject-failure --follow
   ```

2. **Review documentation:**
   - [FULLSTACK_QUICKSTART.md](FULLSTACK_QUICKSTART.md)
   - [FULL_STACK_SUMMARY.md](FULL_STACK_SUMMARY.md)
   - [backend/README.md](backend/README.md)

3. **Check AWS Console:**
   - CloudFormation → Stacks → Events
   - Lambda → Functions → Monitor
   - Step Functions → State machines → Executions

---

## Summary

**✅ You've learned how to:**
1. Set up prerequisites
2. Deploy infrastructure
3. Deploy full-stack application
4. Access the dashboard
5. Run chaos experiments
6. View results and analytics
7. Clean up resources
8. Troubleshoot issues

**🎉 You now have a complete, working Chaos Engineering Platform!**

**Next steps:**
- Run more experiments to test different scenarios
- Customize the UI to match your branding
- Add more chaos experiment types
- Set up production deployment with HTTPS
- Integrate with your CI/CD pipeline

---

**Need help?** Check the documentation or AWS CloudWatch logs for detailed error messages.

**Happy Chaos Engineering!** 🚀
