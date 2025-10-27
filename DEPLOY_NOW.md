# 🚀 DEPLOY EVERYTHING NOW - Single Command

## ONE COMMAND TO DEPLOY EVERYTHING!

No need to run multiple scripts. This ONE script deploys:
- ✅ VPC Infrastructure (Week 1)
- ✅ Target Application - EC2 + ALB (Week 1)
- ✅ Chaos Lambda Functions (Week 2)
- ✅ Step Functions Orchestration (Week 3)
- ✅ DynamoDB Database (Weeks 5-8)
- ✅ Backend API (Weeks 5-8)
- ✅ Frontend Dashboard (Weeks 5-8)

---

## Quick Start (Copy & Paste)

```bash
# Navigate to project
cd "/Users/aravinds/project/Chaos Engineering"

# Run ONE command to deploy everything
./scripts/deploy-fullstack-complete.sh dev
```

**That's it!** Everything will be deployed automatically. ⏱️ Takes 15-20 minutes.

---

## What You Need Before Running

### 1. AWS CLI Configured

```bash
# Check if configured
aws sts get-caller-identity

# If not configured, run:
aws configure
```

### 2. Node.js Installed

```bash
# Check version (need 18+)
node --version

# If not installed:
# macOS: brew install node@20
# Linux: See https://nodejs.org/
```

That's ALL you need! ✅

---

## After Deployment

### Access Your Application

The script will output a URL like:
```
http://chaos-platform-frontend-dev-XXXXX.s3-website-us-east-1.amazonaws.com
```

### Login

- **Email**: `admin@chaos-platform.com`
- **Password**: `anything` (any password works)

### What You Can Do

1. **View Dashboard** - See system health overview
2. **Create Experiments** - Click "New Experiment"
3. **Monitor Live** - Watch real-time progress
4. **View Analytics** - Charts and success rates
5. **Export Data** - Download results

---

## Deployment Details

### What Gets Deployed?

```
🏗️  VPC Infrastructure
   └─ Multi-AZ VPC with public/private subnets
   └─ NAT Gateways, Internet Gateway, Route Tables

🖥️  Target Application
   └─ Auto Scaling Group (2-4 EC2 instances)
   └─ Application Load Balancer
   └─ Security Groups, IAM roles

⚡ Chaos Lambda Functions
   └─ get-target-instance (select random instance)
   └─ inject-failure (terminate instance)
   └─ validate-system-health (check health)

🔄 Step Functions
   └─ 18-state orchestration workflow
   └─ Automated chaos experiment execution

💾 DynamoDB Database
   └─ Experiments table
   └─ Results table
   └─ Users table

🔌 Backend API
   └─ Node.js/TypeScript on Lambda
   └─ REST API endpoints
   └─ Integration with Step Functions

⚛️  Frontend Dashboard
   └─ React + TypeScript
   └─ Beautiful UI with shadcn/ui
   └─ Real-time monitoring
   └─ Analytics charts
```

### Deployment Timeline

- ⏱️ **5 min**: VPC + Networking
- ⏱️ **7 min**: Target Application (EC2 instances)
- ⏱️ **2 min**: Lambda Functions
- ⏱️ **1 min**: Step Functions
- ⏱️ **1 min**: DynamoDB Tables
- ⏱️ **2 min**: Backend Build
- ⏱️ **2 min**: Frontend Build + Upload

**Total: ~15-20 minutes**

---

## Cost Information

### Monthly Cost (24/7 operation)

- EC2 instances (2x t3.micro): $12
- Application Load Balancer: $16
- NAT Gateways (2): $64
- Lambda functions: <$6
- Step Functions: <$1
- DynamoDB (on-demand): <$2
- S3 + Data transfer: <$5

**Total: ~$105/month**

### ⚠️ IMPORTANT

**To avoid charges, clean up when done:**

```bash
./scripts/cleanup.sh
```

---

