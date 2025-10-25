import { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { StatusBadge } from '@/components/common/StatusBadge';
import { StepperTimeline } from '@/components/experiments/StepperTimeline';
import { getExperiment, getExperimentSteps, stopExperiment } from '@/services/api';
import { Experiment, ExperimentStep } from '@/types/api';
import { ArrowLeft, StopCircle } from 'lucide-react';
import { toast } from 'sonner';
import { format } from 'date-fns';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from '@/components/ui/alert-dialog';

export default function ExperimentMonitor() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [experiment, setExperiment] = useState<Experiment | null>(null);
  const [steps, setSteps] = useState<ExperimentStep[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    if (!id) return;

    fetchData();
    
    // Poll every 5 seconds if experiment is running
    const interval = setInterval(() => {
      if (experiment?.status === 'RUNNING') {
        fetchData();
      }
    }, 5000);

    return () => clearInterval(interval);
  }, [id, experiment?.status]);

  const fetchData = async () => {
    if (!id) return;

    const [expRes, stepsRes] = await Promise.all([
      getExperiment(id),
      getExperimentSteps(id),
    ]);

    if (expRes.success) setExperiment(expRes.data);
    if (stepsRes.success) setSteps(stepsRes.data);
    setIsLoading(false);
  };

  const handleStop = async () => {
    if (!id) return;

    const response = await stopExperiment(id);
    if (response.success) {
      toast.success('Experiment stopped');
      fetchData();
    } else {
      toast.error('Failed to stop experiment');
    }
  };

  if (isLoading || !experiment) {
    return (
      <div className="p-6">
        <div className="animate-pulse space-y-4">
          <div className="h-8 bg-muted rounded w-1/3" />
          <div className="h-64 bg-muted rounded" />
        </div>
      </div>
    );
  }

  return (
    <div className="p-6 space-y-6 animate-fade-in">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Button variant="ghost" size="sm" onClick={() => navigate('/experiments')}>
            <ArrowLeft className="w-4 h-4 mr-2" />
            Back
          </Button>
          <div>
            <h2 className="text-2xl font-bold font-mono">{experiment.experimentId}</h2>
            {experiment.metadata?.name && (
              <p className="text-muted-foreground">{experiment.metadata.name}</p>
            )}
          </div>
        </div>
        <div className="flex items-center gap-3">
          <StatusBadge status={experiment.status} />
          {experiment.status === 'RUNNING' && (
            <AlertDialog>
              <AlertDialogTrigger asChild>
                <Button variant="destructive" size="sm">
                  <StopCircle className="w-4 h-4 mr-2" />
                  Stop Experiment
                </Button>
              </AlertDialogTrigger>
              <AlertDialogContent>
                <AlertDialogHeader>
                  <AlertDialogTitle>Stop Experiment?</AlertDialogTitle>
                  <AlertDialogDescription>
                    This will immediately halt the experiment. This action cannot be undone.
                  </AlertDialogDescription>
                </AlertDialogHeader>
                <AlertDialogFooter>
                  <AlertDialogCancel>Cancel</AlertDialogCancel>
                  <AlertDialogAction onClick={handleStop}>Stop</AlertDialogAction>
                </AlertDialogFooter>
              </AlertDialogContent>
            </AlertDialog>
          )}
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle>Experiment Timeline</CardTitle>
            <CardDescription>Step-by-step execution progress</CardDescription>
          </CardHeader>
          <CardContent>
            <StepperTimeline steps={steps} />
          </CardContent>
        </Card>

        <div className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Details</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3 text-sm">
              <div>
                <p className="text-muted-foreground">Target</p>
                <p className="font-mono">{experiment.targetId}</p>
              </div>
              <div>
                <p className="text-muted-foreground">Start Time</p>
                <p>{format(new Date(experiment.startTime), 'PPpp')}</p>
              </div>
              {experiment.endTime && (
                <div>
                  <p className="text-muted-foreground">End Time</p>
                  <p>{format(new Date(experiment.endTime), 'PPpp')}</p>
                </div>
              )}
              {experiment.duration && (
                <div>
                  <p className="text-muted-foreground">Duration</p>
                  <p>{experiment.duration}s</p>
                </div>
              )}
              <div>
                <p className="text-muted-foreground">Created By</p>
                <p>{experiment.createdBy}</p>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Configuration</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3 text-sm">
              <div>
                <p className="text-muted-foreground">Dry Run</p>
                <p>{experiment.configuration.dryRun ? 'Yes' : 'No'}</p>
              </div>
              <div>
                <p className="text-muted-foreground">Expected Healthy</p>
                <p>{experiment.configuration.expectedHealthyInstances} instances</p>
              </div>
              <div>
                <p className="text-muted-foreground">Failure Type</p>
                <p>{experiment.configuration.failureType}</p>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
