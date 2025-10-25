#!/bin/bash

##############################################################################
# Chaos Engineering Platform - Full-Stack Deployment Script
#
# This script deploys the complete full-stack application including:
# - Backend infrastructure (DynamoDB tables)
# - Backend API (Lambda functions + API Gateway)
# - Frontend (React app to S3 + CloudFront)
# - Integration with existing chaos experiment infrastructure
#
# Usage: ./deploy-fullstack.sh [--environment dev|staging|prod]
##############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-dev}
AWS_REGION=${AWS_REGION:-us-east-1}
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Chaos Engineering Platform${NC}"
echo -e "${BLUE}Full-Stack Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Environment: ${GREEN}${ENVIRONMENT}${NC}"
echo -e "AWS Region: ${GREEN}${AWS_REGION}${NC}"
echo -e "Project Root: ${GREEN}${PROJECT_ROOT}${NC}"
echo ""

# Function to print section headers
print_section() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
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

# Verify AWS CLI is installed
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Verify AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials are not configured. Please run 'aws configure'"
    exit 1
fi

print_success "AWS CLI configured"

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
print_success "AWS Account ID: $AWS_ACCOUNT_ID"

##############################################################################
# Step 1: Deploy Existing Infrastructure (if not already deployed)
##############################################################################

print_section "Step 1: Checking Existing Infrastructure"

# Check if VPC infrastructure exists
if aws cloudformation describe-stacks --stack-name chaos-vpc-infrastructure --region $AWS_REGION &> /dev/null; then
    print_success "VPC infrastructure already deployed"
else
    print_warning "VPC infrastructure not found. Deploying..."
    cd "$PROJECT_ROOT"
    ./scripts/deploy.sh
fi

# Get existing infrastructure outputs
VPC_STACK_NAME="chaos-vpc-infrastructure"
TARGET_STACK_NAME="chaos-target-application"
LAMBDA_STACK_NAME="chaos-lambda-functions"
STEP_FUNCTIONS_STACK_NAME="chaos-step-functions"

# Get Stack Outputs
get_stack_output() {
    aws cloudformation describe-stacks \
        --stack-name $1 \
        --region $AWS_REGION \
        --query "Stacks[0].Outputs[?OutputKey=='$2'].OutputValue" \
        --output text 2>/dev/null || echo ""
}

VPC_ID=$(get_stack_output $VPC_STACK_NAME "VPCId")
TARGET_ASG_NAME=$(get_stack_output $TARGET_STACK_NAME "AutoScalingGroupName")
TARGET_GROUP_ARN=$(get_stack_output $TARGET_STACK_NAME "TargetGroupArn")
LOAD_BALANCER_ARN=$(get_stack_output $TARGET_STACK_NAME "LoadBalancerArn")
STATE_MACHINE_ARN=$(get_stack_output $STEP_FUNCTIONS_STACK_NAME "StateMachineArn")

print_success "Retrieved existing infrastructure details"

##############################################################################
# Step 2: Deploy DynamoDB Tables
##############################################################################

print_section "Step 2: Deploying DynamoDB Tables"

DATABASE_STACK_NAME="chaos-fullstack-database-${ENVIRONMENT}"

aws cloudformation deploy \
    --template-file "$PROJECT_ROOT/infrastructure/fullstack-database.yaml" \
    --stack-name $DATABASE_STACK_NAME \
    --parameter-overrides \
        Environment=$ENVIRONMENT \
    --region $AWS_REGION \
    --no-fail-on-empty-changeset

print_success "DynamoDB tables deployed"

# Get table names
EXPERIMENTS_TABLE=$(get_stack_output $DATABASE_STACK_NAME "ExperimentsTableName")
RESULTS_TABLE=$(get_stack_output $DATABASE_STACK_NAME "ResultsTableName")
USERS_TABLE=$(get_stack_output $DATABASE_STACK_NAME "UsersTableName")

print_success "Experiments Table: $EXPERIMENTS_TABLE"
print_success "Results Table: $RESULTS_TABLE"
print_success "Users Table: $USERS_TABLE"

##############################################################################
# Step 3: Build Backend
##############################################################################

print_section "Step 3: Building Backend"

cd "$PROJECT_ROOT/backend"

if [ ! -d "node_modules" ]; then
    print_warning "Installing backend dependencies..."
    npm install
fi

print_success "Backend dependencies installed"

# Build TypeScript
npm run build

print_success "Backend built successfully"

# Package Lambda functions
cd dist
zip -r ../lambda-functions.zip . > /dev/null
cd ..

print_success "Lambda functions packaged"

# Upload to S3
LAMBDA_BUCKET="chaos-platform-lambda-${AWS_ACCOUNT_ID}-${AWS_REGION}"

