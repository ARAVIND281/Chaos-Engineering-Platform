import { ApiResponse } from '../types/api.types';

export const successResponse = <T>(
  data: T,
  message?: string
): ApiResponse<T> => ({
  success: true,
  data,
  message,
});

export const errorResponse = <T = any>(
  error: string,
  data?: T
): ApiResponse<T> => ({
  success: false,
  data: data as T,
  error,
});

export const formatLambdaResponse = (
  statusCode: number,
  body: any,
  headers: Record<string, string> = {}
) => ({
  statusCode,
  headers: {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Credentials': true,
    ...headers,
  },
  body: JSON.stringify(body),
});

export const success = <T>(data: T, message?: string, statusCode: number = 200) =>
  formatLambdaResponse(statusCode, successResponse(data, message));

export const error = (message: string, statusCode: number = 500) =>
  formatLambdaResponse(statusCode, errorResponse(message));

export const badRequest = (message: string = 'Bad Request') =>
  error(message, 400);

export const unauthorized = (message: string = 'Unauthorized') =>
  error(message, 401);

export const forbidden = (message: string = 'Forbidden') =>
  error(message, 403);

export const notFound = (message: string = 'Not Found') =>
  error(message, 404);

export const serverError = (message: string = 'Internal Server Error') =>
  error(message, 500);
