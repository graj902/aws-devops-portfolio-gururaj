# Create a dedicated security group for the RDS instance
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Allow PostgreSQL traffic from the EKS cluster"
  vpc_id      = var.vpc_id

  # Ingress rule: Allow traffic on the PostgreSQL port from the EKS cluster's security group.
  ingress {
    from_port       = 5432
    to_port         = 5432
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
    Name = "${var.project_name}-rds-sg"
  }
}

# The DB Subnet Group tells RDS which subnets it can use.
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# Create the RDS PostgreSQL instance
resource "aws_db_instance" "main" {
  identifier_prefix      = var.project_name
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "14.12" # A known stable version in ap-south-1
  instance_class         = "db.t3.micro"
  db_name                = "${replace(var.project_name, "-", "")}db" # Sanitize name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  
  # Requirement: Multi-AZ failover
  multi_az = true
  
  # Requirement: At-rest encryption
  storage_encrypted = true
  
  # For this project, we don't need a final snapshot on destroy
  skip_final_snapshot = true
}

