resource "aws_backup_vault" "primary" {
  name = "${var.env}-${var.system_name}-primary-backup-vault"
}

resource "aws_backup_vault" "copy" {
  provider = aws.osaka
  name     = "${var.env}-${var.system_name}-osaka-backup-vault"
}

resource "aws_iam_role" "backup_role" {
  name = "${var.env}-${var.system_name}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "backup_policy" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_backup_plan" "plan" {
  name = "${var.env}-${var.system_name}-aurora-backup-plan"

  rule {
    rule_name         = "hourly-aurora-backup"
    target_vault_name = aws_backup_vault.primary.name
    schedule          = "cron(0 * * * ? *)"  # 毎時
    start_window      = 60
    completion_window = 120

    lifecycle {
      cold_storage_after = 0
      delete_after       = 7
    }

    copy_action {
      destination_vault_arn = aws_backup_vault.copy.arn
      lifecycle {
        delete_after = 7
      }
    }
  }
}

resource "aws_backup_selection" "aurora" {
  name          = "aurora-cluster-selection"
  iam_role_arn  = aws_iam_role.backup_role.arn
  plan_id = aws_backup_plan.plan.id

  resources = [ var.rds_cluster ]
}
