#locals {
#  directory_layers = split("/", var.public_key_path)
#  key_pair_file_name = element(local.directory_layers, length(local.directory_layers) - 1)
#}

#resource "aws_key_pair" "my_key_pair" {
#  key_name   = local.key_pair_file_name
#  public_key = file(var.public_key_path)
#}

resource "aws_security_group" "bastion_sg" {
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["163.49.24.253/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-${var.system_name}-sg-bastion"
  }
}

resource "aws_security_group" "web_sg" {
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.subnets_a["public"].cidr_block]
  }

  ingress {
    description     = "Allow HTTP from ALB security group"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [ aws_security_group.sg-alb.id ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-${var.system_name}-web-sg"
  }
}

# バスチョンサーバー (パブリックサブネットに配置)
resource "aws_instance" "bastion" {
  ami           = var.ami_id  # Amazon Linux 2023のAMI ID (リージョンによって異なる)
  instance_type = "t3.micro"
  subnet_id     = var.subnets_a["public"].id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name      = var.keyname

  tags = {
    Name = "${var.env}-${var.system_name}-bastion"
  }
}

resource "aws_eip" "bastion_eip" {
  domain = "vpc"
  instance = aws_instance.bastion.id
}

# Webサーバー1 (プライベートサブネット1に配置)
resource "aws_instance" "web1" {
  ami           = var.ami_id  # Amazon Linux 2023のAMI ID (リージョンによって異なる)
  instance_type = var.ec2_instance
  subnet_id     = var.subnets_a["protected"].id
  vpc_security_group_ids = [ aws_security_group.web_sg.id ]
  key_name      = var.keyname

  tags = {
    Name = "${var.env}-${var.system_name}-web1"
  }
}

# Webサーバー2 (プライベートサブネット2に配置)
resource "aws_instance" "web2" {
  ami           = var.ami_id  # Amazon Linux 2023のAMI ID (リージョンによって異なる)
  instance_type = var.ec2_instance
  subnet_id     = var.subnets_c["protected"].id
  vpc_security_group_ids = [ aws_security_group.web_sg.id ]
  key_name      = var.keyname

  tags = {
    Name = "${var.env}-${var.system_name}-web2"
  }
}

/*
# テスト用
resource "aws_instance" "web0" {
  ami           = "ami-0c1638aa346a43fe8" # Amazon Linux 2023のAMI ID (リージョンによって異なる)
  instance_type = "t3.micro"
  subnet_id     = var.subnets_c["protected"].id
  security_groups = [aws_security_group.web_sg.id]
  key_name      = var.keyname

  user_data = <<EOF
    #!/bin/bash
    yum install -y httpd
    systemctl start httpd.service
    systemctl enable httpd.service
    echo "Hallo World" > /var/www/html/index.html
  EOF

  tags = {
    Name = "${var.env}-${var.system_name}-web0"
  }
}
*/

