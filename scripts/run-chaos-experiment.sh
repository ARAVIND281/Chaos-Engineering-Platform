#!/bin/bash

# Manual chaos experiment execution script
# Week 3: Trigger Step Functions state machine manually

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_NAME="chaos-platform"
REGION="${AWS_REGION:-us-east-1}"
EXPERIMENT_ID="manual-$(date +%Y%m%d-%H%M%S)"

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Chaos Experiment Execution${NC}"
echo -e "${GREEN}Week 3 - Manual Trigger${NC}"
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

# Get infrastructure details
echo -e "${YELLOW}Retrieving infrastructure details...${NC}"

STATE_MACHINE_ARN=$(aws cloudformation describe-stacks \
    --stack-name ${PROJECT_NAME}-step-functions \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`StateMachineArn`].OutputValue' \
    --output text 2>/dev/null)

if [ -z "$STATE_MACHINE_ARN" ]; then
    echo -e "${RED}Error: Step Functions state machine not found${NC}"
    echo "Please deploy Step Functions first: ./scripts/deploy-step-functions.sh"
    exit 1
fi

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
    echo -e "${RED}Error: Target application not found${NC}"
    echo "Please deploy target application first: ./scripts/deploy.sh"
    exit 1
fi

echo -e "${GREEN}✓ Infrastructure details retrieved${NC}\n"

# Display experiment details
echo -e "${BLUE}═══════════════════════════════════${NC}"
echo -e "${BLUE}Chaos Experiment Details${NC}"
echo -e "${BLUE}═══════════════════════════════════${NC}\n"

echo -e "${YELLOW}Experiment ID:${NC} ${EXPERIMENT_ID}"
echo -e "${YELLOW}State Machine:${NC} ${STATE_MACHINE_ARN##*/}"
echo -e "${YELLOW}Target ASG:${NC} ${ASG_NAME}"
echo -e "${YELLOW}Target Group:${NC} ${TG_ARN##*/}"
echo -e "${YELLOW}Expected Healthy Hosts:${NC} 2\n"

# Confirmation prompt
echo -e "${YELLOW}⚠️  WARNING: This will terminate a random EC2 instance!${NC}"
echo -e "${YELLOW}The system should auto-recover, but brief service disruption may occur.${NC}\n"

read -p "Do you want to proceed? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo -e "${GREEN}Experiment cancelled.${NC}"
    exit 0
fi

echo ""

# Create input payload
PAYLOAD=$(cat <<EOF
{
  "experimentId": "${EXPERIMENT_ID}",
  "experimentStartTime": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "autoScalingGroupName": "${ASG_NAME}",
  "targetGroupArn": "${TG_ARN}",
  "loadBalancerArn": "${LB_ARN}",
  "expectedHealthyHosts": 2
}
EOF
)

echo -e "${YELLOW}Starting chaos experiment...${NC}\n"

# Start execution
EXECUTION_ARN=$(aws stepfunctions start-execution \
    --state-machine-arn "$STATE_MACHINE_ARN" \
    --name "$EXPERIMENT_ID" \
    --input "$PAYLOAD" \
    --region $REGION \
    --query 'executionArn' \
    --output text)

if [ -z "$EXECUTION_ARN" ]; then
    echo -e "${RED}Failed to start execution${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Chaos experiment started successfully!${NC}\n"

echo -e "${BLUE}═══════════════════════════════════${NC}"
echo -e "${BLUE}Execution Tracking${NC}"
echo -e "${BLUE}═══════════════════════════════════${NC}\n"

echo -e "${YELLOW}Execution ARN:${NC} ${EXECUTION_ARN}\n"

# Monitor execution
echo -e "${YELLOW}Monitoring execution (this will take ~3-4 minutes)...${NC}\n"

PREVIOUS_STATUS=""
START_TIME=$(date +%s)

