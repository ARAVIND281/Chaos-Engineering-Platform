import { Card, CardContent } from '@/components/ui/card';
import { LucideIcon, TrendingUp, TrendingDown } from 'lucide-react';
import { cn } from '@/lib/utils';

interface MetricCardProps {
  title: string;
  value: string | number;
  icon: LucideIcon;
  trend?: 'up' | 'down';
  trendValue?: string;
  className?: string;
}

export function MetricCard({ title, value, icon: Icon, trend, trendValue, className }: MetricCardProps) {
  return (
    <Card className={cn('hover-lift', className)}>
      <CardContent className="p-6">
        <div className="flex items-center justify-between">
          <div className="space-y-1">
            <p className="text-sm font-medium text-muted-foreground">{title}</p>
            <p className="text-3xl font-bold">{value}</p>
            {trendValue && (
              <div className="flex items-center gap-1 text-xs">
                {trend === 'up' ? (
                  <TrendingUp className="w-3 h-3 text-success" />
                ) : trend === 'down' ? (
                  <TrendingDown className="w-3 h-3 text-danger" />
                ) : null}
                <span className={cn(
                  'font-medium',
                  trend === 'up' ? 'text-success' : trend === 'down' ? 'text-danger' : 'text-muted-foreground'
                )}>
                  {trendValue}
                </span>
              </div>
            )}
          </div>
          <div className="p-3 rounded-lg bg-primary/10">
            <Icon className="w-6 h-6 text-primary" />
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
