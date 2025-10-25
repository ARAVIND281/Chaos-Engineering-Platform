import { useEffect, useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { StatusBadge } from '@/components/common/StatusBadge';
import { getExperiments, deleteExperiment, stopExperiment } from '@/services/api';
import { Experiment } from '@/types/api';
import { Plus, Search, Eye, StopCircle, Trash2, Loader2 } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { format } from 'date-fns';
import { toast } from 'sonner';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog';

export default function Experiments() {
  const [experiments, setExperiments] = useState<Experiment[]>([]);
  const [filteredExperiments, setFilteredExperiments] = useState<Experiment[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState('ALL');
  const [searchQuery, setSearchQuery] = useState('');
  const [deleteDialog, setDeleteDialog] = useState<string | null>(null);
  const navigate = useNavigate();

  useEffect(() => {
    fetchExperiments();
  }, []);

  useEffect(() => {
    let filtered = experiments;

    if (statusFilter !== 'ALL') {
      filtered = filtered.filter(exp => exp.status === statusFilter);
    }

    if (searchQuery) {
      filtered = filtered.filter(exp =>
        exp.experimentId.toLowerCase().includes(searchQuery.toLowerCase()) ||
        exp.targetId.toLowerCase().includes(searchQuery.toLowerCase())
      );
    }

    setFilteredExperiments(filtered);
  }, [experiments, statusFilter, searchQuery]);

  const fetchExperiments = async () => {
    setIsLoading(true);
    const response = await getExperiments();
    if (response.success) {
      setExperiments(response.data);
      setFilteredExperiments(response.data);
    }
    setIsLoading(false);
  };

  const handleStop = async (id: string) => {
    const response = await stopExperiment(id);
    if (response.success) {
      toast.success('Experiment stopped');
      fetchExperiments();
    } else {
      toast.error('Failed to stop experiment');
    }
  };

  const handleDelete = async (id: string) => {
    const response = await deleteExperiment(id);
    if (response.success) {
      toast.success('Experiment deleted');
      fetchExperiments();
    } else {
      toast.error('Failed to delete experiment');
    }
    setDeleteDialog(null);
  };

  return (
    <div className="p-6 space-y-6 animate-fade-in">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold">Chaos Experiments</h2>
          <p className="text-muted-foreground">Manage and monitor your experiments</p>
        </div>
        <Button onClick={() => navigate('/experiments/new')}>
          <Plus className="w-4 h-4 mr-2" />
          New Experiment
        </Button>
      </div>

      <Card>
        <CardContent className="p-6 space-y-4">
          <div className="flex flex-col sm:flex-row gap-4">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
              <Input
                placeholder="Search by ID or target..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-9"
              />
            </div>
            <Select value={statusFilter} onValueChange={setStatusFilter}>
              <SelectTrigger className="w-full sm:w-[180px]">
                <SelectValue placeholder="Filter by status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="ALL">All Status</SelectItem>
                <SelectItem value="PENDING">Pending</SelectItem>
                <SelectItem value="RUNNING">Running</SelectItem>
                <SelectItem value="COMPLETED">Completed</SelectItem>
                <SelectItem value="FAILED">Failed</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {isLoading ? (
            <div className="flex justify-center py-12">
              <Loader2 className="w-8 h-8 animate-spin text-primary" />
            </div>
          ) : (
            <div className="border rounded-lg">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Experiment ID</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Target</TableHead>
                    <TableHead>Start Time</TableHead>
                    <TableHead>Duration</TableHead>
                    <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredExperiments.map((experiment) => (
                    <TableRow key={experiment.experimentId}>
                      <TableCell className="font-mono text-sm">{experiment.experimentId}</TableCell>
                      <TableCell>
                        <StatusBadge status={experiment.status} />
                      </TableCell>
                      <TableCell className="text-sm">{experiment.targetId}</TableCell>
                      <TableCell className="text-sm">
                        {format(new Date(experiment.startTime), 'MMM dd, yyyy HH:mm')}
                      </TableCell>
                      <TableCell className="text-sm">
                        {experiment.duration ? `${experiment.duration}s` : '-'}
                      </TableCell>
                      <TableCell className="text-right">
                        <div className="flex justify-end gap-2">
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => navigate(`/experiments/${experiment.experimentId}/monitor`)}
                          >
                            <Eye className="w-4 h-4" />
                          </Button>
                          {experiment.status === 'RUNNING' && (
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => handleStop(experiment.experimentId)}
                            >
                              <StopCircle className="w-4 h-4 text-danger" />
                            </Button>
                          )}
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => setDeleteDialog(experiment.experimentId)}
                          >
                            <Trash2 className="w-4 h-4 text-danger" />
                          </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          )}
        </CardContent>
      </Card>

      <AlertDialog open={!!deleteDialog} onOpenChange={() => setDeleteDialog(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete Experiment?</AlertDialogTitle>
            <AlertDialogDescription>
              This action cannot be undone. This will permanently delete the experiment record.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={() => deleteDialog && handleDelete(deleteDialog)}>
              Delete
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
