import {
  DynamoDBClient,
  PutItemCommand,
  GetItemCommand,
  QueryCommand,
  UpdateItemCommand,
  DeleteItemCommand,
  ScanCommand,
} from '@aws-sdk/client-dynamodb';
import { marshall, unmarshall } from '@aws-sdk/util-dynamodb';
import { AWS_CONFIG, getDynamoDBConfig } from '../config/aws.config';
import {
  Experiment,
  ExperimentResult,
  User,
  ExperimentQueryParams,
  ResultQueryParams,
} from '../types/api.types';

const client = new DynamoDBClient(getDynamoDBConfig());

// ========== Experiments Table ==========

export const createExperiment = async (experiment: Experiment): Promise<Experiment> => {
  const command = new PutItemCommand({
    TableName: AWS_CONFIG.tables.experiments,
    Item: marshall(experiment, { removeUndefinedValues: true }),
  });

  await client.send(command);
  return experiment;
};

export const getExperiment = async (experimentId: string): Promise<Experiment | null> => {
  const command = new GetItemCommand({
    TableName: AWS_CONFIG.tables.experiments,
    Key: marshall({ experimentId }),
  });

  const response = await client.send(command);

  if (!response.Item) {
    return null;
  }

  return unmarshall(response.Item) as Experiment;
};

export const updateExperiment = async (
  experimentId: string,
  updates: Partial<Experiment>
): Promise<Experiment | null> => {
  // Build update expression
  const updateExpressions: string[] = [];
  const expressionAttributeNames: Record<string, string> = {};
  const expressionAttributeValues: Record<string, any> = {};

  Object.entries(updates).forEach(([key, value], index) => {
    if (key !== 'experimentId') {
      updateExpressions.push(`#attr${index} = :val${index}`);
      expressionAttributeNames[`#attr${index}`] = key;
      expressionAttributeValues[`:val${index}`] = value;
    }
  });

  if (updateExpressions.length === 0) {
    return getExperiment(experimentId);
  }

  const command = new UpdateItemCommand({
    TableName: AWS_CONFIG.tables.experiments,
    Key: marshall({ experimentId }),
    UpdateExpression: `SET ${updateExpressions.join(', ')}`,
    ExpressionAttributeNames: expressionAttributeNames,
    ExpressionAttributeValues: marshall(expressionAttributeValues),
    ReturnValues: 'ALL_NEW',
  });

  const response = await client.send(command);

  if (!response.Attributes) {
    return null;
  }

  return unmarshall(response.Attributes) as Experiment;
};

export const deleteExperiment = async (experimentId: string): Promise<void> => {
  const command = new DeleteItemCommand({
    TableName: AWS_CONFIG.tables.experiments,
    Key: marshall({ experimentId }),
  });

  await client.send(command);
};

export const queryExperiments = async (
  params: ExperimentQueryParams
): Promise<Experiment[]> => {
  // For now, use Scan. In production, consider using GSI for efficient queries
  const command = new ScanCommand({
    TableName: AWS_CONFIG.tables.experiments,
    Limit: params.limit || 10,
  });

  const response = await client.send(command);

  if (!response.Items) {
    return [];
  }

  let experiments = response.Items.map((item) => unmarshall(item) as Experiment);

  // Apply filters
  if (params.status && params.status !== 'ALL') {
    experiments = experiments.filter((exp) => exp.status === params.status);
  }

  if (params.startDate) {
    experiments = experiments.filter((exp) => exp.startTime >= params.startDate!);
  }

  if (params.endDate) {
    experiments = experiments.filter(
      (exp) => exp.endTime && exp.endTime <= params.endDate!
    );
  }

  // Sort by startTime descending
  experiments.sort((a, b) => new Date(b.startTime).getTime() - new Date(a.startTime).getTime());

  return experiments;
};

// ========== Results Table ==========

export const createResult = async (result: ExperimentResult): Promise<ExperimentResult> => {
  const command = new PutItemCommand({
    TableName: AWS_CONFIG.tables.results,
    Item: marshall(result, { removeUndefinedValues: true }),
  });

  await client.send(command);
  return result;
};

