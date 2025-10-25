import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { queryExperiments } from '../../services/dynamodb.service';
import { ExperimentQueryParams } from '../../types/api.types';
import { success, serverError } from '../../utils/response';
import { logger } from '../../utils/logger';

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  try {
    logger.info('Listing experiments', { queryParams: event.queryStringParameters });

    // Parse query parameters
    const params: ExperimentQueryParams = {
      status: event.queryStringParameters?.status,
      startDate: event.queryStringParameters?.startDate,
      endDate: event.queryStringParameters?.endDate,
      page: event.queryStringParameters?.page
        ? parseInt(event.queryStringParameters.page, 10)
        : 1,
      limit: event.queryStringParameters?.limit
        ? parseInt(event.queryStringParameters.limit, 10)
        : 10,
    };

    // Query experiments
    const experiments = await queryExperiments(params);

    logger.info(`Found ${experiments.length} experiments`);

    return success(experiments);
  } catch (error) {
    logger.error('Error listing experiments', error);
    return serverError('Failed to retrieve experiments');
  }
};
