output "alb_id" {
  description = "The alb hostname"
  value = aws_lb.alb.dns_name
}

output "cluster_arn" {
  description = "The ARN of the created ECS cluster."
  value       = aws_ecs_cluster.cluster.arn
}