#!/bin/bash

# Verification script for Chaos Engineering Platform
# Week 1: Verify Target Application high availability

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_NAME="chaos-platform"
REGION="${AWS_REGION:-us-east-1}"

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}High Availability Verification${NC}"
echo -e "${GREEN}================================${NC}\n"

# Get stack outputs
APP_STACK_NAME="${PROJECT_NAME}-target-app"

if ! aws cloudformation describe-stacks --stack-name $APP_STACK_NAME --region $REGION &> /dev/null; then
    echo -e "${RED}Error: Stack $APP_STACK_NAME not found${NC}"
    echo "Please run deploy.sh first"
    exit 1
fi

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

TG_ARN=$(aws cloudformation describe-stacks \
    --stack-name $APP_STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`TargetGroupArn`].OutputValue' \
    --output text)

echo -e "${YELLOW}Application Details:${NC}"
echo -e "Load Balancer: ${GREEN}${ALB_URL}${NC}"
echo -e "Auto Scaling Group: ${GREEN}${ASG_NAME}${NC}\n"

# Test 1: Check ASG instances
echo -e "${YELLOW}Test 1: Checking Auto Scaling Group...${NC}"

ASG_INFO=$(aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names $ASG_NAME \
    --region $REGION)

MIN_SIZE=$(echo $ASG_INFO | jq -r '.AutoScalingGroups[0].MinSize')
MAX_SIZE=$(echo $ASG_INFO | jq -r '.AutoScalingGroups[0].MaxSize')
DESIRED=$(echo $ASG_INFO | jq -r '.AutoScalingGroups[0].DesiredCapacity')
CURRENT=$(echo $ASG_INFO | jq -r '.AutoScalingGroups[0].Instances | length')

echo -e "  Min Size: $MIN_SIZE"
echo -e "  Max Size: $MAX_SIZE"
echo -e "  Desired: $DESIRED"
echo -e "  Current: $CURRENT"

if [ "$CURRENT" -ge "$MIN_SIZE" ]; then
    echo -e "${GREEN}✓ ASG has sufficient instances${NC}\n"
else
    echo -e "${RED}✗ ASG does not have enough instances${NC}\n"
fi

# Test 2: Check instance health
echo -e "${YELLOW}Test 2: Checking instance health...${NC}"

INSTANCES=$(echo $ASG_INFO | jq -r '.AutoScalingGroups[0].Instances[] | .InstanceId')
echo "$INSTANCES" | while read INSTANCE_ID; do
    if [ -n "$INSTANCE_ID" ]; then
        HEALTH=$(echo $ASG_INFO | jq -r ".AutoScalingGroups[0].Instances[] | select(.InstanceId==\"$INSTANCE_ID\") | .HealthStatus")
        LIFECYCLE=$(echo $ASG_INFO | jq -r ".AutoScalingGroups[0].Instances[] | select(.InstanceId==\"$INSTANCE_ID\") | .LifecycleState")
        AZ=$(echo $ASG_INFO | jq -r ".AutoScalingGroups[0].Instances[] | select(.InstanceId==\"$INSTANCE_ID\") | .AvailabilityZone")

        if [ "$HEALTH" == "Healthy" ] && [ "$LIFECYCLE" == "InService" ]; then
            echo -e "  ${GREEN}✓${NC} $INSTANCE_ID - $HEALTH - $LIFECYCLE - $AZ"
        else
            echo -e "  ${YELLOW}⚠${NC} $INSTANCE_ID - $HEALTH - $LIFECYCLE - $AZ"
        fi
    fi
done
echo ""

# Test 3: Check Target Group health
echo -e "${YELLOW}Test 3: Checking Target Group health...${NC}"

TG_HEALTH=$(aws elbv2 describe-target-health \
    --target-group-arn $TG_ARN \
    --region $REGION)

HEALTHY_COUNT=$(echo $TG_HEALTH | jq '[.TargetHealthDescriptions[] | select(.TargetHealth.State=="healthy")] | length')
TOTAL_COUNT=$(echo $TG_HEALTH | jq '.TargetHealthDescriptions | length')

echo -e "  Healthy targets: $HEALTHY_COUNT / $TOTAL_COUNT"

echo $TG_HEALTH | jq -r '.TargetHealthDescriptions[] | "\(.Target.Id) - \(.TargetHealth.State) - \(.TargetHealth.Reason // "N/A")"' | while read LINE; do
    if [[ $LINE == *"healthy"* ]]; then
        echo -e "  ${GREEN}✓${NC} $LINE"
    else
        echo -e "  ${YELLOW}⚠${NC} $LINE"
    fi
done
echo ""

# Test 4: Check application availability
echo -e "${YELLOW}Test 4: Testing application availability...${NC}"

for i in {1..5}; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" $ALB_URL)
    INSTANCE_ID=$(curl -s $ALB_URL | grep -oP 'Instance ID:</strong> \K[^<]+' || echo "Unknown")

    if [ "$HTTP_CODE" == "200" ]; then
        echo -e "  ${GREEN}✓${NC} Request $i: HTTP $HTTP_CODE - Instance: $INSTANCE_ID"
    else
        echo -e "  ${RED}✗${NC} Request $i: HTTP $HTTP_CODE"
    fi
    sleep 1
done
echo ""

# Test 5: Check multi-AZ distribution
echo -e "${YELLOW}Test 5: Checking Multi-AZ distribution...${NC}"

AZS=$(echo $ASG_INFO | jq -r '.AutoScalingGroups[0].Instances[].AvailabilityZone' | sort | uniq)
AZ_COUNT=$(echo "$AZS" | wc -l)

echo "$AZS" | while read AZ; do
    COUNT=$(echo $ASG_INFO | jq -r ".AutoScalingGroups[0].Instances[] | select(.AvailabilityZone==\"$AZ\") | .InstanceId" | wc -l)
    echo -e "  $AZ: $COUNT instance(s)"
done

if [ "$AZ_COUNT" -ge 2 ]; then
    echo -e "${GREEN}✓ Instances distributed across multiple AZs${NC}\n"
else
    echo -e "${YELLOW}⚠ Instances not distributed across multiple AZs${NC}\n"
fi

# Summary
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Verification Summary${NC}"
echo -e "${GREEN}================================${NC}\n"

if [ "$HEALTHY_COUNT" -ge "$MIN_SIZE" ] && [ "$AZ_COUNT" -ge 2 ]; then
    echo -e "${GREEN}✓ Target Application is highly available${NC}"
    echo -e "${GREEN}✓ Ready for chaos experiments${NC}\n"
else
    echo -e "${YELLOW}⚠ Some issues detected. Please review the output above.${NC}\n"
fi

echo -e "${YELLOW}Next Steps:${NC}"
echo -e "1. Monitor the application: ${GREEN}$ALB_URL${NC}"
echo -e "2. Review CloudWatch metrics in AWS Console"
echo -e "3. Proceed to Week 2: Build Chaos Lambda Functions\n"
