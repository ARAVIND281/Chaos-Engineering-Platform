import { cn } from '@/lib/utils';

interface StatusBadgeProps {
  status: 'PENDING' | 'RUNNING' | 'COMPLETED' | 'FAILED' | 'healthy' | 'degraded' | 'critical';
  className?: string;
}

const statusConfig = {
  PENDING: {
    label: 'Pending',
    className: 'bg-muted text-muted-foreground border-muted-foreground/20',
  },
  RUNNING: {
    label: 'Running',
    className: 'bg-primary/10 text-primary border-primary/30 status-pulse',
  },
  COMPLETED: {
    label: 'Completed',
    className: 'bg-success/10 text-success border-success/30',
  },
  FAILED: {
    label: 'Failed',
    className: 'bg-danger/10 text-danger border-danger/30',
  },
  healthy: {
    label: 'Healthy',
    className: 'bg-success/10 text-success border-success/30',
  },
  degraded: {
    label: 'Degraded',
    className: 'bg-secondary/10 text-secondary border-secondary/30',
  },
  critical: {
    label: 'Critical',
    className: 'bg-danger/10 text-danger border-danger/30',
  },
};

export function StatusBadge({ status, className }: StatusBadgeProps) {
  const config = statusConfig[status];
  
  return (
    <span
      className={cn(
        'inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium border',
        config.className,
        className
      )}
    >
      <span className="w-1.5 h-1.5 rounded-full bg-current" />
      {config.label}
    </span>
  );
}
