
variable "environment" {
  description = "The deployment environment dev|cicd|test|prod etc."
  type        = string
}

variable "bucket_name" {
  description = "The name of the s3 bucket where state is stored"
  type        = string
}

variable "_depends_on" {
  description = "The list of dependencies for the module"
  type        = any
  default     = []
}

variable "state_key" {
  description = "The key in the s3 bucket where state is stored"
  type        = string
  default = "tfstate"
}

variable "region" {
  description = "The region for primary RDS"
  type        = string
  default = "us-east-2"
}

variable "region2" {
  description = "The backup region for rds"
  type        = string
  default = "us-east-1"
}

variable "identifier" {
  description = "The identifier of the RDS instance"
  type        = string
  default = "rds-oracle-test"
}

variable "debug_mode" {
  description = "Indicates whether to run deployment in debug mode"
  type        = bool
  default     = true
}

variable "compatible" {
    type      = string
    default   = "12.1.0"
 
}
 
variable "undo_tablespace" {
    type      = string 
    default =  "UNDO_T1"
}
variable "undo_retention" {
    type      = string
    default =  "7200"
}

variable "db_files" {
    type      = string
    default =   "2000"

}
variable "memory_target" {
    type      = string
    default =   "IF({DBInstanceClassHugePagesDefault}, 0, {DBInstanceClassMemory*3/4})"
}
variable "java_pool_size" {
    type      = string
    default =   "0"
}
variable "log_checkpoint_interval" {
    type      = string
    default =   "0"
}
variable "processes" {
    type      = string
    default =   "LEAST({DBInstanceClassMemory/9868951}, 20000)"
}
variable "dml_locks" {
    type      = string
    default =   "100"
}
variable "session_cached_cursors" {
    type      = string
    default =   "200"
}
variable "open_cursors" {
    type      = string
    default =   "200"
}
variable "CURSOR_SHARING" {
    type      = string
    default =   "FORCE"
}
variable "job_queue_processes" {
    type      = string
    default =   "10"
}
variable "timed_statistics" {
    type      = string
    default =   "true"
}
variable "max_dump_file_size" {
    type      = string
    default =   "10240"
}
variable "global_names" {
    type      = string
    default =   "TRUE"
}

variable "optimizer_mode" {
    type      = string
    default =   "FIRST_ROWS_10"
}
variable "aq_tm_processes" {
    type      = string
    default =   "1"
}
variable "QUERY_REWRITE_INTEGRITY" {
    type      = string
    default =   "TRUSTED"
}
variable "QUERY_REWRITE_ENABLED" {
    type      = string
    default =   "TRUE"
}

variable "recyclebin" {
    type      = string
    default =   "OFF"
}
variable "_hash_join_enabled" {
    type      = string
    default =   "false"
}
variable "db_keep_cache_size" {
    type      = string
    default =   "20000000"
}
variable "DEFERRED_SEGMENT_CREATION" {
    type      = string
    default =   "false"
}
variable "db_securefile" {
    type      = string
    default =   "PERMITTED"
}