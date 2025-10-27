import {
  CloudWatchClient,
  GetMetricStatisticsCommand,
  Dimension,
  Statistic,
} from '@aws-sdk/client-cloudwatch';
import {
  ElasticLoadBalancingV2Client,
  DescribeTargetHealthCommand,
  DescribeLoadBalancersCommand,
} from '@aws-sdk/client-elastic-load-balancing-v2';
import {
  AutoScalingClient,
  DescribeAutoScalingGroupsCommand,
} from '@aws-sdk/client-auto-scaling';
import { AWS_CONFIG, getCloudWatchConfig } from '../config/aws.config';
import { SystemHealth } from '../types/api.types';

const cloudwatch = new CloudWatchClient(getCloudWatchConfig());
const elbv2 = new ElasticLoadBalancingV2Client(getCloudWatchConfig());
const autoscaling = new AutoScalingClient(getCloudWatchConfig());

// Get system health status
export const getSystemHealth = async (): Promise<SystemHealth> => {
  try {
    // Get Auto Scaling Group information
    const asgCommand = new DescribeAutoScalingGroupsCommand({
      AutoScalingGroupNames: [AWS_CONFIG.autoScaling.targetAsgName],
    });
    const asgResponse = await autoscaling.send(asgCommand);

    const asg = asgResponse.AutoScalingGroups?.[0];
    const targetInstanceCount = asg?.DesiredCapacity || 0;
    const instances = asg?.Instances || [];
    const healthyInstanceCount = instances.filter(
      (i) => i.HealthStatus === 'Healthy'
    ).length;

    // Get target group health
    let targetGroupHealthy = 0;
    if (AWS_CONFIG.loadBalancer.targetGroupArn) {
      const tgCommand = new DescribeTargetHealthCommand({
        TargetGroupArn: AWS_CONFIG.loadBalancer.targetGroupArn,
      });
      const tgResponse = await elbv2.send(tgCommand);
      targetGroupHealthy =
        tgResponse.TargetHealthDescriptions?.filter(
          (t) => t.TargetHealth?.State === 'healthy'
        ).length || 0;
    }

    // Get load balancer status
    let loadBalancerStatus = 'unknown';
    if (AWS_CONFIG.loadBalancer.loadBalancerArn) {
      const lbCommand = new DescribeLoadBalancersCommand({
        LoadBalancerArns: [AWS_CONFIG.loadBalancer.loadBalancerArn],
      });
      const lbResponse = await elbv2.send(lbCommand);
      loadBalancerStatus = lbResponse.LoadBalancers?.[0]?.State?.Code || 'unknown';
    }

    // Determine overall health status
    let status: 'healthy' | 'degraded' | 'critical';
    if (healthyInstanceCount >= targetInstanceCount) {
      status = 'healthy';
    } else if (healthyInstanceCount > 0) {
      status = 'degraded';
    } else {
      status = 'critical';
    }

    return {
      status,
      targetInstanceCount,
      healthyInstances: Math.max(healthyInstanceCount, targetGroupHealthy),
      loadBalancerStatus,
      lastChecked: new Date().toISOString(),
    };
  } catch (error) {
    console.error('Error getting system health:', error);
    return {
      status: 'critical',
      targetInstanceCount: 0,
      healthyInstances: 0,
      loadBalancerStatus: 'error',
      lastChecked: new Date().toISOString(),
    };
  }
};

// Get CloudWatch metrics for a time period
export const getMetricStatistics = async (
  metricName: string,
  namespace: string,
  dimensions: Dimension[],
  startTime: Date,
  endTime: Date,
  period: number = 300,
  statistics: Statistic[] = [Statistic.Average]
): Promise<any[]> => {
  const command = new GetMetricStatisticsCommand({
    Namespace: namespace,
    MetricName: metricName,
    Dimensions: dimensions,
    StartTime: startTime,
    EndTime: endTime,
    Period: period,
    Statistics: statistics,
  });

  const response = await cloudwatch.send(command);
  return response.Datapoints || [];
};

// Get healthy host count metrics
export const getHealthyHostCountMetrics = async (
  targetGroupArn: string,
  startTime: Date,
  endTime: Date
): Promise<any[]> => {
  const loadBalancerName = extractLoadBalancerName(targetGroupArn);
  const targetGroupName = extractTargetGroupName(targetGroupArn);

  if (!loadBalancerName || !targetGroupName) {
    return [];
  }

  return getMetricStatistics(
    'HealthyHostCount',
    'AWS/ApplicationELB',
    [
      { Name: 'LoadBalancer', Value: loadBalancerName },
      { Name: 'TargetGroup', Value: targetGroupName },
    ],
    startTime,
    endTime
  );
};

// Get request count metrics
export const getRequestCountMetrics = async (
  loadBalancerArn: string,
  startTime: Date,
  endTime: Date
): Promise<any[]> => {
  const loadBalancerName = extractLoadBalancerName(loadBalancerArn);

  if (!loadBalancerName) {
    return [];
  }

  return getMetricStatistics(
    'RequestCount',
    'AWS/ApplicationELB',
    [{ Name: 'LoadBalancer', Value: loadBalancerName }],
    startTime,
    endTime,
    300,
    [Statistic.Sum]
  );
};

// Get target response time metrics
export const getTargetResponseTimeMetrics = async (
  targetGroupArn: string,
  startTime: Date,
  endTime: Date
): Promise<any[]> => {
  const loadBalancerName = extractLoadBalancerName(targetGroupArn);
  const targetGroupName = extractTargetGroupName(targetGroupArn);

  if (!loadBalancerName || !targetGroupName) {
    return [];
  }

  return getMetricStatistics(
    'TargetResponseTime',
    'AWS/ApplicationELB',
    [
      { Name: 'LoadBalancer', Value: loadBalancerName },
      { Name: 'TargetGroup', Value: targetGroupName },
    ],
    startTime,
    endTime
  );
};

// Get HTTP 5xx error metrics
export const getHTTP5xxErrorMetrics = async (
  loadBalancerArn: string,
  startTime: Date,
  endTime: Date
): Promise<any[]> => {
  const loadBalancerName = extractLoadBalancerName(loadBalancerArn);

  if (!loadBalancerName) {
    return [];
  }

  return getMetricStatistics(
    'HTTPCode_Target_5XX_Count',
    'AWS/ApplicationELB',
    [{ Name: 'LoadBalancer', Value: loadBalancerName }],
    startTime,
    endTime,
    300,
    [Statistic.Sum]
  );
};

// Helper functions
function extractLoadBalancerName(arn: string): string | null {
  // Extract from ARN: arn:aws:elasticloadbalancing:region:account:loadbalancer/app/name/id
  const match = arn.match(/loadbalancer\/(app\/[^/]+\/[^/]+)/);
  return match ? match[1] : null;
}

function extractTargetGroupName(arn: string): string | null {
  // Extract from ARN: arn:aws:elasticloadbalancing:region:account:targetgroup/name/id
  const match = arn.match(/targetgroup\/([^/]+\/[^/]+)/);
  return match ? match[1] : null;
}
