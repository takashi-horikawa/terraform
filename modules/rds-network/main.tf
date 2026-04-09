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

