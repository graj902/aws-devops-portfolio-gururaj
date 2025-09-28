output "db_endpoint" {
  description = "The connection endpoint for the RDS instance."
  value       = aws_db_instance.main.endpoint
}

output "db_port" {
  description = "The port for the RDS instance."
  value       = aws_db_instance.main.port
}

output "db_name" {
  description = "The database name."
  value       = aws_db_instance.main.db_name
}
output "db_instance_id" {
  description = "The identifier of the RDS instance."
  value       = aws_db_instance.main.id
}