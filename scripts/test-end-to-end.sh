#!/bin/bash

# End-to-End Testing Script for Chaos Engineering Platform
# Week 4: Comprehensive validation of entire platform

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

PROJECT_NAME="chaos-platform"
REGION="${AWS_REGION:-us-east-1}"
TEST_RESULTS_FILE="/tmp/chaos-platform-test-results.txt"

echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║    Chaos Engineering Platform - E2E Testing Suite     ║${NC}"
echo -e "${CYAN}║                      Week 4                            ║${NC}"
echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}\n"

# Initialize results
> $TEST_RESULTS_FILE
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Test result tracking
log_test_result() {
    local test_name=$1
    local result=$2
    local details=$3

    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    if [ "$result" == "PASS" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "${GREEN}✓${NC} TEST $TESTS_TOTAL: $test_name - ${GREEN}PASS${NC}"
        echo "PASS: $test_name - $details" >> $TEST_RESULTS_FILE
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        echo -e "${RED}✗${NC} TEST $TESTS_TOTAL: $test_name - ${RED}FAIL${NC}"
        echo "FAIL: $test_name - $details" >> $TEST_RESULTS_FILE
    fi

    if [ -n "$details" ]; then
        echo -e "  ${YELLOW}$details${NC}"
    fi
    echo ""
}

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

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Phase 1: Infrastructure Validation${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}\n"

# Test 1: VPC Stack Exists
TEST_NAME="VPC Stack Deployment"
VPC_STACK="${PROJECT_NAME}-vpc"
if aws cloudformation describe-stacks --stack-name $VPC_STACK --region $REGION &> /dev/null; then
    VPC_STATUS=$(aws cloudformation describe-stacks --stack-name $VPC_STACK --region $REGION --query 'Stacks[0].StackStatus' --output text)
    if [[ $VPC_STATUS == *"COMPLETE"* ]]; then
        log_test_result "$TEST_NAME" "PASS" "Stack status: $VPC_STATUS"
    else
        log_test_result "$TEST_NAME" "FAIL" "Stack status: $VPC_STATUS"
    fi
else
    log_test_result "$TEST_NAME" "FAIL" "VPC stack not found"
fi

# Test 2: Target Application Stack Exists
TEST_NAME="Target Application Stack Deployment"
APP_STACK="${PROJECT_NAME}-target-app"
if aws cloudformation describe-stacks --stack-name $APP_STACK --region $REGION &> /dev/null; then
    APP_STATUS=$(aws cloudformation describe-stacks --stack-name $APP_STACK --region $REGION --query 'Stacks[0].StackStatus' --output text)
    if [[ $APP_STATUS == *"COMPLETE"* ]]; then
        log_test_result "$TEST_NAME" "PASS" "Stack status: $APP_STATUS"
    else
        log_test_result "$TEST_NAME" "FAIL" "Stack status: $APP_STATUS"
    fi
else
    log_test_result "$TEST_NAME" "FAIL" "Target application stack not found"
fi

# Test 3: Auto Scaling Group Health
TEST_NAME="Auto Scaling Group Configuration"
ASG_NAME=$(aws cloudformation describe-stacks --stack-name $APP_STACK --region $REGION --query 'Stacks[0].Outputs[?OutputKey==`AutoScalingGroupName`].OutputValue' --output text 2>/dev/null)
if [ -n "$ASG_NAME" ]; then
    ASG_INFO=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $ASG_NAME --region $REGION)
    DESIRED=$(echo $ASG_INFO | jq -r '.AutoScalingGroups[0].DesiredCapacity')
    IN_SERVICE=$(echo $ASG_INFO | jq -r '[.AutoScalingGroups[0].Instances[] | select(.LifecycleState=="InService")] | length')

    if [ "$IN_SERVICE" -ge 2 ]; then
        log_test_result "$TEST_NAME" "PASS" "$IN_SERVICE instances InService (Desired: $DESIRED)"
    else
        log_test_result "$TEST_NAME" "FAIL" "Only $IN_SERVICE instances InService (Expected: >= 2)"
    fi
else
    log_test_result "$TEST_NAME" "FAIL" "ASG not found"
fi

