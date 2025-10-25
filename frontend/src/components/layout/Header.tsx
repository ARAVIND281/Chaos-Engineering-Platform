import { useLocation } from 'react-router-dom';
import { StatusBadge } from '@/components/common/StatusBadge';
import { useEffect, useState } from 'react';
import { getSystemHealth } from '@/services/api';
import { SystemHealth } from '@/types/api';

const routeNames: Record<string, string> = {
  '/': 'Dashboard',
  '/experiments': 'Experiments',
  '/experiments/new': 'New Experiment',
  '/results': 'Results & Analytics',
  '/settings': 'Settings',
};

export function Header() {
  const location = useLocation();
  const [health, setHealth] = useState<SystemHealth | null>(null);

  useEffect(() => {
    const fetchHealth = async () => {
      const response = await getSystemHealth();
      if (response.success) {
        setHealth(response.data);
      }
    };

    fetchHealth();
    const interval = setInterval(fetchHealth, 30000);
    return () => clearInterval(interval);
  }, []);

  const pageName = location.pathname.startsWith('/experiments/') && location.pathname.includes('/monitor')
    ? 'Experiment Monitor'
    : routeNames[location.pathname] || 'Page';

  return (
    <header className="h-16 border-b bg-card px-6 flex items-center justify-between">
      <div>
        <h2 className="text-xl font-semibold">{pageName}</h2>
      </div>

      {health && (
        <div className="flex items-center gap-4">
          <div className="flex items-center gap-2 text-sm">
            <span className="text-muted-foreground">System Health:</span>
            <StatusBadge status={health.status} />
          </div>
          <div className="text-xs text-muted-foreground">
            {health.healthyInstances}/{health.targetInstanceCount} instances
          </div>
        </div>
      )}
    </header>
  );
}
