resource "aws_db_subnet_group" "main" {
  name        = "${local.name}-db-subnets"
  description = "Private subnets used by the Multi-AZ RDS instance"
  subnet_ids  = [for subnet in aws_subnet.private : subnet.id]

  tags = {
    Name = "${local.name}-db-subnets"
  }
}

resource "aws_db_instance" "this" {
  identifier = "${local.name}-db"

  engine         = var.db_engine
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class
  port           = local.db_port

  db_name  = var.db_name
  username = var.db_username

  manage_master_user_password = true

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  multi_az                = true
  publicly_accessible     = false
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.db.id]
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  auto_minor_version_upgrade = true
  apply_immediately          = false
  copy_tags_to_snapshot      = true

  deletion_protection       = var.rds_deletion_protection
  skip_final_snapshot       = var.rds_skip_final_snapshot
  final_snapshot_identifier = "${local.name}-final-snapshot"

  tags = {
    Name = "${local.name}-db"
  }
}
