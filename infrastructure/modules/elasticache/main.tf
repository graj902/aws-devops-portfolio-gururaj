# Create a dedicated security group for the ElastiCache cluster
resource "aws_security_group" "redis" {
  name        = "${var.project_name}-redis-sg"
  description = "Allow Redis traffic from the EKS cluster"
  vpc_id      = var.vpc_id

  # Ingress rule: Allow traffic on the Redis port from the EKS cluster's security group.
  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.cluster_security_group_id]
  }

  # Egress rule: Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-redis-sg"
  }
}

# The ElastiCache Subnet Group tells ElastiCache which subnets it can use.
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-cache-subnet-group"
  subnet_ids = var.private_subnet_ids
}

# Create the ElastiCache Redis replication group (for Multi-AZ and encryption)
resource "aws_elasticache_replication_group" "main" {
  replication_group_id          = "${replace(var.project_name, "_", "-")}-redis-rg"
  description                   = "Redis replication group for ${var.project_name}"
  node_type                     = "cache.t3.micro"
  engine                        = "redis"
  engine_version                = "7.1"
  port                          = 6379
  
  # Requirement: Create a cluster across AZs
  num_node_groups               = 1
  replicas_per_node_group       = 1
  
  subnet_group_name             = aws_elasticache_subnet_group.main.name
  security_group_ids            = [aws_security_group.redis.id]
  automatic_failover_enabled    = true

  # Requirement: At-rest and in-transit encryption
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
}