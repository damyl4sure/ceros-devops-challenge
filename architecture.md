# Architecture

The infrastructure for the Ceros-ski game is constructed in two, interdependent
pieces that must be deployed separately.  The first is the ECR repository that
will store the built docker images for the ceros-ski container.  The second is
the ECS Cluster that will run those docker images.

The ECS Cluster is currently built to use an EC2 Autoscaling group that sits in
a private VPC in a single availability zone.  It has a single service and a
single task definition.

The ECR Repository is defined in `infrastructure/repositories`.

The ECS Cluster is defined in `infrastructure/environments`.

All are currently configured to use local state.
