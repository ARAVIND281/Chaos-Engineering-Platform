#!/bin/bash

# Deployment script for Chaos Engineering Lambda Functions
# Week 2: Deploy all three Lambda functions

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

PROJECT_NAME="chaos-platform"
REGION="${AWS_REGION:-us-east-1}"

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Chaos Lambda Functions${NC}"
echo -e "${GREEN}Deployment Script - Week 2${NC}"
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

# Check if zip command is available
if ! command -v zip &> /dev/null; then
    echo -e "${RED}Error: zip command not found${NC}"
    echo "Please install zip: brew install zip (macOS) or apt-get install zip (Linux)"
    exit 1
fi

# Create temporary directory for deployment packages
TEMP_DIR=$(mktemp -d)
echo -e "${YELLOW}Using temporary directory: $TEMP_DIR${NC}\n"

# Function to package Lambda function
package_function() {
    local function_name=$1
    local function_dir=$2

    echo -e "${YELLOW}Packaging ${function_name}...${NC}"

    cd "$function_dir"

    # Create deployment package
    zip -q -r "${TEMP_DIR}/${function_name}.zip" lambda_function.py

    echo -e "${GREEN}✓ Packaged ${function_name}${NC}"

    cd - > /dev/null
}

# Step 1: Deploy CloudFormation stack (creates Lambda functions with IAM roles)
echo -e "${YELLOW}Step 1: Deploying Lambda Functions CloudFormation Stack...${NC}"
LAMBDA_STACK_NAME="${PROJECT_NAME}-lambda-functions"

if aws cloudformation describe-stacks --stack-name $LAMBDA_STACK_NAME --region $REGION &> /dev/null; then
    echo -e "${YELLOW}Stack $LAMBDA_STACK_NAME already exists. Updating...${NC}"
    aws cloudformation update-stack \
        --stack-name $LAMBDA_STACK_NAME \
        --template-body file://infrastructure/chaos-lambda-functions.yaml \
        --capabilities CAPABILITY_NAMED_IAM \
        --region $REGION || echo "No updates to be performed"
else
    echo -e "${YELLOW}Creating stack $LAMBDA_STACK_NAME...${NC}"
    aws cloudformation create-stack \
        --stack-name $LAMBDA_STACK_NAME \
        --template-body file://infrastructure/chaos-lambda-functions.yaml \
        --capabilities CAPABILITY_NAMED_IAM \
        --region $REGION
fi

echo -e "${YELLOW}Waiting for Lambda stack to complete...${NC}"
aws cloudformation wait stack-create-complete \
    --stack-name $LAMBDA_STACK_NAME \
    --region $REGION 2>/dev/null || \
aws cloudformation wait stack-update-complete \
    --stack-name $LAMBDA_STACK_NAME \
    --region $REGION 2>/dev/null || true

LAMBDA_STATUS=$(aws cloudformation describe-stacks \
    --stack-name $LAMBDA_STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].StackStatus' \
    --output text)

if [[ $LAMBDA_STATUS == *"COMPLETE"* ]]; then
    echo -e "${GREEN}✓ Lambda stack deployed successfully${NC}\n"
else
    echo -e "${RED}✗ Lambda stack deployment failed with status: $LAMBDA_STATUS${NC}"
    exit 1
fi

# Step 2: Package Lambda functions
echo -e "${YELLOW}Step 2: Packaging Lambda Functions...${NC}\n"

package_function "get-target-instance" "lambda-functions/get-target-instance"
package_function "inject-failure" "lambda-functions/inject-failure"
package_function "validate-system-health" "lambda-functions/validate-system-health"

echo ""

# Step 3: Update Lambda function code
echo -e "${YELLOW}Step 3: Updating Lambda Function Code...${NC}\n"