## Troubleshooting

### Script Fails Immediately

**Check AWS credentials:**
```bash
aws sts get-caller-identity
```

**Check Node.js version:**
```bash
node --version  # Should be v18+
```

### Deployment Stalls

- Check CloudFormation in AWS Console
- Look for failed stacks
- Check IAM permissions

### Frontend URL Not Working

- Wait 2-3 minutes after deployment
- Check browser console for errors
- Verify S3 bucket is publicly accessible

### Need Help?

Check detailed guides:
- [STEP_BY_STEP_GUIDE.md](STEP_BY_STEP_GUIDE.md) - Detailed walkthrough
- [FULLSTACK_QUICKSTART.md](FULLSTACK_QUICKSTART.md) - Reference guide
- [FULL_STACK_SUMMARY.md](FULL_STACK_SUMMARY.md) - Complete overview

---

## Example Output

```
╔════════════════════════════════════════════════════════════════════════╗
║                                                                        ║
║     🚀  CHAOS ENGINEERING PLATFORM - COMPLETE DEPLOYMENT  🚀          ║
║                                                                        ║
║     This will deploy EVERYTHING in one go:                            ║
║     ✓ VPC Infrastructure                                              ║
║     ✓ Target Application (EC2 + ALB)                                  ║
║     ✓ Chaos Lambda Functions                                          ║
║     ✓ Step Functions Orchestration                                    ║
║     ✓ DynamoDB Database                                               ║
║     ✓ Backend API (Lambda + API Gateway)                              ║
║     ✓ Frontend Dashboard (React + S3)                                 ║
║                                                                        ║
╚════════════════════════════════════════════════════════════════════════╝

Configuration:
  Environment: dev
  AWS Region: us-east-1
  Project Root: /Users/aravinds/project/Chaos Engineering

⚠ This deployment will take approximately 15-20 minutes
⚠ Estimated AWS cost: ~$105/month (if left running 24/7)

Continue with deployment? (yes/no): yes

═══════════════════════════════════════════════════════════════
▶ WEEK 1: Deploying VPC Infrastructure
═══════════════════════════════════════════════════════════════

✓ VPC infrastructure deployed
ℹ VPC ID: vpc-0123456789abcdef0

═══════════════════════════════════════════════════════════════
▶ WEEK 1: Deploying Target Application (EC2 + ALB)
═══════════════════════════════════════════════════════════════

⚠ This step takes ~7-10 minutes (EC2 instances need to launch)
✓ Target application deployed
ℹ Auto Scaling Group: chaos-target-asg
ℹ Load Balancer: chaos-target-lb-xxxxx.us-east-1.elb.amazonaws.com

... (continuing through all steps) ...

═══════════════════════════════════════════════════════════════
▶ 🎉 DEPLOYMENT COMPLETE! 🎉
═══════════════════════════════════════════════════════════════

╔════════════════════════════════════════════════════════════════════════╗
║                                                                        ║
║    ✅ ALL COMPONENTS SUCCESSFULLY DEPLOYED!                           ║
║                                                                        ║
╚════════════════════════════════════════════════════════════════════════╝

🌐 ACCESS YOUR APPLICATION

Frontend URL:
  http://chaos-platform-frontend-dev-123456.s3-website-us-east-1.amazonaws.com

Login Credentials (Mock Auth):
  Email:    admin@chaos-platform.com
  Password: anything (any password works)

🚀 NEXT STEPS

  1. Open the frontend URL in your browser
  2. Login with the credentials above
  3. Click 'New Experiment' to create your first chaos test
  4. Enable 'Dry Run' for safe testing
  5. Monitor the experiment in real-time

✨ Happy Chaos Engineering! ✨
```

---

## Ready to Deploy?

```bash
cd "/Users/aravinds/project/Chaos Engineering"
./scripts/deploy-fullstack-complete.sh dev
```

🎉 **That's it! You're done!** 🎉
