/******************************************************************************
* ECS Cluster
*
* Create ECS Cluster and its supporting services, in this case EC2 instances in
* and Autoscaling group.
*
* *****************************************************************************/

/**
* The ECS Cluster and its services and task groups. 
*
* The ECS Cluster has no dependencies, but will be referenced in the launch
* configuration, may as well define it first for clarity's sake.
*/

resource "aws_ecs_cluster" "cluster" {
  name = "ceros-ski-${var.environment}"

  tags = {
    Application = "ceros-ski"
    Environment = var.environment
    Resource = "modules.ecs.cluster.aws_ecs_cluster.cluster"
  }
}

/*******************************************************************************
* AutoScaling Group
*
* The autoscaling group that will generate the instances used by the ECS
* cluster.
*
********************************************************************************/

/**
* The IAM policy needed by the ecs agent to allow it to manage the instances
* that back the cluster.  This is the terraform structure that defines the
* policy.
*/
data "aws_iam_policy_document" "ecs_agent" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeTags",
      "ecs:CreateCluster",
      "ecs:DeregisterContainerInstance",
      "ecs:DiscoverPollEndpoint",
      "ecs:Poll",
      "ecs:RegisterContainerInstance",
      "ecs:StartTelemetrySession",
      "ecs:UpdateContainerInstancesState",
      "ecs:Submit*",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "*"
    ]
  }
}

/**
* The policy resource itself.  Uses the policy document defined above.
*/
resource "aws_iam_policy" "ecs_agent" {
  name = "ceros-ski-ecs-agent-policy"
  path = "/"
  description = "Access policy for the EC2 instances backing the ECS cluster."

  policy = data.aws_iam_policy_document.ecs_agent.json
}

/**
* A policy document defining the assume role policy for the IAM role below.
* This is required.
*/
data "aws_iam_policy_document" "ecs_agent_assume_role_policy" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }

}

/**
* The IAM role that will be used by the instances that back the ECS Cluster.
*/
resource "aws_iam_role" "ecs_agent" {
  name = "ceros-ski-ecs-agent"
  path = "/"

  assume_role_policy = data.aws_iam_policy_document.ecs_agent_assume_role_policy.json
}

/**
* Attatch the ecs_agent policy to the role.  The assume_role policy is attached
* above in the role itself.
*/
resource "aws_iam_role_policy_attachment" "ecs_agent" {
  role = aws_iam_role.ecs_agent.name 
  policy_arn = aws_iam_policy.ecs_agent.arn 
}

/**
* The Instance Profile that associates the IAM resources we just finished
* defining with the launch configuration.
*/
resource "aws_iam_instance_profile" "ecs_agent" {
  name = "ceros-ski-ecs-agent"
  role = aws_iam_role.ecs_agent.name 
}

/**
* A security group for the instances in the autoscaling group allowing HTTP
* ingress.  With out this the Target Group won't be able to reach the instances
* (and thus the containers) and the health checks will fail, causing the
* instances to be deregistered.
*/
resource "aws_security_group" "autoscaling_group" {
  name        = "ceros-ski-${var.environment}-autoscaling_group"
  description = "Security Group for the Autoscaling group which provides the instances for the ECS Cluster."
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP Ingress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Application = "ceros-ski"
    Environment = var.environment
    Resource = "modules.ecs.cluster.aws_security_group.autoscaling_group"
  }
}

/** 
* This parameter contains the AMI ID of the ECS Optimized version of Amazon
* Linux 2 maintained by AWS.  We'll use it to launch the instances that back
* our ECS cluster.
*/
data "aws_ssm_parameter" "cluster_ami_id" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

/**
* The launch configuration for the autoscaling group that backs our cluster.  
*/
resource "aws_launch_configuration" "cluster" {
  name = "ceros-ski-${var.environment}-cluster"
  image_id = data.aws_ssm_parameter.cluster_ami_id.value 
  instance_type = "t3.micro"
  iam_instance_profile = aws_iam_instance_profile.ecs_agent.name
  security_groups = [aws_security_group.autoscaling_group.id]

  // Register our EC2 instances with the correct ECS cluster.
  user_data = <<EOF
#!/bin/bash
echo "ECS_CLUSTER=${aws_ecs_cluster.cluster.name}" >> /etc/ecs/ecs.config
EOF
}

/**
* The autoscaling group that backs our ECS cluster.
*/
resource "aws_autoscaling_group" "cluster" {

  name = "ceros-ski-${var.environment}-cluster"
  min_size = 2
  max_size = 3
  
  vpc_zone_identifier = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]
  launch_configuration = aws_launch_configuration.cluster.name 

  tags = [{
    "key" = "Application"
    "value" = "ceros-ski"
    "propagate_at_launch" = true
  },
  {
    "key" = "Environment"
    "value" = var.environment
    "propagate_at_launch" = true
  },
  {
    "key" = "Resource"
    "value" = "modules.ecs.cluster.aws_autoscaling_group.cluster"
    "propagate_at_launch" = true
  }]
}

/**
* Create the task definition for the ceros-ski backend, in this case a thin
* wrapper around the container definition.
*/
resource "aws_ecs_task_definition" "backend" {
  family = "ceros-ski-${var.environment}-backend"
  network_mode = "bridge"

  container_definitions = <<EOF
[
  {
    "name": "ceros-ski",
    "image": "${var.repository_url}:latest",
    "environment": [
      {
        "name": "PORT",
        "value": "8080"
      }
    ],
    "cpu": 512,
    "memoryReservation": 512,
    "essential": true,
    "portMappings": [
      {
        "containerPort": 8080,
        "hostPort": 8080,
        "protocol": "tcp"
      }
    ]
  }
]
EOF

  tags = {
    Application = "ceros-ski" 
    Environment = var.environment 
    Name = "ceros-ski-${var.environment}-backend"
    Resource = "modules.environment.aws_ecs_task_definition.backend"
  }
}


/**
* This role is automatically created by ECS the first time we try to use an ECS
* Cluster.  By the time we attempt to use it, it should exist.  However, there
* is a possible TECHDEBT race condition here.  I'm hoping terraform is smart
* enough to handle this - but I don't know that for a fact. By the time I tried
* to use it, it already existed.
*/
data "aws_iam_role" "ecs_service" {
  name = "AWSServiceRoleForECS"
}

/**
* Create the ECS Service that will wrap the task definition.  Used primarily to
* define the connections to the load balancer and the placement strategies and
* constraints on the tasks.
*/
resource "aws_ecs_service" "backend" {
  name = "ceros-ski-${var.environment}-backend"
  cluster = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.backend.arn

  #iam_role        = data.aws_iam_role.ecs_service.arn
  depends_on      = [
    aws_iam_role.ecs_agent,
    aws_lb_listener.front_end,
  ]
  
  desired_count = 2 
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent = 100

  # network_configuration {
  #   subnets          = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]
  #   assign_public_ip = false
  #   security_groups = [
  #     aws_security_group.autoscaling_group.id,
  #     aws_security_group.alb.id
  #   ]
  # }

  load_balancer {
    target_group_arn = aws_lb_target_group.cluster.arn
    container_name   = "ceros-ski"
    container_port   = 8080

  }

  force_new_deployment = true

  tags = {
    Application = "ceros-ski" 
    Environment = var.environment 
    Resource = "modules.environment.aws_ecs_service.backend"
  }
}

# Attach autoscalling group to ALB backend target

resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = "${aws_autoscaling_group.cluster.id}"
  alb_target_group_arn   = "${aws_lb_target_group.cluster.arn}"
}