locals {
  env         = "dev"
  region      = "ap-northeast-1"
  system_name = "system"
  vpc_cidr    = "10.0.0.0/16"
  subnet_public_cidr_a = "10.0.11.0/24"
  subnet_public_cidr_c = "10.0.12.0/24"
  subnet_protected_cidr_a = "10.0.21.0/24"
  subnet_protected_cidr_c = "10.0.22.0/24"
  subnet_private_cidr_a = "10.0.31.0/24"
  subnet_private_cidr_c = "10.0.32.0/24"
  keyname     = "horikawa"
  ami_id      = "ami-03d6ff1bfaee16fc6"
  ec2_instance = "t3.micro"
  #certificate_arn     = "arn:aws:acm:ap-northeast-1:575108922795:certificate/dde87e5f-e745-43f4-bdf3-d70ed7a7b8b2"

  dbname     = "aurora"
  engine      = "aurora-mysql"
  engine_version = "8.0.mysql_aurora.3.08.2"
  instance_class = "db.serverless"
}

module "network" {
  source = "../../modules/network"

  region = local.region
  env = local.env
  vpc_cidr = local.vpc_cidr
  system_name = local.system_name
  subnet_public_cidr_a = local.subnet_public_cidr_a
  subnet_public_cidr_c = local.subnet_public_cidr_c
  subnet_protected_cidr_a = local.subnet_protected_cidr_a
  subnet_protected_cidr_c = local.subnet_protected_cidr_c
  subnet_private_cidr_a = local.subnet_private_cidr_a
  subnet_private_cidr_c = local.subnet_private_cidr_c
}

module "compute" {
  source = "../../modules/compute"

  env = local.env
  system_name = local.system_name
  vpc_id = module.network.vpc_id
  subnets_a = module.network.subnets_a
  subnets_c = module.network.subnets_c
  keyname = local.keyname
  ami_id  = local.ami_id
  ec2_instance = local.ec2_instance
  certificate_arn = local.certificate_arn
}

/*
module "rds" {
  source = "../../modules/rds"
  env = local.env
  system_name = local.system_name
  vpc_id = module.network.vpc_id
  subnets_a = module.network.subnets_a
  subnets_c = module.network.subnets_c
  web_sg    = module.compute.web_sg
  dbname          = local.dbname
  engine          = local.engine
  engine_version  = local.engine_version
  instance_class  = local.instance_class    
}

module "backup" {
  source = "../../modules/backup"
  env = local.env
  system_name = local.system_name
  rds_cluster = module.rds.rds_cluster
  plans = {
    # キー名はプラン名
    rds_plan = {
      rules = {
        rds_daily_backup_rule = {
          schedule                 = "cron(0 15 ? * * *)" // 毎日 00:00 JST
          enable_continuous_backup = false
          start_window             = 60
          completion_window        = 120
          delete_after             = 7
          copy_action = {
            delete_after = 14
          }
        }
        rds_hourly_backup_rule = {
          schedule                 = "cron(0 * ? * * *)" // 毎時 0 分に取得
          enable_continuous_backup = true                // ポイントインタイムリカバリ(PITR)バックアップ
          start_window             = 60
          completion_window        = 120
          delete_after             = 3
          copy_action              = { /* コピーしない */ }
        }
      }
      condition = {
        resources = ["arn:aws:rds:*:*:db:*"]
        key       = "aws:ResourceTag/aws-backup" // aws-backup の箇所は好みのタグに変える
        value     = "true"
      }
    }
  }
}

*/
