import { APP_CONFIG } from '../config/app.config';

type LogLevel = 'debug' | 'info' | 'warn' | 'error';

const logLevels: Record<LogLevel, number> = {
  debug: 0,
  info: 1,
  warn: 2,
  error: 3,
};

const currentLogLevel = (APP_CONFIG.logging.level as LogLevel) || 'info';

const shouldLog = (level: LogLevel): boolean => {
  return logLevels[level] >= logLevels[currentLogLevel];
};

const formatMessage = (level: LogLevel, message: string, meta?: any): string => {
  const timestamp = new Date().toISOString();
  const metaStr = meta ? ` ${JSON.stringify(meta)}` : '';
  return `[${timestamp}] [${level.toUpperCase()}] ${message}${metaStr}`;
};

export const logger = {
  debug: (message: string, meta?: any) => {
    if (shouldLog('debug')) {
      console.log(formatMessage('debug', message, meta));
    }
  },

  info: (message: string, meta?: any) => {
    if (shouldLog('info')) {
      console.log(formatMessage('info', message, meta));
    }
  },

  warn: (message: string, meta?: any) => {
    if (shouldLog('warn')) {
      console.warn(formatMessage('warn', message, meta));
    }
  },

  error: (message: string, error?: any) => {
    if (shouldLog('error')) {
      const errorInfo = error instanceof Error
        ? { message: error.message, stack: error.stack }
        : error;
      console.error(formatMessage('error', message, errorInfo));
    }
  },
};
