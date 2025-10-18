#!/bin/bash

# Deployment script for Chaos Engineering Step Functions
# Week 3: Deploy Step Functions state machine and EventBridge scheduling

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

PROJECT_NAME="chaos-platform"
REGION="${AWS_REGION:-us-east-1}"
ENABLE_SCHEDULING="${1:-false}"

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Chaos Step Functions${NC}"
echo -e "${GREEN}Deployment Script - Week 3${NC}"
echo -e "${GREEN}================================${NC}\n"

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not installed${NC}"
    exit 1
fi

# Check AWS credentials
echo -e "${YELLOW}Checking AWS credentials...${NC}"
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}Error: AWS credentials not configured${NC}"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}✓ Connected to AWS Account: ${ACCOUNT_ID}${NC}\n"

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check if Lambda functions are deployed
LAMBDA_STACK="${PROJECT_NAME}-lambda-functions"
if ! aws cloudformation describe-stacks --stack-name $LAMBDA_STACK --region $REGION &> /dev/null; then
    echo -e "${RED}Error: Lambda functions stack not found${NC}"
    echo "Please deploy Lambda functions first: ./scripts/deploy-lambda-functions.sh"
    exit 1
fi

# Check if target application is deployed
APP_STACK="${PROJECT_NAME}-target-app"
if ! aws cloudformation describe-stacks --stack-name $APP_STACK --region $REGION &> /dev/null; then
    echo -e "${RED}Error: Target application stack not found${NC}"
    echo "Please deploy target application first: ./scripts/deploy.sh"
    exit 1
fi

echo -e "${GREEN}✓ All prerequisites met${NC}\n"

# Get infrastructure details
echo -e "${YELLOW}Retrieving infrastructure details...${NC}"

TG_ARN=$(aws cloudformation describe-stacks \
    --stack-name $APP_STACK \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`TargetGroupArn`].OutputValue' \
    --output text)