while true; do
    # Get execution status
    EXEC_DETAILS=$(aws stepfunctions describe-execution \
        --execution-arn "$EXECUTION_ARN" \
        --region $REGION \
        --output json)

    STATUS=$(echo "$EXEC_DETAILS" | jq -r '.status')

    # Only print if status changed
    if [ "$STATUS" != "$PREVIOUS_STATUS" ]; then
        ELAPSED=$(($(date +%s) - START_TIME))
        echo -e "[${ELAPSED}s] Status: ${YELLOW}${STATUS}${NC}"
        PREVIOUS_STATUS="$STATUS"
    fi

    # Check if execution is complete
    if [ "$STATUS" == "SUCCEEDED" ] || [ "$STATUS" == "FAILED" ] || [ "$STATUS" == "TIMED_OUT" ] || [ "$STATUS" == "ABORTED" ]; then
        break
    fi

    sleep 5
done

echo ""

# Get final output
OUTPUT=$(echo "$EXEC_DETAILS" | jq -r '.output // "No output"')

# Display results
echo -e "${BLUE}═══════════════════════════════════${NC}"
echo -e "${BLUE}Experiment Results${NC}"
echo -e "${BLUE}═══════════════════════════════════${NC}\n"

if [ "$STATUS" == "SUCCEEDED" ]; then
    echo -e "${GREEN}✓ EXPERIMENT SUCCEEDED${NC}\n"

    RESULT_STATUS=$(echo "$OUTPUT" | jq -r '.status // "UNKNOWN"')
    MESSAGE=$(echo "$OUTPUT" | jq -r '.message // "No message"')
    INSTANCE_ID=$(echo "$OUTPUT" | jq -r '.targetInstance.instanceId // "N/A"')
    AZ=$(echo "$OUTPUT" | jq -r '.targetInstance.availabilityZone // "N/A"')

    echo -e "${YELLOW}Result:${NC} ${RESULT_STATUS}"
    echo -e "${YELLOW}Message:${NC} ${MESSAGE}"
    echo -e "${YELLOW}Terminated Instance:${NC} ${INSTANCE_ID} (${AZ})\n"

    echo -e "${YELLOW}Health Checks:${NC}"
    echo "$OUTPUT" | jq -r '.healthChecks.preExperiment.summary // "N/A"' | sed 's/^/  Pre:  /'
    echo "$OUTPUT" | jq -r '.healthChecks.postExperiment.summary // "N/A"' | sed 's/^/  Post: /'
    echo ""

    echo -e "${GREEN}Conclusion: System demonstrated resilience${NC}\n"

else
    echo -e "${RED}✗ EXPERIMENT ${STATUS}${NC}\n"

    if [ "$OUTPUT" != "No output" ] && [ "$OUTPUT" != "null" ]; then
        REASON=$(echo "$OUTPUT" | jq -r '.reason // "Unknown"')
        MESSAGE=$(echo "$OUTPUT" | jq -r '.message // "No message"')

        echo -e "${YELLOW}Reason:${NC} ${REASON}"
        echo -e "${YELLOW}Message:${NC} ${MESSAGE}\n"
    fi
fi

# Show useful commands
echo -e "${YELLOW}View Execution in AWS Console:${NC}"
echo -e "  https://console.aws.amazon.com/states/home?region=${REGION}#/executions/details/${EXECUTION_ARN}\n"

echo -e "${YELLOW}View CloudWatch Logs:${NC}"
echo -e "  ${GREEN}aws logs tail /aws/vendedlogs/states/${PROJECT_NAME}-chaos-experiment --follow --region $REGION${NC}\n"

echo -e "${YELLOW}View Target Application:${NC}"
ALB_URL=$(aws cloudformation describe-stacks \
    --stack-name ${PROJECT_NAME}-target-app \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' \
    --output text 2>/dev/null)
echo -e "  ${GREEN}${ALB_URL}${NC}\n"

echo -e "${YELLOW}List Recent Executions:${NC}"
echo -e "  ${GREEN}aws stepfunctions list-executions --state-machine-arn ${STATE_MACHINE_ARN} --max-items 10 --region $REGION${NC}\n"

# Show execution history
echo -e "${YELLOW}Recent Execution History:${NC}"
aws stepfunctions list-executions \
    --state-machine-arn "$STATE_MACHINE_ARN" \
    --max-items 5 \
    --region $REGION \
    --query 'executions[*].[name,status,startDate]' \
    --output table

echo ""
echo -e "${GREEN}Chaos experiment execution complete!${NC}\n"
