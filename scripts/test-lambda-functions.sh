#!/bin/bash

# Testing script for Chaos Engineering Lambda Functions
# Week 2: Test all three Lambda functions individually

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_NAME="chaos-platform"
REGION="${AWS_REGION:-us-east-1}"
TEST_MODE="${1:-all}"

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Chaos Lambda Functions${NC}"
echo -e "${GREEN}Testing Script - Week 2${NC}"
echo -e "${GREEN}================================${NC}\n"

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

# Get Auto Scaling Group name from target application stack
echo -e "${YELLOW}Retrieving infrastructure details...${NC}"
ASG_NAME=$(aws cloudformation describe-stacks \
    --stack-name ${PROJECT_NAME}-target-app \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`AutoScalingGroupName`].OutputValue' \
    --output text 2>/dev/null)

TG_ARN=$(aws cloudformation describe-stacks \
    --stack-name ${PROJECT_NAME}-target-app \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`TargetGroupArn`].OutputValue' \
    --output text 2>/dev/null)

LB_ARN=$(aws cloudformation describe-stacks \
    --stack-name ${PROJECT_NAME}-target-app \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerArn`].OutputValue' \
    --output text 2>/dev/null)

if [ -z "$ASG_NAME" ] || [ -z "$TG_ARN" ]; then
    echo -e "${RED}Error: Target application stack not found${NC}"
    echo "Please deploy the target application first: ./scripts/deploy.sh"
    exit 1
fi

echo -e "${GREEN}✓ Infrastructure details retrieved${NC}"
echo -e "  ASG: $ASG_NAME"
echo -e "  Target Group: ${TG_ARN##*/}"
echo -e "  Load Balancer: ${LB_ARN##*/}\n"

# Test Get-Target-Instance Function
test_get_target() {
    echo -e "${BLUE}═══════════════════════════════════${NC}"
    echo -e "${BLUE}Testing: Get-Target-Instance${NC}"
    echo -e "${BLUE}═══════════════════════════════════${NC}\n"

    echo -e "${YELLOW}Creating test payload...${NC}"
    cat > /tmp/get-target-test.json <<EOF
{
  "autoScalingGroupName": "${ASG_NAME}"
}
EOF

    echo -e "${YELLOW}Invoking Lambda function...${NC}\n"

    RESPONSE=$(aws lambda invoke \
        --function-name ${PROJECT_NAME}-get-target-instance \
        --payload file:///tmp/get-target-test.json \
        --region $REGION \
        --cli-binary-format raw-in-base64-out \
        /tmp/get-target-response.json \
        --query 'StatusCode' \
        --output text)

    if [ "$RESPONSE" == "200" ]; then
        echo -e "${GREEN}✓ Lambda invocation successful (Status: 200)${NC}\n"

        echo -e "${YELLOW}Response:${NC}"
        cat /tmp/get-target-response.json | python3 -m json.tool

        # Extract instance ID for next tests
        INSTANCE_ID=$(cat /tmp/get-target-response.json | python3 -c "import sys, json; print(json.load(sys.stdin).get('instanceId', ''))")

        if [ -n "$INSTANCE_ID" ] && [ "$INSTANCE_ID" != "null" ]; then
            echo -e "\n${GREEN}✓ Selected instance: ${INSTANCE_ID}${NC}"
            echo "$INSTANCE_ID" > /tmp/chaos-test-instance-id.txt
        else
            echo -e "\n${YELLOW}⚠ No instance ID in response${NC}"
        fi
    else
        echo -e "${RED}✗ Lambda invocation failed (Status: $RESPONSE)${NC}"
        cat /tmp/get-target-response.json
    fi

    rm -f /tmp/get-target-test.json /tmp/get-target-response.json
    echo ""
}

# Test Inject-Failure Function (Dry Run)
test_inject_failure() {
    echo -e "${BLUE}═══════════════════════════════════${NC}"
    echo -e "${BLUE}Testing: Inject-Failure (Dry Run)${NC}"
    echo -e "${BLUE}═══════════════════════════════════${NC}\n"

    # Get instance ID from previous test or use a test value
    if [ -f /tmp/chaos-test-instance-id.txt ]; then
        TEST_INSTANCE=$(cat /tmp/chaos-test-instance-id.txt)
    else
        # Get first instance from ASG
        TEST_INSTANCE=$(aws autoscaling describe-auto-scaling-groups \
            --auto-scaling-group-names $ASG_NAME \
            --region $REGION \
            --query 'AutoScalingGroups[0].Instances[0].InstanceId' \
            --output text)
    fi

    if [ -z "$TEST_INSTANCE" ] || [ "$TEST_INSTANCE" == "None" ]; then
        echo -e "${RED}Error: No instance ID available for testing${NC}"
        return 1
    fi

    echo -e "${YELLOW}Creating test payload (DRY RUN MODE)...${NC}"
    echo -e "  Instance ID: ${TEST_INSTANCE}\n"

    cat > /tmp/inject-failure-test.json <<EOF
{
  "instanceId": "${TEST_INSTANCE}",
  "dryRun": true
}
EOF

    echo -e "${YELLOW}Invoking Lambda function...${NC}\n"

    RESPONSE=$(aws lambda invoke \
        --function-name ${PROJECT_NAME}-inject-failure \
        --payload file:///tmp/inject-failure-test.json \
        --region $REGION \
        --cli-binary-format raw-in-base64-out \
        /tmp/inject-failure-response.json \
        --query 'StatusCode' \
        --output text)

    if [ "$RESPONSE" == "200" ]; then
        echo -e "${GREEN}✓ Lambda invocation successful (Status: 200)${NC}\n"

        echo -e "${YELLOW}Response:${NC}"
        cat /tmp/inject-failure-response.json | python3 -m json.tool

        ACTION=$(cat /tmp/inject-failure-response.json | python3 -c "import sys, json; print(json.load(sys.stdin).get('action', ''))")

        if [ "$ACTION" == "validated" ]; then
            echo -e "\n${GREEN}✓ Validation successful - Instance is eligible for termination${NC}"
            echo -e "${YELLOW}Note: This was a DRY RUN - no actual termination occurred${NC}"
        fi
    else
        echo -e "${RED}✗ Lambda invocation failed (Status: $RESPONSE)${NC}"
        cat /tmp/inject-failure-response.json
    fi

    rm -f /tmp/inject-failure-test.json /tmp/inject-failure-response.json
    echo ""
}

# Test Validate-System-Health Function
test_validate_health() {
    echo -e "${BLUE}═══════════════════════════════════${NC}"
    echo -e "${BLUE}Testing: Validate-System-Health${NC}"
    echo -e "${BLUE}═══════════════════════════════════${NC}\n"

    echo -e "${YELLOW}Creating test payload...${NC}"
    cat > /tmp/validate-health-test.json <<EOF
{
  "targetGroupArn": "${TG_ARN}",
  "loadBalancerArn": "${LB_ARN}",
  "expectedHealthyHosts": 2,
  "checkType": "test"
}
EOF

    echo -e "${YELLOW}Invoking Lambda function...${NC}\n"

    RESPONSE=$(aws lambda invoke \
        --function-name ${PROJECT_NAME}-validate-system-health \
        --payload file:///tmp/validate-health-test.json \
        --region $REGION \
        --cli-binary-format raw-in-base64-out \
        /tmp/validate-health-response.json \
        --query 'StatusCode' \
        --output text)

    if [ "$RESPONSE" == "200" ]; then
        echo -e "${GREEN}✓ Lambda invocation successful (Status: 200)${NC}\n"

        echo -e "${YELLOW}Response:${NC}"
        cat /tmp/validate-health-response.json | python3 -m json.tool

        HEALTH_STATUS=$(cat /tmp/validate-health-response.json | python3 -c "import sys, json; print(json.load(sys.stdin).get('healthStatus', ''))")

        if [ "$HEALTH_STATUS" == "PASS" ]; then
            echo -e "\n${GREEN}✓ System health: PASS${NC}"
        elif [ "$HEALTH_STATUS" == "FAIL" ]; then
            echo -e "\n${YELLOW}⚠ System health: FAIL${NC}"
        fi
    else
        echo -e "${RED}✗ Lambda invocation failed (Status: $RESPONSE)${NC}"
        cat /tmp/validate-health-response.json
    fi

    rm -f /tmp/validate-health-test.json /tmp/validate-health-response.json
    echo ""
}

# Run tests based on mode
case "$TEST_MODE" in
    "get-target")
        test_get_target
        ;;
    "inject-failure")
        test_inject_failure
        ;;
    "validate-health")
        test_validate_health
        ;;
    "all")
        test_get_target
        echo -e "${YELLOW}Waiting 2 seconds before next test...${NC}\n"
        sleep 2

        test_inject_failure
        echo -e "${YELLOW}Waiting 2 seconds before next test...${NC}\n"
        sleep 2

        test_validate_health
        ;;
    *)
        echo -e "${RED}Error: Invalid test mode${NC}"
        echo "Usage: $0 [get-target|inject-failure|validate-health|all]"
        exit 1
        ;;
esac

# Cleanup
rm -f /tmp/chaos-test-instance-id.txt

# Summary
echo -e "${GREEN}═══════════════════════════════════${NC}"
echo -e "${GREEN}Testing Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════${NC}\n"

echo -e "${YELLOW}Next Steps:${NC}"
echo -e "  1. Review CloudWatch logs for detailed execution logs"
echo -e "  2. Verify IAM permissions are working correctly"
echo -e "  3. Proceed to Week 3: Step Functions integration\n"

echo -e "${YELLOW}View Logs:${NC}"
echo -e "  ${GREEN}aws logs tail /aws/lambda/${PROJECT_NAME}-get-target-instance --follow --region $REGION${NC}"
echo -e "  ${GREEN}aws logs tail /aws/lambda/${PROJECT_NAME}-inject-failure --follow --region $REGION${NC}"
echo -e "  ${GREEN}aws logs tail /aws/lambda/${PROJECT_NAME}-validate-system-health --follow --region $REGION${NC}\n"
