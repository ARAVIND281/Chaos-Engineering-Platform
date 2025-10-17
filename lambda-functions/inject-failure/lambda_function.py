"""
Inject Failure Lambda Function

Purpose: Terminate a specified EC2 instance to inject chaos into the system
Input: Instance ID
Output: Termination status and details

This function is part of the Chaos Engineering Platform and is responsible
for safely terminating EC2 instances that are tagged as chaos targets.
"""

import json
import boto3
import logging
from datetime import datetime
from botocore.exceptions import ClientError

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
ec2 = boto3.client('ec2')


def lambda_handler(event, context):
    """
    Main Lambda handler function

    Args:
        event: Lambda event object containing:
            - instanceId: EC2 instance ID to terminate
            - dryRun: (optional) If true, only validate without terminating
        context: Lambda context object

    Returns:
        dict: Response containing termination status and details
    """
    logger.info(f"Received event: {json.dumps(event)}")

    try:
        # Extract instance ID from event
        instance_id = event.get('instanceId')
        dry_run = event.get('dryRun', False)

        if not instance_id:
            raise ValueError("Missing required parameter: instanceId")

        logger.info(f"Processing termination request for instance: {instance_id}")

        # Safety check: Verify instance is tagged as ChaosTarget
        if not is_chaos_target(instance_id):
            raise Exception(
                f"Instance {instance_id} is not tagged as ChaosTarget=true. "
                "Refusing to terminate for safety reasons."
            )

        # Get instance details before termination
        instance_details = get_instance_details(instance_id)

        if not instance_details:
            raise Exception(f"Instance {instance_id} not found or not accessible")

        current_state = instance_details.get('State', 'unknown')
        logger.info(f"Current instance state: {current_state}")

        # Check if instance is already terminated or terminating
        if current_state in ['terminated', 'terminating']:
            return {
                'statusCode': 200,
                'instanceId': instance_id,
                'action': 'skipped',
                'previousState': current_state,
                'currentState': current_state,
                'message': f"Instance {instance_id} is already {current_state}",
                'timestamp': datetime.utcnow().isoformat()
            }

        # Dry run mode - validate only, don't terminate
        if dry_run:
            logger.info(f"Dry run mode: Would terminate instance {instance_id}")
            return {
                'statusCode': 200,
                'instanceId': instance_id,
                'action': 'validated',
                'dryRun': True,
                'previousState': current_state,
                'message': f"Validation successful. Instance {instance_id} is eligible for termination",
                'instanceDetails': instance_details,
                'timestamp': datetime.utcnow().isoformat()
            }

        # Terminate the instance
        logger.warning(f"⚠️  TERMINATING INSTANCE: {instance_id}")

        termination_response = terminate_instance(instance_id)

        new_state = termination_response.get('CurrentState', {}).get('Name', 'unknown')

        # Prepare response
        response = {
            'statusCode': 200,
            'instanceId': instance_id,
            'action': 'terminated',
            'previousState': current_state,
            'currentState': new_state,
            'availabilityZone': instance_details.get('AvailabilityZone', 'N/A'),
            'instanceType': instance_details.get('InstanceType', 'N/A'),
            'privateIpAddress': instance_details.get('PrivateIpAddress', 'N/A'),
            'message': f"Successfully initiated termination of instance {instance_id}",
            'timestamp': datetime.utcnow().isoformat(),
            'chaosExperiment': True
        }

        logger.info(f"Termination successful: {json.dumps(response, default=str)}")

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
        error_code = e.response['Error']['Code']
        error_message = e.response['Error']['Message']

        logger.error(f"AWS API error ({error_code}): {error_message}")

        return {
            'statusCode': 500,
            'error': 'AWSError',
            'errorCode': error_code,
            'message': f"AWS API error: {error_message}",
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


def is_chaos_target(instance_id):
    """
    Verify that an instance is tagged as a chaos target

    This is a critical safety check to prevent accidental termination
    of instances that are not part of chaos experiments.

    Args:
        instance_id: EC2 instance ID

    Returns:
        bool: True if instance is tagged with ChaosTarget=true
    """
    try:
        response = ec2.describe_instances(InstanceIds=[instance_id])

        if not response['Reservations']:
            logger.error(f"Instance {instance_id} not found")
            return False

        instance = response['Reservations'][0]['Instances'][0]
        tags = instance.get('Tags', [])

        # Check for ChaosTarget tag
        for tag in tags:
            if tag['Key'] == 'ChaosTarget' and tag['Value'].lower() == 'true':
                logger.info(f"Instance {instance_id} is tagged as ChaosTarget=true")
                return True

        logger.warning(f"Instance {instance_id} is NOT tagged as ChaosTarget=true")
        return False

    except ClientError as e:
        logger.error(f"Error checking instance tags: {str(e)}")
        return False


def get_instance_details(instance_id):
    """
    Get detailed information about an EC2 instance before termination

    Args:
        instance_id: EC2 instance ID

    Returns:
        dict: Instance details including state, type, IP, AZ, etc.
    """
    try:
        response = ec2.describe_instances(InstanceIds=[instance_id])

        if not response['Reservations']:
            return {}

        instance = response['Reservations'][0]['Instances'][0]

        return {
            'InstanceId': instance.get('InstanceId'),
            'InstanceType': instance.get('InstanceType'),
            'PrivateIpAddress': instance.get('PrivateIpAddress'),
            'PublicIpAddress': instance.get('PublicIpAddress'),
            'State': instance.get('State', {}).get('Name'),
            'AvailabilityZone': instance.get('Placement', {}).get('AvailabilityZone'),
            'LaunchTime': instance.get('LaunchTime').isoformat() if instance.get('LaunchTime') else 'N/A',
            'SubnetId': instance.get('SubnetId'),
            'VpcId': instance.get('VpcId'),
            'Tags': instance.get('Tags', [])
        }

    except ClientError as e:
        logger.error(f"Error retrieving instance details: {str(e)}")
        return {}


def terminate_instance(instance_id):
    """
    Terminate an EC2 instance

    Args:
        instance_id: EC2 instance ID

    Returns:
        dict: Termination response from EC2 API
    """
    try:
        logger.info(f"Calling EC2 TerminateInstances API for {instance_id}")

        response = ec2.terminate_instances(
            InstanceIds=[instance_id]
        )

        if response['TerminatingInstances']:
            terminating_instance = response['TerminatingInstances'][0]
            logger.info(
                f"Instance {instance_id} state change: "
                f"{terminating_instance['PreviousState']['Name']} -> "
                f"{terminating_instance['CurrentState']['Name']}"
            )
            return terminating_instance

        return {}

    except ClientError as e:
        logger.error(f"Failed to terminate instance {instance_id}: {str(e)}")
        raise