LB_ARN=$(aws cloudformation describe-stacks \
    --stack-name $APP_STACK \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerArn`].OutputValue' \
    --output text)

ASG_NAME=$(aws cloudformation describe-stacks \
    --stack-name $APP_STACK \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`AutoScalingGroupName`].OutputValue' \
    --output text)

echo -e "${GREEN}✓ Infrastructure details retrieved${NC}"
echo -e "  Auto Scaling Group: ${ASG_NAME}"
echo -e "  Target Group: ${TG_ARN##*/}"
echo -e "  Load Balancer: ${LB_ARN##*/}\n"

# Step 1: Deploy Step Functions stack
echo -e "${YELLOW}Step 1: Deploying Step Functions CloudFormation Stack...${NC}"
STEP_STACK_NAME="${PROJECT_NAME}-step-functions"

# Create parameters file with infrastructure details
cat > /tmp/step-functions-params.json <<EOF
[
  {
    "ParameterKey": "ProjectName",
    "ParameterValue": "${PROJECT_NAME}"
  },
  {
    "ParameterKey": "EnableScheduling",
    "ParameterValue": "${ENABLE_SCHEDULING}"
  }
]
EOF

if aws cloudformation describe-stacks --stack-name $STEP_STACK_NAME --region $REGION &> /dev/null; then
    echo -e "${YELLOW}Stack $STEP_STACK_NAME already exists. Updating...${NC}"
    aws cloudformation update-stack \
        --stack-name $STEP_STACK_NAME \
        --template-body file://infrastructure/chaos-step-functions.yaml \
        --parameters file:///tmp/step-functions-params.json \
        --capabilities CAPABILITY_NAMED_IAM \
        --region $REGION || echo "No updates to be performed"
else
    echo -e "${YELLOW}Creating stack $STEP_STACK_NAME...${NC}"
    aws cloudformation create-stack \
        --stack-name $STEP_STACK_NAME \
        --template-body file://infrastructure/chaos-step-functions.yaml \
        --parameters file:///tmp/step-functions-params.json \
        --capabilities CAPABILITY_NAMED_IAM \
        --region $REGION
fi

echo -e "${YELLOW}Waiting for Step Functions stack to complete...${NC}"
aws cloudformation wait stack-create-complete \
    --stack-name $STEP_STACK_NAME \
    --region $REGION 2>/dev/null || \
aws cloudformation wait stack-update-complete \
    --stack-name $STEP_STACK_NAME \
    --region $REGION 2>/dev/null || true

STEP_STATUS=$(aws cloudformation describe-stacks \
    --stack-name $STEP_STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].StackStatus' \
    --output text)

if [[ $STEP_STATUS == *"COMPLETE"* ]]; then
    echo -e "${GREEN}✓ Step Functions stack deployed successfully${NC}\n"
else
    echo -e "${RED}✗ Step Functions deployment failed with status: $STEP_STATUS${NC}"
    exit 1
fi

# Cleanup
rm -f /tmp/step-functions-params.json

# Step 2: Get outputs
echo -e "${YELLOW}Step 2: Retrieving deployment outputs...${NC}\n"

STATE_MACHINE_ARN=$(aws cloudformation describe-stacks \
    --stack-name $STEP_STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`StateMachineArn`].OutputValue' \
    --output text)

STATE_MACHINE_NAME=$(aws cloudformation describe-stacks \
    --stack-name $STEP_STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`StateMachineName`].OutputValue' \
    --output text)

LOG_GROUP=$(aws cloudformation describe-stacks \
    --stack-name $STEP_STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`LogGroupName`].OutputValue' \
    --output text)

# Step 3: Display outputs
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}================================${NC}\n"

echo -e "${YELLOW}Step Functions Details:${NC}"
echo -e "  State Machine Name: ${GREEN}${STATE_MACHINE_NAME}${NC}"
echo -e "  State Machine ARN: ${GREEN}${STATE_MACHINE_ARN}${NC}"
echo -e "  Log Group: ${GREEN}${LOG_GROUP}${NC}\n"

if [ "$ENABLE_SCHEDULING" == "true" ]; then
    SCHEDULE_ARN=$(aws cloudformation describe-stacks \
        --stack-name $STEP_STACK_NAME \
        --region $REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`ScheduleRuleArn`].OutputValue' \
        --output text 2>/dev/null)

    SCHEDULE_EXPR=$(aws cloudformation describe-stacks \
        --stack-name $STEP_STACK_NAME \
        --region $REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`ScheduleExpression`].OutputValue' \
        --output text 2>/dev/null)

    echo -e "${YELLOW}EventBridge Scheduling:${NC}"
    echo -e "  ${GREEN}ENABLED${NC}"
    echo -e "  Schedule: ${GREEN}${SCHEDULE_EXPR}${NC}"
    echo -e "  Rule ARN: ${GREEN}${SCHEDULE_ARN}${NC}\n"
else
    echo -e "${YELLOW}EventBridge Scheduling:${NC}"
    echo -e "  ${YELLOW}DISABLED${NC} (manual execution only)\n"
fi

echo -e "${YELLOW}Testing Commands:${NC}"
echo -e "  Manual execution: ${GREEN}./scripts/run-chaos-experiment.sh${NC}"
echo -e "  View executions: ${GREEN}aws stepfunctions list-executions --state-machine-arn $STATE_MACHINE_ARN --region $REGION${NC}"
echo -e "  View logs: ${GREEN}aws logs tail ${LOG_GROUP} --follow --region $REGION${NC}\n"

echo -e "${YELLOW}Next Steps:${NC}"
echo -e "  1. Test manual execution: ${GREEN}./scripts/run-chaos-experiment.sh${NC}"
echo -e "  2. View execution in AWS Console"
echo -e "  3. Monitor CloudWatch logs"
if [ "$ENABLE_SCHEDULING" == "true" ]; then
    echo -e "  4. Automated experiments will run according to schedule: ${SCHEDULE_EXPR}\n"
else
    echo -e "  4. To enable scheduling, redeploy with: ${GREEN}./scripts/deploy-step-functions.sh true${NC}\n"
fi

echo -e "${GREEN}Week 3 Step Functions deployed successfully!${NC}\n"
