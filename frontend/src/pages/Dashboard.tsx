import { useEffect, useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { MetricCard } from '@/components/common/MetricCard';
import { ExperimentCard } from '@/components/experiments/ExperimentCard';
import { StatusBadge } from '@/components/common/StatusBadge';
import { getSystemHealth, getExperiments, getAnalytics } from '@/services/api';
import { SystemHealth, Experiment, Analytics } from '@/types/api';
import { Activity, Beaker, CheckCircle, Clock, Plus, TrendingUp } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { Skeleton } from '@/components/ui/skeleton';

export default function Dashboard() {
  const [health, setHealth] = useState<SystemHealth | null>(null);
  const [experiments, setExperiments] = useState<Experiment[]>([]);
  const [analytics, setAnalytics] = useState<Analytics | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    const fetchData = async () => {
      setIsLoading(true);
      const [healthRes, experimentsRes, analyticsRes] = await Promise.all([
        getSystemHealth(),
        getExperiments(),
        getAnalytics(),
      ]);

      if (healthRes.success) setHealth(healthRes.data);
      if (experimentsRes.success) setExperiments(experimentsRes.data.slice(0, 5));
      if (analyticsRes.success) setAnalytics(analyticsRes.data);
      setIsLoading(false);
    };

    fetchData();
  }, []);

  if (isLoading) {
    return (
      <div className="p-6 space-y-6 animate-fade-in">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {[1, 2, 3, 4].map((i) => (
            <Skeleton key={i} className="h-32" />
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6 animate-fade-in">
      {/* Quick Stats */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <MetricCard
          title="Total Experiments"
          value={analytics?.totalExperiments || 0}
          icon={Beaker}
          trend="up"
          trendValue="+12%"
        />
        <MetricCard
          title="Success Rate"
          value={`${analytics?.successRate || 0}%`}
          icon={CheckCircle}
          trend="up"
          trendValue="+5%"
        />
        <MetricCard
          title="Avg Recovery Time"
          value={`${analytics?.averageRecoveryTime || 0}s`}
          icon={Clock}
        />
        <MetricCard
          title="Active Experiments"
          value={experiments.filter(e => e.status === 'RUNNING').length}
          icon={Activity}
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* System Health */}
        <Card>
          <CardHeader>
            <CardTitle>System Health</CardTitle>
            <CardDescription>Current infrastructure status</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {health && (
              <>
                <div className="flex items-center justify-between">
                  <span className="text-sm font-medium">Status</span>
                  <StatusBadge status={health.status} />
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground">Target Instances</span>
                  <span className="font-mono">{health.targetInstanceCount}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground">Healthy Instances</span>
                  <span className="font-mono">{health.healthyInstances}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-muted-foreground">Load Balancer</span>
                  <span className="font-mono">{health.loadBalancerStatus}</span>
                </div>
              </>
            )}
          </CardContent>
        </Card>

        {/* Recent Experiments */}
        <Card>
          <CardHeader>
            <CardTitle>Recent Experiments</CardTitle>
            <CardDescription>Latest chaos experiments</CardDescription>
          </CardHeader>
          <CardContent className="space-y-3">
            {experiments.map((experiment) => (
              <ExperimentCard
                key={experiment.experimentId}
                experiment={experiment}
                onClick={() => navigate(`/experiments/${experiment.experimentId}/monitor`)}
              />
            ))}
          </CardContent>
        </Card>
      </div>

      {/* Quick Actions */}
      <Card>
        <CardHeader>
          <CardTitle>Quick Actions</CardTitle>
          <CardDescription>Common operations</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex flex-wrap gap-3">
            <Button onClick={() => navigate('/experiments/new')}>
              <Plus className="w-4 h-4 mr-2" />
              Run New Experiment
            </Button>
            <Button variant="outline" onClick={() => navigate('/results')}>
              <TrendingUp className="w-4 h-4 mr-2" />
              View All Results
            </Button>
            <Button variant="outline" onClick={() => navigate('/experiments')}>
              <Beaker className="w-4 h-4 mr-2" />
              Manage Experiments
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
