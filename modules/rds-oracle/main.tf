#resource "null_resource" "smoke_tests" {
#  provisioner "local-exec" {
#    working_dir = "${path.module}/scripts"
#    command     = "chmod +x smoke_tests.sh  && ./smoke_tests.sh"
#    interpreter = ["/bin/bash", "-c"]
#  }
#}

provider "aws" {
  region = local.region
}

provider "aws" {
  alias  = "region2"
  region = local.region2
}

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

locals {
  name    = "rds-oracle"
  region  = var.region
  region2 = var.region2

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Name       = local.name
    Example    = local.name
    Repository = "https://github.com/sourirv/tf-rds-oracle"
  }

  timestamp = "${timestamp()}"
  timestamp_for_postfix = "${replace("${local.timestamp}", "/[- TZ:]/", "")}"
}

################################################################################
# RDS Module
################################################################################

module "db" {
  source  = "terraform-aws-modules/rds/aws"

  identifier = var.identifier

  engine               = "oracle-ee"
  engine_version       = "19"
  family               = "oracle-ee-19" # DB parameter group
  major_engine_version = "19"           # DB option group
  instance_class       = "db.m5.large"
  license_model        = "bring-your-own-license"

  allocated_storage     = 20
  max_allocated_storage = 100

  # Make sure that database name is capitalized, otherwise RDS will try to recreate RDS instance every time
  # Oracle database name cannot be longer than 8 characters
  db_name  = "ORACLE"
  username = "admin_user"
  port     = 1521

  multi_az               = true
  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [module.security_group.security_group_id]

  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["alert", "audit"]
  create_cloudwatch_log_group     = true

  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  create_monitoring_role                = false

  # See here for support character sets https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.OracleCharacterSets.html
  character_set_name = "AL32UTF8"

  tags = local.tags
  create_db_parameter_group = false
  parameter_group_name = aws_db_parameter_group.custom.name
  apply_immediately    = true
}


resource "aws_db_parameter_group" "custom" {
  name   = "custom-${local.timestamp_for_postfix}"
  family = "oracle-ee-19"

  parameter {
    name  = "compatible"
    value = var.compatible
    apply_method = "pending-reboot"
  }
  
  parameter {
    name  = "undo_tablespace"
    value = var.undo_tablespace
  }
  parameter {
    name  = "undo_retention"
    value = var.undo_retention
  }
  parameter {
    name  = "db_files"
    value = var.db_files
    apply_method = "pending-reboot"
  }
  parameter {
    name  = "memory_target"
    value = var.memory_target
  }
  parameter {
    name  = "java_pool_size"
    value = var.java_pool_size
  }
  parameter {
    name  = "log_checkpoint_interval"
    value = var.log_checkpoint_interval
  }
  parameter {
    name  = "processes"
    value = var.processes
    apply_method = "pending-reboot"
  }
  parameter {
    name  = "dml_locks"
    value = var.dml_locks
    apply_method = "pending-reboot"
  }
  parameter {
    name  = "session_cached_cursors"
    value = var.session_cached_cursors
    apply_method = "pending-reboot"
  }
  parameter {
    name  = "open_cursors"
    value = var.open_cursors
  }
  parameter {
    name  = "CURSOR_SHARING"
    value = var.CURSOR_SHARING
  }
  parameter {
    name  = "job_queue_processes"
    value = var.job_queue_processes
  }
  parameter {
    name  = "timed_statistics"
    value = var.timed_statistics
    apply_method = "pending-reboot"
  }
  parameter {
    name  = "max_dump_file_size"
    value = var.max_dump_file_size
  }
  parameter {
    name  = "global_names"
    value = var.global_names
  }
  
  parameter {
    name  = "optimizer_mode"
    value = var.optimizer_mode
  }
  parameter {
    name  = "aq_tm_processes"
    value = var.aq_tm_processes
  }
  parameter {
    name  = "QUERY_REWRITE_INTEGRITY"
    value = var.QUERY_REWRITE_INTEGRITY
  }
  parameter {
    name  = "QUERY_REWRITE_ENABLED"
    value = var.QUERY_REWRITE_ENABLED
  }
  
  parameter {
    name  = "recyclebin"
    value = var.recyclebin
    apply_method = "pending-reboot"
  }
  parameter {
    name  = "_hash_join_enabled"
    value = var._hash_join_enabled
    apply_method = "pending-reboot"
  }
  parameter {
    name  = "db_keep_cache_size"
    value = var.db_keep_cache_size
  }
  parameter {
    name  = "DEFERRED_SEGMENT_CREATION"
    value = var.DEFERRED_SEGMENT_CREATION
  }
  parameter {
    name  = "db_securefile"
    value = var.db_securefile
  }
}

module "db_disabled" {
  source  = "terraform-aws-modules/rds/aws"

  identifier = "${local.name}-disabled"

  create_db_instance        = false
  create_db_parameter_group = false
  create_db_option_group    = false
}

################################################################################
# RDS Automated Backups Replication Module
################################################################################

module "kms" {
  source      = "terraform-aws-modules/kms/aws"
  version     = "~> 1.0"
  description = "KMS key for cross region automated backups replication"

  # Aliases
  aliases                 = [local.name]
  aliases_use_name_prefix = true

  key_owners = [data.aws_caller_identity.current.arn]

  tags = local.tags

  providers = {
    aws = aws.region2
  }
}


resource "aws_db_instance_automated_backups_replication" "default" {
  source_db_instance_arn = module.db.db_instance_arn
  kms_key_id             = module.kms.key_arn

  provider = aws.region2
}


################################################################################
# Supporting Resources
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = local.name
  cidr = local.vpc_cidr

  azs              = local.azs
  public_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 3)]
  database_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 6)]

  create_database_subnet_group = true

  tags = local.tags
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = local.name
  description = "Complete Oracle example security group"
  vpc_id      = module.vpc.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 1521
      to_port     = 1521
      protocol    = "tcp"
      description = "Oracle access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]

  tags = local.tags
}