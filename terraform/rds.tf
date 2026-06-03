resource "aws_db_subnet_group" "main" {
  name       = "three-tier-db-subnet-group"
  subnet_ids = aws_subnet.db[*].id
  tags       = { Name = "three-tier-db-subnet-group" }
}

resource "aws_db_instance" "main" {
  identifier             = "three-tier-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  multi_az               = true
  skip_final_snapshot    = false
  final_snapshot_identifier = "three-tier-db-final"
  backup_retention_period = 7
  storage_encrypted      = true
  tags                   = { Name = "three-tier-rds" }
}
