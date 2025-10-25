import { Card, CardContent } from '@/components/ui/card';
import { StatusBadge } from '@/components/common/StatusBadge';
import { Experiment } from '@/types/api';
import { format } from 'date-fns';
import { Clock, Target } from 'lucide-react';

interface ExperimentCardProps {
  experiment: Experiment;
  onClick: () => void;
}

export function ExperimentCard({ experiment, onClick }: ExperimentCardProps) {
  return (
    <Card className="hover-lift cursor-pointer" onClick={onClick}>
      <CardContent className="p-4">
        <div className="space-y-3">
          <div className="flex items-start justify-between">
            <div className="space-y-1">
              <p className="font-mono text-sm font-medium">{experiment.experimentId}</p>
              {experiment.metadata?.name && (
                <p className="text-sm text-muted-foreground">{experiment.metadata.name}</p>
              )}
            </div>
            <StatusBadge status={experiment.status} />
          </div>
          
          <div className="flex items-center gap-4 text-xs text-muted-foreground">
            <div className="flex items-center gap-1">
              <Target className="w-3 h-3" />
              <span>{experiment.targetId}</span>
            </div>
            <div className="flex items-center gap-1">
              <Clock className="w-3 h-3" />
              <span>{format(new Date(experiment.startTime), 'MMM dd, HH:mm')}</span>
            </div>
          </div>
          
          {experiment.duration && (
            <p className="text-xs text-muted-foreground">
              Duration: {experiment.duration}s
            </p>
          )}
        </div>
      </CardContent>
    </Card>
  );
}