# Test 4: Load Balancer Health
TEST_NAME="Load Balancer Target Health"
TG_ARN=$(aws cloudformation describe-stacks --stack-name $APP_STACK --region $REGION --query 'Stacks[0].Outputs[?OutputKey==`TargetGroupArn`].OutputValue' --output text 2>/dev/null)
if [ -n "$TG_ARN" ]; then
    HEALTHY_COUNT=$(aws elbv2 describe-target-health --target-group-arn $TG_ARN --region $REGION --query 'TargetHealthDescriptions[?TargetHealth.State==`healthy`] | length(@)' --output text)

    if [ "$HEALTHY_COUNT" -ge 2 ]; then
        log_test_result "$TEST_NAME" "PASS" "$HEALTHY_COUNT healthy targets"
    else
        log_test_result "$TEST_NAME" "FAIL" "Only $HEALTHY_COUNT healthy targets (Expected: >= 2)"
    fi
else
    log_test_result "$TEST_NAME" "FAIL" "Target group not found"
fi

# Test 5: Application Accessibility
TEST_NAME="Application HTTP Accessibility"
ALB_URL=$(aws cloudformation describe-stacks --stack-name $APP_STACK --region $REGION --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerURL`].OutputValue' --output text 2>/dev/null)
if [ -n "$ALB_URL" ]; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" $ALB_URL || echo "000")
    if [ "$HTTP_CODE" == "200" ]; then
        log_test_result "$TEST_NAME" "PASS" "HTTP $HTTP_CODE - Application responding"
    else
        log_test_result "$TEST_NAME" "FAIL" "HTTP $HTTP_CODE - Application not responding"
    fi
else
    log_test_result "$TEST_NAME" "FAIL" "Load balancer URL not found"
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Phase 2: Lambda Functions Validation${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}\n"

# Test 6: Lambda Functions Deployed
TEST_NAME="Lambda Functions Deployment"
LAMBDA_STACK="${PROJECT_NAME}-lambda-functions"
if aws cloudformation describe-stacks --stack-name $LAMBDA_STACK --region $REGION &> /dev/null; then
    LAMBDA_STATUS=$(aws cloudformation describe-stacks --stack-name $LAMBDA_STACK --region $REGION --query 'Stacks[0].StackStatus' --output text)
    if [[ $LAMBDA_STATUS == *"COMPLETE"* ]]; then
        log_test_result "$TEST_NAME" "PASS" "Stack status: $LAMBDA_STATUS"
    else
        log_test_result "$TEST_NAME" "FAIL" "Stack status: $LAMBDA_STATUS"
    fi
else
    log_test_result "$TEST_NAME" "FAIL" "Lambda functions stack not found"
fi

# Test 7: Get-Target-Instance Function
TEST_NAME="Lambda: Get-Target-Instance Function"
GET_TARGET_FUNC="${PROJECT_NAME}-get-target-instance"
PAYLOAD='{"autoScalingGroupName":"'$ASG_NAME'"}'
RESPONSE=$(aws lambda invoke --function-name $GET_TARGET_FUNC --payload "$PAYLOAD" --region $REGION --cli-binary-format raw-in-base64-out /tmp/get-target-response.json --query 'StatusCode' --output text 2>/dev/null || echo "000")

if [ "$RESPONSE" == "200" ]; then
    INSTANCE_ID=$(cat /tmp/get-target-response.json | jq -r '.instanceId // empty')
    if [ -n "$INSTANCE_ID" ] && [ "$INSTANCE_ID" != "null" ]; then
        log_test_result "$TEST_NAME" "PASS" "Selected instance: $INSTANCE_ID"
    else
        log_test_result "$TEST_NAME" "FAIL" "No instance ID returned"
    fi
else
    log_test_result "$TEST_NAME" "FAIL" "Lambda invocation failed (Status: $RESPONSE)"
fi

# Test 8: Inject-Failure Function (Dry Run)
TEST_NAME="Lambda: Inject-Failure Function (Dry Run)"
INJECT_FUNC="${PROJECT_NAME}-inject-failure"
PAYLOAD='{"instanceId":"'$INSTANCE_ID'","dryRun":true}'
RESPONSE=$(aws lambda invoke --function-name $INJECT_FUNC --payload "$PAYLOAD" --region $REGION --cli-binary-format raw-in-base64-out /tmp/inject-response.json --query 'StatusCode' --output text 2>/dev/null || echo "000")

if [ "$RESPONSE" == "200" ]; then
    ACTION=$(cat /tmp/inject-response.json | jq -r '.action // empty')
    if [ "$ACTION" == "validated" ]; then
        log_test_result "$TEST_NAME" "PASS" "Dry run validation successful"
    else
        log_test_result "$TEST_NAME" "FAIL" "Action: $ACTION (Expected: validated)"
    fi
else
    log_test_result "$TEST_NAME" "FAIL" "Lambda invocation failed (Status: $RESPONSE)"
fi

# Test 9: Validate-System-Health Function
TEST_NAME="Lambda: Validate-System-Health Function"
VALIDATE_FUNC="${PROJECT_NAME}-validate-system-health"
LB_ARN=$(aws cloudformation describe-stacks --stack-name $APP_STACK --region $REGION --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerArn`].OutputValue' --output text 2>/dev/null)
PAYLOAD='{"targetGroupArn":"'$TG_ARN'","loadBalancerArn":"'$LB_ARN'","expectedHealthyHosts":2,"checkType":"test"}'
RESPONSE=$(aws lambda invoke --function-name $VALIDATE_FUNC --payload "$PAYLOAD" --region $REGION --cli-binary-format raw-in-base64-out /tmp/validate-response.json --query 'StatusCode' --output text 2>/dev/null || echo "000")

