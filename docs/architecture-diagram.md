# Architecture Diagrams

## Overall System Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          Chaos Engineering Platform                      │
└─────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────────┐
│                        CHAOS PLATFORM (Week 2-3)                         │
│                                                                           │
│  ┌─────────────┐    ┌──────────────────┐    ┌─────────────────────┐   │
│  │ EventBridge │───▶│  Step Functions  │───▶│  Lambda Functions   │   │
│  │  Scheduler  │    │  State Machine   │    │  - Get Target       │   │
│  └─────────────┘    └──────────────────┘    │  - Inject Failure   │   │
│                                               │  - Validate Health  │   │
│                                               └─────────────────────┘   │
│                            │                            │                │
│                            │                            │                │
│                            ▼                            ▼                │
│                     ┌──────────────┐          ┌──────────────┐         │
│                     │  CloudWatch  │          │     IAM      │         │
│                     │   Metrics    │          │    Roles     │         │
│                     └──────────────┘          └──────────────┘         │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ Chaos Experiments
                                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                      TARGET APPLICATION (Week 1)                         │
│                                                                           │
│                          ┌────────────────┐                              │
│                          │      Users     │                              │
│                          └────────┬───────┘                              │
│                                   │                                       │
│                                   ▼                                       │
│                    ┌──────────────────────────┐                          │
│                    │ Application Load Balancer │                         │
│                    │  (Internet-facing)        │                         │
│                    └──────────┬───────────────┘                          │
│                               │                                           │
│              ┌────────────────┴────────────────┐                         │
│              │                                  │                         │
│    ┌─────────▼────────┐              ┌────────▼─────────┐               │
│    │  Availability     │              │  Availability     │               │
│    │    Zone 1        │              │    Zone 2        │               │
│    │                   │              │                   │               │
│    │  ┌─────────────┐ │              │ ┌─────────────┐  │               │
│    │  │ EC2 Instance│ │              │ │ EC2 Instance│  │               │
│    │  │  (Apache)   │ │              │ │  (Apache)   │  │               │
│    │  │ ┌─────────┐ │ │              │ │ ┌─────────┐ │  │               │
│    │  │ │  Auto   │ │ │              │ │ │  Auto   │ │  │               │
│    │  │ │ Scaling │ │ │              │ │ │ Scaling │ │  │               │
│    │  │ │  Group  │ │ │              │ │ │  Group  │ │  │               │
│    │  │ └─────────┘ │ │              │ │ └─────────┘ │  │               │
│    │  └─────────────┘ │              │ └─────────────┘  │               │
│    │                   │              │                   │               │
│    └───────────────────┘              └───────────────────┘               │
│                                                                           │
│    VPC: 10.0.0.0/16                                                      │
│    - Public Subnets: 10.0.1.0/24, 10.0.2.0/24                           │
│    - Private Subnets: 10.0.11.0/24, 10.0.12.0/24                        │
└──────────────────────────────────────────────────────────────────────────┘
```

## Week 1: Target Application Architecture

```
                    Internet
                       │
                       ▼
              ┌────────────────┐
              │ Internet Gateway│
              └────────┬────────┘
                       │
        ┌──────────────┴──────────────┐
        │      VPC: 10.0.0.0/16       │
        │                              │
        │  ┌────────────────────────┐ │
        │  │Application Load Balancer│ │
        │  │ (Public Subnet 1 & 2)  │ │
        │  └──────────┬──────────────┘ │
        │             │                 │
        │    ┌────────┴────────┐       │
        │    │                 │       │
        │    ▼                 ▼       │
        │ ┌─────────┐      ┌─────────┐│
        │ │  AZ-1   │      │  AZ-2   ││
        │ │         │      │         ││
        │ │ ┌─────┐ │      │ ┌─────┐ ││
        │ │ │ EC2 │ │      │ │ EC2 │ ││
        │ │ │ Web │ │      │ │ Web │ ││
        │ │ └─────┘ │      │ └─────┘ ││
        │ │         │      │         ││
        │ │ Public  │      │ Public  ││
        │ │ Subnet  │      │ Subnet  ││
        │ └─────────┘      └─────────┘│
        │                              │
        │ ┌─────────┐      ┌─────────┐│
        │ │ Private │      │ Private ││
        │ │ Subnet  │      │ Subnet  ││
        │ │         │      │         ││
        │ │ (NAT GW)│      │ (NAT GW)││
        │ └─────────┘      └─────────┘│
        └──────────────────────────────┘
```

## Chaos Experiment Workflow (Week 3)

```
START
  │
  ▼
┌─────────────────────────┐
│ Check Pre-Experiment    │
│ Health                  │
│ (Validate-System-Health)│
└───────────┬─────────────┘
            │
            ▼
     ┌──────────────┐
     │   Healthy?   │
     └──┬────────┬──┘
   Yes  │        │  No
        │        │
        │        └──────────────┐
        ▼                       │
┌─────────────────────────┐    │
│ Select Target Instance  │    │
│ (Get-Target-Instance)   │    │
└───────────┬─────────────┘    │
            │                   │
            ▼                   │
┌─────────────────────────┐    │
│ Inject Failure          │    │
│ (Terminate Instance)    │    │
└───────────┬─────────────┘    │
            │                   │
            ▼                   │
┌─────────────────────────┐    │
│ Wait for Recovery       │    │
│ (2-3 minutes)           │    │
└───────────┬─────────────┘    │
            │                   │
            ▼                   │
