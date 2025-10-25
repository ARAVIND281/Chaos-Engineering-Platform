// Application Configuration

export const APP_CONFIG = {
  // Application
  name: 'Chaos Engineering Platform API',
  version: '1.0.0',
  environment: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '3000', 10),

  // JWT
  jwt: {
    secret: process.env.JWT_SECRET || 'chaos-engineering-secret-key-change-in-production',
    expiresIn: process.env.JWT_EXPIRES_IN || '24h',
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
  },

  // CORS
  cors: {
    origin: process.env.CORS_ORIGIN || '*',
    credentials: true,
  },

  // Pagination
  pagination: {
    defaultLimit: 10,
    maxLimit: 100,
  },

  // Experiment defaults
  experiment: {
    defaultExpectedHealthyInstances: 2,
    defaultFailureType: 'INSTANCE_TERMINATION',
    recoveryWaitTime: 60, // seconds
  },

  // Polling intervals (for monitoring)
  polling: {
    stepFunctionStatus: 5000, // 5 seconds
    systemHealth: 30000, // 30 seconds
  },

  // Logging
  logging: {
    level: process.env.LOG_LEVEL || 'info',
  },
};

export const isDevelopment = () => APP_CONFIG.environment === 'development';
export const isProduction = () => APP_CONFIG.environment === 'production';
export const isTest = () => APP_CONFIG.environment === 'test';
