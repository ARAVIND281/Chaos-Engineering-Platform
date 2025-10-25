import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Switch } from '@/components/ui/switch';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';
import { createExperiment } from '@/services/api';
import { CreateExperimentRequest } from '@/types/api';
import { useNavigate } from 'react-router-dom';
import { toast } from 'sonner';
import { HelpCircle, Loader2 } from 'lucide-react';

export default function NewExperiment() {
  const [isLoading, setIsLoading] = useState(false);
  const [formData, setFormData] = useState({
    targetType: 'AUTO_SCALING_GROUP',
    targetId: 'chaos-target-asg',
    dryRun: false,
    expectedHealthyInstances: 2,
    failureType: 'INSTANCE_TERMINATION',
    name: '',
    hypothesis: '',
    owner: '',
  });
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);

    const request: CreateExperimentRequest = {
      targetType: formData.targetType,
      targetId: formData.targetId,
      configuration: {
        dryRun: formData.dryRun,
        expectedHealthyInstances: formData.expectedHealthyInstances,
        failureType: formData.failureType,
      },
      metadata: {
        name: formData.name || undefined,
        hypothesis: formData.hypothesis || undefined,
        owner: formData.owner || undefined,
      },
    };

    const response = await createExperiment(request);
    
    if (response.success) {
      toast.success('Experiment started successfully');
      navigate(`/experiments/${response.data.experimentId}/monitor`);
    } else {
      toast.error('Failed to start experiment');
      setIsLoading(false);
    }
  };

  return (
    <div className="p-6 max-w-3xl mx-auto animate-fade-in">
      <div className="mb-6">
        <h2 className="text-2xl font-bold">Create New Experiment</h2>
        <p className="text-muted-foreground">Configure and launch a chaos engineering experiment</p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        <Card>
          <CardHeader>
            <CardTitle>Target Selection</CardTitle>
            <CardDescription>Choose the infrastructure target for this experiment</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="asg">Auto Scaling Group</Label>
              <Select
                value={formData.targetId}
                onValueChange={(value) => setFormData({ ...formData, targetId: value })}
              >
                <SelectTrigger id="asg">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="chaos-target-asg">chaos-target-asg</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Experiment Configuration</CardTitle>
            <CardDescription>Configure the chaos experiment parameters</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center justify-between">
              <div className="space-y-0.5">
                <Label htmlFor="dryRun" className="flex items-center gap-2">
                  Dry Run Mode
                  <TooltipProvider>
                    <Tooltip>
                      <TooltipTrigger asChild>
                        <HelpCircle className="w-4 h-4 text-muted-foreground" />
                      </TooltipTrigger>
                      <TooltipContent>
                        <p className="max-w-xs">
                          Simulates the experiment without making actual changes
                        </p>
                      </TooltipContent>
                    </Tooltip>
                  </TooltipProvider>
                </Label>
                <p className="text-sm text-muted-foreground">
                  Test the experiment without affecting infrastructure
                </p>
              </div>
              <Switch
                id="dryRun"
                checked={formData.dryRun}
                onCheckedChange={(checked) => setFormData({ ...formData, dryRun: checked })}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="healthyInstances">Expected Healthy Instances</Label>
              <Input
                id="healthyInstances"
                type="number"
                min="1"
                value={formData.expectedHealthyInstances}
                onChange={(e) => setFormData({ ...formData, expectedHealthyInstances: parseInt(e.target.value) })}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="failureType">Failure Type</Label>
              <Select
                value={formData.failureType}
                onValueChange={(value) => setFormData({ ...formData, failureType: value })}
              >
                <SelectTrigger id="failureType">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="INSTANCE_TERMINATION">Instance Termination</SelectItem>
                  <SelectItem value="NETWORK_LATENCY">Network Latency</SelectItem>
                  <SelectItem value="CPU_STRESS">CPU Stress</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Metadata (Optional)</CardTitle>
            <CardDescription>Additional information about this experiment</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="name">Experiment Name</Label>
              <Input
                id="name"
                placeholder="e.g., Instance Recovery Test"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="hypothesis">Hypothesis/Description</Label>
              <Textarea
                id="hypothesis"
                placeholder="What are you testing?"
                value={formData.hypothesis}
                onChange={(e) => setFormData({ ...formData, hypothesis: e.target.value })}
                rows={3}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="owner">Owner/Team</Label>
              <Input
                id="owner"
                placeholder="e.g., Platform Team"
                value={formData.owner}
                onChange={(e) => setFormData({ ...formData, owner: e.target.value })}
              />
            </div>
          </CardContent>
        </Card>

        <div className="flex gap-3">
          <Button type="submit" disabled={isLoading}>
            {isLoading && <Loader2 className="w-4 h-4 mr-2 animate-spin" />}
            Start Experiment
          </Button>
          <Button type="button" variant="outline" onClick={() => navigate('/experiments')}>
            Cancel
          </Button>
        </div>
      </form>
    </div>
  );
}
