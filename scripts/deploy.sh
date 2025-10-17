#!/bin/bash

# Deployment script for Chaos Engineering Platform
# Week 1: VPC and Target Application

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

PROJECT_NAME="chaos-platform"
REGION="${AWS_REGION:-us-east-1}"

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Chaos Engineering Platform${NC}"
echo -e "${GREEN}Deployment Script - Week 1${NC}"
echo -e "${GREEN}================================${NC}\n"

# Check AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not installed${NC}"
    echo "Please install AWS CLI: https://aws.amazon.com/cli/"
    exit 1
fi

# Check AWS credentials
echo -e "${YELLOW}Checking AWS credentials...${NC}"
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}Error: AWS credentials not configured${NC}"
    echo "Run: aws configure"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}✓ Connected to AWS Account: ${ACCOUNT_ID}${NC}\n"

# Step 1: Deploy VPC Infrastructure
echo -e "${YELLOW}Step 1: Deploying VPC Infrastructure...${NC}"
VPC_STACK_NAME="${PROJECT_NAME}-vpc"

if aws cloudformation describe-stacks --stack-name $VPC_STACK_NAME --region $REGION &> /dev/null; then
    echo -e "${YELLOW}Stack $VPC_STACK_NAME already exists. Updating...${NC}"
    aws cloudformation update-stack \
        --stack-name $VPC_STACK_NAME \
        --template-body file://infrastructure/vpc-infrastructure.yaml \
        --capabilities CAPABILITY_NAMED_IAM \
        --region $REGION || echo "No updates to be performed"
else
    echo -e "${YELLOW}Creating stack $VPC_STACK_NAME...${NC}"
    aws cloudformation create-stack \
        --stack-name $VPC_STACK_NAME \
        --template-body file://infrastructure/vpc-infrastructure.yaml \
        --capabilities CAPABILITY_NAMED_IAM \
        --region $REGION
fi

echo -e "${YELLOW}Waiting for VPC stack to complete...${NC}"
aws cloudformation wait stack-create-complete \
    --stack-name $VPC_STACK_NAME \
    --region $REGION 2>/dev/null || \
aws cloudformation wait stack-update-complete \
    --stack-name $VPC_STACK_NAME \
    --region $REGION 2>/dev/null || true

VPC_STATUS=$(aws cloudformation describe-stacks \
    --stack-name $VPC_STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].StackStatus' \
    --output text)

if [[ $VPC_STATUS == *"COMPLETE"* ]]; then
    echo -e "${GREEN}✓ VPC Infrastructure deployed successfully${NC}\n"
else
    echo -e "${RED}✗ VPC deployment failed with status: $VPC_STATUS${NC}"
    exit 1
fi

# Step 2: Deploy Target Application
echo -e "${YELLOW}Step 2: Deploying Target Application...${NC}"
APP_STACK_NAME="${PROJECT_NAME}-target-app"

if aws cloudformation describe-stacks --stack-name $APP_STACK_NAME --region $REGION &> /dev/null; then
    echo -e "${YELLOW}Stack $APP_STACK_NAME already exists. Updating...${NC}"
    aws cloudformation update-stack \
        --stack-name $APP_STACK_NAME \
        --template-body file://infrastructure/target-application.yaml \
        --parameters file://infrastructure/parameters.json \
        --capabilities CAPABILITY_NAMED_IAM \
        --region $REGION || echo "No updates to be performed"
else
    echo -e "${YELLOW}Creating stack $APP_STACK_NAME...${NC}"
    aws cloudformation create-stack \
        --stack-name $APP_STACK_NAME \
        --template-body file://infrastructure/target-application.yaml \
        --parameters file://infrastructure/parameters.json \
        --capabilities CAPABILITY_NAMED_IAM \
        --region $REGION
fi

echo -e "${YELLOW}Waiting for Target Application stack to complete (this may take 5-10 minutes)...${NC}"
aws cloudformation wait stack-create-complete \
    --stack-name $APP_STACK_NAME \
    --region $REGION 2>/dev/null || \
aws cloudformation wait stack-update-complete \
    --stack-name $APP_STACK_NAME \
    --region $REGION 2>/dev/null || true

APP_STATUS=$(aws cloudformation describe-stacks \
    --stack-name $APP_STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].StackStatus' \
    --output text)

if [[ $APP_STATUS == *"COMPLETE"* ]]; then
    echo -e "${GREEN}✓ Target Application deployed successfully${NC}\n"
else
    echo -e "${RED}✗ Target Application deployment failed with status: $APP_STATUS${NC}"
    exit 1
fi

# Step 3: Display outputs
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}================================${NC}\n"

echo -e "${YELLOW}Application Details:${NC}"

ALB_URL=$(aws cloudformation describe-stacks \
    --stack-name $APP_STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' \
    --output text)

ASG_NAME=$(aws cloudformation describe-stacks \
    --stack-name $APP_STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`AutoScalingGroupName`].OutputValue' \
    --output text)

echo -e "Load Balancer URL: ${GREEN}${ALB_URL}${NC}"
echo -e "Auto Scaling Group: ${GREEN}${ASG_NAME}${NC}\n"

echo -e "${YELLOW}Testing application availability...${NC}"
sleep 30  # Give the instances time to register

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" $ALB_URL || echo "000")
if [ "$HTTP_CODE" == "200" ]; then
    echo -e "${GREEN}✓ Application is responding successfully!${NC}"
    echo -e "${GREEN}Visit: ${ALB_URL}${NC}\n"
else
    echo -e "${YELLOW}⚠ Application is still initializing (HTTP $HTTP_CODE)${NC}"
    echo -e "${YELLOW}This may take a few more minutes. Check: ${ALB_URL}${NC}\n"
fi

echo -e "${YELLOW}Useful Commands:${NC}"
echo -e "  View ASG instances: ${GREEN}aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $ASG_NAME --region $REGION${NC}"
echo -e "  View ALB health: ${GREEN}aws elbv2 describe-target-health --target-group-arn <TG_ARN> --region $REGION${NC}"
echo -e "  View logs: ${GREEN}aws logs tail /aws/ec2/$PROJECT_NAME/httpd/access --follow --region $REGION${NC}\n"

echo -e "${GREEN}Week 1 deployment completed successfully!${NC}"
