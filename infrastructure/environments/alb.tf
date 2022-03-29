/******************************************************************************
* ALB Security group
*******************************************************************************/
/**
* A security group to allow HTTP access into our alb instance.
*/
resource "aws_security_group" "alb" {
  name = "alb-security-group-us-east-1a"
  vpc_id = module.vpc.vpc_id

  ingress {
    protocol = "tcp"
    from_port = 80
    to_port = 80
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    protocol = -1
    from_port = 0
    to_port = 0
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  tags = {
    Application = "ceros-ski" 
    Environment = var.environment 
    Resource = "modules.aws_security_group.alb"
  }

}


resource "aws_lb" "alb" {  
  name            = "ceros-ski-${var.environment}-backend"
  internal        = false
  load_balancer_type = "application"
  #subnets = aws_subnet.public_subnet.id
  subnets = module.vpc.public_subnets[*]
  security_groups = [aws_security_group.alb.id]
  
  tags = {
    Application = "ceros-ski" 
    Environment = var.environment 
    Name = "ceros-ski-${var.environment}-us-east-1a-public"
    Resource = "modules.availability_zone.aws_subnet.public_subnet"
  }
}

/** Introduced ALB due to IAM roles are only valid for services configured to use load balancers error **/

resource "aws_lb_target_group" "cluster" {
  name     = "ceros-ski-${var.environment}-backend"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    healthy_threshold   = "3"
    interval            = "300"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/"
    unhealthy_threshold = "2"
  }

  tags = {
    Application = "ceros-ski" 
    Environment = var.environment 
    Name = "ceros-ski-${var.environment}-backend"
    Resource = "modules.environment.aws_ecs_task_definition.backend"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.alb.arn
  
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cluster.arn
  }
}

resource "aws_lb_listener_rule" "static" {
  listener_arn = aws_lb_listener.front_end.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cluster.arn
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}
