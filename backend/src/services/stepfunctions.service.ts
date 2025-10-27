import {
  SFNClient,
  StartExecutionCommand,
  DescribeExecutionCommand,
  StopExecutionCommand,
  GetExecutionHistoryCommand,
  ListExecutionsCommand,
  ExecutionStatus,
} from '@aws-sdk/client-sfn';
import { AWS_CONFIG, getStepFunctionsConfig } from '../config/aws.config';
import { CreateExperimentRequest, ExperimentStep } from '../types/api.types';

const client = new SFNClient(getStepFunctionsConfig());

export interface StepFunctionInput {
  autoScalingGroupName: string;
  loadBalancerArn?: string;
  targetGroupArn?: string;
  expectedHealthyInstances: number;
  dryRun: boolean;
  experimentId: string;
  metadata?: {
    name?: string;
    hypothesis?: string;
    owner?: string;
  };
}

export interface StepFunctionExecution {
  executionArn: string;
  startDate: Date;
  stopDate?: Date;
  status: ExecutionStatus;
  input: string;
  output?: string;
}

// Start a chaos experiment
export const startChaosExperiment = async (
  request: CreateExperimentRequest,
  experimentId: string
): Promise<{ executionArn: string }> => {
  const input: StepFunctionInput = {
    autoScalingGroupName: request.targetId,
    loadBalancerArn: AWS_CONFIG.loadBalancer.loadBalancerArn,
    targetGroupArn: AWS_CONFIG.loadBalancer.targetGroupArn,
    expectedHealthyInstances: request.configuration.expectedHealthyInstances,
    dryRun: request.configuration.dryRun,
    experimentId,
    metadata: request.metadata,
  };

  const command = new StartExecutionCommand({
    stateMachineArn: AWS_CONFIG.stepFunctions.stateMachineArn,
    input: JSON.stringify(input),
    name: experimentId, // Use experimentId as execution name
  });

  const response = await client.send(command);

  if (!response.executionArn) {
    throw new Error('Failed to start Step Functions execution');
  }

  return {
    executionArn: response.executionArn,
  };
};

// Get execution status
export const getExecutionStatus = async (
  executionArn: string
): Promise<StepFunctionExecution> => {
  const command = new DescribeExecutionCommand({
    executionArn,
  });

  const response = await client.send(command);

  return {
    executionArn: response.executionArn!,
    startDate: response.startDate!,
    stopDate: response.stopDate,
    status: response.status!,
    input: response.input!,
    output: response.output,
  };
};

// Stop an execution
export const stopExecution = async (
  executionArn: string,
  cause: string = 'User requested stop'
): Promise<void> => {
  const command = new StopExecutionCommand({
    executionArn,
    cause,
  });

  await client.send(command);
};

// Get execution history and parse steps
export const getExecutionSteps = async (executionArn: string): Promise<ExperimentStep[]> => {
  const command = new GetExecutionHistoryCommand({
    executionArn,
    maxResults: 100,
    reverseOrder: false,
  });

  const response = await client.send(command);

  if (!response.events || response.events.length === 0) {
    return [];
  }

  // Parse events into steps
  const steps: ExperimentStep[] = [];
  const stateMap = new Map<string, Partial<ExperimentStep>>();

  response.events.forEach((event) => {
    const type = event.type;
    const timestamp = event.timestamp;

    switch (type) {
      case 'TaskStateEntered':
        if (event.stateEnteredEventDetails?.name) {
          const name = event.stateEnteredEventDetails.name;
          stateMap.set(name, {
            stepName: name,
            status: 'running',
            startTime: timestamp?.toISOString(),
          });
        }
        break;

      case 'TaskStateExited':
        if (event.stateExitedEventDetails?.name) {
          const name = event.stateExitedEventDetails.name;
          const existing = stateMap.get(name) || {};
          const startTime = existing.startTime
            ? new Date(existing.startTime)
            : timestamp!;
          const duration = timestamp
            ? Math.floor((timestamp.getTime() - startTime.getTime()) / 1000)
            : undefined;

          stateMap.set(name, {
            ...existing,
            status: 'completed',
            endTime: timestamp?.toISOString(),
            duration,
          });
        }
        break;

      case 'TaskFailed':
        if (event.taskFailedEventDetails) {
          const previousId = event.previousEventId;
          // Find the corresponding state
          const failedEvent = response.events?.find(
            (e) => e.id === previousId
          );
          if (failedEvent?.stateEnteredEventDetails?.name) {
            const name = failedEvent.stateEnteredEventDetails.name;
            const existing = stateMap.get(name) || {};
            stateMap.set(name, {
              ...existing,
              stepName: name,
              status: 'failed',
              endTime: timestamp?.toISOString(),
            });
          }
        }
        break;
    }
  });

  // Convert map to array
  stateMap.forEach((step) => {
    if (step.stepName) {
      steps.push(step as ExperimentStep);
    }
  });

  return steps;
};

// List recent executions
export const listExecutions = async (
  maxResults: number = 10
): Promise<StepFunctionExecution[]> => {
  const command = new ListExecutionsCommand({
    stateMachineArn: AWS_CONFIG.stepFunctions.stateMachineArn,
    maxResults,
  });

  const response = await client.send(command);

  if (!response.executions || response.executions.length === 0) {
    return [];
  }

  return response.executions
    .filter((exec) => exec.executionArn && exec.startDate && exec.status)
    .map((exec) => ({
      executionArn: exec.executionArn!,
      startDate: exec.startDate!,
      stopDate: exec.stopDate,
      status: exec.status!,
      input: '',
      output: '',
    }));
};

// Get execution by experiment ID
export const getExecutionByExperimentId = async (
  experimentId: string
): Promise<StepFunctionExecution | null> => {
  try {
    // The execution name is the experimentId
    const executionArn = `${AWS_CONFIG.stepFunctions.stateMachineArn.replace(':stateMachine:', ':execution:')}:${experimentId}`;
    return await getExecutionStatus(executionArn);
  } catch (error) {
    return null;
  }
};
