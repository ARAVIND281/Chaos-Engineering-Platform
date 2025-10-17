# Step Functions Workflow

This directory contains the AWS Step Functions state machine definition for orchestrating chaos experiments.

## Week 3 Development

The Step Functions state machine will be developed in Week 3 to orchestrate the chaos experiment workflow.

### Workflow Steps

1. **Start** - Experiment initialization
2. **Check Pre-Experiment Health** - Validate system is healthy before testing
3. **Select Target** - Choose a random EC2 instance
4. **Inject Failure** - Terminate the selected instance
5. **Wait** - Allow time for auto-scaling recovery (2-3 minutes)
6. **Check Post-Experiment Health** - Validate system recovered
7. **Report Result** - Log success or failure

### State Machine Definition

The state machine will be defined in JSON using Amazon States Language (ASL).

File: `chaos-experiment-workflow.json`

### Integration Points

- **Lambda Functions**: All three functions from Week 2
- **CloudWatch**: For logging and metrics
- **EventBridge**: For scheduling (optional cron trigger)

## Deployment

The Step Functions state machine will be deployed via CloudFormation in Week 3.
