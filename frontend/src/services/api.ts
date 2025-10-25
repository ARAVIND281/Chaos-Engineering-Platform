import {
  ApiResponse,
  SystemHealth,
  Experiment,
  ExperimentResult,
  ExperimentStep,
  User,
  CreateExperimentRequest,
  LoginRequest,
  LoginResponse,
  Analytics,
} from '@/types/api';
import {
  mockUser,
  mockSystemHealth,
  mockExperiments,
  mockResults,
  mockExperimentSteps,
  mockAnalytics,
} from './mockData';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000/api/v1';

// Simulate API delay
const delay = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));

// Authentication
export const login = async (email: string, password: string): Promise<ApiResponse<LoginResponse>> => {
  await delay(800);
  
  // Mock authentication - accept any email/password
  if (email && password) {
    const token = 'mock-jwt-token-' + Date.now();
    localStorage.setItem('auth_token', token);
    
    return {
      success: true,
      data: {
        token,
        user: mockUser,
      },
    };
  }
  
  return {
    success: false,
    data: { token: '', user: mockUser },
    error: 'Invalid credentials',
  };
};

export const logout = async (): Promise<void> => {
  await delay(300);
  localStorage.removeItem('auth_token');
};

export const getCurrentUser = async (): Promise<ApiResponse<User>> => {
  await delay(300);
  const token = localStorage.getItem('auth_token');
  
  if (token) {
    return {
      success: true,
      data: mockUser,
    };
  }
  
  return {
    success: false,
    data: mockUser,
    error: 'Not authenticated',
  };
};

// System Health
export const getSystemHealth = async (): Promise<ApiResponse<SystemHealth>> => {
  await delay(500);
  
  return {
    success: true,
    data: {
      ...mockSystemHealth,
      lastChecked: new Date().toISOString(),
    },
  };
};

// Experiments
export const getExperiments = async (params?: {
  status?: string;
  startDate?: string;
  endDate?: string;
  page?: number;
  limit?: number;
}): Promise<ApiResponse<Experiment[]>> => {
  await delay(600);
  
  let filtered = [...mockExperiments];
  
  if (params?.status && params.status !== 'ALL') {
    filtered = filtered.filter(exp => exp.status === params.status);
  }
  
  return {
    success: true,
    data: filtered,
  };
};

export const getExperiment = async (id: string): Promise<ApiResponse<Experiment>> => {
  await delay(400);
  
  const experiment = mockExperiments.find(exp => exp.experimentId === id);
  
  if (experiment) {
    return {
      success: true,
      data: experiment,
    };
  }
  
  return {
    success: false,
    data: mockExperiments[0],
    error: 'Experiment not found',
  };
};

export const createExperiment = async (data: CreateExperimentRequest): Promise<ApiResponse<Experiment>> => {
  await delay(1000);
  
  const newExperiment: Experiment = {
    experimentId: `exp-${new Date().toISOString().split('T')[0]}-${Math.random().toString(36).substr(2, 9)}`,
    status: 'RUNNING',
    targetType: data.targetType,
    targetId: data.targetId,
    configuration: data.configuration,
    startTime: new Date().toISOString(),
    createdBy: mockUser.email,
    metadata: data.metadata,
  };
  
  mockExperiments.unshift(newExperiment);
  
  return {
    success: true,
    data: newExperiment,
    message: 'Experiment started successfully',
  };
};

export const stopExperiment = async (id: string): Promise<ApiResponse<Experiment>> => {
  await delay(800);
  
  const experiment = mockExperiments.find(exp => exp.experimentId === id);
  
  if (experiment) {
    experiment.status = 'COMPLETED';
    experiment.endTime = new Date().toISOString();
    experiment.duration = 60;
    
    return {
      success: true,
      data: experiment,
      message: 'Experiment stopped',
    };
  }
  
  return {
    success: false,
    data: mockExperiments[0],
    error: 'Experiment not found',
  };
};

export const deleteExperiment = async (id: string): Promise<ApiResponse<void>> => {
  await delay(500);
  
  const index = mockExperiments.findIndex(exp => exp.experimentId === id);
  
  if (index !== -1) {
    mockExperiments.splice(index, 1);
    
    return {
      success: true,
      data: undefined,
      message: 'Experiment deleted',
    };
  }
  
  return {
    success: false,
    data: undefined,
    error: 'Experiment not found',
  };
};

// Experiment Monitoring
export const getExperimentStatus = async (id: string): Promise<ApiResponse<Experiment>> => {
  await delay(300);
  
  const experiment = mockExperiments.find(exp => exp.experimentId === id);
  
  if (experiment) {
    return {
      success: true,
      data: experiment,
    };
  }
  
  return {
    success: false,
    data: mockExperiments[0],
    error: 'Experiment not found',
  };
};

export const getExperimentSteps = async (id: string): Promise<ApiResponse<ExperimentStep[]>> => {
  await delay(400);
  
  return {
    success: true,
    data: mockExperimentSteps,
  };
};

// Results
export const getResults = async (params?: {
  experimentId?: string;
  startDate?: string;
  endDate?: string;
  page?: number;
  limit?: number;
}): Promise<ApiResponse<ExperimentResult[]>> => {
  await delay(600);
  
  let filtered = [...mockResults];
  
  if (params?.experimentId) {
    filtered = filtered.filter(result => result.experimentId === params.experimentId);
  }
  
  return {
    success: true,
    data: filtered,
  };
};

export const getResult = async (id: string): Promise<ApiResponse<ExperimentResult>> => {
  await delay(400);
  
  const result = mockResults.find(res => res.resultId === id);
  
  if (result) {
    return {
      success: true,
      data: result,
    };
  }
  
  return {
    success: false,
    data: mockResults[0],
    error: 'Result not found',
  };
};

export const getAnalytics = async (): Promise<ApiResponse<Analytics>> => {
  await delay(700);
  
  return {
    success: true,
    data: mockAnalytics,
  };
};

export const exportResults = async (format: 'csv' | 'json'): Promise<ApiResponse<Blob>> => {
  await delay(1000);
  
  const data = format === 'json' ? JSON.stringify(mockResults, null, 2) : 'CSV data here';
  const blob = new Blob([data], { type: format === 'json' ? 'application/json' : 'text/csv' });
  
  return {
    success: true,
    data: blob,
  };
};
