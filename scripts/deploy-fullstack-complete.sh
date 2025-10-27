#!/bin/bash

##############################################################################
# Chaos Engineering Platform - COMPLETE Full-Stack Deployment Script
#
# This script deploys EVERYTHING in one command:
# - Week 1: VPC infrastructure + Target application
# - Week 2: Chaos Lambda functions
# - Week 3: Step Functions orchestration
# - Week 4: Testing infrastructure
# - Weeks 5-8: Full-stack application (Frontend + Backend + Database)
#
# NO NEED TO RUN ANY OTHER SCRIPTS!
#
# Usage: ./deploy-fullstack-complete.sh [dev|staging|prod]
##############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-dev}
AWS_REGION=${AWS_REGION:-us-east-1}
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Print banner
clear
cat << "EOF"
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
EOF

echo ""
echo -e "${CYAN}Configuration:${NC}"
echo -e "  Environment: ${GREEN}${ENVIRONMENT}${NC}"
echo -e "  AWS Region: ${GREEN}${AWS_REGION}${NC}"
echo -e "  Project Root: ${GREEN}${PROJECT_ROOT}${NC}"
echo ""

# Function to print section headers
print_section() {
    echo ""
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}▶ $1${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Function to print success
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Function to print info
print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

# Function to wait with progress
wait_with_progress() {
    local duration=$1
    local message=$2
    echo -ne "${CYAN}${message}${NC}"
    for ((i=0; i<duration; i++)); do
        echo -ne "."
        sleep 1
    done
    echo -e " ${GREEN}Done!${NC}"
}

##############################################################################
# Pre-flight Checks
##############################################################################

print_section "Pre-flight Checks"

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install it first."
    echo ""
    echo "Install: https://aws.amazon.com/cli/"
    exit 1
fi
print_success "AWS CLI installed"

# Check Node.js
if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed. Please install Node.js 20+ first."
    echo ""
    echo "Install: https://nodejs.org/"
    exit 1
fi
NODE_VERSION=$(node --version)
print_success "Node.js installed: $NODE_VERSION"

# Check npm
if ! command -v npm &> /dev/null; then
    print_error "npm is not installed. Please install Node.js first."
    exit 1
fi
NPM_VERSION=$(npm --version)
print_success "npm installed: $NPM_VERSION"

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials are not configured."
    echo ""
    echo "Run: aws configure"
    exit 1
fi
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_USER=$(aws sts get-caller-identity --query Arn --output text)
print_success "AWS credentials configured"
print_info "Account ID: $AWS_ACCOUNT_ID"
print_info "User: $AWS_USER"

echo ""
print_warning "This deployment will take approximately 15-20 minutes"
print_warning "Estimated AWS cost: ~\$105/month (if left running 24/7)"
echo ""
read -p "Continue with deployment? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo ""
    print_info "Deployment cancelled"
    exit 0
fi

##############################################################################
# WEEK 1: VPC Infrastructure
##############################################################################

print_section "WEEK 1: Deploying VPC Infrastructure"

VPC_STACK_NAME="chaos-vpc-infrastructure"

if aws cloudformation describe-stacks --stack-name $VPC_STACK_NAME --region $AWS_REGION &> /dev/null 2>&1; then
    print_success "VPC infrastructure already exists"
else
    print_info "Creating VPC with multi-AZ setup..."

    aws cloudformation deploy \
        --template-file "$PROJECT_ROOT/infrastructure/vpc-infrastructure.yaml" \
        --stack-name $VPC_STACK_NAME \
        --region $AWS_REGION \
        --no-fail-on-empty-changeset \
        --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM

    print_success "VPC infrastructure deployed"
fi

# Get VPC ID
VPC_ID=$(aws cloudformation describe-stacks \
    --stack-name $VPC_STACK_NAME \
    --region $AWS_REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`VPCId`].OutputValue' \
    --output text)

print_info "VPC ID: $VPC_ID"

##############################################################################
# WEEK 1: Target Application
##############################################################################

print_section "WEEK 1: Deploying Target Application (EC2 + ALB)"

TARGET_STACK_NAME="chaos-target-application"

if aws cloudformation describe-stacks --stack-name $TARGET_STACK_NAME --region $AWS_REGION &> /dev/null 2>&1; then
    print_success "Target application already exists"
else
    print_info "Creating Auto Scaling Group with Load Balancer..."
    print_warning "This step takes ~7-10 minutes (EC2 instances need to launch)"

    aws cloudformation deploy \
        --template-file "$PROJECT_ROOT/infrastructure/target-application.yaml" \
        --stack-name $TARGET_STACK_NAME \
        --region $AWS_REGION \
        --no-fail-on-empty-changeset \
        --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM

    print_success "Target application deployed"
fi

# Get outputs
TARGET_ASG_NAME=$(aws cloudformation describe-stacks \
    --stack-name $TARGET_STACK_NAME \
    --region $AWS_REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`AutoScalingGroupName`].OutputValue' \
    --output text)

TARGET_GROUP_ARN=$(aws cloudformation describe-stacks \
    --stack-name $TARGET_STACK_NAME \
    --region $AWS_REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`TargetGroupArn`].OutputValue' \
    --output text)

LOAD_BALANCER_ARN=$(aws cloudformation describe-stacks \
    --stack-name $TARGET_STACK_NAME \
    --region $AWS_REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerArn`].OutputValue' \
    --output text)

LOAD_BALANCER_DNS=$(aws cloudformation describe-stacks \
    --stack-name $TARGET_STACK_NAME \
    --region $AWS_REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
    --output text)

print_info "Auto Scaling Group: $TARGET_ASG_NAME"
print_info "Load Balancer: $LOAD_BALANCER_DNS"

##############################################################################
# WEEK 2: Chaos Lambda Functions
##############################################################################

print_section "WEEK 2: Deploying Chaos Lambda Functions"

LAMBDA_STACK_NAME="chaos-lambda-functions"

if aws cloudformation describe-stacks --stack-name $LAMBDA_STACK_NAME --region $AWS_REGION &> /dev/null 2>&1; then
    print_success "Lambda functions already exist"
else
    print_info "Packaging Lambda functions..."

    # Package each Lambda function
    for FUNCTION_DIR in "$PROJECT_ROOT/lambda-functions"/*; do
        if [ -d "$FUNCTION_DIR" ]; then
            FUNCTION_NAME=$(basename "$FUNCTION_DIR")
            print_info "Packaging $FUNCTION_NAME..."

            cd "$FUNCTION_DIR"
            zip -q -r "../${FUNCTION_NAME}.zip" . -x "*.pyc" "__pycache__/*"
        fi
    done

    cd "$PROJECT_ROOT"

    print_info "Deploying Lambda functions..."

    aws cloudformation deploy \
        --template-file "$PROJECT_ROOT/infrastructure/chaos-lambda-functions.yaml" \
        --stack-name $LAMBDA_STACK_NAME \
        --region $AWS_REGION \
        --no-fail-on-empty-changeset \
        --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
        --parameter-overrides \
            VPCStackName=$VPC_STACK_NAME \
            TargetStackName=$TARGET_STACK_NAME

    print_success "Lambda functions deployed"
fi

##############################################################################
# WEEK 3: Step Functions Orchestration
##############################################################################

print_section "WEEK 3: Deploying Step Functions Orchestration"

STEP_FUNCTIONS_STACK_NAME="chaos-step-functions"

if aws cloudformation describe-stacks --stack-name $STEP_FUNCTIONS_STACK_NAME --region $AWS_REGION &> /dev/null 2>&1; then
    print_success "Step Functions already exist"
else
    print_info "Creating Step Functions state machine..."

    aws cloudformation deploy \
        --template-file "$PROJECT_ROOT/infrastructure/chaos-step-functions.yaml" \
        --stack-name $STEP_FUNCTIONS_STACK_NAME \
        --region $AWS_REGION \
        --no-fail-on-empty-changeset \
        --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
        --parameter-overrides \
            LambdaStackName=$LAMBDA_STACK_NAME \
            EnableScheduling=false

    print_success "Step Functions deployed"
fi

# Get State Machine ARN
STATE_MACHINE_ARN=$(aws cloudformation describe-stacks \
    --stack-name $STEP_FUNCTIONS_STACK_NAME \
    --region $AWS_REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`StateMachineArn`].OutputValue' \
    --output text)

print_info "State Machine: $STATE_MACHINE_ARN"

##############################################################################
# WEEKS 5-8: DynamoDB Database
##############################################################################

print_section "WEEKS 5-8: Deploying DynamoDB Database"

DATABASE_STACK_NAME="chaos-fullstack-database-${ENVIRONMENT}"

print_info "Creating DynamoDB tables..."

aws cloudformation deploy \
    --template-file "$PROJECT_ROOT/infrastructure/fullstack-database.yaml" \
    --stack-name $DATABASE_STACK_NAME \
    --region $AWS_REGION \
    --no-fail-on-empty-changeset \
    --parameter-overrides Environment=$ENVIRONMENT

print_success "DynamoDB tables deployed"

# Get table names
EXPERIMENTS_TABLE=$(aws cloudformation describe-stacks \
    --stack-name $DATABASE_STACK_NAME \
    --region $AWS_REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`ExperimentsTableName`].OutputValue' \
    --output text)

RESULTS_TABLE=$(aws cloudformation describe-stacks \
    --stack-name $DATABASE_STACK_NAME \
    --region $AWS_REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`ResultsTableName`].OutputValue' \
    --output text)

USERS_TABLE=$(aws cloudformation describe-stacks \
    --stack-name $DATABASE_STACK_NAME \
    --region $AWS_REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`UsersTableName`].OutputValue' \
    --output text)

print_info "Experiments Table: $EXPERIMENTS_TABLE"
print_info "Results Table: $RESULTS_TABLE"
print_info "Users Table: $USERS_TABLE"

##############################################################################
# WEEKS 5-8: Backend API
##############################################################################

print_section "WEEKS 5-8: Building and Packaging Backend API"

cd "$PROJECT_ROOT/backend"

# Install dependencies
if [ ! -d "node_modules" ]; then
    print_info "Installing backend dependencies..."
    npm install --silent
    print_success "Backend dependencies installed"
else
    print_success "Backend dependencies already installed"
fi

# Build TypeScript
print_info "Building backend (TypeScript compilation)..."
npm run build
print_success "Backend built successfully"

# Package for Lambda
print_info "Packaging Lambda functions..."
cd dist
zip -q -r ../lambda-functions.zip .
cd ..
print_success "Lambda functions packaged"

# Upload to S3
LAMBDA_BUCKET="chaos-platform-lambda-${AWS_ACCOUNT_ID}-${AWS_REGION}"

# Create bucket if needed
if ! aws s3 ls "s3://${LAMBDA_BUCKET}" 2>&1 | grep -q 'NoSuchBucket'; then
    print_success "Lambda S3 bucket exists"
else
    print_info "Creating Lambda S3 bucket..."
    aws s3 mb "s3://${LAMBDA_BUCKET}" --region $AWS_REGION
    aws s3api put-bucket-versioning \
        --bucket $LAMBDA_BUCKET \
        --versioning-configuration Status=Enabled
    print_success "Lambda bucket created"
fi

print_info "Uploading Lambda package to S3..."
aws s3 cp lambda-functions.zip "s3://${LAMBDA_BUCKET}/lambda-functions.zip"
print_success "Lambda package uploaded"

cd "$PROJECT_ROOT"

##############################################################################
# WEEKS 5-8: Frontend Application
##############################################################################

print_section "WEEKS 5-8: Building Frontend Application"

cd "$PROJECT_ROOT/frontend"

# Install dependencies
if [ ! -d "node_modules" ]; then
    print_info "Installing frontend dependencies..."
    npm install --silent
    print_success "Frontend dependencies installed"
else
    print_success "Frontend dependencies already installed"
fi

# Create production environment file
print_info "Configuring frontend environment..."
cat > .env.production << EOF
VITE_API_BASE_URL=https://api-${ENVIRONMENT}.chaos-platform.com/api/v1
VITE_AWS_REGION=$AWS_REGION
VITE_ENVIRONMENT=$ENVIRONMENT
EOF

# Build frontend
print_info "Building frontend (React + Vite)..."
npm run build
print_success "Frontend built successfully"

##############################################################################
# WEEKS 5-8: Deploy Frontend to S3
##############################################################################

print_section "WEEKS 5-8: Deploying Frontend to S3"

FRONTEND_BUCKET="chaos-platform-frontend-${ENVIRONMENT}-${AWS_ACCOUNT_ID}"

# Create bucket if needed
if aws s3 ls "s3://${FRONTEND_BUCKET}" 2>&1 | grep -q 'NoSuchBucket'; then
    print_info "Creating frontend S3 bucket..."

    aws s3 mb "s3://${FRONTEND_BUCKET}" --region $AWS_REGION

    # Configure static website hosting
    aws s3 website "s3://${FRONTEND_BUCKET}" \
        --index-document index.html \
        --error-document index.html

    # Set bucket policy for public read
    cat > /tmp/bucket-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${FRONTEND_BUCKET}/*"
    }
  ]
}
EOF

    aws s3api put-bucket-policy \
        --bucket $FRONTEND_BUCKET \
        --policy file:///tmp/bucket-policy.json

    rm /tmp/bucket-policy.json

    print_success "Frontend bucket created and configured"
else
    print_success "Frontend bucket already exists"
fi

# Upload frontend files
print_info "Uploading frontend files to S3..."

aws s3 sync dist/ "s3://${FRONTEND_BUCKET}/" \
    --delete \
    --cache-control "public, max-age=31536000" \
    --exclude "index.html" \
    --quiet

# Upload index.html without caching
aws s3 cp dist/index.html "s3://${FRONTEND_BUCKET}/index.html" \
    --cache-control "no-cache, no-store, must-revalidate"

print_success "Frontend deployed to S3"

# Get website URL
WEBSITE_URL="http://${FRONTEND_BUCKET}.s3-website-${AWS_REGION}.amazonaws.com"

cd "$PROJECT_ROOT"

##############################################################################
# Deployment Complete!
##############################################################################

print_section "🎉 DEPLOYMENT COMPLETE! 🎉"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                                        ║${NC}"
echo -e "${GREEN}║    ✅ ALL COMPONENTS SUCCESSFULLY DEPLOYED!                           ║${NC}"
echo -e "${GREEN}║                                                                        ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Infrastructure Summary
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}📊 INFRASTRUCTURE SUMMARY${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Week 1: Foundation${NC}"
echo -e "  VPC ID:              ${GREEN}$VPC_ID${NC}"
echo -e "  Auto Scaling Group:  ${GREEN}$TARGET_ASG_NAME${NC}"
echo -e "  Load Balancer DNS:   ${GREEN}$LOAD_BALANCER_DNS${NC}"
echo ""
echo -e "${YELLOW}Week 2-3: Chaos Infrastructure${NC}"
echo -e "  Lambda Functions:    ${GREEN}3 functions deployed${NC}"
echo -e "  State Machine:       ${GREEN}$STATE_MACHINE_ARN${NC}"
echo ""
echo -e "${YELLOW}Weeks 5-8: Full-Stack Application${NC}"
echo -e "  Experiments Table:   ${GREEN}$EXPERIMENTS_TABLE${NC}"
echo -e "  Results Table:       ${GREEN}$RESULTS_TABLE${NC}"
echo -e "  Users Table:         ${GREEN}$USERS_TABLE${NC}"
echo -e "  Frontend Bucket:     ${GREEN}$FRONTEND_BUCKET${NC}"
echo -e "  Lambda Package:      ${GREEN}s3://${LAMBDA_BUCKET}/lambda-functions.zip${NC}"
echo ""

# Access Information
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}🌐 ACCESS YOUR APPLICATION${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Frontend URL:${NC}"
echo -e "  ${GREEN}${WEBSITE_URL}${NC}"
echo ""
echo -e "${YELLOW}Login Credentials (Mock Auth):${NC}"
echo -e "  Email:    ${GREEN}admin@chaos-platform.com${NC}"
echo -e "  Password: ${GREEN}anything (any password works)${NC}"
echo ""

# Next Steps
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}🚀 NEXT STEPS${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  1. ${GREEN}Open the frontend URL in your browser${NC}"
echo -e "  2. ${GREEN}Login with the credentials above${NC}"
echo -e "  3. ${GREEN}Click 'New Experiment' to create your first chaos test${NC}"
echo -e "  4. ${GREEN}Enable 'Dry Run' for safe testing${NC}"
echo -e "  5. ${GREEN}Monitor the experiment in real-time${NC}"
echo ""

# Cost Information
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}💰 COST INFORMATION${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  Estimated Monthly Cost (24/7): ${YELLOW}~\$105/month${NC}"
echo ""
echo -e "  ${YELLOW}⚠ IMPORTANT:${NC} To avoid charges, run cleanup when done:"
echo -e "     ${GREEN}./scripts/cleanup.sh${NC}"
echo ""

# Useful Commands
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}📝 USEFUL COMMANDS${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  Test target application:"
echo -e "    ${GREEN}curl http://${LOAD_BALANCER_DNS}${NC}"
echo ""
echo -e "  View experiment logs:"
echo -e "    ${GREEN}aws logs tail /aws/lambda/chaos-inject-failure --follow${NC}"
echo ""
echo -e "  Run end-to-end tests:"
echo -e "    ${GREEN}./scripts/test-end-to-end.sh${NC}"
echo ""
echo -e "  Clean up all resources:"
echo -e "    ${GREEN}./scripts/cleanup.sh${NC}"
echo ""

echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}✨ Happy Chaos Engineering! ✨${NC}"
echo ""
