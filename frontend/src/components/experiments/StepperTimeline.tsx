import { ExperimentStep } from '@/types/api';
import { Check, Circle, Loader2, X } from 'lucide-react';
import { cn } from '@/lib/utils';

interface StepperTimelineProps {
  steps: ExperimentStep[];
}

export function StepperTimeline({ steps }: StepperTimelineProps) {
  return (
    <div className="space-y-4">
      {steps.map((step, index) => (
        <div key={index} className="flex items-start gap-4">
          <div className="flex flex-col items-center">
            <div className={cn(
              'w-10 h-10 rounded-full flex items-center justify-center border-2',
              step.status === 'completed' && 'bg-success/10 border-success text-success',
              step.status === 'running' && 'bg-primary/10 border-primary text-primary status-pulse',
              step.status === 'failed' && 'bg-danger/10 border-danger text-danger',
              step.status === 'pending' && 'bg-muted border-muted-foreground/20 text-muted-foreground'
            )}>
              {step.status === 'completed' && <Check className="w-5 h-5" />}
              {step.status === 'running' && <Loader2 className="w-5 h-5 animate-spin" />}
              {step.status === 'failed' && <X className="w-5 h-5" />}
              {step.status === 'pending' && <Circle className="w-5 h-5" />}
            </div>
            {index < steps.length - 1 && (
              <div className={cn(
                'w-0.5 h-12 mt-2',
                step.status === 'completed' ? 'bg-success/30' : 'bg-muted'
              )} />
            )}
          </div>
          
          <div className="flex-1 pb-8">
            <div className="flex items-center justify-between">
              <h4 className="font-medium">{step.stepName}</h4>
              {step.duration && (
                <span className="text-xs text-muted-foreground">
                  {step.duration}s
                </span>
              )}
            </div>
            
            {step.startTime && (
              <p className="text-xs text-muted-foreground mt-1">
                {new Date(step.startTime).toLocaleTimeString()}
              </p>
            )}
            
            {step.output && (
              <div className="mt-2 p-2 rounded bg-muted text-xs font-mono">
                {JSON.stringify(step.output, null, 2)}
              </div>
            )}
          </div>
        </div>
      ))}
    </div>
  );
}