export const getResult = async (resultId: string): Promise<ExperimentResult | null> => {
  const command = new GetItemCommand({
    TableName: AWS_CONFIG.tables.results,
    Key: marshall({ resultId }),
  });

  const response = await client.send(command);

  if (!response.Item) {
    return null;
  }

  return unmarshall(response.Item) as ExperimentResult;
};

export const queryResults = async (params: ResultQueryParams): Promise<ExperimentResult[]> => {
  // If experimentId is provided, use Query with GSI
  if (params.experimentId) {
    const command = new QueryCommand({
      TableName: AWS_CONFIG.tables.results,
      IndexName: 'ExperimentIdIndex', // GSI on experimentId
      KeyConditionExpression: 'experimentId = :experimentId',
      ExpressionAttributeValues: marshall({
        ':experimentId': params.experimentId,
      }),
      Limit: params.limit || 10,
      ScanIndexForward: false, // Sort descending by sort key (timestamp)
    });

    const response = await client.send(command);

    if (!response.Items) {
      return [];
    }

    return response.Items.map((item) => unmarshall(item) as ExperimentResult);
  }

  // Otherwise, use Scan
  const command = new ScanCommand({
    TableName: AWS_CONFIG.tables.results,
    Limit: params.limit || 10,
  });

  const response = await client.send(command);

  if (!response.Items) {
    return [];
  }

  let results = response.Items.map((item) => unmarshall(item) as ExperimentResult);

  // Apply filters
  if (params.startDate) {
    results = results.filter((res) => res.timestamp >= params.startDate!);
  }

  if (params.endDate) {
    results = results.filter((res) => res.timestamp <= params.endDate!);
  }

  // Sort by timestamp descending
  results.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());

  return results;
};

export const getResultsByExperimentId = async (
  experimentId: string
): Promise<ExperimentResult[]> => {
  return queryResults({ experimentId });
};

// ========== Users Table ==========

export const createUser = async (user: User): Promise<User> => {
  const command = new PutItemCommand({
    TableName: AWS_CONFIG.tables.users,
    Item: marshall(user, { removeUndefinedValues: true }),
  });

  await client.send(command);
  return user;
};

export const getUser = async (userId: string): Promise<User | null> => {
  const command = new GetItemCommand({
    TableName: AWS_CONFIG.tables.users,
    Key: marshall({ userId }),
  });

  const response = await client.send(command);

  if (!response.Item) {
    return null;
  }

  return unmarshall(response.Item) as User;
};

export const getUserByEmail = async (email: string): Promise<User | null> => {
  // Use GSI on email
  const command = new QueryCommand({
    TableName: AWS_CONFIG.tables.users,
    IndexName: 'EmailIndex', // GSI on email
    KeyConditionExpression: 'email = :email',
    ExpressionAttributeValues: marshall({
      ':email': email,
    }),
  });

  const response = await client.send(command);

  if (!response.Items || response.Items.length === 0) {
    return null;
  }

  return unmarshall(response.Items[0]) as User;
};

export const updateUser = async (userId: string, updates: Partial<User>): Promise<User | null> => {
  const updateExpressions: string[] = [];
  const expressionAttributeNames: Record<string, string> = {};
  const expressionAttributeValues: Record<string, any> = {};

  Object.entries(updates).forEach(([key, value], index) => {
    if (key !== 'userId') {
      updateExpressions.push(`#attr${index} = :val${index}`);
      expressionAttributeNames[`#attr${index}`] = key;
      expressionAttributeValues[`:val${index}`] = value;
    }
  });

  if (updateExpressions.length === 0) {
    return getUser(userId);
  }

  const command = new UpdateItemCommand({
    TableName: AWS_CONFIG.tables.users,
    Key: marshall({ userId }),
    UpdateExpression: `SET ${updateExpressions.join(', ')}`,
    ExpressionAttributeNames: expressionAttributeNames,
    ExpressionAttributeValues: marshall(expressionAttributeValues),
    ReturnValues: 'ALL_NEW',
  });

  const response = await client.send(command);

  if (!response.Attributes) {
    return null;
  }

  return unmarshall(response.Attributes) as User;
};
