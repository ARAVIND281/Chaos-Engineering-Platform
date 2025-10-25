import { useEffect, useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { MetricCard } from '@/components/common/MetricCard';
import { getResults, getAnalytics, exportResults } from '@/services/api';
import { ExperimentResult, Analytics } from '@/types/api';
import { Activity, CheckCircle, Clock, Beaker, Download } from 'lucide-react';
import { LineChart, Line, BarChart, Bar, PieChart, Pie, Cell, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { Button } from '@/components/ui/button';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { format } from 'date-fns';
import { toast } from 'sonner';

const COLORS = ['#1e40af', '#f97316', '#10b981', '#ef4444'];

export default function Results() {
  const [results, setResults] = useState<ExperimentResult[]>([]);
  const [analytics, setAnalytics] = useState<Analytics | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    setIsLoading(true);
    const [resultsRes, analyticsRes] = await Promise.all([
      getResults(),
      getAnalytics(),
    ]);

    if (resultsRes.success) setResults(resultsRes.data);
    if (analyticsRes.success) setAnalytics(analyticsRes.data);
    setIsLoading(false);
  };

  const handleExport = async (format: 'csv' | 'json') => {
    const response = await exportResults(format);
    if (response.success) {
      const url = URL.createObjectURL(response.data);
      const a = document.createElement('a');
      a.href = url;
      a.download = `experiment-results.${format}`;
      a.click();
      toast.success(`Results exported as ${format.toUpperCase()}`);
    } else {
      toast.error('Failed to export results');
    }
  };

  if (isLoading || !analytics) {
    return (
      <div className="p-6">
        <div className="animate-pulse space-y-4">
          <div className="h-8 bg-muted rounded w-1/3" />
          <div className="grid grid-cols-4 gap-4">
            {[1, 2, 3, 4].map((i) => (
              <div key={i} className="h-32 bg-muted rounded" />
            ))}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6 animate-fade-in">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold">Results & Analytics</h2>
          <p className="text-muted-foreground">Analyze experiment outcomes and trends</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" size="sm" onClick={() => handleExport('json')}>
            <Download className="w-4 h-4 mr-2" />
            Export JSON
          </Button>
          <Button variant="outline" size="sm" onClick={() => handleExport('csv')}>
            <Download className="w-4 h-4 mr-2" />
            Export CSV
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <MetricCard
          title="Total Experiments"
          value={analytics.totalExperiments}
          icon={Beaker}
        />
        <MetricCard
          title="Success Rate"
          value={`${analytics.successRate}%`}
          icon={CheckCircle}
        />
        <MetricCard
          title="Avg Recovery Time"
          value={`${analytics.averageRecoveryTime}s`}
          icon={Clock}
        />
        <MetricCard
          title="Last 24h Experiments"
          value={analytics.last24hExperiments}
          icon={Activity}
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Experiments Over Time</CardTitle>
            <CardDescription>Daily experiment count (last 30 days)</CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={analytics.experimentsOverTime}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Line type="monotone" dataKey="count" stroke="#1e40af" strokeWidth={2} />
              </LineChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Success vs Failure Rate</CardTitle>
            <CardDescription>Weekly comparison</CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={analytics.successFailureByWeek}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="week" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Bar dataKey="success" fill="#10b981" />
                <Bar dataKey="failure" fill="#ef4444" />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Experiment Type Distribution</CardTitle>
            <CardDescription>Breakdown by type</CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={250}>
              <PieChart>
                <Pie
                  data={analytics.experimentTypeDistribution}
                  dataKey="count"
                  nameKey="type"
                  cx="50%"
                  cy="50%"
                  outerRadius={80}
                  label
                >
                  {analytics.experimentTypeDistribution.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle>Recent Results</CardTitle>
            <CardDescription>Latest experiment outcomes</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="border rounded-lg">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Result ID</TableHead>
                    <TableHead>Timestamp</TableHead>
                    <TableHead>Success</TableHead>
                    <TableHead>Recovery Time</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {results.slice(0, 5).map((result) => (
                    <TableRow key={result.resultId}>
                      <TableCell className="font-mono text-sm">{result.resultId}</TableCell>
                      <TableCell className="text-sm">
                        {format(new Date(result.timestamp), 'MMM dd, HH:mm')}
                      </TableCell>
                      <TableCell>
                        <span className={`font-medium ${result.success ? 'text-success' : 'text-danger'}`}>
                          {result.success ? 'Yes' : 'No'}
                        </span>
                      </TableCell>
                      <TableCell>{result.recoveryTime}s</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