if [ "$RESPONSE" == "200" ]; then
    HEALTH_STATUS=$(cat /tmp/validate-response.json | jq -r '.healthStatus // empty')
    if [ "$HEALTH_STATUS" == "PASS" ]; then
        log_test_result "$TEST_NAME" "PASS" "Health status: PASS"
    else
        log_test_result "$TEST_NAME" "FAIL" "Health status: $HEALTH_STATUS"
    fi
else
    log_test_result "$TEST_NAME" "FAIL" "Lambda invocation failed (Status: $RESPONSE)"
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Phase 3: Step Functions Validation${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}\n"

# Test 10: Step Functions Stack Deployed
TEST_NAME="Step Functions Stack Deployment"
STEP_STACK="${PROJECT_NAME}-step-functions"
if aws cloudformation describe-stacks --stack-name $STEP_STACK --region $REGION &> /dev/null; then
    STEP_STATUS=$(aws cloudformation describe-stacks --stack-name $STEP_STACK --region $REGION --query 'Stacks[0].StackStatus' --output text)
    if [[ $STEP_STATUS == *"COMPLETE"* ]]; then
        log_test_result "$TEST_NAME" "PASS" "Stack status: $STEP_STATUS"
    else
        log_test_result "$TEST_NAME" "FAIL" "Stack status: $STEP_STATUS"
    fi
else
    log_test_result "$TEST_NAME" "FAIL" "Step Functions stack not found"
fi

# Test 11: State Machine Exists
TEST_NAME="Step Functions State Machine"
STATE_MACHINE_ARN=$(aws cloudformation describe-stacks --stack-name $STEP_STACK --region $REGION --query 'Stacks[0].Outputs[?OutputKey==`StateMachineArn`].OutputValue' --output text 2>/dev/null)
if [ -n "$STATE_MACHINE_ARN" ]; then
    STATE_MACHINE_STATUS=$(aws stepfunctions describe-state-machine --state-machine-arn $STATE_MACHINE_ARN --region $REGION --query 'status' --output text 2>/dev/null || echo "UNKNOWN")
    if [ "$STATE_MACHINE_STATUS" == "ACTIVE" ]; then
        log_test_result "$TEST_NAME" "PASS" "State machine is ACTIVE"
    else
        log_test_result "$TEST_NAME" "FAIL" "State machine status: $STATE_MACHINE_STATUS"
    fi
else
    log_test_result "$TEST_NAME" "FAIL" "State machine not found"
fi

# Test 12: IAM Permissions
TEST_NAME="Step Functions IAM Permissions"
ROLE_ARN=$(aws cloudformation describe-stacks --stack-name $STEP_STACK --region $REGION --query 'Stacks[0].Outputs[?OutputKey==`StepFunctionsRoleArn`].OutputValue' --output text 2>/dev/null)
if [ -n "$ROLE_ARN" ]; then
    ROLE_NAME="${ROLE_ARN##*/}"
    POLICIES=$(aws iam list-role-policies --role-name $ROLE_NAME --query 'PolicyNames | length(@)' --output text 2>/dev/null || echo "0")
    if [ "$POLICIES" -ge 1 ]; then
        log_test_result "$TEST_NAME" "PASS" "$POLICIES inline policies attached"
    else
        log_test_result "$TEST_NAME" "FAIL" "No policies found"
    fi
else
    log_test_result "$TEST_NAME" "FAIL" "IAM role not found"
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Phase 4: End-to-End Chaos Experiment${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}Running live chaos experiment (this will take ~4 minutes)...${NC}\n"

