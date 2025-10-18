#!/bin/bash


# Cleanup script for Chaos Engineering Platform


# Removes all AWS resources to avoid charges


set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

PROJECT_NAME="chaos-platform"
REGION="${AWS_REGION:-us-east-1}"

echo -e "${RED}================================${NC}"
echo -e "${RED}Chaos Engineering Platform${NC}"
echo -e "${RED}CLEANUP SCRIPT${NC}"
echo -e "${RED}================================${NC}\n"

echo -e "${YELLOW}This will DELETE all resources created by the Chaos Engineering Platform.${NC}"
echo -e "${RED}WARNING: This action cannot be undone!${NC}\n"

read -p "Are you sure you want to continue? (type 'yes' to confirm): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo -e "${GREEN}Cleanup cancelled.${NC}"
    exit 0
fi

echo ""

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not installed${NC}"
    exit 1
fi

# Check credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}Error: AWS credentials not configured${NC}"
    exit 1
fi

# Step 1: Delete Target Application Stack
echo -e "${YELLOW}Step 1: Deleting Target Application...${NC}"
APP_STACK_NAME="${PROJECT_NAME}-target-app"

if aws cloudformation describe-stacks --stack-name $APP_STACK_NAME --region $REGION &> /dev/null; then
    echo -e "${YELLOW}Deleting stack: $APP_STACK_NAME${NC}"
    aws cloudformation delete-stack \
        --stack-name $APP_STACK_NAME \
        --region $REGION

    echo -e "${YELLOW}Waiting for Target Application deletion (this may take a few minutes)...${NC}"
    aws cloudformation wait stack-delete-complete \
        --stack-name $APP_STACK_NAME \
        --region $REGION 2>/dev/null || true

    echo -e "${GREEN}✓ Target Application deleted${NC}\n"
else
    echo -e "${YELLOW}Stack $APP_STACK_NAME not found, skipping...${NC}\n"
fi

# Step 2: Delete VPC Stack
echo -e "${YELLOW}Step 2: Deleting VPC Infrastructure...${NC}"
VPC_STACK_NAME="${PROJECT_NAME}-vpc"

if aws cloudformation describe-stacks --stack-name $VPC_STACK_NAME --region $REGION &> /dev/null; then
    echo -e "${YELLOW}Deleting stack: $VPC_STACK_NAME${NC}"
    aws cloudformation delete-stack \
        --stack-name $VPC_STACK_NAME \
        --region $REGION

    echo -e "${YELLOW}Waiting for VPC deletion...${NC}"
    aws cloudformation wait stack-delete-complete \
        --stack-name $VPC_STACK_NAME \
        --region $REGION 2>/dev/null || true

    echo -e "${GREEN}✓ VPC Infrastructure deleted${NC}\n"
else
    echo -e "${YELLOW}Stack $VPC_STACK_NAME not found, skipping...${NC}\n"
fi

# Step 3: Clean up CloudWatch Logs
echo -e "${YELLOW}Step 3: Cleaning up CloudWatch Logs...${NC}"

LOG_GROUPS=(
    "/aws/vpc/${PROJECT_NAME}"
    "/aws/ec2/${PROJECT_NAME}/httpd/access"
    "/aws/ec2/${PROJECT_NAME}/httpd/error"
)

for LOG_GROUP in "${LOG_GROUPS[@]}"; do
    if aws logs describe-log-groups --log-group-name-prefix "$LOG_GROUP" --region $REGION --query 'logGroups[0]' &> /dev/null; then
        echo -e "${YELLOW}Deleting log group: $LOG_GROUP${NC}"
        aws logs delete-log-group --log-group-name "$LOG_GROUP" --region $REGION 2>/dev/null || echo "Already deleted"
    fi
done

echo -e "${GREEN}✓ CloudWatch logs cleaned up${NC}\n"

# Verification
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Cleanup Complete!${NC}"
echo -e "${GREEN}================================${NC}\n"

echo -e "${YELLOW}Verifying cleanup...${NC}"

REMAINING_STACKS=$(aws cloudformation list-stacks \
    --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
    --region $REGION \
    --query "StackSummaries[?starts_with(StackName, '${PROJECT_NAME}')].StackName" \
    --output text)

if [ -z "$REMAINING_STACKS" ]; then
    echo -e "${GREEN}✓ All CloudFormation stacks removed${NC}"
else
    echo -e "${YELLOW}⚠ Some stacks may still exist: $REMAINING_STACKS${NC}"
fi

echo -e "\n${GREEN}All Chaos Engineering Platform resources have been cleaned up.${NC}"
echo -e "${YELLOW}Note: It may take a few minutes for all resources to be fully removed.${NC}\n"