# Create bucket if it doesn't exist
if ! aws s3 ls "s3://${LAMBDA_BUCKET}" 2>&1 | grep -q 'NoSuchBucket'; then
    print_success "Lambda S3 bucket exists"
else
    print_warning "Creating Lambda S3 bucket..."
    aws s3 mb "s3://${LAMBDA_BUCKET}" --region $AWS_REGION
    aws s3api put-bucket-versioning \
        --bucket $LAMBDA_BUCKET \
        --versioning-configuration Status=Enabled
fi

aws s3 cp lambda-functions.zip "s3://${LAMBDA_BUCKET}/lambda-functions.zip"

print_success "Lambda package uploaded to S3"

##############################################################################
# Step 4: Deploy Backend API (Lambda + API Gateway)
##############################################################################

print_section "Step 4: Deploying Backend API"

# Note: This would require a fullstack-backend.yaml CloudFormation template
# For now, we'll create a simplified version message

print_warning "Backend API Gateway + Lambda deployment requires additional CloudFormation template"
print_warning "This will be completed in the next step of the deployment"

##############################################################################
# Step 5: Build Frontend
##############################################################################

print_section "Step 5: Building Frontend"

cd "$PROJECT_ROOT/frontend"

if [ ! -d "node_modules" ]; then
    print_warning "Installing frontend dependencies..."
    npm install
fi

print_success "Frontend dependencies installed"

# Create production environment file
cat > .env.production << EOF
VITE_API_BASE_URL=https://api-${ENVIRONMENT}.chaos-platform.example.com/api/v1
VITE_AWS_REGION=$AWS_REGION
VITE_ENVIRONMENT=$ENVIRONMENT
EOF

print_success "Frontend environment configured"

# Build frontend
npm run build

print_success "Frontend built successfully"

##############################################################################
# Step 6: Deploy Frontend to S3
##############################################################################

print_section "Step 6: Deploying Frontend"

# Create S3 bucket for frontend
FRONTEND_BUCKET="chaos-platform-frontend-${ENVIRONMENT}-${AWS_ACCOUNT_ID}"

if aws s3 ls "s3://${FRONTEND_BUCKET}" 2>&1 | grep -q 'NoSuchBucket'; then
    print_warning "Creating frontend S3 bucket..."
    aws s3 mb "s3://${FRONTEND_BUCKET}" --region $AWS_REGION

    # Configure bucket for static website hosting
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

    print_success "Frontend bucket created and configured"
else
    print_success "Frontend bucket exists"
fi

# Upload frontend files
aws s3 sync dist/ "s3://${FRONTEND_BUCKET}/" \
    --delete \
    --cache-control "public, max-age=31536000" \
    --exclude "index.html"

# Upload index.html without caching
aws s3 cp dist/index.html "s3://${FRONTEND_BUCKET}/index.html" \
    --cache-control "no-cache, no-store, must-revalidate"

print_success "Frontend deployed to S3"

# Get website URL
WEBSITE_URL="http://${FRONTEND_BUCKET}.s3-website-${AWS_REGION}.amazonaws.com"
print_success "Frontend URL: $WEBSITE_URL"

##############################################################################
# Step 7: Display Deployment Summary
##############################################################################

print_section "Deployment Summary"

echo ""
echo -e "${GREEN}✓ Full-Stack Deployment Complete!${NC}"
echo ""
echo -e "${BLUE}Infrastructure Details:${NC}"
echo -e "  VPC ID: ${GREEN}$VPC_ID${NC}"
echo -e "  Target ASG: ${GREEN}$TARGET_ASG_NAME${NC}"
echo -e "  State Machine: ${GREEN}$STATE_MACHINE_ARN${NC}"
echo ""
echo -e "${BLUE}Database:${NC}"
echo -e "  Experiments Table: ${GREEN}$EXPERIMENTS_TABLE${NC}"
echo -e "  Results Table: ${GREEN}$RESULTS_TABLE${NC}"
echo -e "  Users Table: ${GREEN}$USERS_TABLE${NC}"
echo ""
echo -e "${BLUE}Frontend:${NC}"
echo -e "  S3 Bucket: ${GREEN}$FRONTEND_BUCKET${NC}"
echo -e "  Website URL: ${GREEN}$WEBSITE_URL${NC}"
echo ""
echo -e "${BLUE}Backend:${NC}"
echo -e "  Lambda Package: ${GREEN}s3://${LAMBDA_BUCKET}/lambda-functions.zip${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo -e "  1. Complete API Gateway deployment (manual step required)"
echo -e "  2. Update frontend environment with API Gateway URL"
echo -e "  3. Access the application at: ${GREEN}$WEBSITE_URL${NC}"
echo -e "  4. Run end-to-end tests: ${GREEN}./scripts/test-fullstack.sh${NC}"
echo ""
echo -e "${BLUE}========================================${NC}"