update_function() {
    local function_name=$1
    local zip_file=$2

    echo -e "${YELLOW}Updating ${function_name}...${NC}"

    aws lambda update-function-code \
        --function-name "${PROJECT_NAME}-${function_name}" \
        --zip-file "fileb://${zip_file}" \
        --region $REGION \
        --output json > /dev/null

    # Wait for update to complete
    aws lambda wait function-updated \
        --function-name "${PROJECT_NAME}-${function_name}" \
        --region $REGION

    echo -e "${GREEN}✓ Updated ${function_name}${NC}"
}

update_function "get-target-instance" "${TEMP_DIR}/get-target-instance.zip"
update_function "inject-failure" "${TEMP_DIR}/inject-failure.zip"
update_function "validate-system-health" "${TEMP_DIR}/validate-system-health.zip"

echo ""

# Step 4: Verify deployments
echo -e "${YELLOW}Step 4: Verifying Deployments...${NC}\n"

verify_function() {
    local function_name="${PROJECT_NAME}-$1"

    FUNC_INFO=$(aws lambda get-function \
        --function-name "$function_name" \
        --region $REGION \
        --query 'Configuration.[FunctionName,Runtime,Handler,Timeout,MemorySize,LastModified]' \
        --output text)

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $function_name${NC}"
        echo "  $FUNC_INFO"
    else
        echo -e "${RED}✗ Failed to verify $function_name${NC}"
    fi
}

verify_function "get-target-instance"
verify_function "inject-failure"
verify_function "validate-system-health"

echo ""

# Cleanup
echo -e "${YELLOW}Cleaning up temporary files...${NC}"
rm -rf "$TEMP_DIR"
echo -e "${GREEN}✓ Cleanup complete${NC}\n"

# Step 5: Display outputs
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}================================${NC}\n"

echo -e "${YELLOW}Lambda Function ARNs:${NC}"

GET_TARGET_ARN=$(aws cloudformation describe-stacks \
    --stack-name $LAMBDA_STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`GetTargetInstanceFunctionArn`].OutputValue' \
    --output text)

INJECT_FAILURE_ARN=$(aws cloudformation describe-stacks \
    --stack-name $LAMBDA_STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`InjectFailureFunctionArn`].OutputValue' \
    --output text)

VALIDATE_HEALTH_ARN=$(aws cloudformation describe-stacks \
    --stack-name $LAMBDA_STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`ValidateHealthFunctionArn`].OutputValue' \
    --output text)

echo -e "  Get-Target-Instance: ${GREEN}${GET_TARGET_ARN}${NC}"
echo -e "  Inject-Failure: ${GREEN}${INJECT_FAILURE_ARN}${NC}"
echo -e "  Validate-Health: ${GREEN}${VALIDATE_HEALTH_ARN}${NC}\n"

echo -e "${YELLOW}Testing Commands:${NC}"
echo -e "  Test Get-Target: ${GREEN}./scripts/test-lambda-functions.sh get-target${NC}"
echo -e "  Test Inject-Failure: ${GREEN}./scripts/test-lambda-functions.sh inject-failure${NC}"
echo -e "  Test Validate-Health: ${GREEN}./scripts/test-lambda-functions.sh validate-health${NC}"
echo -e "  Test All: ${GREEN}./scripts/test-lambda-functions.sh all${NC}\n"

echo -e "${YELLOW}View Logs:${NC}"
echo -e "  Get-Target: ${GREEN}aws logs tail /aws/lambda/${PROJECT_NAME}-get-target-instance --follow${NC}"
echo -e "  Inject-Failure: ${GREEN}aws logs tail /aws/lambda/${PROJECT_NAME}-inject-failure --follow${NC}"
echo -e "  Validate-Health: ${GREEN}aws logs tail /aws/lambda/${PROJECT_NAME}-validate-system-health --follow${NC}\n"

echo -e "${GREEN}Week 2 Lambda functions deployed successfully!${NC}"
echo -e "${YELLOW}Next: Test individual functions before integrating with Step Functions${NC}\n"