# Test 13: Execute Full Chaos Experiment
TEST_NAME="Full Chaos Experiment Execution"
EXPERIMENT_ID="e2e-test-$(date +%Y%m%d-%H%M%S)"
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

EXECUTION_ARN=$(aws stepfunctions start-execution \
    --state-machine-arn "$STATE_MACHINE_ARN" \
    --name "$EXPERIMENT_ID" \
    --input "$PAYLOAD" \
    --region $REGION \
    --query 'executionArn' \
    --output text 2>/dev/null || echo "")

if [ -n "$EXECUTION_ARN" ]; then
    echo -e "${YELLOW}Execution started: $EXPERIMENT_ID${NC}"
    echo -e "${YELLOW}Monitoring execution...${NC}\n"

    # Wait for execution to complete
    TIMEOUT=300  # 5 minutes
    ELAPSED=0
    while [ $ELAPSED -lt $TIMEOUT ]; do
        STATUS=$(aws stepfunctions describe-execution --execution-arn "$EXECUTION_ARN" --region $REGION --query 'status' --output text 2>/dev/null || echo "UNKNOWN")

        if [ "$STATUS" == "SUCCEEDED" ] || [ "$STATUS" == "FAILED" ] || [ "$STATUS" == "TIMED_OUT" ] || [ "$STATUS" == "ABORTED" ]; then
            break
        fi

        echo -ne "\r  Progress: ${ELAPSED}s - Status: $STATUS    "
        sleep 5
        ELAPSED=$((ELAPSED + 5))
    done
    echo ""

    if [ "$STATUS" == "SUCCEEDED" ]; then
        OUTPUT=$(aws stepfunctions describe-execution --execution-arn "$EXECUTION_ARN" --region $REGION --query 'output' --output text)
        RESULT_STATUS=$(echo "$OUTPUT" | jq -r '.status // "UNKNOWN"')

        if [ "$RESULT_STATUS" == "SUCCESS" ]; then
            log_test_result "$TEST_NAME" "PASS" "Experiment completed successfully - System is resilient"
        else
            log_test_result "$TEST_NAME" "FAIL" "Experiment completed but result: $RESULT_STATUS"
        fi
    else
        log_test_result "$TEST_NAME" "FAIL" "Execution status: $STATUS"
    fi
else
    log_test_result "$TEST_NAME" "FAIL" "Failed to start execution"
fi

# Test 14: System Recovery Verification
TEST_NAME="System Recovery After Chaos"
sleep 10  # Brief wait for metrics to update

FINAL_HEALTHY=$(aws elbv2 describe-target-health --target-group-arn $TG_ARN --region $REGION --query 'TargetHealthDescriptions[?TargetHealth.State==`healthy`] | length(@)' --output text)

if [ "$FINAL_HEALTHY" -ge 2 ]; then
    log_test_result "$TEST_NAME" "PASS" "$FINAL_HEALTHY healthy instances after experiment"
else
    log_test_result "$TEST_NAME" "FAIL" "Only $FINAL_HEALTHY healthy instances (Expected: >= 2)"
fi

# Cleanup temp files
rm -f /tmp/get-target-response.json /tmp/inject-response.json /tmp/validate-response.json

echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                    Test Summary                        ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${YELLOW}Total Tests:${NC} $TESTS_TOTAL"
echo -e "${GREEN}Passed:${NC} $TESTS_PASSED"
echo -e "${RED}Failed:${NC} $TESTS_FAILED"

PASS_RATE=$((TESTS_PASSED * 100 / TESTS_TOTAL))
echo -e "${YELLOW}Pass Rate:${NC} ${PASS_RATE}%\n"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          ALL TESTS PASSED - PLATFORM READY! ✓          ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}\n"
    EXIT_CODE=0
else
    echo -e "${RED}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║      SOME TESTS FAILED - REVIEW REQUIRED ✗             ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════╝${NC}\n"
    EXIT_CODE=1
fi

echo -e "${YELLOW}Detailed results saved to:${NC} $TEST_RESULTS_FILE"
echo -e "${YELLOW}View results:${NC} cat $TEST_RESULTS_FILE\n"

echo -e "${YELLOW}Useful Commands:${NC}"
echo -e "  View recent executions: ${GREEN}aws stepfunctions list-executions --state-machine-arn $STATE_MACHINE_ARN --max-items 5${NC}"
echo -e "  View logs: ${GREEN}aws logs tail /aws/vendedlogs/states/${PROJECT_NAME}-chaos-experiment --follow${NC}\n"

exit $EXIT_CODE
