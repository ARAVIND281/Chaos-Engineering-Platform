"""
Get Target Instance Lambda Function

Purpose: Select a random healthy EC2 instance from an Auto Scaling Group
Input: Auto Scaling Group name
Output: Instance ID of a randomly selected healthy instance

This function is part of the Chaos Engineering Platform and is responsible
for selecting a victim instance for chaos experiments.
"""

import json
import random
import boto3
import logging
from botocore.exceptions import ClientError

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
autoscaling = boto3.client('autoscaling')
ec2 = boto3.client('ec2')


def lambda_handler(event, context):
    """
    Main Lambda handler function

    Args:
        event: Lambda event object containing:
            - autoScalingGroupName: Name of the Auto Scaling Group
        context: Lambda context object

    Returns:
        dict: Response containing selected instance details
    """
    logger.info(f"Received event: {json.dumps(event)}")

    try:
        # Extract Auto Scaling Group name from event
        asg_name = event.get('autoScalingGroupName')

        if not asg_name:
            raise ValueError("Missing required parameter: autoScalingGroupName")

        logger.info(f"Selecting target instance from ASG: {asg_name}")

        # Get instances from Auto Scaling Group
        healthy_instances = get_healthy_instances(asg_name)

        if not healthy_instances:
            raise Exception(f"No healthy instances found in Auto Scaling Group: {asg_name}")

        # Select a random instance
        target_instance = random.choice(healthy_instances)

        # Get additional instance details
        instance_details = get_instance_details(target_instance['InstanceId'])

        # Prepare response
        response = {
            'statusCode': 200,
            'instanceId': target_instance['InstanceId'],
            'availabilityZone': target_instance['AvailabilityZone'],
            'healthStatus': target_instance['HealthStatus'],
            'lifecycleState': target_instance['LifecycleState'],
            'privateIpAddress': instance_details.get('PrivateIpAddress', 'N/A'),
            'instanceType': instance_details.get('InstanceType', 'N/A'),
            'launchTime': instance_details.get('LaunchTime', 'N/A').isoformat() if instance_details.get('LaunchTime') else 'N/A',
            'totalHealthyInstances': len(healthy_instances),
            'autoScalingGroupName': asg_name,
            'message': f"Selected instance {target_instance['InstanceId']} from {len(healthy_instances)} healthy instances"
        }

        logger.info(f"Successfully selected target instance: {json.dumps(response, default=str)}")

        return response

    except ValueError as e:
        logger.error(f"Validation error: {str(e)}")
        return {
            'statusCode': 400,
            'error': 'ValidationError',
            'message': str(e)
        }

    except ClientError as e:
        logger.error(f"AWS API error: {str(e)}")
        return {
            'statusCode': 500,
            'error': 'AWSError',
            'message': f"AWS API error: {e.response['Error']['Message']}"
        }

    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        return {
            'statusCode': 500,
            'error': 'InternalError',
            'message': str(e)
        }


def get_healthy_instances(asg_name):
    """
    Retrieve all healthy instances from an Auto Scaling Group

    Args:
        asg_name: Name of the Auto Scaling Group

    Returns:
        list: List of healthy instance dictionaries
    """
    try:
        response = autoscaling.describe_auto_scaling_groups(
            AutoScalingGroupNames=[asg_name]
        )

        if not response['AutoScalingGroups']:
            raise Exception(f"Auto Scaling Group not found: {asg_name}")

        asg = response['AutoScalingGroups'][0]
        instances = asg.get('Instances', [])

        logger.info(f"Found {len(instances)} total instances in ASG")

        # Filter for healthy instances that are InService
        healthy_instances = [
            instance for instance in instances
            if instance['HealthStatus'] == 'Healthy'
            and instance['LifecycleState'] == 'InService'
        ]

        # Additional safety check: Only select instances tagged as ChaosTarget
        filtered_instances = []
        for instance in healthy_instances:
            if is_chaos_target(instance['InstanceId']):
                filtered_instances.append(instance)
            else:
                logger.warning(f"Instance {instance['InstanceId']} is not tagged as ChaosTarget, skipping")

        logger.info(f"Found {len(filtered_instances)} healthy instances eligible for chaos experiments")

        return filtered_instances

    except ClientError as e:
        logger.error(f"Error retrieving Auto Scaling Group: {str(e)}")
        raise


def is_chaos_target(instance_id):
    """
    Check if an instance is tagged as a chaos target

    Args:
        instance_id: EC2 instance ID

    Returns:
        bool: True if instance is tagged with ChaosTarget=true
    """
    try:
        response = ec2.describe_instances(InstanceIds=[instance_id])

        if not response['Reservations']:
            return False

        instance = response['Reservations'][0]['Instances'][0]
        tags = instance.get('Tags', [])

        # Check for ChaosTarget tag
        for tag in tags:
            if tag['Key'] == 'ChaosTarget' and tag['Value'].lower() == 'true':
                return True

        return False

    except ClientError as e:
        logger.error(f"Error checking instance tags: {str(e)}")
        return False


def get_instance_details(instance_id):
    """
    Get detailed information about an EC2 instance

    Args:
        instance_id: EC2 instance ID

    Returns:
        dict: Instance details
    """
    try:
        response = ec2.describe_instances(InstanceIds=[instance_id])

        if not response['Reservations']:
            return {}

        instance = response['Reservations'][0]['Instances'][0]

        return {
            'InstanceType': instance.get('InstanceType'),
            'PrivateIpAddress': instance.get('PrivateIpAddress'),
            'PublicIpAddress': instance.get('PublicIpAddress'),
            'LaunchTime': instance.get('LaunchTime'),
            'State': instance.get('State', {}).get('Name'),
            'SubnetId': instance.get('SubnetId'),
            'VpcId': instance.get('VpcId')
        }

    except ClientError as e:
        logger.error(f"Error retrieving instance details: {str(e)}")
        return {}
