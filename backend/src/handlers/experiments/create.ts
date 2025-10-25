import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { v4 as uuidv4 } from 'uuid';
import { createExperiment } from '../../services/dynamodb.service';
import { startChaosExperiment } from '../../services/stepfunctions.service';
import { CreateExperimentRequest, Experiment } from '../../types/api.types';
import { success, badRequest, serverError } from '../../utils/response';
import { logger } from '../../utils/logger';

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  try {
    logger.info('Creating new experiment', { event });

    // Parse request body
    if (!event.body) {
      return badRequest('Request body is required');
    }

    const request: CreateExperimentRequest = JSON.parse(event.body);

    // Validate request
    if (!request.targetType || !request.targetId || !request.configuration) {
      return badRequest('Missing required fields: targetType, targetId, configuration');
    }

    // Get user from JWT claims (populated by authorizer)
    const userEmail =
      event.requestContext.authorizer?.claims?.email || 'system@chaos-platform.com';
    const userId = event.requestContext.authorizer?.claims?.sub || 'system';

    // Generate experiment ID
    const experimentId = `exp-${new Date().toISOString().split('T')[0]}-${uuidv4().substring(0, 8)}`;

    // Create experiment object
    const experiment: Experiment = {
      experimentId,
      status: 'PENDING',
      targetType: request.targetType,
      targetId: request.targetId,
      configuration: {
        dryRun: request.configuration.dryRun ?? false,
        expectedHealthyInstances: request.configuration.expectedHealthyInstances ?? 2,
        failureType: request.configuration.failureType ?? 'INSTANCE_TERMINATION',
      },
      startTime: new Date().toISOString(),
      createdBy: userEmail,
      metadata: request.metadata,
    };

    // Save to DynamoDB
    await createExperiment(experiment);
    logger.info('Experiment created in DynamoDB', { experimentId });

    // Start Step Functions execution
    try {
      const { executionArn } = await startChaosExperiment(request, experimentId);
      logger.info('Step Functions execution started', { experimentId, executionArn });

      // Update experiment status to RUNNING
      experiment.status = 'RUNNING';
    } catch (error) {
      logger.error('Failed to start Step Functions execution', error);
      experiment.status = 'FAILED';
    }

    return success(experiment, 'Experiment started successfully', 201);
  } catch (error) {
    logger.error('Error creating experiment', error);
    return serverError('Failed to create experiment');
  }
};
