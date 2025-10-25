// API Request and Response Types
// These match the frontend types for seamless integration

export interface SystemHealth {
  status: 'healthy' | 'degraded' | 'critical';
  targetInstanceCount: number;
  healthyInstances: number;
  loadBalancerStatus: string;
  lastChecked: string;
}

export interface ExperimentConfiguration {
  dryRun: boolean;
  expectedHealthyInstances: number;
  failureType: string;
}

export interface ExperimentMetadata {
  name?: string;
  hypothesis?: string;
  owner?: string;
}

export interface Experiment {
  experimentId: string;
  status: 'PENDING' | 'RUNNING' | 'COMPLETED' | 'FAILED';
  targetType: string;
  targetId: string;
  configuration: ExperimentConfiguration;
  startTime: string;
  endTime?: string;
  duration?: number;
  createdBy: string;
  metadata?: ExperimentMetadata;
}

export interface MetricsSnapshot {
  healthyHostCount: number;
  responseTime: number;
  errorRate: number;
}

export interface ExperimentResult {
  resultId: string;
  experimentId: string;
  timestamp: string;
  success: boolean;
  targetInstance: string;
  recoveryTime: number;
  metricsSnapshot: MetricsSnapshot;
  logs: string[];
  stepFunctionOutput?: any;
}

export interface ExperimentStep {
  stepName: string;
  status: 'pending' | 'running' | 'completed' | 'failed';
  startTime?: string;
  endTime?: string;
  duration?: number;
  output?: any;
}

export interface User {
  userId: string;
  email: string;
  name: string;
  role: 'ADMIN' | 'OPERATOR' | 'VIEWER';
}

export interface ApiResponse<T> {
  success: boolean;
  data: T;
  message?: string;
  error?: string;
}

export interface CreateExperimentRequest {
  targetType: string;
  targetId: string;
  configuration: ExperimentConfiguration;
  metadata?: ExperimentMetadata;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface LoginResponse {
  token: string;
  user: User;
}

export interface Analytics {
  totalExperiments: number;
  successRate: number;
  averageRecoveryTime: number;
  last24hExperiments: number;
  experimentsOverTime: { date: string; count: number }[];
  successFailureByWeek: { week: string; success: number; failure: number }[];
  experimentTypeDistribution: { type: string; count: number }[];
}

export interface PaginationParams {
  page?: number;
  limit?: number;
}

export interface ExperimentQueryParams extends PaginationParams {
  status?: string;
  startDate?: string;
  endDate?: string;
}

export interface ResultQueryParams extends PaginationParams {
  experimentId?: string;
  startDate?: string;
  endDate?: string;
}
