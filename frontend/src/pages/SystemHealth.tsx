import { useEffect, useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import {
  Activity,
  Server,
  Database,
  Cloud,
  Zap,
  RefreshCw,
  CheckCircle2,
  XCircle,
  AlertTriangle,
  Clock
} from 'lucide-react';

interface ServiceHealth {
  name: string;
  status: 'healthy' | 'degraded' | 'unhealthy' | 'unknown';
  lastCheck: string;
  responseTime?: number;
  details?: string;
  metrics?: {
    label: string;
    value: string | number;
    status?: 'good' | 'warning' | 'critical';
  }[];
}

interface SystemHealthData {
  overall: 'healthy' | 'degraded' | 'critical';
  lastUpdated: string;
  services: {
    compute: ServiceHealth[];
    database: ServiceHealth[];
    orchestration: ServiceHealth[];
    networking: ServiceHealth[];
  };
}

export default function SystemHealth() {
  const [healthData, setHealthData] = useState<SystemHealthData | null>(null);
  const [loading, setLoading] = useState(true);
  const [autoRefresh, setAutoRefresh] = useState(true);

  const fetchHealthStatus = async () => {
    try {
      setLoading(true);

      // Mock data - Replace with actual API call
      // const response = await fetch('/api/v1/health');
      // const data = await response.json();

      // Mock data for demonstration
      const mockData: SystemHealthData = {
        overall: 'healthy',
        lastUpdated: new Date().toISOString(),
        services: {
          compute: [
            {
              name: 'EC2 Auto Scaling Group',
              status: 'healthy',
              lastCheck: new Date().toISOString(),
              responseTime: 45,
              details: 'All instances healthy and passing health checks',
              metrics: [
                { label: 'Running Instances', value: '2 / 2', status: 'good' },
                { label: 'Healthy Instances', value: '2', status: 'good' },
                { label: 'CPU Utilization', value: '45%', status: 'good' },
                { label: 'Memory Usage', value: '62%', status: 'good' }
              ]
            },
            {
              name: 'Application Load Balancer',
              status: 'healthy',
              lastCheck: new Date().toISOString(),
              responseTime: 23,
              details: 'Load balancer operating normally',
              metrics: [
                { label: 'Active Connections', value: 127, status: 'good' },
                { label: 'Healthy Targets', value: '2 / 2', status: 'good' },
                { label: 'Request Rate', value: '450/min', status: 'good' },
                { label: 'Latency (p95)', value: '89ms', status: 'good' }
              ]
            },
            {
              name: 'Target Group Health',
              status: 'healthy',
              lastCheck: new Date().toISOString(),
              responseTime: 12,
              details: 'All targets passing health checks',
              metrics: [
                { label: 'Healthy Targets', value: '2 / 2', status: 'good' },
                { label: 'Unhealthy Targets', value: '0', status: 'good' },
                { label: 'Health Check Interval', value: '30s', status: 'good' }
              ]
            }
          ],
          database: [
            {
              name: 'DynamoDB - Experiments Table',
              status: 'healthy',
              lastCheck: new Date().toISOString(),
              responseTime: 8,
              details: 'Table accessible and responding',
              metrics: [
                { label: 'Item Count', value: '247', status: 'good' },
                { label: 'Table Size', value: '1.2 MB', status: 'good' },
                { label: 'Read Capacity', value: 'On-Demand', status: 'good' },
                { label: 'Write Capacity', value: 'On-Demand', status: 'good' }
              ]
            },
            {
              name: 'DynamoDB - Results Table',
              status: 'healthy',
              lastCheck: new Date().toISOString(),
              responseTime: 7,
              details: 'Table accessible and responding',
              metrics: [
                { label: 'Item Count', value: '1,042', status: 'good' },
                { label: 'Table Size', value: '5.7 MB', status: 'good' },
                { label: 'Read Throughput', value: '12/sec', status: 'good' },
                { label: 'Write Throughput', value: '3/sec', status: 'good' }
              ]
            },
            {
              name: 'DynamoDB - Users Table',
              status: 'healthy',
              lastCheck: new Date().toISOString(),
              responseTime: 6,
              details: 'Table accessible and responding',
              metrics: [
                { label: 'Item Count', value: '8', status: 'good' },
                { label: 'Table Size', value: '0.1 MB', status: 'good' }
              ]
            }
          ],
          orchestration: [
            {
              name: 'Step Functions State Machine',
              status: 'healthy',
              lastCheck: new Date().toISOString(),
              responseTime: 34,
              details: 'State machine operational',
              metrics: [
                { label: 'Running Executions', value: 2, status: 'good' },
                { label: 'Success Rate (24h)', value: '98.5%', status: 'good' },
                { label: 'Avg Duration', value: '5m 23s', status: 'good' },
                { label: 'Failed (24h)', value: 3, status: 'warning' }
              ]
            },
            {
              name: 'Lambda - Get Target Instance',
              status: 'healthy',
              lastCheck: new Date().toISOString(),
              responseTime: 156,
              details: 'Function responding normally',
              metrics: [
                { label: 'Invocations (24h)', value: '234', status: 'good' },
                { label: 'Errors (24h)', value: '0', status: 'good' },
                { label: 'Avg Duration', value: '156ms', status: 'good' },
                { label: 'Throttles', value: '0', status: 'good' }
              ]
            },
            {
              name: 'Lambda - Inject Failure',
              status: 'healthy',
              lastCheck: new Date().toISOString(),
              responseTime: 2340,
              details: 'Function executing chaos experiments',
              metrics: [
                { label: 'Invocations (24h)', value: '187', status: 'good' },
                { label: 'Errors (24h)', value: '2', status: 'warning' },
                { label: 'Avg Duration', value: '2.3s', status: 'good' },
                { label: 'Success Rate', value: '98.9%', status: 'good' }
              ]
            },
            {
              name: 'Lambda - Validate Health',
              status: 'healthy',
              lastCheck: new Date().toISOString(),
              responseTime: 892,
              details: 'Function monitoring system health',
              metrics: [
                { label: 'Invocations (24h)', value: '468', status: 'good' },
                { label: 'Errors (24h)', value: '1', status: 'good' },
                { label: 'Avg Duration', value: '892ms', status: 'good' }
              ]
            }
          ],
          networking: [
            {
              name: 'VPC Configuration',
              status: 'healthy',
              lastCheck: new Date().toISOString(),
              details: 'VPC and subnets configured correctly',
              metrics: [
                { label: 'VPC ID', value: 'vpc-0c719f6fd8645ce8c', status: 'good' },
                { label: 'Public Subnets', value: '2', status: 'good' },
                { label: 'Private Subnets', value: '2', status: 'good' },
                { label: 'Availability Zones', value: '2', status: 'good' }
              ]
            },
            {
              name: 'NAT Gateways',
              status: 'healthy',
              lastCheck: new Date().toISOString(),
              details: 'NAT gateways operational in both AZs',
              metrics: [
                { label: 'Active NAT Gateways', value: '2', status: 'good' },
                { label: 'Data Processed (24h)', value: '2.3 GB', status: 'good' }
              ]
            },
            {
              name: 'Internet Gateway',
              status: 'healthy',
              lastCheck: new Date().toISOString(),
              details: 'Internet gateway attached and operational',
              metrics: [
                { label: 'Status', value: 'Attached', status: 'good' },
                { label: 'VPC', value: 'vpc-0c719f6fd8645ce8c', status: 'good' }
              ]
            },
            {
              name: 'Security Groups',
              status: 'healthy',
              lastCheck: new Date().toISOString(),
              details: 'Security groups configured correctly',
              metrics: [
                { label: 'Total Rules', value: '14', status: 'good' },
                { label: 'Ingress Rules', value: '8', status: 'good' },
                { label: 'Egress Rules', value: '6', status: 'good' }
              ]
            }
          ]
        }
      };

      setHealthData(mockData);
    } catch (error) {
      console.error('Failed to fetch health status:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchHealthStatus();

    if (autoRefresh) {
      const interval = setInterval(fetchHealthStatus, 30000); // Refresh every 30 seconds
      return () => clearInterval(interval);
    }
  }, [autoRefresh]);

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'healthy':
        return <CheckCircle2 className="h-5 w-5 text-green-500" />;
      case 'degraded':
        return <AlertTriangle className="h-5 w-5 text-yellow-500" />;
      case 'unhealthy':
        return <XCircle className="h-5 w-5 text-red-500" />;
      default:
        return <Activity className="h-5 w-5 text-gray-400" />;
    }
  };

  const getStatusBadge = (status: string) => {
    const variants: Record<string, 'default' | 'secondary' | 'destructive'> = {
      healthy: 'default',
      degraded: 'secondary',
      unhealthy: 'destructive',
      unknown: 'secondary'
    };

    return (
      <Badge variant={variants[status] || 'secondary'}>
        {status.toUpperCase()}
      </Badge>
    );
  };

  const getMetricStatusColor = (status?: string) => {
    switch (status) {
      case 'good':
        return 'text-green-600';
      case 'warning':
        return 'text-yellow-600';
      case 'critical':
        return 'text-red-600';
      default:
        return 'text-gray-600';
    }
  };

  const renderServiceCard = (service: ServiceHealth) => (
    <Card key={service.name} className="mb-4">
      <CardHeader>
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            {getStatusIcon(service.status)}
            <div>
              <CardTitle className="text-lg">{service.name}</CardTitle>
              <CardDescription className="text-sm mt-1">
                {service.details}
              </CardDescription>
            </div>
          </div>
          <div className="flex items-center gap-3">
            {service.responseTime && (
              <span className="text-sm text-gray-500">
                {service.responseTime}ms
              </span>
            )}
            {getStatusBadge(service.status)}
          </div>
        </div>
      </CardHeader>
      {service.metrics && service.metrics.length > 0 && (
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {service.metrics.map((metric, idx) => (
              <div key={idx} className="flex flex-col">
                <span className="text-sm text-gray-500">{metric.label}</span>
                <span className={`text-lg font-semibold ${getMetricStatusColor(metric.status)}`}>
                  {metric.value}
                </span>
              </div>
            ))}
          </div>
        </CardContent>
      )}
    </Card>
  );

  if (loading && !healthData) {
    return (
      <div className="container mx-auto py-8">
        <div className="flex items-center justify-center h-64">
          <RefreshCw className="h-8 w-8 animate-spin text-gray-400" />
        </div>
      </div>
    );
  }

  return (
    <div className="container mx-auto py-8">
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-3xl font-bold">System Health</h1>
          <p className="text-gray-600 mt-2">
            Real-time monitoring of all infrastructure components
          </p>
        </div>
        <div className="flex items-center gap-4">
          <button
            onClick={() => setAutoRefresh(!autoRefresh)}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg border ${
              autoRefresh ? 'bg-green-50 border-green-300' : 'bg-gray-50 border-gray-300'
            }`}
          >
            <RefreshCw className={`h-4 w-4 ${autoRefresh ? 'animate-spin' : ''}`} />
            <span className="text-sm">
              {autoRefresh ? 'Auto-refresh ON' : 'Auto-refresh OFF'}
            </span>
          </button>
          <button
            onClick={fetchHealthStatus}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
          >
            <RefreshCw className="h-4 w-4" />
            Refresh Now
          </button>
        </div>
      </div>

      {/* Overall Status */}
      {healthData && (
        <Alert className={`mb-8 ${
          healthData.overall === 'healthy' ? 'border-green-300 bg-green-50' :
          healthData.overall === 'degraded' ? 'border-yellow-300 bg-yellow-50' :
          'border-red-300 bg-red-50'
        }`}>
          <div className="flex items-center gap-3">
            {getStatusIcon(healthData.overall)}
            <div>
              <AlertDescription className="font-semibold text-lg">
                System Status: {healthData.overall.toUpperCase()}
              </AlertDescription>
              <AlertDescription className="text-sm text-gray-600 mt-1 flex items-center gap-2">
                <Clock className="h-3 w-3" />
                Last updated: {new Date(healthData.lastUpdated).toLocaleString()}
              </AlertDescription>
            </div>
          </div>
        </Alert>
      )}

      {/* Services by Category */}
      <Tabs defaultValue="compute" className="w-full">
        <TabsList className="grid w-full grid-cols-4">
          <TabsTrigger value="compute" className="flex items-center gap-2">
            <Server className="h-4 w-4" />
            Compute
          </TabsTrigger>
          <TabsTrigger value="database" className="flex items-center gap-2">
            <Database className="h-4 w-4" />
            Database
          </TabsTrigger>
          <TabsTrigger value="orchestration" className="flex items-center gap-2">
            <Zap className="h-4 w-4" />
            Orchestration
          </TabsTrigger>
          <TabsTrigger value="networking" className="flex items-center gap-2">
            <Cloud className="h-4 w-4" />
            Networking
          </TabsTrigger>
        </TabsList>

        {healthData && (
          <>
            <TabsContent value="compute" className="mt-6">
              {healthData.services.compute.map(renderServiceCard)}
            </TabsContent>

            <TabsContent value="database" className="mt-6">
              {healthData.services.database.map(renderServiceCard)}
            </TabsContent>

            <TabsContent value="orchestration" className="mt-6">
              {healthData.services.orchestration.map(renderServiceCard)}
            </TabsContent>

            <TabsContent value="networking" className="mt-6">
              {healthData.services.networking.map(renderServiceCard)}
            </TabsContent>
          </>
        )}
      </Tabs>
    </div>
  );
}