┌─────────────────────────┐    │
│ Check Post-Experiment   │    │
│ Health                  │    │
│ (Validate-System-Health)│    │
└───────────┬─────────────┘    │
            │                   │
            ▼                   │
     ┌──────────────┐          │
     │  Recovered?  │          │
     └──┬────────┬──┘          │
   Yes  │        │  No         │
        │        │              │
        ▼        ▼              │
   ┌────────┐ ┌────────┐       │
   │SUCCESS │ │FAILURE │◄──────┘
   └────────┘ └────────┘
        │        │
        └────┬───┘
             │
             ▼
    ┌──────────────────┐
    │ Log Results to   │
    │ CloudWatch       │
    └──────────────────┘
             │
             ▼
           END
```

## Network Architecture Detail

```
┌──────────────────────────────────────────────────────────────┐
│                    AWS Region: us-east-1                      │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐│
│  │              VPC: chaos-platform-vpc                     ││
│  │              CIDR: 10.0.0.0/16                          ││
│  │                                                          ││
│  │  ┌───────────────────────┬───────────────────────┐     ││
│  │  │   Availability Zone   │   Availability Zone   │     ││
│  │  │       us-east-1a      │       us-east-1b      │     ││
│  │  │                       │                       │     ││
│  │  │  ┌─────────────────┐ │ ┌─────────────────┐  │     ││
│  │  │  │ Public Subnet   │ │ │ Public Subnet   │  │     ││
│  │  │  │ 10.0.1.0/24     │ │ │ 10.0.2.0/24     │  │     ││
│  │  │  │                 │ │ │                 │  │     ││
│  │  │  │ - ALB           │ │ │ - ALB           │  │     ││
│  │  │  │ - EC2 Instances │ │ │ - EC2 Instances │  │     ││
│  │  │  │ - NAT Gateway   │ │ │ - NAT Gateway   │  │     ││
│  │  │  └─────────────────┘ │ └─────────────────┘  │     ││
│  │  │                       │                       │     ││
│  │  │  ┌─────────────────┐ │ ┌─────────────────┐  │     ││
│  │  │  │ Private Subnet  │ │ │ Private Subnet  │  │     ││
│  │  │  │ 10.0.11.0/24    │ │ │ 10.0.12.0/24    │  │     ││
│  │  │  │                 │ │ │                 │  │     ││
│  │  │  │ (Reserved for   │ │ │ (Reserved for   │  │     ││
│  │  │  │  future use)    │ │ │  future use)    │  │     ││
│  │  │  └─────────────────┘ │ └─────────────────┘  │     ││
│  │  └───────────────────────┴───────────────────────┘     ││
│  │                                                          ││
│  │  Route Tables:                                          ││
│  │  - Public: 0.0.0.0/0 → Internet Gateway                ││
│  │  - Private AZ1: 0.0.0.0/0 → NAT Gateway 1              ││
│  │  - Private AZ2: 0.0.0.0/0 → NAT Gateway 2              ││
│  └──────────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────────┘
```

## Security Architecture

```
┌─────────────────────────────────────────────────────┐
│              Security Groups & IAM                   │
└─────────────────────────────────────────────────────┘

┌──────────────────────┐
│ ALB Security Group   │
│                      │
│ Inbound:             │
│  - HTTP (80): 0.0.0.0/0
│  - HTTPS (443): 0.0.0.0/0
│                      │
│ Outbound:            │
│  - All traffic       │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Web Server SG        │
│                      │
│ Inbound:             │
│  - HTTP (80): ALB SG │
│  - SSH (22): 0.0.0.0/0 (optional)
│                      │
│ Outbound:            │
│  - All traffic       │
└──────────────────────┘

┌──────────────────────────────────────┐
│ IAM Roles                            │
│                                      │
│ ┌──────────────────────────────────┐│
│ │ EC2 Instance Role                ││
│ │ - CloudWatchAgentServerPolicy    ││
│ │ - AmazonSSMManagedInstanceCore   ││
│ └──────────────────────────────────┘│
│                                      │
│ ┌──────────────────────────────────┐│
│ │ Lambda Execution Roles (Week 2)  ││
│ │ - Get-Target: ASG:Describe*      ││
│ │ - Inject-Failure: EC2:Terminate  ││
│ │   (Tag: ChaosTarget=true only)   ││
│ │ - Validate: CloudWatch:Get*      ││
│ └──────────────────────────────────┘│
└──────────────────────────────────────┘
```

## Monitoring & Observability

```
┌─────────────────────────────────────────────────┐
│              CloudWatch Metrics                  │
└─────────────────────────────────────────────────┘

Auto Scaling Group
├── GroupDesiredCapacity
├── GroupInServiceInstances
├── GroupMinSize
└── GroupMaxSize

Application Load Balancer
├── HealthyHostCount ◄── Critical for validation
├── UnHealthyHostCount ◄── Critical for validation
├── TargetResponseTime
├── HTTPCode_Target_2XX_Count
└── HTTPCode_Target_5XX_Count ◄── Error detection

EC2 Instances
├── CPUUtilization
├── NetworkIn
└── NetworkOut

┌─────────────────────────────────────────────────┐
│              CloudWatch Logs                     │
└─────────────────────────────────────────────────┘

/aws/vpc/chaos-platform
├── VPC Flow Logs

/aws/ec2/chaos-platform/httpd/
├── access
└── error

/aws/lambda/chaos-platform/ (Week 2)
├── get-target-instance
├── inject-failure
└── validate-system-health
```

## Tags Strategy

All resources are tagged for easy identification and chaos targeting:

```
Common Tags:
- Project: chaos-platform
- Name: <resource-specific-name>

Chaos Targeting Tags:
- ChaosTarget: true  ◄── Used by Lambda to identify valid targets
- ManagedBy: AutoScaling
```

This tagging strategy ensures the chaos platform only affects intended resources.
