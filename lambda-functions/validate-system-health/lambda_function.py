"""
Validate System Health Lambda Function

Purpose: Query CloudWatch metrics to determine if the target application is healthy
Input: Load Balancer ARN, Target Group ARN, expected healthy host count
Output: Health status (pass/fail) with detailed metrics

This function is part of the Chaos Engineering Platform and validates that
the application remained healthy (or recovered) after a chaos experiment.
"""

import json
import boto3
import logging
from datetime import datetime, timedelta
from botocore.exceptions import ClientError

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
cloudwatch = boto3.client('cloudwatch')
elbv2 = boto3.client('elbv2')

# Health check thresholds
HEALTHY_HOST_THRESHOLD = 2  # Minimum number of healthy hosts
MAX_5XX_ERRORS = 10  # Maximum acceptable 5XX errors
MAX_RESPONSE_TIME_MS = 2000  # Maximum acceptable response time in milliseconds
METRIC_PERIOD_SECONDS = 60  # CloudWatch metric period


def lambda_handler(event, context):
    """
    Main Lambda handler function

    Args:
        event: Lambda event object containing:
            - targetGroupArn: ARN of the target group
            - loadBalancerArn: ARN of the load balancer (optional)
            - expectedHealthyHosts: Expected number of healthy hosts (optional)
            - checkType: 'pre' or 'post' experiment (optional)
        context: Lambda context object

    Returns:
        dict: Health validation results with pass/fail status
    """
    logger.info(f"Received event: {json.dumps(event)}")

    try:
        # Extract parameters from event
        target_group_arn = event.get('targetGroupArn')
        load_balancer_arn = event.get('loadBalancerArn')
        expected_healthy = event.get('expectedHealthyHosts', HEALTHY_HOST_THRESHOLD)
        check_type = event.get('checkType', 'unknown')

        if not target_group_arn:
            raise ValueError("Missing required parameter: targetGroupArn")

        logger.info(f"Validating system health ({check_type} experiment)")
        logger.info(f"Target Group: {target_group_arn}")

        # Get target group name and load balancer details
        tg_name = extract_resource_name(target_group_arn, 'targetgroup')
        lb_name = None

        if load_balancer_arn:
            lb_name = extract_resource_name(load_balancer_arn, 'loadbalancer/app')

        # Collect health metrics
        metrics = {}

        # 1. Check Target Group health
        target_health = check_target_health(target_group_arn)
        metrics['targetHealth'] = target_health

        # 2. Get CloudWatch metrics
        if tg_name and lb_name:
            metrics['healthyHostCount'] = get_healthy_host_count(tg_name, lb_name)
            metrics['unhealthyHostCount'] = get_unhealthy_host_count(tg_name, lb_name)
            metrics['target5xxErrors'] = get_target_5xx_errors(lb_name)
            metrics['responseTime'] = get_response_time(lb_name)
            metrics['requestCount'] = get_request_count(lb_name)

        # 3. Evaluate overall health
        health_result = evaluate_health(metrics, expected_healthy)

        # Prepare response
        response = {
            'statusCode': 200,
            'checkType': check_type,
            'healthStatus': 'PASS' if health_result['healthy'] else 'FAIL',
            'healthy': health_result['healthy'],
            'timestamp': datetime.utcnow().isoformat(),
            'metrics': metrics,
            'evaluation': health_result['evaluation'],
            'summary': health_result['summary']
        }

        logger.info(f"Health validation result: {response['healthStatus']}")
        logger.info(f"Summary: {response['summary']}")

        return response

    except ValueError as e:
        logger.error(f"Validation error: {str(e)}")
        return {
            'statusCode': 400,
            'error': 'ValidationError',
            'message': str(e),
            'timestamp': datetime.utcnow().isoformat()
        }

    except ClientError as e:
        logger.error(f"AWS API error: {str(e)}")
        return {
            'statusCode': 500,
            'error': 'AWSError',
            'message': f"AWS API error: {e.response['Error']['Message']}",
            'timestamp': datetime.utcnow().isoformat()
        }

    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        return {
            'statusCode': 500,
            'error': 'InternalError',
            'message': str(e),
            'timestamp': datetime.utcnow().isoformat()
        }


