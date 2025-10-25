// AWS SDK Configuration

export const AWS_CONFIG = {
  region: process.env.AWS_REGION || 'us-east-1',

  // DynamoDB Table Names
  tables: {
    experiments: process.env.EXPERIMENTS_TABLE || 'chaos-experiments',
    results: process.env.RESULTS_TABLE || 'chaos-results',
    users: process.env.USERS_TABLE || 'chaos-users',
  },

  // Step Functions
  stepFunctions: {
    stateMachineArn: process.env.STATE_MACHINE_ARN || '',
  },

  // Auto Scaling
  autoScaling: {
    targetAsgName: process.env.TARGET_ASG_NAME || 'chaos-target-asg',
  },

  // Load Balancer
  loadBalancer: {
    targetGroupArn: process.env.TARGET_GROUP_ARN || '',
    loadBalancerArn: process.env.LOAD_BALANCER_ARN || '',
  },

  // Cognito
  cognito: {
    userPoolId: process.env.COGNITO_USER_POOL_ID || '',
    clientId: process.env.COGNITO_CLIENT_ID || '',
  },
};

export const getDynamoDBConfig = () => ({
  region: AWS_CONFIG.region,
});

export const getStepFunctionsConfig = () => ({
  region: AWS_CONFIG.region,
});

export const getCloudWatchConfig = () => ({
  region: AWS_CONFIG.region,
});
