output "primary_endpoint_address" {
  description = "The connection endpoint for the Redis replication group's primary node."
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "port" {
  description = "The port for the Redis replication group."
  value       = aws_elasticache_replication_group.main.port
}