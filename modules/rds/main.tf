# -----------------------------------------------------------------------------
# Subnet Group
# -----------------------------------------------------------------------------
resource "aws_db_subnet_group" "database_sg_group" {
  name       = "${var.env}-${var.system_name}-database-subnet-group"
  subnet_ids = [ 
                var.subnets_a["private"].id,
                var.subnets_c["private"].id
              ]
}

# -----------------------------------------------------------------------------
# Security Group
# -----------------------------------------------------------------------------
resource "aws_security_group" "database_sg" {
  name   = "${var.env}-${var.system_name}-database-sg"
  vpc_id = var.vpc_id

  ingress {
    description = "Allow 3306 from Web-Server"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [ var.web_sg ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -----------------------------------------------------------------------------
# Secrets Manager
# -----------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "aurora_credentials" {
  name = "${var.env}-${var.system_name}-aurora-secret"
}

resource "random_password" "aurora_password" {
  length           = 41
  special          = true
  override_special = "!()*+,-.;<=>?[]^_{|}~"
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
}

resource "aws_secretsmanager_secret_version" "aurora_credentials_version" {
  secret_id = aws_secretsmanager_secret.aurora_credentials.id
  secret_string = jsonencode({
    username              = "root",
    password              = random_password.aurora_password.result,
    port                  = "3306",
    dbname                = var.dbname
  })
}

data "aws_secretsmanager_secret" "data_aurora_credentials" {
  arn = aws_secretsmanager_secret.aurora_credentials.arn
}

data "aws_secretsmanager_secret_version" "data_aurora_credentials_version" {
  secret_id = data.aws_secretsmanager_secret.data_aurora_credentials.id
}

locals {
  secret_data = jsondecode(data.aws_secretsmanager_secret_version.data_aurora_credentials_version.secret_string)
}

# -----------------------------------------------------------------------------
# RDS
# -----------------------------------------------------------------------------

#resource "aws_rds_cluster_parameter_group" "parameter_group" {
#  name   = "${var.env}-${var.system_name}-database-cluster-parameter-group"
#  family = "aurora-mysql8.0"
#
#  parameter {
#    name  = "time_zone"
#    value = "Asia/Tokyo"
#  }
#}

resource "aws_rds_cluster" "rds_cluster" {
  depends_on             = [aws_secretsmanager_secret_version.aurora_credentials_version]
  cluster_identifier     = "${var.env}-${var.system_name}-cluster"
  db_subnet_group_name   = aws_db_subnet_group.database_sg_group.name
  vpc_security_group_ids = [aws_security_group.database_sg.id]
  availability_zones     = ["ap-northeast-1a","ap-northeast-1c"]
  engine                 = var.engine
  engine_version         = var.engine_version
  engine_mode            = "provisioned"
  database_name          = local.secret_data.dbname
  master_username        = local.secret_data.username
  master_password        = local.secret_data.password
  port                   = "3306"

  skip_final_snapshot             = true
  #db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.parameter_group.name
  db_cluster_parameter_group_name = "default.aurora-mysql8.0"

  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 1.0
  }

  lifecycle {
    ignore_changes = [availability_zones]
  }
}

resource "aws_rds_cluster_instance" "rds_instance" {
  identifier         = "${var.env}-${var.system_name}-instance"
  cluster_identifier = aws_rds_cluster.rds_cluster.id

  engine         = aws_rds_cluster.rds_cluster.engine
  engine_version = aws_rds_cluster.rds_cluster.engine_version

  instance_class       = var.instance_class
  db_subnet_group_name = aws_rds_cluster.rds_cluster.db_subnet_group_name
}