def check_target_health(target_group_arn):
    """
    Check the health of targets in the target group using ELBv2 API

    Args:
        target_group_arn: ARN of the target group

    Returns:
        dict: Target health statistics
    """
    try:
        response = elbv2.describe_target_health(TargetGroupArn=target_group_arn)

        targets = response.get('TargetHealthDescriptions', [])

        healthy = sum(1 for t in targets if t['TargetHealth']['State'] == 'healthy')
        unhealthy = sum(1 for t in targets if t['TargetHealth']['State'] == 'unhealthy')
        draining = sum(1 for t in targets if t['TargetHealth']['State'] == 'draining')
        unused = sum(1 for t in targets if t['TargetHealth']['State'] == 'unused')

        total = len(targets)

        logger.info(f"Target health: {healthy} healthy, {unhealthy} unhealthy, {draining} draining, {unused} unused (total: {total})")

        return {
            'healthy': healthy,
            'unhealthy': unhealthy,
            'draining': draining,
            'unused': unused,
            'total': total,
            'details': [
                {
                    'targetId': t['Target']['Id'],
                    'state': t['TargetHealth']['State'],
                    'reason': t['TargetHealth'].get('Reason', 'N/A')
                }
                for t in targets
            ]
        }

    except ClientError as e:
        logger.error(f"Error checking target health: {str(e)}")
        return {'error': str(e)}


def get_healthy_host_count(target_group_name, load_balancer_name):
    """Get HealthyHostCount metric from CloudWatch"""
    return get_cloudwatch_metric(
        namespace='AWS/ApplicationELB',
        metric_name='HealthyHostCount',
        dimensions=[
            {'Name': 'TargetGroup', 'Value': target_group_name},
            {'Name': 'LoadBalancer', 'Value': load_balancer_name}
        ],
        statistic='Average'
    )


def get_unhealthy_host_count(target_group_name, load_balancer_name):
    """Get UnHealthyHostCount metric from CloudWatch"""
    return get_cloudwatch_metric(
        namespace='AWS/ApplicationELB',
        metric_name='UnHealthyHostCount',
        dimensions=[
            {'Name': 'TargetGroup', 'Value': target_group_name},
            {'Name': 'LoadBalancer', 'Value': load_balancer_name}
        ],
        statistic='Average'
    )


def get_target_5xx_errors(load_balancer_name):
    """Get HTTPCode_Target_5XX_Count metric from CloudWatch"""
    return get_cloudwatch_metric(
        namespace='AWS/ApplicationELB',
        metric_name='HTTPCode_Target_5XX_Count',
        dimensions=[
            {'Name': 'LoadBalancer', 'Value': load_balancer_name}
        ],
        statistic='Sum'
    )


def get_response_time(load_balancer_name):
    """Get TargetResponseTime metric from CloudWatch"""
    return get_cloudwatch_metric(
        namespace='AWS/ApplicationELB',
        metric_name='TargetResponseTime',
        dimensions=[
            {'Name': 'LoadBalancer', 'Value': load_balancer_name}
        ],
        statistic='Average'
    )


def get_request_count(load_balancer_name):
    """Get RequestCount metric from CloudWatch"""
    return get_cloudwatch_metric(
        namespace='AWS/ApplicationELB',
        metric_name='RequestCount',
        dimensions=[
            {'Name': 'LoadBalancer', 'Value': load_balancer_name}
        ],
        statistic='Sum'
    )


def get_cloudwatch_metric(namespace, metric_name, dimensions, statistic):
    """
    Generic function to retrieve a CloudWatch metric

    Args:
        namespace: CloudWatch namespace
        metric_name: Name of the metric
        dimensions: List of dimension dictionaries
        statistic: Statistic type (Average, Sum, etc.)

    Returns:
        dict: Metric data including value and timestamp
    """
    try:
        end_time = datetime.utcnow()
        start_time = end_time - timedelta(minutes=5)  # Look back 5 minutes

        logger.info(f"Querying metric: {metric_name} from {namespace}")

        response = cloudwatch.get_metric_statistics(
            Namespace=namespace,
            MetricName=metric_name,
            Dimensions=dimensions,
            StartTime=start_time,
            EndTime=end_time,
            Period=METRIC_PERIOD_SECONDS,
            Statistics=[statistic]
        )

        datapoints = response.get('Datapoints', [])

        if not datapoints:
            logger.warning(f"No datapoints found for metric {metric_name}")
            return {
                'value': None,
                'timestamp': None,
                'available': False
            }

        # Get the most recent datapoint
        latest = sorted(datapoints, key=lambda x: x['Timestamp'], reverse=True)[0]

        value = latest.get(statistic, 0)

        logger.info(f"Metric {metric_name}: {value}")

        return {
            'value': value,
            'timestamp': latest['Timestamp'].isoformat(),
            'available': True,
            'unit': latest.get('Unit', 'None')
        }

    except ClientError as e:
        logger.error(f"Error retrieving metric {metric_name}: {str(e)}")
        return {
            'value': None,
            'error': str(e),
            'available': False
        }


def evaluate_health(metrics, expected_healthy):
    """
    Evaluate overall system health based on collected metrics

    Args:
        metrics: Dictionary of collected metrics
        expected_healthy: Expected number of healthy hosts

    Returns:
        dict: Evaluation results with healthy status and details
    """
    evaluation = []
    is_healthy = True
    issues = []

    # Check 1: Target health from ELBv2 API
    target_health = metrics.get('targetHealth', {})
    healthy_count = target_health.get('healthy', 0)
    unhealthy_count = target_health.get('unhealthy', 0)

    if healthy_count >= expected_healthy:
        evaluation.append({
            'check': 'Target Health',
            'status': 'PASS',
            'details': f"{healthy_count} healthy targets (expected >= {expected_healthy})"
        })
    else:
        evaluation.append({
            'check': 'Target Health',
            'status': 'FAIL',
            'details': f"Only {healthy_count} healthy targets (expected >= {expected_healthy})"
        })
        is_healthy = False
        issues.append(f"Insufficient healthy targets: {healthy_count}/{expected_healthy}")

    if unhealthy_count > 0:
        issues.append(f"{unhealthy_count} unhealthy targets detected")

    # Check 2: CloudWatch HealthyHostCount metric
    healthy_host_metric = metrics.get('healthyHostCount', {})
    if healthy_host_metric.get('available'):
        metric_value = healthy_host_metric.get('value', 0)
        if metric_value >= expected_healthy:
            evaluation.append({
                'check': 'HealthyHostCount Metric',
                'status': 'PASS',
                'details': f"CloudWatch reports {metric_value} healthy hosts"
            })
        else:
            evaluation.append({
                'check': 'HealthyHostCount Metric',
                'status': 'WARN',
                'details': f"CloudWatch reports {metric_value} healthy hosts (expected >= {expected_healthy})"
            })

    # Check 3: 5XX errors
    errors_5xx = metrics.get('target5xxErrors', {})
    if errors_5xx.get('available'):
        error_count = errors_5xx.get('value', 0)
        if error_count <= MAX_5XX_ERRORS:
            evaluation.append({
                'check': '5XX Errors',
                'status': 'PASS',
                'details': f"{error_count} errors (threshold: {MAX_5XX_ERRORS})"
            })
        else:
            evaluation.append({
                'check': '5XX Errors',
                'status': 'FAIL',
                'details': f"{error_count} errors exceeds threshold of {MAX_5XX_ERRORS}"
            })
            is_healthy = False
            issues.append(f"High error rate: {error_count} 5XX errors")

    # Check 4: Response time
    response_time = metrics.get('responseTime', {})
    if response_time.get('available'):
        rt_value = response_time.get('value', 0) * 1000  # Convert to ms
        if rt_value <= MAX_RESPONSE_TIME_MS:
            evaluation.append({
                'check': 'Response Time',
                'status': 'PASS',
                'details': f"{rt_value:.2f}ms (threshold: {MAX_RESPONSE_TIME_MS}ms)"
            })
        else:
            evaluation.append({
                'check': 'Response Time',
                'status': 'WARN',
                'details': f"{rt_value:.2f}ms exceeds threshold of {MAX_RESPONSE_TIME_MS}ms"
            })
            issues.append(f"High response time: {rt_value:.2f}ms")

    # Generate summary
    if is_healthy:
        summary = f"System is HEALTHY: {healthy_count} targets healthy, all checks passed"
    else:
        summary = f"System is UNHEALTHY: {', '.join(issues)}"

    return {
        'healthy': is_healthy,
        'evaluation': evaluation,
        'summary': summary,
        'issues': issues
    }


def extract_resource_name(arn, resource_type):
    """
    Extract resource name from ARN

    Args:
        arn: AWS Resource ARN
        resource_type: Type of resource (e.g., 'targetgroup', 'loadbalancer/app')

    Returns:
        str: Resource name
    """
    try:
        # ARN format: arn:aws:elasticloadbalancing:region:account-id:targetgroup/name/id
        parts = arn.split(':')
        if len(parts) >= 6:
            resource_part = parts[5]
            # Remove the resource type prefix
            if resource_type in resource_part:
                return resource_part.split(resource_type + '/', 1)[1] if resource_type + '/' in resource_part else resource_part
            return resource_part
        return None
    except Exception as e:
        logger.error(f"Error extracting resource name from ARN: {str(e)}")
        return None
